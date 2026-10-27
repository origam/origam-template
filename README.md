<img width="1200" height="675" alt="image" src="https://github.com/user-attachments/assets/29e224eb-c077-4201-85eb-70547bab082a" />
<p></p>

Install and run ORIGAM Server + Architect with Docker Compose.

This repo supports three deployment targets:

- Docker in WSL / Docker Desktop (Linux containers)
- Docker on regular Linux host or Mac
- Docker on Windows Container Service (Windows containers)

## Choose your environment

### Install on your Windows environment with WSL / Docker Desktop

Use this when Docker Desktop runs in Linux containers mode.

#### Command Prompt CMD

**Step 1** — Set the database type:
```bat
set DB_TYPE=mssql
```

**Step 2** — Set the remaining variables and start the containers:
```bat
set DB_HOST=mssql&& set DB_PORT=1433&& set DB_NAME=origam&& set DB_USERNAME=sa&& set DB_PASSWORD=YourStrong!Passw0rd&& set PROJECT_NAME=mainorigam&& set ADMIN_USERNAME=admin&& set ADMIN_PASSWORD=change-me&& set ADMIN_EMAIL=no-reply@origam.com&& set COMPOSE_PROFILES=%DB_TYPE%,linux&& docker compose up
```

### Install with Docker on Linux or Mac

Same runtime profile as WSL (`linux`):

```bash
export DB_TYPE=mssql; export DB_HOST=mssql; export DB_PORT=1433; export DB_NAME=origam; export DB_USERNAME=sa; export DB_PASSWORD='YourStrong!Passw0rd'; export PROJECT_NAME=mainorigam; export ADMIN_USERNAME=admin; export ADMIN_PASSWORD=change-me; export ADMIN_EMAIL=no-reply@origam.com; export COMPOSE_PROFILES=$DB_TYPE,linux; docker compose up
```

On Linux (Docker Engine) the containers run as user id 1655 and write to the project folder. Before the first start give that user and yourself write access to it, including files created later, for example `setfacl -R -m u:1655:rwX -m d:u:1655:rwX -m d:u:$(id -u):rwX .` in the project folder (needs the `acl` package). Otherwise the composer stops with "The project folder is not writable for the container user".

### Install with Docker on Windows Container Service

Use this when Docker is running Windows containers.

```powershell
$env:DB_TYPE="mssql"; $env:DB_HOST="172.20.0.1"; $env:DB_PORT="1433"; $env:DB_NAME="origam"; $env:DB_USERNAME="sa"; $env:DB_PASSWORD="yourStrong(!)Password"; $env:PROJECT_NAME="mainorigam"; $env:ADMIN_USERNAME="admin"; $env:ADMIN_PASSWORD="change-me"; $env:ADMIN_EMAIL="no-reply@origam.com"; $env:COMPOSE_PROFILES="windows"; docker compose up
```

After startup:

- Server: https://localhost:443
- Architect: http://localhost:8081

## Packages created in Architect

The server works with one package and the packages it references, and reads them when it starts. In a new project
that is the `<PROJECT_NAME>` package. Without `CUSTOM_MODEL_PATH` the server instead takes the package built on top of
it: the one package that references `<PROJECT_NAME>`, directly or through other packages, and that no other such
package references. The server log shows which package it uses (`Active package: ...`).

To see a package created with **New Package** in Architect in the client:

1. In the Packages panel of Architect click **References** at the new package (right after **New Package** it is
   open; otherwise double-click it first), tick the package created before it (`<PROJECT_NAME>` for the first one)
   and click **OK**. This also makes the `Menu` of `Root Menu` available in the new package.
2. Restart the server, for example `docker restart <PROJECT_NAME>-server-linux`.

So every next package references the one before it, for example `Test11` references `Test10` and `Test10`
references `<PROJECT_NAME>`. When several packages are built on `<PROJECT_NAME>` and none of them references the
others, the server stays on `<PROJECT_NAME>` and its log names them. After the last package is deleted in Architect,
the server uses the package before it on its next start. `<PROJECT_NAME>_Environments.env` is not changed. A project
created with an older version of this template needs `docker compose up` once to get this. Linux containers only
(`linux` profile).

With `CUSTOM_MODEL_PATH`, tick the current active package (for example `Widgets`) in **References** of the new
package, then set `ACTIVE_PACKAGE_ID` to the id of the new package and run `docker compose up` (see below).

## Work with your own model (optional)

