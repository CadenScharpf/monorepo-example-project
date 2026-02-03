#!/usr/bin/env sh
set -e

# Defaults
APP_PORT="${PORT:-80}"
DEBUG_PORT="${DEBUG_PORT:-9229}"

if [ "$NODE_ENV" = "development" ]; then
  echo "Starting app on port $APP_PORT with debugger on $DEBUG_PORT"
  exec node --inspect=0.0.0.0:"$DEBUG_PORT" ./bin/www
else
  echo "Starting app on port $APP_PORT"
  exec node ./bin/www
fi