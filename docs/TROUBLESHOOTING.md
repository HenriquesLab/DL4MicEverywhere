# Troubleshooting Guide

This guide contains solutions to common problems when using DL4MicEverywhere.

## Docker Issues

**Docker daemon fails to start**

- Check that your OS meets the requirements for Docker Desktop. Docker requires Windows 10 Pro/Enterprise x64 or macOS 10.13+ 
- On Linux, make sure Docker engine is installed and the service is running. Check status with `systemctl status docker`
- Verify your user is in the `docker` group to avoid permission errors.

**Cannot pull Docker images** 

- Check internet connection and proxy settings. Docker needs access to Docker Hub.
- If authentication errors, re-enter Docker Hub credentials in Docker Desktop settings or `~/.docker/config.json`.
- For GitHub Package Registry images, make sure you are logged in with `docker login docker.pkg.github.com`

**Docker command not found**

- Make sure Docker CLI client is installed and in your PATH. 
- On Linux, you may need to add user to `docker` group. Log out and back in for changes to take effect.

**Docker takes too long to start**

- Increase Docker resources in Preferences > Resources. At least 2 CPUs and 4GB memory recommended.
- On Linux, check other processes consuming resources. Docker may need more RAM/CPUs.

## GPU Support

**Notebooks fail with CUDA errors**

- Verify Nvidia drivers are properly installed for your GPU.
- Make sure `nvidia-docker` is installed and runtime is enabled in Docker.
- Try updating Nvidia driver and CUDA to latest compatible versions.

**Docker fails to detect GPU** 

- Check `nvidia-smi` works outside Docker. If not, reinstall Nvidia driver.
- Make sure no other processes (e.g. X server) are using GPU when starting Docker.

**Out of memory on GPU**

- Lower batch size or model complexity to reduce VRAM usage.
- Use a GPU with more VRAM.
- Enable paging to swap some GPU memory to system RAM.

## Notebooks 

**Notebooks fail to build**

- Check Docker build logs for errors. Debug or raise issue.
- Try updating Docker engine and Nvidia driver to latest versions.

**Notebooks run slow** 

- Increase allocated resources for Docker engine (CPUs/RAM).
- Lower model and data complexity. Simplify notebooks.
- Use a machine with more powerful CPU/GPU resources.

**Notebooks crash/fail**

- Check notebook logs for errors and debug. 
- Raise issue with logs and steps to reproduce problem.

**Models produce poor results**

- Ensure training data is sufficient and correctly formatted.
- Try tuning model hyperparameters and architecture.
- Use more suitable model or training scheme.

## General

Still having problems? Search GitHub issues or raise a new one with details to reproduce the problem. We'll do our best to help resolve it!

Citations:
[1] https://ppl-ai-file-upload.s3.amazonaws.com/web/direct-files/34958/d84cc43a-014e-4ed5-9b79-2c5d28cbf153/output.txt