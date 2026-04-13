# origam-template

docker build -f DockerfileArchitect.windows-nano -t origam/architect:2026.4.alpha.4213.win-nano .

docker compose --profile win --profile win-app up

docker compose --profile mssql --profile linux --profile app up

docker compose --profile postgres --profile linux --profile app down -v

docker compose --profile postgres --profile linux --profile app up

docker compose --profile linux --profile app up

docker compose --profile win --profile app up