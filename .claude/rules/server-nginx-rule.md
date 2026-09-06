---
paths:
  - "scripts/**/nginx/**"
---

# Server Rules

This rule is the judgment criteria (SoT) for the Nginx configuration that serves this Symfony
application. The full annotated config files, the 4-file mapping, and the deployment checklist live in
the docs.

@see .claude/docs/server-nginx-docs.md — annotated configs, file mapping, checklist
@see https://symfony.com/doc/current/setup/web_server_configuration.html#nginx — Symfony web server config
@see https://nginx.org/en/docs/ — Nginx official docs

## General Rules

- Never run nginx as `user root;` — use `user www-data;` in the Ubuntu base configuration, and
  remove the `user` directive entirely in the Alpine production container (the Alpine nginx default
  is already non-root).
- Set `server_tokens off;` explicitly in every `server {}` block — do not rely on the global default.
- Always validate the configuration with `nginx -t` before reloading; in Docker: `docker exec <container> nginx -t`.
- Never modify the nginx configuration files inside a running container — always edit the source under
  `scripts/containers/prod/server/nginx/` and rebuild the image.
- Keep the location blocks of base/dev (`scripts/base/server/nginx/`) and prod
  (`scripts/containers/prod/server/nginx/`) in sync — they must implement the same Symfony routing
  logic; only the `fastcgi_pass` socket path and the `listen` address should differ between environments.
- Do not put `proxy_buffering off;` in a `server {}` block — that is an HTTP proxy directive and has
  no effect in an nginx→php-fpm direct-connection setup; instead scope the `fastcgi_buffering` directive
  inside the `location ~ ^/index\.php` block.
- Do not expose the PHP-FPM status page (`pm.status_path`) publicly — if monitoring is needed, restrict
  it with `allow 127.0.0.1; deny all;`.

## File Layout

- Two environments, four files (see the docs for the full mapping): base/dev `nginx.conf` + `conf.d/symfony.conf`, prod container `nginx.conf` + `http.d/www.conf`.
- The production Dockerfile copies both `nginx.conf` and `http.d/www.conf` unconditionally (STEP 05). Changing either one requires an image rebuild — never edit them inside a running container.
- External TLS is terminated by a host reverse proxy on port 443; the container internally exposes port 8080 and does not terminate SSL itself.

## Symfony Routing

@see https://symfony.com/doc/current/setup/web_server_configuration.html#nginx

The three-stage location pattern (`location /` → `location ~ ^/index\.php` → `location ~ \.php$`) is the reference in the docs. Order matters; never reorder these blocks.

- Never omit `internal;` — it prevents browsers from requesting `/index.php` directly.
- Do not add `$uri/` to the `try_files` fallback — a directory-listing fallback is not needed.
- Never change the `fastcgi_split_path_info` regex — it handles Symfony's PATH_INFO correctly.
- Always use `$realpath_root` (not `$document_root`) — it prevents OPcache path issues on symlink-switch deployments.

## PHP-FPM Connection

@see https://www.php.net/manual/en/install.fpm.configuration.php

- Prefer a Unix socket in the Ubuntu dev environment (`unix:/run/php/php8.4-fpm.sock`) — lower latency, no TCP overhead, same host.
- Use TCP in the Alpine production container (`127.0.0.1:9000`) — the Alpine php-fpm default pool uses that address.
- Never bind PHP-FPM to `0.0.0.0` — always use `127.0.0.1` for TCP.
- When nginx sits behind a reverse proxy that terminates SSL, add `fastcgi_param HTTPS on;` and `fastcgi_param HTTP_X_FORWARDED_PROTO https;` to `fastcgi_params` so Symfony generates correct HTTPS URLs.
- Keep `fastcgi_read_timeout` shorter than PHP-FPM's `request_terminate_timeout` (180s vs. 200s for the production pool). FPM must be the one to kill a runaway request, so it logs a backtrace instead of nginx returning a bare 504 — change one value and change the other.

## Static Asset Delivery

