#!/bin/bash

# Lightweight smoke tests performed after an image has been built/pulled.
# Usage: post_build_test.sh <docker_tag> [gpu_flag]
#
# The basic checks run for every image. GPU checks run only when gpu_flag=1.
# TensorFlow/PyTorch are optional: if a framework is not installed it is
# reported as [SKIP], not as a failure.

docker_tag="${1:-}"
gpu_flag="${2:-0}"

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

if [ -z "$docker_tag" ]; then
    print_error "The Docker image tag is empty, so the image cannot be verified."
    exit 1
fi

if ! [[ "$gpu_flag" =~ ^[01]$ ]]; then
    print_error "The GPU flag is invalid. Expected 0 or 1, received: $gpu_flag"
    exit 1
fi

echo "Post-build checks:"

run_container_check \
    "Python starts correctly." \
    "Python could not be started inside the Docker image." \
    python --version || exit 1

run_container_check \
    "Python packages are consistent." \
    "Python reported missing or incompatible package dependencies." \
    python -m pip check || exit 1

run_container_check \
    "Jupyter starts correctly." \
    "Jupyter could not be started inside the Docker image." \
    jupyter --version || exit 1

# GPU framework checks are only relevant when the user requested GPU support.
if [ "$gpu_flag" -eq 1 ]; then
    echo ""
    echo "GPU checks:"

    gpu_output=$(docker run --rm --gpus all "$docker_tag" nvidia-smi 2>&1)
    gpu_status=$?
    if [ "$gpu_status" -ne 0 ]; then
        print_error \
            "The Docker image is ready, but Docker could not access the NVIDIA GPU." \
            "$gpu_output"
        exit 1
    fi
    echo "  [OK] Docker can access the NVIDIA GPU."

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
        print_error \
            "TensorFlow is installed, but its GPU integration check failed." \
            "$tensorflow_output"
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
        print_error \
            "PyTorch is installed, but its GPU integration check failed." \
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
