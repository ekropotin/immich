# Immich Machine Learning — community fork (Blackwell / CUDA 12.8)

> **This is a community fork** of [immich-app/immich](https://github.com/immich-app/immich) that updates the CUDA base image to 12.8 to support **NVIDIA Blackwell GPUs (RTX 50-series, sm_120)**.
>
> **Published image:** `ghcr.io/ekropotin/immich-machine-learning:cuda-blackwell`
>
> **Why:** The upstream `release-cuda` image is built on `nvidia/cuda:12.2.2-runtime-ubuntu22.04`. CUDA 12.2 predates sm_120, so ONNX Runtime silently falls back to CPU with no error — the only symptom is 0% GPU utilization. This fork changes the prod-cuda base to `nvidia/cuda:12.8.1-runtime-ubuntu22.04` (see `prod-cuda` stage in `Dockerfile`). An upstream fix was proposed in [immich-app/immich#28032](https://github.com/immich-app/immich/pull/28032).
>
> **Usage:**
> ```yaml
> # In your docker-compose hwaccel override:
> services:
>   immich_machine_learning:
>     image: ghcr.io/ekropotin/immich-machine-learning:cuda-blackwell
> ```
>
> **Rebuilding locally:**
> ```bash
> docker build --build-arg DEVICE=cuda \
>   -t ghcr.io/ekropotin/immich-machine-learning:cuda-blackwell \
>   machine-learning/
> ```
>
> Once the upstream PR merges and a new release ships with CUDA 12.8, switch back to the official image.

---

# Immich Machine Learning

- CLIP embeddings
- Facial recognition

# Setup

This project uses [uv](https://docs.astral.sh/uv/getting-started/installation/), so be sure to install it first.
Running `uv sync --extra cpu` will install everything you need in an isolated virtual environment.
CUDA, ROCM and OpenVINO are supported as acceleration APIs. To use them, you can replace `--extra cpu` with either of `--extra cuda`, `--extra rocm` or `--extra openvino`. In the case of CUDA, a [compute capability](https://developer.nvidia.com/cuda-gpus) of 5.2 or higher is required.

To add or remove dependencies, you can use the commands `uv add $PACKAGE_NAME` and `uv remove $PACKAGE_NAME`, respectively.
Be sure to commit the `uv.lock` and `pyproject.toml` files with `uv lock` to reflect any changes in dependencies.

# Load Testing

To measure inference throughput and latency, you can use [Locust](https://locust.io/) using the provided `locustfile.py`.
Locust works by querying the model endpoints and aggregating their statistics, meaning the app must be deployed.
You can change the models or adjust options like score thresholds through the Locust UI.

To get started, you can simply run `locust --web-host 127.0.0.1` and open `localhost:8089` in a browser to access the UI. See the [Locust documentation](https://docs.locust.io/en/stable/index.html) for more info on running Locust.

Note that in Locust's jargon, concurrency is measured in `users`, and each user runs one task at a time. To achieve a particular per-endpoint concurrency, multiply that number by the number of endpoints to be queried. For example, if there are 3 endpoints and you want each of them to receive 8 requests at a time, you should set the number of users to 24.

# Facial Recognition

## Acknowledgements

This project utilizes facial recognition models from the [InsightFace](https://github.com/deepinsight/insightface/tree/master/model_zoo) project. We appreciate the work put into developing these models, which have been beneficial to the machine learning part of this project.

### Used Models

- antelopev2
- buffalo_l
- buffalo_m
- buffalo_s

## License and Use Restrictions

We have received permission to use the InsightFace facial recognition models in our project, as granted via email by Jia Guo (guojia@insightface.ai) on 18th March 2023. However, it's important to note that this permission does not extend to the redistribution or commercial use of their models by third parties. Users and developers interested in using these models should review the licensing terms provided in the InsightFace GitHub repository.

For more information on the capabilities of the InsightFace models and to ensure compliance with their license, please refer to their [official repository](https://github.com/deepinsight/insightface). Adhering to the specified licensing terms is crucial for the respectful and lawful use of their work.
