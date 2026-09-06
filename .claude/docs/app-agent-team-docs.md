# App Agent Team Composition

> Status: **Design document (SoT)** — the **repository-wide umbrella**. Defines the collaboration
> structure that groups every specialist agent along a workflow-role axis, and the rationale for
> `app-agent-team`'s routing, handoffs and verification loops.
> Written: 2026-07-11 · Last updated: 2026-08-28
>
> **Re-split 2026-08-28** — this document and `api-agent-team-docs.md` were a single consolidated file
> between 2026-08-16 and 2026-08-28, paired with the single orchestrator `agent-team`. That orchestrator
> was split back into `app-agent-team` and `api-agent-team`, and the documents followed: the
> **API-Platform-specific content moved back out** to `api-agent-team-docs.md` — the section 2
> sub-inventory, the API half of the section 3.5 Build team and its cross-domain boundary table, the
> section 4 template ② worked example, and section 5.1 in full. What remains here is the material that
> is genuinely repository-wide. The rationale for the split itself is section 5.2.
>
> **Scope of this document:** the 15 `app-*` agents, the 6 infrastructure reviewers, and the Commit,
> Diagram and Deploy teams. For the 5 `api-platform-*` agents and the API Platform Build loop, read
> `api-agent-team-docs.md` — it is the SoT for that domain and references this file for the shared
> principles rather than restating them.

@see .claude/docs/api-agent-team-docs.md — API Platform domain document (sub-inventory · Build loop · revision history)
@see .claude/rules/abstract-structure-rule.md — rule index (SoT)
@see .claude/skills/utility-git-commit-skill/SKILL.md — orchestration reference standard
@see .claude/skills/tools-app-deploy-skill/SKILL.md — pre-deploy gate fan-out
@see .claude/output-styles/abstract-english-style.md — document style (ADR · trade-offs · citation)

---

## 1. Overview and Premises

### Purpose

`.claude/` already holds a well-ordered set of per-domain agents, skills and rules, but **there was no
document binding them into a "team" and defining the collaboration flow.** This document defines a
composition that reorganises the 30 specialist agents along a **workflow-role** axis
(Review / Security / Debug / Test / Build / Commit / Diagram / Deploy).

The **API Platform domain** (resource DTOs, operations and serialization in `app/src/ApiResource/`;
Providers/Processors, validation, security and filters in `app/src/State/`) has its own document,
`api-agent-team-docs.md`, and its own orchestrator, `api-agent-team`. It appears in the section 2
matrix so the inventory stays complete, but its detail lives there — see section 5.2 for why the two
were separated.

### Established Premises (verified)

- The agent-teams experimental feature is already enabled — `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS: "1"`.
  `[Verified]` [Read: .claude/settings.json:13]
- The default permission mode is `plan`, the output style is `abstract-english-style`, and effort is
  `high`. `[Verified]` [Read: .claude/settings.json:7,8,94]
- Multi-agent orchestration is **no longer a single instance** — `utility-git-commit-skill` was the
  first, and today `utility-shell-script-skill` and several provider/API build skills run the same
  author→reviewer verification loop (`utility-claude-code-skill` has used a **command-based
  self-verification** loop instead of an agent pair since 2026-08-08).
  `utility-git-commit-skill` remains the **reference standard** among them. `[Verified]`
  [Read: .claude/skills/utility-git-commit-skill/SKILL.md]

### The Three-Layer Collaboration Principle

The existing assets separate responsibilities across the three layers below, and the team composition
inherits that principle unchanged.

```text
rules/     = the single source of truth (SoT) for verdicts. Auto-applied via paths globs, no natural-language trigger.
agents/    = executors. Load rules, docs and the output style with Read and perform the work.
skills/    = orchestrator / entry point. Controls retries, gates and artifacts.
commands/  = holders of procedure and criteria. Read by a skill as its self-verification basis, or invoked directly by the user.
```

- A rule is a **passively auto-applied** artifact with `paths` and no `description` (the exception
  being the index-like `abstract-structure-rule.md`, which deliberately has no frontmatter and loads
  only via the explicit reference in CLAUDE.md). Agents are triggered by their natural-language
  `description`. `[Verified]`
- Agents hold no criteria of their own; they reference the rules (SoT), docs and output style via
  `@see`. `[Verified]` [Read: .claude/agents/app-php-symfony-reviewer.md:16-19]
- **A skill does not necessarily call an agent** — since 2026-08-08 some domains **self-verify against
  the criteria in a command body** with no agent pair (section 4, template ②). In that case the three
  layers run rules → command → skill, with the agent layer empty. `[Verified]`

---

## 2. Agent Inventory (role × domain matrix)

The current **30 specialist** agents, organised by **workflow role (rows) × technical domain (columns)**.
`[Verified]` 2026-08-30 — **33 files** in the `agents/` tree, less the **three orchestrators**
(`app-agent-team.md`, `api-agent-team.md`, `tools-agent-team.md`). The specialist count is unchanged by
either the 2026-08-28 split or the 2026-08-30 addition; only the orchestrator count moved 1 → 2 → 3.
[Bash: `ls .claude/agents/*.md | wc -l` → 33]

| Workflow role | Backend (PHP) | Frontend (JS · Twig) | Infrastructure · data | Integration (API · provider) | Operations · configuration |
| --- | --- | --- | --- | --- | --- |
| **Security** (vulnerability diagnosis) | `app-php-symfony-analyzer` | `app-javascript-stimulus-analyzer` · `app-twig-symfony-analyzer` | — | `api-platform-analyzer` | — |
| **Debug** | `app-php-symfony-debugger` | `app-javascript-stimulus-debugger` · `app-twig-symfony-debugger` | — | — | — |
| **Review** (sole verdict) | `app-php-symfony-reviewer` | `app-javascript-stimulus-reviewer` · `app-twig-symfony-reviewer` | `database-postgresql-reviewer` · `cache-redis-reviewer` · `message-rabbitmq-reviewer` · `server-nginx-reviewer` · `tools-gcp-cloudrun-reviewer` · `tools-aws-ecs-reviewer` | `api-platform-reviewer` | — |
| **Test** | `app-php-symfony-tester` | `app-javascript-stimulus-tester` · `app-twig-symfony-tester` | — | — | — |
| **Build** (generate-verify) | `app-php-symfony-author` | `app-javascript-stimulus-author` · `app-twig-symfony-author` | — | `api-platform-author` (+ providers self-verify against the `*-build` commands) | — (Shell Script self-verifies against the `/utility-shell-script-review` command) |
| **Commit** | — | — | — | — | `utility-git-commit-author` + `utility-git-commit-reviewer` |
| **Diagram** (generate-verify) | — | — | — | — | `utility-drawio-diagram-author` + `utility-drawio-diagram-reviewer` |
| **Deploy** | — | — | (deploy gate: reuses `server-nginx-reviewer`, `tools-gcp-cloudrun-reviewer`, `tools-aws-ecs-reviewer` + the `/utility-shell-script-review` command) | — | — |

