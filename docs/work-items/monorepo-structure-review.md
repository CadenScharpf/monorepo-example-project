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
- **Task 11 (Addressed):** Make the development command surface Docker-only. `build.dev.sh` and `build.prod.sh` now only call Docker, `docker.workspace.sh` runs workspace commands such as PNPM, Turborepo, and Prisma inside the Docker `workspace` service, and `.devcontainer/devcontainer.json` provides a root monorepo dev container with Docker CLI access.

### Medium Priority

- **Task 5:** `extra_hosts` maps `${TOP_LEVEL_DOMAIN}` to `host-gateway`. With Docker-only development, containers should usually talk through Compose service DNS and internal networks. Keep host-gateway only as an explicit dev escape hatch, preferably under a dedicated alias like `host.docker.internal`.
- **Task 6:** The nginx template proxies to `host.docker.internal`, but there is no nginx service in Compose, and the current `extra_hosts` does not define `host.docker.internal`. If path-based routing is part of the Docker runtime story, add nginx as a real Compose service; otherwise remove the unused template and task references.
- **Task 7:** Dev app-container bind mounts only app `src`, `public`, and `package.json`. The dev container gives the IDE access to the whole monorepo and dependency volumes, but runtime hot reload should still cover `apps/*`, `packages/*`, workspace config, Prisma files, and generated output without requiring manual app-container rebuilds for shared package changes.
- **Task 8:** Debug wiring is inconsistent. Docker-based debugging should expose stable inspect ports, and Node processes that need debugger attach should listen on `0.0.0.0:9229` inside the container.
- **Task 9 (Addressed):** `build.dev.sh` no longer runs host `pnpm install` or broad Docker volume pruning. Project-scoped cleanup is available through `clean.dev.sh`.

### Low Priority

- **Task 10:** Compose `version` is obsolete in both `docker-compose.yml` and `docker-compose.dev.yml`; `docker compose config --quiet` warns about this.

## Overall Feedback

The basic shape is good: apps live under `apps/`, shared code lives under `packages/`, Turborepo coordinates tasks, and the Compose networks separate app traffic from database traffic. Since the project direction is Docker-only local development and Docker-based production runtime, the main area to tighten is the command surface: scripts, docs, debugging, database tasks, dev-container tooling, and production deployment should all assume Docker is the only local prerequisite.

## Recommended Order

1. Task 1, Task 2: Ignore and untrack `.env`, add `.dockerignore`, and move Postgres persistence out of the repo.
2. Task 3: Split host-facing Postgres port configuration from the internal database URL, using `postgres:5432` inside containers.
3. Task 11, Task 9: Make wrapper scripts Docker-only and remove host PNPM/Node assumptions.
4. Task 7, Task 8: Rework dev mounts and debug scripts so Docker development hot-reloads apps and shared packages predictably.
5. Task 5, Task 6: Normalize Docker networking and decide whether nginx/path-based routing is part of the runtime.
6. Task 4: Keep Prisma validation and database commands running inside Docker, using the package-local CLI.
