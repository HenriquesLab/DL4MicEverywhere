from pathlib import Path
import os
import shutil
import subprocess
import tempfile
import unittest

REPO_ROOT = Path(__file__).resolve().parents[3]
STATUS = REPO_ROOT / ".tools" / "bash_tools" / "launcher_status.sh"
LINUX = REPO_ROOT / "Linux_launch.sh"
WINDOWS = REPO_ROOT / "Windows_launch.bat"
PRELAUNCH = REPO_ROOT / ".tools" / "bash_tools" / "pre_launch_test.sh"
UPDATE = REPO_ROOT / ".tools" / "bash_tools" / "pre_build_launch" / "update_dl4miceverywhere.sh"
GUI = REPO_ROOT / ".tools" / "tcl_tools" / "main_gui.tcl"
LOCAL_DIALOG = REPO_ROOT / ".tools" / "tcl_tools" / "local_img_gui.tcl"
HUB_DIALOG = REPO_ROOT / ".tools" / "tcl_tools" / "hub_img_gui.tcl"


class ControlledOutcomeTests(unittest.TestCase):
    def test_shared_status_contract_is_explicit(self):
        text = STATUS.read_text(encoding="utf-8")
        expected = {
            "DL4ME_STATUS_UNINSTALL_HANDOFF": 42,
            "DL4ME_STATUS_RESTART_LATER": 90,
            "DL4ME_STATUS_RESTART_SCHEDULED": 91,
            "DL4ME_STATUS_GUI_CLOSED": 92,
            "DL4ME_STATUS_UPDATE_COMPLETE": 93,
            "DL4ME_STATUS_USER_CANCELLED": 94,
            "DL4ME_STATUS_HISTORICAL_IMAGE_UNAVAILABLE": 95,
            "DL4ME_STATUS_INPUT_INVALID": 96,
            "DL4ME_STATUS_DEPENDENCY_FAILED": 97,
            "DL4ME_STATUS_DOCKER_IMAGE_FAILED": 98,
            "DL4ME_STATUS_POST_BUILD_FAILED": 99,
            "DL4ME_STATUS_CONTAINER_RUNTIME_FAILED": 100,
            "DL4ME_STATUS_UPDATE_FAILED": 101,
            "DL4ME_STATUS_UNINSTALL_FAILED": 102,
            "DL4ME_STATUS_PREREQUISITE_FAILED": 103,
            "DL4ME_STATUS_PORT_UNAVAILABLE": 104,
        }
        for name, value in expected.items():
            with self.subTest(name=name):
                self.assertIn(f"{name}={value}", text)

    def test_windows_routes_every_known_status_before_generic_failure(self):
        text = WINDOWS.read_text(encoding="utf-8")
        routes = {
            42: "complete_uninstall",
            90: "restart_later",
            91: "restart_scheduled",
            92: "gui_closed",
            93: "update_complete",
            94: "operation_cancelled",
            95: "historical_image_unavailable",
            96: "input_invalid",
            97: "dependency_failed",
            98: "docker_image_failed",
            99: "post_build_failed",
            100: "container_runtime_failed",
            101: "update_failed",
            102: "uninstall_failed",
            103: "linux_prerequisite_failed",
            104: "port_unavailable",
        }
        generic = text.index("goto :launch_failed")
        for code, label in routes.items():
            with self.subTest(code=code):
                needle = f'if "%LAUNCH_RESULT%"=="{code}" goto :{label}'
                self.assertIn(needle, text)
                self.assertLess(text.index(needle), generic)
                self.assertIn(f":{label}", text)

    def test_quit_and_window_close_share_controlled_cancel_protocol(self):
        text = GUI.read_text(encoding="utf-8")
        self.assertIn('-label Quit -underline 0 -command { onCancel }', text)
        self.assertIn('wm protocol . WM_DELETE_WINDOW onCancel', text)
        self.assertIn('puts "__DL4ME_CANCEL__"', text)
        self.assertIn('bind .fr <Control-x> onCancel', text)

    def test_image_choice_windows_emit_zero_for_close(self):
        for path in (LOCAL_DIALOG, HUB_DIALOG):
            with self.subTest(path=path.name):
                text = path.read_text(encoding="utf-8")
                self.assertIn('proc finish {code}', text)
                self.assertIn('wm protocol . WM_DELETE_WINDOW {finish 0}', text)
        linux = LINUX.read_text(encoding="utf-8")
        self.assertIn('controlled_exit "$DL4ME_STATUS_USER_CANCELLED"', linux)

    def test_successful_update_has_dedicated_controlled_outcome(self):
        update = UPDATE.read_text(encoding="utf-8")
        gui = GUI.read_text(encoding="utf-8")
        linux = LINUX.read_text(encoding="utf-8")
        self.assertIn('exit "$DL4ME_STATUS_UPDATE_COMPLETE"', update)
        self.assertIn('repo_git pull --ff-only', update)
        self.assertIn('puts "__DL4ME_UPDATED__"', gui)
        self.assertIn('if [ "${strarr[0]}" = "__DL4ME_UPDATED__" ]; then', linux)

    def test_update_check_and_optional_cleanup_are_nonfatal(self):
        update = UPDATE.read_text(encoding="utf-8")
        prelaunch = PRELAUNCH.read_text(encoding="utf-8")
        self.assertIn('Update check unavailable', update)
        self.assertIn('exit 0', update)
        self.assertIn('Docker space cleanup could not be completed.', prelaunch)
        self.assertIn('This cleanup is optional, so DL4MicEverywhere will continue normally.', prelaunch)
        self.assertNotIn('pre_build_launch/clean_docker.sh" || exit 1', prelaunch)

    def test_container_exit_status_is_checked(self):
        text = LINUX.read_text(encoding="utf-8")
        self.assertGreaterEqual(text.count('CONTAINER_OUT=$?'), 2)
        self.assertIn('[ "$CONTAINER_OUT" -ne 130 ]', text)
        self.assertIn('[ "$CONTAINER_OUT" -ne 143 ]', text)
        self.assertIn('exit "$DL4ME_STATUS_CONTAINER_RUNTIME_FAILED"', text)

    def test_pause_helper_is_not_recursive(self):
        text = LINUX.read_text(encoding="utf-8")
        start = text.index('pause_native_cli() {')
        end = text.index('\n}', start) + 2
        body = text[start:end]
        self.assertIn('read -r -p "Press enter to close the terminal."', body)
        self.assertEqual(body.count('pause_native_cli'), 1)


