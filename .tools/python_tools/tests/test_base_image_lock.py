import importlib.util
from pathlib import Path
import tempfile
import unittest
from unittest import mock

MODULE_PATH = Path(__file__).resolve().parents[1] / "base_image_lock.py"
spec = importlib.util.spec_from_file_location("base_image_lock", MODULE_PATH)
base_image_lock = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(base_image_lock)


class BaseImageLockTests(unittest.TestCase):
    def make_config(self, root: Path, ubuntu="22.04", cuda="11.8.0") -> Path:
        config = root / "configuration.yaml"
        config.write_text(
            "config:\n"
            "  dl4miceverywhere:\n"
            f"    ubuntu_version: '{ubuntu}'\n"
            f"    cuda_version: {cuda}\n",
            encoding="utf-8",
        )
        return config

    def entry(self, seed: str):
        digit = seed[0]
        return {
            "digest": "sha256:" + digit * 64,
            "platforms": {
                "linux/amd64": "sha256:" + seed[1] * 64,
                "linux/arm64": "sha256:" + seed[2] * 64,
            },
        }

    def test_modular_configuration_derives_expected_tags(self):
        with tempfile.TemporaryDirectory() as tmp:
            config = self.make_config(Path(tmp), "20.04", "11.2.2")
            self.assertEqual(base_image_lock.logical_final_image(config, False), "ubuntu:20.04")
            self.assertEqual(
                base_image_lock.logical_final_image(config, True),
                "nvidia/cuda:11.2.2-devel-ubuntu20.04",
            )

    def test_lock_round_trip(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "base_images.lock.yaml"
            expected = {
                "ubuntu:22.04": self.entry("abc"),
                "python:3.9.20-alpine3.19": self.entry("def"),
            }
            base_image_lock.write_lock(path, expected)
            self.assertEqual(base_image_lock.load_lock(path), expected)

    def test_ensure_does_not_refresh_existing_pin(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "base_images.lock.yaml"
            original = {"ubuntu:22.04": self.entry("abc")}
            base_image_lock.write_lock(path, original)
            new_entry = self.entry("def")
            with mock.patch.object(base_image_lock, "inspect_image", return_value=new_entry) as inspect:
                images, changed = base_image_lock.ensure_images(
                    path,
                    ["ubuntu:22.04", "python:3.9.20-alpine3.19"],
                    refresh=False,
                )
            self.assertTrue(changed)
            self.assertEqual(images["ubuntu:22.04"], original["ubuntu:22.04"])
            inspect.assert_called_once_with("python:3.9.20-alpine3.19")

    def test_refresh_is_explicit(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "base_images.lock.yaml"
            base_image_lock.write_lock(path, {"ubuntu:22.04": self.entry("abc")})
            replacement = self.entry("def")
            with mock.patch.object(base_image_lock, "inspect_image", return_value=replacement) as inspect:
                images, changed = base_image_lock.ensure_images(path, ["ubuntu:22.04"], refresh=True)
            self.assertTrue(changed)
            self.assertEqual(images["ubuntu:22.04"], replacement)
            inspect.assert_called_once_with("ubuntu:22.04")


if __name__ == "__main__":
    unittest.main()
