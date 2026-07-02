# Monorepo Framework Philosophy

## Purpose

This repository is a starter framework for building new monorepo projects. The goal is not just to hold multiple apps and packages in one place, but to provide a repeatable operating model for local development, production deployment, and contributor onboarding.

The framework is opinionated in a few important ways:

- Local development should work through Docker.
- Production deployment should follow the same container-first model.
- Shared code should live in workspace packages, not be duplicated across apps.
- The command surface should be small, explicit, and consistent.
- Infrastructure decisions should optimize for repeatability over host-specific convenience.

## Core Principles

### Docker Is the Runtime Contract

The most important project decision is that contributors should not need host-installed Node, PNPM, Prisma, or Turborepo for normal workflows. Docker is the contract for both development and deployment.

Takeaway:

- When a tool is required for normal work, prefer running it inside a container.
- Host tooling should be optional and used only for edge cases.
- If documentation and scripts disagree on whether Docker is required, Docker should win and the docs should be corrected.

### The Monorepo Should Separate Apps From Shared Capabilities

Applications belong in `apps/`. Shared concerns belong in `packages/`. This keeps boundaries clear and makes new projects easier to scaffold from the same template.

Takeaway:

- Put deployable surfaces in `apps/`.
- Put reusable logic, configuration, UI, logging, data access, and presets in `packages/`.
- Keep workspace conventions at the repo root so all apps inherit the same baseline.

### Internal Networking and Browser Routing Are Different Problems

Container-to-container traffic should use Docker networking and Compose service DNS. Browser-facing links should use a single published HTTP entrypoint.

The current framework uses nginx as that entrypoint. It publishes the host HTTP port and routes path-based URLs to internal services such as `web-app-1` and `server-app-1`. The public contract is split into two parts: a repo host such as `mono-repo-1.cadenscharpf.com`, and app base paths such as `/web-app-1`.

For local development, prefer a high host port (for example `PORT=18080`) instead of `80` when the stack is being accessed from Windows through WSL or Docker Desktop. This avoids conflicts and makes the browser entrypoint explicit.

Takeaway:

- Use Compose service names for internal traffic, such as `postgres:5432` or `server-app-1:80`.
- Do not make browser URLs depend on Docker service DNS.
- Expose one browser-facing gateway when multiple apps need to link to each other.
- Treat `host.docker.internal` as an exception, not the default design.
- Parameterize the repo host separately from each app base path so multiple monorepos can coexist behind one external reverse proxy.

### Environment Variables Should Reflect Real Boundaries

Environment configuration should describe the actual runtime model. Internal container URLs and host-facing URLs should not be conflated.

Examples from this framework:

- `DATABASE_URL` uses `postgres:5432` for container-internal access.
- `LOCAL_DATABASE_URL` exists separately for host-side access when needed.
- Public app URLs are built from a repo host plus app base paths, rather than app-specific published ports.

Takeaway:

- Split internal and external addresses when they serve different consumers.
- Remove stale environment variables when architecture changes.
- Prefer env files that describe current behavior, not previous experiments.

### Developer Experience Must Survive Shared-Workspace Complexity

Hot reload and debugger attach need to work even when code lives across multiple packages. A monorepo starter is only useful if edits to shared code behave predictably during development.

The current dev setup mounts the `apps/` and `packages/` trees plus root workspace config so changes propagate into containers immediately. At the same time, container-managed `node_modules` must be preserved so pnpm workspace links and dev binaries remain intact.

Takeaway:

- Bind mount source code and workspace config that developers edit frequently.
- Preserve container-managed dependency directories when using pnpm workspaces.
- Make debugger ports explicit and bind Node inspectors to `0.0.0.0` inside containers.

## Expected Workflow

### Development

Use the devcontainer lifecycle as the primary interface:

