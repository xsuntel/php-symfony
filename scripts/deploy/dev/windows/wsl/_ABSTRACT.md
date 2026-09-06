# Scripts - Deploy

## Dev Environment

## Platform

  ```text
  # WSL2
  # Windows Explorer:
  \\wsl.localhost\Ubuntu\home\[username]\
  # (legacy form, still valid)
  \\wsl$\Ubuntu\home\[username]\
  ```

  ```text
  # VSCode
  Ctrl + Shift + P
  → Select "Terminal: Select Default Profile"
  → Select "Ubuntu (WSL)" or "WSL"
  ```

## Project

* Windows
  * install

    ```bash
    dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
    ```

    ```bash
    dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
    ```

    ```bash
    Restart-Computer
    ```

  * WSL2

    ```bash
    wsl --update
    ```

    ```bash
    wsl --set-default-version 2
    ```

    ```bash
    wsl --list --online
    ```

    ```bash
    wsl --install Ubuntu-24.04
    ```

    ```bash
    sudo vi /etc/wsl.conf

    [boot]
    systemd=true

    [interop]
    enabled=true
    appendWindowsPath=true
    ```

    ```bash
    curl -0- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash
    ```

    ```bash
    \. "$HOME/.nvm/nvm.sh"
    ```

    ```bash
    nvm install 24
    ```

    ```bash
    node -v
    npm -v
    ```

    ```bash
    npm install -g @anthropic-ai/claude-code
    ```

### App - Symfony Framework

* Create APP_SECRET

```bash
date | md5
```

* Update default variables in Dev Environment

```bash
vi .env.dev

# ----------------------------------------------------------------------------------------------------------------------
# Symfony Framework - Dev Environment                                    https://symfony.com/doc/current/deployment.html
# ----------------------------------------------------------------------------------------------------------------------

# >>>> Cache
REDIS_HOST=127.0.0.1
REDIS_PORT=6379

# >>>> Database
POSTGRES_HOST=127.0.0.1
POSTGRES_PORT=5432                                                    # POSTGRES_NETWORK_PORT ---> POSTGRES_PORT   5432
POSTGRES_DB={Your default Database}
POSTGRES_USER={Your Name}
POSTGRES_PASSWORD={Your Password}

# >>>> Message
RABBITMQ_VERSION=3
RABBITMQ_HOST=127.0.0.1
RABBITMQ_PORT=5672

# >>>> Server
NGINX_HOST=127.0.0.1
NGINX_PORT=8000
```

* Update a part of configurations for twig in dev

```bash
vi {project_directory}/app/config/packages/dev/twig.yaml

when@dev:
  twig:
    debug: true
    cache: ./app/var/cache/dev
    auto_reload: true
    strict_variables: true
```

### Database - PostgreSQL

* Update docker-compose's variables in Dev Environment

```bash
vi {project_directory}/scripts/containers/dev/docker-compose.env

# ----------------------------------------------------------------------------------------------------------------------
# Architecture
# ----------------------------------------------------------------------------------------------------------------------

# >>>> Database - PostgreSQL
POSTGRES_LOCALHOST_PORT=5432
POSTGRES_DB=app
POSTGRES_USER=symfony
POSTGRES_PASSWORD=!ChangeMe!
```

### Server - Localhost

* Symfony Local Server

```bash
vi {project_directory}/scripts/deploy/dev/.symfony.local.yaml

# ----------------------------------------------------------------------------------------------------------------------
# Local Web Server                                                                            PATH : "${PROJECT_PATH}"/app
# ----------------------------------------------------------------------------------------------------------------------
http:
  document_root: public/
  passthru: index.php
  port: 8000
  preferred_port: 8001
  #p12: ./config/authentication/p12_cert
  allow_http: true
  no_tls: true
  daemon: true
  use_gzip: true
  no_workers: true
```

## Deployment

* Deploy this project

```bash
./scripts/deploy/dev/windows/wsl/deploy.sh
```

* Check status

```bash
./scripts/deploy/dev/windows/wsl/status.sh
```

### Console

* Assets

```bash
./scripts/base/app/symfony/assets.sh
```

* Cache

```bash
./scripts/base/app/symfony/cache.sh
```

* Migrations

```bash
./scripts/base/app/symfony/database.sh
```

* Messenger

```bash
./scripts/base/app/symfony/scheduler.sh
```

## Reference

* [Windows](https://www.microsoft.com/)
* [Docker Desktop](https://www.docker.com/products/docker-desktop/)
