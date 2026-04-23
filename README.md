# ORIGAM Template

Simple Docker Compose template for starting ORIGAM Server + Architect.
You can use an internal PostgreSQL/MSSQL container or connect to your own database.

## Quick start

Set variables and run `docker compose up`.

### PowerShell (Windows)

```powershell
$env:DB_TYPE="postgres"; $env:DB_HOST="postgres"; $env:DB_NAME="origam"; $env:DB_USERNAME="postgres"; $env:DB_PASSWORD="postgres"; $env:PROJECT_NAME="MainOrigam2"; $env:ADMIN_USERNAME="admin"; $env:ADMIN_PASSWORD="5axg1zr8"; $env:ADMIN_EMAIL="no-reply@origam.com"; $env:COMPOSE_PROFILES="$env:DB_TYPE,linux"; docker compose up
```

### Bash (Linux/macOS/WSL)

```bash
export DB_TYPE=postgres; export DB_HOST=postgres; export DB_NAME=origam; export DB_USERNAME=postgres; export DB_PASSWORD=postgres; export PROJECT_NAME=MainOrigam2; export ADMIN_USERNAME=admin; export ADMIN_PASSWORD=5axg1zr8; export ADMIN_EMAIL=no-reply@origam.com; export COMPOSE_PROFILES=$DB_TYPE,linux; docker compose up
```

After startup:

- Server: https://localhost:443
- Architect: http://localhost:8081

## Required variables

There is no `.env` file. Pass everything through environment variables.

| Variable | What it is |
|---|---|
| `PROJECT_NAME` | Output folder name: `./model/<PROJECT_NAME>` |
| `DB_TYPE` | `postgres` or `mssql` |
| `DB_HOST` | Database host reachable from containers |
| `DB_NAME` | Database name |
| `DB_USERNAME` | Database user |
| `DB_PASSWORD` | Database password |
| `ADMIN_USERNAME` | First ORIGAM admin login |
| `ADMIN_PASSWORD` | First ORIGAM admin password |
| `ADMIN_EMAIL` | First ORIGAM admin email |
| `COMPOSE_PROFILES` | Runtime + DB profile, for example `postgres,linux` |

## `DB_HOST` cheat sheet

- Linux runtime + internal DB: `postgres` or `mssql`
- Windows runtime + internal DB: `172.20.0.1`
- External DB: your DB hostname or IP

## Profiles

Use one runtime profile (`linux` or `windows`) and optionally one DB profile (`postgres` or `mssql`).

| `COMPOSE_PROFILES` | What starts |
|---|---|
| `postgres,linux` | Linux ORIGAM + internal PostgreSQL |
| `mssql,linux` | Linux ORIGAM + internal MSSQL |
| `postgres,windows` | Windows ORIGAM + internal PostgreSQL |
| `mssql,windows` | Windows ORIGAM + internal MSSQL |
| `linux` | Linux ORIGAM only (external DB required) |

If Docker Desktop is in Linux containers mode, use `linux`.
Use `windows` only in Windows containers mode.

## Reset project

```bash
docker compose down
rm -rf ./model/<PROJECT_NAME>
```

Then run quick start again.

## Windows containers firewall rule

For `stable-nat` networking, allow inbound traffic from `172.20.0.0/20`:

```powershell
New-NetFirewallRule `
  -DisplayName "Allow from stable-nat" `
  -Direction Inbound `
  -Action Allow `
  -RemoteAddress 172.20.0.0/20 `
  -Profile Any
```

## Troubleshooting

- `port is already allocated`: free `443`, `8081`, `1433`, or `5432`, or change ports in `docker-compose.yml`
- Composer failed: `docker compose logs origam-composer-linux` or `docker compose logs origam-composer-windows`
- Server/Architect do not start: check composer logs first
- DB connection fails: verify `DB_HOST`, `DB_USERNAME`, and `DB_PASSWORD`

## Security note

Default passwords in examples are weak.
Change `DB_PASSWORD` and `ADMIN_PASSWORD` before shared or production-like use.

## Useful commands

```bash
docker compose up -d
docker compose down
docker compose logs -f
docker compose logs -f origam-server-linux
```
