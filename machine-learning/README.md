# Immich Machine Learning — community fork (Blackwell / CUDA 12.8)

This is a community fork of the `immich-machine-learning` service from [immich-app/immich](https://github.com/immich-app/immich), maintained to provide CUDA 12.8 support for **NVIDIA Blackwell GPUs (RTX 50-series, compute capability sm_120)** until upstream support is released.

Upstream tracking issue: [immich-app/immich#28031](https://github.com/immich-app/immich/issues/28031).

## Why this fork exists

The upstream `release-cuda` image is built on `nvidia/cuda:12.2.2-runtime-ubuntu22.04`. CUDA 12.2 predates sm_120, so on Blackwell hardware ONNX Runtime silently falls back to CPU with no error — the only visible symptom is 0% GPU utilization.

This fork:

1. Pins the `prod-cuda` base image to `nvidia/cuda:12.8.1-runtime-ubuntu22.04`.
2. Reinstalls `cuda-cudart-12-8` after `libcudnn9-cuda-12` is installed, because the cuDNN package pulls in `cuda-cudart-12-2` and overwrites the CUDA 12.8 runtime that the base image provides. The fork pins it with `apt-mark manual` and sets it as the primary `update-alternatives` target.

A proposed upstream fix is in [immich-app/immich#28032](https://github.com/immich-app/immich/pull/28032). Once it merges and a new release ships, switch back to the official image.

## Published image

```yaml
# docker-compose hwaccel override
services:
  immich_machine_learning:
    image: ghcr.io/ekropotin/immich-machine-learning:cuda-blackwell
```

## Building locally

```bash
docker build --build-arg DEVICE=cuda \
  -t ghcr.io/ekropotin/immich-machine-learning:cuda-blackwell \
  machine-learning/
```

## Upstream

For everything else — overall ML service docs, dependency management, load testing, facial recognition model attribution, and contributing — refer to the upstream project:

- **Repository:** https://github.com/immich-app/immich
- **Upstream `machine-learning/README.md`:** https://github.com/immich-app/immich/blob/main/machine-learning/README.md
