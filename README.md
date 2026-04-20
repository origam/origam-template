# ORIGAM Template

Docker Compose template that:

- generates a new ORIGAM project with `Origam.Composer`
- starts ORIGAM Server + Architect
- optionally starts an internal MSSQL or PostgreSQL database

No local ORIGAM binaries are required.

## Quick Start (60 seconds)

1. Edit `.env`:
   - set `PROJECT_NAME`
   - set `DB_TYPE` (`mssql` or `postgres`)
   - set strong `DB_PASSWORD`, `ADMIN_PASSWORD`
2. Run one of startup profiles (see table below).
3. Open:
   - Server: `https://localhost:${SERVER_PORT}`
   - Architect: `http://localhost:${ARCHITECT_PORT}`

## Run Profiles

| Scenario | Command | Use when |
|---|---|---|
| Linux + internal MSSQL | `docker compose --profile mssql-internal --profile linux up` | Default local development flow |
| Linux + internal PostgreSQL | `docker compose --profile postgres-internal --profile linux up` | You want PostgreSQL locally |
| Linux + external database | `docker compose --profile linux up` | You use an existing external MSSQL/PostgreSQL database (requires updating .env host/port) |
| Windows containers | `docker compose --profile windows up` | You run ORIGAM in Windows container mode |

Tip: add `-d` for detached mode.

### Linux profile on Windows (WSL2)

If Docker Desktop is using Linux containers, then Windows + WSL2 is effectively the same runtime as Linux for this project.

Use Linux profile commands in both cases:

- `docker compose --profile mssql-internal --profile linux up`
- `docker compose --profile postgres-internal --profile linux up`

Use `--profile windows` only when you explicitly switch Docker Desktop to Windows containers.

## Configuration (`.env`)

All settings and image tags live in `.env`.

### Required minimum

- `PROJECT_NAME` - output project name in `./model/<PROJECT_NAME>`
- `DB_TYPE` - `mssql` or `postgres`
- `DB_PASSWORD` - DB user password
- `ADMIN_USERNAME`, `ADMIN_PASSWORD`, `ADMIN_EMAIL` - initial app admin

### Practical defaults

- `DB_TYPE=mssql`
- `DB_PORT=1433` for MSSQL
- `DB_PORT=5432` for PostgreSQL
- `SERVER_PORT=443`
- `ARCHITECT_PORT=8081`

### Host values by runtime

- Linux containers use `DB_HOST_LINUX` (default: service name, e.g. `mssql`/`postgres`)
- Windows containers use `DB_HOST_WINDOWS`

`DB_HOST_WINDOWS=172.20.0.1` is the host gateway on the `stable-nat` Docker network in this setup.

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

## Architecture at a glance

1. Composer container creates project files in `./model/<PROJECT_NAME>`.
2. Server/Architect wait for generated environment files in `./model/<PROJECT_NAME>/docker`.
3. Server/Architect load env vars from generated files.
4. Server/Architect map generated model/custom assets to runtime paths.

## Idempotent behavior and regeneration

`docker compose up` is idempotent for project generation:

- if `./model/<PROJECT_NAME>/model` and `./model/<PROJECT_NAME>/docker` exist, Composer skips generation
- services still start normally

To regenerate project files from scratch:

1. Stop stack: `docker compose down`
2. Remove `./model/<PROJECT_NAME>`
3. (Optional) Delete the `origam` database if you need to start with a clean database
4. Run `docker compose up` again with your desired profiles

## Windows-only note (Firewall)

For Windows containers service, add inbound access from `stable-nat`:

```powershell
New-NetFirewallRule `
  -DisplayName "Allow from stable-nat" `
  -Direction Inbound `
  -Action Allow `
  -RemoteAddress 172.20.0.0/20 `
  -Profile Any
```

## Troubleshooting

- `port is already allocated`:
  - change `SERVER_PORT`, `ARCHITECT_PORT`, or `DB_PORT` in `.env`
- project was not generated:
  - check Composer logs: `docker compose logs origam-composer-linux` or `docker compose logs origam-composer-windows`
- Server/Architect waiting forever:
  - verify generated env file exists in `./model/<PROJECT_NAME>/docker`
- DB connection errors:
  - confirm `DB_TYPE`, `DB_HOST_*`, `DB_PORT`, `DB_USERNAME`, `DB_PASSWORD`
  - ensure corresponding DB profile is enabled when using internal DB
- Windows DB host issues:
  - verify `stable-nat` network exists and gateway `172.20.0.1` is reachable

## Security notes

- Do not commit real passwords to git.
- Always replace default credentials before shared or production-like usage.
- For team setups, keep sensitive overrides in local, untracked env files.

## Useful commands

```bash
# Start with selected profiles
docker compose --profile mssql-internal --profile linux up

# Start detached
docker compose --profile mssql-internal --profile linux up -d

# Stop and remove containers/networks
docker compose down

# Follow logs
docker compose logs -f
```
