#!/bin/bash
set -euo pipefail

compose=(
  docker compose
  --env-file .env
  -f docker-compose.yml
  -f docker-compose.dev.yml
)

"${compose[@]}" run --rm --build workspace "$@"
