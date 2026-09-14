from pathlib import Path
import unittest


REPO_ROOT = Path(__file__).resolve().parents[3]
WINDOWS_LAUNCH = REPO_ROOT / "Windows_launch.bat"
INSTALL_HELPER = REPO_ROOT / ".tools" / "windows_tools" / "install_docker_desktop_per_user.ps1"
DAEMON_HELPER = REPO_ROOT / ".tools" / "bash_tools" / "pre_build_launch" / "check_docker_daemon.sh"


class PerUserDockerInstallationTests(unittest.TestCase):
    def test_windows_launcher_checks_wsl_before_docker(self):
        text = WINDOWS_LAUNCH.read_text(encoding="utf-8")
        self.assertLess(text.index(":check_wsl"), text.index(":check_docker"))
        self.assertIn("check_wsl_version.ps1", text)
        self.assertIn("%LOCALAPPDATA%\\Programs\\DockerDesktop\\Docker Desktop.exe", text)
        self.assertIn("C:\\Program Files\\Docker\\Docker\\Docker Desktop.exe", text)

    def test_installer_uses_non_elevated_per_user_mode(self):
        text = INSTALL_HELPER.read_text(encoding="utf-8")
        for required in (
            "--user",
            "--backend=wsl-2",
            "--accept-license",
            "--no-windows-containers",
            "Get-AuthenticodeSignature",
            "desktop.docker.com/win/main/amd64/",
            "desktop.docker.com/win/main/arm64/",
        ):
            self.assertIn(required, text)
        self.assertNotIn("--always-run-service", text)
        self.assertNotIn("RunAs", text)

    def test_license_acceptance_is_explicit(self):
        text = INSTALL_HELPER.read_text(encoding="utf-8")
        self.assertIn("I have read and agree", text)
        self.assertIn("Agree and Install", text)
        self.assertIn("Docker Subscription Service Agreement", text)

    def test_wsl_daemon_helper_supports_per_user_desktop(self):
        text = DAEMON_HELPER.read_text(encoding="utf-8")
        self.assertIn("%LOCALAPPDATA%", text)
        self.assertIn("Programs/DockerDesktop/Docker Desktop.exe", text)
        self.assertIn("/mnt/c/Program Files/Docker/Docker/Docker Desktop.exe", text)


if __name__ == "__main__":
    unittest.main()