> **The Build role was created in this revision.** At the time of the draft only Commit (git) had an
> author→reviewer pair; today the API, provider and configuration domains all work the same way
> (section 4).
>
> **Claude Code configuration artifacts stopped being Build team members on 2026-08-08** — the author
> and reviewer agents were merged into the slash command `/utility-claude-code-review`, and the
> `utility-claude-code-skill` skill self-verifies against it (section 3.5).
>
> **Providers (UPbit, KoreaInvestment) likewise stopped being Build team members on 2026-08-15** — the
> 10 author and reviewer agents were merged into 5 `*-build` commands, and the 5 `*-build-skill`
> skills self-verify against them (section 3.5).
>
> **API Platform stopped being a Build team member on 2026-08-17** — `api-platform-author` was merged
> into the `/api-platform-rest-build` and `/api-platform-oauth2-build` commands and the agent itself
> was repurposed as `api-platform-analyzer` (the Analyze axis) (section 5.1). That left **Commit (Git)
> as the only** role retaining an author→reviewer **agent pair** under Build.
>
> **↑ That paragraph was partially reversed on 2026-08-22.** The same day, the 3 app-domain authors
> were filled in and `api-platform-author` was revived, making the Build team a hybrid of
> **4 agent pairs + 6 command self-verifications**. **The SoT for the authoring conventions is still
> the commands**, and `api-platform-author` references them via `@see` rather than duplicating them —
> the core of the merge decision (gathering the criteria into one file) holds. Detail in section 5.1,
> revision 3.
>
> **The Diagram role was created on 2026-08-19** — it covers generating draw.io diagrams under
> `diagram/**`, and unlike the Build role's convergence on command self-verification it adopted an
> **author→reviewer agent pair** (template ①). The reason is that `.drawio` XML output is large and
> that verifying id uniqueness and edge referential integrity benefits from an independent context
> uncontaminated by the generation process (see the selection criteria in section 4). It sits on its
> own row rather than under Build because its output is a diagram asset rather than source code, and
> its quality gate is XML structural verification rather than static analysis.
>
> **Shell Script also stopped being a Build team member on 2026-08-16** — the author and reviewer were
> merged into the slash command `/utility-shell-script-review`, and the `utility-shell-script-skill`
> skill drafts from that command's `## Authoring Conventions` and then self-verifies via its
> `## Review Procedure` (section 3.5).
>
> **The Analyze role joined on 2026-08-01.** The previously empty `*-code-analyzer` stubs (3 in the app
> domain: PHP, JS, Twig) were filled in as a static structural-analysis role, becoming a third
> analysis axis distinct from Review (rule compliance) and Debug (runtime cause) (section 3.2).
>
> **Revision of 2026-08-22 — the Analyze (structure) axis became the Security axis, and 4 authors
> joined the Build axis.** The two changes are a pair:
>
> - The 4 `*-analyzer` agents (PHP, JS, Twig, API Platform) now diagnose **security vulnerabilities**
>   instead of structural health. The rationale was a gap section 3.6 had recorded itself —
>   *"this repository has no dedicated security-audit agent"*. The security criteria
>   (`08-security-rule.md` and others) were already in place; **only an executor to check code against
>   them was missing.** Detail in section 3.2.
> - The same revision **filled in the 4 empty `*-author` stubs.** They were 11-line stubs whose
>   `description` had been copied from the analyzer, leaving the harness no basis to route a
>   generation intent to them — **the same defect pattern** as when Debug and Test joined on
>   2026-08-17. This gives the "refactoring design" handoff, orphaned by the disappearance of the
>   structure axis, somewhere to converge.
> - **`api-platform-author` was revived**, partially reversing the 2026-08-17 merge decision — though
>   the commands remain the SoT for the authoring conventions (section 5.1, revision 3).

### API Platform Sub-inventory — moved

The per-agent detail for the 5 `api-platform-*` agents (model, tools, output, and the axis-by-axis
history) **moved to `api-agent-team-docs.md` on 2026-08-28**, together with the orchestrator that
directs them. The matrix row above is the complete record kept here.

@see .claude/docs/api-agent-team-docs.md — `## API Platform Sub-inventory (5 axes)`

### Model and Tool Distribution (re-verified)

**Important:** all 30 specialist agents **specify `model:` explicitly; none inherits the default** (the
"inherits" claim in a previous revision was an error). The models split between two values, `opus` and
`sonnet`. `[Verified]`

> ⚠️ **Corrected 2026-08-28 — the previous revision of this section was wrong on both counts and on
> the convention it inferred.** It claimed "opus — 21 / sonnet — 9", that the 5 API Platform agents
> were "all opus, symmetric", and that the Diagram team was "the only pair with asymmetric models".
> Re-measured against the tree, **all ten `*-reviewer` agents are `sonnet`**, which falsifies each of
> those three claims. The figures below are the measurement, not the design intent.

- **`opus` — 19 files = 17 specialists + 2 orchestrators.** Every **author, analyzer, debugger and
  tester** in the four code domains (3 app + API Platform = 16), plus `utility-drawio-diagram-author`,
  plus `app-agent-team` and `api-agent-team`.
- **`sonnet` — 13 specialists.** **All ten `*-reviewer` agents** — the 3 app-domain reviewers,
  `api-platform-reviewer`, and the 6 infrastructure reviewers (Postgresql · Redis · RabbitMQ · Nginx ·
  GCP · AWS) — plus `utility-git-commit-author`, `utility-git-commit-reviewer` and
  `utility-drawio-diagram-reviewer`.

`[Verified]` 2026-08-28
[Bash: `grep -l '^model: opus' .claude/agents/*.md | wc -l` → 19 · `grep -l '^model: sonnet' … | wc -l` → 13 · total 32]

**The real convention is a role axis, not a domain-criticality axis.** The split falls almost exactly
on **generate-or-diagnose vs. judge**:

| Model | Roles | Rationale `[Inferred]` |
| --- | --- | --- |
| `opus` | author · analyzer · debugger · tester · orchestrator | open-ended work — designing code, tracing a cause, reasoning about an exploitation path, planning a fan-out |
| `sonnet` | **every** reviewer | a bounded verdict against a written rule (SoT): enumerate the checklist, cite `file:line`, label MUST/SHOULD/CONSIDER |

Two consequences worth stating plainly, because the earlier revision asserted the opposite:

- **Every code domain's Build pair is asymmetric** (author = opus → reviewer = sonnet), not just the
  Diagram team. Asymmetry is the norm here, not the exception.
- **API Platform is *not* symmetric across its five axes** — four are opus and `api-platform-reviewer`
  is sonnet, exactly like the three app domains. The domain remains structurally symmetric with the
  app domains; it is the *model* claim that was wrong.

The `utility-git-commit-*` pair is the one place the role axis does not hold: its **author is sonnet**
too, because drafting a Conventional Commits subject from a diff is itself a bounded task.

Tools (`tools`) are a **separate axis** from the model: **since 2026-08-15 every agent specifies a
narrow tool set and none inherits the full set.** The role sets the axis — reviewers and analyzers,
which only judge, are read-only with `Read, Grep, Glob, Bash` plus `disallowedTools: Edit, Write`,
while debuggers (which apply minimal fixes), testers (which write tests) and the author family add
`Edit`/`Write`. `[Verified]`
[Read: .claude/agents/app-php-symfony-reviewer.md] [Read: .claude/agents/app-php-symfony-tester.md]

---

## 3. Team Definitions (by workflow role)

Each team is defined in ADR style (Context / Decision / Consequences). The organising axis is the
**workflow role**, and domain agents are reused across several teams.

### 3.1 Review Team

#### Context

Checks a changed file's quality against the domain criteria (SoT) and flags findings at MUST/SHOULD/
CONSIDER severity. Ten standalone reviewers exist today, but the routing rules for which reviewer to
call when were undocumented.

#### Decision

- **Members:** `app-php-symfony-reviewer`, `app-javascript-stimulus-reviewer`,
  `app-twig-symfony-reviewer`, `database-postgresql-reviewer`, `cache-redis-reviewer`,
  `message-rabbitmq-reviewer`, `server-nginx-reviewer`, `tools-gcp-cloudrun-reviewer`,
  `tools-aws-ecs-reviewer`, `api-platform-reviewer`.
  (Agents are written with their frontmatter `name` verbatim — no abbreviations or display names, for
  the same reason as skills.)
- **Trigger:** after a code change. Determined by which rule's `paths` glob the changed file path
  matches — it does not depend on a separate global convention document.
- **Routing basis:** match the changed file path against the rules' `paths` globs to select the
  reviewer. The rule paths in the table below reflect the current rule tree. `[Verified]`

