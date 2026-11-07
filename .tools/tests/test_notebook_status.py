import json
import tempfile
import unittest
from unittest import mock
from argparse import Namespace
from pathlib import Path

import sys
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "python_tools"))

import notebook_status


CONFIG_TEXT = """\
name: Demo Notebook
version: 1.2.3
config:
  dl4miceverywhere:
    notebook_version: 1.2.3
    docker_hub_image: demo-z1.2.3-d2.2.0
"""


class NotebookStatusTests(unittest.TestCase):
    def make_repo(self):
        temp = tempfile.TemporaryDirectory()
        root = Path(temp.name)
        config = root / "notebooks" / "ZeroCostDL4Mic_notebooks" / "Demo_DL4Mic" / "configuration.yaml"
        config.parent.mkdir(parents=True)
        config.write_text(CONFIG_TEXT, encoding="utf-8")
        (root / ".tools").mkdir(exist_ok=True)
        return temp, root, config

    def test_record_success_keeps_generation_timestamp(self):
        temp, root, config = self.make_repo()
        self.addCleanup(temp.cleanup)
        args = Namespace(
            repo_root=str(root), status_file=".tools/notebook-build-status.json",
            config=str(config.relative_to(root)), docker_tag="demo-z1.2.3-d2.2.0",
            amd64_build="success", amd64_smoke="success", amd64_generated_at="2026-09-14T10:00:00Z",
            gpu_build="failure", gpu_smoke="skipped", gpu_generated_at="",
            arm64_build="success", arm64_smoke="failure", arm64_generated_at="2026-09-14T10:05:00Z",
            multi_manifest="failure", amd64_manifest="success", arm64_manifest="skipped",
            attempted_at="2026-09-14T10:06:00Z", run_url="https://example/run/1", commit_sha="abc",
        )
        notebook_status.record_release(args)
        data = json.loads((root / ".tools/notebook-build-status.json").read_text())
        release = data["notebooks"][str(config.relative_to(root)).replace('\\', '/')]["releases"][args.docker_tag]
        self.assertEqual(release["architectures"]["amd64"]["generated_at"], "2026-09-14T10:00:00Z")
        self.assertEqual(release["architectures"]["gpu"]["build_status"], "failure")
        self.assertEqual(release["manifest_status"], "success")

    def test_failure_does_not_erase_previous_generation_time(self):
        previous = {"generated_at": "2026-01-01T00:00:00Z"}
        record = notebook_status.architecture_record(
            previous, "failure", "skipped", "", "2026-09-14T10:00:00Z", "demo"
        )
        self.assertEqual(record["generated_at"], "2026-01-01T00:00:00Z")
        self.assertEqual(record["build_status"], "failure")

    def test_render_lists_all_configs_and_ci_evidence(self):
        temp, root, config = self.make_repo()
        self.addCleanup(temp.cleanup)
        status = {
            "schema_version": 1,
            "notebooks": {
                str(config.relative_to(root)).replace('\\', '/'): {
                    "name": "Demo Notebook",
                    "releases": {
                        "demo-z1.2.3-d2.2.0": {
                            "docker_tag": "demo-z1.2.3-d2.2.0",
                            "run_url": "https://example/run/1",
                            "manifest_status": "success",
                            "last_attempted_at": "2026-09-14T10:06:00Z",
                            "architectures": {
                                "amd64": {
                                    "build_status": "success", "smoke_status": "success",
                                    "generated_at": "2026-09-14T10:00:00Z"
                                }
                            }
                        }
                    }
                }
            }
        }
        (root / ".tools/notebook-build-status.json").write_text(json.dumps(status), encoding="utf-8")
        args = Namespace(repo_root=str(root), status_file=".tools/notebook-build-status.json", report_file=".tools/test-notebooks.md")
        notebook_status.render_report(args)
        report = (root / ".tools/test-notebooks.md").read_text(encoding="utf-8")
        self.assertIn("Demo Notebook", report)
        self.assertIn("✅ Built", report)
        self.assertIn("2026-09-14 10:00 UTC", report)
        self.assertIn("[CI run](https://example/run/1)", report)


    def test_sync_dockerhub_imports_existing_tags_without_faking_smoke(self):
        temp, root, config = self.make_repo()
        self.addCleanup(temp.cleanup)
        responses = {
            "demo-z1.2.3-d2.2.0": {"last_updated": "2026-09-10T12:00:00Z"},
            "demo-z1.2.3-d2.2.0-amd64": {"last_updated": "2026-09-10T11:00:00Z"},
            "demo-z1.2.3-d2.2.0-gpu": {"last_updated": "2026-09-10T11:05:00Z"},
            "demo-z1.2.3-d2.2.0-arm64": None,
        }
        args = Namespace(
            repo_root=str(root), status_file=".tools/notebook-build-status.json",
            namespace="henriqueslab", repository="dl4miceverywhere", username="", token="",
        )
        with mock.patch.object(notebook_status, "fetch_dockerhub_tag", side_effect=lambda ns, repo, tag, token='': responses[tag]):
            notebook_status.sync_dockerhub(args)
        data = json.loads((root / ".tools/notebook-build-status.json").read_text())
        release = data["notebooks"][str(config.relative_to(root)).replace('\\', '/')]["releases"]["demo-z1.2.3-d2.2.0"]
        self.assertEqual(release["manifest_status"], "success")
        self.assertEqual(release["architectures"]["amd64"]["generated_at"], "2026-09-10T11:00:00Z")
        self.assertEqual(release["architectures"]["amd64"]["smoke_status"], "not_run")
        self.assertNotIn("arm64", release["architectures"])

    def test_manifest_status_prefers_any_success(self):
        self.assertEqual(notebook_status.compute_manifest_status(["skipped", "success", "failure"]), "success")
        self.assertEqual(notebook_status.compute_manifest_status(["failure", "skipped", "skipped"]), "failure")
        self.assertEqual(notebook_status.compute_manifest_status(["skipped", "skipped", "skipped"]), "skipped")


if __name__ == "__main__":
    unittest.main()
