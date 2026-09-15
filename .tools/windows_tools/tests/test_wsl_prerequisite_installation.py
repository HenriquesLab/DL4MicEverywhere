from pathlib import Path
import unittest


REPO_ROOT = Path(__file__).resolve().parents[3]
WINDOWS_LAUNCH = REPO_ROOT / "Windows_launch.bat"
VERSION_CHECKER = REPO_ROOT / ".tools" / "windows_tools" / "check_wsl_version.ps1"
WSL_HELPER = REPO_ROOT / ".tools" / "windows_tools" / "install_or_update_wsl.ps1"


class WslPrerequisiteInstallationTests(unittest.TestCase):
    def test_version_checker_distinguishes_missing_from_outdated_wsl(self):
        text = VERSION_CHECKER.read_text(encoding="utf-8")
        self.assertIn("exit 2", text)
        self.assertIn("exit 3", text)
        self.assertIn("Test-LegacyWslRuntime", text)
        self.assertIn("wsl.exe --status", text)
        self.assertIn("wsl.exe --list --quiet", text)
        self.assertIn("Get-Command wsl.exe", text)

    def test_launcher_routes_missing_and_outdated_states_separately(self):
        text = WINDOWS_LAUNCH.read_text(encoding="utf-8")
        self.assertIn('if "%WSL_VERSION_RESULT%"=="2" goto :wsl_update_required', text)
        self.assertIn('if "%WSL_VERSION_RESULT%"=="3" goto :wsl_not_installed', text)
        self.assertIn(":wsl_detection_failed", text)
        self.assertNotIn('if not "%WSL_VERSION_RESULT%"=="0" goto :wsl_update_required', text)

    def test_launcher_uses_dedicated_wsl_prerequisite_helper(self):
        text = WINDOWS_LAUNCH.read_text(encoding="utf-8")
        self.assertIn("install_or_update_wsl.ps1", text)
        self.assertIn("-Operation Install", text)
        self.assertIn("-Operation Update", text)
        self.assertIn(":wsl_restart_required", text)
        self.assertIn(":wsl_restart_scheduled", text)

    def test_wsl_install_uses_official_no_distribution_path(self):
        text = WSL_HELPER.read_text(encoding="utf-8")
        self.assertIn("@('--install', '--no-distribution')", text)
        self.assertIn("@('--update')", text)
        self.assertIn("--web-download", text)
        self.assertNotIn("Add-AppxPackage", text)
        self.assertNotIn("Enable-WindowsOptionalFeature", text)
        self.assertNotIn("dism.exe", text.lower())

    def test_only_wsl_command_is_elevated(self):
        text = WSL_HELPER.read_text(encoding="utf-8")
        self.assertIn("Start-Process -FilePath $wslPath", text)
        self.assertIn("-Verb RunAs", text)
        self.assertIn("-Wait", text)
        self.assertIn("-PassThru", text)
        self.assertNotIn("Start-Process -FilePath 'powershell", text)

    def test_update_is_attempted_without_elevation_first(self):
        text = WSL_HELPER.read_text(encoding="utf-8")
        self.assertIn("Invoke-WslCurrentUser", text)
        self.assertIn("Trying Microsoft's WSL update as the current Windows user", text)
        self.assertIn("Retrying with Administrator permission", text)

    def test_helper_requires_explicit_consent_before_uac(self):
        text = WSL_HELPER.read_text(encoding="utf-8")
        consent_pos = text.index("Show-WslConsentDialog")
        main_consent_pos = text.index("if (-not (Show-WslConsentDialog", consent_pos)
        elevated_pos = text.index("Invoke-ElevatedWsl", main_consent_pos)
        self.assertLess(main_consent_pos, elevated_pos)
        self.assertIn("Install WSL", text)
        self.assertIn("Update WSL", text)

    def test_helper_handles_reboot_required_and_optional_restart(self):
        text = WSL_HELPER.read_text(encoding="utf-8")
        self.assertIn("@(3010, 1641)", text)
        self.assertIn("Request-WindowsRestart", text)
        self.assertIn("shutdown.exe /r /t 0", text)
        self.assertIn("return 20", text)
        self.assertIn("return 12", text)

    def test_launcher_handles_all_prerequisite_result_codes(self):
        text = WINDOWS_LAUNCH.read_text(encoding="utf-8")
        for code in ("0", "2", "10", "11", "12", "13", "20"):
            self.assertIn(f'"%WSL_PREREQUISITE_RESULT%"=="{code}"', text)

    def test_wsl_install_does_not_install_ubuntu_itself(self):
        text = WSL_HELPER.read_text(encoding="utf-8")
        self.assertNotIn("Ubuntu-24.04", text)
        self.assertNotIn("--distribution", text)
        self.assertIn("--no-distribution", text)


if __name__ == "__main__":
    unittest.main()
