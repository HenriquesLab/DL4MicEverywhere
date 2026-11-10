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


# Case labels of the build-tool pins in the modern Dockerfiles, e.g.
#   3.9|3.10|3.11|3.12|3.13) \
#       PIP_VERSION=25.3; SETUPTOOLS_VERSION=75.3.2; WHEEL_VERSION=0.45.1; BUILD_SETUPTOOLS_SPEC="<74" ;; \
CASE_37 = r"3\.7"
CASE_38 = r"3\.8"
CASE_39PLUS = r"3\.9\|[^)]*"


def dockerfile_case_line(dockerfile: Path, case_label: str) -> str:
    text = dockerfile.read_text(encoding="utf-8")
    case = re.search(rf"^\s*{case_label}\)\s*\\\s*\n\s*([^\n]*SETUPTOOLS_VERSION[^\n]*)", text, re.MULTILINE)
    assert case is not None, f"No build-tool case {case_label} in {dockerfile.name}"
    return case.group(1)


def dockerfile_case_pin(dockerfile: Path, case_label: str, variable: str) -> str:
    value = re.search(rf"{variable}=([0-9.]+)", dockerfile_case_line(dockerfile, case_label))
    return value.group(1) if value else ""


def dockerfile_case_build_spec(dockerfile: Path, case_label: str) -> str:
    value = re.search(r'BUILD_SETUPTOOLS_SPEC="([^"]+)"', dockerfile_case_line(dockerfile, case_label))
    return value.group(1) if value else ""


def version_tuple(version: str) -> tuple:
    return tuple(int(part) for part in version.split("."))


def spec_admits(spec: str, version: str) -> bool:
    # Only the upper-limit forms used by the Dockerfiles: "<=X" and "<X".
    match = re.fullmatch(r"(<=|<)([0-9.]+)", spec)
    assert match is not None, f"Unexpected setuptools build limit: {spec}"
    operator, limit = match.groups()
    if operator == "<=":
        return version_tuple(version) <= version_tuple(limit)
    return version_tuple(version) < version_tuple(limit)


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
            for case_label in (CASE_38, CASE_39PLUS):
                with self.subTest(dockerfile=dockerfile.name, case=case_label):
                    self.assertEqual(dockerfile_case_pin(dockerfile, case_label, "SETUPTOOLS_VERSION"), pinned)

    def test_python37_profile_keeps_dockerfile_setuptools(self):
        # The lock install also runs under a setuptools constraint (see below),
        # so a setuptools in the lock outside that limit would make the install fail.
        pinned = profile_pin("setuptools", PROFILE_37)
        self.assertTrue(pinned, "python3.7.in must pin setuptools")
        for dockerfile in MODERN_DOCKERFILES:
            with self.subTest(dockerfile=dockerfile.name):
                self.assertEqual(dockerfile_case_pin(dockerfile, CASE_37, "SETUPTOOLS_VERSION"), pinned)

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

    def test_packages_compiled_from_source_get_an_upper_setuptools_limit(self):
        # pip compiles packages without wheels (mpi4py, wget, ...) in isolated
        # environments that ignore installed versions and fetch the newest
        # setuptools unless a constraint applies. mpi4py 3.1.5 fails to build
        # with setuptools 80+ ("new_compiler() got an unexpected keyword argument 'dry_run'").
        # The constraint must be a limit, not an exact pin: packages that ask
        # for an older setuptools (scikit-image 0.18: <=51, nanopyx: <74) could
        # not be built on ARM64 under setuptools==X.
        for dockerfile in MODERN_DOCKERFILES:
            with self.subTest(dockerfile=dockerfile.name):
                self.assertIn(
                    "printf 'setuptools%s\\n' \"${BUILD_SETUPTOOLS_SPEC}\" > /opt/dl4me-build-constraints.txt",
                    dockerfile.read_text(encoding="utf-8"))
        for dockerfile in ALL_DOCKERFILES[2:]:
            with self.subTest(dockerfile=dockerfile.name):
                self.assertIn(
                    "printf 'setuptools<=%s\\n' \"${SETUPTOOLS_VERSION}\" > /opt/dl4me-build-constraints.txt",
                    dockerfile.read_text(encoding="utf-8"))
        for dockerfile in ALL_DOCKERFILES:
            with self.subTest(dockerfile=dockerfile.name):
                self.assertNotIn("printf 'setuptools==", dockerfile.read_text(encoding="utf-8"))

    def test_python39plus_build_limit_keeps_distutils_msvccompiler(self):
        # setuptools 74 removed distutils.msvccompiler, which numpy.distutils
        # builds such as stardist 0.8.3 import. Keeping the build environments
        # below 74 while the installed setuptools stays at 75.3.2 needs build
        # constraints that do not reach the install, i.e. pip 25.3+.
        for dockerfile in MODERN_DOCKERFILES:
            with self.subTest(dockerfile=dockerfile.name):
                self.assertEqual(dockerfile_case_build_spec(dockerfile, CASE_39PLUS), "<74")
                pip_version = dockerfile_case_pin(dockerfile, CASE_39PLUS, "PIP_VERSION")
                self.assertGreaterEqual(version_tuple(pip_version), (25, 3))

    def test_pip_constraint_limits_admit_the_installed_setuptools(self):
        # Python 3.7 and 3.8 pips have no build constraints, so the limit is
        # applied through PIP_CONSTRAINT to the whole install. It must admit
        # the setuptools that the Dockerfile and the lock pin exactly.
        for dockerfile in MODERN_DOCKERFILES:
            for case_label in (CASE_37, CASE_38):
                with self.subTest(dockerfile=dockerfile.name, case=case_label):
                    spec = dockerfile_case_build_spec(dockerfile, case_label)
                    installed = dockerfile_case_pin(dockerfile, case_label, "SETUPTOOLS_VERSION")
                    self.assertTrue(spec_admits(spec, installed), f"{spec} excludes setuptools {installed}")
                    pip_version = dockerfile_case_pin(dockerfile, case_label, "PIP_VERSION")
                    self.assertLess(version_tuple(pip_version), (25, 3))

    def test_install_sets_exactly_one_constraint_variable(self):
        # pip 25.3+ refuses to run when PIP_CONSTRAINT and PIP_BUILD_CONSTRAINT
        # are both set, and with older pips PIP_BUILD_CONSTRAINT does nothing.
        for dockerfile in ALL_DOCKERFILES:
            with self.subTest(dockerfile=dockerfile.name):
                text = dockerfile.read_text(encoding="utf-8")
                self.assertIn(
                    "    pip_install_help=$(python -m pip install --help) && \\\n"
                    "    case \"$pip_install_help\" in \\\n"
                    "        *--build-constraint*) constraint_var=PIP_BUILD_CONSTRAINT ;; \\\n"
                    "        *) constraint_var=PIP_CONSTRAINT ;; \\\n"
                    "    esac && \\\n", text)
                self.assertIn("env -u PIP_NO_CACHE_DIR \"${constraint_var}=/opt/dl4me-build-constraints.txt\" \\\n"
                              "            python -m pip install --cache-dir /root/.cache/pip \\\n"
                              "                --require-hashes -r /tmp/requirements.lock.txt", text)
                self.assertNotIn("PIP_CONSTRAINT=/opt/dl4me-build-constraints.txt", text)


if __name__ == "__main__":
    unittest.main()
