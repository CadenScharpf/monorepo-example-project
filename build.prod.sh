#docker system prune --volumes -f
#pnpm install
docker compose --env-file .env -f docker-compose.yml up -d --build "$@"
docker rmi $(docker images -f "dangling=true" -q)