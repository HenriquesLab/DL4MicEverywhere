#!/bin/bash

# Lightweight smoke tests performed after an image has been built/pulled.
# Usage: post_build_test.sh <docker_tag> [gpu_flag] [strict_deps]
#
# The basic checks run for every image. GPU checks run only when gpu_flag=1.
# TensorFlow/PyTorch are optional: if a framework is not installed it is
# reported as [SKIP], not as a failure.
#
# strict_deps=1 (default) makes `pip check` failures fatal. Images built in this
# run use it. Pulled or reused images were already validated when they were
# published; older ones may report harmless inconsistencies from system Python
# packages, so for them (strict_deps=0) `pip check` only warns.
#
# GPU failures name the layer that failed:
#   1. Docker -> GPU passthrough (host driver, NVIDIA Container Toolkit, Docker Desktop)
#   2. CUDA/cuDNN libraries inside the image (configuration.yaml versions)
#   3. The deep-learning framework itself (TensorFlow / PyTorch)

SCRIPT_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd -P)" || exit 1

docker_tag="${1:-}"
gpu_flag="${2:-0}"
strict_deps="${3:-1}"

print_error() {
    echo ""
    echo "------------------------------------"
    echo "Post-build check failed"
    echo "$1"
    if [ -n "${2:-}" ]; then
        echo ""
        echo "Details:"
        printf '%s\n' "$2"
    fi
    echo "------------------------------------"
}

run_container_check() {
    label="$1"
    message="$2"
    shift 2

    output=$(docker run --rm "$docker_tag" "$@" 2>&1)
    status=$?

    if [ "$status" -ne 0 ]; then
        print_error "$message" "$output"
        return 1
    fi

    echo "  [OK] $label"
    return 0
}

explain_gpu_passthrough_failure() {
    source "$SCRIPT_DIR/pre_build_launch/gpu_docker_support.sh" || return 0
    if dl4me_is_wsl; then
        echo "On Windows, GPU access is provided by Docker Desktop through WSL 2:"
        echo "  - Update Docker Desktop (Docker Desktop > Check for updates)."
        echo "  - Update the Windows NVIDIA driver (WSL uses the Windows driver; do not install one inside Ubuntu)."
        echo "  - Make sure Docker Desktop uses the WSL 2 based engine."
        return 0
    fi
    local problem
    problem=$(dl4me_docker_gpu_problem)
    if [ -n "$problem" ]; then
        dl4me_explain_docker_gpu_problem "$problem" "$(dirname "$(dirname "$SCRIPT_DIR")")"
    else
        echo "Check that 'nvidia-smi' works on this computer (NVIDIA driver installed and loaded)."
    fi
}

