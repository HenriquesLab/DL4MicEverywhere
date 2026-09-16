from pathlib import Path
import os
import subprocess
import tempfile
import textwrap
import unittest


REPO_ROOT = Path(__file__).resolve().parents[3]
CLEAN_SCRIPT = REPO_ROOT / ".tools" / "bash_tools" / "pre_build_launch" / "clean_docker.sh"
GUI_SCRIPT = REPO_ROOT / ".tools" / "tcl_tools" / "main_gui.tcl"


class ManualDockerCleanupTests(unittest.TestCase):
    def _run_cleanup_with_fake_docker(self, prune_exit=0):
        with tempfile.TemporaryDirectory() as tmp:
            fake_docker = Path(tmp) / "docker"
            fake_docker.write_text(
                textwrap.dedent(
                    f"""\
                    #!/bin/sh
                    if [ \"$1\" = \"info\" ]; then
                        exit 0
                    fi
                    if [ \"$1 $2\" = \"system prune\" ]; then
                        echo \"Deleted build cache objects:\"
                        echo \"example\"
                        echo \"Total reclaimed space: 1.25GB\"
                        exit {prune_exit}
                    fi
                    exit 99
                    """
                ),
                encoding="utf-8",
            )
            fake_docker.chmod(0o755)
            env = os.environ.copy()
            env["PATH"] = f"{tmp}:{env['PATH']}"
            return subprocess.run(
                ["/bin/bash", str(CLEAN_SCRIPT)],
                cwd=REPO_ROOT,
                env=env,
                text=True,
                capture_output=True,
                check=False,
            )

    def test_cleanup_uses_same_conservative_24_hour_policy_without_volumes(self):
        text = CLEAN_SCRIPT.read_text(encoding="utf-8")
        self.assertIn('docker system prune -f --filter "until=24h"', text)
        self.assertNotIn("--volumes", text)

    def test_cleanup_propagates_docker_prune_failure(self):
        result = self._run_cleanup_with_fake_docker(prune_exit=17)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Docker cleanup failed", result.stderr)

    def test_cleanup_success_preserves_reclaimed_space_output(self):
        result = self._run_cleanup_with_fake_docker(prune_exit=0)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Total reclaimed space: 1.25GB", result.stdout)
        self.assertIn("Docker cleanup completed successfully", result.stdout)

    def test_gui_exposes_manual_reclaim_action_using_shared_cleanup_script(self):
        text = GUI_SCRIPT.read_text(encoding="utf-8")
        self.assertIn('-label "Reclaim Docker Space..."', text)
        self.assertIn("proc cmdcleandocker", text)
        self.assertIn('pre_build_launch/clean_docker.sh', text)
        self.assertIn('Docker volumes are not removed.', text)
        self.assertIn('Total reclaimed space:', text)


if __name__ == "__main__":
    unittest.main()
