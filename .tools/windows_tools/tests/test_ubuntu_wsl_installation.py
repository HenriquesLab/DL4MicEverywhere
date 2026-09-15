from pathlib import Path
import unittest


REPO_ROOT = Path(__file__).resolve().parents[3]
WINDOWS_LAUNCH = REPO_ROOT / "Windows_launch.bat"
INSTALL_HELPER = REPO_ROOT / ".tools" / "windows_tools" / "install_ubuntu_wsl.ps1"
DISCOVERY_HELPER = REPO_ROOT / ".tools" / "windows_tools" / "discover_ubuntu_wsl.ps1"
READINESS_HELPER = REPO_ROOT / ".tools" / "windows_tools" / "wsl_readiness.ps1"
VERSION_HELPER = REPO_ROOT / ".tools" / "windows_tools" / "check_wsl_distribution_version.ps1"
CONVERSION_HELPER = REPO_ROOT / ".tools" / "windows_tools" / "convert_wsl_distribution_to_v2.ps1"


class UbuntuWslInstallationTests(unittest.TestCase):
    def test_launcher_prefers_ubuntu_2404_and_invokes_helper(self):
        text = WINDOWS_LAUNCH.read_text(encoding="utf-8")
        self.assertIn('PREFERRED_UBUNTU_DISTRO=Ubuntu-24.04', text)
        self.assertIn('install_ubuntu_wsl.ps1', text)
        self.assertIn(':discover_ubuntu', text)
        self.assertIn(':verify_ubuntu', text)
        self.assertLess(text.index(':check_wsl'), text.index(':check_docker'))

    def test_helper_uses_official_wsl_installation_flow(self):
        text = INSTALL_HELPER.read_text(encoding="utf-8")
        self.assertIn("Ubuntu-24.04", text)
        self.assertIn("& wsl.exe --list --online", text)
        self.assertIn("'--install', '--distribution'", text)
        self.assertIn("'--no-launch'", text)
        self.assertIn("'--web-download'", text)
        self.assertNotIn("Add-AppxPackage", text)
        self.assertNotIn("--set-default", text)

    def test_helper_requires_explicit_user_consent(self):
        text = INSTALL_HELPER.read_text(encoding="utf-8")
        self.assertIn("Show-UbuntuConsentDialog", text)
        self.assertIn("Install Ubuntu", text)
        self.assertIn("installation was cancelled by the user", text)

    def test_launcher_handles_helper_result_codes(self):
        text = WINDOWS_LAUNCH.read_text(encoding="utf-8")
        for code in ("0", "2", "10", "11", "12", "13", "14", "15"):
            self.assertIn(f'"%UBUNTU_INSTALL_RESULT%"=="{code}"', text)

    def test_discovery_is_normalized_in_powershell(self):
        launcher = WINDOWS_LAUNCH.read_text(encoding="utf-8")
        helper = DISCOVERY_HELPER.read_text(encoding="utf-8")

        self.assertIn("discover_ubuntu_wsl.ps1", launcher)
        self.assertNotIn('findstr /i /x /c:"%PREFERRED_UBUNTU_DISTRO%"', launcher)
        self.assertNotIn('findstr /i /b /c:"Ubuntu"', launcher)
        self.assertIn("--list --quiet", helper)
        self.assertIn("Replace([string][char]0, '')", helper)
        self.assertIn("TrimStart([char]0xFEFF)", helper)
        self.assertIn("-ieq $PreferredDistribution", helper)

    def test_fresh_install_uses_known_distribution_name_without_rediscovery(self):
        text = WINDOWS_LAUNCH.read_text(encoding="utf-8")
        block = text[text.index("\n:ubuntu_install_completed\n"):text.index("\n:ubuntu_install_cancelled\n")]
        self.assertIn('set "UBUNTU_DISTRO=%PREFERRED_UBUNTU_DISTRO%"', block)
        self.assertNotIn("call :discover_ubuntu", block)

    def test_readiness_probe_uses_linux_root_and_preserves_diagnostics(self):
        launcher = WINDOWS_LAUNCH.read_text(encoding="utf-8")
        readiness = READINESS_HELPER.read_text(encoding="utf-8")

        self.assertIn("wsl_readiness.ps1", launcher)
        self.assertIn('type "%TEMP%\\dl4me_wsl_probe_stderr.txt"', launcher)
        self.assertIn("--user root --cd / --exec /bin/true", readiness)
        self.assertIn('1> $StdoutPath 2> $StderrPath', readiness)


    def test_wsl2_detection_uses_verbose_wsl_metadata_not_kernel_grep(self):
        launcher = WINDOWS_LAUNCH.read_text(encoding="utf-8")
        helper = VERSION_HELPER.read_text(encoding="utf-8")

        self.assertIn("check_wsl_distribution_version.ps1", launcher)
        self.assertNotIn("/proc/sys/kernel/osrelease", launcher)
        self.assertNotIn("microsoft-standard|WSL2", launcher)
        self.assertIn("--list --verbose", helper)
        self.assertIn("Replace([string][char]0, '')", helper)
        self.assertIn("$version -eq '2'", helper)
        self.assertIn("$version -eq '1'", helper)

    def test_fresh_install_explicitly_configures_ubuntu_as_wsl2(self):
        helper = INSTALL_HELPER.read_text(encoding="utf-8")
        self.assertIn("& wsl.exe --set-version $Distribution 2", helper)
        self.assertIn("exit 14", helper)

    def test_existing_wsl1_distro_can_be_converted_automatically(self):
        launcher = WINDOWS_LAUNCH.read_text(encoding="utf-8")
        helper = CONVERSION_HELPER.read_text(encoding="utf-8")

        self.assertIn(":ubuntu_convert_to_wsl2", launcher)
        self.assertIn("convert_wsl_distribution_to_v2.ps1", launcher)
        self.assertIn("& wsl.exe --set-version $Distribution 2", helper)
        self.assertIn("MessageBoxButtons]::YesNo", helper)

    def test_official_ubuntu_discovery_does_not_accept_space_names(self):
        helper = DISCOVERY_HELPER.read_text(encoding="utf-8")
        self.assertIn("^Ubuntu(?:$|-[0-9].*)", helper)
        self.assertNotIn("^Ubuntu(?:$|[- ])", helper)

    def test_launcher_does_not_wrap_normalized_distro_tokens_in_cmd_quotes(self):
        launcher = WINDOWS_LAUNCH.read_text(encoding="utf-8")
        self.assertNotIn('-Distro "%UBUNTU_DISTRO%"', launcher)
        self.assertNotIn('-Distribution "%UBUNTU_DISTRO%"', launcher)
        self.assertNotIn('-d "%UBUNTU_DISTRO%"', launcher)
        self.assertIn('-Distro %UBUNTU_DISTRO%', launcher)
        self.assertIn('-Distribution %UBUNTU_DISTRO%', launcher)
        self.assertIn('-d %UBUNTU_DISTRO%', launcher)


    def test_install_helper_normalizes_listed_distro_and_probes_from_root(self):
        text = INSTALL_HELPER.read_text(encoding="utf-8")
        self.assertIn("Normalize-WslDistributionName", text)
        self.assertIn("Replace([string][char]0, '')", text)
        self.assertIn("--user root --cd / --exec /bin/true", text)


if __name__ == "__main__":
    unittest.main()
