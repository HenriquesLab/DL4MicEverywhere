from pathlib import Path
import os
import subprocess
import sys
import tempfile
import textwrap
import unittest


REPO_ROOT = Path(__file__).resolve().parents[3]
BASH_TOOLS = REPO_ROOT / ".tools" / "bash_tools"
DOCKER_STATE = BASH_TOOLS / "pre_build_launch" / "docker_state.sh"
GPU_SUPPORT = BASH_TOOLS / "pre_build_launch" / "gpu_docker_support.sh"
CHECK_DAEMON = BASH_TOOLS / "pre_build_launch" / "check_docker_daemon.sh"
POST_BUILD = BASH_TOOLS / "post_build_test.sh"
DOCKER_INSTALL = BASH_TOOLS / "requirements_installation" / "docker.sh"
TOOLKIT_INSTALL = BASH_TOOLS / "requirements_installation" / "nvidia_container_toolkit.sh"
REQUIREMENTS = BASH_TOOLS / "requirements_installation.sh"
LINUX = REPO_ROOT / "Linux_launch.sh"
DOCKERFILES = [
    REPO_ROOT / "docker" / "Dockerfile.modern",
    REPO_ROOT / "docker" / "Dockerfile.legacy",
    REPO_ROOT / "docker" / "Dockerfile.gpu.modern",
    REPO_ROOT / "docker" / "Dockerfile.gpu.legacy",
]

ON_LINUX = sys.platform.startswith("linux")


