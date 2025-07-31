#docker system prune --volumes -f
docker compose --env-file .env -f docker-compose.yml up -d --build "$@"
docker rmi $(docker images -f "dangling=true" -q)