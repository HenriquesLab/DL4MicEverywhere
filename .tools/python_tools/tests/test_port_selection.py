from pathlib import Path
import os
import shutil
import socket
import subprocess
import tempfile
import unittest


REPO_ROOT = Path(__file__).resolve().parents[3]
SELECTOR = REPO_ROOT / ".tools" / "bash_tools" / "select_notebook_port.sh"
WINDOWS_HELPER = REPO_ROOT / ".tools" / "windows_tools" / "check_windows_port.ps1"
LINUX = REPO_ROOT / "Linux_launch.sh"
WINDOWS = REPO_ROOT / "Windows_launch.bat"
BROWSER = REPO_ROOT / ".tools" / "bash_tools" / "open_browser.sh"
STATUS = REPO_ROOT / ".tools" / "bash_tools" / "launcher_status.sh"


class PortSelectionRuntimeTests(unittest.TestCase):
    def run_selector(self, port, **extra_env):
        env = os.environ.copy()
        env.update(extra_env)
        return subprocess.run(
            ["bash", str(SELECTOR), str(port)],
            cwd=REPO_ROOT,
            env=env,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
        )

    def test_busy_local_port_moves_to_next_port(self):
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        try:
            sock.bind(("127.0.0.1", 8888))
            sock.listen(1)
        except OSError:
            sock.close()
            self.skipTest("Port 8888 is already occupied in the test environment")

        try:
            result = self.run_selector(8888)
        finally:
            sock.close()

        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(result.stdout.strip(), "8889")
        self.assertIn("Port 8888 is already allocated", result.stderr)


    def test_macos_uses_lsof_before_linux_netstat_syntax(self):
        # Stock macOS has BSD netstat and lsof. The selector must prefer lsof
        # because the Linux `netstat -ltn` probe is not portable to macOS.
        with tempfile.TemporaryDirectory(prefix="dl4me-mac-port-test-") as tempdir:
            fakebin = Path(tempdir)
            (fakebin / "lsof").write_text(
                "#!/bin/bash\n"
                "case \" $* \" in\n"
                "  *\" -iTCP:8888 \"*) exit 0 ;;\n"
                "  *) exit 1 ;;\n"
                "esac\n",
                encoding="utf-8",
            )
            (fakebin / "netstat").write_text(
                "#!/bin/bash\nexit 99\n",
                encoding="utf-8",
            )
            os.chmod(fakebin / "lsof", 0o755)
            os.chmod(fakebin / "netstat", 0o755)

            result = self.run_selector(
                8888,
                OSTYPE="darwin",
                PATH=f"{fakebin}:/usr/bin:/bin",
            )

        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(result.stdout.strip(), "8889")
        self.assertIn("Port 8888 is already allocated", result.stderr)

    def test_windows_host_listener_is_checked_even_when_linux_port_is_free(self):
        # Simulate the user's topology: WSL has no listener on 8888, but a native
        # Windows application does. The fake PowerShell helper reports only 8888
        # as occupied, so the selector must choose 8889.
        with tempfile.TemporaryDirectory(prefix="dl4me-port-test-") as tempdir:
            fakebin = Path(tempdir)
            (fakebin / "wslpath").write_text(
                "#!/bin/bash\nprintf '%s\\n' \"$2\"\n",
                encoding="utf-8",
            )
            (fakebin / "powershell.exe").write_text(
                "#!/bin/bash\n"
                "for arg in \"$@\"; do\n"
                "  if [ \"$arg\" = \"8888\" ]; then exit 1; fi\n"
                "done\n"
                "exit 0\n",
                encoding="utf-8",
            )
            os.chmod(fakebin / "wslpath", 0o755)
            os.chmod(fakebin / "powershell.exe", 0o755)

            # Avoid a collision with an unrelated test-environment listener.
            with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as probe:
                try:
                    probe.bind(("127.0.0.1", 8888))
                except OSError:
                    self.skipTest("Port 8888 is already occupied in the test environment")

            env_path = f"{fakebin}:/usr/bin:/bin"
            result = self.run_selector(
                8888,
                DL4ME_WINDOWS_WRAPPER="1",
                PATH=env_path,
            )

        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(result.stdout.strip(), "8889")
        self.assertIn("Port 8888 is already allocated", result.stderr)


class PortSelectionContractTests(unittest.TestCase):
    def test_linux_launcher_uses_shared_bounded_selector(self):
        text = LINUX.read_text(encoding="utf-8")
        self.assertIn('select_notebook_port.sh" "$requested_port"', text)
        self.assertIn('exit "$DL4ME_STATUS_PORT_UNAVAILABLE"', text)
        self.assertNotIn('while ( netstat -a | grep :$port', text)
        self.assertNotIn('while ( lsof -i:$port', text)

        selector = SELECTOR.read_text(encoding="utf-8")
        self.assertIn("PORT_MIN=8000", selector)
        self.assertIn("PORT_MAX=9000", selector)
        self.assertIn('while [ "$attempt" -lt "$PORT_RANGE_SIZE" ]', selector)
        self.assertIn("windows_port_status", selector)

    def test_windows_probe_uses_active_tcp_listener_table(self):
        text = WINDOWS_HELPER.read_text(encoding="utf-8")
        self.assertIn("GetActiveTcpListeners", text)
        self.assertIn("$_.Port -eq $Port", text)

    def test_port_exhaustion_has_a_handled_windows_status(self):
        status = STATUS.read_text(encoding="utf-8")
        windows = WINDOWS.read_text(encoding="utf-8")
        self.assertIn("DL4ME_STATUS_PORT_UNAVAILABLE=104", status)
        self.assertIn('if "%LAUNCH_RESULT%"=="104" goto :port_unavailable', windows)
        self.assertIn(":port_unavailable", windows)
        self.assertIn("could not find a usable notebook port", windows)

    def test_wsl_browser_open_does_not_load_powershell_profile(self):
        text = BROWSER.read_text(encoding="utf-8")
        self.assertIn("powershell.exe -NoProfile -NonInteractive", text)
        self.assertNotIn('export BROWSER="powershell.exe /C start"', text)


if __name__ == "__main__":
    unittest.main()
