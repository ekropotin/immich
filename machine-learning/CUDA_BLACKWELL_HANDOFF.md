# Blackwell GPU (sm_120) support for Immich ML — handoff notes

## Problem

Immich ML (CLIP embeddings, face detection) silently runs on CPU instead of GPU on systems
with NVIDIA Blackwell GPUs (RTX 50-series, compute capability sm_120). GPU passthrough at
the infrastructure level is fully working — the issue is entirely inside the container.

Symptom: 0% GPU utilization during ML jobs. No error shown in Immich UI. ML logs show:

```
Setting execution providers to ['CUDAExecutionProvider', 'CPUExecutingProvider']
...
EP Error: CUDA failure 35: CUDA driver version is insufficient for CUDA runtime version
...
Falling back to ['CPUExecutionProvider'] and retrying.
```

## Root cause chain

### 1. Upstream image used CUDA 12.2

The official `ghcr.io/immich-app/immich-machine-learning:release-cuda` image was built on
`nvidia/cuda:12.2.2-runtime-ubuntu22.04`. CUDA 12.2 predates Blackwell — `cudaGetDeviceCount`
returns error 35 on sm_120 hardware because the PTX in CUDA 12.2 does not know about sm_120.

Upstream fix proposed: PR [immich-app/immich#28032](https://github.com/immich-app/immich/pull/28032)
— changes `prod-cuda` base to `nvidia/cuda:12.8.1-runtime-ubuntu22.04`. **PR was rejected.**

### 2. Fork applies the base image change

This fork (`ekropotin/immich`, branch `fix/cuda-blackwell-support`) implements the same fix.
The `prod-cuda` stage in `machine-learning/Dockerfile` now uses:

```dockerfile
FROM nvidia/cuda:12.8.1-runtime-ubuntu22.04 AS prod-cuda
```

### 3. libcudnn9-cuda-12 reinstates CUDA 12.2

The `prod-cuda` stage installs `libcudnn9-cuda-12=9.10.2.21-1` (kept at this version because
cuDNN 9.11 dropped Pascal GPU support). This package's apt dependency chain pulls in:

```
cuda-cudart-12-2
cuda-libraries-12-2
libcublas-12-2
cuda-compat-12-2
...
```

These packages install to `/usr/local/cuda-12.2/` and run `update-alternatives` to set
`/usr/local/cuda → /etc/alternatives/cuda → /usr/local/cuda-12.2`. The CUDA 12.8 runtime
that the base image provides is completely gone from the final image — only `cuda-cudart-12-2`
remains installed.

Additionally, `apt-get autoremove` in the final `prod` stage triggers dpkg maintainer scripts
that re-run `update-alternatives`, so a simple `ln -sfn` or even `update-alternatives --set`
in `prod-cuda` gets overridden before the image is finalised.

### 4. Current fix approach (in progress)

After installing `libcudnn9-cuda-12`, explicitly reinstall `cuda-cudart-12-8`, pin it with
`apt-mark manual` so `autoremove` doesn't strip it, then set it as primary:

```dockerfile
RUN apt-get update && \
    apt-get install --no-install-recommends -yqq libcudnn9-cuda-12=9.10.2.21-1 && \
    apt-get install --no-install-recommends -yqq cuda-cudart-12-8 && \
    apt-mark manual cuda-cudart-12-8 && \
    update-alternatives --set cuda /usr/local/cuda-12.8 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
```

A guard in the final `prod` stage re-pins after all apt operations:

```dockerfile
RUN if [ "$DEVICE" = "cuda" ]; then \
    update-alternatives --set cuda /usr/local/cuda-12.8 2>/dev/null || \
    ln -sfn /usr/local/cuda-12.8 /usr/local/cuda; \
fi
```

**This fix has not yet been tested** — the image is being rebuilt at the time of writing.

## Verification steps

After deploying the new image:

```bash
# 1. Confirm libcudart.so.12 resolves to 12.8.x (not 12.2.x)
podman exec immich_immich_machine_learning_1 \
  ls -la /usr/local/cuda/targets/x86_64-linux/lib/libcudart.so.12
# Expected: -> libcudart.so.12.8.x

# 2. Confirm ONNX Runtime initialises the CUDA provider
podman exec immich_immich_machine_learning_1 \
  python -c "import onnxruntime; print(onnxruntime.get_available_providers())"
# Expected: ['TensorrtExecutionProvider', 'CUDAExecutionProvider', 'CPUExecutionProvider']

# 3. Confirm no fallback in ML logs at startup
podman logs immich_immich_machine_learning_1 2>&1 | grep -i "provider\|fallback\|cuda"
# Expected: "Setting execution providers to ['CUDAExecutionProvider', ...]" with no fallback line

# 4. Confirm GPU utilisation during an ML job (run from Incus host)
nvitop   # should show non-zero GPU utilisation on RTX 5060 Ti during face detection / CLIP
```

## Alternative approaches considered and rejected

| Approach | Why rejected |
|---|---|
| COPY /usr/local/cuda from cuda:12.8 image (rebase trick) | COPY merges directories but does not update existing symlinks; 12.2 symlinks remain |
| ln -sfn in prod-cuda stage | apt-get autoremove in prod stage triggers update-alternatives and overrides it |
| update-alternatives in prod-cuda stage | Same — overridden by prod stage apt operations |
| Build from upstream with only base image changed | Correct but heavy (~30 min build); what this fork does |

## Infrastructure context (homelab)

- GPU: NVIDIA RTX 5060 Ti (Blackwell, sm_120) on NixOS host `incus01`
- Driver: 580.126.18 (passes through `/dev/nvidia*` into Incus LXC `immich01`)
- NVIDIA user-space libs: bind-mounted from `/run/opengl-driver` → container `/opt/opengl-driver`
- LD_LIBRARY_PATH: `/opt/opengl-driver/lib` (set in hwaccel.ml.yml compose override)
- Container image reference: `ghcr.io/ekropotin/immich-machine-learning:cuda-blackwell`
- Compose override: `incus-workloads/ansible/roles/immich/templates/hwaccel.ml.yml.j2`
