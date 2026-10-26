import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


MODULE_PATH = Path(__file__).resolve().parents[1] / "build_and_test_images.py"
spec = importlib.util.spec_from_file_location("build_and_test_images", MODULE_PATH)
images = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(images)

REPO_ROOT = Path(__file__).resolve().parents[3]
STARDIST = REPO_ROOT / "notebooks" / "ZeroCostDL4Mic_notebooks" / "StarDist_2D_DL4Mic" / "configuration.yaml"


def notebook(*cells):
    return {"cells": [{"cell_type": kind, "source": source} for kind, source in cells], "nbformat": 4}


class ImportCheckTests(unittest.TestCase):
    def run_check(self, nb, packages=None):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "notebook.ipynb"
            path.write_text(json.dumps(nb), encoding="utf-8")
            # Optional fake packages importable by the check: {name: __init__ source}.
            for name, source in (packages or {}).items():
                (Path(tmp) / name).mkdir()
                (Path(tmp) / name / "__init__.py").write_text(source, encoding="utf-8")
            env = dict(os.environ, PYTHONPATH=tmp)
            result = subprocess.run(
                [sys.executable, "-c", images.IMPORT_CHECK_CODE, str(path)],
                text=True, capture_output=True, check=False, env=env,
            )
        report = images.parse_import_report(result.stdout)
        self.assertIsNotNone(report, result.stdout + result.stderr)
        self.last_install_commands = report["install_commands"]
        return result.returncode, {entry["statement"]: entry for entry in report["imports"]}

    def test_modules_from_kept_install_steps_are_runtime_warnings(self):
        # DecoNoising-like notebook: the install section clones the code the
        # later cells import, so those modules only exist after it runs.
        status, report = self.run_check(notebook(
            ("code", "!git clone https://github.com/juglab/DecoNoising\n%pip uninstall torch -y\n"),
            ("code", "from deconoising_like_missing import training\nimport json\n"),
        ))
        self.assertEqual(status, 0)
        entry = report["from deconoising_like_missing import training"]
        self.assertFalse(entry["ok"])
        self.assertTrue(entry["runtime"])
        self.assertEqual(self.last_install_commands, ["!git clone https://github.com/juglab/DecoNoising"])

    def test_modules_from_downloaded_code_are_runtime_warnings(self):
        # FRUNet: the notebook downloads and unzips functions.py, then imports it.
        status, report = self.run_check(notebook(
            ("code", "!wget --no-check-certificate https://example.org/FRU_processing.zip\n"),
            ("code", "from frunet_like_functions import unet_segmentation\n"),
        ))
        self.assertEqual(status, 0)
        self.assertTrue(report["from frunet_like_functions import unet_segmentation"]["runtime"])

    def test_matplotlib_uses_a_non_gui_backend_like_jupyter(self):
        # matplotlib 2.x defaults to TkAgg outside Jupyter; fnet 3D has no tkinter.
        status, report = self.run_check(
            notebook(("code", "import mpl_backend_probe\n")),
            {"mpl_backend_probe": "import os\nassert os.environ['MPLBACKEND'] == 'Agg'\n"},
        )
        self.assertEqual(status, 0)
        self.assertTrue(report["import mpl_backend_probe"]["ok"])

    def test_google_colab_is_never_a_runtime_install(self):
        # U-Net 3D: a Colab-only cell left in the notebook is a real bug.
        status, report = self.run_check(notebook(
            ("code", "!pip install something\nfrom google.colab import files\n"),
        ))
        self.assertEqual(status, 1)
        self.assertFalse(report["from google.colab import files"]["runtime"])

    def test_report_marker_is_found_after_progress_output(self):
        # pix2pix: a download progress bar (no newline) preceded the marker.
        text = "collection.json: 235kiB [00:00, 125MiB/s]   " + images.IMPORT_REPORT_MARKER + \
            json.dumps({"imports": [], "install_commands": []})
        self.assertEqual(images.parse_import_report(text), {"imports": [], "install_commands": []})

    def test_missing_module_fails(self):
        status, report = self.run_check(notebook(
            ("markdown", "# Load key dependencies"),
            ("code", ["%matplotlib inline\n", "import json\n",
                      "from os import path, sep\n", "import dl4me_module_that_does_not_exist\n"]),
        ))
        self.assertEqual(status, 1)
        self.assertTrue(report["import json"]["ok"])
        self.assertTrue(report["from os import path, sep"]["ok"])
        failed = report["import dl4me_module_that_does_not_exist"]
        self.assertFalse(failed["ok"])
        self.assertFalse(failed["optional"])
        self.assertFalse(failed["runtime"])
        self.assertIn("ModuleNotFoundError", failed["error"])

    def test_broken_dependency_fails_even_with_install_commands(self):
        # StarDist: the package is installed but itself imports a missing module.
        # Install commands kept in the notebook cannot explain that.
        status, report = self.run_check(
            notebook(("code", "!pip install unrelated-tool\nfrom dl4me_fake_stardist import fill_label_holes\n")),
            packages={"dl4me_fake_stardist": "from dl4me_missing_pkg_resources import get_distribution\n"},
        )
        self.assertEqual(status, 1)
        failed = report["from dl4me_fake_stardist import fill_label_holes"]
        self.assertFalse(failed["ok"])
        self.assertFalse(failed["runtime"])
        self.assertIn("dl4me_missing_pkg_resources", failed["error"])

    def test_imports_inside_try_are_optional_warnings(self):
        status, report = self.run_check(notebook(
            ("code", "try:\n    import google_colab_like_missing\nexcept ImportError:\n    pass\nimport os\n"),
        ))
        self.assertEqual(status, 0)
        self.assertTrue(report["import google_colab_like_missing"]["optional"])
        self.assertFalse(report["import google_colab_like_missing"]["ok"])

    def test_nested_and_function_level_imports_are_checked(self):
        status, report = self.run_check(notebook(
            ("code", "def helper():\n    import dl4me_missing_in_function\n    return 1\n"),
            ("code", "if True:\n    import sys\n"),
        ))
        self.assertEqual(status, 1)
        self.assertIn("import dl4me_missing_in_function", report)
        self.assertTrue(report["import sys"]["ok"])

    def test_cells_with_ipython_syntax_fall_back_to_import_lines(self):
        status, report = self.run_check(notebook(
            ("code", "files = !ls\nimport json\nfrom os import path\n"),
        ))
        self.assertEqual(status, 0)
        self.assertIn("import json", report)
        self.assertIn("from os import path", report)