| Changed path pattern | Responsible reviewer | Governing rule (paths) |
| --- | --- | --- |
| `app/src/**/*.php` | `app-php-symfony-reviewer` | `app-php-symfony-00~15-*-rule.md` |
| `app/src/{Entity,Repository}/**/*.php` | `database-postgresql-reviewer` | `database-postgresql-rule.md` |
| `app/assets/**/*.js` | `app-javascript-stimulus-reviewer` | `app-javascript-stimulus-00~03-*-rule.md` |
| `app/templates/**/*.twig` | `app-twig-symfony-reviewer` | `app-twig-symfony-00-overview-rule.md` |
| `app/src/{ApiResource,State}/**/*.php` | `api-platform-reviewer` | `api-platform-rule.md` |
| `app/src/**/API/**/*.php` (provider integration) | (no agent — the per-provider `*-build-skill`) | `api/providers/finance/**/api-*-rule.md` |
| `app/config/packages/cache.yaml`, `app/src/**/*.php` | `cache-redis-reviewer` | `cache-redis-rule.md` |
| `app/src/Message*/**/*.php`, `app/config/packages/messenger.yaml` | `message-rabbitmq-reviewer` | `message-rabbitmq-rule.md` |
| `scripts/**/nginx/**` | `server-nginx-reviewer` | `server-nginx-rule.md` |
| `scripts/containers/prod/**`, `**/*.tf`, `**/cloudbuild.yaml`, `**/Dockerfile` | `tools-gcp-cloudrun-reviewer` | `tools-gcp-cloudrun-rule.md` |
| `scripts/containers/prod/**`, `**/*.tf`, `**/taskdef*.json`, `**/buildspec.yml`, `**/Dockerfile` | `tools-aws-ecs-reviewer` | `tools-aws-ecs-rule.md` |
| `scripts/**/*.sh`, `scripts/**/entrypoint.sh` | (no agent — the `/utility-shell-script-review` command) | `utility-shell-script-rule.md` |

- **I/O:** input = changed file paths + the rules (SoT). Output = a severity-classified report (only
  `[MUST]` blocks a merge).
  `[Verified]` [Read: .claude/agents/app-php-symfony-reviewer.md] — "only `[MUST]` blocks a merge".

#### Consequences

- (+) Per-domain verdicts always track the current rules (SoT), because reviewers hold no criteria of
  their own.
- (−) One file can match several reviewers. In particular **the Redis rule's paths are as broad as
  `app/src/**/*.php`**, so effectively every PHP change matches PHP, Redis and (for an Entity)
  Postgresql simultaneously. The orchestrator must manage a **duplicate-finding merge rule**. See
  section 6, items #5 and #8.

### 3.2 Security Team (2026-08-22 — repurposed from the Analyze team)

#### Context

Reads code to identify **security vulnerabilities** and propose fixes. Where the Review team asks
"does the code follow the rules" (a standalone verdict) and the Debug team asks "why doesn't it work"
(runtime cause), the Security team asks **"is it exploitable"** (authentication and authorization
defects, injection, sensitive data exposure, vulnerable dependencies).

This team is a **role change, in the same files, of the Analyze (structural health) team** created on
2026-08-01. The rationale was a gap section 3.6 had recorded itself — *"this repository has no
dedicated security-audit agent — the pre-deploy security verdict is split across the three domain
reviewers above, each covering the `## Security` section of its own rule (SoT)."* The security
criteria were already in place, `app-php-symfony-08-security-rule.md` (192 lines) among them, and
**only an executor to check code against them was missing.** A reviewer moonlighting sees only the
diff, so it never amounts to an audit sweeping the whole existing codebase.

**The structure axis was moved, not abolished** — refactoring design and implementation go to the
`*-author` agents filled in by the same revision, and rule-compliance verdicts go to `*-reviewer`.

#### Decision

- **Members:** `app-php-symfony-analyzer` (missing authorization, SQL injection, validation bypass,
  sensitive data logging, JWT/session defects, rate limiting, vulnerable dependencies),
  `app-javascript-stimulus-analyzer` (DOM XSS, `eval`, credentials in web storage, unverified message
  origin, SSE trust boundary), `app-twig-symfony-analyzer` (`|raw` XSS, context escaping mismatch,
  missing CSRF token, mistaking `is_granted` for server authorization), `api-platform-analyzer`
  (missing operation authorization, BOLA, security timing confusion, sensitive fields exposed in a
  read group, mass assignment). All are `opus`,
  `tools: Read, Grep, Glob, Bash` + `disallowedTools: Edit, Write`.
