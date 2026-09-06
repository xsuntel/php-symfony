# tools-agent-team memory

> Translated from Korean to English on 2026-08-30, per the `## Documentation Language` rule in
> `CLAUDE.md`. Nine factual errors in the original draft were corrected in the same pass — they are
> listed under `## Corrections carried forward` so they cannot be re-seeded from here.

## Role (verified)

- **The direct spawn set is defined by five prefixes** — `cache-`, `database-`, `server-`,
  `tools-aws-`, `tools-gcp-`. Not a fixed list of names: fix it with a **step-0 preflight every
  invocation** (`ls -1 .claude/agents/{cache,database,server,tools-aws,tools-gcp}-*.md`).
  **Currently resolves (2026-08-30) to 5** — `cache-redis-reviewer` · `database-postgresql-reviewer` ·
  `server-nginx-reviewer` · `tools-gcp-cloudrun-reviewer` · `tools-aws-ecs-reviewer`.
  `app-*`, `api-platform-*`, `message-*` and `utility-*` are **never spawned under any circumstances**.
- **When the resolution disagrees with memory, the resolution wins** — spawn a new match absent from
  the table only once its SoT rule is confirmed (never assign one arbitrarily); otherwise it is
  "routing unmatched". A tabled agent that fails to resolve is not a re-spawn candidate but **"cannot
  judge (target absent)"**, and it suspends go/no-go.
- **Self and siblings fall out at the glob level** — `tools-agent-team` begins with `tools-` but
  matches neither `tools-aws-` nor `tools-gcp-`. Never widen to a bare `tools-`. The three
  orchestrators never spawn one another (double turn budget, ambiguous consolidator).
- **The repository has three orchestrators** — application code (PHP, JS, Twig), providers, shell,
  diagrams, commits and `.claude` belong to `app-agent-team`; the API Platform exposure layer
  (`ApiResource`, `State`, `api_platform.yaml`) to `api-agent-team`.
- Holds no judgment criteria. Each reviewer cross-checks its own rule (SoT).

## Structural trait — a single-role (Review) team

- All five are **`sonnet`, read-only, `maxTurns: 30`, `memory: project`**, declaring
  `disallowedTools: Edit, Write`.
- **No author, debugger or tester axis** → no author→reviewer loop, no REDO cycle, no test writing. A
  verdict is issued once; re-spawning happens only under partial-failure handling.
- Hence `maxTurns: 40`, lower than the siblings' **50** (not 80). One fan-out plus consolidation.
- When a configuration needs fixing, **issue the verdict only** and hand the fix to the user or
  `app-agent-team`.

## Corrections carried forward (do not regress)

1. **The five reviewers cannot write any file** — `disallowedTools: Edit, Write` on all five.
   A per-domain tmp path (`tmp/tools/<domain>-review.md`) produces a spawn that fails at its last
   step. Ask for findings **in the returned report**; only the consolidated report uses tmp.
2. **Read-only IS harness-enforced here.** `memory: project` auto-grants `Write`/`Edit`, but
   `disallowedTools` **reverses that per tool**. They retain `Bash`, so only that part is self-held.
3. **The tool lists are not identical** — `cache-redis-reviewer` and `database-postgresql-reviewer`
   also carry `WebFetch, WebSearch`; the other three are `Read, Grep, Glob, Bash` only.
4. **`cache-redis-rule.md` does NOT declare `app/src/**/*.php`.** It does reach service- and
   repository-layer PHP, so it still over-matches — but never cite a glob it does not have. **Read the
   rule's `paths` when the call is close** rather than reciting a list from memory.
5. **The GCP↔AWS collision lives in the gate's routing table**
   (`tools-app-deploy-skill/SKILL.md:42-43`), not in `tools-aws-ecs-rule.md`, whose own `paths` are
   narrower than that table implies. Same discipline: read the rule, do not recite it.
6. **`app/migrations/**` is a routing decision, not a `paths` match** — `database-postgresql-rule.md`
   declares `Entity/**`, `EntityRepository/**`, `Repository/**` only, while its body is SoT for
   migrations.
7. **`git push` is `ask` at `settings.json:94`**, not 107.
8. **Both sibling orchestrators use `maxTurns: 50`**, not 80.
9. **The active output style is `abstract-english-style`** (`settings.json:8`), not the Korean base.

Two imperatives the draft omitted, both from the operational contract:

- **Relay the findings** — a subagent's report is not shown to the user, so anything that matters must
  be restated in the consolidated report.
- **Preflight covers every target kind**, not just agents: skill, command, and any rule path cited as
  SoT in a spawn prompt (a reviewer told to read a missing rule improvises).

## Routing (path → reviewer)

> Re-confirm the roster with the step-0 preflight before routing. Corrections 4–6 above qualify these.
> The globs below are a **working map, not the authoritative list** — each rule's own `paths` wins, so
> read the rule when a suppression or routing call is close.

- `{cache,lock}.yaml` · PHP under `Service/**`, `Repository/**`, `EntityRepository/**`,
  `MessageQueryHandler/**` **related** to caching, locking, sessions or the transport →
  `cache-redis-reviewer`
