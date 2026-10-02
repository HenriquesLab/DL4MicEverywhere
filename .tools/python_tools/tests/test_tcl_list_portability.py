from pathlib import Path
import os
import subprocess
import tempfile
import unittest


REPO_ROOT = Path(__file__).resolve().parents[3]
GUI = REPO_ROOT / ".tools" / "tcl_tools" / "main_gui.tcl"
LIST_UTILS = REPO_ROOT / ".tools" / "tcl_tools" / "list_utils.tcl"


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
            script = r'''
source $::env(DL4ME_LIST_UTILS)
set values [dl4me_immediate_subdirectory_names $::env(DL4ME_LIST_ROOT)]
puts [llength $values]
foreach value $values {
    puts [binary encode hex [encoding convertto utf-8 $value]]
}
'''
            result = subprocess.run(
                ["tclsh"],
                input=script,
                env=env,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                check=False,
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            lines = result.stdout.splitlines()
            self.assertEqual(int(lines[0]), len(names))
            returned = [bytes.fromhex(line).decode("utf-8") for line in lines[1:]]
            self.assertEqual(returned, sorted(names, key=str.casefold))

    def test_word_output_with_braces_and_colons_never_becomes_raw_list_syntax(self):
        env = os.environ.copy()
        env["DL4ME_LIST_UTILS"] = str(LIST_UTILS)
        script = r'''
source $::env(DL4ME_LIST_UTILS)
set values [dl4me_nonempty_words "1.2.3(latest)   {broken}:value\n2.0.0"]
puts [llength $values]
foreach value $values {
    puts [binary encode hex [encoding convertto utf-8 $value]]
}
'''
        result = subprocess.run(
            ["tclsh"],
            input=script,
            env=env,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        lines = result.stdout.splitlines()
        self.assertEqual(int(lines[0]), 3)
        returned = [bytes.fromhex(line).decode("utf-8") for line in lines[1:]]
        self.assertEqual(returned, ["1.2.3(latest)", "{broken}:value", "2.0.0"])


if __name__ == "__main__":
    unittest.main()