- **Trigger:** a natural-language request ("security check", "find vulnerabilities", "authorization
  audit", "injection risk"), or the pre-deploy gate.
- **Working principles (common to all four):**
  1. **Read-only** — `memory: project` auto-grants `Write` and `Edit`, but the
     `disallowedTools: Edit, Write` all four declare reverses that per tool. **This is physical
     enforcement, not a norm** (see Consequences below). Fixes go to `*-author`.
  2. Classify by severity as **Critical / High / Medium / Low**.
  3. Fill all three of **location (`file:line`), description and recommended fix** for every finding.
  4. **Reference CVE and OWASP** — but quote a CVE number only when `composer audit` or `npm audit`
     actually printed it, and **never invent one.** OWASP Top 10 2021, API Security Top 10 2023 and
     CWE are used for classification.
- **Severity ↔ repository convention mapping:** Critical·High = `[MUST]` (blocks a merge),
  Medium = `[SHOULD]`, Low = `[CONSIDER]`. A rule violation on its own does not earn a High — **you
  must be able to describe the exploitation path** to rate anything High or above.
- **Output:** diagnosis scope → summary table (count per severity) → findings → needs verification →
  **unchecked items**. With zero findings, report "no vulnerabilities confirmed" together with the
  **list of perspectives checked** — unchecked and clean are different things.
- **Role boundaries (handoff):** `Security (diagnose) → Build/author (implement the fix) → Review
  (quality gate) → Test (regression prevention)`. On discovering a runtime failure, `Security → Debug`.

#### Consequences

- (+) The repository gains its first **dedicated security-audit axis** — the gap section 3.6 recorded
  closes, and the pre-deploy gate no longer depends solely on three infrastructure reviewers
  moonlighting.
- (+) The severity scheme maps onto `[MUST]/[SHOULD]/[CONSIDER]`, connecting to the existing
  merge-blocking convention.
- (−) **The structural-analysis axis disappears.** No agent is dedicated to diagnosing questions like
  "are the layer boundaries healthy?" or "is there a circular dependency?", and refactoring design is
  performed by `*-author` as part of generation. Diagnosing structural debt on its own now depends on
  `[CONSIDER]` findings from `*-reviewer`.
- (+) **Read-only is enforcement, not a norm.** It is true that declaring `memory: project` makes the
  harness grant `Write` and `Edit` regardless of the `tools` list, but **`disallowedTools` reverses
  that per tool.** The 4 `*-analyzer` agents declared `disallowedTools: Edit, Write` on 2026-08-23,
  which blocks writing physically while retaining the always-on context of `memory: project`.
  `[Verified]` — the 10 reviewers that declare `disallowedTools: Edit, Write` are exposed in the
  agent-type listing without those tools, while the 2 `utility-*-reviewer` agents that declare only
  `disallowedTools: Edit` retain `Write`. **Before this revision this item claimed the tools "cannot
  be removed even with `disallowedTools`", which was false** — `agent-memory/utility-git-commit-reviewer/MEMORY.md:45`
  in the same repository already recorded the opposite.
- (−) The infrastructure domains (nginx/gcp/aws/redis) have no dedicated Security agent — only the 3
  app agents and 1 API Platform agent exist. Security verdicts for those domains are still handled by
  the domain reviewer moonlighting (section 3.6, Deploy).
- (!) **With `app/vendor` absent, `composer audit` and `importmap:audit` cannot run, so dependency CVE
  checking is impossible.** All four state this gap in their body and memory, and report "unchecked"
  rather than estimating a CVE.

### 3.3 Debug Team

#### Context

Traces a bug's **root cause**. Where the Review team asks "does the code follow the rules", the Debug
team asks "why doesn't it work" — the two have different purposes.

#### Decision

- **Members:** `app-php-symfony-debugger` (handler not running, N+1 and detached entities, migration
  mismatch, transport routing, locking and idempotency, DI miswiring),
  `app-javascript-stimulus-debugger` (controller not registered, target mismatch, Turbo update
  failure, memory leak, importmap resolution failure), `app-twig-symfony-debugger` (undefined
  variable, double or missing escaping, block not inherited, include/macro path error, form theme not
  applied), **`api-platform-debugger`** (property not exposed due to a serialization group ↔ context
  mismatch, 404 from an undeclared operation, validation returning 500 instead of 422, confusion
  between `security:` and `securityPostDenormalize:`, State not wired or not delegating, filter
  ignored). `[Verified]`
- **Trigger:** on a bug reproduction or symptom report. Natural-language requests ("why isn't this
  working", "the handler isn't running", etc.).
- **Boundary against the Build, Security and Review teams (handoff):** `Debug (cause and fix) → Review
  (quality) → (if needed) Test (regression prevention)`. When a structural defect is the cause, pass
  it to `Debug → Build/author` to implement the refactor; when the cause is a security vulnerability,
  pass it to `Debug → Security` to diagnose severity and the exploitation path (revised 2026-08-22 —
  previously the structure axis, `Analyze`, held this slot).

#### Consequences

- (+) Separating diagnosis from quality verdicts sharpens each agent's prompt focus.
- (−) The infrastructure and integration domains (nginx/gcp/aws/redis/provider) have no dedicated
  Debug agent — those bugs are handled by the domain reviewer moonlighting or diagnosed procedurally
  via the provider test skill. See section 6.
  **API Platform left this gap on 2026-08-17 when `api-platform-debugger` joined.**

### 3.4 Test Team

#### Context

Writes tests that prevent regressions in changed code. The testing rules (SoT) must be followed.

#### Decision

- **Members:** `app-php-symfony-tester` (PHPUnit Unit/Integration/Functional),
  `app-javascript-stimulus-tester` and `app-twig-symfony-tester` (Symfony Functional / WebTestCase,
  `lint:twig`), and **`api-platform-tester`**
  (an operation × case matrix based on `ApiPlatform\Symfony\Bundle\Test\ApiTestCase`). `[Verified]`
- **Mandatory requirements** (`app-php-symfony-09-testing-rule.md`, SoT):
  - Unit tests must not touch the filesystem, DB, cache or network.
  - Integration tests use **real PostgreSQL and Redis instances** — mocking the DB or Redis is forbidden.
  - Functional tests verify HTTP responses, redirects and rendered HTML; verifying internal service
    state directly is forbidden.
  `[Verified]` [Read: .claude/rules/app-php-symfony-09-testing-rule.md]
- **Working method — TDD Red-Green-Refactor (adopted 2026-08-17):** the 4 Test team members treat
  tests as **a procedure that drives the implementation**, not an after-the-fact artifact. One cycle =
  one logical fact, and RED only counts once you have **run it and confirmed the failure** (a failure
  caused by a gap or an environment problem is not RED). GREEN means the minimum implementation only;
  REFACTOR happens with the suite green and without changing behaviour.
  - **Who writes the production code in GREEN differs by domain** — for API Platform the Build axis is
    a skill, so it delegates to `api-platform-rest-build-skill` (the tester implements directly, with
    a note to use the reviewer gate, only on a standalone TDD request); for PHP, Twig and JS there was
    no author agent, so the tester implements the minimum itself (referring structural design back to
    `*-analyzer` and runtime causes to `*-debugger`).
  - This cycle is **a procedure owned by the agent body** and is not duplicated into
    `09-testing-rule.md` (which owns layers, templates and mocking boundaries) — preserving the split
    where rules hold criteria and agents hold procedure.
- **Trigger:** after writing a new class, when regression prevention is requested following a Debug
  team fix, or when implementing new behaviour via TDD.

#### Consequences

- (+) The test-layer boundary (Unit/Integration/Functional) is enforced by a rule (`09-testing-rule.md`).
- (−) Infrastructure configuration (nginx/gcp/aws/shell) has no corresponding test writer — that layer
  depends on procedural tests (the provider `*-test` commands) or manual verification. API Platform
  briefly ran a dual system of **command (canonical procedure) + agent (file authoring)** right after
  `api-platform-tester` joined on 2026-08-17, but the same day the `/api-platform-test` command was
  retired and **the canonical procedure was unified into the agent body (`## Test Procedure`)** — the
  same shape as the 3 app-domain testers (procedure and author in one place).

### 3.5 Build Team (new)

#### Context

**Generates** API, provider and configuration code and immediately **verifies** it with a dedicated
reviewer. A role that did not exist at the time of the draft, it now accounts for the majority of the
repository's orchestration.

The rationale for attaching a dedicated reviewer immediately after generation is that each domain has
anti-patterns a rule (SoT) must block but a generator will happily produce — and the generator is the
worst-placed reader of its own output. The API Platform domain has the sharpest examples of this
(exposing an Entity directly, hand-implementing filters, hand-assembling custom errors); they are
catalogued in `api-agent-team-docs.md` rather than restated here.

#### Decision

- **Members (author→reviewer pairs):** the 3 app-domain agents (`app-php-symfony-author`,
  `app-javascript-stimulus-author`, `app-twig-symfony-author`) and 1 API Platform agent
  (`api-platform-author`). Each pairs with its matching `*-reviewer`. **Joined 2026-08-22** — until
  then all four were 11-line empty stubs whose `description` had been copied from the analyzer.
- **The app-domain authors' self-gates reuse the existing `PostToolUse` hooks via the CLI.** Unlike the
  Commit and Diagram draft guards, `php-lint.sh`, `php-cs-fixer.sh`, `twig-lint.sh` and `js-guard.sh`
  **take no `$1` argument and read only stdin JSON.** The author therefore feeds them the payload
  directly rather than modifying the hook files:
  ```bash
  echo '{"tool_input":{"file_path":"app/assets/controllers/x_controller.js"}}' \
    | .claude/hooks/post-tool-use/js-guard.sh
  ```
  Because there is a single implementation, the hook and the author's verdict cannot diverge (the same
  effect as the Commit and Diagram dual entry points).
- **exit 0 does not mean "passed" — this team's biggest trap.** All four hooks are built for
  `PostToolUse` and are therefore **non-blocking**: with the precondition missing they **skip silently**
  via `[ -d app/vendor ] || exit 0`
  `[Verified]` [Read: .claude/hooks/post-tool-use/twig-lint.sh:39]. All four authors must check the
  precondition first and **explicitly mark any gate that did not run as "unchecked" in the handoff.**
  **`app/vendor` is currently absent, so the PHP, Twig and API Platform gates are mostly inert and the
  only ones that actually work are `php -l` and `js-guard.sh`** (for JS, the decision not to take on a
  new linter makes the grep guard the only and complete verdict layer).
- **The output is a direct source edit, not a draft file** — the point of divergence from the Commit
  and Diagram authors. Those two teams place drafts under `.claude/tmp/` because their final action
  (`git commit -F`, `set_page`) is destructive, whereas code generation was already established by the
  5 build skills editing `app/src/` directly, and `permissions.allow` in `settings.json` pre-authorizes
  `Edit(app/src/**/*)` and friends. **The verification medium is `git diff` (uncommitted changes)**,
  and the retry limit is 3 because these are code domains.
- **API Platform routing and canonical ownership** moved to `api-agent-team-docs.md` on 2026-08-28,
  along with the orchestrator that performs it.
  @see .claude/docs/api-agent-team-docs.md — `## Build Team (API Platform)`
- **Orchestrator:** each domain's orchestrator skill (its `*-build-skill` and so on) calls the author
  to produce a draft and the reviewer to return PASS/REDO (section 4, verification loops). `[Verified]`
- **Exception ① (agentless variant — meta and configuration):** since 2026-08-08, Claude Code
  configuration artifacts have **the slash command `/utility-claude-code-review` hold the criteria**
  instead of author and reviewer agents, and the `utility-claude-code-skill` skill drafts, self-verifies
  against those criteria, and records the result (the max-2-retry convention is unchanged). `[Verified]`
  [Read: .claude/commands/utility-claude-code-review.md]
- **Exception ② (agentless variant — providers):** UPbit REST/WebSocket and KoreaInvestment
  OAuth2/REST/WebSocket have worked the same way since 2026-08-15 — the **`*-build` commands under
  `commands/api/providers/**` hold the authoring conventions, verification checklist and known gaps**,
  and the 5 matching `*-build-skill` skills run a generate → self-verify loop (max 3 retries; the
  PHPStan gate is unchanged). `[Verified]`
  [Read: .claude/commands/api/providers/finance/digitalasset/upbit/api-rest-build.md]
- **Exception ③ (agentless variant — shell scripts):** `scripts/**` Bash scripts have worked the same
  way since 2026-08-16 — **the slash command `/utility-shell-script-review` holds both the authoring
  conventions (mode B) and the criteria**, and the `utility-shell-script-skill` skill drafts,
  self-verifies against them, and records the result (max 2 retries). `[Verified]`
  [Read: .claude/commands/utility-shell-script-review.md]
- **Model:** follows the **role axis** re-measured in section 2 — every `*-author` is `opus` and every
  `*-reviewer` is `sonnet`, so **each Build pair is asymmetric by design**. Every author-family tool
  set is narrowly specified (Bash, Read, Write, Edit, Grep, Glob). `[Verified]` 2026-08-28

#### Consequences

- (+) Generation and verification are closed inside a single skill, making retry and artifact
  management consistent.
- (−) Each domain must maintain three artifacts (author, reviewer, skill), so the file count grows quickly.
- (+) The command variant, which gathers the criteria into one file, reduces the artifact count (3 → 2)
  and the drift, but because verification runs in the main session context it **loses the isolation of
  an independent subagent** — it is adopted only for meta and configuration domains where the criteria
  converge on a single document.
- (−) When one change spans State domain logic, a Doctrine Entity and security, it can match
  cross-domain reviewers redundantly (see the boundary table below) — the orchestrator delegates and merges.

#### API Platform Cross-domain Boundaries — moved

The boundary table naming what `api-agent-team` delegates back to the app domains moved to
`api-agent-team-docs.md` on 2026-08-28. The two halves this document keeps are the **domain logic a
State delegates to** (`app/src/Service/**`, `app/src/Repository/**` → `app-php-symfony-*`) and the
**Symfony security configuration** behind a resource (`app-php-symfony-08-security-rule.md` is SoT for
firewalls, Voters, `stateless` tokens and the rate limiter).

Since 2026-08-29 both halves are **delegated in** rather than spawned by the sibling: `api-agent-team`
no longer reaches `app-php-symfony-*` or `database-postgresql-reviewer` directly, so it spawns
`app-agent-team` (Mode D) with the file list and merges what comes back. The routing *within* this
document is unchanged — only the caller is.

@see .claude/docs/api-agent-team-docs.md — `## Cross-domain Boundaries`

### 3.6 Commit · Diagram · Deploy Teams

#### Context

Commits changes, updates diagram assets, and deploys. Commit holds the **finished orchestration
standard** (utility-git-commit-skill), Diagram is the second team to apply that standard, and the
Deploy gate is first defined by this draft.

#### Decision

- **Commit sub-team (implemented · reference standard):** the `utility-git-commit-skill` skill acts as
  orchestrator, calling `utility-git-commit-author` → `utility-git-commit-reviewer` in sequence, then
  `git commit -F` on PASS or up to 2 retries on REDO. `[Verified]`
  [Read: .claude/skills/utility-git-commit-skill/SKILL.md]
- **Diagram sub-team (created 2026-08-19):** the `utility-drawio-diagram-skill` skill calls
  `utility-drawio-diagram-author` → `utility-drawio-diagram-reviewer` in sequence, then on PASS applies
  the result to `diagram/**` via `mcp__drawio-tool__set_page` (an existing page) or `Write` (a new
  file), with up to 2 retries on REDO. The SoT for the criteria is
  `rules/utility-drawio-diagram-rule.md`, which both agents reference via `@see` without restating.
  - **Asymmetric models (author = opus, reviewer = sonnet)** — the only asymmetric pair in this repository.
  - **Applying can be destructive** — `set_page` replaces the target page wholesale, so any cell
    missing from the draft is deleted. The defence is threefold: the guard mechanically checks for
    omissions against the sidecar `baselineCellIds`, the reviewer cross-checks that baseline itself
    against `get_page`, and the skill re-confirms with `get_page` after applying.
- **Deploy sub-team (proposed):** **reuses** the domain reviewers as a pre-deploy security and
  configuration gate.
  - `server-nginx-reviewer` → server configuration (security headers, TTLs, FastCGI).
  - `tools-gcp-cloudrun-reviewer` / `tools-aws-ecs-reviewer` → runtime, secrets, least-privilege IAM.
  - The `/utility-shell-script-review` command → deploy script safety (`rm -rf` guards, etc.).
  - **Security verdicts on application code belong to the Security team created on 2026-08-22**
    (the 4 `*-analyzer` agents, section 3.2) — the arrangement for deployment assets (nginx, Cloud
    Run, ECS, shell) is unchanged, with the 3 domain reviewers and the command each covering the
    `## Security` section of their own rule. That is, **the infrastructure layer still has no
    dedicated security agent.** "User approval before a destructive operation" is enforced by the
    approval gates in `tools-gcp-cloudrun-skill` and `tools-aws-ecs-skill`.

#### Consequences

- (+) The Commit flow reuses an already-proven pattern (no rework needed).
- (+) The Deploy gate was created on 2026-07-23 as the `tools-app-deploy-skill` skill — after the
  domain reviewer fan-out, the actual deployment hands off to `tools-gcp-cloudrun-skill` or
  `tools-aws-ecs-skill` (section 7).
- (!) `git push` is set to `ask` in `settings.json`, so it always goes through user confirmation.
  `[Verified]` [Read: .claude/settings.json:95]

---

## 4. Orchestration Reference Patterns

Generalises `utility-git-commit-skill` into a **reusable team orchestration template**. Since the
draft this pattern has already spread to numerous build and orchestrator skills and become the de facto
repository standard. `[Verified]`

### Verification Loop Template ① — the author→reviewer pattern (agent pair)

```text
skill (orchestrator)
  ├─ 1. Precondition check (e.g. git diff --cached --quiet)
  ├─ 2. Call the author agent   → ./.claude/tmp/utility/<domain>/<task>-draft.*  (+ a meta sidecar if needed)
  │      └─ 2a. Self-gate — the author runs the guard script itself and fixes until 0 [MUST] remain
  ├─ 3. Call the reviewer agent → runs the same guard (deterministic evidence) + model-only judgment
  │                              → ./.claude/tmp/utility/<domain>/<task>-review.md (PASS/REDO)
  ├─ 4. Branch on the verdict
  │      PASS → perform the final action
  │      REDO → include the review instructions in a re-invocation of the author, repeat from step 2
  └─ 5. Past the retry limit (max 2) → stop automatic execution + recommend manual review
```

**Deterministic gates (designed 2026-08-22)** ⚠️ *planned — not built* — the intent is that the Commit
and Diagram teams split their verdict into two layers. Everything mechanically decidable (format,
length, XML structure, id uniqueness, referential integrity, palette, missing cells) would be handled
**entirely by a hook script**, leaving the agent to judge only the layer the script cannot see (factual
agreement with the diff, type suitability, intent reflection, the authenticity of the sidecar
`baselineCellIds`).

| Team | Guard script | Model-only judgment |
| --- | --- | --- |
| Commit | `.claude/hooks/post-tool-use/utility-git-commit-draft.sh` | factual agreement with the diff · type suitability · scope selection · the *why* in the body |
| Diagram | `.claude/hooks/post-tool-use/utility-drawio-diagram-draft.sh` | `baselineCellIds` authenticity · intent reflection · shape and label semantics · convention inheritance |

> `[Verified]` 2026-08-31: **both guard scripts now exist and are registered.**
> `.claude/hooks/post-tool-use/` contains six files, and `settings.json` registers all six under
> `PostToolUse` — the four `app-*` gates plus these two `utility-*-draft.sh` guards. Each filters to its
> own draft path (`.claude/tmp/utility/git/commit-message-draft.md`,
> `.claude/tmp/utility/drawio/diagram-draft.xml`), so they are order-independent and need no `if` filter.
> This section therefore describes the **current** two-layer split, and an agent may invoke either
> script directly by its CLI entry point.
>
> Note the rename against the earlier plan: the files landed as `utility-git-commit-draft.sh` and
> `utility-drawio-diagram-draft.sh`, not `commit-draft-guard.sh` / `drawio-draft-guard.sh`, so that they
> carry the same `<domain>-<name>` prefix as the agents and skills they pair with. This paragraph
> supersedes a note that stood from 2026-08-25 to 2026-08-31 asserting neither script existed; it was
> correct when written and became stale when the scripts were added.

- Both scripts are **dual entry points, hook + CLI** — registered under `PostToolUse` in
  `settings.json` while the author and reviewer call the same file from the CLI. Because there is a
  single implementation, the hook and the review verdict cannot diverge, and the loop does not depend
  on whether the hook fired.
- A guard is **only a projection of the rule (SoT) and never introduces criteria of its own.** When a
  rule changes, the guard is fixed in the same change.
- **The reviewer is not replaced by this gate** — the guard merely trusts the sidecar meta, so if the
  baseline is empty or truncated the missing-cell check is silently defeated. Cross-checking that
  baseline against `get_page` from an independent context is the rationale for keeping the Diagram
  reviewer.

**Template ② applied — the API Platform Build loop** moved to `api-agent-team-docs.md` on 2026-08-28.
@see .claude/docs/api-agent-team-docs.md — `## The API Platform Build Loop (template ② applied)`

- Secret values (tokens, credentials) are never included in any artifact or output.
- Intermediate artifacts are exchanged as files under `./.claude/tmp/` (gitignored). `[Verified]`
  [Read: .claude/skills/utility-git-commit-skill/SKILL.md]
- This pattern is portable to **any team with a "write → verify → judge" structure**, such as the
  Deploy gate or large-scale review consolidation. After API Platform switched to template ② on
  2026-08-17 it was **Commit (Git) alone** for a while, but the Diagram team's creation on 2026-08-19
  means **two teams — Commit (Git) and Diagram (draw.io)** — now keep this shape with an **agent
  pair**. `[Verified]`

### Verification Loop Template ② — command-based self-verification (no agent pair)

A domain whose criteria converge on a single file (a slash command) keeps no author or reviewer agent
and instead **generates and self-verifies within the same session**. Beginning with the Claude Code
config on 2026-08-08 and extending to the 5 providers on 2026-08-15, **this has become the majority
shape by artifact count**. `[Verified]`

```text
skill (orchestrator)
  ├─ 1. Precondition check (if the target is unclear, ask once and stop)
  ├─ 2. Generate     — edit (or draft) per the command's `## Authoring Conventions`
  ├─ 3. Self-verify  — cross-check per the same command's `## Verification Checklist` → ./.claude/tmp/<task>-review.md
  ├─ 4. Branch       PASS → final action / REDO → apply only the instructions and repeat from step 2
  └─ 5. Past the retry limit → stop + recommend manual review
```

| Aspect | ① agent pair | ② command self-verification |
| --- | --- | --- |
| Artifact count | 3 (author, reviewer, skill) | 2 (command, skill) |
| Where the criteria live | the reviewer body (authoring conventions scattered into the author) | one place, the command body |
| Verification isolation | an independent subagent context | the main session context (no isolation) |
| Retry limit | 2 (config) · 3 (code) | same |
| Adopted by | Commit (Git), Diagram (draw.io) | Claude Code config, the 5 providers, Shell Script, API Platform |

**Selection criteria:** choose ② when the criteria converge on a single document and drift is the
principal risk; choose ① when the output is large and the verifier needs an **independent context**
(a perspective uncontaminated by the generation process). `[Inferred]`

### Alternative Comparison: orchestrator skill vs. direct routing by the main agent

| Approach | Advantages | Disadvantages | When to choose it |
| --- | --- | --- | --- |
| **Orchestrator skill** (the build/commit approach) | explicitly controls retries, artifact management and the verdict loop | requires creating and maintaining a skill file | teams needing multiple steps, retries and gates (Build, Commit, Deploy) |
| **Direct routing by the main agent** | no new file needed, works immediately via `paths` matching | retry and consolidated-report logic is improvised each time | a one-off single review (one Review, Security, Debug or Test) |

**Recommendation:** direct routing suffices for Review/Security/Debug/Test, and Build, Commit and
Deploy already have orchestrator skills (the Deploy gate was created on 2026-07-23, section 7). Note
that the Deploy gate is a **multi-reviewer fan-out** variant rather than an author→reviewer loop.
`[Inferred]` — the real operational load needs re-examination after adoption.

---

## 5. Trade-offs (adopting the workflow-role axis)

A three-axis analysis of the decision to organise teams by **workflow role** rather than by **domain**.

- **Scalability:** when a new technical domain is added (a new provider, say), the role teams
  (Review/Security/Debug/Test/Build) stay as they are and only the domain agents join the relevant
  team. Since the draft, the Twig, provider and config domains were added while the role axis stayed
  stable (only their domain agents joined), and the Analyze role added on 2026-08-01 took the role
  axis from 6 → 7. `[Verified]`
- **Maintainability:** each role gives its agent prompt a single focus, which keeps cognitive load low
  (a reviewer only judges, a debugger only finds causes, an author only generates). However, because a
  single domain agent belongs to several teams, **membership is 1:N** and the mapping table
  (section 2) needs maintaining.
- **Performance:** a role team calls only the agents it needs, avoiding unnecessary domain reviewer
  starts. The opposite risk is duplicate calls in the Review team when one file matches many rules
  (especially the broad Redis paths) — mitigated by the orchestrator's merge logic (section 6).

**Comparison with the domain axis:** a domain axis (where a "Backend team" handles review, debug and
test alike) has high domain cohesion, but mixing roles bloats the prompt and forces each domain to
define the roles redundantly. This repository already separates PHP, JS and Twig into 5 role agents
(author/analyzer/debugger/reviewer/tester), so **the role axis is more coherent with the existing
structure**. `[Verified]` 2026-08-28 — the **15** files in `agents/app-*` = 3 domains × 5 roles.

**The orchestrator layer is the one place the domain axis won.** The single `agent-team` created by the
2026-08-16 merge was split back into `app-agent-team` and `api-agent-team` on 2026-08-28 — a *domain*
partition sitting above a role-partitioned roster. Section 5.2 records why.

### 5.1 API Platform — moved

The API Platform domain's own trade-off analysis and its full revision history (Build consolidation →
four-axis expansion → Build command merge → author revival + Analyze→Security repurposing) **moved to
`api-agent-team-docs.md` on 2026-08-28**, together with the orchestrator and the sub-inventory.

@see .claude/docs/api-agent-team-docs.md — `## Trade-offs and Revision History`

### 5.2 Splitting the orchestrator into two (2026-08-28)

#### Context

Between 2026-08-16 and 2026-08-28 the repository had **one** orchestrator, `agent-team`, paired with
**one** design document. It carried the full 20-agent roster (15 `app-*` + 5 `api-platform-*`), the
infrastructure reviewers, the provider routes and the Deploy gate in a single prompt.

The user split it into `api-agent-team` and `app-agent-team`. The split was performed first as a
**file copy** — `[Verified]` 2026-08-28: the three resulting pairs (agent, memory, docs) were
byte-identical apart from the H1 and `name:` line. That intermediate state had a concrete defect worth
recording, because it is the failure mode any future "split an agent" change will hit:

- **Two agents with identical `description:` frontmatter are not separately routable.** Claude Code
  selects a sub-agent by matching its natural-language `description`, so both copies claimed the
  triggers `'app team'`, `'api team'` and `'API Platform team'` and the harness had no basis to prefer
  either. Splitting the *file* without splitting the *description* produces a coin flip, not a router.

#### Decision

Two orchestrators with **disjoint trigger vocabularies and one anchor each**:

| | `app-agent-team` | `api-agent-team` |
| --- | --- | --- |
| Anchor | the 15 `agents/app-*` agents | the 5 `agents/api-platform-*` agents — **exclusively** (revision 2026-08-29) |
| Path scope | everything under `app/`, `scripts/`, `diagram/` **except** the exposure layer | `app/src/ApiResource/**`, `app/src/State/**`, `api_platform.yaml` |
| Also owns | the pre-deploy gate · Commit · the provider routes, **all through skills** | — (hands these off) |
| Design SoT | this document (repository-wide umbrella) | `api-agent-team-docs.md` |

- **Shared domains go to `app-agent-team`.** As of **2026-08-29** `api-agent-team` keeps **no
  cross-boundary adjuncts at all** — its `Agent` target list is the 5 `api-platform-*` agents plus
  **this orchestrator**, which it spawns (at most once per invocation) for the entire non-exposure half
  and whose findings it merges into its own report. See `api-agent-team-docs.md` revision 5.
- **Later the same day, this orchestrator's roster closed too** (`app-*` only, by the same explicit
  instruction). The consequence is worth stating plainly, because it is the one place the two changes
  interact: **`app-php-symfony-*` is still reached through the delegation, but
  `database-postgresql-reviewer` is not reachable by either orchestrator any more.** A `stateOptions`
  Entity reuse therefore yields an exposure verdict, a domain-logic verdict, and a **referral** to
  `/database-postgresql-review` that a human closes out. See `## 5.3` below.
