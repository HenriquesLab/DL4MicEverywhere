#!/usr/bin/env python3
"""Fail early when a versioned DL4MicEverywhere Docker Hub tag already exists.

Published version tags are treated as immutable release identifiers. This
pre-build guard uses Docker Hub's Registry API before any architecture build
starts. If the exact final tag already has a manifest, the workflow stops and
asks the contributor to update the version/tag instead of overwriting the
existing release.

The intentionally mutable ``*-latest`` aliases and architecture-specific
intermediate tags are not checked here; the guard protects the final versioned
release tag supplied by configuration.yaml.
"""

from __future__ import annotations

import argparse
import json
import sys
from typing import Optional
from urllib import error, parse, request

DEFAULT_AUTH_URL = "https://auth.docker.io/token"
DEFAULT_REGISTRY = "https://registry-1.docker.io"
DEFAULT_NAMESPACE = "henriqueslab"
DEFAULT_REPOSITORY = "dl4miceverywhere"
ACCEPT_MANIFESTS = ", ".join(
    [
        "application/vnd.oci.image.index.v1+json",
        "application/vnd.docker.distribution.manifest.list.v2+json",
        "application/vnd.oci.image.manifest.v1+json",
        "application/vnd.docker.distribution.manifest.v2+json",
    ]
)


class DockerHubCheckError(RuntimeError):
    """Raised when Docker Hub cannot be queried reliably."""


def auth_token_url(namespace: str, repository: str, auth_url: str = DEFAULT_AUTH_URL) -> str:
    scope = f"repository:{namespace}/{repository}:pull"
    query = parse.urlencode({"service": "registry.docker.io", "scope": scope})
    return f"{auth_url}?{query}"


def manifest_url(
    namespace: str,
    repository: str,
    tag: str,
    registry: str = DEFAULT_REGISTRY,
) -> str:
    namespace_q = parse.quote(namespace, safe="")
    repository_q = parse.quote(repository, safe="")
    tag_q = parse.quote(tag, safe="")
    return f"{registry.rstrip('/')}/v2/{namespace_q}/{repository_q}/manifests/{tag_q}"


def anonymous_pull_token(
    namespace: str,
    repository: str,
    *,
    auth_url: str = DEFAULT_AUTH_URL,
    timeout: float = 20.0,
) -> str:
    """Obtain a read-only bearer token for a public Docker Hub repository."""
    req = request.Request(
        auth_token_url(namespace, repository, auth_url),
        headers={"User-Agent": "DL4MicEverywhere-DockerHub-Tag-Guard/1"},
        method="GET",
    )
    try:
        with request.urlopen(req, timeout=timeout) as response:
            payload = json.loads(response.read().decode("utf-8"))
    except error.HTTPError as exc:
        raise DockerHubCheckError(
            f"Docker Hub token request returned HTTP {exc.code}"
        ) from exc
    except error.URLError as exc:
        raise DockerHubCheckError(f"Could not reach Docker Hub authentication: {exc.reason}") from exc
    except (json.JSONDecodeError, UnicodeDecodeError) as exc:
        raise DockerHubCheckError("Docker Hub returned an invalid authentication response") from exc
    except TimeoutError as exc:
        raise DockerHubCheckError("Docker Hub authentication timed out") from exc

    token = payload.get("token") or payload.get("access_token")
    if not token:
        raise DockerHubCheckError("Docker Hub authentication response did not contain a bearer token")
    return str(token)


def tag_exists(
    namespace: str,
    repository: str,
    tag: str,
    *,
    auth_url: str = DEFAULT_AUTH_URL,
    registry: str = DEFAULT_REGISTRY,
    timeout: float = 20.0,
) -> bool:
    """Return True if *tag* exists, False on a definite registry 404.

    Any other HTTP/network failure is considered indeterminate and raises an
    error. A publishing workflow must not continue if it could not verify that
    the release tag is unused.
    """
    token = anonymous_pull_token(
        namespace,
        repository,
        auth_url=auth_url,
        timeout=timeout,
    )
    req = request.Request(
        manifest_url(namespace, repository, tag, registry),
        headers={
            "Authorization": f"Bearer {token}",
            "Accept": ACCEPT_MANIFESTS,
            "User-Agent": "DL4MicEverywhere-DockerHub-Tag-Guard/1",
        },
        method="HEAD",
    )
    try:
        with request.urlopen(req, timeout=timeout):
            return True
    except error.HTTPError as exc:
        if exc.code == 404:
            return False
        raise DockerHubCheckError(
            f"Docker Hub manifest check returned HTTP {exc.code}"
        ) from exc
    except error.URLError as exc:
        raise DockerHubCheckError(f"Could not reach Docker Hub registry: {exc.reason}") from exc
    except TimeoutError as exc:
        raise DockerHubCheckError("Docker Hub manifest check timed out") from exc


def github_error(message: str) -> None:
    """Emit a GitHub Actions error annotation and regular stderr output."""
    escaped = (
        message.replace("%", "%25")
        .replace("\r", "%0D")
        .replace("\n", "%0A")
    )
    print(f"::error title=Docker Hub tag already published::{escaped}", file=sys.stderr)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Refuse to build if an exact DL4MicEverywhere Docker Hub tag already exists."
    )
    parser.add_argument("--tag", required=True, help="Exact final Docker tag to protect")
    parser.add_argument("--namespace", default=DEFAULT_NAMESPACE)
    parser.add_argument("--repository", default=DEFAULT_REPOSITORY)
    parser.add_argument("--auth-url", default=DEFAULT_AUTH_URL, help=argparse.SUPPRESS)
    parser.add_argument("--registry", default=DEFAULT_REGISTRY, help=argparse.SUPPRESS)
    parser.add_argument("--timeout", type=float, default=20.0, help=argparse.SUPPRESS)
    return parser


def main(argv: Optional[list[str]] = None) -> int:
    args = build_parser().parse_args(argv)
    tag = args.tag.strip()
    if not tag or tag.lower() in {"null", "none"}:
        github_error("The calculated Docker tag is empty; refusing to start a publishing build.")
        return 2

    image = f"{args.namespace}/{args.repository}:{tag}"
    try:
        exists = tag_exists(
            args.namespace,
            args.repository,
            tag,
            auth_url=args.auth_url,
            registry=args.registry,
            timeout=args.timeout,
        )
    except DockerHubCheckError as exc:
        message = (
            f"Could not verify whether {image} is already published. {exc}. "
            "The build is stopped to avoid accidentally overwriting an existing release tag."
        )
        github_error(message)
        print(f"ERROR: {message}", file=sys.stderr)
        return 2

    if exists:
        message = (
            f"Docker image tag {image} already exists on Docker Hub. "
            "Published version tags are treated as immutable, so DL4MicEverywhere will not rebuild "
            "or overwrite this tag. Update the notebook/DL4MicEverywhere version so "
            "configuration.yaml generates a new docker_hub_image tag, then run the workflow again."
        )
        github_error(message)
        print(f"ERROR: {message}", file=sys.stderr)
        return 1

    print(f"Docker Hub tag is available: {image}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
