from pathlib import Path
import re
import unittest


REPO_ROOT = Path(__file__).resolve().parents[3]
GPU_DOCKERFILES = [
    REPO_ROOT / "docker" / "Dockerfile.gpu.modern",
    REPO_ROOT / "docker" / "Dockerfile.gpu.legacy",
]

CUDA_RE = re.compile(r"^\d+\.\d+\.\d+$")
CUDNN_RE = re.compile(r"^\d+\.\d+\.\d+\.\d+$")


def config_value(text: str, key: str) -> str:
    match = re.search(rf"^\s*{key}:\s*['\"]?([^'\"\n]*)['\"]?\s*$", text, re.MULTILINE)
    return match.group(1).strip() if match else ""


class CudaCudnnConfigurationTests(unittest.TestCase):
    def test_every_configuration_pins_a_valid_cuda_cudnn_pair(self):
        configs = sorted((REPO_ROOT / "notebooks").rglob("configuration.yaml"))
        self.assertTrue(configs)
        for config in configs:
            text = config.read_text(encoding="utf-8")
            cuda = config_value(text, "cuda_version")
            cudnn = config_value(text, "cudnn_version")
            with self.subTest(config=str(config.relative_to(REPO_ROOT))):
                # GPU images install exactly this pair, so both must be present.
                self.assertRegex(cuda, CUDA_RE)
                self.assertRegex(cudnn, CUDNN_RE)
                cuda_major = int(cuda.split(".")[0])
                cudnn_major = int(cudnn.split(".")[0])
                self.assertIn(cudnn_major, (8, 9))
                if cudnn_major >= 9:
                    # NVIDIA publishes cuDNN 9 only for CUDA 11.8 and CUDA 12+.
                    self.assertTrue(
                        cuda_major >= 12 or cuda.startswith("11.8."),
                        f"cuDNN {cudnn} is not published for CUDA {cuda}",
                    )

    def test_gpu_dockerfiles_derive_cudnn_packages_from_configuration(self):
        for dockerfile in GPU_DOCKERFILES:
            text = dockerfile.read_text(encoding="utf-8")
            with self.subTest(dockerfile=dockerfile.name):
                self.assertIn('cudnn_major="${CUDNN_VERSION%%.*}"', text)
                self.assertIn("libcudnn${cudnn_major}-cuda-${cuda_major}=${CUDNN_VERSION}-1", text)
                self.assertIn("libcudnn${cudnn_major}=${CUDNN_VERSION}-1+cuda${cuda_major_minor}", text)
                # No unpinned or hard-coded cuDNN package names.
                self.assertNotRegex(text, r"\blibcudnn8(-dev)?\s*;")
                self.assertNotIn("libcudnn9-cuda-12", text)


if __name__ == "__main__":
    unittest.main()