- **That delegation arrives here as Mode D (sub-delegation)** — an enumerated file list, no scope
  re-expansion, and **no splitting the exposure layer back to the caller**. Without that lock the two
  orchestrators bounce the same diff between them.
- **A mixed diff is split, not duplicated.** Each orchestrator takes its half and names the sibling in
  its `## Handoffs` section.
- **The operational contracts are deliberately duplicated** across both prompts (Preflight, the Spawn
  Prompt Contract, failure semantics, the report format, the safety boundaries). These are procedure,
  not criteria; each orchestrator runs standalone and cannot `@see` its way to them at spawn time. The
  **criteria** stay single-sourced in `rules/` and the `*-build` / `*-review` commands, so the
  repository's "criteria in one place" convention is intact.

#### Alternatives considered

- **One orchestrator with an internal domain switch** (the 2026-08-16 → 2026-08-28 status quo). Rejected:
  the routing table had grown to cover four unrelated concerns, and a user asking for an API review
  paid the context cost of the provider rows, the Deploy gate and the infrastructure fan-out.
- **A strict partition with no cross-boundary spawns at all.** Rejected: an API change that reuses a
  Doctrine Entity through `stateOptions` would need two separate orchestrator invocations to reach one
  verdict, and the duplicate-finding merge — the thing an orchestrator exists to do — could not happen.

  > ⚠️ **Superseded 2026-08-29.** This entry weighed only two options — keep the adjuncts, or partition
  > with no cross-boundary spawn — and the user's instruction that `api-agent-team` handle **only**
  > API Platform ruled out the first. The resolution is a **third option neither this ADR nor its
  > rejection considered: delegate to the sibling orchestrator.** `api-agent-team` spawns
  > `app-agent-team` for the whole non-exposure half and merges its returned findings, so the roster
  > closes to `api-platform-*` **and** the duplicate merge still happens in one invocation. The
  > objection recorded above therefore does not apply to what was actually adopted; it remains here as
  > the reasoning that was superseded, not as current guidance. Full rationale, costs and the recursion
  > guard: `api-agent-team-docs.md` revision 5.

