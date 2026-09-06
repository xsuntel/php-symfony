# AWS / ECS (Fargate) — Technical Reference

This document holds the **annotated deployment examples and the pre-deploy checklist** for running this
Symfony application on AWS ECS (Fargate) — the **alternative** target to the project-default GCP Cloud
Run. The enforced judgment criteria (SoT) live in the rule file — if this document conflicts with the
rule, the rule wins.

@see .claude/rules/tools-aws-ecs-rule.md — ECS judgment criteria (SoT)
@see .claude/rules/tools-gcp-cloudrun-rule.md — the project-default target
@see https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ — ECS official docs
@see https://docs.aws.amazon.com/secretsmanager/latest/userguide/ — Secrets Manager official docs

> ⚠️ AWS CLI flags, service policies, and pricing change frequently. The snippets below are
> **illustrative** — verify exact flags, limits, and prices in the official docs before running them.
> Assumed context: region `ap-northeast-2` (Seoul), cluster `symfony`, service `symfony-app`,
> account `ACCOUNT_ID`, image in ECR repo `symfony/app`.

---

## 1. Task Definition (`taskdef.json`)

Version-controlled Task Definition. Note the **two separate roles**, secrets by ARN, and container port
8080 (the ALB Target Group forwards to it; nginx does not terminate TLS).

```json
{
  "family": "symfony-app",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "512",
  "memory": "1024",
  "executionRoleArn": "arn:aws:iam::ACCOUNT_ID:role/symfony-app-execution",
  "taskRoleArn": "arn:aws:iam::ACCOUNT_ID:role/symfony-app-task",
  "containerDefinitions": [
    {
      "name": "app",
      "image": "ACCOUNT_ID.dkr.ecr.ap-northeast-2.amazonaws.com/symfony/app:GIT_SHA",
      "portMappings": [{ "containerPort": 8080, "protocol": "tcp" }],
      "environment": [
        { "name": "APP_ENV", "value": "prod" },
        { "name": "APP_DEBUG", "value": "false" }
      ],
      "secrets": [
        { "name": "APP_SECRET", "valueFrom": "arn:aws:secretsmanager:ap-northeast-2:ACCOUNT_ID:secret:app-secret" },
        { "name": "DATABASE_URL", "valueFrom": "arn:aws:secretsmanager:ap-northeast-2:ACCOUNT_ID:secret:database-url" }
      ],
      "healthCheck": {
        "command": ["CMD-SHELL", "curl -f http://localhost:8080/healthcheck.php || exit 1"],
        "interval": 30, "timeout": 5, "retries": 3
      },
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/symfony-app",
          "awslogs-region": "ap-northeast-2",
          "awslogs-stream-prefix": "app"
        }
      }
    }
  ]
}
```

- **Execution Role** = ECR pull + Secrets/SSM read + CloudWatch Logs write (used by the ECS agent).
- **Task Role** = the AWS permissions the running app needs. Never merge the two.
- Secrets injected by ARN in `secrets` — never plaintext in `environment`, never committed `.env.*.local`.
- Image tag is the commit SHA (immutable). Never `:latest` in production.

---

## 2. Rolling Deploy with Circuit Breaker

Zero-downtime rollout: register a new revision → `update-service` → ALB health check → auto-rollback on
failure.

```bash
# Register the new revision
aws ecs register-task-definition --cli-input-json file://taskdef.json

# Roll out; circuit breaker rolls back automatically on failed health checks
aws ecs update-service \
  --cluster symfony --service symfony-app \
  --task-definition symfony-app \
  --deployment-configuration \
    "deploymentCircuitBreaker={enable=true,rollback=true},minimumHealthyPercent=100,maximumPercent=200"
```

- ALB Target Group health check path = `/healthcheck.php` (nginx short-circuits 200 without PHP).
- Set `minimumHealthyPercent`/`maximumPercent` explicitly — do not rely on defaults.

---

## 3. Migrations as a Separate Step (`run-task`)

Do **not** run migrations at container startup. Run a one-shot task on the same image/network per
EntityManager, overriding the command.

```bash
aws ecs run-task \
  --cluster symfony --launch-type FARGATE \
  --task-definition symfony-app \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-priv],securityGroups=[sg-task],assignPublicIp=DISABLED}" \
  --overrides '{"containerOverrides":[{"name":"app","command":["php","bin/console","doctrine:migrations:migrate","--no-interaction","--em=default"]}]}'
```

---

## 4. Secrets & IAM (least privilege)

```json
// symfony-app-execution role — scope GetSecretValue to specific ARNs only
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Action": "secretsmanager:GetSecretValue",
    "Resource": [
      "arn:aws:secretsmanager:ap-northeast-2:ACCOUNT_ID:secret:app-secret-*",
      "arn:aws:secretsmanager:ap-northeast-2:ACCOUNT_ID:secret:database-url-*"
    ]
  }]
}
```

- Never `AdministratorAccess` or wildcard `Resource: "*"`.
- RDS and ElastiCache in private subnets; inbound only from the ECS task security group.
- Fargate tasks `assignPublicIp=DISABLED` with egress via NAT.

---

## 5. CI (`buildspec.yml`) sketch

```yaml
version: 0.2
phases:
  pre_build:
    commands:
      - composer audit && npm audit --omit=dev || true   # gate; fail policy per project
      - vendor/bin/phpstan analyse && vendor/bin/phpunit
  build:
    commands:
      - docker build -t "$ECR/symfony/app:$CODEBUILD_RESOLVED_SOURCE_VERSION" .
      - aws ecr get-login-password | docker login --username AWS --password-stdin "$ECR"
      - docker push "$ECR/symfony/app:$CODEBUILD_RESOLVED_SOURCE_VERSION"
  post_build:
    commands:
      - aws ecs register-task-definition --cli-input-json file://taskdef.json
      - aws ecs update-service --cluster symfony --service symfony-app --task-definition symfony-app
```

Manage infrastructure with Terraform where possible; run `apply` only after reviewing `terraform plan`.

---

## Pre-Deploy Checklist

- [ ] Image tagged by commit SHA (no `:latest`), pushed to ECR.
- [ ] Build artifacts baked in (`asset-map:compile`, `composer install --no-dev`, `cache:warmup`).
- [ ] Secrets injected by ARN in the Task Def `secrets` block — no plaintext `environment`, no committed `.env.*.local`.
- [ ] `APP_ENV=prod`, `APP_DEBUG=false`.
- [ ] Execution Role and Task Role kept separate; least-privilege, no wildcard resources.
- [ ] Migrations run via `run-task` per EntityManager — not at startup.
- [ ] Deployment circuit breaker `enable=true, rollback=true`; `min/maxHealthyPercent` set.
- [ ] ALB Target Group health check = `/healthcheck.php`, forwarding to container port 8080.
- [ ] RDS/ElastiCache in private subnets; tasks `assignPublicIp=DISABLED`.
- [ ] Task CPU/memory + Application Auto Scaling sized to the load profile.
- [ ] `terraform plan` reviewed before `apply`; destructive changes confirmed.
- [ ] CI gates passed: `composer audit`, `npm audit`, PHPStan, PHPUnit.
