# origam-template

Docker-Compose template that spins up ORIGAM (server + architect) and generates
a new project via the **Origam.Composer Docker image** — no local binaries
required.

## Usage

All image tags and project settings live in `.env`.

## Configuration via `.env`

### Required values

- `DB_TYPE` — database type:
  - `mssql` (recommended default)
  - `postgres`
- `PROJECT_NAME` — project name (for example `Test2`)
- `DB_PASSWORD` — database password

### Recommended defaults

- `DB_TYPE=mssql`
- `DB_PORT=1433` for `mssql`
- `DB_PORT=5432` for `postgres`
- `SERVER_PORT=443`
- `ARCHITECT_PORT=8081`

### Example: MSSQL (default)

```env
DB_TYPE=mssql
DB_HOST_LINUX=mssql
DB_HOST_WINDOWS=172.20.0.1
DB_PORT=1433
DB_NAME=origam
DB_USERNAME=sa
DB_PASSWORD='yourStrong(!)Password'
```

`DB_HOST_WINDOWS=172.20.0.1` is used because Windows containers in this setup run on the `stable-nat` Docker network, where `172.20.0.1` acts as the host gateway (effectively the container-side equivalent of localhost for reaching host services).

### Example: PostgreSQL (default)

```env
DB_TYPE=postgres
DB_HOST_LINUX=postgres
DB_HOST_WINDOWS=172.20.0.1
DB_PORT=5432
DB_NAME=origam
DB_USERNAME=postgres
DB_PASSWORD=postgres
```

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
