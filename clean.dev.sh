#!/bin/bash
set -euo pipefail

docker compose --env-file .env -f docker-compose.yml -f docker-compose.dev.yml down --remove-orphans "$@"