class PlanTests(unittest.TestCase):
    def test_build_matches_launcher_inputs(self):
        plan = images.Plan(STARDIST, gpu=False, platform="amd64")
        command = plan.build_command("converter@sha256:a", "final@sha256:b")
        args = dict(
            value.split("=", 1) for flag, value in zip(command, command[1:]) if flag == "--build-arg"
        )
        self.assertEqual(plan.dockerfile, "docker/Dockerfile.modern")
        self.assertEqual(args["PATH_TO_REQUIREMENTS_LOCK"],
                         "notebooks/ZeroCostDL4Mic_notebooks/StarDist_2D_DL4Mic/requirements.lock.txt")
        self.assertEqual(args["NOTEBOOK_NAME"], "StarDist_2D_ZeroCostDL4Mic.ipynb")
        self.assertEqual(args["GPU_FLAG"], "0")
        self.assertEqual(args["FINAL_BASE_IMAGE"], "final@sha256:b")
        self.assertIn("org.dl4miceverywhere.managed=true", command)
        self.assertEqual(command[-1], ".")

    def test_gpu_and_arm64_variants(self):
        plan = images.Plan(STARDIST, gpu=True, platform="arm64")
        self.assertEqual(plan.dockerfile, "docker/Dockerfile.gpu.modern")
        self.assertTrue(plan.tag.endswith("-gpu"))
        self.assertTrue(plan.lock_relative.endswith("requirements.arm64.lock.txt"))
        self.assertIn("--gpus", plan.import_command())

    def test_legacy_python_uses_legacy_dockerfiles(self):
        self.assertEqual(images.select_dockerfile(False, "3.6"), "docker/Dockerfile.legacy")
        self.assertEqual(images.select_dockerfile(True, "3.5"), "docker/Dockerfile.gpu.legacy")
        self.assertEqual(images.select_dockerfile(False, "3.7"), "docker/Dockerfile.modern")

    def test_only_filter_and_dry_run_cover_every_configuration(self):
        every = images.discover_configs(REPO_ROOT, [])
        self.assertEqual(len(every), len(list((REPO_ROOT / "notebooks").rglob("configuration.yaml"))))
        self.assertEqual(images.discover_configs(REPO_ROOT, ["stardist_2d"]), [STARDIST])
        for config in every:
            with self.subTest(config=config.parent.name):
                images.Plan(config, gpu=False, platform="amd64")


class ReportTests(unittest.TestCase):
    def test_report_lists_failed_imports(self):
        result = {
            "config": "notebooks/X/StarDist_2D_DL4Mic/configuration.yaml", "variant": "cpu", "python": "3.11",
            "image": "dl4me-image-test:stardist-cpu", "status": "FAIL", "failed_step": "imports",
            "steps": {"build": {"ok": True, "seconds": 600}, "imports": {"ok": False, "seconds": 20}},
            "imports": {"total": 3, "optional_failed": [], "failed": [
                {"statement": "from stardist import fill_label_holes", "optional": False, "ok": False,
                 "error": "ModuleNotFoundError: No module named 'pkg_resources'"}]},
            "image_size_gb": 6.2, "logs": {},
        }
        with tempfile.TemporaryDirectory() as tmp:
            out = Path(tmp)
            images.write_reports(out, [result], {"started": "now", "platform": "amd64", "variants": ["cpu"],
                                                 "planned": 1})
            markdown = (out / "report.md").read_text(encoding="utf-8")
            data = json.loads((out / "report.json").read_text(encoding="utf-8"))
        self.assertIn("0 PASS, 0 WARN, 1 FAIL", markdown)
        self.assertIn("| StarDist_2D_DL4Mic | cpu | 3.11 | FAIL | imports | 10.0 | 6.2 | 2/3 |", markdown)
        self.assertIn("No module named 'pkg_resources'", markdown)
        self.assertEqual(data["results"][0]["failed_step"], "imports")


if __name__ == "__main__":
    unittest.main()
