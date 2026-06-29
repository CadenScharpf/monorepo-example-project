# Multi-Monorepo Host Routing (Cloudflare + Host Nginx)

## Goal

Run multiple monorepos of this framework on the same machine behind one domain, with URLs such as:

- `https://mono-repo-1.cadenscharpf.com/web-app-1`
- `https://mono-repo-2.cadenscharpf.com/web-app-1`

Each monorepo keeps its own internal nginx for app-level routing, while a host-level external nginx routes by subdomain.

## Architecture

Request path:

1. Browser resolves subdomain in Cloudflare DNS.
2. Cloudflare sends traffic to your host public IP.
3. Host nginx routes by `Host` header to the correct monorepo port.
4. Monorepo nginx routes app paths (`/web-app-1`, `/server-app-1`) to internal services.

This gives strong monorepo isolation and keeps app routing logic inside each repo.

## Cloudflare DNS

Create one DNS record per monorepo host, all pointing to the same machine IP:

- `mono-repo-1.cadenscharpf.com` -> your host public IP
- `mono-repo-2.cadenscharpf.com` -> your host public IP

Recommended:

- Record type: `A` (or `AAAA` if you have IPv6)
- Proxy mode: start with DNS only while validating; switch to proxied once stable

## Your Dynamic-IP Updater Container

Your IP-updater container is relevant and useful.

It should update the Cloudflare DNS records when your home/public IP changes. That solves DNS correctness. It does not replace host nginx routing or per-monorepo port mapping.

If the updater supports multiple hostnames, ensure it updates both subdomains (or all monorepo subdomains you use).

## Host Nginx (External Edge)

Host nginx should listen on `80/443` and route each subdomain to a different local monorepo port.

Example:

```nginx
# /etc/nginx/conf.d/monorepos.conf

server {
    listen 80;
    server_name mono-repo-1.cadenscharpf.com;

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}

server {
    listen 80;
    server_name mono-repo-2.cadenscharpf.com;

    location / {
        proxy_pass http://127.0.0.1:8081;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

Notes:

- Use TLS (`443`) with certificates once routing is confirmed.
- Keep host nginx as the only public edge.
- Monorepo ports (`8080`, `8081`, etc.) should only be reachable locally on the host when possible.

## Per-Repo Configuration

Each monorepo needs a unique `PORT` and repo-specific `REPO_HOST`.

Example for repo 1 (`.env`):

```env
REPO_HOST=mono-repo-1.cadenscharpf.com
PORT=8080
WEB_APP_1_BASE_PATH=web-app-1
SERVER_APP_1_BASE_PATH=server-app-1
```

Example for repo 2 (`.env`):

```env
REPO_HOST=mono-repo-2.cadenscharpf.com
PORT=8081
WEB_APP_1_BASE_PATH=web-app-1
SERVER_APP_1_BASE_PATH=server-app-1
```

Then expected public URLs are:

- `https://mono-repo-1.cadenscharpf.com/web-app-1`
- `https://mono-repo-2.cadenscharpf.com/web-app-1`

## Validation Checklist

1. Start each monorepo and verify its local port (`PORT`) is published.
2. Verify host nginx routes each `Host` to the correct local monorepo port.
3. Verify monorepo nginx serves app paths under `/<APP_BASE_PATH>`.
4. Verify frontend assets load under the app base path.
5. Verify websocket-based dev tooling works through both proxy layers.
6. Verify Cloudflare DNS records point to your current public IP.

## Common Pitfalls

- Reusing the same `PORT` across multiple monorepos.
- Forgetting to set per-repo `REPO_HOST`.
- Missing websocket proxy headers on host nginx.
- Frontend apps not configured for path-based hosting.
- IP-updater only updating one subdomain when multiple are in use.

## Summary

Use Cloudflare for hostname-to-IP resolution, host nginx for subdomain-to-monorepo routing, and monorepo nginx for app-level path routing. Your IP-updater container remains important for keeping DNS records current, especially on dynamic residential IPs.
