---
name: tools-aws-ecs-skill
description: Use when deploying and operating this Symfony project on AWS ECS (Fargate). Covers Task Definition registration/rolling deploy, deployment circuit breaker rollback, CloudWatch log inspection, Secrets Manager/SSM secret injection, Task/Execution Role, run-task migrations, and Application Auto Scaling/cost settings. Triggered by requests like "ECS deploy", "ECS rollback", "ECS logs", "aws ecs", "task definition", "Secrets Manager injection", or "run-task migration". Do not use it for a complete command already given, such as "run aws ecs update-service ...".
---

# AWS ECS Skill

This is the entry point for deploying and operating this project on AWS ECS (Fargate).

> AWS ECS is the **alternative** deployment target; GCP Cloud Run is the project default
> (@see tools-gcp-cloudrun-skill).

## Information Source (single source of truth: the rule file)

**All detailed criteria** — ECS deployment architecture, secrets, IAM least privilege, cost, and IaC
— are in the rule file. This skill does not duplicate the rules; it only provides the working
procedure and verification commands.

@see .claude/rules/server-nginx-rule.md — container nginx, port 8080 exposure, TLS termination (ALB), deployment checklist
@see .claude/rules/tools-aws-ecs-rule.md — full ECS deployment/secrets/IAM/cost/IaC standards (SoT)
@see https://docs.aws.amazon.com/AmazonECS/latest/developerguide/

Source of truth (configuration): `scripts/containers/prod/**` (Dockerfile/nginx), `**/*.tf`,
`**/taskdef*.json`, `**/buildspec.yml`.

> ⚠️ **aws CLI options, service policies, and pricing change frequently.** The commands below are
> conventions; verify exact flags, limits, and prices with `aws <service> <cmd> help` or the official
> documentation before running — do not assert unverified flags or defaults.

## Architecture Overview

This project's production container runs php-fpm (background) + nginx (foreground) from a single
image, **exposes port 8080**, and does not terminate TLS itself
(`scripts/containers/prod/Dockerfile`). The ECS placement therefore maps as follows:

```text
Client → ALB(443, TLS termination) → Target Group(HTTP) → ECS Service(Fargate) → Task(container 8080)
                                       └ health check: GET /healthcheck.php
Migration: aws ecs run-task (one-shot, per EntityManager)   Secrets: Task Def secrets → Secrets Manager/SSM
State: session/cache/lock = ElastiCache Redis, persistent data = RDS PostgreSQL (stateless container)
```

## Working Procedure

1. **Deployment prep** → Confirm build artifacts (`asset-map:compile`, `composer install --no-dev`, `cache:warmup`) are baked into the image. `APP_ENV=prod` / `APP_DEBUG=false`; secrets injected by referencing Secrets Manager/SSM ARNs in the Task Definition `secrets` block (no plaintext `environment`). See the rule's `## Deployment Architecture` and `## Secrets & Configuration`.
2. **Migrations** → Not run automatically at container startup, but in a **separate step** (a one-shot `aws ecs run-task`), per EntityManager. Run it on the same image/network and pass the migration command via `overrides`. See the rule's `## Deployment Architecture`.
3. **Rolling deploy / health** → After registering the new Task Definition revision, roll out with `update-service`. Confirm the ALB Target Group health check (`/healthcheck.php`) passes. Set the deployment circuit breaker to `enable=true,rollback=true` so it rolls back automatically on failure. Soften an immediate full replacement with `minimumHealthyPercent`.
4. **IAM/cost** → Separate the Task Execution Role (ECR pull, secret read, log write) from the Task Role (app runtime permissions), least privilege. Set the Service desired count and Application Auto Scaling (target tracking) based on the load profile. See the rule's `## IAM & Security` and `## Cost Awareness`.

## Verification & Operation (Bash)

State the region (e.g. `ap-northeast-2`, Seoul), cluster, and service name as assumptions. Keep them in variables.

