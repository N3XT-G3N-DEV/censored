docker compose kill -s SIGINT && rm ./Dockerfile ./.env ./.dockerignore ./docker-compose.yml && docker system prune --volumes -a -f