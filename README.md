# ORIGAM Template

Docker Compose template that bootstraps a new ORIGAM project and starts the Server + Architect containers. Optionally runs an internal PostgreSQL or MSSQL database alongside. No local ORIGAM binaries required.

## Quick start

Pick the one-liner for your shell. It sets the required environment variables and starts the stack.

### PowerShell (Windows / Docker Desktop)

```powershell
$env:DB_TYPE="postgres"; $env:DB_HOST="postgres"; $env:DB_NAME="origam"; $env:DB_USERNAME="postgres"; $env:DB_PASSWORD="postgres"; $env:PROJECT_NAME="MainOrigam2"; $env:ADMIN_USERNAME="admin"; $env:ADMIN_PASSWORD="5axg1zr8"; $env:ADMIN_EMAIL="no-reply@origam.com"; $env:COMPOSE_PROFILES="$env:DB_TYPE,linux"; docker compose up
```

### bash (Linux / macOS / WSL)

```bash
export DB_TYPE=postgres; export DB_HOST=postgres; export DB_NAME=origam; export DB_USERNAME=postgres; export DB_PASSWORD=postgres; export PROJECT_NAME=MainOrigam2; export ADMIN_USERNAME=admin; export ADMIN_PASSWORD=5axg1zr8; export ADMIN_EMAIL=no-reply@origam.com; export COMPOSE_PROFILES=$DB_TYPE,linux; docker compose up
```

Once the stack is up:

- Server — https://localhost:443
- Architect — http://localhost:8081

## Environment variables

All configuration is passed via environment variables (there is no `.env` file).

| Variable | Meaning | Example |
|---|---|---|
| `PROJECT_NAME` | Compose project name and output folder `./model/<PROJECT_NAME>` | `MainOrigam2` |
| `DB_TYPE` | `postgres` or `mssql` — also used to pick the DB profile | `postgres` |
| `DB_HOST` | Host the composer uses to reach the DB (see table below) | `postgres` |
| `DB_NAME` | Database name | `origam` |
| `DB_USERNAME` | Database user | `postgres` |
| `DB_PASSWORD` | Database password | `postgres` |
| `ADMIN_USERNAME` | Initial ORIGAM admin login | `admin` |
| `ADMIN_PASSWORD` | Initial ORIGAM admin password | `5axg1zr8` |
| `ADMIN_EMAIL` | Initial ORIGAM admin email | `no-reply@origam.com` |
| `COMPOSE_PROFILES` | Profiles to activate — combine one DB and one runtime profile | `postgres,linux` |

### Picking `DB_HOST`

| Runtime profile | `DB_HOST` value |
|---|---|
| `linux` with internal DB | service name — `postgres` or `mssql` |
| `windows` with internal DB | `172.20.0.1` (gateway on the `stable-nat` network) |
| external DB | hostname / IP of your external database |

## Profiles

Compose profiles control which services start. Combine **one runtime** (`linux` or `windows`) with **one database** (`postgres` or `mssql`), or drop the database profile if you bring your own.

| `COMPOSE_PROFILES` | Starts |
|---|---|
| `postgres,linux` | PostgreSQL + Composer/Server/Architect in Linux containers |
| `mssql,linux` | MSSQL + Composer/Server/Architect in Linux containers |
| `postgres,windows` | PostgreSQL + Composer/Server/Architect in Windows containers |
| `mssql,windows` | MSSQL + Composer/Server/Architect in Windows containers |
| `linux` | ORIGAM Linux stack only — external DB required (`DB_HOST` → your DB) |

On Windows with Docker Desktop in Linux-containers mode, use the `linux` runtime profile. Switch to `windows` only when Docker Desktop is in Windows-containers mode.

## How it works

1. The composer container (`origam-composer-linux` or `origam-composer-windows`) generates project files into `./model/<PROJECT_NAME>`.
2. Server and Architect wait for the composer to finish (`service_completed_successfully`).
3. Server starts on **443**, Architect on **8081**.

Re-running `docker compose up` is idempotent — if `./model/<PROJECT_NAME>` already exists, the composer skips generation and only the services start.

## Regenerate the project from scratch

```bash
docker compose down
rm -rf ./model/<PROJECT_NAME>
# optional: also drop the `origam` database to start with a clean schema
```

Then re-run the quick start command.

## Windows containers — firewall rule

Windows containers on the `stable-nat` network need an inbound allow rule on the host:

```powershell
New-NetFirewallRule `
  -DisplayName "Allow from stable-nat" `
  -Direction Inbound `
  -Action Allow `
  -RemoteAddress 172.20.0.0/20 `
  -Profile Any
```

## Troubleshooting

- **`port is already allocated`** — another process is using `443`, `8081`, `1433`, or `5432`. Free the port or edit the published port in `docker-compose.yml`.
- **Composer failed** — check its logs:
  - `docker compose logs origam-composer-linux`
  - `docker compose logs origam-composer-windows`
- **Server/Architect never start** — they wait for the composer to complete. Investigate composer logs first.
- **DB connection error** — verify `DB_HOST`, `DB_USERNAME`, `DB_PASSWORD`. For `linux` use the service name; for `windows` use `172.20.0.1`.
- **Windows DB unreachable** — confirm the `stable-nat` Docker network exists and gateway `172.20.0.1` is reachable from inside the container.

## Security

The example uses weak passwords for convenience. Replace `DB_PASSWORD` and `ADMIN_PASSWORD` with strong values before any shared or production-like use. Do not commit real credentials.

## Useful commands

```bash
# Start detached
docker compose up -d

# Stop and remove containers + network
docker compose down

# Follow all logs
docker compose logs -f

# Follow one service
docker compose logs -f origam-server-linux
```
