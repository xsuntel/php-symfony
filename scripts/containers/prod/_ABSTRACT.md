# Scripts - Docker Containers

## Platform

* Linux
* Mac - MacOS
* Windows

## Project

### Docker - Containers

* App : PHP-FPM + Nginx + Supervisor (single container, port 8080)

### Configuration

```bash
vi ./scripts/containers/prod/.env.prod.local
```

`deploy.sh setBuild()` copies this file to `app/.env.prod.local`, where `composer dump-env prod`
compiles it into `app/.env.local.php`.

```dotenv
# ----------------------------------------------------------------------------------------------------------------------
# Symfony Framework - Prod Environment                                   https://symfony.com/doc/current/deployment.html
# ----------------------------------------------------------------------------------------------------------------------
# The app container joins the dev compose network (`--net symfony_back-end`), so these hosts are the
# Compose container names: ${DOCKER_CONTAINER_NAME}-<service>-${DOCKER_ENVIRONMENT}, which
# scripts/containers/dev/docker-compose.env defaults to symfony / dev.

# >>>> Cache - Redis
REDIS_HOST=symfony-redis-dev                                                            # <<<< Container's Name or IP
REDIS_PORT=6379

# >>>> Database - PostgreSQL
POSTGRES_HOST=symfony-postgres-dev                                                      # <<<< Container's Name or IP
POSTGRES_PORT=5432

# >>>> Message - RabbitMQ
RABBITMQ_HOST=symfony-rabbitmq-dev                                                      # <<<< Container's Name or IP
RABBITMQ_PORT=5672

# >>>> Server - Nginx
NGINX_SCHEME=http
NGINX_HOST=127.0.0.1
NGINX_PORT=8080
```

> ⚠️ This is the **local end-to-end test** topology, which is why it points at the dev containers.
> Real deployments inject these as secrets — Secret Manager on Cloud Run, Secrets Manager/SSM on ECS.
> Never commit real credentials to this file.

### Deployment

The dev compose stack must be running first — `deploy.sh` attaches the container to the
`symfony_back-end` network that it creates.

```bash
./scripts/containers/prod/deploy.sh
```

The script frees port 8080, builds the app on the host (`composer install --no-dev`,
`dump-env prod`, `asset-map:compile`), builds the image, runs it, polls the container health check,
then reports `php-fpm -t`, `nginx -t` and `supervisorctl status`.

Override the published port with `DOCKERFILE_LOCALHOST_PORT`; it defaults to 8080 and is used
consistently by the port-freeing, publishing and verification steps.

### Verification

```bash
docker exec symfony-php-prod supervisorctl status
#   php-fpm, nginx, messenger-consume_00, messenger-consume_01 --> all RUNNING

curl -fsS http://127.0.0.1:8080/healthcheck.php
```

## Reference

### Tools

* [Release notes](https://docs.docker.com/desktop/release-notes/)
* [Docker Desktop](https://www.docker.com/products/docker-desktop/)
* [Symfony deployment](https://symfony.com/doc/current/deployment.html)
