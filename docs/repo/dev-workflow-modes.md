# Development Workflow

This repository now uses a devcontainer-first startup model.

## How Services Start

1. Devcontainer starts the `workspace` service from Compose.
2. `runServices` starts `postgres` automatically.
3. `postCreateCommand` runs `corepack enable && pnpm install`.
4. `postStartCommand` launches `pnpm dev` (Turbo) to run app dev processes.
5. `shutdownAction: stopCompose` stops Compose services when the container stops.

## Primary Commands

- Normal development: `pnpm dev`
- Build all: `pnpm build`
- Run tests: `pnpm test`

## Startup Verification

Use these VS Code tasks after opening the devcontainer:

- `Dev:Logs` to follow `/tmp/pnpm-dev.log` and confirm Turbo has started watchers.
- `Dev:Healthcheck` to verify both the web app and API health endpoint are reachable.

## Debug Notes

- Inspect ports come from `.env` (`WEB_APP_1_DEBUG_PORT`, `SERVER_APP_1_DEBUG_PORT`).
- Use VS Code compound launch `Debug: Web + Server`.
