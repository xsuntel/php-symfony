---
name: tools-gcp-cloudrun-skill
description: Use when deploying and operating this Symfony project on Google Cloud Run. Covers Cloud Run service deployment, traffic splitting, revision rollback, log inspection, Secret Manager secret injection, IAM service accounts, and autoscaling/cost settings. Triggered by requests like "Cloud Run deploy", "Cloud Run rollback", "Cloud Run logs", "gcloud run", "traffic split", or "Secret Manager injection". Do not use it for a complete command already given, such as "run gcloud run deploy ...".
---

# Google Cloud Run Skill

This is the entry point for deploying and operating this project on GCP Cloud Run.

## Information Source (single source of truth: the rule file)

**All detailed criteria** — Cloud Run deployment architecture, secrets, IAM least privilege, cost, and
IaC — are in the rule file. This skill does not duplicate the rules; it only provides the working
procedure and verification commands.

@see .claude/rules/server-nginx-rule.md — container nginx, port 8080 exposure, TLS termination, deployment checklist
@see .claude/rules/tools-gcp-cloudrun-rule.md — full Cloud Run deployment/secrets/IAM/cost/IaC standards (SoT)
@see https://cloud.google.com/run/docs

Source of truth (configuration): `scripts/containers/prod/**` (Dockerfile/nginx), `**/*.tf`, `**/cloudbuild.yaml`.

> ⚠️ **gcloud CLI options, service policies, and pricing change frequently.** The commands below are
> conventions; verify exact flags, limits, and prices with `gcloud ... --help` or the official
> documentation before running — do not assert unverified flags or defaults.

## Working Procedure

1. **Deployment prep** → Confirm build artifacts (`asset-map:compile`, `composer install --no-dev`, `cache:warmup`) are baked into the image. `APP_ENV=prod` / `APP_DEBUG=false`, secrets injected via Secret Manager (no plaintext environment variables). See the rule's `## Deployment Architecture` and `## Secrets & Configuration`.
2. **Migrations** → Not run automatically at container startup, but in a **separate step** (a Cloud Build step / Cloud Run Job), per EntityManager. See the rule's `## Deployment Architecture`.
3. **Traffic shift** → After deploying the new revision, confirm `/healthcheck.php` passes and shift traffic gradually. Avoid an immediate 100% cutover.
4. **IAM/cost** → A dedicated service account with least-privilege roles per service; set `min/max-instances` and `concurrency` based on the load profile. See the rule's `## IAM & Security` and `## Cost Awareness`.

## Verification & Operation (Bash)

State the project ID, region (e.g. `asia-northeast3`), and service name as assumptions. Keep them in variables.

```bash
# Assumed variables (replace with real values)
PROJECT_ID="your-project"
REGION="asia-northeast3"
SERVICE="your-service"

# Inspect current service state, revisions, and traffic
gcloud run services describe "${SERVICE}" --region "${REGION}" --project "${PROJECT_ID}"
gcloud run revisions list --service "${SERVICE}" --region "${REGION}" --project "${PROJECT_ID}"

# Deploy an image (digest tag preferred — no latest)
gcloud run deploy "${SERVICE}" \
  --image "${REGION}-docker.pkg.dev/${PROJECT_ID}/repo/${SERVICE}@sha256:..." \
  --region "${REGION}" --no-traffic

# Inject secrets (Secret Manager reference — never pass a plaintext value)
gcloud run services update "${SERVICE}" --region "${REGION}" \
  --update-secrets "DATABASE_URL=projects/${PROJECT_ID}/secrets/database-url:latest"

# Gradual traffic shift → raise the ratio after the health check passes
gcloud run services update-traffic "${SERVICE}" --region "${REGION}" \
  --to-revisions "NEW_REVISION=10"

# Health check (container-internal 8080)
curl -f "$(gcloud run services describe "${SERVICE}" --region "${REGION}" --format='value(status.url)')/healthcheck.php" || echo "UNHEALTHY"

# Inspect logs
gcloud run services logs read "${SERVICE}" --region "${REGION}" --limit 100
```

## Destructive / Irreversible Operation Caution

For the operations below, **explain the impact scope and confirmation procedure first** and proceed
only after user approval (CLAUDE.md security & agent-usage rules):

- **Rollback** — shift traffic to a previous revision. Present the rollback target revision and the current traffic ratio first.
  ```bash
  gcloud run services update-traffic "${SERVICE}" --region "${REGION}" --to-revisions "PREVIOUS_REVISION=100"
  ```
- **Service/revision deletion**, **IAM role changes**, **`terraform apply` (including resource replacement / destroy)** — review and present the `plan` / impact scope first, then get approval.

## Checklist (common to deployment & review)

- [ ] Are build artifacts (assets, vendor, cache) baked into the image (no runtime volume dependency)?
- [ ] Is it `APP_ENV=prod` / `APP_DEBUG=false`?
- [ ] Are all production secrets injected via Secret Manager (no plaintext env vars, not committed)?
- [ ] Does the container listen on `PORT` (8080) with no TLS termination of its own?
- [ ] Are session/cache/lock in Redis and persistent data in Cloud SQL (stateless container)?
- [ ] Were migrations run per EntityManager in a separate step?
- [ ] Is the image tag a digest (immutable) (no `latest`)?
- [ ] Is there a dedicated service account per service with least-privilege roles (no Owner/Editor)?
- [ ] Was traffic shifted gradually after the health check passed?
- [ ] Are `min/max-instances` and `concurrency` set based on the load profile?

When a review is requested, report severity as MUST (critical) / SHOULD (recommended) / CONSIDER (optional).
