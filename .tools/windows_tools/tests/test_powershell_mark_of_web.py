from pathlib import Path
import re
import unittest


REPO_ROOT = Path(__file__).resolve().parents[3]
WINDOWS_LAUNCH = REPO_ROOT / "Windows_launch.bat"


class PowerShellMarkOfWebTests(unittest.TestCase):
    def setUp(self):
        self.text = WINDOWS_LAUNCH.read_text(encoding="utf-8")

    def test_bootstrap_runs_before_first_script_file(self):
        prepare = self.text.index("call :prepare_powershell_helpers")
        first_file = self.text.index(" -File ")
        self.assertLess(prepare, first_file)
        self.assertIn('set "DL4ME_WINDOWS_TOOLS=%BASEDIR%\\.tools\\windows_tools"', self.text)

    def test_bootstrap_recursively_unblocks_and_verifies_helpers(self):
        start = self.text.index("\n:prepare_powershell_helpers\n")
        end = self.text.index("\n:discover_ubuntu\n")
        block = self.text[start:end]

        self.assertIn("Get-ChildItem -LiteralPath $env:DL4ME_WINDOWS_TOOLS -Recurse", block)
        self.assertIn("-Filter '*.ps1' -File", block)
        self.assertIn("Unblock-File -LiteralPath $file.FullName", block)
        self.assertIn("-Stream Zone.Identifier", block)
        self.assertIn("Remove-Item -LiteralPath $file.FullName -Stream Zone.Identifier", block)
        self.assertGreaterEqual(block.count("Get-Item -LiteralPath $file.FullName -Stream Zone.Identifier"), 3)
        self.assertIn("if ($blocked.Count -gt 0)", block)
        self.assertIn("exit 3", block)

    def test_managed_signing_policies_are_not_bypassed(self):
        start = self.text.index("\n:prepare_powershell_helpers\n")
        end = self.text.index("\n:discover_ubuntu\n")
        block = self.text[start:end]

        self.assertIn("Get-ExecutionPolicy", block)
        self.assertIn("'AllSigned'", block)
        self.assertIn("'Restricted'", block)
        self.assertIn("exit 2", block)
        self.assertNotIn("Set-ExecutionPolicy", block)

    def test_launcher_routes_bootstrap_outcomes_before_wsl(self):
        preflight = self.text[: self.text.index("\n:check_wsl\n")]
        self.assertIn('if "%POWERSHELL_HELPER_RESULT%"=="0" goto :check_wsl', preflight)
        self.assertIn('if "%POWERSHELL_HELPER_RESULT%"=="2" goto :powershell_policy_unsupported', preflight)
        self.assertIn('if "%POWERSHELL_HELPER_RESULT%"=="3" goto :powershell_helpers_still_blocked', preflight)
        self.assertIn("goto :powershell_helpers_unavailable", preflight)

    def test_every_powershell_file_invocation_occurs_after_bootstrap_definition(self):
        # The launcher may contain the inline bootstrap itself before :check_wsl,
        # but no `-File` invocation is allowed ahead of its call site.
        prefix = self.text[: self.text.index("call :prepare_powershell_helpers")]
        self.assertNotRegex(prefix, re.compile(r"powershell(?:\.exe)?[^\r\n]*\s-File\s", re.IGNORECASE))


if __name__ == "__main__":
    unittest.main()
