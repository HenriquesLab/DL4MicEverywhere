from pathlib import Path
import os
import subprocess
import tempfile
import textwrap
import unittest


REPO_ROOT = Path(__file__).resolve().parents[3]
CLEAN_SCRIPT = REPO_ROOT / ".tools" / "bash_tools" / "pre_build_launch" / "clean_docker.sh"
GUI_SCRIPT = REPO_ROOT / ".tools" / "tcl_tools" / "main_gui.tcl"
LINUX_LAUNCHER = REPO_ROOT / "Linux_launch.sh"
PREFERENCES = REPO_ROOT / ".tools" / "tcl_tools" / "menubar" / "preferences.tcl"
INITIAL_PREFERENCES = REPO_ROOT / ".tools" / "tcl_tools" / "menubar" / "initial_preferences.tcl"
DOCKERFILES = [
    REPO_ROOT / "docker" / "Dockerfile.modern",
    REPO_ROOT / "docker" / "Dockerfile.gpu.modern",
    REPO_ROOT / "docker" / "Dockerfile.legacy",
    REPO_ROOT / "docker" / "Dockerfile.gpu.legacy",
]


class ManualDockerCleanupTests(unittest.TestCase):
    def _run_cleanup_with_fake_docker(self, *args, fail_on=""):
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            command_log = tmp_path / "docker-commands.log"
            fake_docker = tmp_path / "docker"
            fake_docker.write_text(
                textwrap.dedent(
                    """\
                    #!/bin/sh
                    printf '%s\\n' "$*" >> "$DOCKER_LOG"
                    if [ "$1" = "info" ]; then
                        exit 0
                    fi
                    if [ -n "${FAIL_ON:-}" ]; then
                        case "$*" in
                            *"$FAIL_ON"*)
                                echo "simulated Docker failure" >&2
                                exit 17
                                ;;
                        esac
                    fi
                    case "$1 $2" in
                        "container prune")
                            echo "Total reclaimed space: 12kB"
                            exit 0
                            ;;
                        "image prune")
                            echo "Total reclaimed space: 1.25GB"
                            exit 0
                            ;;
                        "network prune")
                            echo "Deleted Networks:"
                            exit 0
                            ;;
                        "builder prune")
                            echo "Total reclaimed space: 640MB"
                            exit 0
                            ;;
                    esac
                    exit 99
                    """
                ),
                encoding="utf-8",
            )
            fake_docker.chmod(0o755)
            env = os.environ.copy()
            env["PATH"] = f"{tmp}:{env['PATH']}"
            env["DOCKER_LOG"] = str(command_log)
            env["FAIL_ON"] = fail_on
            result = subprocess.run(
                ["/bin/bash", str(CLEAN_SCRIPT), *args],
                cwd=REPO_ROOT,
                env=env,
                text=True,
                capture_output=True,
                check=False,
            )
            commands = command_log.read_text(encoding="utf-8").splitlines()
            return result, commands

    def test_default_cleanup_is_label_scoped_and_preserves_shared_state(self):
        result, commands = self._run_cleanup_with_fake_docker()
        self.assertEqual(result.returncode, 0, result.stderr)

        joined = "\n".join(commands)
        managed = "label=org.dl4miceverywhere.managed=true"
        self.assertIn(f"container prune -f --filter {managed} --filter until=24h", joined)
        self.assertIn(f"image prune -a -f --filter {managed} --filter until=24h", joined)
        self.assertIn(f"network prune -f --filter {managed} --filter until=24h", joined)
        self.assertNotIn("system prune", joined)
        self.assertNotIn("builder prune", joined)
        self.assertNotIn("--volumes", joined)
        self.assertIn("Only DL4MicEverywhere-labelled resources were considered", result.stdout)

    def test_build_cache_cleanup_requires_explicit_opt_in(self):
        result, commands = self._run_cleanup_with_fake_docker("--include-build-cache")
        self.assertEqual(result.returncode, 0, result.stderr)
        joined = "\n".join(commands)
        self.assertIn("builder prune -f --filter until=24h", joined)
        self.assertNotIn("system prune", joined)
        self.assertNotIn("--volumes", joined)
        self.assertIn("shared Docker build cache", result.stdout)
        self.assertIn("Total reclaimed space: 640MB", result.stdout)

    def test_scoped_prune_failure_is_propagated(self):
        result, commands = self._run_cleanup_with_fake_docker(fail_on="image prune")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Docker cleanup failed while processing", result.stderr)
        self.assertTrue(any(command.startswith("image prune") for command in commands))
        self.assertFalse(any(command.startswith("network prune") for command in commands))

    def test_gui_offers_scoped_cleanup_and_explicit_shared_cache_option(self):
        text = GUI_SCRIPT.read_text(encoding="utf-8")
        self.assertIn('-label "Reclaim Docker Space..."', text)
        self.assertIn("proc cmdcleandocker", text)
        self.assertIn('"Clean DL4MicEverywhere"', text)
        self.assertIn('"Clean + build cache"', text)
        self.assertIn("--include-build-cache", text)
        self.assertIn("Docker volumes and unrelated Docker resources are preserved", text)
        self.assertIn("Docker build cache is shared daemon-wide", text)

    def test_builds_and_notebook_containers_carry_management_label(self):
        text = LINUX_LAUNCHER.read_text(encoding="utf-8")
        self.assertEqual(text.count('--label "org.dl4miceverywhere.managed=true"'), 2)
        self.assertGreaterEqual(text.count("--label org.dl4miceverywhere.managed=true"), 4)

    def test_all_published_runtime_images_embed_management_label(self):
        for dockerfile in DOCKERFILES:
            with self.subTest(dockerfile=dockerfile.name):
                text = dockerfile.read_text(encoding="utf-8")
                self.assertEqual(text.count('LABEL org.dl4miceverywhere.managed="true"'), 1)
                self.assertIn('FROM ${FINAL_BASE_IMAGE} AS final', text)

    def test_cleanup_preference_uses_its_own_choices(self):
        for preferences in (PREFERENCES, INITIAL_PREFERENCES):
            with self.subTest(preferences=preferences.name):
                text = preferences.read_text(encoding="utf-8")
                self.assertIn('set listClean [list "Automatically" "Ask first" "Manually"]', text)
                self.assertIn(".fr.principal.clean -values $listClean", text)
                self.assertNotIn(".fr.principal.clean -values $listUpdate", text)


if __name__ == "__main__":
    unittest.main()
