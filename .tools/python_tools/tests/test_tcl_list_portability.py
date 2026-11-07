from pathlib import Path
import os
import subprocess
import tempfile
import unittest


REPO_ROOT = Path(__file__).resolve().parents[3]
GUI = REPO_ROOT / ".tools" / "tcl_tools" / "main_gui.tcl"
LIST_UTILS = REPO_ROOT / ".tools" / "tcl_tools" / "list_utils.tcl"

# Prints the list length, then each element as UTF-8 hex. `binary scan ... H*`
# also works on Tcl 8.5 (the macOS system tclsh); `binary encode` needs 8.6.
PRINT_LIST = r'''
puts [llength $values]
foreach value $values {
    binary scan [encoding convertto utf-8 $value] H* hex
    puts $hex
}
'''


def run_tcl(script, env):
    """Run a Tcl script from a file so that any Tcl error fails the process.

    tclsh reading a script from stdin reports errors but still exits 0.
    """
    with tempfile.TemporaryDirectory() as td:
        path = Path(td) / "check.tcl"
        path.write_text(script, encoding="utf-8")
        return subprocess.run(["tclsh", str(path)], env=env, text=True,
                              stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)


def decoded_values(result):
    lines = result.stdout.splitlines()
    return int(lines[0]), [bytes.fromhex(line).decode("utf-8") for line in lines[1:]]


class TclListPortabilityTests(unittest.TestCase):
    def test_gui_does_not_build_selector_lists_from_find_or_xargs_output(self):
        text = GUI.read_text(encoding="utf-8")
        self.assertIn("source [file join $basedir .tools tcl_tools list_utils.tcl]", text)
        self.assertNotIn("exec find", text)
        self.assertNotIn("xargs -0", text)
        self.assertNotIn('append folderList " "', text)
        self.assertNotIn('append notebookList " "', text)
        self.assertNotIn('append versionList " "', text)
        self.assertNotIn("no_folders_flag_flag", text)

    def test_directory_names_are_returned_as_real_tcl_list_elements(self):
        with tempfile.TemporaryDirectory(prefix="dl4me Tcl list path ") as td:
            root = Path(td)
            names = [
                "Alpha folder",
                "{brace}:suffix",
                "normal_folder",
                "Zeta",
            ]
            for name in names:
                (root / name).mkdir()
            (root / "not-a-directory.txt").write_text("x", encoding="utf-8")

            env = os.environ.copy()
            env["DL4ME_LIST_UTILS"] = str(LIST_UTILS)
            env["DL4ME_LIST_ROOT"] = str(root)
            result = run_tcl(
                "source $::env(DL4ME_LIST_UTILS)\n"
                "set values [dl4me_immediate_subdirectory_names $::env(DL4ME_LIST_ROOT)]\n" + PRINT_LIST,
                env,
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            count, returned = decoded_values(result)
            self.assertEqual(count, len(names))
            self.assertEqual(returned, sorted(names, key=str.casefold))

    def test_word_output_with_braces_and_colons_never_becomes_raw_list_syntax(self):
        env = os.environ.copy()
        env["DL4ME_LIST_UTILS"] = str(LIST_UTILS)
        result = run_tcl(
            "source $::env(DL4ME_LIST_UTILS)\n"
            'set values [dl4me_nonempty_words "1.2.3(latest)   {broken}:value\\n2.0.0"]\n' + PRINT_LIST,
            env,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        count, returned = decoded_values(result)
        self.assertEqual(count, 3)
        self.assertEqual(returned, ["1.2.3(latest)", "{broken}:value", "2.0.0"])


if __name__ == "__main__":
    unittest.main()
