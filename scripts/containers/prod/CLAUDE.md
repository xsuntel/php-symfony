# CLAUDE.md

The production application image: **PHP-FPM + Nginx + Supervisor in a single container**, serving the
Symfony app on port 8080. Built and run by `deploy.sh`.

## Files

| Path | Role |
| --- | --- |
| `Dockerfile` | The image. Single stage, `php:8.4-fpm-alpine` base |
| `deploy.sh` | Host-side driver: free the port → build the app → build the image → run → verify |
| `.env.prod.local` | Copied to `app/.env.prod.local` by `setBuild()` before `composer dump-env prod` |
| `app/php/etc/php-fpm.d/www.conf` | The FPM pool (`www-data`, `127.0.0.1:9000`) |
| `app/php/etc/conf.d/docker-php-ext-opcache.ini` | OPcache, production settings |
| `server/nginx/etc/nginx/nginx.conf` | Global nginx config |
| `server/nginx/etc/nginx/http.d/www.conf` | The Symfony vhost |
| `utility/entrypoint.sh` | PID 1 — `exec`s supervisord and nothing else |
| `utility/supervisor/etc/supervisord.conf` | Process supervision for php-fpm and nginx |
| `utility/supervisor/etc/supervisor.d/messenger-consume.ini` | The two Messenger workers |
| `server/apache/` | **Unused.** Reference only — Nginx is the project standard |

## Build context

The build context is the **repository root** — `deploy.sh` passes `"${PROJECT_PATH}"` — so every
`COPY` path in the Dockerfile is repo-root-relative. What reaches the build is filtered by
`/.dockerignore`: secrets (`app/.env.*.local`), runtime artifacts (`app/var/**`) and dev-only sources
are excluded **there**, rather than being `rm`'d in a later layer where they would still sit in the
image history.

## The image is not hermetic, by design

Three steps run **on the host in `deploy.sh setBuild()`, before `docker build`**:

1. `composer install --no-dev` → `app/vendor/`
2. `composer dump-env prod` → `app/.env.local.php` (this is why the raw dotenv files can be ignored)
3. `asset-map:compile` → `app/public/assets/`

The Dockerfile then copies the already-built result. Changing this to build inside the image means
adding Composer and the full build toolchain to the runtime layer. See
`scripts/base/app/symfony/config/_deployment.sh`.

## Process model

`entrypoint.sh` does one thing: `exec /usr/bin/supervisord -n -c /etc/supervisord.conf`.

- **`exec`** so supervisord becomes PID 1 and receives `SIGTERM` from `docker stop` directly. Without
  it the shell stays PID 1, never forwards the signal, and every stop waits the full grace period for
  `SIGKILL`.
- **`-n`** so supervisord stays in the foreground; without it it daemonizes and the container exits.

Supervisor owns every process — the entrypoint must not start any of them itself.

| Program | Priority | User | Stop signal |
| --- | --- | --- | --- |
| `php-fpm` | 10 | root master → `www-data` workers | `QUIT` (graceful) |
| `nginx` | 20 | root master → `nginx` workers | `QUIT` (graceful) |
| `messenger-consume_00`, `_01` | 30 | `www-data` | `TERM` (finishes the in-flight message) |

php-fpm has the lower priority so it is accepting connections before nginx starts proxying to it.
`supervisorctl status` should show all four RUNNING; a missing worker means the `[include]` section
of `supervisord.conf` is not being read.

## Health check

`location = /healthcheck.php` in the nginx vhost is **short-circuited with `return 200;`** — it never
executes `app/public/healthcheck.php`. That is deliberate: it proves nginx is serving without
depending on PHP-FPM having a free worker, so a saturated pool does not read as a dead container. The
Dockerfile `HEALTHCHECK` and `deploy.sh`'s startup poll both target it.

## Dependency on the dev compose stack

`deploy.sh` runs the container with `--net symfony_back-end`, the network created by
`scripts/containers/dev/docker-compose.yml`. **The dev stack must be up first**, and
`.env.prod.local` must name the services as Compose names them —
`symfony-redis-dev`, `symfony-postgres-dev`, `symfony-rabbitmq-dev`. See
`scripts/containers/dev/CLAUDE.md`.

This is a local end-to-end test topology. Real deployments (Cloud Run, ECS) inject those hosts as
secrets instead; see `.claude/rules/tools-gcp-cloudrun-rule.md` and `tools-aws-ecs-rule.md`.

## Gotchas

- **`zz-docker.conf` is removed in STEP 05.** It overrides the pool to listen on `[::]:9000`, which
  would break the `fastcgi_pass 127.0.0.1:9000` in the nginx vhost.
- **Timeout ordering is load-bearing:** nginx `fastcgi_read_timeout 180s` < php-fpm
  `request_terminate_timeout 200`. FPM must be the one to kill a runaway request, so it logs a
  backtrace instead of nginx returning a bare 504. Change one and change the other.
- **`add_header` does not merge.** Any location in the vhost that sets its own header must repeat the
  three security headers, or it loses them.
- `opcache.validate_timestamps = 0` means **the image never picks up source changes** — rebuild, do
  not exec in and edit.
