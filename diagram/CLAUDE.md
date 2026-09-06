# CLAUDE.md

This file configures Claude's behavior and expertise context for this project; Claude reads it automatically when
working in this repository.

## Directory Structure & Path Context

The project infrastructure acts as a wrapper, and the related diagram files live in the `./diagram` directory.

```text
symfony-scripts/                             ← Repository root
└── diagram/                                 ← draw.io
    ├── base/                                ← Reference architecture diagrams per technology component
    │   ├── api/                             ← API Platform / REST reference diagrams
    │   ├── app/
    │   │   └── symfony/                     ← Symfony framework learning and reference diagrams
    │   ├── cache/                           ← Redis architecture diagrams
    │   ├── database/                        ← PostgreSQL schema and structure diagrams
    │   ├── message/                         ← RabbitMQ topology diagrams
    │   ├── server/                          ← Nginx configuration diagrams
    │   └── utility/                         ← Docker and Git utility diagrams
    ├── containers/                          ← Docker container layout diagrams
    │   ├── dev/
    │   └── prod/
    ├── deploy/                              ← Deployment environment architecture diagrams
    │    ├── dev/                            ← Domain and feature flow / sequence diagrams
    │    │   └── app/                        ← Mirrors app domain structure (Abstract, Providers, Partners, etc.)
    │    └── prod/                           ← Production infrastructure layered diagrams (0-base … 9-tools) per cloud provider
    │         ├── aws/                       ← AWS layered diagrams
    │         ├── gcp/                       ← GCP layered diagrams
    │         └── ncloud/                    ← NAVER Cloud layered diagrams
    └── CLAUDE.md
```

## File Naming Convention

| Location | Convention | Example |
|----------|-----------|---------|
| `base/` | `{component}.drawio` | `redis.drawio`, `nginx.drawio` |
| `deploy/dev/` | Domain namespace path as-is | `providers/apac/kor/finance/.../index.drawio` |
| `deploy/prod/{provider}/` | `{N} - {layer}.drawio` | `aws/0 - base.drawio`, `gcp/4 - database.drawio` |

## Category Purpose

| Category | Purpose |
|---------|---------|
| `base/` | Technology component references — infrastructure layout and Symfony learning diagrams |
| `containers/` | Docker container diagrams — container placement per dev/prod environment |
| `deploy/dev/` | Development environment flow diagrams — domain page and API sequence diagrams |
| `deploy/prod/` | Production infrastructure per cloud provider (`aws/`, `gcp/`, `ncloud/`) — layered diagrams: base, network, app, cache, DB, message, server, CDN, API, tools |

## Notes

- `deploy/dev/app/` mirrors the app domain structure (`Abstract/`, `Providers/`, `Partners/`, etc.) — add new
  domain diagrams here when creating a new domain under `app/src/`.
- Draw.io files can be created and edited directly via the MCP `drawio-tool` server available in this environment
  (e.g. `open_drawio_xml`, `open_drawio_mermaid`, `get_page`/`set_page`).