# Layer 2 diagnostics: compare the CUDA/cuDNN libraries in the image with what
# TensorFlow was built for and with what the host driver supports. Compatible
# with old Python versions used by legacy images. Exit 20 = mismatch found.
gpu_library_diagnostics_code=$(cat <<'PY'
import os
import re
import subprocess
import sys


def run(command):
    try:
        output = subprocess.check_output(command, shell=True, stderr=subprocess.STDOUT)
    except Exception as exc:
        output = getattr(exc, "output", None) or b""
    return output.decode("utf-8", "replace")


def major(version):
    return version.split(".")[0] if version else ""


def major_minor(version):
    parts = [int(p) for p in re.findall(r"\d+", version)[:2]]
    while len(parts) < 2:
        parts.append(0)
    return tuple(parts)


image_cuda = os.environ.get("CUDA_VERSION", "")
driver_cuda = os.environ.get("DL4ME_DRIVER_CUDA", "")

image_cudnn = ""
for line in run("dpkg-query -W -f='${Package} ${Version}\\n' 'libcudnn*' 2>/dev/null").splitlines():
    parts = line.split()
    if len(parts) == 2 and re.match(r"^libcudnn\d+(-cuda-\d+)?$", parts[0]):
        image_cudnn = parts[1].split("-")[0]

has_cudart = "libcudart.so" in run("ldconfig -p 2>/dev/null")

build_cuda = ""
build_cudnn = ""
try:
    import tensorflow as tf
    info = tf.sysconfig.get_build_info()
    build_cuda = str(info.get("cuda_version", "") or "")
    build_cudnn = str(info.get("cudnn_version", "") or "")
except Exception:
    pass

print("Image CUDA: %s" % (image_cuda or "unknown"))
print("Image cuDNN: %s" % (image_cudnn or "not installed"))
print("CUDA runtime library (libcudart) found: %s" % ("yes" if has_cudart else "no"))
print("Host driver supports CUDA up to: %s" % (driver_cuda or "unknown"))
if build_cuda or build_cudnn:
    print("TensorFlow was built for CUDA %s / cuDNN %s" % (build_cuda or "?", build_cudnn or "?"))

problems = []
if not image_cudnn:
    problems.append("No cuDNN library is installed in the image.")
if not has_cudart:
    problems.append("The CUDA runtime library (libcudart) is missing from the image.")
if build_cudnn and image_cudnn and major(build_cudnn) != major(image_cudnn):
    problems.append(
        "TensorFlow needs cuDNN %s but the image has cuDNN %s. Update cudnn_version "
        "(and cuda_version) in configuration.yaml." % (build_cudnn, image_cudnn))
if build_cuda and image_cuda and major(build_cuda) != major(image_cuda):
    problems.append(
        "TensorFlow needs CUDA %s but the image has CUDA %s. Update cuda_version "
        "(and cudnn_version) in configuration.yaml." % (build_cuda, image_cuda))
if driver_cuda and image_cuda and major_minor(image_cuda) > major_minor(driver_cuda):
    problems.append(
        "The image uses CUDA %s but the host NVIDIA driver supports CUDA up to %s. "
        "Update the NVIDIA driver on this computer." % (image_cuda, driver_cuda))

for problem in problems:
    print("PROBLEM: %s" % problem)
sys.exit(20 if problems else 0)
PY
)

if [ -z "$docker_tag" ]; then
    print_error "The Docker image tag is empty, so the image cannot be verified."
    exit 1
fi

if ! [[ "$gpu_flag" =~ ^[01]$ ]]; then
    print_error "The GPU flag is invalid. Expected 0 or 1, received: $gpu_flag"
    exit 1
fi

if ! [[ "$strict_deps" =~ ^[01]$ ]]; then
    print_error "The strict dependency flag is invalid. Expected 0 or 1, received: $strict_deps"
    exit 1
fi

echo "Post-build checks:"

run_container_check \
    "Python starts correctly." \
    "Python could not be started inside the Docker image." \
    python --version || exit 1

if [ "$strict_deps" -eq 1 ]; then
    run_container_check \
        "Python packages are consistent." \
        "Python reported missing or incompatible package dependencies." \
        python -m pip check || exit 1
else
    pip_check_output=$(docker run --rm "$docker_tag" python -m pip check 2>&1)
    if [ $? -eq 0 ]; then
        echo "  [OK] Python packages are consistent."
    else
        echo "  [WARN] The published image reports package dependency inconsistencies."
        echo "         The image is used exactly as it was published, so DL4MicEverywhere continues."
        printf '%s\n' "$pip_check_output" | sed 's/^/         /'
    fi
fi

run_container_check \
    "Jupyter starts correctly." \
    "Jupyter could not be started inside the Docker image." \
    jupyter --version || exit 1

