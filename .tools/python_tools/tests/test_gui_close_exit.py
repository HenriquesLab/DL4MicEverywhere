from pathlib import Path
import unittest


REPO_ROOT = Path(__file__).resolve().parents[3]
LINUX_LAUNCH = REPO_ROOT / "Linux_launch.sh"
WINDOWS_LAUNCH = REPO_ROOT / "Windows_launch.bat"
GUI_SCRIPT = REPO_ROOT / ".tools" / "tcl_tools" / "main_gui.tcl"


class GuiCloseExitTests(unittest.TestCase):
    def test_gui_close_emits_explicit_success_marker(self):
        text = GUI_SCRIPT.read_text(encoding="utf-8")
        self.assertIn('proc onCancel {} {', text)
        self.assertIn('puts "__DL4ME_CANCEL__"', text)
        self.assertIn('wm protocol . WM_DELETE_WINDOW onCancel', text)
        self.assertIn('ttk::button .fr.cb -text "Close" -command { onCancel }', text)
        self.assertNotIn('ttk::button .fr.cb -text "Close" -command { exit 1 }', text)

    def test_linux_launcher_returns_windows_control_code_for_cancel(self):
        text = LINUX_LAUNCH.read_text(encoding="utf-8")
        self.assertIn('gui_result=$?', text)
        self.assertIn('if [ "$gui_result" -ne 0 ]; then', text)
        self.assertIn('if [ "${strarr[0]}" = "__DL4ME_CANCEL__" ]; then', text)
        self.assertIn('controlled_exit() {', text)
        self.assertIn('controlled_exit "$DL4ME_STATUS_GUI_CLOSED"', text)
        self.assertIn('DL4ME_STATUS_GUI_CLOSED=92', (REPO_ROOT / ".tools" / "bash_tools" / "launcher_status.sh").read_text(encoding="utf-8"))
        self.assertIn('GUI exited without returning a launcher result.', text)

    def test_windows_wrapper_explains_normal_gui_close_and_waits(self):
        text = WINDOWS_LAUNCH.read_text(encoding="utf-8")
        self.assertIn('if "%LAUNCH_RESULT%"=="92" goto :gui_closed', text)
        self.assertIn(':gui_closed', text)
        self.assertIn('DL4MicEverywhere closed normally', text)
        self.assertIn('No error occurred', text)
        self.assertIn('Docker Desktop is left running intentionally.', text)
        self.assertIn('Press any key to close this window...', text)
        self.assertIn('pause >nul', text)
        self.assertIn('exit /b 0', text)


if __name__ == "__main__":
    unittest.main()
