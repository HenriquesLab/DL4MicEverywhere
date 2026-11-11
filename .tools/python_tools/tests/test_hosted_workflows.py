from pathlib import Path
import re
import subprocess
import sys
import unittest


REPO_ROOT = Path(__file__).resolve().parents[3]
WORKFLOWS = REPO_ROOT / ".github" / "workflows"
GENERATOR = REPO_ROOT / ".tools" / "python_tools" / "generate_hosted_workflows.py"
HOSTED = sorted(WORKFLOWS.glob("gh_hosted_*.yml"))
AUTOMATIC_TRIGGERS = ("push:", "pull_request:", "release:", "schedule:")


def top_level_on_block(text):
    match = re.search(r"^on:\n(.*?)(?=^[A-Za-z_]+:)", text, re.MULTILINE | re.DOTALL)
    return match.group(1) if match else ""


class HostedWorkflowTests(unittest.TestCase):
    def test_every_self_hosted_workflow_has_a_hosted_copy(self):
        for path in sorted(WORKFLOWS.glob("*.yml")):
            if path.name.startswith("gh_hosted_"):
                continue
            text = path.read_text(encoding="utf-8")
            if "self-hosted" in re.sub(r"#.*", "", text):
                with self.subTest(workflow=path.name):
                    self.assertTrue((WORKFLOWS / f"gh_hosted_{path.name}").is_file())

    def test_hosted_copies_are_up_to_date(self):
        result = subprocess.run(
            [sys.executable, str(GENERATOR), "--check"],
            cwd=REPO_ROOT, text=True, capture_output=True, check=False,
        )
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_hosted_copies_use_only_github_hosted_runners(self):
        self.assertTrue(HOSTED)
        for path in HOSTED:
            text = re.sub(r"#.*", "", path.read_text(encoding="utf-8"))
            with self.subTest(workflow=path.name):
                self.assertNotIn("self-hosted", text)

    def test_hosted_copies_call_hosted_workflows_that_exist(self):
        for path in HOSTED:
            for target in re.findall(r"uses: \./\.github/workflows/(\S+\.yml)", path.read_text(encoding="utf-8")):
                with self.subTest(workflow=path.name, target=target):
                    self.assertTrue((WORKFLOWS / target).is_file())
                    target_text = (WORKFLOWS / target).read_text(encoding="utf-8")
                    self.assertNotIn("self-hosted", re.sub(r"#.*", "", target_text))

    def test_hosted_copies_never_start_automatically(self):
        # The self-hosted originals keep their push/release/schedule triggers;
        # a hosted copy firing on the same event would build and push twice.
        for path in HOSTED:
            on_block = top_level_on_block(path.read_text(encoding="utf-8"))
            with self.subTest(workflow=path.name):
                for trigger in AUTOMATIC_TRIGGERS:
                    self.assertNotIn(trigger, re.sub(r"#.*", "", on_block))

    def test_hosted_docker_builds_free_disk_space_first(self):
        for name in ("gh_hosted_build_docker_images_aux.yml", "gh_hosted_build_docker_images_new_config.yml"):
            text = (WORKFLOWS / name).read_text(encoding="utf-8")
            with self.subTest(workflow=name):
                self.assertEqual(text.count("Free disk space on the GitHub-hosted runner"), 2)
                self.assertIn("runs-on: ubuntu-24.04-arm", text)
                self.assertLess(text.index("Free disk space before the GPU image"),
                                text.index("Build and push GPU image"))


class UpdatedNotebookWorkflowTests(unittest.TestCase):
    def test_arm64_job_uses_the_arm64_lock(self):
        # Same fix as build_docker_images_aux.yml: ARM64 images need their own lock.
        text = (WORKFLOWS / "build_docker_images_new_config.yml").read_text(encoding="utf-8")
        arm64 = text[text.index("\n  build_arm64:\n"):text.index("\n  build_only_arm64:\n")]
        self.assertIn("--platform arm64", arm64)
        self.assertIn("/requirements.arm64.lock.txt", arm64)


if __name__ == "__main__":
    unittest.main()