# GPU framework checks are only relevant when the user requested GPU support.
if [ "$gpu_flag" -eq 1 ]; then
    echo ""
    echo "GPU checks:"

    # Layer 1: Docker -> GPU passthrough.
    gpu_output=$(docker run --rm --gpus all "$docker_tag" nvidia-smi 2>&1)
    gpu_status=$?
    if [ "$gpu_status" -ne 0 ]; then
        print_error \
            "GPU check failed (layer 1 of 3: Docker -> GPU passthrough). The Docker image is ready, but Docker could not give it access to the NVIDIA GPU." \
            "$gpu_output"
        explain_gpu_passthrough_failure
        exit 1
    fi
    echo "  [OK] Docker can access the NVIDIA GPU."

    # Highest CUDA version supported by the host driver, as reported by nvidia-smi.
    driver_cuda_version=$(printf '%s\n' "$gpu_output" | sed -n 's/.*CUDA Version: *\([0-9][0-9.]*\).*/\1/p' | head -n 1)

    # TensorFlow compatibility check.
    # Exit 10 means TensorFlow is not installed and should be skipped.
    # The script detects modern vs legacy TensorFlow APIs at runtime rather
    # than depending on a hard-coded TensorFlow version table.
    tensorflow_code=$(cat <<'PY'
import sys

try:
    import tensorflow as tf
except ImportError:
    sys.exit(10)

print("TensorFlow version: %s" % getattr(tf, "__version__", "unknown"))

gpu_name = ""

# Modern TensorFlow GPU discovery.
try:
    config = getattr(tf, "config", None)
    list_devices = getattr(config, "list_physical_devices", None) if config is not None else None
    if list_devices is not None:
        gpus = list_devices("GPU")
        if gpus:
            gpu_name = "/GPU:0"
except Exception:
    pass

# Legacy-compatible fallback, also retained by newer TensorFlow releases.
if not gpu_name:
    try:
        test_api = getattr(tf, "test", None)
        get_gpu_name = getattr(test_api, "gpu_device_name", None) if test_api is not None else None
        if get_gpu_name is not None:
            gpu_name = get_gpu_name() or ""
    except Exception:
        pass

if not gpu_name:
    print("TensorFlow cannot detect a GPU.")
    sys.exit(11)

try:
    # Prevent modern TensorFlow from silently moving an explicitly requested
    # GPU operation to the CPU when GPU placement fails.
    config = getattr(tf, "config", None)
    set_soft = getattr(config, "set_soft_device_placement", None) if config is not None else None
    if set_soft is not None:
        try:
            set_soft(False)
        except Exception:
            pass

    with tf.device("/GPU:0"):
        a = tf.constant([[1.0, 2.0], [3.0, 4.0]])
        result = tf.matmul(a, a)

    executing_eagerly = getattr(tf, "executing_eagerly", None)
    is_eager = bool(executing_eagerly()) if executing_eagerly is not None else False

    if is_eager:
        # Materialize the result so the GPU operation is actually executed.
        to_numpy = getattr(result, "numpy", None)
        if to_numpy is not None:
            to_numpy()

        result_device = getattr(result, "device", "") or ""
        if result_device and "GPU" not in result_device.upper():
            raise RuntimeError("TensorFlow placed the test operation on %s instead of the GPU." % result_device)
    else:
        # TensorFlow 1.x / graph-mode execution.
        session_cls = getattr(tf, "Session", None)
        config_cls = getattr(tf, "ConfigProto", None)

        if session_cls is None or config_cls is None:
            compat = getattr(tf, "compat", None)
            v1 = getattr(compat, "v1", None) if compat is not None else None
            if session_cls is None and v1 is not None:
                session_cls = getattr(v1, "Session", None)
            if config_cls is None and v1 is not None:
                config_cls = getattr(v1, "ConfigProto", None)

        if session_cls is None or config_cls is None:
            raise RuntimeError("No compatible TensorFlow session API was found for graph-mode execution.")

        session_config = config_cls(allow_soft_placement=False)
        with session_cls(config=session_config) as sess:
            sess.run(result)

except Exception as exc:
    print("TensorFlow GPU computation failed:")
    print(exc)
    sys.exit(12)

print("TensorFlow GPU detected: %s" % gpu_name)
print("TensorFlow GPU computation succeeded.")
sys.exit(0)
PY
)

    tensorflow_output=$(docker run --rm --gpus all "$docker_tag" python -c "$tensorflow_code" 2>&1)
    tensorflow_status=$?

    if [ "$tensorflow_status" -eq 10 ]; then
        echo "  [SKIP] TensorFlow is not installed."
    elif [ "$tensorflow_status" -ne 0 ]; then
        # Distinguish missing/mismatched CUDA libraries (layer 2) from a
        # TensorFlow problem (layer 3).
        library_report=$(docker run --rm --gpus all -e DL4ME_DRIVER_CUDA="$driver_cuda_version" \
            "$docker_tag" python -c "$gpu_library_diagnostics_code" 2>&1)
        library_status=$?
        library_errors=$(printf '%s\n' "$tensorflow_output" | grep -E "Could not load dynamic library|Cannot dlopen" || true)
        if [ "$library_status" -eq 20 ]; then
            print_error \
                "GPU check failed (layer 2 of 3: CUDA/cuDNN libraries in the image). TensorFlow cannot use the GPU because of the CUDA/cuDNN versions in this image." \
                "$library_report${library_errors:+