By default the new project is created from the ORIGAM model bundled in the composer image.
To work with another model instead, set `CUSTOM_MODEL_PATH` to a folder that contains `model/`
(for example the `model-tests` folder of the [origam repository](https://github.com/origam/origam))
and run the usual command from above with this extra variable. Use a new project folder
and keep the variable set on every start.

`ACTIVE_PACKAGE_ID` sets the main (active) package of the project, the one the server works with. It is optional: without it
`Widgets` (`f17329d6-3143-420a-a2e6-30e431eea51d`) is used, which is the right package for `model-tests`. For your own model,
put the id of its main package there. The id is the `x:id` in `model/<package>/.origamPackage`. When the id is not in the model,
the composer stops and lists all packages with their ids.

CMD:
```bat
set CUSTOM_MODEL_PATH=C:\Repos\origam\model-tests&& set ACTIVE_PACKAGE_ID=f17329d6-3143-420a-a2e6-30e431eea51d&& set DB_TYPE=mssql&& set DB_HOST=mssql&& set DB_PORT=1433&& set DB_NAME=origam&& set DB_USERNAME=sa&& set DB_PASSWORD=YourStrong!Passw0rd&& set PROJECT_NAME=mainorigam&& set ADMIN_USERNAME=admin&& set ADMIN_PASSWORD=change-me&& set ADMIN_EMAIL=no-reply@origam.com&& set COMPOSE_PROFILES=mssql,linux&& docker compose up
```

Linux or Mac:
```bash
export CUSTOM_MODEL_PATH="$HOME/repos/origam/model-tests"; export ACTIVE_PACKAGE_ID=f17329d6-3143-420a-a2e6-30e431eea51d; export DB_TYPE=mssql; export DB_HOST=mssql; export DB_PORT=1433; export DB_NAME=origam; export DB_USERNAME=sa; export DB_PASSWORD='YourStrong!Passw0rd'; export PROJECT_NAME=mainorigam; export ADMIN_USERNAME=admin; export ADMIN_PASSWORD=change-me; export ADMIN_EMAIL=no-reply@origam.com; export COMPOSE_PROFILES=$DB_TYPE,linux; docker compose up
```

What happens:

- The server and Architect work directly with `CUSTOM_MODEL_PATH/model` (a link, not a copy). Changes made in Architect are written to that folder. Neither of them reloads the model while running: after changing files in that folder outside Architect (for example `git pull`), restart both with the same variables set (`docker compose restart origam-server-linux origam-architect-linux`) and do not save in Architect before that, or it may overwrite the changed files. The server deploys new versions of the active packages to the database when it starts.
- On the first start the composer creates the database and the admin user from a temporary copy of that model inside its container. It deploys the active package with all packages it references, and `Root Menu` when the model has it, in one pass into the empty database, the same way Architect deploys an empty database. Only `<PROJECT_NAME>_Environments.env` and `customAssets/` (taken from the custom model when it has one, otherwise the bundled one, unless the project folder already has `customAssets/`) are written to the project folder. No copy of the model and no `<PROJECT_NAME>` package are created.
- The active package on the server is the package with the id in `ACTIVE_PACKAGE_ID` (the id is in the package's `.origamPackage` file and in Architect). Without it, a new project uses `Widgets` (`f17329d6-3143-420a-a2e6-30e431eea51d`), as in `model-tests` and `HOWTOSTART.md` of the origam repository, and later starts keep the current active package. When the model has no package with that id, the composer stops and lists the packages with their ids. The server shows the active package with the packages it references. All packages can be opened and edited in Architect.
- `ACTIVE_PACKAGE_ID` can be changed later by running `docker compose up` again with the new value. The server then deploys the packages that the new active package adds on top of the existing database. This fails for packages whose deployment scripts only work in an empty database (for example switching from `Root Menu` to `Widgets` with `model-tests` on MSSQL), so choose the package before the first start, or start again from scratch.
- On Linux (Docker Engine) the containers also write to `CUSTOM_MODEL_PATH/model`. Give user id 1655 and yourself write access to everything in it as well, for example `setfacl -R -m u:1655:rwX -m d:u:1655:rwX -m d:u:$(id -u):rwX "$CUSTOM_MODEL_PATH/model"`. Otherwise Architect cannot save, or `git pull` fails with Permission denied in folders created by Architect.
- A project created without `CUSTOM_MODEL_PATH` cannot be switched to it, and a project created with it cannot be started without it. A project created with `CUSTOM_MODEL_PATH` by an older version of this template has to be started again from scratch. In all these cases the composer stops with an error.
- If the first start failed, the composer stops with an error. To start again from scratch, run `docker compose down -v` in the same shell with the same variables set (removes the containers and the database volume), delete `customAssets/` and `<PROJECT_NAME>_Environments.env`, then run the command again.
- Linux containers only (`linux` profile).

## Important variables

| Variable | Description |
|---|---|
| `PROJECT_NAME` | Project name and, without `CUSTOM_MODEL_PATH`, output folder `./model/<PROJECT_NAME>` |
| `DB_TYPE` | `postgresql` or `mssql` |
| `DB_HOST` | Database hostname from the rules above |
| `DB_PORT` | Database port (default: `1433` for MSSQL, `5432` for PostgreSQL) |
| `DB_NAME` | Application database name |
| `DB_USERNAME` | Database user |
| `DB_PASSWORD` | Database password |
| `ADMIN_USERNAME` | First ORIGAM admin login |
| `ADMIN_PASSWORD` | First ORIGAM admin password |
| `ADMIN_EMAIL` | First ORIGAM admin email |
| `COMPOSE_PROFILES` | Active runtime and database profiles |
| `CUSTOM_MODEL_PATH` | Optional. Folder with `model/` that the server and Architect work with instead of the bundled model (set it on every start) |
| `ACTIVE_PACKAGE_ID` | Optional, only with `CUSTOM_MODEL_PATH`. Id of the package the server works with (default: `Widgets`, `f17329d6-3143-420a-a2e6-30e431eea51d`) |

## Database host rules

| Runtime | Internal DB in this compose | `DB_HOST` |
|---|---|---|
| `linux` | Supported (`postgres` or `mssql` profile) | `postgres` or `mssql` |
| `windows` | Not supported (DB images are Linux-based) | `172.20.0.1` (host / gateway) |

## Database port defaults

- MSSQL default: `DB_PORT=1433`
- PostgreSQL default: `DB_PORT=5432`
- You can change the port if your DB listens on another one (for example managed DB or custom host setup).

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
If you run **Windows containers + local DB on the same Windows host**, this rule is required.
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

If DB is remote and network/firewall already allows traffic from your container host, you usually do not need this specific host firewall rule.
## Profiles reference

| `COMPOSE_PROFILES` | Starts |
|---|---|
| `postgres,linux` | Linux ORIGAM + internal PostgreSQL |
| `mssql,linux` | Linux ORIGAM + internal MSSQL |
| `windows` | Windows ORIGAM only (external DB) |
| `linux` | Linux ORIGAM only (external DB) |

Note: `postgres,windows` and `mssql,windows` are not supported in Windows containers mode.

Tip: to switch PostgreSQL -> MSSQL, set `DB_TYPE=mssql`, `COMPOSE_PROFILES=mssql,<runtime>`, and set matching DB credentials.

For PostgreSQL defaults, use `DB_TYPE=postgresql`, `DB_HOST=postgres` (Linux internal DB) or your external host, and `DB_PORT=5432`. The database type is `postgresql`, but the compose profile is `postgres`, so set `COMPOSE_PROFILES=postgres,linux` explicitly instead of `$DB_TYPE,linux`:

```bash
export DB_TYPE=postgresql; export DB_HOST=postgres; export DB_PORT=5432; export DB_NAME=origam; export DB_USERNAME=postgres; export DB_PASSWORD='YourStrong!Passw0rd'; export PROJECT_NAME=mainorigam; export ADMIN_USERNAME=admin; export ADMIN_PASSWORD=change-me; export ADMIN_EMAIL=no-reply@origam.com; export COMPOSE_PROFILES=postgres,linux; docker compose up
```

## Overriding services (images, ports, environment)

Docker Compose supports layered configuration, so you can replace images or tweak any service setting without editing `docker-compose.yml` directly. This is useful for pinning to a specific published ORIGAM build, swapping in a custom image, or changing ports per environment.

### Option: `docker-compose.override.yml` (auto-loaded)

Create `docker-compose.override.yml` next to `docker-compose.yml`. Compose merges it automatically — no extra flags needed.

Example: run a specific published server image (e.g. `origam/server:2026.4.alpha.4228.linux`) instead of the default `local.linux` tag:

```yaml
services:
  origam-server-linux:
    image: origam/server:2026.4.alpha.4228.linux
  origam-architect-linux:
    image: origam/architect:2026.4.alpha.4228.linux
```

Then start as usual:

```bash
docker compose up
```

<b>To update your project</b> 
```
unset PROJECT_NAME DB_TYPE DB_HOST DB_PORT DB_NAME DB_USERNAME DB_PASSWORD ADMIN_USERNAME ADMIN_PASSWORD ADMIN_EMAIL CUSTOM_MODEL_PATH ACTIVE_PACKAGE_ID
```
or Windows Cmd 

```
for %v in (PROJECT_NAME DB_TYPE DB_HOST DB_PORT DB_NAME DB_USERNAME DB_PASSWORD ADMIN_USERNAME ADMIN_PASSWORD ADMIN_EMAIL CUSTOM_MODEL_PATH ACTIVE_PACKAGE_ID) do @set "%v="
```

Then, run your docker compose up command with the injected environment variables ( its Mac and Linux version ) 
```
export DB_TYPE=mssql; export DB_HOST=mssql; export DB_PORT=1433; export DB_NAME=origam; export DB_USERNAME=sa; export DB_PASSWORD='YourStrong!Passw0rd'; export PROJECT_NAME=mainorigam; export ADMIN_USERNAME=admin; export ADMIN_PASSWORD=change-me; export ADMIN_EMAIL=no-reply@origam.com; export COMPOSE_PROFILES=$DB_TYPE,linux; docker compose up
```
If the project was created with `CUSTOM_MODEL_PATH`, set it again as well.
If you want to apply a configuration update, such as adding an Origam AI API Key https://github.com/origam/origam/tree/master/backend/Origam.AI.Agent, add it to the `_Environments.env` file. Your settings will be loaded after a restart.

For example:

Ai__Endpoint=https://api.openai.com/v1

Ai__Model=gpt-6-luna

Ai__ApiKey=sk-proj-O4FMlW-

Docker uses a lot of disk space. If you run low on space, run this command. It removes all unused Docker data without confirmation: stopped containers, networks, images and build cache. Volumes are kept ( in this solution volume is db data ) 
```
docker system prune -a 
```