#### Consequences

- (+) **Routing is decidable.** Disjoint trigger phrases mean the harness picks one deterministically.
- (+) **Each prompt is roughly half the size**, so more of the `maxTurns: 50` budget goes to spawns
  rather than to reading routes that will never fire.
- (+) The API Platform domain regains a **paired orchestrator + design document**, the shape it had
  before 2026-08-16 and the shape every other domain uses.
- (−) **The boundary is a new failure surface.** An exposure-layer file is still `.php` under
  `app/src/`, so `app-agent-team` can plausibly mis-route it to `app-php-symfony-reviewer`. Both
  prompts carry an explicit checklist item against exactly this.
- (−) **Two prompts to keep in step.** The duplicated operational contracts will drift unless changed
  together; the `## Per-invocation Checklist` in each is the most likely divergence point.
- (−) A mixed diff now produces **two consolidated reports** unless the user invokes only one
  orchestrator, which pushes the final merge onto the reader.

#### Three-axis trade-off

- **Scalability:** adding a sixth code domain now means choosing an anchor rather than extending one
  routing table — but a third orchestrator would triple the duplicated operational contract. The split
  scales to two well and is unlikely to scale gracefully past three.
- **Maintainability:** each prompt has a single focus and a single design SoT, which is the same
  argument that justified the role axis in section 5. The cost is the duplicated procedure noted above.
