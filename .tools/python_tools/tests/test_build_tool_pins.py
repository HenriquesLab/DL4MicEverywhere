from pathlib import Path
import re
import unittest


REPO_ROOT = Path(__file__).resolve().parents[3]
PROFILE = REPO_ROOT / ".tools" / "lock_profiles" / "python3.8plus.in"
MODERN_DOCKERFILES = [
    REPO_ROOT / "docker" / "Dockerfile.modern",
    REPO_ROOT / "docker" / "Dockerfile.gpu.modern",
]


def profile_pin(package: str) -> str:
    match = re.search(rf"^{package}==(\S+)\s*$", PROFILE.read_text(encoding="utf-8"), re.MULTILINE)
    return match.group(1) if match else ""


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


if __name__ == "__main__":
    unittest.main()
