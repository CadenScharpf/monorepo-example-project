#!/usr/bin/env sh
set -e

# Defaults
APP_PORT="${PORT:-80}"

echo "Starting app on port $APP_PORT"
exec node ./bin/www
