#!/bin/bash
docker compose --env-file .env -f docker-compose.yml -f docker-compose.dev.yml up  --force-recreate -d --build "$@"
docker volume prune --force --all