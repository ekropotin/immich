# Immich — community fork (Blackwell / CUDA 12.8)

> [!CAUTION]
> ## ⛔ Deprecated — do not use this fork
>
> **Use the official image instead:** `ghcr.io/immich-app/immich-machine-learning:release-cuda`.
>
> This fork and the `ghcr.io/ekropotin/immich-machine-learning:cuda-blackwell`
> image are unmaintained and should not be used. The premise below turned out to
> be **wrong**: the CUDA 12.8 rebase was never necessary. The official image
> already works on NVIDIA Blackwell (sm_120) — onnxruntime ships PTX that the
> NVIDIA driver JIT-compiles to sm_120 at runtime (verified on an RTX 5060 Ti,
> back to onnxruntime 1.19.2). The `CUDA failure 35` this fork tried to fix is a
> GPU driver / container passthrough problem on the **host**, not a problem with
> the image. Fix the host GPU passthrough and the stock image works.
>
> Full write-up: [immich-app/immich#28583](https://github.com/immich-app/immich/issues/28583).
>
> _Everything below is kept for historical context only._

This is a community fork of [immich-app/immich](https://github.com/immich-app/immich) that exists for one purpose: to provide an `immich-machine-learning` image that works on **NVIDIA Blackwell GPUs (RTX 50-series, compute capability sm_120)** until upstream support lands.

## Why this fork exists

The upstream `release-cuda` ML image is built on `nvidia/cuda:12.2.2-runtime-ubuntu22.04`. CUDA 12.2 predates sm_120, so on Blackwell hardware ONNX Runtime silently falls back to CPU with no error — the only visible symptom is 0% GPU utilization during smart-search / face-detection jobs.

This fork bumps the `prod-cuda` stage to `nvidia/cuda:12.8.1-runtime-ubuntu22.04` and works around a packaging quirk where `libcudnn9-cuda-12` drags in `cuda-cudart-12-2` and overwrites the CUDA 12.8 runtime that the base image provides.

Tracking issue upstream: [immich-app/immich#28031](https://github.com/immich-app/immich/issues/28031).

**See the full diff vs upstream:** [immich-app/immich:main ↔ ekropotin/immich:fix/cuda-blackwell-support](https://github.com/immich-app/immich/compare/main...ekropotin:immich:fix/cuda-blackwell-support).

## Scope

- Only the `machine-learning/` service is modified.
- Server, web, mobile, and everything else are kept in lock-step with upstream via periodic rebase.
- Once upstream ships an ML image with CUDA 12.8+, this fork will be archived.

## Using the published image

```yaml
# docker-compose hwaccel override
services:
  immich_machine_learning:
    image: ghcr.io/ekropotin/immich-machine-learning:cuda-blackwell
```

See [`machine-learning/README.md`](machine-learning/README.md) for build and usage details.

## Upstream

For everything else — features, installation, docs, demo, contributing — refer to the upstream project:

- **Repository:** https://github.com/immich-app/immich
- **Documentation:** https://immich.app
- **Discord:** https://discord.immich.app
