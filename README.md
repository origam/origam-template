# origam-template

Docker-Compose template that spins up ORIGAM (server + architect) and generates
a new project via the **Origam.Composer Docker image** — no local binaries
required.

## Usage

All image tags and project settings live in `.env`.

### Generate a project + run on Linux containers (MSSQL from compose):

```
docker compose --profile mssql --profile linux --profile app up
```

### Generate a project + run on Linux containers (bundled PostgreSQL):

```
docker compose --profile postgres --profile linux --profile app up
```

### Generate a project + run on Windows containers:

```
docker compose --profile mssql --profile win --profile win-app up
```

### Tear down and clear volumes:

```
docker compose --profile postgres --profile linux --profile app down -v
```

## How it works

The `create-project-linux` / `create-project-windows` services use
`origam/composer:<tag>` directly — the entrypoint runs
`dotnet Origam.Composer.dll create` with args populated from `.env`.

If `./model/<PROJECT_NAME>/docker` already exists, the Composer step is
skipped, so `up` is idempotent. To regenerate, delete that folder first.