TensorFlow reported:
$library_errors}"
        else
            print_error \
                "GPU check failed (layer 3 of 3: TensorFlow). Docker can reach the GPU and the CUDA/cuDNN libraries look consistent, but TensorFlow could not use the GPU." \
                "$tensorflow_output

Library report:
$library_report"
        fi
        exit 1
    else
        tensorflow_version=$(printf '%s\n' "$tensorflow_output" | grep -m1 '^TensorFlow version:' || true)
        if [ -n "$tensorflow_version" ]; then
            echo "  [OK] $tensorflow_version"
        fi
        echo "  [OK] TensorFlow can execute a GPU operation."
    fi

    # PyTorch compatibility check.
    # Uses long-standing CUDA APIs (.cuda(), torch.mm, cuda.is_available)
    # to remain compatible with a broad range of PyTorch versions.
    pytorch_code=$(cat <<'PY'
import sys

try:
    import torch
except ImportError:
    sys.exit(10)

print("PyTorch version: %s" % getattr(torch, "__version__", "unknown"))

try:
    if not torch.cuda.is_available():
        print("PyTorch reports that CUDA is unavailable.")
        sys.exit(11)

    a = torch.FloatTensor([[1.0, 2.0], [3.0, 4.0]]).cuda()
    result = torch.mm(a, a)

    synchronize = getattr(torch.cuda, "synchronize", None)
    if synchronize is not None:
        synchronize()

    get_device_name = getattr(torch.cuda, "get_device_name", None)
    if get_device_name is not None:
        try:
            print("PyTorch GPU: %s" % get_device_name(0))
        except Exception:
            pass

except Exception as exc:
    print("PyTorch GPU computation failed:")
    print(exc)
    sys.exit(12)

print("PyTorch GPU computation succeeded.")
sys.exit(0)
PY
)

    pytorch_output=$(docker run --rm --gpus all "$docker_tag" python -c "$pytorch_code" 2>&1)
    pytorch_status=$?

    if [ "$pytorch_status" -eq 10 ]; then
        echo "  [SKIP] PyTorch is not installed."
    elif [ "$pytorch_status" -ne 0 ]; then
        # PyTorch wheels ship their own CUDA libraries, so a failure here is a
        # framework/driver compatibility problem (layer 3).
        print_error \
            "GPU check failed (layer 3 of 3: PyTorch). Docker can reach the GPU, but PyTorch could not use it. Host driver supports CUDA up to: ${driver_cuda_version:-unknown}." \
            "$pytorch_output"
        exit 1
    else
        pytorch_version=$(printf '%s\n' "$pytorch_output" | grep -m1 '^PyTorch version:' || true)
        pytorch_gpu=$(printf '%s\n' "$pytorch_output" | grep -m1 '^PyTorch GPU:' || true)
        if [ -n "$pytorch_version" ]; then
            echo "  [OK] $pytorch_version"
        fi
        if [ -n "$pytorch_gpu" ]; then
            echo "  [OK] $pytorch_gpu"
        fi
        echo "  [OK] PyTorch can execute a GPU operation."
    fi
fi

echo ""
echo "Post-build checks: OK"
echo ""

exit 0
