from pathlib import Path
import subprocess
import tempfile
import unittest

REPO_ROOT = Path(__file__).resolve().parents[2]
LOADER = REPO_ROOT / ".tools" / "bash_tools" / "get_yaml_args.sh"


class YamlNoEvalTests(unittest.TestCase):
    def run_bash(self, script: str):
        return subprocess.run(
            ["bash", "-c", script],
            cwd=REPO_ROOT,
            text=True,
            capture_output=True,
            check=False,
        )

    def test_configuration_values_are_loaded_as_data_not_shell_code(self):
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            marker = tmp_path / "should-not-exist"
            config = tmp_path / "configuration.yaml"
            payload = f'$(touch "{marker}")'
            config.write_text(
                "config:\n"
                "  dl4miceverywhere:\n"
                f'    description: \'{payload}\'\n',
                encoding="utf-8",
            )
            result = self.run_bash(
                f'source "{LOADER}"\n'
                f'load_yaml_args_from_file "{config}"\n'
                'printf "%s" "$config_dl4miceverywhere_description"\n'
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(result.stdout, payload)
            self.assertFalse(marker.exists())

    def test_real_configuration_values_still_load(self):
        config = REPO_ROOT / "notebooks" / "ZeroCostDL4Mic_notebooks" / "DFCAN_DL4Mic" / "configuration.yaml"
        result = self.run_bash(
            f'source "{LOADER}"\n'
            f'load_yaml_args_from_file "{config}"\n'
            'printf "%s|%s|%s" "$config_dl4miceverywhere_python_version" '
            '"$config_dl4miceverywhere_notebook_version" "$config_dl4miceverywhere_docker_hub_image"\n'
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            result.stdout,
            "3.9|1.14.1|dfcan_zerocostdl4mic-z1.14.1-d2.2.0",
        )

    def test_yaml_consumers_do_not_eval_parser_output(self):
        consumers = [
            REPO_ROOT / "Linux_launch.sh",
            REPO_ROOT / ".tools" / "bash_tools" / "get_docker_versions.sh",
            REPO_ROOT / ".tools" / "bash_tools" / "get_docker_tag.sh",
            REPO_ROOT / ".tools" / "bash_tools" / "cache_docker_tags.sh",
            REPO_ROOT / ".tools" / "bash_tools" / "get_local_description.sh",
            REPO_ROOT / ".tools" / "bash_tools" / "get_dl4miceverywhere_version.sh",
        ]
        for path in consumers:
            with self.subTest(path=path):
                text = path.read_text(encoding="utf-8")
                self.assertNotIn("eval $(get_yaml_args_from_file", text)
                self.assertNotIn("eval $(get_yaml_args_from_url", text)

    def test_gui_cache_loading_does_not_eval_cache_values(self):
        for relative in [
            ".tools/tcl_tools/main_gui.tcl",
            ".tools/tcl_tools/menubar/preferences.tcl",
        ]:
            path = REPO_ROOT / relative
            with self.subTest(path=path):
                text = path.read_text(encoding="utf-8")
                self.assertNotIn('eval "set cache_', text)


if __name__ == "__main__":
    unittest.main()