- **Performance:** fewer dead routes evaluated per invocation and a smaller prompt, at the price of a
  possible second invocation when a change genuinely spans both anchors.

### 5.3 Closing the `app-agent-team` roster to `app-*` (2026-08-29)

#### Context

The 2026-08-29 change in 5.2 closed `api-agent-team` to `api-platform-*`. Later the same day the user
applied the **same instruction to this orchestrator**: `app-agent-team` may use only
`agents/app-*-*.md`. Measured against the tree, its non-`app-*` spawn targets were the **six
infrastructure and data reviewers** — but only **three** were ever spawned directly
(`database-postgresql-reviewer`, `message-rabbitmq-reviewer`, `cache-redis-reviewer`, routing-table
rows for `Entity`/`Repository`, `Message*`, and the cache configs). The other three (nginx, Cloud Run,
ECS) already reached the tree only through `tools-app-deploy-skill`, so they needed no change.

The structural difference from 5.2 matters: **there is no third orchestrator to delegate to.** The
delegate-to-sibling escape that preserved the merge for `api-agent-team` has no analogue here.

#### Decision

**Refer, do not judge.** The three direct spawns become referrals: `app-agent-team` judges the `app-*`
half and names `/database-postgresql-review`, `/message-rabbitmq-review` or `/cache-redis-review` in
`## Handoffs`, stating that the layer was **not reviewed**.

Two alternatives were weighed and rejected:

