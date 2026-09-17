from pathlib import Path
import os
import shutil
import subprocess
import tempfile
import unittest

REPO_ROOT = Path(__file__).resolve().parents[3]
MAC_LAUNCHER = REPO_ROOT / "MacOS_launch.command"
LINUX = REPO_ROOT / "Linux_launch.sh"
STATUS = REPO_ROOT / ".tools" / "bash_tools" / "launcher_status.sh"
PATH_UTILS = REPO_ROOT / ".tools" / "bash_tools" / "path_utils.sh"
MAC_ENV = REPO_ROOT / ".tools" / "bash_tools" / "macos_env.sh"
REQUIREMENTS = REPO_ROOT / ".tools" / "bash_tools" / "requirements_installation.sh"
DOCKER_INSTALL = REPO_ROOT / ".tools" / "bash_tools" / "requirements_installation" / "docker.sh"
HOMEBREW = REPO_ROOT / ".tools" / "bash_tools" / "requirements_installation" / "homebrew.sh"
DOCKER_DAEMON = REPO_ROOT / ".tools" / "bash_tools" / "pre_build_launch" / "check_docker_daemon.sh"
LAUNCHER_PY = REPO_ROOT / "launcher.py"
LAUNCHER_SPEC = REPO_ROOT / "launcher.spec"
MAC_WORKFLOW = REPO_ROOT / ".github" / "workflows" / "macos_launcher_tests.yml"


class MacOSLauncherStaticTests(unittest.TestCase):
    def test_repository_has_no_gnu_readlink_f_dependency(self):
        offenders = []
        for path in REPO_ROOT.rglob("*"):
            if not path.is_file() or ".git" in path.parts:
                continue
            try:
                text = path.read_text(encoding="utf-8")
            except UnicodeDecodeError:
                continue
            if ("readlink " + "-f") in text and path not in {PATH_UTILS, Path(__file__)}:
                offenders.append(str(path.relative_to(REPO_ROOT)))
        self.assertEqual(offenders, [])
        helper = PATH_UTILS.read_text(encoding="utf-8").replace("`readlink " + "-f`", "")
        self.assertNotIn("readlink " + "-f", helper)

    def test_mac_wrapper_preserves_and_routes_shared_statuses(self):
        text = MAC_LAUNCHER.read_text(encoding="utf-8")
        self.assertIn("DL4ME_MACOS_WRAPPER=1", text)
        self.assertNotIn("tell application \"Terminal\" to quit", text)
        for code in [42, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100, 101, 102, 103, 104]:
            with self.subTest(code=code):
                self.assertIn(f"    {code})", text)

    def test_linux_controlled_outcomes_reach_mac_wrapper(self):
        text = LINUX.read_text(encoding="utf-8")
        self.assertIn('[ "${DL4ME_MACOS_WRAPPER:-0}" = "1" ]', text)

    def test_homebrew_bootstrap_is_spelled_and_architecture_neutral(self):
        self.assertTrue(HOMEBREW.is_file())
        text = HOMEBREW.read_text(encoding="utf-8")
        self.assertIn("export NONINTERACTIVE=1", text)
        self.assertNotIn("exportNONINTERACTIVE", text)
        self.assertNotIn("brew shellenv", text)
        req = REQUIREMENTS.read_text(encoding="utf-8")
        self.assertIn('requirements_installation/homebrew.sh', req)
        env = MAC_ENV.read_text(encoding="utf-8")
        self.assertIn("/opt/homebrew/bin", env)
        self.assertIn("/usr/local/bin", env)

    def test_docker_desktop_uses_current_stable_architecture_urls(self):
        text = DOCKER_INSTALL.read_text(encoding="utf-8")
        self.assertIn("https://desktop.docker.com/mac/main/arm64/Docker.dmg", text)
        self.assertIn("https://desktop.docker.com/mac/main/amd64/Docker.dmg", text)
        self.assertNotIn("136059", text)
        self.assertNotIn("4.27.1", text)
        self.assertNotIn("--install-rosetta", text)
        self.assertIn('--user="$USER"', text)
        self.assertIn("hdiutil verify", text)

    def test_macos_requires_docker_app_not_only_cli(self):
        text = REQUIREMENTS.read_text(encoding="utf-8")
        self.assertIn('docker_app="${DL4ME_DOCKER_APP_PATH:-/Applications/Docker.app}"', text)
        self.assertIn('[ ! -d "$docker_app" ]', text)
        self.assertIn("No system restart is required", text)
        daemon = DOCKER_DAEMON.read_text(encoding="utf-8")
        self.assertIn('open "$docker_app"', daemon)
        self.assertIn("license/onboarding", daemon)


    def test_macos_docker_build_uses_user_desktop_context(self):
        text = LINUX.read_text(encoding="utf-8")
        self.assertIn('if [[ "$OSTYPE" == "darwin"* ]]; then', text)
        self.assertIn('docker_build_command=(docker build)', text)
        self.assertIn('docker_build_command=(sudo docker build)', text)

    def test_docker_wait_loop_does_not_require_seq(self):
        text = DOCKER_DAEMON.read_text(encoding="utf-8")
        self.assertNotIn("$(seq ", text)
        self.assertIn('while [ "$attempt" -lt 60 ]', text)

    def test_python_launcher_preserves_paths_with_spaces_and_child_status(self):
        text = LAUNCHER_PY.read_text(encoding="utf-8")
        self.assertIn('subprocess.run(["/bin/bash", launch_command], check=False)', text)
        self.assertIn('sys.exit(result.returncode)', text)


    def test_macos_bundle_name_and_ci_are_enabled(self):
        spec = LAUNCHER_SPEC.read_text(encoding="utf-8")
        workflow = MAC_WORKFLOW.read_text(encoding="utf-8")
        self.assertIn("name=f'{output_name}.app'", spec)
        self.assertIn("runs-on: macos-latest", workflow)
        self.assertIn("Run launcher regression tests on macOS", workflow)
        self.assertIn("/bin/bash -n", workflow)


