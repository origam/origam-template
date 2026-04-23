# ORIGAM Template

Install and run ORIGAM Server + Architect with Docker Compose.

This repo supports three deployment targets:

- Docker in WSL / Docker Desktop (Linux containers)
- Docker on regular Linux host
- Docker on Windows Container Service (Windows containers)

## Before you start

You need:

- Docker Engine / Docker Desktop with `docker compose`
- Free ports: `443` (Server), `8081` (Architect), plus `5432` or `1433` when using internal DB
- Write access to this project folder

ORIGAM is configured via environment variables (no `.env` file in this template).

Important: run commands in the folder that contains `docker-compose.yml`.
If you run from another folder, use `-f <full-path-to-docker-compose.yml>`.

## Choose your environment

### Install with Docker on WSL / Docker Desktop

Use this when Docker Desktop runs in Linux containers mode.
Pick the command for your shell.

#### WSL terminal (bash)

```bash
export DB_TYPE=postgres; export DB_HOST=postgres; export DB_NAME=origam; export DB_USERNAME=postgres; export DB_PASSWORD=postgres; export PROJECT_NAME=MainOrigam2; export ADMIN_USERNAME=admin; export ADMIN_PASSWORD=change-me; export ADMIN_EMAIL=no-reply@origam.com; export COMPOSE_PROFILES=$DB_TYPE,linux; docker compose up
```

#### PowerShell on Windows

```powershell
$env:DB_TYPE="postgres"; $env:DB_HOST="postgres"; $env:DB_NAME="origam"; $env:DB_USERNAME="postgres"; $env:DB_PASSWORD="postgres"; $env:PROJECT_NAME="MainOrigam2"; $env:ADMIN_USERNAME="admin"; $env:ADMIN_PASSWORD="change-me"; $env:ADMIN_EMAIL="no-reply@origam.com"; $env:COMPOSE_PROFILES="$env:DB_TYPE,linux"; docker compose up
```

#### Command Prompt CMD

```bat
set DB_TYPE=postgres&& set DB_HOST=postgres&& set DB_NAME=origam&& set DB_USERNAME=postgres&& set DB_PASSWORD=postgres&& set PROJECT_NAME=MainOrigam2&& set ADMIN_USERNAME=admin&& set ADMIN_PASSWORD=change-me&& set ADMIN_EMAIL=no-reply@origam.com&& set COMPOSE_PROFILES=%DB_TYPE%,linux&& docker compose up
```

### Install with Docker on Linux

Same runtime profile as WSL (`linux`):

```bash
export DB_TYPE=postgres; export DB_HOST=postgres; export DB_NAME=origam; export DB_USERNAME=postgres; export DB_PASSWORD=postgres; export PROJECT_NAME=MainOrigam2; export ADMIN_USERNAME=admin; export ADMIN_PASSWORD=change-me; export ADMIN_EMAIL=no-reply@origam.com; export COMPOSE_PROFILES=$DB_TYPE,linux; docker compose up
```

### Install with Docker on Windows Container Service

Use this when Docker is running Windows containers.

```powershell
$env:DB_TYPE="postgres"; $env:DB_HOST="172.20.0.1"; $env:DB_NAME="origam"; $env:DB_USERNAME="postgres"; $env:DB_PASSWORD="postgres"; $env:PROJECT_NAME="MainOrigam2"; $env:ADMIN_USERNAME="admin"; $env:ADMIN_PASSWORD="change-me"; $env:ADMIN_EMAIL="no-reply@origam.com"; $env:COMPOSE_PROFILES="$env:DB_TYPE,windows"; docker compose up
```

After startup:

- Server: https://localhost:443
- Architect: http://localhost:8081

## Database host rules

| Runtime | Internal DB | `DB_HOST` |
|---|---|---|
| `linux` | `postgres` or `mssql` | service name: `postgres` or `mssql` |
| `windows` | `postgres` or `mssql` | `172.20.0.1` |
| any | external DB | your DB hostname or IP |

## Profiles reference

| `COMPOSE_PROFILES` | Starts |
|---|---|
| `postgres,linux` | Linux ORIGAM + internal PostgreSQL |
| `mssql,linux` | Linux ORIGAM + internal MSSQL |
| `postgres,windows` | Windows ORIGAM + internal PostgreSQL |
| `mssql,windows` | Windows ORIGAM + internal MSSQL |
| `linux` | Linux ORIGAM only (external DB) |
| `windows` | Windows ORIGAM only (external DB) |

Tip: to switch PostgreSQL -> MSSQL, set `DB_TYPE=mssql`, `COMPOSE_PROFILES=mssql,<runtime>`, and set matching DB credentials.

## Important variables

| Variable | Description |
|---|---|
| `PROJECT_NAME` | Project name and output folder `./model/<PROJECT_NAME>` |
| `DB_TYPE` | `postgres` or `mssql` |
| `DB_HOST` | Database hostname from the rules above |
| `DB_NAME` | Application database name |
| `DB_USERNAME` | Database user |
| `DB_PASSWORD` | Database password |
| `ADMIN_USERNAME` | First ORIGAM admin login |
| `ADMIN_PASSWORD` | First ORIGAM admin password |
| `ADMIN_EMAIL` | First ORIGAM admin email |
| `COMPOSE_PROFILES` | Active runtime and database profiles |

## Windows containers firewall rule

For `stable-nat`, allow inbound traffic from `172.20.0.0/20`:

```powershell
New-NetFirewallRule `
  -DisplayName "Allow from stable-nat" `
  -Direction Inbound `
  -Action Allow `
  -RemoteAddress 172.20.0.0/20 `
  -Profile Any
```

## Common operations

```bash
# Start in background
docker compose up -d

# Stop stack
docker compose down

# Follow all logs
docker compose logs -f

# Composer logs
docker compose logs origam-composer-linux
docker compose logs origam-composer-windows
```

## Reset from scratch

```bash
docker compose down
rm -rf ./model/<PROJECT_NAME>
```

Run your install command again.

## Troubleshooting

- `port is already allocated`: free `443`, `8081`, `5432`, `1433` or change port mapping in `docker-compose.yml`
- Server/Architect do not start: check composer logs first
- DB connection errors: verify `DB_HOST`, `DB_USERNAME`, `DB_PASSWORD`, `DB_TYPE`

## Security

Examples use weak credentials for convenience.
Change `DB_PASSWORD` and `ADMIN_PASSWORD` before shared or production-like usage.
