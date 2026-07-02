# Monorepo Structure Review

## Context

Review the current monorepo structure with a focus on networking, development workflow, and general best practices.

Project direction: local development and production deployments should both run through Docker. A contributor should not need host-installed Node, PNPM, Prisma, or Turborepo for normal workflows. VS Code development should use the root dev container so editor tooling, dependency resolution, Docker CLI, and Compose commands all run inside Docker.

## Findings

### High Priority

- **Task 1 (Addressed):** `.env` appears tracked or locally modified, while dotenv ignores are commented out in `.gitignore`. Treat this as a secret-leak risk. Track `.env.example`, ignore `.env`, and remove `.env` from git history/index if it ever contained real secrets.
- **Task 2 (Addressed):** Docker builds now exclude local secrets, dependency folders, build output, and runtime database state through `.dockerignore`. Postgres persists to the named Docker volume `postgres-data` instead of a repo-local `database/postgresql` directory.
- **Task 3 (Addressed):** `DATABASE_URL` now uses the Docker-internal address `postgres:5432`, while Compose publishes Postgres with a separate `POSTGRES_HOST_PORT`. A separate `LOCAL_DATABASE_URL` is available for host-side tooling.
- **Task 4 (Addressed):** Prisma now validates under Node `22.16.0`. `Post` is defined in the schema, database scripts invoke the package-local Prisma CLI, and the repo declares Prisma-compatible Node versions. Normal Prisma usage should still run inside Docker rather than requiring contributors to install Node locally.
- **Task 11 (Addressed):** Made the development command surface Docker-only. The earlier script-based wrappers were replaced by a devcontainer lifecycle model where `.devcontainer/devcontainer.json` starts required Compose services and `pnpm dev` from lifecycle hooks.

### Medium Priority

- **Task 5 (Addressed):** The default `${TOP_LEVEL_DOMAIN}` to `host-gateway` mapping has been removed from Compose. App containers now rely on Compose service DNS on Docker networks for internal traffic, while browser-facing links continue to go through the published nginx entrypoint. No service currently requires host access; if one does in the future, add `host.docker.internal:host-gateway` only to that specific service as an explicit escape hatch.
- **Task 6 (Addressed):** Nginx is now a real Compose service on `appnet`, publishes the browser-facing HTTP port, and proxies path-based routes to service DNS names such as `web-app-1:80` and `server-app-1:80`. This preserves clean browser URLs like `http://localhost/web-app-1/` while keeping app-to-app networking internal.
- **Task 7 (Addressed):** Dev app containers now bind mount the full `apps/` and `packages/` trees plus root workspace config files (`package.json`, `pnpm-lock.yaml`, `pnpm-workspace.yaml`, and `turbo.json`). This keeps Docker-based hot reload responsive to app code, shared package changes, Prisma files, and workspace config updates without requiring manual rebuilds for routine edit cycles.
- **Task 8 (Addressed):** Debug wiring now exposes stable inspect ports for both dev app containers, and the active Node dev commands bind the inspector to `0.0.0.0:9229` inside the container. VS Code launch settings include attach targets for both apps on the published debug ports.
- **Task 9 (Addressed):** Removed host-side dependency bootstrapping and broad Docker volume pruning from the active workflow. Cleanup and startup are now managed by the devcontainer lifecycle and Compose shutdown behavior.

### Low Priority

- **Task 10 (Addressed):** The obsolete Compose `version` fields have been removed from `docker-compose.yml` and `docker-compose.dev.yml`, so `docker compose config --quiet` no longer warns about schema version keys.

## Overall Feedback

The basic shape is good: apps live under `apps/`, shared code lives under `packages/`, Turborepo coordinates tasks, and the Compose networks separate app traffic from database traffic. Since the project direction is Docker-only local development and Docker-based production runtime, the main area to tighten is the command surface: scripts, docs, debugging, database tasks, dev-container tooling, networking, and production deployment should all assume Docker is the only local prerequisite. Use Docker networks for container-to-container traffic, and use a single browser-facing entrypoint such as nginx for links that need to work in webpages.

Current workflow reference: see `docs/repo/dev-workflow-modes.md` for the active devcontainer lifecycle startup guide and command matrix.

## Recommended Order

1. Task 1, Task 2: Ignore and untrack `.env`, add `.dockerignore`, and move Postgres persistence out of the repo.
2. Task 3: Split host-facing Postgres port configuration from the internal database URL, using `postgres:5432` inside containers.
3. Task 11, Task 9: Make wrapper scripts Docker-only and remove host PNPM/Node assumptions.
4. Task 7, Task 8: Rework dev mounts and debug scripts so Docker development hot-reloads apps and shared packages predictably.
5. Task 5, Task 6: Normalize Docker networking and decide whether nginx/path-based routing is part of the runtime.
6. Task 4: Keep Prisma validation and database commands running inside Docker, using the package-local CLI.