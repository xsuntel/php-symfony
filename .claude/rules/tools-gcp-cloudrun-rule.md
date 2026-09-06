---
paths:
  - "scripts/deploy/prod/gcp/**"
  - "scripts/containers/prod/**"
  - "**/*.tf"
  - "**/cloudbuild.yaml"
  - "**/Dockerfile"
---

# GCP / Cloud Run Rules

These rules apply to all code and configuration that deploys and operates this Symfony application on
Google Cloud Platform (GCP) — with **Cloud Run** as the default runtime environment.

@see https://cloud.google.com/run/docs
@see https://cloud.google.com/secret-manager/docs
@see .claude/rules/server-nginx-rule.md — container nginx, TLS termination, port 8080 exposure

> ⚠️ GCP CLI options, service policies, and pricing change frequently. **Always verify exact commands,
> flags, limits, and prices in the official documentation** — these rules fix architectural
> conventions, not volatile values.

## General Rules

- Unless stated otherwise, the default deployment target is **Cloud Run** (managed) — do not introduce GKE or GCE on your own.
- Pin the region to a single project-standard region (e.g. `asia-northeast3`, Seoul) — do not scatter regions across services.
- The container listens on the `PORT` environment variable (8080 by default) — nginx exposes port 8080 inside the container and does not terminate TLS itself (external TLS is terminated by Cloud Run / the proxy).
- Design the container to be **stateless** — session/cache/lock state goes in Redis, persistent data in PostgreSQL (Cloud SQL). Do not store state on the container-local filesystem.
- Push images to Artifact Registry by tag (immutable digest preferred) — do not deploy to production with the `latest` tag.

## Deployment Architecture

- **Bake build artifacts into the image** — run `asset-map:compile`, `composer install --no-dev`, and `cache:warmup` at image build time; do not depend on runtime volume mounts (consistent with the nginx-rule deployment rules).
- Do not run Doctrine migrations automatically at container startup — run them per EntityManager in a **separate step** of the deployment pipeline (a Cloud Build step or a Cloud Run Job).
- Zero-downtime deployment: create a new revision → confirm the health check passes → gradually shift traffic. Use `/healthcheck.php` as the Cloud Run health check.
- Set the autoscaling floor (`min-instances`) explicitly based on cold-start sensitivity — do not rely on the default.

## Secrets & Configuration

- Store all production secrets (DB password, Redis DSN, provider API keys, `APP_SECRET`) in **Secret Manager** and inject them into Cloud Run as secret references — no plaintext in the image or environment variables, and never commit `.env.*.local`.
- Enforce `APP_ENV=prod` and `APP_DEBUG=false` — never deploy with `APP_DEBUG=true` (it exposes stack traces and disables OPcache).
- Compile configuration into `.env.local.php` with `composer dump-env prod` to reduce runtime parsing cost.

## IAM & Security (least privilege)

- Run each service under a **dedicated service account** — do not reuse the default Compute service account.
- Deny by default, allow explicitly: grant the service account only the roles it actually needs (e.g. Secret Manager `secretAccessor`, Cloud SQL `client`). Never grant broad Owner/Editor roles.
- Connect to Cloud SQL via the Cloud SQL Auth Proxy or a private IP — no public IP plus a broad firewall.
- For destructive/irreversible operations (deleting a service, changing IAM, rolling back a production revision), **explain the impact scope and confirmation procedure first** and proceed only after user approval.

## Cost Awareness

- Set `min-instances`, `max-instances`, `concurrency`, and CPU/memory allocation based on the load profile — no unjustified over-provisioning.
- For changes that affect cost (always-on instances, large machine types), state the expected cost impact. Verify exact unit prices on the official pricing page.

## IaC / CI

- Manage infrastructure changes declaratively with Terraform (`.tf`) where possible — do not create drift through manual console changes.
- Run `apply` only after reviewing the `terraform plan` output — confirm destructive changes (`destroy`, resource replacement) beforehand.
- Run `composer audit`, `npm audit`, PHPStan, and PHPUnit as pre-deployment gates in CI.
