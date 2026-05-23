# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository purpose

This is a **community fork** of [immich-app/immich](https://github.com/immich-app/immich). The fork exists solely to provide an `immich-machine-learning` image that supports NVIDIA Blackwell GPUs (RTX 50-series, sm_120) until upstream support lands — see `README.md` and `machine-learning/README.md`. Scope work to `machine-learning/` unless the user explicitly broadens it; the rest of the tree should stay as close to upstream as possible so periodic rebases stay clean.

Tracking issue: https://github.com/immich-app/immich/issues/28031. Detailed root-cause / fix notes for the Blackwell work live in `machine-learning/CUDA_BLACKWELL_HANDOFF.md`.

## Tooling

The repo uses [`mise`](https://mise.jdx.dev/) as the universal task runner across every subproject (`mise.toml` in the root, `server/`, `web/`, `mobile/`, `e2e/`, `machine-learning/`, etc.). Tools (Node 24, pnpm 10, Flutter, Java 21, jellyfin-ffmpeg, …) are pinned in the root `mise.toml`. Run `mise install` once to provision them.

Tasks are namespaced: `mise <task>` runs in the current directory's project, `mise //server:<task>` runs a task in a specific subproject, `mise //:<task>` runs a root-level task (e.g. `mise //:open-api` regenerates the SDK/Dart clients from the server's OpenAPI spec).

Package manager: pnpm workspace defined in `pnpm-workspace.yaml` (members: `packages/*`, `server`, `web`, `docs`, `e2e`, `i18n`, `.github`). ML uses `uv` (not pnpm). Mobile uses Flutter / Dart.

## Common commands

### Whole-stack dev (Docker)

The root `Makefile` wraps the dev/e2e/prod Docker Compose stacks:

- `make dev` — start the full dev stack (`docker/docker-compose.dev.yml`); auto-tears down on exit.
- `make dev-update` — same, but rebuild images.
- `make prod` — production compose (`docker/docker-compose.prod.yml`).
- `make e2e` / `make e2e-dev` — run the e2e stack.
- `make test-e2e` — build the e2e compose and run `pnpm --filter immich-e2e run test && test:web`.
- `make clean` — wipe `node_modules`, `dist`, `build`, `.svelte-kit`, `coverage`, `.pnpm-store`, and stop dev/e2e stacks.

### Server (`server/`, NestJS)

From `server/`:

- `mise install` — `pnpm install --filter immich --frozen-lockfile`.
- `mise build` — `nest build`.
- `mise test` — Vitest unit tests (`test/vitest.config.mjs`). Single test: `mise test -- path/to/file.spec.ts -t "test name"`.
- `mise test-medium` — Vitest medium / integration suite (`vitest.config.medium.mjs`).
- `mise lint` / `mise lint-fix` — ESLint with `--max-warnings 0`.
- `mise format` / `mise format-fix` — Prettier.
- `mise check` — `tsc --noEmit`.
- `mise migrations -- <create|generate|run|debug|query>` — DB migrations via `dist/bin/migrations.js`.
- `mise schema-reset` — drop + recreate the `public` schema and re-run migrations.
- `mise ci-unit` / `mise ci-medium` / `mise checklist` — composite CI tasks.

### Web (`web/`, SvelteKit)

From `web/`:

- `mise start` — `pnpm run dev` (depends on installing & building the SDK first).
- `mise build`, `mise preview`.
- `mise test`, `mise lint`, `mise format`, `mise check` (typescript + svelte-check), `mise check-typescript`, `mise check-svelte`.
- `mise ci-unit` / `mise checklist` — composite CI tasks.

### Machine learning (`machine-learning/`, Python + FastAPI)

Uses `uv`. From `machine-learning/`:

- `uv sync --extra cpu` (or `--extra cuda` / `--extra openvino` / `--extra rocm` / `--extra armnn` / `--extra rknn`) — provision the venv with the chosen ONNX Runtime backend.
- `uv run pytest` — run unit tests (`test_main.py`). Single test: `uv run pytest test_main.py::TestClass::test_name`.
- `uv run ruff check` / `uv run ruff format` — lint / format (line length 120, target `py311`).
- `uv run mypy immich_ml` — type-check (strict mypy config with the pydantic plugin).
- `uv lock` after changing dependencies; commit `uv.lock` + `pyproject.toml`.
- Load testing: `locust --web-host 127.0.0.1` then `localhost:8089`.

### Root

- `pnpm format` / `pnpm format:fix` — Prettier over `i18n/`.
- `mise //:open-api` — regenerate the TS and Dart OpenAPI clients (builds the server, dumps the spec to `open-api/immich-openapi-specs.json`, runs `oazapfts` for TS, and `open-api/bin/generate-dart-sdk.sh` for Dart). Run this whenever server DTOs change.
- `mise //:plugins` — install + build `@immich/plugin-sdk` and `@immich/plugin-core`.

## Architecture (big picture)

This is a self-hosted photo / video platform. Services run as separate containers and talk over HTTP. The OpenAPI spec generated from the server is the contract between the server and every client (web, mobile, CLI, SDK).

### Server (`server/src/`, NestJS)

- `controllers/` — HTTP endpoints; decorated DTOs auto-generate the OpenAPI spec.
- `services/` — business logic.
- `repositories/` — data access; the server uses **Kysely** (not TypeORM) for queries, with a custom migration system in `bin/migrations.ts` driving SQL in `src/schema/`.
- `dtos/` — request/response shapes; changes here ripple into generated SDKs.
- `workers/` — background job processors (microservices entry).
- `bin/` — operational scripts (migrations, OpenAPI sync, SQL sync).
- Two runtime entrypoints: the API server and the microservices worker, both in the same Nest application but selected at boot.
- After editing DTOs or controllers, run `mise //server:sync-open-api` then `mise //:open-api` to refresh downstream clients.

### Web (`web/`, SvelteKit + Svelte 5 + Tailwind v4)

Consumes `@immich/sdk` (generated TS client). Tailwind v4 with custom Immich UI components from `@immich/ui` (peer dep on `tailwindcss >=4.1`).

### Mobile (`mobile/`, Flutter / Dart)

Dart OpenAPI client is regenerated by `open-api/bin/generate-dart-sdk.sh`. DCM is used for static analysis; see `mobile/dcm_global.yaml` and `analysis_options.yaml`. Drift is used for the local DB (`drift_schemas/`).

### Machine learning (`machine-learning/`, Python / FastAPI / ONNX Runtime)

- FastAPI app under `immich_ml/main.py`; entrypoint is `python -m immich_ml`.
- `models/` — CLIP embeddings + facial recognition (InsightFace antelopev2 / buffalo_l/m/s — note the InsightFace license restriction documented in the ML README).
- `sessions/` — ONNX Runtime session lifecycle, chooses provider based on the `DEVICE` build arg / runtime configuration.
- Config is Pydantic-based (`config.py`); gunicorn config lives in `gunicorn_conf.py`.
- The Dockerfile is multi-stage (`builder-{cpu,cuda,openvino,armnn,rknn,rocm}` → `prod-*` → final `prod`) with the device selected by `--build-arg DEVICE=…`.

### Packages (`packages/`)

- `sdk/` — generated TypeScript client (`@immich/sdk`).
- `cli/` — the upload CLI.
- `plugin-sdk/`, `plugin-core/` — extism / WebAssembly plugin system.
- `e2e-auth-server/` — auth helper used by e2e tests.

### E2E (`e2e/`)

Compose-based integration tests; `make e2e` and `make test-e2e` are the entry points. Server and web are tested against a real Postgres + Redis.

### Docker / deployment

- `docker/` — production and dev compose files, plus hwaccel overrides (`hwaccel.ml.yml`, `hwaccel.transcoding.yml`).
- `.github/workflows/docker.yml` builds and publishes `immich-machine-learning` and `immich-server` to `ghcr.io/${repo_owner}/…` on changes to the respective paths. **On this fork that means images publish under `ghcr.io/ekropotin/…`, not `ghcr.io/immich-app/…`.**

## Fork-specific constraints (machine-learning/Dockerfile)

The `prod-cuda` stage pins `nvidia/cuda:12.8.1-runtime-ubuntu22.04` for sm_120. When `libcudnn9-cuda-12=9.10.2.21-1` is installed (kept at 9.10 because 9.11 dropped Pascal), apt drags in `cuda-cudart-12-2` and overwrites the CUDA 12.8 runtime via `update-alternatives`. Mitigations already in the Dockerfile — preserve them when editing:

1. After installing cuDNN, reinstall `cuda-cudart-12-8`, `apt-mark manual` it, and `update-alternatives --set cuda /usr/local/cuda-12.8`.
2. A guard in the final `prod` stage re-pins the symlink after all apt operations, because `apt-get autoremove` re-triggers `update-alternatives`.

Do **not** simplify these to a single `ln -sfn` — see `machine-learning/CUDA_BLACKWELL_HANDOFF.md` for the full root cause and alternatives that were rejected.

## Notes

- Upstream policy is **no LLM-generated PRs** (`CONTRIBUTING.md`). This fork is independent of that policy, but anything proposed back upstream needs to follow it.
- Feature freezes upstream: Sharing/Asset ownership, External libraries (per `CONTRIBUTING.md`).
