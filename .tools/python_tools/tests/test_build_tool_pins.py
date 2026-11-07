from pathlib import Path
import re
import unittest


REPO_ROOT = Path(__file__).resolve().parents[3]
PROFILE = REPO_ROOT / ".tools" / "lock_profiles" / "python3.8plus.in"
PROFILE_37 = REPO_ROOT / ".tools" / "lock_profiles" / "python3.7.in"
MODERN_DOCKERFILES = [
    REPO_ROOT / "docker" / "Dockerfile.modern",
    REPO_ROOT / "docker" / "Dockerfile.gpu.modern",
]
ALL_DOCKERFILES = MODERN_DOCKERFILES + [
    REPO_ROOT / "docker" / "Dockerfile.legacy",
    REPO_ROOT / "docker" / "Dockerfile.gpu.legacy",
]


def profile_pin(package: str, profile: Path = PROFILE) -> str:
    match = re.search(rf"^{package}==(\S+)\s*$", profile.read_text(encoding="utf-8"), re.MULTILINE)
    return match.group(1) if match else ""


def dockerfile_python37_pin(dockerfile: Path, variable: str) -> str:
    text = dockerfile.read_text(encoding="utf-8")
    case = re.search(r"^\s*3\.7\)\s*\\\s*\n\s*([^\n]*SETUPTOOLS_VERSION[^\n]*)", text, re.MULTILINE)
    assert case is not None, f"No Python 3.7 build-tool case in {dockerfile.name}"
    value = re.search(rf"{variable}=([0-9.]+)", case.group(1))
    return value.group(1) if value else ""


def dockerfile_python38plus_pin(dockerfile: Path, variable: str) -> str:
    # The Python 3.8+ case of the build-tool pins, e.g.
    #   3.8|3.9|3.10|3.11|3.12|3.13) \
    #       PIP_VERSION=24.3.1; SETUPTOOLS_VERSION=75.3.2; WHEEL_VERSION=0.45.1 ;; \
    text = dockerfile.read_text(encoding="utf-8")
    case = re.search(r"^\s*3\.8\|3\.9\|[^)]*\)\s*\\\s*\n\s*([^\n]*SETUPTOOLS_VERSION[^\n]*)", text, re.MULTILINE)
    assert case is not None, f"No Python 3.8+ build-tool case in {dockerfile.name}"
    value = re.search(rf"{variable}=([0-9.]+)", case.group(1))
    return value.group(1) if value else ""


class BuildToolPinTests(unittest.TestCase):
    def test_lock_profile_keeps_dockerfile_setuptools(self):
        # The lock is installed after the Dockerfile pins the build tools. If the
        # lock resolved setuptools freely (it is a dependency of TensorFlow), it
        # would replace the pinned version, e.g. with setuptools 82+, which no
        # longer provides pkg_resources and breaks stardist 0.9.1.
        pinned = profile_pin("setuptools")
        self.assertTrue(pinned, "python3.8plus.in must pin setuptools")
        self.assertLess(int(pinned.split(".")[0]), 82, "setuptools 82+ removed pkg_resources")
        for dockerfile in MODERN_DOCKERFILES:
            with self.subTest(dockerfile=dockerfile.name):
                self.assertEqual(dockerfile_python38plus_pin(dockerfile, "SETUPTOOLS_VERSION"), pinned)

    def test_python37_profile_keeps_dockerfile_setuptools(self):
        # The lock install also runs under a setuptools constraint (see below),
        # so a different setuptools in the lock would make the install fail.
        pinned = profile_pin("setuptools", PROFILE_37)
        self.assertTrue(pinned, "python3.7.in must pin setuptools")
        for dockerfile in MODERN_DOCKERFILES:
            with self.subTest(dockerfile=dockerfile.name):
                self.assertEqual(dockerfile_python37_pin(dockerfile, "SETUPTOOLS_VERSION"), pinned)

    def test_legacy_profiles_keep_dockerfile_setuptools(self):
        for version in ("3.5", "3.6"):
            pinned = profile_pin("setuptools", PROFILE.with_name(f"python{version}.in"))
            for dockerfile in ALL_DOCKERFILES[2:]:
                with self.subTest(python=version, dockerfile=dockerfile.name):
                    block = re.search(rf"^\s*{re.escape(version)}\)\s*\\\n(.*?);;",
                                      dockerfile.read_text(encoding="utf-8"), re.MULTILINE | re.DOTALL)
                    self.assertIsNotNone(block)
                    self.assertIn(f"SETUPTOOLS_VERSION={pinned};", block.group(1))

    def test_legacy_pip_bootstrap_ignores_pip_no_cache_dir(self):
        # Python 3.6.15 bundles pip 18.1, which crashes on PIP_NO_CACHE_DIR=1
        # ("expected str, bytes or os.PathLike object, not int").
        for dockerfile in ALL_DOCKERFILES[2:]:
            with self.subTest(dockerfile=dockerfile.name):
                self.assertIn('env -u PIP_NO_CACHE_DIR "${VIRTUAL_ENV}/bin/python" -m pip install --no-cache-dir',
                              dockerfile.read_text(encoding="utf-8"))

    def test_packages_compiled_from_source_use_the_pinned_setuptools(self):
        # pip compiles packages without wheels (mpi4py, wget, ...) in isolated
        # environments that ignore installed versions and fetch the newest
        # setuptools unless a constraint applies. mpi4py 3.1.5 fails to build
        # with setuptools 80+ ("new_compiler() got an unexpected keyword argument 'dry_run'").
        for dockerfile in ALL_DOCKERFILES:
            with self.subTest(dockerfile=dockerfile.name):
                text = dockerfile.read_text(encoding="utf-8")
                self.assertIn(
                    "printf 'setuptools==%s\\n' \"${SETUPTOOLS_VERSION}\" > /opt/dl4me-build-constraints.txt", text)
                self.assertIn("env -u PIP_NO_CACHE_DIR PIP_CONSTRAINT=/opt/dl4me-build-constraints.txt \\\n"
                              "            python -m pip install --cache-dir /root/.cache/pip \\\n"
                              "                --require-hashes -r /tmp/requirements.lock.txt", text)


if __name__ == "__main__":
    unittest.main()
