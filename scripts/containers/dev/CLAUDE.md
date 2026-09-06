# CLAUDE.md

Development infrastructure: Redis, PostgreSQL, RabbitMQ and pgAdmin, run as containers via Docker
Compose. **The Symfony application itself does not run here** — it runs on the host (`symfony serve`
or the host PHP-FPM/Nginx configured by `scripts/base/`), and connects to these services on
`127.0.0.1`. The containerised application image is the production one,
`scripts/containers/prod/Dockerfile`.

## Files

| Path | Role |
| --- | --- |
| `docker-compose.yml` | Service definitions. `name: symfony` is pinned so the network is deterministically `symfony_back-end` |
| `docker-compose.env` | Ports, versions, credentials, `COMPOSE_PROFILES` |
| `<domain>/<service>/Dockerfile` | Thin wrapper over the official image, one per service |
| `<domain>/<service>/.env` | Service-specific `env_file`, referenced from `docker-compose.yml` |
| `cache/redis/etc/redis.conf` | The single source of truth for Redis tuning — see the warning below |
| `database/postgres/etc/postgresql.conf` | **Reference template, not loaded.** PostgreSQL tuning lives in the service's `command:` block |

## Usage

Every path inside `docker-compose.yml` — build contexts, `dockerfile:` paths, `env_file:` entries — is
written relative to the **repository root**, not to the compose file. Compose resolves them against
the project directory, which defaults to the compose file's own directory, so `--project-directory`
must be passed explicitly. **A bare `docker compose -f scripts/containers/dev/docker-compose.yml up`
will fail on every build context.**

The canonical entry point handles this for you:

```bash
# Sourced from a deploy script's setDocker(); inherits PROJECT_PATH and ENVIRONMENT_NAME
source scripts/base/utility/docker/_deploy.sh
```

To drive Compose directly, from the repository root:

```bash
docker compose \
  -f scripts/containers/dev/docker-compose.yml \
  --project-directory . \
  --env-file .env.app \
  --env-file scripts/containers/dev/docker-compose.env \
  up -d
```

`config --quiet` validates without starting anything; `config --services` lists what the active
profiles resolve to.

## Profiles

Every service declares `profiles:`, so **with no profile active `up` starts zero containers**.
Selection comes from `COMPOSE_PROFILES` in `docker-compose.env` (default `core,utility`).

| Profile | Services | Started by default |
| --- | --- | --- |
| `core` | redis, postgres, rabbitmq | yes |
| `utility` | pgadmin | yes |
| `database-alt` | mysql, mongo | no — opt-in alternates to PostgreSQL |

> ⚠️ Do not pass `--profile` on the command line. The CLI flag **overrides** `COMPOSE_PROFILES`
> rather than adding to it, so `--profile core` silently suppresses pgAdmin.

## Ports

All published ports bind to `127.0.0.1` only — nothing is reachable off-host.

| Service | Host port (`docker-compose.env`) | Container port |
| --- | --- | --- |
| Redis | `REDIS_LOCALHOST_PORT` (6379) | 6379 |
| PostgreSQL | `POSTGRES_LOCALHOST_PORT` (5432) | 5432 |
| RabbitMQ (AMQP) | `RABBITMQ_LOCALHOST_PORT` (5672) | 5672 |
| RabbitMQ (management UI) | `RABBITMQ_WEBSITE_PORT` (15672) | 15672 |
| pgAdmin | `PGADMIN_WEBSITE_PORT` (5450) | 80 |
| MySQL *(alt)* | `MYSQL_LOCALHOST_PORT` (3306) | 3306 |
| Mongo *(alt)* | `MONGO_LOCALHOST_PORT` (27017) | 27017 |

## Network contract with prod

`scripts/containers/prod/deploy.sh` attaches the production app container with
`--net symfony_back-end`. That network only exists while this compose project is up, and its name
depends on `name: symfony` at the top of `docker-compose.yml`. **Changing or removing `name:` breaks
the production deploy script**, because Compose would then derive the project name from the
`--project-directory` basename (`symfony-scripts`).

Service hostnames on that network follow `${DOCKER_CONTAINER_NAME}-<service>-${DOCKER_ENVIRONMENT}`
— by default `symfony-redis-dev`, `symfony-postgres-dev`, `symfony-rabbitmq-dev`. These are the values
`scripts/containers/prod/.env.prod.local` must carry.

## Gotchas

- **Redis has no `command:` override, deliberately.** A `command:` in Compose replaces the Dockerfile
  `CMD` wholesale, which would leave `cache/redis/etc/redis.conf` unread. All Redis tuning
  (`maxmemory`, eviction policy, `appendonly`, `save`) belongs in that file.
- **PostgreSQL is the mirror image.** `database/postgres/etc/postgresql.conf` is *not* copied or
  mounted; tuning lives in the service's `command:` block. See the header comment in that file.
- `docker-compose.env` ships `!ChangeMe!` placeholder passwords. They are fine for a loopback-only dev
  stack; never reuse them anywhere else.
