from pathlib import Path
import os
import re
import subprocess
import tempfile
import unittest

REPO_ROOT = Path(__file__).resolve().parents[3]
LINUX_LAUNCH = REPO_ROOT / "Linux_launch.sh"


class JupyterExitPreservationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        text = LINUX_LAUNCH.read_text(encoding="utf-8")
        match = re.search(r'^\s*docker_command=".*JUPYTER_OUT=.*"\s*$', text, re.MULTILINE)
        if not match:
            raise AssertionError("Could not find the Jupyter docker_command assignment")
        cls.assignment = match.group(0).strip()

    def _render_command(self):
        script = (
            'port=8888\n'
            'notebook_token=testtoken\n'
            "notebook_name='Test Notebook.ipynb'\n"
            f'{self.assignment}\n'
            "printf '%s' \"$docker_command\"\n"
        )
        result = subprocess.run(
            ["bash", "-c", script],
            check=True,
            capture_output=True,
            text=True,
        )
        return result.stdout

    def _run_generated_command(self, jupyter_exit, cp_exit):
        command = self._render_command()
        with tempfile.TemporaryDirectory(prefix="dl4me-jupyter-status-") as tempdir:
            temp = Path(tempdir)
            fakebin = temp / "bin"
            fakebin.mkdir()
            cp_log = temp / "cp.log"

            (fakebin / "jupyter").write_text(
                "#!/bin/bash\nexit \"${FAKE_JUPYTER_EXIT:?}\"\n",
                encoding="utf-8",
            )
            (fakebin / "cp").write_text(
                "#!/bin/bash\n"
                "printf '%s\\n' \"$*\" >> \"${FAKE_CP_LOG:?}\"\n"
                "exit \"${FAKE_CP_EXIT:?}\"\n",
                encoding="utf-8",
            )
            os.chmod(fakebin / "jupyter", 0o755)
            os.chmod(fakebin / "cp", 0o755)

            env = os.environ.copy()
            env.update(
                {
                    "PATH": f"{fakebin}:{env.get('PATH', '')}",
                    "FAKE_JUPYTER_EXIT": str(jupyter_exit),
                    "FAKE_CP_EXIT": str(cp_exit),
                    "FAKE_CP_LOG": str(cp_log),
                }
            )
            result = subprocess.run(
                ["bash", "-c", command],
                capture_output=True,
                text=True,
                env=env,
            )
            cp_calls = cp_log.read_text(encoding="utf-8").splitlines() if cp_log.exists() else []
            return result, cp_calls

    def test_generated_command_captures_jupyter_status_before_copying(self):
        command = self._render_command()
        self.assertIn("JUPYTER_OUT=$?", command)
        self.assertIn('exit "$JUPYTER_OUT"', command)
        self.assertLess(command.index("JUPYTER_OUT=$?"), command.index("cp /home/docker_info.txt"))
        self.assertLess(command.index("cp /home/docker_info.txt"), command.index('exit "$JUPYTER_OUT"'))

    def test_jupyter_failure_is_not_hidden_by_successful_copies(self):
        result, cp_calls = self._run_generated_command(jupyter_exit=7, cp_exit=0)
        self.assertEqual(result.returncode, 7)
        self.assertEqual(len(cp_calls), 2)

    def test_copy_failures_do_not_replace_successful_jupyter_status(self):
        result, cp_calls = self._run_generated_command(jupyter_exit=0, cp_exit=9)
        self.assertEqual(result.returncode, 0)
        self.assertEqual(len(cp_calls), 2)
        self.assertIn("Could not copy docker_info.txt", result.stderr)
        self.assertIn("Could not copy the notebook", result.stderr)

    def test_normal_sigint_style_jupyter_exit_is_preserved(self):
        result, cp_calls = self._run_generated_command(jupyter_exit=130, cp_exit=0)
        self.assertEqual(result.returncode, 130)
        self.assertEqual(len(cp_calls), 2)


if __name__ == "__main__":
    unittest.main()
