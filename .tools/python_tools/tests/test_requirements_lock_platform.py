import importlib.util
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest import mock


MODULE_PATH = Path(__file__).resolve().parents[1] / "requirements_lock.py"
spec = importlib.util.spec_from_file_location("requirements_lock", MODULE_PATH)
requirements_lock = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(requirements_lock)

REPO_ROOT = Path(__file__).resolve().parents[3]
LINUX = REPO_ROOT / "Linux_launch.sh"
CUTOFF = "2026-01-01T00:00:00Z"


class RequirementsLockPlatformTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        self.source = self.root / "requirements.txt"
        self.source.write_text("tensorflow==2.12.0\n", encoding="utf-8")
        self.commands = []

    def tearDown(self):
        self.tmp.cleanup()

    def fake_run(self, cmd, check=True):
        self.commands.append(cmd)
        output = Path(cmd[cmd.index("--output-file") + 1])
        output.write_text(
            "tensorflow==2.12.0 \\\n    --hash=sha256:" + "a" * 64 + "\n", encoding="utf-8"
        )
        return subprocess.CompletedProcess(cmd, 0)

    def generate(self, platform):
        lock = self.root / requirements_lock.lock_filename(platform)
        with mock.patch.object(requirements_lock, "locate_uv", return_value=["uv"]), \
                mock.patch.object(requirements_lock.subprocess, "run", side_effect=self.fake_run):
            requirements_lock.generate_lock(
                lock, str(self.source), self.root, self.root, "3.10", "none", CUTOFF, platform
            )
        return lock

    def validate(self, lock, platform):
        return requirements_lock.validate_lock(
            lock, str(self.source), self.root, self.root, "3.10", "none", platform
        )[0]

    def test_lock_names_keep_amd64_default(self):
        self.assertEqual(requirements_lock.lock_filename("amd64"), "requirements.lock.txt")
        self.assertEqual(requirements_lock.lock_filename("arm64"), "requirements.arm64.lock.txt")

    def test_arm64_lock_is_resolved_for_aarch64(self):
        lock = self.generate("arm64")
        cmd = self.commands[-1]
        self.assertEqual(cmd[cmd.index("--python-platform") + 1], "aarch64-unknown-linux-gnu")
        self.assertIn("# dl4me-lock-python-platform: aarch64-unknown-linux-gnu", lock.read_text(encoding="utf-8"))
        self.assertTrue(self.validate(lock, "arm64"))
        self.assertFalse(self.validate(lock, "amd64"))

    def test_amd64_lock_is_resolved_for_x86_64(self):
        lock = self.generate("amd64")
        cmd = self.commands[-1]
        self.assertEqual(cmd[cmd.index("--python-platform") + 1], "x86_64-unknown-linux-gnu")
        self.assertTrue(self.validate(lock, "amd64"))

    def test_locks_without_platform_header_count_as_amd64(self):
        lock = self.generate("amd64")
        text = lock.read_text(encoding="utf-8")
        legacy = "".join(
            line for line in text.splitlines(keepends=True)
            if not line.startswith("# dl4me-lock-python-platform:")
        )
        lock.write_text(legacy, encoding="utf-8")
        self.assertTrue(self.validate(lock, "amd64"))
        self.assertFalse(self.validate(lock, "arm64"))

    def test_arm64_resolution_failure_explains_missing_arm_builds(self):
        lock = self.root / requirements_lock.lock_filename("arm64")
        failure = subprocess.CalledProcessError(1, ["uv"])
        with mock.patch.object(requirements_lock, "locate_uv", return_value=["uv"]), \
                mock.patch.object(requirements_lock.subprocess, "run", side_effect=failure):
            with self.assertRaisesRegex(RuntimeError, "ARM"):
                requirements_lock.generate_lock(
                    lock, str(self.source), self.root, self.root, "3.10", "none", CUTOFF, "arm64"
                )

    def test_launcher_selects_lock_for_docker_daemon_architecture(self):
        text = LINUX.read_text(encoding="utf-8")
        self.assertIn("docker info --format '{{.Architecture}}'", text)
        self.assertIn('lock_file_name="requirements.$lock_platform.lock.txt"', text)
        self.assertIn('--platform "$lock_platform"', text)


if __name__ == "__main__":
    unittest.main()
