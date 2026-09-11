import importlib.util
from io import BytesIO
from pathlib import Path
import unittest
from unittest import mock
from urllib import error

MODULE_PATH = Path(__file__).resolve().parents[1] / "dockerhub_tag_guard.py"
spec = importlib.util.spec_from_file_location("dockerhub_tag_guard", MODULE_PATH)
dockerhub_tag_guard = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(dockerhub_tag_guard)


class DummyResponse:
    def __init__(self, payload=b""):
        self.payload = payload

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc, tb):
        return False

    def read(self, _size=-1):
        return self.payload


class DockerHubTagGuardTests(unittest.TestCase):
    def test_registry_urls_are_formed_for_exact_repository_tag(self):
        self.assertIn(
            "scope=repository%3Ahenriqueslab%2Fdl4miceverywhere%3Apull",
            dockerhub_tag_guard.auth_token_url("henriqueslab", "dl4miceverywhere"),
        )
        self.assertEqual(
            dockerhub_tag_guard.manifest_url(
                "henriqueslab", "dl4miceverywhere", "model-z1.2.3-d2.0.0"
            ),
            "https://registry-1.docker.io/v2/henriqueslab/dl4miceverywhere/"
            "manifests/model-z1.2.3-d2.0.0",
        )

    @mock.patch.object(dockerhub_tag_guard.request, "urlopen")
    def test_existing_tag_returns_true(self, urlopen):
        urlopen.side_effect = [
            DummyResponse(b'{"token":"abc"}'),
            DummyResponse(),
        ]
        self.assertTrue(
            dockerhub_tag_guard.tag_exists("henriqueslab", "dl4miceverywhere", "existing")
        )
        manifest_request = urlopen.call_args_list[1].args[0]
        self.assertEqual(manifest_request.get_method(), "HEAD")
        self.assertEqual(manifest_request.get_header("Authorization"), "Bearer abc")

    @mock.patch.object(dockerhub_tag_guard.request, "urlopen")
    def test_missing_tag_returns_false(self, urlopen):
        urlopen.side_effect = [
            DummyResponse(b'{"token":"abc"}'),
            error.HTTPError(
                "https://example.invalid", 404, "Not Found", {}, BytesIO(b"")
            ),
        ]
        self.assertFalse(
            dockerhub_tag_guard.tag_exists("henriqueslab", "dl4miceverywhere", "missing")
        )

    @mock.patch.object(dockerhub_tag_guard.request, "urlopen")
    def test_indeterminate_registry_error_does_not_allow_build(self, urlopen):
        urlopen.side_effect = [
            DummyResponse(b'{"token":"abc"}'),
            error.HTTPError(
                "https://example.invalid", 500, "Server Error", {}, BytesIO(b"")
            ),
        ]
        with self.assertRaises(dockerhub_tag_guard.DockerHubCheckError):
            dockerhub_tag_guard.tag_exists("henriqueslab", "dl4miceverywhere", "unknown")

    @mock.patch.object(dockerhub_tag_guard, "tag_exists", return_value=True)
    def test_main_fails_when_release_tag_already_exists(self, _exists):
        rc = dockerhub_tag_guard.main(["--tag", "model-z1.2.3-d2.0.0"])
        self.assertEqual(rc, 1)

    @mock.patch.object(dockerhub_tag_guard, "tag_exists", return_value=False)
    def test_main_allows_unused_release_tag(self, _exists):
        rc = dockerhub_tag_guard.main(["--tag", "model-z1.2.4-d2.0.0"])
        self.assertEqual(rc, 0)


if __name__ == "__main__":
    unittest.main()