class PortablePathRuntimeTests(unittest.TestCase):
    def test_path_helper_resolves_spaces_and_symlink_without_readlink_f(self):
        with tempfile.TemporaryDirectory(prefix="dl4me path test ") as td:
            root = Path(td)
            real_dir = root / "real dir"
            real_dir.mkdir()
            target = real_dir / "target.sh"
            target.write_text("#!/bin/bash\n", encoding="utf-8")
            link = root / "link.sh"
            link.symlink_to(target)
            command = (
                f'source "{PATH_UTILS}"; '
                f'dl4me_realpath "{link}"'
            )
            result = subprocess.run(
                ["bash", "-c", command],
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                check=False,
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(Path(result.stdout.strip()), target.resolve())


class MacOSEnvironmentRuntimeTests(unittest.TestCase):
    def test_docker_cli_inside_app_is_added_without_profile_edits(self):
        with tempfile.TemporaryDirectory(prefix="dl4me-mac-env-") as td:
            root = Path(td)
            app = root / "Docker.app"
            docker_bin = app / "Contents" / "Resources" / "bin"
            docker_bin.mkdir(parents=True)
            docker = docker_bin / "docker"
            docker.write_text("#!/bin/bash\nexit 0\n", encoding="utf-8")
            os.chmod(docker, 0o755)

            command = (
                f'source "{MAC_ENV}"; '
                'dl4me_setup_macos_path; '
                'command -v docker'
            )
            env = os.environ.copy()
            env["OSTYPE"] = "darwin"
            env["DL4ME_DOCKER_APP_PATH"] = str(app)
            env["PATH"] = "/usr/bin:/bin"
            result = subprocess.run(
                ["bash", "-c", command],
                env=env,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                check=False,
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(Path(result.stdout.strip()), docker)


class MacOSWrapperRuntimeTests(unittest.TestCase):
    def setUp(self):
        self.tempdir = Path(tempfile.mkdtemp(prefix="dl4me-mac-wrapper-"))
        (self.tempdir / ".tools" / "bash_tools").mkdir(parents=True)
        shutil.copy2(MAC_LAUNCHER, self.tempdir / "MacOS_launch.command")
        shutil.copy2(PATH_UTILS, self.tempdir / ".tools" / "bash_tools" / "path_utils.sh")
        shutil.copy2(MAC_ENV, self.tempdir / ".tools" / "bash_tools" / "macos_env.sh")
        shutil.copy2(STATUS, self.tempdir / ".tools" / "bash_tools" / "launcher_status.sh")
        self.fake_linux = self.tempdir / "Linux_launch.sh"
        self.fake_linux.write_text(
            "#!/bin/bash\nexit \"${FAKE_LINUX_STATUS:-0}\"\n",
            encoding="utf-8",
        )
        os.chmod(self.fake_linux, 0o755)

    def tearDown(self):
        shutil.rmtree(self.tempdir)

    def run_wrapper(self, status):
        env = os.environ.copy()
        env["OSTYPE"] = "darwin"
        env["FAKE_LINUX_STATUS"] = str(status)
        env["DL4ME_TEST_NO_PAUSE"] = "1"
        return subprocess.run(
            ["bash", str(self.tempdir / "MacOS_launch.command")],
            cwd=self.tempdir,
            env=env,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
        )

    def test_update_complete_is_explained_and_successful(self):
        result = self.run_wrapper(93)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("updated successfully", result.stdout)
        self.assertIn("Launch DL4MicEverywhere again", result.stdout)

    def test_known_runtime_failure_has_context_and_nonzero_status(self):
        result = self.run_wrapper(100)
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        self.assertIn("Notebook container ended with an error", result.stdout)

    def test_unclassified_failure_remains_unexpected(self):
        result = self.run_wrapper(17)
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        self.assertIn("ended unexpectedly on macOS", result.stdout)
        self.assertIn("exit code 17", result.stdout)


if __name__ == "__main__":
    unittest.main()