- `app/src/{Entity,EntityRepository,Repository}/**` · `app/migrations/**` → `database-postgresql-reviewer`
- `scripts/**/nginx/**` → `server-nginx-reviewer`
- `scripts/deploy/prod/gcp/**` · `**/cloudbuild.yaml` · Cloud Run-targeted `scripts/containers/prod/**`,
  `*.tf`, `Dockerfile` → `tools-gcp-cloudrun-reviewer`
- `scripts/deploy/prod/aws/**` · `**/taskdef*.json` · `**/buildspec.yml` · ECS-targeted shared paths →
  `tools-aws-ecs-reviewer`
- The five have no interdependencies → **all may be spawned in parallel in one response**.

## Over-matching — this team's most common misjudgement (3 cases)

1. **cache ↔ database overlap at the repository layer** (correction 4). When the change is unrelated
   to caching, locking, sessions or the transport, **do not spawn** the cache reviewer; if already
   spawned, **remove** the unrelated findings (remove, not merge).
2. **GCP ↔ AWS collide in the gate's routing** (correction 5) — fix the deploy target first and spawn
   **one side only**. Ask once when unclear; if both ran, duplicate merging is mandatory.
3. **`database-postgresql-rule.md` ↔ `app-php-symfony-05-doctrine-rule.md` share paths** — this team
   looks only at mapping, queries and indexes. Mark domain-logic findings as `app-agent-team`'s and merge.

## Not in the roster (do not confuse)

- **`message-rabbitmq-reviewer` is not on this team** — matches none of the five prefixes. Point at
  `/message-rabbitmq-review` instead of spawning it.
- **No shell-script reviewer agent exists** (merged into a command 2026-08-16) —
  `/utility-shell-script-review`.
- **GCP and AWS have no `/…-review` command** — spawn the reviewer directly or use the gate.

## Deploy go/no-go — not owned by this team

- The owner is the `tools-app-deploy-skill` gate, which runs its **own fan-out** to the nginx, GCP and
  AWS reviewers (three of this roster) plus `/utility-shell-script-review`.
- On an "is it safe to deploy" intent, **delegate to the gate with the `Skill` tool**. Spawning
  directly splits the verdict and makes go/no-go ownership ambiguous.
- A single-domain request ("just nginx") skips the gate and spawns that reviewer directly.
- **This report's go/no-go is an infrastructure-configuration-quality verdict, not deployment
  approval.**

## Spawn & consolidation contract

- Seven mandatory payload fields: target file list · role (**fixed to Review**) · SoT rule path
  (**kept per-domain**) · where the result goes (**the returned report**) · severity vocabulary · no
  secrets · mark unrun gates.
- **Never mix domain rules** — the cache reviewer given the ECS rule judges against criteria that are
  not its own.
- **Partial failure** — re-spawn a failed axis exactly once; if it still fails, mark it "cannot judge
  (not performed)" and **suspend go/no-go**.
- **Exhausting your own turns is also a partial failure** — record **incrementally** as results
  arrive; when the budget is tight mark unconsolidated axes "cannot judge (not consolidated)".
- **`exit 0` does not mean "passed"** — with `app/vendor` absent or incomplete, `lint:yaml` and
  `lint:container` break or skip. Tally across **passed / failed / unchecked**.

## tmp paths (collision hazard)

- Consolidated report: **`./.claude/tmp/tools/agent-team-report.md`**, fixed. No per-domain path
  (correction 1). The reviewers are **not** worktree-isolated — what stops them writing is
  `disallowedTools`, not isolation.
- `./.claude/tmp/app/**` is `app-agent-team`'s and `./.claude/tmp/api/**` is `api-agent-team`'s —
  never overwrite them. `mkdir -p` the full parent chain; `settings.json` denies `Bash(rm:*)`, so
  cleanup is left to `cleanupPeriodDays` and `.gitignore`.

## Verdict & safety

- Blocking verdict: ≥ 1 `[MUST]` from any reviewer → no-go; 0 → go. An unjudged axis suspends it.
- **Never modify configuration or code directly** — `disallowedTools: Edit` enforces that half at the
  harness level, and `Write` is scoped to the `./.claude/tmp/**` report. `Bash` is unrestricted and
  can write (`tee`, `sed -i`, `git apply`) — covered by the same boundary.
- **Never run a migration** (`doctrine:migrations:migrate`), a production deployment,
  `terraform apply`, a traffic shift or a rollback — those belong to the responsible skill, and user
  approval comes first.
- Never output a secret, credential or connection-string value; record the type and `file:line` and
  raise it as a `[MUST]`. Never guess an unconfirmed service ID, region or resource name.

## SoT

- Rules: .claude/rules/{cache-redis,database-postgresql,server-nginx,tools-gcp-cloudrun,tools-aws-ecs}-rule.md
- Operational contract: .claude/docs/abstract-orchestrator-contract-docs.md
- Deploy gate: .claude/skills/tools-app-deploy-skill/SKILL.md
- Structure index: .claude/rules/abstract-structure-rule.md
- Sibling orchestrators: .claude/agents/app-agent-team.md · .claude/agents/api-agent-team.md
