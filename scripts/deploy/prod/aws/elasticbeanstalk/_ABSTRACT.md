# Scripts - Deploy - AWS (Amazon Web Service) - Elastic Beanstalk

## Prod Environment

## Platform

* Linux - [Ubuntu Server](https://ubuntu.com/download/server/)
  * App : PHP
  * Cache : Redis
  * Database : PostgreSQL
  * Message : RabbitMQ
  * Server : Nginx

## Project

### App - Symfony Framework

* Create APP_SECRET

```bash
date | md5
```

* Update default variables in Prod Environment

```bash
vi .env.prod

# ----------------------------------------------------------------------------------------------------------------------
# Architecture
# ----------------------------------------------------------------------------------------------------------------------

# >>>> Cache - Redis
REDIS_HOST=
REDIS_PORT=6379

# >>>> Database - PostgreSQL
POSTGRES_VERSION=16
POSTGRES_HOST=
POSTGRES_PORT=5432
POSTGRES_DB=
POSTGRES_USER=
POSTGRES_PASSWORD=

# >>>> Message - RabbitMQ
RABBITMQ_HOST=
RABBITMQ_PORT=5672
RABBITMQ_USER=guest
RABBITMQ_PASSWORD=guest

# >>>> Server - Nginx
NGINX_SCHEME=http
NGINX_HOST=
NGINX_PORT=

# >>>> Utility - Mailer
MAILER_HOST=
MAILER_PORT=
```

## Deployment

* Deploy this project

```bash
./scripts/deploy/prod/aws/elasticbeanstalk/deploy.sh
```

### Console

* Cache

```bash
./scripts/base/app/symfony/cache.sh
```

* Migrations

```bash
./scripts/base/app/symfony/database.sh
```

## Reference

### Server

* Cloud
  * AWS (Amazon Web Services)
    * [Elastic Beanstalk](https://aws.amazon.com/ko/elasticbeanstalk)

  * AWS Codecommit
    * [Troubleshooting the credential helper](https://docs.aws.amazon.com/codecommit/latest/userguide/troubleshooting-ch.html)