- `runServices` starts `postgres`.
- `postCreateCommand` runs `corepack enable && pnpm install`.
- `postStartCommand` runs `pnpm dev` so Turbo starts app dev processes.
- `shutdownAction: stopCompose` stops Compose services when the devcontainer stops.

This means common operations such as installing dependencies, running Prisma commands, invoking Turborepo tasks, or using PNPM should happen through the workspace container rather than on the host.

For the current devcontainer startup model and command reference, see `docs/repo/dev-workflow-modes.md`.

### Editing and Debugging

VS Code should connect through the root dev container so the editor, terminal, Docker CLI, and workspace dependencies all share the same containerized environment.

Application debugging follows a container-first model:

- each app exposes a stable inspect port
- Node listens on `0.0.0.0:9229` inside the container
- VS Code attaches to the published debug port from the host

### Building and Deploying

Docker images should be the deployment artifact, not host-built output. Multi-stage builds and Turbo pruning are used to keep images scoped to the app being built while preserving workspace structure.

Takeaway:

- Build once from the monorepo context.
- Ship container images that already contain the required runtime assets.
- Keep production behavior aligned with the development topology whenever practical.

## Design Decisions and Lessons Learned

### Use Named Volumes for Runtime State

Database state should live in Docker-managed volumes, not repo-local directories.

Why:

- it keeps local state out of source control
- it avoids permission and cleanup issues
- it makes the repository easier to clone, reset, and reuse as a template

### Prefer a Real Reverse Proxy Over Port Sprawl

Publishing every app directly to the host scales poorly once apps need to link to each other or present a cohesive local surface.

Why:

- a single entrypoint gives predictable browser URLs
- internal app topology can change without changing public links
- reverse proxy rules map cleanly to production patterns

### Separate Repo Identity From App Identity

If multiple monorepos may run on the same machine or behind the same public domain, the repo itself needs a public identity that is distinct from the apps inside it.

Why:

- different repos can use different hosts such as `mono-repo-1.cadenscharpf.com` and `mono-repo-2.cadenscharpf.com`
- apps inside each repo can still use stable paths such as `/web-app-1`
- the external reverse proxy only needs to know which host maps to which monorepo nginx
- internal monorepo routing stays self-contained

### Keep Host Escape Hatches Explicit

Default `host-gateway` mappings were removed. If a service truly needs host access later, that exception should be added deliberately and only to the service that needs it.

Why:

- it keeps internal networking honest
- it reduces hidden host dependencies
- it makes portability better across machines and environments

### Small Script Surfaces Beat Implicit Tribal Knowledge

The project should expose a few stable scripts instead of expecting contributors to remember a chain of Docker, PNPM, Prisma, and Turbo commands.

Why:

- onboarding is faster
- mistakes are less likely
- the framework becomes easier to reuse in future monorepo projects

## Guidance for Future Projects

If this repository is used as the basis for a new monorepo, preserve these defaults unless a project has a clear reason not to:

1. Keep Docker as the required local runtime.
2. Keep app code under `apps/` and reusable code under `packages/`.
3. Use Compose DNS for internal service traffic.
4. Use one published browser entrypoint for cross-app navigation.
5. Keep host-specific behavior isolated and explicit.
6. Treat workspace tooling, debug wiring, and hot reload as first-class design requirements.

When running multiple monorepos behind one external edge proxy, give each repo its own host and let the monorepo-local nginx route app paths inside that host. Example URLs:

- `http://mono-repo-1.cadenscharpf.com/web-app-1`
- `http://mono-repo-2.cadenscharpf.com/web-app-1`

For a concrete Cloudflare plus host-nginx setup, see `docs/multi-monorepo-host-routing.md`.

## Summary

This framework is meant to reduce setup drift and make new monorepo projects feel operationally complete from the start. The main lesson from the review work is that infrastructure, tooling, and docs must reinforce the same model: Docker is the platform, the monorepo is the boundary, and developer workflows should be predictable enough to copy into the next project with minimal reinvention.