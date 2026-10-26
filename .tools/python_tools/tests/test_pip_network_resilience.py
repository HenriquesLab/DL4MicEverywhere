from pathlib import Path
import unittest


REPO_ROOT = Path(__file__).resolve().parents[3]
DOCKERFILES = [
    REPO_ROOT / "docker" / "Dockerfile.modern",
    REPO_ROOT / "docker" / "Dockerfile.gpu.modern",
    REPO_ROOT / "docker" / "Dockerfile.legacy",
    REPO_ROOT / "docker" / "Dockerfile.gpu.legacy",
]


class PipNetworkResilienceTests(unittest.TestCase):
    def test_all_runtime_dockerfiles_use_resilient_pip_network_settings(self):
        for dockerfile in DOCKERFILES:
            with self.subTest(dockerfile=dockerfile.name):
                text = dockerfile.read_text(encoding="utf-8")
                # Each Dockerfile has a converter stage and a final runtime stage.
                self.assertEqual(text.count("ENV PIP_DEFAULT_TIMEOUT=120"), 2)
                self.assertEqual(text.count("ENV PIP_RETRIES=10"), 2)

    def test_deterministic_hash_install_remains_enabled(self):
        for dockerfile in DOCKERFILES:
            with self.subTest(dockerfile=dockerfile.name):
                text = dockerfile.read_text(encoding="utf-8")
                self.assertGreaterEqual(text.count("--require-hashes"), 2)
                self.assertIn("COPY ${PATH_TO_REQUIREMENTS_LOCK} /tmp/requirements.lock.txt", text)

    def test_package_install_is_retried_with_cached_downloads(self):
        # A download that stalls halfway (pix2pix on a slow connection) is not
        # retried by pip itself; the retry must not start every download again.
        for dockerfile in DOCKERFILES:
            with self.subTest(dockerfile=dockerfile.name):
                text = dockerfile.read_text(encoding="utf-8")
                self.assertIn("RUN --mount=type=cache,id=dl4me-pip,target=/root/.cache/pip \\\n"
                              "    for attempt in 1 2 3; do \\\n", text)
                self.assertIn("python -m pip install --cache-dir /root/.cache/pip", text)
                self.assertIn('if [ "$attempt" -eq 3 ]; then exit 1; fi', text)

    def test_unet_2d_uses_jupyterlab_compatible_requests_pin(self):
        requirements = (
            REPO_ROOT
            / "notebooks"
            / "ZeroCostDL4Mic_notebooks"
            / "U-Net_2D_DL4Mic"
            / "requirements.txt"
        ).read_text(encoding="utf-8")
        self.assertIn("requests==2.32.4", requirements)
        self.assertNotIn("requests==2.27.1\n", requirements)
        self.assertIn("DL4MicEverywhere compatibility override", requirements)


if __name__ == "__main__":
    unittest.main()
