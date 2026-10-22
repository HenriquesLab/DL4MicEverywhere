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


if __name__ == "__main__":
    unittest.main()
