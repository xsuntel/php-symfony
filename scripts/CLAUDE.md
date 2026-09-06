# CLAUDE.md

This file configures Claude's behavior and expertise context for this project; Claude reads it automatically when
working in this repository.

## Directory Structure & Path Context

The project infrastructure acts as a wrapper, and the related shell-script files live in the `./scripts` directory.

```text
symfony-scripts/                             ← Repository root
└── scripts/                                 ← shell-script
    ├── base/                                ← Environment-independent install and configuration scripts
    │   ├── app/                             ← PHP 8.4 config files + Symfony app CLI scripts
    │   │   ├── php/                         ← PHP FPM/CLI config files (php.ini, pool.d)
    │   │   └── symfony/                     ← Symfony operation scripts (cache, database, message, assets)
    │   ├── cache/redis/                     ← Redis install and dev/prod configuration (redis.conf)
    │   ├── database/postgresql/             ← PostgreSQL installation
    │   ├── message/rabbitmq/                ← RabbitMQ installation
    │   ├── server/
    │   │   ├── nginx/                       ← Nginx installation and configuration (symfony.conf)
    │   │   └── supervisor/                  ← Supervisor installation + Messenger worker configuration
    │   ├── utility/
    │   │   ├── docker/                      ← Docker installation and deployment scripts
    │   │   └── git/                         ← Git configuration and local server scripts
    │   ├── _abstract.sh                     ← Shared functions and variable definitions
    │   ├── _environment.sh                  ← Environment variable setup
    │   ├── _platform.sh                     ← OS and platform detection
    │   └── _project.sh                      ← Project path configuration
    ├── containers/                          ← Docker container configuration
    │   ├── dev/                             ← Development docker-compose (Redis, PostgreSQL, RabbitMQ)
    │   └── prod/                            ← Production Dockerfile, entrypoint, Nginx/Apache, Supervisor
    ├── deploy/                              ← OS-specific environment deployment scripts
    │    ├── dev/
    │    │   ├── linux/ubuntu/               ← Ubuntu development server (packages, network, security, utilities)
    │    │   ├── mac/os/                     ← macOS development environment
    │    │   └── windows/wsl/                ← Windows development environment
    │    └── prod/                           ← Production deployment targets (cloud providers + on-premise)
    │         ├── aws/                       ← AWS (ECS, Elastic Beanstalk, Lightsail)
    │         ├── gcp/                       ← GCP (Cloud Run) — project default
    │         ├── ncloud/                    ← NAVER Cloud (Compute)
    │         └── office/server/             ← On-premise office server deployment
    ├── tools/                               ← Documents about tooling (AI assistants, IDEs)
    │   ├── ai/                              ← AI assistant references
    │   │   ├── anthropic/
    │   │   │   └── claude/                  ← _ABSTRACT.md, _PLUGIN.md, _SKILLS.md
    │   │   ├── google/
    │   │   │   └── gemini/                  ← _ABSTRACT.md
    │   │   └── microsoft/
    │   │       └── github/                  ← _ABSTRACT.md (GitHub Copilot)
    │   └── ide/                             ← IDE setup references
    │       ├── phpstorm/                    ← _ABSTRACT.md, _CONFIG.md
    │       ├── vscode/                      ← _ABSTRACT.md, _CONFIG.md, symfony.code-snippets, CLAUDE.md
    │       └── tutorial.sh                  ← IDE onboarding helper script
    └── CLAUDE.md
```

## Category Purpose

| Category | Purpose |
|---------|---------|
| `base/` | Environment-independent component install and config scripts — referenced by both `containers/` and `deploy/` |
| `containers/dev/` | Local development Docker environment — run infrastructure services via `docker-compose up` |
| `containers/prod/` | Production container image build and deployment scripts |
| `deploy/dev/` | OS-specific development machine initial setup — packages, network, and security configuration |
| `deploy/prod/` | Production server deployment scripts — executed via `deploy.sh` |
| `tools/ai/` | Per-vendor AI assistant references — Anthropic Claude (plugins, skills), Google Gemini, GitHub Copilot |
| `tools/ide/` | IDE setup and optimization references — PhpStorm and VSCode configuration, snippets, onboarding |

## Shared Function Pattern

`base/_abstract.sh` defines shared variables and helper functions used by all other scripts. `_environment.sh` sets
environment variables and `_platform.sh` detects the OS/arch. Source these at the top of any new script:

```bash
source "$(dirname "$0")/../../base/_abstract.sh"
```

## Usage

```bash
# Start development infrastructure (PostgreSQL, Redis, RabbitMQ) — run from project root
docker-compose -f scripts/containers/dev/docker-compose.yml up -d

# Initial Ubuntu dev server setup (run once on a new machine)
bash scripts/deploy/dev/linux/ubuntu/deploy.sh

# Production server deploy
bash scripts/deploy/prod/office/server/deploy.sh
```

## Key Scripts

| Script | Role |
|--------|------|
| `base/app/symfony/assets.sh` | AssetMapper asset compilation |
| `base/app/symfony/cache.sh` | Symfony cache clear and warm-up |
| `base/app/symfony/database.sh` | Doctrine migration execution |
| `base/app/symfony/scheduler.sh` | Symfony Scheduler task management (Messenger worker helpers live in `base/app/symfony/common/_messenger.sh`) |
| `containers/dev/docker-compose.yml` | Development environment infrastructure service definitions |
| `containers/prod/deploy.sh` | Production container build and deployment |
| `deploy/dev/linux/ubuntu/deploy.sh` | Ubuntu development server initial setup |
| `deploy/dev/mac/os/deploy.sh` | Mac development server initial setup |
| `deploy/dev/windows/wsl/deploy.sh` | Windows development server initial setup |
| `deploy/prod/aws/ecs/deploy.sh` | AWS ECS production deploy (alternative) |
| `deploy/prod/gcp/cloud_run/deploy.sh` | GCP Cloud Run production deploy (project default) |
| `deploy/prod/office/server/deploy.sh` | On-premise office server deployment |