- `/assets/` (AssetMapper, content-hashed): never set a TTL shorter than one year — use `expires 1y;` + `Cache-Control "public, immutable"`. The filename hash is the cache buster.
- `/bundles/` (not content-hashed): use a moderate TTL (`expires 7d;` + `Cache-Control "public"`).
- Serve `/robots.txt` and `/sitemap.xml` directly with `access_log off;`.

## Security Directives

- Always set `server_tokens off;` in every `server {}` block, and add `fastcgi_hide_header X-Powered-By;` inside the PHP location. Do not add a custom `Server:` header.
- Always place the sensitive-file-type blocking `location ~ \.(env|sh|ini|...)$ { deny all; }` **after** `location ~ \.php$`.
- Always include the security response headers (`X-Frame-Options`, `X-Content-Type-Options`, `Referrer-Policy`) in every `server {}` block.
- `add_header` **replaces** the inherited set rather than merging it: a `location` that declares any `add_header` of its own loses every header inherited from `server {}`. Repeat all three security headers inside any location that sets its own header (typically the `Cache-Control` on `/assets` and `/bundles`). Do not "de-duplicate" them.
- Do **not** add `Content-Security-Policy` in nginx — CSP is application-specific; manage it in Symfony (NelmioSecurityBundle) or a controller response.
- Production TLS: `ssl_protocols TLSv1.2 TLSv1.3;` only (TLSv1.1 removed per RFC 8996), `ssl_session_tickets off;`, and generate `dh2048.pem` before the first deployment.

## Performance Tuning

- Gzip: enable it (`gzip on;`), use `gzip_comp_level 6;`, `gzip_min_length 1024;`, `gzip_vary on;`. Use `application/javascript` (not the deprecated `application/x-javascript`); do not gzip already-compressed image formats.
- Use `sendfile on; tcp_nopush on;` together at the http level (`tcp_nopush` has no effect without `sendfile`); add `tcp_nodelay on;`. The `sendfile off;` in `http.d/www.conf` is an intentional override for Docker volume compatibility — set it `on` only on bare-metal.
- Keep `fastcgi_buffering on;` inside the PHP location. `fastcgi_connect_timeout 10s;` (a 180s value masks FPM pool exhaustion); `fastcgi_read_timeout 180s;` is appropriate for this project's heavy financial data aggregation.

## WebSocket, SSE, and Turbo Streams

- Turbo Stream and Live Component requests are standard HTTP/AJAX through `try_files` → `index.php` — no special nginx config; keep `fastcgi_buffering on;`.
- Never set `fastcgi_buffering off;` at the server level — scope it to SSE locations only (with a long `fastcgi_read_timeout`), placed before the main PHP block.
- The current Ratchet/Pawl WebSocket connections are **outbound** from PHP workers — no nginx WebSocket proxy is required.

## Health Check Endpoint

- Always suppress access logs in `location = /healthcheck.php` and short-circuit with `return 200;` — do not execute `app/public/healthcheck.php`.
- Do not place any PHP-blocking rules before this location. Docker health check: `curl -f http://localhost:8080/healthcheck.php || exit 1`.

## Deployment Rules

@see https://symfony.com/doc/current/deployment.html

- Exclude `var/cache/`, `var/log/`, and `var/sessions/` from the deployment archive — they are runtime artifacts.
- Never commit `.env.local` or `.env.prod.local` — inject secrets via Docker environment variables or a secrets manager.
- Always run `doctrine:migrations:migrate --no-interaction --em=<name>` for each EntityManager with schema changes in the release.
- Use zero-downtime deployment: build the image → run `cache:warmup` inside the container → switch traffic to the new container.
- Always run `nginx -t` before `nginx -s reload` — a config syntax error stops nginx handling all requests on reload.
- Always run `asset-map:compile` before building the image — compiled assets must be baked in, not volume-mounted at runtime.
- Never deploy with `APP_DEBUG=true` — it disables OPcache file overrides and exposes full stack traces.
- Verify `fastcgi_read_timeout` is shorter than PHP-FPM's `request_terminate_timeout`.
- See the docs for the full production optimization checklist.