```bash
# Assumed variables (replace with real values)
AWS_REGION="ap-northeast-2"
CLUSTER="your-cluster"
SERVICE="your-service"
TASKDEF_FAMILY="your-taskdef"
ECR_REPO="123456789012.dkr.ecr.${AWS_REGION}.amazonaws.com/your-repo"

# Inspect current service state, in-progress rollout, and events
aws ecs describe-services --cluster "${CLUSTER}" --services "${SERVICE}" --region "${AWS_REGION}" \
  --query 'services[0].{status:status,desired:desiredCount,running:runningCount,deployments:deployments}'

# Inspect Task Definition revisions
aws ecs list-task-definitions --family-prefix "${TASKDEF_FAMILY}" --sort DESC --region "${AWS_REGION}"
aws ecs describe-task-definition --task-definition "${TASKDEF_FAMILY}" --region "${AWS_REGION}"

# Push the image (after ECR login — deploy by digest, no latest)
aws ecr get-login-password --region "${AWS_REGION}" \
  | docker login --username AWS --password-stdin "${ECR_REPO%/*}"
docker push "${ECR_REPO}:$(git rev-parse --short HEAD)"   # immutable tag (commit SHA, etc.)

# Register a new Task Definition (taskdef.json includes the image digest and secrets block)
aws ecs register-task-definition --cli-input-json file://taskdef.json --region "${AWS_REGION}"

# Rolling deploy (circuit breaker auto-rollback) — <N> is the revision just registered
aws ecs update-service --cluster "${CLUSTER}" --service "${SERVICE}" --region "${AWS_REGION}" \
  --task-definition "${TASKDEF_FAMILY}:<N>" --force-new-deployment \
  --deployment-configuration \
    'deploymentCircuitBreaker={enable=true,rollback=true},minimumHealthyPercent=100,maximumPercent=200'

# Wait for the deployment to complete (steady state)
aws ecs wait services-stable --cluster "${CLUSTER}" --services "${SERVICE}" --region "${AWS_REGION}"

# One-shot migration (swap the command per EntityManager)
aws ecs run-task --cluster "${CLUSTER}" --launch-type FARGATE --region "${AWS_REGION}" \
  --task-definition "${TASKDEF_FAMILY}:<N>" \
  --network-configuration 'awsvpcConfiguration={subnets=[subnet-xxx],securityGroups=[sg-xxx],assignPublicIp=DISABLED}' \
  --overrides '{"containerOverrides":[{"name":"app","command":["php","bin/console","doctrine:migrations:migrate","--no-interaction","--env=prod","--em=abstract"]}]}'

# ALB Target Group health (container 8080 → /healthcheck.php)
aws elbv2 describe-target-health --target-group-arn "${TARGET_GROUP_ARN}" --region "${AWS_REGION}" \
  --query 'TargetHealthDescriptions[].TargetHealth.State'

# Inspect logs (CloudWatch, awslogs driver)
aws logs tail "/ecs/${SERVICE}" --follow --since 10m --region "${AWS_REGION}"
```

## Destructive / Irreversible Operation Caution

For the operations below, **explain the impact scope and confirmation procedure first** and proceed
only after user approval (CLAUDE.md security & agent-usage rules):

- **Rollback** — switch to a previous Task Definition revision. Present the rollback target revision and the current rollout state first. The circuit breaker rolls back automatically on a failed deployment; a manual rollback redeploys the previous revision.
  ```bash
  aws ecs update-service --cluster "${CLUSTER}" --service "${SERVICE}" --region "${AWS_REGION}" \
    --task-definition "${TASKDEF_FAMILY}:<PREVIOUS_N>" --force-new-deployment
  ```
- **Service/Task Def deletion or deactivation** (`delete-service`, `deregister-task-definition`), **IAM role changes**, **`terraform apply` (including resource replacement / destroy)** — review and present the `plan` / impact scope first, then get approval.

## Checklist (common to deployment & review)

- [ ] Are build artifacts (assets, vendor, cache) baked into the image (no runtime volume dependency)?
- [ ] Is it `APP_ENV=prod` / `APP_DEBUG=false`?
- [ ] Are all production secrets injected via the Task Def `secrets` block (Secrets Manager/SSM) (no plaintext `environment`, not committed)?
- [ ] Does the container listen on 8080 with no TLS termination of its own (ALB terminates 443)?
- [ ] Are session/cache/lock in ElastiCache Redis and persistent data in RDS (stateless container)?
- [ ] Were migrations run per EntityManager in a separate `run-task`?
- [ ] Is the image tag immutable (digest/commit SHA) (no `latest`)?
- [ ] Are the Task Execution Role and Task Role separated with least privilege (no Admin)?
- [ ] Is the deployment circuit breaker `rollback=true` and was completion confirmed after the ALB health passed?
- [ ] Are the desired count, Application Auto Scaling (min/max), and CPU/memory set based on the load profile?

When a review is requested, report severity as MUST (critical) / SHOULD (recommended) / CONSIDER (optional).
