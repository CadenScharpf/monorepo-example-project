#!/bin/bash
set -euo pipefail

docker compose --env-file .env -f docker-compose.yml up -d --build "$@"