- **Call the `/…-review` skills in-context.** Would preserve the single-invocation merge, but a skill
  loads into the orchestrator's *own* context, so it would be forming the domain verdict itself —
  contradicting the invariant stated in its own `## Role` ("you hold no judgment criteria or code
  standards of your own") and discarding subagent isolation. Rejected: the roster restriction is about
  *what this agent may judge*, and routing around it through a skill would honour the letter while
  breaking the intent.
- **A new data/infra fan-out gate skill**, mirroring `tools-app-deploy-skill`. Preserves both isolation
  and the merge, and remains the natural upgrade path. Rejected **for now** as a scope expansion: it
  requires a new artifact plus a new indirection layer, and the referral covers the need until the
  duplicate-merge loss is felt in practice.

#### Consequences

- (+) **Both rosters are now closed and symmetric** — each orchestrator spawns only its own prefix, so
  "which agents can this reach?" is a one-line answer in both prompts.
- (+) The invariant that an orchestrator **never forms a domain verdict itself** is preserved intact.
- (−) **The doctrine ↔ postgresql duplicate merge is gone.** It was the concrete benefit 5.2 fought to
  keep, and here it is deliberately surrendered: an `Entity` change yields a Doctrine verdict plus a
  referral, and the user runs the second pass. Recorded in section 6 as a live gap.
- (−) **`api-agent-team`'s Mode D delegation returns less than it used to.** It delegates the
  non-exposure half expecting the persistence layer to be judged; that half now comes back as a
  referral. Both orchestrator prompts, both memories and `database-postgresql-reviewer` itself were
  updated in the same change so the expectation is not silently disappointed.
- (−) **`database-postgresql-reviewer`, `cache-redis-reviewer` and `message-rabbitmq-reviewer` are now
  user-invoked only.** No orchestrator reaches them. Their prompts were rewritten to name the
  `/…-review` command as the primary upstream, so they no longer describe themselves as one branch of
  a fan-out whose findings someone else merges.

---

## 6. Current Gaps and Follow-up Work

The following are facts confirmed during exploration, recorded as a **diagnostic log** (this draft is a
design document, so they are not directly actionable here). Each item is recommended for separate
follow-up work.

| # | Finding | Basis | Status · recommendation |
| --- | --- | --- | --- |
| 1 | ~~`git-commit-reviewer`'s name is `Git Commit Reviewr` (typo)~~ | agents/utility-git-commit-reviewer.md | ✅ **Resolved** — the current name is `utility-git-commit-reviewer` and the file is `agents/utility-git-commit-reviewer.md` |
| 2 | ~~`paths` mismatch in the shared rule `api/rest-client-rule.md`~~ | — | ⛔ **Void** — that rule file no longer exists. The provider integration rules were split into `api/providers/finance/**/api-*-rule.md` |
| 3 | ~~No dedicated agents for the providers (UPbit/KoreaInvestment)~~ | commands/api/providers/finance/** | ✅ **Resolved, then reshaped** — 10 author and reviewer agents were created, then merged into 5 `*-build` commands on 2026-08-15. Generate-verify in the provider domain is handled by the build skills' self-verification loop |
| 4 | ~~No rules (SoT) for the shell and git domains~~ | the rules/ tree | ✅ **Resolved** — the shell rule (`utility-shell-script-rule.md`, `paths: scripts/**/*.sh`) and the git rule (`utility-git-commit-rule.md`) were created |
| 5 | `05-doctrine-rule.md` and `database-postgresql-rule.md` apply redundantly to the **same paths** (`Entity`, `Repository`) | both rules' frontmatter `[Verified]` | ⚠️ **Live** — the Review team needs a defined merge rule (eliminating duplicate findings) |
| 6 | ~~`server/nginx-rule.md` and `abstract-structure-rule.md` lack frontmatter~~ | rules/server-nginx-rule.md | ✅ **Resolved** — nginx has `paths: scripts/**/nginx/**`. structure is an index and deliberately has no frontmatter |
| 7 | ~~api/cache/database/server/utility in `docs/` are empty `.gitkeep` placeholders~~ | the docs/ tree `[Verified]` | ✅ **Resolved** — all filled in as per-domain `-docs.md` files in the flat single tier (`api-platform-docs.md`, `cache-redis-docs.md`, `database-postgresql-docs.md`, `server-nginx-docs.md`, `utility-shell-script-docs.md`, etc.). The last two to remain empty, `utility-claude-code-docs.md` (191 lines) and `utility-git-commit-docs.md` (93 lines), have also been written |
| 8 | `cache-redis-rule.md`'s `paths` is as **broad** as `app/src/**/*.php` → `cache-redis-reviewer` matches every PHP change | the rule's frontmatter `[Verified]` | ⚠️ **Live** — narrowing the Redis paths needs consideration (together with #5, for Review team merging and routing precision) |
| 9 | ~~API Platform is asymmetric with the providers at Author = sonnet / Reviewer = inherited~~ | agent frontmatter `[Verified]` | ⛔ **Void (error correction)** — measured, the API Platform Author and Reviewer are **both opus and symmetric**, and both providers are opus too. The model policy is consistent on the "domain criticality axis" (restated in section 2) |

---

## 7. Next Steps (for reference during implementation)

Review/Security/Debug/Test already work via direct routing, and Build/Commit via the existing skills.
The last remaining gap, the **Deploy gate**, was created on 2026-07-23. `[Verified]`

```text
.claude/skills/tools-app-deploy-skill/SKILL.md   ← Deploy gate orchestrator (created)
```

- `tools-app-deploy-skill` is not a single author→reviewer loop but a gate that **fans the changed
  deployment assets out to the domain reviewers (Nginx, GCP Cloud Run, AWS ECS) and the
  `/utility-shell-script-review` command**, consolidates the MUST/SHOULD/CONSIDER findings and returns
  a go/no-go (PASS/BLOCK). On PASS the actual deployment hands off to `tools-gcp-cloudrun-skill` or
  `tools-aws-ecs-skill`; the gate itself never performs a deployment or rollback.
- BLOCK (= 1 or more MUST) → fix and re-run, max 2 times. Intermediate artifacts live under
  `./.claude/tmp/` (gitignored).
- The remaining improvement work is section 6 items #5 (merging the duplicate doctrine ↔ postgresql
  rules) and #8 (narrowing the Redis paths).

---

## Appendix: Reference Assets

| Asset | Path | Role |
| --- | --- | --- |
| Orchestrator (app) | `.claude/agents/app-agent-team.md` | routing and handoffs for the 15 `app-*` agents, the 6 infrastructure reviewers, Deploy and Commit |
| Orchestrator (api) | `.claude/agents/api-agent-team.md` | routing and handoffs for the 5 `api-platform-*` agents (exposure layer) |
| API Platform design SoT | `.claude/docs/api-agent-team-docs.md` | sub-inventory · Build loop · revision history |
| Orchestration standard | `.claude/skills/utility-git-commit-skill/SKILL.md` | verification loop reference pattern |
| Deterministic gate | `.claude/hooks/post-tool-use/utility-git-commit-draft.sh` | the machine-verdict layer for Commit drafts (dual hook + CLI entry point) — registered under `PostToolUse`, `[Verified]` 2026-08-31 |
| Deterministic gate | `.claude/hooks/post-tool-use/utility-drawio-diagram-draft.sh` | the machine-verdict layer for Diagram drafts (dual hook + CLI entry point) — registered under `PostToolUse`, `[Verified]` 2026-08-31 |
| Hook wiring conventions | `.claude/hooks/README.md` | event mappings · exit code contract · list of active hooks |
| Agent body pattern | `.claude/agents/app-php-symfony-reviewer.md` | role · SoT references · quality gate structure |
| Rule index | `.claude/rules/abstract-structure-rule.md` | the index of domain rule SoTs |
| API Platform rule | `.claude/rules/api-platform-rule.md` | resource · State · security verdict SoT |
| API Platform procedure | `.claude/docs/api-platform-docs.md` | step-by-step guide to adding a resource |
| Output style | `.claude/output-styles/abstract-english-style.md` | ADR · trade-off · citation format |
| Team feature toggle | `.claude/settings.json:12` | `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` |