class FakeCommands:
    """Temporary directory of fake executables placed first on PATH."""

    def __init__(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.path = Path(self.tmp.name)

    def add(self, name, body):
        script = self.path / name
        script.write_text("#!/bin/sh\n" + textwrap.dedent(body), encoding="utf-8", newline="\n")
        script.chmod(0o755)

    def env(self):
        env = os.environ.copy()
        env["PATH"] = f"{self.path}:{env['PATH']}"
        return env

    def cleanup(self):
        self.tmp.cleanup()


class StaticDockerInstallationTests(unittest.TestCase):
    def test_linux_installs_docker_engine_only(self):
        text = DOCKER_INSTALL.read_text(encoding="utf-8")
        linux_branch = text[text.index('if [[ "$OSTYPE" == "linux-gnu"* ]]'):text.index('elif [[ "$OSTYPE" == "darwin"* ]]')]
        self.assertIn("docker-ce docker-ce-cli containerd.io", linux_branch)
        self.assertNotIn("docker-desktop", linux_branch)
        self.assertNotIn("DockerDesktop.deb", linux_branch)
        # The Ubuntu 24.04 AppArmor relaxation was only needed by Docker Desktop.
        self.assertNotIn("apparmor_restrict_unprivileged_userns", linux_branch)
        self.assertIn("sudo systemctl enable --now docker", linux_branch)
        self.assertIn("getent group docker", linux_branch)

    def test_linux_install_never_replaces_existing_container_packages(self):
        text = DOCKER_INSTALL.read_text(encoding="utf-8")
        guard = text.index("conflicting_packages")
        self.assertLess(guard, text.index("apt-get -y install docker-ce"))
        for package in ("docker.io", "containerd", "runc", "podman-docker"):
            self.assertIn(package, text[guard:text.index("apt-get -y install docker-ce")])

    def test_wsl_never_installs_docker_engine(self):
        text = DOCKER_INSTALL.read_text(encoding="utf-8")
        self.assertLess(text.index('"wsl"*'), text.index("apt-get -y install docker-ce"))
        self.assertIn("Windows_launch.bat", text)

    def test_toolkit_is_configured_only_after_fresh_engine_install(self):
        text = REQUIREMENTS.read_text(encoding="utf-8")
        marker = text.index("DL4ME_DOCKER_INSTALLED_MARKER=")
        toolkit = text.index("nvidia_container_toolkit.sh")
        self.assertLess(marker, toolkit)
        self.assertIn('if [ -f "$docker_installed_marker" ]', text)
        # The "Docker already installed" path never touches the toolkit.
        already_installed = text.index('echo "Docker already installed."')
        self.assertLess(text.rindex("nvidia_container_toolkit.sh"), already_installed)
        self.assertLess(text.rindex("nvidia_container_toolkit.sh"), text.rindex("else", 0, already_installed))

    def test_toolkit_script_follows_nvidia_flow_and_never_touches_driver(self):
        text = TOOLKIT_INSTALL.read_text(encoding="utf-8")
        for required in (
            "nvidia.github.io/libnvidia-container",
            "apt-get install -y nvidia-container-toolkit",
            "nvidia-ctk runtime configure --runtime=docker",
            "systemctl restart docker",
            "--print-instructions",
            "stops every running container",
        ):
            self.assertIn(required, text)
        self.assertNotIn("nvidia-driver", text)

    def test_daemon_check_distinguishes_engine_desktop_and_permissions(self):
        text = CHECK_DAEMON.read_text(encoding="utf-8")
        for state in ("no_permission", "engine_stopped", "unknown"):
            self.assertIn(state, text)
        self.assertIn("sudo systemctl start docker", text)
        self.assertIn('docker_desktop_gui.tcl" "$docker_product"', text)

    def test_gpu_problem_is_detected_before_pull_or_build(self):
        text = LINUX.read_text(encoding="utf-8")
        check = text.index("docker_gpu_problem=$(dl4me_docker_gpu_problem)")
        self.assertLess(check, text.index('docker_tag=$docker_tag-gpu'))
        self.assertLess(check, text.index('docker pull "$docker_tag"'))

    def test_dockerfiles_silence_only_the_base_image_arg_warning(self):
        for dockerfile in DOCKERFILES:
            with self.subTest(dockerfile=dockerfile.name):
                text = dockerfile.read_text(encoding="utf-8")
                self.assertTrue(text.startswith("# check=skip=InvalidDefaultArgInFrom\n"))
                self.assertIn("ARG CONVERTER_BASE_IMAGE\n", text)

    def test_strict_dependency_check_only_for_images_built_in_this_run(self):
        text = LINUX.read_text(encoding="utf-8")
        block = text[text.index('if [ "$flag_build" -eq 2 ]; then\n    strict_dependency_check=1'):]
        self.assertIn("strict_dependency_check=0", block[:200])
        self.assertIn('post_build_test.sh" "$docker_tag" "$flag_gpu" "$strict_dependency_check"', text)

    def test_gpu_failures_name_their_layer(self):
        text = POST_BUILD.read_text(encoding="utf-8")
        self.assertIn("layer 1 of 3: Docker -> GPU passthrough", text)
        self.assertIn("layer 2 of 3: CUDA/cuDNN libraries in the image", text)
        self.assertIn("layer 3 of 3: TensorFlow", text)
        self.assertIn("tf.sysconfig.get_build_info()", text)


@unittest.skipUnless(ON_LINUX, "Runtime checks use Linux bash semantics")
class DockerStateRuntimeTests(unittest.TestCase):
    def setUp(self):
        self.fake = FakeCommands()
        # Never classify the test machine itself as WSL.
        self.fake.add("systemd-detect-virt", 'echo none\n')

    def tearDown(self):
        self.fake.cleanup()

    def state(self):
        result = subprocess.run(
            ["bash", "-c", f'source "{DOCKER_STATE}"; dl4me_docker_state'],
            text=True, capture_output=True, env=self.fake.env(), check=False,
        )
        return result.stdout.strip()

    def test_ready(self):
        self.fake.add("docker", 'exit 0\n')
        self.assertEqual(self.state(), "ready")

    def test_permission_denied_is_not_a_stopped_daemon(self):
        self.fake.add("docker", """\
            if [ "$1" = "info" ]; then
                echo "permission denied while trying to connect to the Docker daemon socket at unix:///var/run/docker.sock" >&2
                exit 1
            fi
            exit 0
        """)
        self.assertEqual(self.state(), "no_permission")

    def test_stopped_engine_service(self):
        self.fake.add("docker", """\
            [ "$1" = "context" ] && { echo default; exit 0; }
            echo "Cannot connect to the Docker daemon" >&2; exit 1
        """)
        self.fake.add("systemctl", """\
            [ "$1" = "cat" ] && [ "$2" = "docker.service" ] && exit 0
            exit 1
        """)
        self.assertEqual(self.state(), "engine_stopped")

    def test_stopped_docker_desktop_for_linux(self):
        self.fake.add("docker", """\
            [ "$1" = "context" ] && { echo desktop-linux; exit 0; }
            echo "Cannot connect to the Docker daemon" >&2; exit 1
        """)
        self.assertEqual(self.state(), "desktop_stopped")


@unittest.skipUnless(ON_LINUX, "Runtime checks use Linux bash semantics")
class GpuDockerSupportRuntimeTests(unittest.TestCase):
    def setUp(self):
        self.fake = FakeCommands()
        self.fake.add("systemd-detect-virt", 'echo none\n')

    def tearDown(self):
        self.fake.cleanup()

    def problem(self):
        env = self.fake.env()
        # Hide any real NVIDIA hook on the test machine.
        env["PATH"] = f"{self.fake.path}:/usr/bin:/bin"
        result = subprocess.run(
            ["bash", "-c", f'source "{GPU_SUPPORT}"; dl4me_docker_gpu_problem'],
            text=True, capture_output=True, env=env, check=False,
        )
        return result.stdout.strip()

    def test_desktop_linux_cannot_pass_gpus(self):
        self.fake.add("docker", '[ "$1" = "context" ] && echo desktop-linux; exit 0\n')
        self.assertEqual(self.problem(), "desktop_linux")

    def test_engine_without_nvidia_runtime(self):
        self.fake.add("docker", """\
            [ "$1" = "context" ] && { echo default; exit 0; }
            echo '{"io.containerd.runc.v2":{},"runc":{}}'
        """)
        if Path("/usr/bin/nvidia-container-runtime-hook").exists():
            self.skipTest("The test machine has the NVIDIA hook installed")
        self.assertEqual(self.problem(), "no_nvidia_runtime")

    def test_engine_with_nvidia_runtime(self):
        self.fake.add("docker", """\
            [ "$1" = "context" ] && { echo default; exit 0; }
            echo '{"nvidia":{"path":"nvidia-container-runtime"},"runc":{}}'
        """)
        self.assertEqual(self.problem(), "")


@unittest.skipUnless(ON_LINUX, "Runtime checks use Linux bash semantics")
class PostBuildDependencyCheckRuntimeTests(unittest.TestCase):
    def setUp(self):
        self.fake = FakeCommands()
        # Every container command succeeds except `pip check`.
        self.fake.add("docker", """\
            case "$*" in
                *"pip check"*) echo "pygobject 3.42.1 requires pycairo, which is not installed."; exit 1 ;;
            esac
            exit 0
        """)

    def tearDown(self):
        self.fake.cleanup()

    def run_check(self, strict):
        return subprocess.run(
            ["bash", str(POST_BUILD), "example:tag", "0", strict],
            text=True, capture_output=True, env=self.fake.env(), check=False,
        )

    def test_published_images_only_warn(self):
        result = self.run_check("0")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("[WARN]", result.stdout)
        self.assertIn("pycairo", result.stdout)

    def test_images_built_in_this_run_fail(self):
        result = self.run_check("1")
        self.assertEqual(result.returncode, 1)
        self.assertIn("Python reported missing or incompatible package dependencies.", result.stdout)


if __name__ == "__main__":
    unittest.main()
