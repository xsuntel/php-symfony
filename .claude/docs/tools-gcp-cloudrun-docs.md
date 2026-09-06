# GCP / Cloud Run — Technical Reference

This document holds the **annotated deployment examples and the pre-deploy checklist** for running this
Symfony application on GCP Cloud Run (the project default runtime). The enforced judgment criteria (SoT)
live in the rule file — if this document conflicts with the rule, the rule wins.

@see .claude/rules/tools-gcp-cloudrun-rule.md — Cloud Run judgment criteria (SoT)
@see https://cloud.google.com/run/docs — Cloud Run official docs
@see https://cloud.google.com/secret-manager/docs — Secret Manager official docs

> ⚠️ gcloud flags, service policies, and pricing change frequently. The commands below are
> **illustrative** — verify exact flags, limits, and prices in the official docs before running them.
> Assumed context: project `PROJECT_ID`, region `asia-northeast3` (Seoul), service `symfony-app`.

---

## 1. Deployment Flow (build → deploy → shift traffic)

Zero-downtime rollout: build an immutable image → deploy a **no-traffic** revision → run migrations in a
separate step → verify health → shift traffic.

```bash
# 1) Build and push an immutable image (commit SHA tag, never :latest)
IMAGE="asia-northeast3-docker.pkg.dev/PROJECT_ID/symfony/app:${GIT_SHA}"
gcloud builds submit --tag "${IMAGE}"

# 2) Deploy a new revision WITHOUT shifting traffic yet
gcloud run deploy symfony-app \
  --image "${IMAGE}" \
  --region asia-northeast3 \
  --no-traffic --tag "rev-${GIT_SHA}" \
  --service-account symfony-app-run@PROJECT_ID.iam.gserviceaccount.com \
  --min-instances 1 --max-instances 10 --concurrency 80 \
  --cpu 1 --memory 512Mi \
  --set-env-vars APP_ENV=prod,APP_DEBUG=false \
  --set-secrets APP_SECRET=app-secret:latest,DATABASE_URL=database-url:latest

# 3) Verify the tagged revision health (see §4), then shift 100% traffic
gcloud run services update-traffic symfony-app \
  --region asia-northeast3 --to-tags "rev-${GIT_SHA}=100"
```

- `--no-traffic --tag` gives the revision a private URL for smoke-testing before it serves users.
- The container listens on `$PORT` (8080). nginx exposes 8080 inside the container and does **not**
  terminate TLS — Cloud Run/front proxy terminates it.
- Image tag is the commit SHA (immutable). Never deploy `:latest` to production.

---

## 2. Secret Injection (Secret Manager)

Never bake secrets into the image or pass them as plaintext env vars. Reference them by version.

```bash
# Create/rotate a secret
printf '%s' "$APP_SECRET_VALUE" | gcloud secrets create app-secret --data-file=-

# Grant the service account read access to THAT secret only (least privilege)
gcloud secrets add-iam-policy-binding app-secret \
  --member "serviceAccount:symfony-app-run@PROJECT_ID.iam.gserviceaccount.com" \
  --role roles/secretmanager.secretAccessor
```

- Inject with `--set-secrets ENV_NAME=secret-name:latest` (see §1).
- Enforce `APP_ENV=prod`, `APP_DEBUG=false`. Optionally `composer dump-env prod` at build time to compile
  `.env.local.php` and cut runtime parsing.

---

## 3. Migrations as a Separate Step

Do **not** run migrations at container startup. Run one Cloud Run Job (or Cloud Build step) per
EntityManager on the same image before shifting traffic.

```bash
gcloud run jobs deploy migrate-default \
  --image "${IMAGE}" --region asia-northeast3 \
  --service-account symfony-app-run@PROJECT_ID.iam.gserviceaccount.com \
  --set-secrets DATABASE_URL=database-url:latest \
  --command php \
  --args bin/console,doctrine:migrations:migrate,--no-interaction,--em=default
gcloud run jobs execute migrate-default --region asia-northeast3 --wait
```

---

## 4. Health Check

Cloud Run startup/liveness probes should hit the nginx short-circuit endpoint (returns 200 without
executing PHP — see the nginx rule).

```yaml
# service.yaml excerpt (Knative)
startupProbe:
  httpGet: { path: /healthcheck.php, port: 8080 }
  initialDelaySeconds: 5
  failureThreshold: 10
```

---

## 5. IAM (least privilege)

- Run under a **dedicated** service account (`symfony-app-run@…`) — never the default Compute SA.
- Grant only what is needed: Secret Manager `secretAccessor` (per secret), Cloud SQL `client`.
- Connect to Cloud SQL via the Auth Proxy or private IP — never public IP + broad firewall.

```bash
gcloud iam service-accounts create symfony-app-run --display-name "Symfony App (Cloud Run)"
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member "serviceAccount:symfony-app-run@PROJECT_ID.iam.gserviceaccount.com" \
  --role roles/cloudsql.client
```

---

## 6. IaC (Terraform) sketch

```hcl
resource "google_cloud_run_v2_service" "app" {
  name     = "symfony-app"
  location = "asia-northeast3"
  template {
    service_account = google_service_account.app.email
    scaling { min_instance_count = 1, max_instance_count = 10 }
    containers {
      image = var.image   # commit-SHA tag, injected by CI
      ports { container_port = 8080 }
      env {
        name = "APP_SECRET"
        value_source { secret_key_ref { secret = "app-secret", version = "latest" } }
      }
    }
  }
}
```

Run `terraform apply` only after reviewing `terraform plan`; confirm any `destroy`/replacement first.

---

## Pre-Deploy Checklist

- [ ] Image tagged by commit SHA (no `:latest`), pushed to Artifact Registry.
- [ ] Build artifacts baked in (`asset-map:compile`, `composer install --no-dev`, `cache:warmup`).
- [ ] Secrets injected via Secret Manager references — no plaintext env vars, no committed `.env.*.local`.
- [ ] `APP_ENV=prod`, `APP_DEBUG=false`.
- [ ] Migrations run in a separate Job/step per EntityManager — not at startup.
- [ ] New revision deployed `--no-traffic`, health verified, then traffic shifted.
- [ ] Dedicated service account with least-privilege roles (no Owner/Editor).
- [ ] `min/max-instances`, `concurrency`, CPU/memory sized to the load profile.
- [ ] `terraform plan` reviewed before `apply`; destructive changes confirmed.
- [ ] CI gates passed: `composer audit`, `npm audit`, PHPStan, PHPUnit.
