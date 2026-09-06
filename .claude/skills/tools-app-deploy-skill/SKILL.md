---
name: tools-app-deploy-skill
description: "A pre-deploy gate that, before running a deployment, fans the changed deploy assets (nginx, Cloud Run, ECS, deploy scripts) out to the domain reviewers to verify security/config and decide go/no-go. Use it for requests like 'pre-deploy check', 'is it safe to deploy', 'deploy gate', 'pre-deploy review', or 'deployment readiness review'. This skill does not run the actual deploy/rollback — it hands off to tools-gcp-cloudrun-skill for Cloud Run and tools-aws-ecs-skill for ECS."
---

# Deploy Gate Skill

**Right before** running a deployment, this gate fans the changed deploy assets out to their domain
reviewers, aggregates the security/config findings, and decides **go/no-go (PASS/BLOCK)**. On PASS, the
actual deploy is handed off to the respective deploy skill — **this skill does not deploy or roll back.**

- Intermediate artifacts location: `./.claude/tmp/` (gitignored)
- Verdict rule: any reviewer with ≥ 1 `[MUST]` → **BLOCK**; none → **PASS**
- Real deploy handoff: Cloud Run → `tools-gcp-cloudrun-skill`, AWS ECS → `tools-aws-ecs-skill`

**Scope distinction:** this skill is a **pre-deploy verification gate**. Running the deploy command,
shifting traffic, rolling back, and checking logs are handled by `tools-gcp-cloudrun-skill` (GCP) /
`tools-aws-ecs-skill` (AWS). To review a single domain only, use its review command directly
(`/server-nginx-review`, `/utility-shell-script-review`).

## Criteria (single source of truth: rule files)

The detailed gate criteria live in each domain rule (SoT). This skill does not restate them; it defines
only the routing, aggregation, and verdict procedure.

@see .claude/rules/server-nginx-rule.md — nginx security headers, static TTLs, FastCGI, 8080 exposure
@see .claude/rules/tools-gcp-cloudrun-rule.md — Cloud Run deploy, secrets, IAM, cost, IaC
@see .claude/rules/tools-aws-ecs-rule.md — ECS (Fargate) Task definition, secrets, IAM, autoscaling
@see .claude/rules/utility-shell-script-rule.md — deploy script safety (`rm -rf` guards, etc.)
@see .claude/skills/utility-git-commit-skill/SKILL.md — orchestration reference standard

---

## Routing (changed path → reviewer)

Match each changed file path against the rule `paths` glob to select the reviewer. One file can match
several reviewers (e.g. `scripts/containers/prod/**/Dockerfile` matches Cloud Run, ECS, and Shell).

| Changed path pattern | Reviewer (agent) | Backing rule (paths) |
|---|---|---|
| `scripts/**/nginx/**` | `server-nginx-reviewer` | `server-nginx-rule.md` |
| `scripts/containers/prod/**`, `**/*.tf`, `**/cloudbuild.yaml`, `**/Dockerfile` | `tools-gcp-cloudrun-reviewer` | `tools-gcp-cloudrun-rule.md` |
| `scripts/containers/prod/**`, `**/*.tf`, `**/taskdef*.json`, `**/buildspec.yml`, `**/Dockerfile` | `tools-aws-ecs-reviewer` | `tools-aws-ecs-rule.md` |
| `scripts/**/*.sh`, `scripts/**/entrypoint.sh` | `/utility-shell-script-review` (command — no agent) | `utility-shell-script-rule.md` |

> **Two dispatch shapes in this table.** The nginx / GCP / AWS rows name **reviewer agents** — those
> domains have no dedicated review command, so call the agent directly. The shell row names a
> **slash command**: the `utility-shell-script-author` / `-reviewer` agent pair was retired on
> 2026-08-16 in favour of command-based self-verification, so run `/utility-shell-script-review` in
> this session instead of spawning an agent that no longer exists.
>
> If the deploy target is Cloud Run, apply the GCP row only; if ECS, the AWS row only (both if both).

---

## Workflow

1. **Precondition — confirm the deploy target and scope**
   - Confirm the deploy target (**Cloud Run** / **AWS ECS**) and the scope of assets to verify.
   - If unclear, confirm with **one clear question** before proceeding (do not ask about multiple ambiguities at once).

2. **Collect changed assets**
   - Get the changed file list via `git diff --name-only` (or the user-specified scope).
   - Map the files to reviewers using the routing table above. If no reviewer matches, report "no gated
     deploy assets changed" and finish.

3. **Fan out to reviewers**
   - Call the mapped reviewer agents **in parallel** (no dependencies). Pass each the deploy target and changed file list.
   - For the shell row, run `/utility-shell-script-review` per changed script instead — it is a command, not an agent, so it runs in this session rather than as a parallel spawn.
   - Output: `./.claude/tmp/deploy-gate-<domain>-review.md` (e.g. `deploy-gate-nginx-review.md`).
   - Each reviewer reports findings at `[MUST]` / `[SHOULD]` / `[CONSIDER]` severity.

4. **Aggregate and decide**
   - Merge all review outputs and **dedupe findings** (same file + same issue counts once).
   - **PASS:** zero `[MUST]` → gate passes. `[SHOULD]`/`[CONSIDER]` are presented as recommendations.
   - **BLOCK:** ≥ 1 `[MUST]` → gate blocks. List the MUST items and their owning domain.

5. **Report and hand off**
   - **PASS:** present the aggregated report and point to the real deploy step
     (Cloud Run → `tools-gcp-cloudrun-skill`, ECS → `tools-aws-ecs-skill`).
   - **BLOCK:** present the MUST findings in priority order and request fixes. After fixing, **re-run from step 2**.

6. **Retry-limit handling**
   - If still BLOCK after 2 gate re-runs, **do not proceed to the deploy handoff.**
   - Present the last aggregated report and finish with the warning "gate not passed — manual review recommended".

---

## Destructive / Irreversible Operations

This skill only runs up to the gate, but the subsequent deploy steps can be destructive. For the
following, **explain the impact scope and confirmation procedure first** and proceed only after user
approval (CLAUDE.md `## Security Guidelines`):

- **Actual deploy, traffic shift, rollback**, **`terraform apply` (including resource replacement/destroy)**,
  and **IAM role changes** → each deploy skill presents the `plan`/impact first, then gets approval. This
  gate is the pre-approval step.
- **`git push`** is set to `ask` in `settings.json`, so it always requires user confirmation.
  `[Verified]` [Read: .claude/settings.json:94]
- The pre-deploy security check is this gate. The `tools-gcp-cloudrun-reviewer` /
  `tools-aws-ecs-reviewer` rows own the deploy security criteria (secret injection, IAM least
  privilege, image immutability) — there is no separate `security-auditor` agent in this project.

## Checklist (common to the gate)

- [ ] Is the deploy target (Cloud Run / ECS) confirmed?
- [ ] Are all changed deploy assets mapped via the routing table?
- [ ] Are all matching domain reviewers called (nginx · gcp/aws · shell as matched)?
- [ ] Are there zero `[MUST]` findings (any one → BLOCK)?
- [ ] Are secrets injected via Secret Manager/SSM, not plaintext env vars or commits?
- [ ] Are image tags digests (immutable) — no `latest`?
- [ ] Is a dedicated service account / Task Role used with least privilege (no Owner/Editor or wildcards)?
- [ ] Do deploy scripts have safety guards such as `rm -rf` guards?

Report the aggregated review result classified by severity MUST (critical) / SHOULD (recommended) / CONSIDER (optional).
