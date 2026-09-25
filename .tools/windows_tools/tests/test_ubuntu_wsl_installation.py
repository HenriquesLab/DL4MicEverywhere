from pathlib import Path
import unittest


REPO_ROOT = Path(__file__).resolve().parents[3]
WINDOWS_LAUNCH = REPO_ROOT / "Windows_launch.bat"
INSTALL_HELPER = REPO_ROOT / ".tools" / "windows_tools" / "install_ubuntu_wsl.ps1"
DISCOVERY_HELPER = REPO_ROOT / ".tools" / "windows_tools" / "discover_ubuntu_wsl.ps1"
READINESS_HELPER = REPO_ROOT / ".tools" / "windows_tools" / "wsl_readiness.ps1"
VERSION_HELPER = REPO_ROOT / ".tools" / "windows_tools" / "check_wsl_distribution_version.ps1"
CONVERSION_HELPER = REPO_ROOT / ".tools" / "windows_tools" / "convert_wsl_distribution_to_v2.ps1"
USER_DISCOVERY_HELPER = REPO_ROOT / ".tools" / "windows_tools" / "discover_ubuntu_user.ps1"
DOCKER_USER_ACCESS_HELPER = REPO_ROOT / ".tools" / "windows_tools" / "ensure_ubuntu_docker_user_access.ps1"
PRE_LAUNCH_TEST = REPO_ROOT / ".tools" / "bash_tools" / "pre_launch_test.sh"


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


    def test_launcher_resolves_and_explicitly_uses_non_root_ubuntu_user(self):
        launcher = WINDOWS_LAUNCH.read_text(encoding="utf-8")
        helper = USER_DISCOVERY_HELPER.read_text(encoding="utf-8")

        self.assertIn('set "UBUNTU_USER="', launcher)
        self.assertIn("discover_ubuntu_user.ps1", launcher)
        self.assertIn("Ubuntu user: %UBUNTU_USER%", launcher)
        self.assertIn("wsl.exe -d %UBUNTU_DISTRO% -u root --cd / --exec /usr/bin/env docker info", launcher)
        self.assertIn("wsl.exe -d %UBUNTU_DISTRO% -u %UBUNTU_USER% --exec /usr/bin/env DL4ME_WINDOWS_WRAPPER=1", launcher)
        self.assertNotIn("wsl.exe -d %UBUNTU_DISTRO% -u %UBUNTU_USER% --exec /usr/bin/env docker info", launcher)
        self.assertNotIn("wsl.exe -d %UBUNTU_DISTRO% --exec /usr/bin/env docker info", launcher)
        self.assertNotIn("wsl.exe -d %UBUNTU_DISTRO% --exec /usr/bin/env DL4ME_WINDOWS_WRAPPER=1", launcher)

        self.assertIn("/etc/wsl.conf", helper)
        self.assertIn("/etc/passwd", helper)
        self.assertIn("--exec /usr/bin/id -u $Name", helper)
        self.assertIn("return ($uid -gt 0)", helper)
        self.assertNotIn("getent passwd 1000", helper)
        self.assertNotIn("$uid -eq 1000", helper)

    def test_docker_integration_probe_is_root_then_user_access_is_verified(self):
        launcher = WINDOWS_LAUNCH.read_text(encoding="utf-8")

        integration_start = launcher.index("\n:check_docker_integration\n")
        launch_start = launcher.index("\n:launch_application\n")
        integration_block = launcher[integration_start:launch_start]
        launch_block = launcher[launch_start:]

        self.assertIn("-u root --cd / --exec /usr/bin/env docker info", integration_block)
        self.assertIn("ensure_ubuntu_docker_user_access.ps1", integration_block)
        self.assertIn("-Distribution %UBUNTU_DISTRO% -User %UBUNTU_USER%", integration_block)
        self.assertIn('DOCKER_USER_ACCESS_RESULT=%ERRORLEVEL%', integration_block)
        self.assertIn("-u %UBUNTU_USER% --exec /usr/bin/env DL4ME_WINDOWS_WRAPPER=1", launch_block)

    def test_docker_user_access_helper_treats_native_permission_denied_as_exit_code(self):
        helper = DOCKER_USER_ACCESS_HELPER.read_text(encoding="utf-8")

        # The first docker-info probe is expected to fail for a user that lacks
        # socket access. Native stderr must not trip the script-wide
        # ErrorActionPreference=Stop before LASTEXITCODE can be classified.
        self.assertIn("$previousErrorActionPreference = $ErrorActionPreference", helper)
        self.assertGreaterEqual(helper.count("$ErrorActionPreference = 'Continue'"), 2)
        self.assertGreaterEqual(helper.count("$exitCode = $LASTEXITCODE"), 2)
        self.assertGreaterEqual(helper.count("$ErrorActionPreference = $previousErrorActionPreference"), 2)

    def test_docker_user_access_helper_repairs_only_standard_docker_group_case(self):
        helper = DOCKER_USER_ACCESS_HELPER.read_text(encoding="utf-8")

        self.assertIn("Test-DockerAccess -RunAs $User", helper)
        self.assertIn("Test-DockerAccess -RunAs 'root'", helper)
        self.assertIn("/var/run/docker.sock", helper)
        self.assertIn("$socketGroup -ne 'docker'", helper)
        self.assertIn("'/usr/sbin/usermod', '-aG', 'docker', $User", helper)
        self.assertIn("Show-DockerAccessConsentDialog", helper)
        self.assertIn("Grant Docker Access", helper)
        self.assertNotIn("chmod 666", helper)
        self.assertNotIn("usermod -aG root", helper)

    def test_windows_wrapped_linux_prelaunch_does_not_offer_to_restart_desktop(self):
        text = PRE_LAUNCH_TEST.read_text(encoding="utf-8")

        self.assertIn('DL4ME_WINDOWS_WRAPPER:-0', text)
        self.assertIn("not a stopped Docker daemon", text)
        wrapper_block = text[text.index('if [[ "${DL4ME_WINDOWS_WRAPPER:-0}"'):text.index('fi\n        /bin/bash "$BASEDIR/pre_build_launch/check_docker_daemon.sh"')]
        self.assertNotIn("docker_desktop_gui.tcl", wrapper_block)


    def test_user_discovery_prefers_wsl_conf_and_only_falls_back_unambiguously(self):
        helper = USER_DISCOVERY_HELPER.read_text(encoding="utf-8")

        self.assertIn("Get-ConfiguredDefaultUser", helper)
        self.assertIn("Get-RegularHomeUsers", helper)
        self.assertIn("-ieq 'user'", helper)
        self.assertIn("(?i:default)", helper)
        self.assertIn("$regularUsers.Count -eq 1", helper)
        self.assertIn("$uid -lt 1000 -or $uid -ge 65534", helper)
        self.assertIn("$home.StartsWith('/home/')", helper)

    def test_user_discovery_distinguishes_uninitialized_from_ambiguous_state(self):
        helper = USER_DISCOVERY_HELPER.read_text(encoding="utf-8")

        self.assertIn("if ($regularUsers.Count -eq 0)", helper)
        self.assertIn("exit 2", helper)
        self.assertIn("exit 3", helper)
        self.assertLess(helper.index("if ($regularUsers.Count -eq 0)"), helper.index("exit 3"))

    def test_launcher_resumes_ubuntu_oobe_only_when_no_regular_user_exists(self):
        launcher = WINDOWS_LAUNCH.read_text(encoding="utf-8")

        verify_block = launcher[
            launcher.index("rem Resolve the configured non-root Linux account explicitly."):
            launcher.index("rem =============================================================================\nrem 2. Docker Desktop discovery")
        ]
        self.assertIn('set "UBUNTU_USER_DISCOVERY_RESULT=%ERRORLEVEL%"', verify_block)
        self.assertIn('if "%UBUNTU_USER_DISCOVERY_RESULT%"=="2" goto :ubuntu_user_setup_required', verify_block)
        self.assertIn('if not "%UBUNTU_USER_DISCOVERY_RESULT%"=="0" goto :ubuntu_user_not_ready', verify_block)

        recovery_start = launcher.index("\n:ubuntu_user_setup_required\n")
        recovery_end = launcher.index("\n:ubuntu_user_not_ready\n")
        recovery = launcher[recovery_start:recovery_end]
        self.assertIn("wsl.exe -d %UBUNTU_DISTRO%", recovery)
        self.assertIn("call :discover_ubuntu_user", recovery)
        self.assertIn("goto :ubuntu_user_setup_still_incomplete", recovery)
        self.assertNotIn("goto :verify_ubuntu", recovery)

    def test_launcher_preserves_user_discovery_helper_exit_code(self):
        launcher = WINDOWS_LAUNCH.read_text(encoding="utf-8")
        start = launcher.index("\n:discover_ubuntu_user\n")
        end = launcher.index("\n:discover_docker\n")
        block = launcher[start:end]

        self.assertIn('> "%UBUNTU_USER_OUTPUT%"', block)
        self.assertIn('set "UBUNTU_USER_DISCOVERY_RESULT=%ERRORLEVEL%"', block)
        self.assertIn('exit /b %UBUNTU_USER_DISCOVERY_RESULT%', block)


    def test_install_helper_normalizes_listed_distro_and_probes_from_root(self):
        text = INSTALL_HELPER.read_text(encoding="utf-8")
        self.assertIn("Normalize-WslDistributionName", text)
        self.assertIn("Replace([string][char]0, '')", text)
        self.assertIn("--user root --cd / --exec /bin/true", text)


if __name__ == "__main__":
    unittest.main()