class UpdateScriptRuntimeTests(unittest.TestCase):
    def setUp(self):
        self.tempdir = Path(tempfile.mkdtemp(prefix="dl4me-update-test-"))
        self.root = self.tempdir / "repo"
        script_dir = self.root / ".tools" / "bash_tools" / "pre_build_launch"
        script_dir.mkdir(parents=True)
        cache_dir = self.root / ".tools" / ".cache"
        cache_dir.mkdir(parents=True)
        shutil.copy2(UPDATE, script_dir / "update_dl4miceverywhere.sh")
        shutil.copy2(STATUS, self.root / ".tools" / "bash_tools" / "launcher_status.sh")
        (cache_dir / ".cache_preferences").write_text("update : Automatically\n", encoding="utf-8")

        self.fakebin = self.tempdir / "bin"
        self.fakebin.mkdir()
        (self.fakebin / "git").write_text(
            "#!/bin/bash\n"
            "case \" $* \" in\n"
            "  *\" branch --show-current \"*) echo improve_gui; exit 0 ;;\n"
            "  *\" rev-parse HEAD \"*) echo localsha; exit 0 ;;\n"
            "  *\" pull --ff-only \"*) exit \"${FAKE_GIT_PULL_STATUS:-0}\" ;;\n"
            "esac\n"
            "exit 1\n",
            encoding="utf-8",
        )
        (self.fakebin / "curl").write_text(
            "#!/bin/bash\n"
            "if [ \"${FAKE_CURL_EMPTY:-0}\" = 1 ]; then exit 22; fi\n"
            "printf '%s\\n' '{\"sha\":\"remotesha\"}'\n",
            encoding="utf-8",
        )
        os.chmod(self.fakebin / "git", 0o755)
        os.chmod(self.fakebin / "curl", 0o755)
        self.script = script_dir / "update_dl4miceverywhere.sh"

    def tearDown(self):
        shutil.rmtree(self.tempdir)

    def run_update(self, **extra_env):
        env = os.environ.copy()
        env.update(extra_env)
        env["PATH"] = f"{self.fakebin}:/usr/bin:/bin"
        return subprocess.run(
            ["bash", str(self.script), "0", "0"],
            cwd=self.root,
            env=env,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
        )

    def test_successful_automatic_update_returns_93(self):
        result = self.run_update()
        self.assertEqual(result.returncode, 93, result.stdout + result.stderr)
        self.assertIn("updated successfully", result.stdout)

    def test_failed_git_pull_is_reported_but_does_not_crash_launcher(self):
        result = self.run_update(FAKE_GIT_PULL_STATUS="1")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("could not be updated", result.stdout)

    def test_unavailable_update_check_is_nonfatal(self):
        result = self.run_update(FAKE_CURL_EMPTY="1")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("could not reach GitHub", result.stderr)


if __name__ == "__main__":
    unittest.main()
