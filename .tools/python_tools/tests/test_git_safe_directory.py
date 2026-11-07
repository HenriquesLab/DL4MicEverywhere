import importlib.util
from pathlib import Path
import unittest


REPO_ROOT = Path(__file__).resolve().parents[3]
LOCK_SCRIPT = REPO_ROOT / ".tools" / "python_tools" / "requirements_lock.py"
UPDATE_SCRIPT = REPO_ROOT / ".tools" / "bash_tools" / "pre_build_launch" / "update_dl4miceverywhere.sh"


def load_lock_module():
    spec = importlib.util.spec_from_file_location("requirements_lock", LOCK_SCRIPT)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


class GitSafeDirectoryTests(unittest.TestCase):
    def test_python_git_commands_scope_safe_directory_to_checkout(self):
        module = load_lock_module()
        root = REPO_ROOT / "example checkout"
        command = module.git_repo_command(root, "status", "--porcelain")
        resolved = str(root.resolve())
        self.assertEqual(command[:5], ["git", "-c", f"safe.directory={resolved}", "-C", resolved])
        self.assertEqual(command[5:], ["status", "--porcelain"])

    def test_update_script_uses_scoped_repo_git_wrapper(self):
        text = UPDATE_SCRIPT.read_text(encoding="utf-8")
        self.assertIn('git -c safe.directory="$REPO_ROOT" -C "$REPO_ROOT" "$@"', text)
        self.assertIn("branch_name=$(repo_git branch --show-current", text)
        self.assertIn("local_commit=$(repo_git rev-parse HEAD", text)
        self.assertIn("repo_git pull --ff-only", text)
        self.assertNotIn("git config --global", text)


if __name__ == "__main__":
    unittest.main()
