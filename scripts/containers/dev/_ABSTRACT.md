# Scripts - Docker Containers

## Platform

* Linux
* Mac - MacOS
* Windows

## Project

### Docker - Containers

Core (started by default):

* Cache : Redis
* Database : PostgreSQL
* Message : RabbitMQ
* Utility : pgAdmin

Alternate databases (profile `database-alt`, opt-in — not started by default):

* Database : MySQL
* Database : Mongo

### Configuration

```bash
vi ./scripts/containers/dev/docker-compose.env
```

```dotenv
# ----------------------------------------------------------------------------------------------------------------------
# Symfony Framework - Dev Environment                                    https://symfony.com/doc/current/deployment.html
# ----------------------------------------------------------------------------------------------------------------------

# >>>> Project
DOCKER_CONTAINER_NAME=symfony                                         # container name prefix
DOCKER_ENVIRONMENT=dev                                                # container name suffix

# >>>> Profiles
# Every service declares `profiles:`, so an empty value starts NOTHING.
# Do not pass --profile on the CLI: it overrides this instead of adding to it.
COMPOSE_PROFILES=core,utility                                         # add database-alt for MySQL/Mongo

# ----------------------------------------------------------------------------------------------------------------------
# Architecture - Core
# ----------------------------------------------------------------------------------------------------------------------

# >>>> Cache
REDIS_VERSION=7.0
REDIS_LOCALHOST_PORT=6379                                             # REDIS_NETWORK_PORT    ---> REDIS_PORT      6379

# >>>> Database
POSTGRES_VERSION=16
POSTGRES_LOCALHOST_PORT=5432                                          # POSTGRES_NETWORK_PORT ---> POSTGRES_PORT   5432
POSTGRES_DB={Your default Database}
POSTGRES_USER={Your Name}
POSTGRES_PASSWORD={Your Password}

# >>>> Message
RABBITMQ_VERSION=3.13
RABBITMQ_LOCALHOST_PORT=5672                                          # RABBITMQ_NETWORK_PORT ---> RABBITMQ_PORT   5672
RABBITMQ_WEBSITE_PORT=15672

# ----------------------------------------------------------------------------------------------------------------------
# Architecture - Database (alternate)                                   profile: database-alt
# ----------------------------------------------------------------------------------------------------------------------

MYSQL_VERSION=8.4
MYSQL_LOCALHOST_PORT=3306
MYSQL_DB={Your default Database}

MONGO_VERSION=8.0
MONGO_LOCALHOST_PORT=27017

# ----------------------------------------------------------------------------------------------------------------------
# Utility
# ----------------------------------------------------------------------------------------------------------------------

# >>>> pgAdmin
PGADMIN_VERSION=9.17
PGADMIN_WEBSITE_PORT=5450                                             # PGADMIN_NETWORK_PORT  ---> HTTP            80
PGADMIN_MAIL={Your Email}
PGADMIN_PW={Your Password}
```

Per-service credentials live in the sibling `.env` files
(`cache/redis/.env`, `database/postgres/.env`, `message/rabbitmq/.env`, ...).

## Deployment

* Docker

```bash
docker login -u <username>

vi ~/.docker/config.json
```

```bash
sudo vi /etc/docker/daemon.json
```

```json
{
  "dns": ["8.8.8.8", "8.8.4.4"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "userland-proxy": false
}
```

```bash
sudo systemctl restart docker
```

### Compose

> ⚠️ **`--project-directory` is mandatory.** Every path inside `docker-compose.yml` is relative to the
> repository root, not to the compose file. A bare `docker compose -f ... up` fails on every build
> context. Run these from the repository root.

```bash
docker compose \
  -f scripts/containers/dev/docker-compose.yml \
  --project-directory . \
  --env-file .env.app \
  --env-file scripts/containers/dev/docker-compose.env \
  down

docker network prune -f

docker compose \
  -f scripts/containers/dev/docker-compose.yml \
  --project-directory . \
  --env-file .env.app \
  --env-file scripts/containers/dev/docker-compose.env \
  up -d
```

Or let the project driver do it — this is the canonical entry point:

```bash
source scripts/base/utility/docker/_deploy.sh
```

### Troubleshooting

```bash
sudo lsof -i | grep docker-pr
```

```bash
sudo fuser -k 6379/tcp
sudo fuser -k 5432/tcp
sudo fuser -k 5672/tcp
```

## Reference

### Tools

* [Release notes](https://docs.docker.com/desktop/release-notes/)
* [Docker Desktop](https://www.docker.com/products/docker-desktop/)
* [Compose profiles](https://docs.docker.com/compose/profiles/)
