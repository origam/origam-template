# ORIGAM Template

Install and run ORIGAM Server + Architect with Docker Compose.

This repo supports three deployment targets:

- Docker in WSL / Docker Desktop (Linux containers)
- Docker on regular Linux host or Mac
- Docker on Windows Container Service (Windows containers)

## Choose your environment

### Install on your Windows environment with WSL / Docker Desktop

Use this when Docker Desktop runs in Linux containers mode.

#### Command Prompt CMD

```bat
set DB_TYPE=postgres&& set DB_HOST=postgres&& set DB_NAME=origam&& set DB_USERNAME=postgres&& set DB_PASSWORD=postgres&& set PROJECT_NAME=MainOrigam2&& set ADMIN_USERNAME=admin&& set ADMIN_PASSWORD=change-me&& set ADMIN_EMAIL=no-reply@origam.com&& set COMPOSE_PROFILES=%DB_TYPE%,linux&& docker compose up
```

### Install with Docker on Linux or Mac

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

## Database host rules

| Runtime | Internal DB in this compose | `DB_HOST` |
|---|---|---|
| `linux` | Supported (`postgres` or `mssql` profile) | `postgres` or `mssql` |
| `windows` | Not supported (DB images are Linux-based) | `172.20.0.1` (host / gateway) |

## Runtime notes

### Linux runtime (`COMPOSE_PROFILES=...,linux`)

- You can run ORIGAM with internal PostgreSQL or MSSQL.
- Use `DB_HOST=postgres` or `DB_HOST=mssql`.
- App and DB communicate by Docker service name.

### Windows runtime (`COMPOSE_PROFILES=windows`)

- Use external DB (on host machine or remote server).
- Set `DB_HOST=172.20.0.1` for DB on the same Windows host.
- If DB is remote, set `DB_HOST=<remote-host-or-ip>`.

## Windows containers firewall rule

The compose file defines network `stable-nat` with subnet `172.20.0.0/20` and gateway `172.20.0.1`.
Allow inbound traffic from that subnet on the DB host:

```powershell
New-NetFirewallRule `
  -DisplayName "Allow from stable-nat" `
  -Direction Inbound `
  -Action Allow `
  -RemoteAddress 172.20.0.0/20 `
  -Profile Any
```

Prerequisites for Windows runtime:

- PostgreSQL or MSSQL is installed on host or reachable remotely.
- DB allows incoming connections from `172.20.0.0/20`.
- DB auth allows container clients (for example SQL auth / `pg_hba.conf`).
## Profiles reference

| `COMPOSE_PROFILES` | Starts |
|---|---|
| `postgres,linux` | Linux ORIGAM + internal PostgreSQL |
| `mssql,linux` | Linux ORIGAM + internal MSSQL |
| `windows` | Windows ORIGAM only (external DB) |
| `linux` | Linux ORIGAM only (external DB) |

Note: `postgres,windows` and `mssql,windows` are not supported in Windows containers mode.

Tip: to switch PostgreSQL -> MSSQL, set `DB_TYPE=mssql`, `COMPOSE_PROFILES=mssql,<runtime>`, and set matching DB credentials.
