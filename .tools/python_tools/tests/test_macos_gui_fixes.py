from pathlib import Path
import os
import re
import shutil
import subprocess
import sys
import tempfile
import unittest


REPO_ROOT = Path(__file__).resolve().parents[3]
MAIN_GUI = REPO_ROOT / ".tools" / "tcl_tools" / "main_gui.tcl"
EXEC_UTILS = REPO_ROOT / ".tools" / "tcl_tools" / "exec_utils.tcl"
ABOUT = REPO_ROOT / ".tools" / "tcl_tools" / "menubar" / "about.tcl"
MAC_ENV = REPO_ROOT / ".tools" / "bash_tools" / "macos_env.sh"
PATH_UTILS = REPO_ROOT / ".tools" / "bash_tools" / "path_utils.sh"
REQUIREMENTS = REPO_ROOT / ".tools" / "bash_tools" / "requirements_installation.sh"
TCL_TOOLS = REPO_ROOT / ".tools" / "tcl_tools"
WINDOW_UTILS = TCL_TOOLS / "window_utils.tcl"
BASH_TOOLS = REPO_ROOT / ".tools" / "bash_tools"
GUI_UTILS = BASH_TOOLS / "gui_utils.sh"


class TclChildProcessTests(unittest.TestCase):
    def test_gui_child_processes_tolerate_stderr_noise(self):
        text = MAIN_GUI.read_text(encoding="utf-8")
        self.assertIn("source [file join $basedir .tools tcl_tools exec_utils.tcl]", text)
        # Every child process launched by the GUI goes through dl4me_exec, except
        # commands that already merge stderr into their output (`2>@1`) and
        # background commands (`&`) whose output is never inspected. The GPU probe
        # is owned by the GPU-capability check and treats any failure as "no GPU".
        for line in text.splitlines():
            stripped = line.strip()
            if re.search(r"\bexec\b", stripped) and not stripped.startswith("#"):
                with self.subTest(line=stripped):
                    self.assertTrue(
                        "dl4me_exec" in stripped
                        or "2>@1" in stripped
                        or stripped.endswith("&")
                        or "nvidia-smi" in stripped,
                        "GUI child processes must use dl4me_exec",
                    )
        self.assertIn('-message "The uninstall confirmation window could not be opened." \\\n            -detail', text)

    def test_exec_helper_ignores_stderr_but_not_exit_status(self):
        text = EXEC_UTILS.read_text(encoding="utf-8")
        self.assertIn("exec -ignorestderr -- {*}$args", text)
        self.assertIn("-ignorestderr", ABOUT.read_text(encoding="utf-8"))

    @unittest.skipUnless(shutil.which("tclsh"), "tclsh is not installed")
    def test_exec_helper_runtime(self):
        script = (
            f'source "{EXEC_UTILS.as_posix()}"\n'
            'puts [dl4me_exec sh -c "echo noise >&2; echo ok"]\n'
            'if {[catch {dl4me_exec sh -c "exit 3"} msg options]} {\n'
            '    puts [lindex [dict get $options -errorcode] 0]-[lindex [dict get $options -errorcode] 2]\n'
            '}\n'
        )
        result = subprocess.run(["tclsh"], input=script, text=True, capture_output=True, check=False)
        self.assertEqual(result.stdout.split(), ["ok", "CHILDSTATUS-3"], result.stderr)


class MacOSWishSelectionTests(unittest.TestCase):
    def test_requirements_reject_system_tk_on_macos(self):
        text = REQUIREMENTS.read_text(encoding="utf-8")
        self.assertIn("dl4me_macos_wish_usable", text)
        self.assertIn("if ! wish_is_usable; then", text)
        env = MAC_ENV.read_text(encoding="utf-8")
        self.assertIn("/usr/bin/*|/System/Library/*", env)

    @unittest.skipIf(sys.platform.startswith("win"), "Runtime check uses POSIX paths")
    def test_wish_usability_by_location(self):
        with tempfile.TemporaryDirectory() as td:
            brew_bin = Path(td) / "homebrew" / "bin"
            brew_bin.mkdir(parents=True)
            fake_wish = brew_bin / "wish"
            fake_wish.write_text("#!/bin/sh\nexit 0\n", encoding="utf-8")
            os.chmod(fake_wish, 0o755)

            def usable(path_value):
                command = (
                    f'source "{PATH_UTILS}"; source "{MAC_ENV}"; '
                    'dl4me_macos_wish_usable && echo yes || echo no'
                )
                env = os.environ.copy()
                env["PATH"] = path_value
                result = subprocess.run(["bash", "-c", command], env=env, text=True,
                                        capture_output=True, check=False)
                return result.stdout.strip()

            self.assertEqual(usable(f"{brew_bin}:/usr/bin:/bin"), "yes")
            if Path("/usr/bin/wish").exists():
                self.assertEqual(usable("/usr/bin:/bin"), "no")


class DialogInFrontTests(unittest.TestCase):
    # Since macOS 14 a wish process started from Terminal cannot activate
    # itself, so its dialog opened behind the Terminal window.
    def test_every_dialog_is_brought_to_front(self):
        libraries = {"exec_utils.tcl", "list_utils.tcl", "window_utils.tcl"}
        dialogs = [p for p in TCL_TOOLS.rglob("*.tcl") if p.name not in libraries]
        self.assertEqual(len(dialogs), 14)
        for dialog in dialogs:
            with self.subTest(dialog=dialog.name):
                text = dialog.read_text(encoding="utf-8")
                self.assertIn("window_utils.tcl]", text)
                self.assertIn("\ndl4me_bring_to_front\n", text)
        helper = WINDOW_UTILS.read_text(encoding="utf-8")
        self.assertIn("wm attributes $w -topmost 1", helper)
        self.assertIn("bind $w <ButtonPress> +", helper)

    def test_every_wish_call_tells_the_terminal(self):
        scripts = [REPO_ROOT / "Linux_launch.sh", *(p for p in BASH_TOOLS.rglob("*.sh") if p != GUI_UTILS)]
        calls = 0
        for script in scripts:
            lines = script.read_text(encoding="utf-8").splitlines()
            for index, line in enumerate(lines):
                if not re.search(r'(^|\$\()\s*(dl4me_)?wish "', line.strip()):
                    continue
                calls += 1
                with self.subTest(script=script.name, line=index + 1):
                    announced = "dl4me_wish" in line or lines[index - 1].strip() == "dl4me_announce_dialog"
                    self.assertTrue(announced, line)
                    self.assertIn('/gui_utils.sh" || exit 1', "\n".join(lines))
        self.assertEqual(calls, 15)

    @unittest.skipIf(sys.platform.startswith("win"), "Runtime check uses POSIX bash")
    def test_hint_goes_to_stderr_on_macos_only(self):
        def run(ostype):
            command = f'source "{GUI_UTILS}"; OSTYPE={ostype}; wish() {{ echo answer; }}; dl4me_wish x'
            return subprocess.run(["bash", "-c", command], text=True, capture_output=True, check=False)

        mac = run("darwin23")
        self.assertEqual(mac.stdout, "answer\n")
        self.assertIn("window is waiting for your answer", mac.stderr)
        linux = run("linux-gnu")
        self.assertEqual((linux.stdout, linux.stderr), ("answer\n", ""))


if __name__ == "__main__":
    unittest.main()
