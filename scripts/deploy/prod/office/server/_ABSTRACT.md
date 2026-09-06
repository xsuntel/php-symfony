# Scripts - Deploy - Office - Local Server

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

### Database - PostgreSQL

* Configure the database

```bash
[root@localhost] sudo -i -u postgres
[sudo] password for user: {password}

postgres@localhost:~$ psql
psql (xx.y)
Type "help" for help.

postgres=# create user symfony password '!ChangeMe!' superuser;
CREATE ROLE
postgres=# \du
                                   List of roles
 Role name |                         Attributes                         | Member of
-----------+------------------------------------------------------------+-----------
 postgres  | Superuser, Create role, Create DB, Replication, Bypass RLS | {}
 symfony   | Superuser                                                  | {}

postgres=# \q

```

* Change the user's password

```bash
sudo -i -u postgres
[sudo] password for user: {password}

postgres@localhost:~$ psql
psql (xx.y)
Type "help" for help.

postgres=# alter user {user_name} with password {user_password};

postgres=# \q

```

## Deployment

* Deploy this project

```bash
./scripts/deploy/prod/office/server/deploy.sh
```

* Check status

```bash
./scripts/deploy/prod/office/server/status.sh
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

* [Ubuntu Desktop](https://ubuntu.com/desktop)
