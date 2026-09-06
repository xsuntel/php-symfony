---
paths:
  - "scripts/deploy/prod/aws/**"
  - "**/taskdef*.json"
  - "**/buildspec.yml"
---

# AWS / ECS (Fargate) Rules

These rules apply to all code and configuration that deploys and operates this Symfony application on
Amazon Web Services (AWS) — with **ECS on Fargate** as the runtime environment.

> This is the **alternative** deployment target. GCP / Cloud Run is the project default
> (@see .claude/rules/tools-gcp-cloudrun-rule.md). The shared deployment sources
> (`scripts/containers/prod/**`, `**/*.tf`, `**/Dockerfile`) are owned by the GCP rule; this rule
> activates only on AWS-specific files (`taskdef*.json`, `buildspec.yml`).

@see https://docs.aws.amazon.com/AmazonECS/latest/developerguide/
@see https://docs.aws.amazon.com/secretsmanager/latest/userguide/
@see .claude/rules/server-nginx-rule.md — container nginx, TLS termination (ALB), port 8080 exposure

> ⚠️ AWS CLI options, service policies, and pricing change frequently. **Always verify exact commands,
> flags, limits, and prices in the official documentation** — these rules fix architectural
> conventions, not volatile values.

## General Rules

- Unless stated otherwise, the default deployment target is **ECS on Fargate** (serverless) — do not introduce the EC2 launch type, EKS, or self-managed EC2 on your own.
- Pin the region to a single project-standard region (e.g. `ap-northeast-2`, Seoul) — do not scatter regions across services.
- The container listens on port 8080 — nginx exposes port 8080 inside the container and does not terminate TLS itself (external TLS is terminated by the ALB on 443). The ALB Target Group forwards to container port 8080.
- Design the container to be **stateless** — session/cache/lock state goes in Redis (ElastiCache), persistent data in PostgreSQL (RDS). Do not store state on the container-local filesystem.
- Push images to ECR with an immutable tag (digest or commit SHA preferred) — do not deploy to production with the `latest` tag.

## Deployment Architecture

- **Bake build artifacts into the image** — run `asset-map:compile`, `composer install --no-dev`, and `cache:warmup` at image build time; do not depend on runtime volume mounts (consistent with the nginx-rule deployment rules).
- Do not run Doctrine migrations automatically at container startup — run them per EntityManager in a **separate step** of the deployment pipeline (a one-shot `aws ecs run-task` on the same image/network, passing the command via `overrides`).
- Zero-downtime deployment: register a new Task Definition revision → roll out with `update-service` → confirm the ALB health check passes. Set the deployment circuit breaker to `enable=true, rollback=true` so a failed deployment rolls back automatically.
- Use `/healthcheck.php` as the ALB Target Group health check path (nginx returns a short-circuit 200 without executing PHP).
- Set `minimumHealthyPercent` and `maximumPercent` explicitly to control the available task ratio during rollout — do not rely on the defaults.

## Secrets & Configuration

- Store all production secrets (DB password, Redis DSN, provider API keys, `APP_SECRET`) in **Secrets Manager or SSM Parameter Store (SecureString)** and inject them by ARN reference in the Task Definition `secrets` block — no plaintext in the image or the Task Def `environment`, and never commit `.env.*.local`.
- Enforce `APP_ENV=prod` and `APP_DEBUG=false` — never deploy with `APP_DEBUG=true` (it exposes stack traces and disables OPcache).
- Compile configuration into `.env.local.php` with `composer dump-env prod` to reduce runtime parsing cost.

## IAM & Security (least privilege)

- **Separate** the **Task Execution Role** (for the ECS agent — ECR pull, Secrets/SSM read, CloudWatch Logs write) from the **Task Role** (the AWS permissions the app runtime uses). Do not consolidate both into a single role.
- Deny by default, allow explicitly: grant each role only the actions it actually needs (e.g. `secretsmanager:GetSecretValue` scoped to the specific secret ARN). Never grant `AdministratorAccess` or wildcard resources (`*`).
- Place RDS and ElastiCache in private subnets and allow inbound only from the ECS task security group — no public access or broad opening. Default Fargate tasks to `assignPublicIp=DISABLED` plus egress via NAT.
- For destructive/irreversible operations (deleting a service, changing IAM, rolling back a production Task Definition), **explain the impact scope and confirmation procedure first** and proceed only after user approval.

## Cost Awareness

- Set the Service desired count, Application Auto Scaling (min/max, target tracking), and Task CPU/memory allocation based on the load profile — no unjustified over-provisioning.
- For changes that affect cost (always-on large tasks, raised min capacity, NAT/ALB traffic), state the expected cost impact. Verify exact unit prices on the official pricing page.

## IaC / CI

- Manage infrastructure changes declaratively with Terraform (`.tf`) where possible — do not create drift through manual console changes. Version-control the Task Definition (`taskdef*.json`) as well.
- Run `apply` only after reviewing the `terraform plan` output — confirm destructive changes (`destroy`, resource replacement) beforehand.
- Run `composer audit`, `npm audit`, PHPStan, and PHPUnit as pre-deployment gates in CI. Automate image build, ECR push, `register-task-definition`, and `update-service` in the CI pipeline (e.g. `buildspec.yml` or GitHub Actions).
