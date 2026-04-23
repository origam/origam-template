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

| Runtime | Internal DB (in Docker) | `DB_HOST` Value |
|---------|------------------------|-----------------|
| Linux   | **Supported** — PostgreSQL and MSSQL run as Docker services alongside the app | Service name: `postgres` or `mssql` |
| Windows | **Not supported** — Windows containers cannot run PostgreSQL/MSSQL as Docker services | Host machine IP: `172.20.0.1` |
 
## Linux Runtime
 
PostgreSQL or MSSQL can be started as separate services within the same Docker Compose stack. Since all containers share a Docker network, they communicate using service names as hostnames.
 
**Configuration:**
 
```env
DB_HOST=postgres   # or mssql
```
 
No additional setup is required — the database service starts automatically with the rest of the stack.
 
## Windows Runtime


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
 
Windows containers do not support running PostgreSQL or MSSQL as internal Docker services. Instead, you need to install and run the database engine directly on the host machine (or connect to a remote database server).
 
The application container connects to the host via the Docker network gateway address.
 
**Configuration:**
 
```env
DB_HOST=172.20.0.1
```
 
**Prerequisites:**
 
- PostgreSQL or MSSQL must be installed and running on the host machine (or on a remote server accessible from the container).
- The database must accept connections from the Docker network subnet (`172.20.0.0/16`).
- Authentication must be configured to allow connections from the container (e.g., SQL Server authentication or `pg_hba.conf` for PostgreSQL).
> **Note:** The gateway address `172.20.0.1` corresponds to the default Docker network configuration. If you are using a custom Docker network, verify the gateway address by running `docker network inspect <network_name>`.
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
