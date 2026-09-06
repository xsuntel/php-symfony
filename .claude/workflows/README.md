# `.claude/workflows` — Workflow Playbooks (draft)

> Status: **Draft** — defines this directory's purpose and conventions, and documents the repository's
> actual workflows as playbooks that both people and Claude can reference. Written: 2026-07-24 ·
> Last updated: 2026-08-29 (section 0 corrected against the official dynamic-workflows documentation).
>
> ⚠️ **Scope warning:** the `.md` files here are reference documents; they never trigger or execute
> themselves. The **directory**, however, is an official Claude Code load target — see section 0, which
> was corrected on 2026-08-29.

@see .claude/docs/app-agent-team-docs.md — per-workflow-role team design (SoT, background and rationale)
@see .claude/docs/api-agent-team-docs.md — API Platform domain design (5-axis roster, Build loop)
@see .claude/rules/abstract-structure-rule.md — rule index
@see .claude/skills/utility-git-commit-skill/SKILL.md — orchestration reference standard

---

## 0. Important Fact — The Directory Is Official; These `.md` Files Are Not

> **Corrected 2026-08-29.** This section previously asserted that `.claude/workflows/` was "a custom
> placeholder directory created by this repository" and that "there is no file-based `workflow`
> artifact". Both statements are now false, and the correction matters because it changes who may write
> here. The rest of this document's premise — that a **markdown playbook** placed here does not
> auto-trigger — is unaffected and still holds.

`.claude/workflows/` **is an official Claude Code load target.** `[Verified]` 2026-08-29
[WebFetch: <https://code.claude.com/docs/en/workflows>]

- When a dynamic workflow run does what you wanted, `/workflows` → select the run → `s` **saves its
  script into `.claude/workflows/`** (or `~/.claude/workflows/` for the personal copy). The saved file
  is JavaScript: a `meta` block (`name`, `description`) followed by a body that orchestrates subagents
  via `agent()` and `pipeline()`.
- A saved script then runs as **`/<name>`** in later sessions, appearing in `/` autocomplete beside the
  bundled `/deep-research`. Project workflows load from every `.claude/workflows/` between the working
  directory and the repository root; when two define the same name, the one closest to the working
  directory wins, and a project workflow beats a personal one.
- Plugins distribute workflows the same way, from a `workflows/` directory at the plugin root.

**What still holds — a `.md` playbook here is inert.** The harness looks for workflow **scripts**; a
markdown file has no `paths` matching and no `description` trigger, so placing a document here does not
make it auto-apply the way a rule or skill does. When a real trigger is needed, build a skill
(`.claude/skills/`) or a subagent (`.claude/agents/`).

**What is genuinely not file-based** is the *authoring* step: Claude writes the orchestration script at
runtime for the task you describe. You do not hand-author a definition file here and expect it to be
picked up — you run a workflow, then save the script it produced.

> On that basis, this repository uses `.claude/workflows/` for **workflow playbooks (reference documents
> for people and Claude)**, which coexist with any saved workflow script — see the conventions in
> section 5.

---

## 1. The Two Official Meanings of "workflow" (reference)

### 1.1 Dynamic Workflows (runtime orchestration)

Claude takes a request, **writes a JavaScript orchestration script dynamically**, and a separate runtime
executes it in the background, distributing and verifying the work across many parallel subagents before
returning one result. `[Verified]` 2026-08-29 [WebFetch: <https://code.claude.com/docs/en/workflows>]
— this now has a dedicated official page; the earlier announcement blog post is kept in the References
table as background only.

- **Trigger:** ask in your own words ("use a workflow"), include the keyword `ultracode` in a prompt you
  type yourself, or set `/effort ultracode` to let Claude decide per task. `[Verified]`
- **Availability:** requires v2.1.154+; available on all paid plans, the Anthropic API, Bedrock, Google
  Cloud's Agent Platform, and Microsoft Foundry. On Pro it is enabled from the Dynamic workflows row in
  `/config`. `[Verified]`
- **Monitoring:** `/workflows` lists running and completed runs and opens a per-phase progress view;
  `s` saves the run's script as a command. `[Verified]`
- **Limits:** up to 16 concurrent agents and 1,000 agents per run; the script body is plain JavaScript
  with no module loading and no direct filesystem or shell access — the agents do that work.
  `[Verified]`
- **Sizing:** `workflowSizeGuideline` (`unrestricted` | `small` | `medium` | `large`, default `medium`)
  advises Claude how many agents to aim for; it is guidance, not a cap. `[Verified]`
- **Where the script lands:** in `~/.claude/projects/` per run, and in `.claude/workflows/` once saved
  (section 0). `[Verified]`
- **Turning it off:** `disableWorkflows: true` in settings, or `CLAUDE_CODE_DISABLE_WORKFLOWS=1`.
  `[Verified]`

### 1.2 Common Workflows (everyday development recipes)

The official docs' "Common workflows" covers **prompt recipes** for code exploration, bug fixing,
refactoring, testing, PRs and documentation, along with subagent delegation, parallel git worktree
sessions, plan mode, and scheduled execution (routines, `/loop`, GitHub Actions). `[Verified]`
[WebFetch: https://code.claude.com/docs/en/common-workflows]

---

## 2. This Repository's Workflows Are Already Built from Skills + Subagents

This repository realises "workflows" as three layers: an **orchestrator skill (entry point)** calls
**subagents (executors)**, which reference **rules (the verdict SoT)**. `docs/app-agent-team-docs.md` is
the SoT for the design background.

```text
skills/    = orchestrator / entry point — calls agents sequentially or fanned out, consolidates artifacts
agents/    = executor — loads rules, docs and the output style with Read and performs the work
rules/     = the single source of truth for verdicts (SoT) — auto-applied via paths globs
```

Three execution shapes are standard. `[Verified]` (`docs/app-agent-team-docs.md` sections 4 and 3.5)

| Shape | When | Example entry point |
| --- | --- | --- |
| **Orchestrator skill** (author→reviewer verification loop, max 2 retries) | multi-step work needing gates and retries | `utility-git-commit-skill`, `*-build-skill`, `utility-shell-script-skill`, `tools-app-deploy-skill` |
| **Orchestrator skill + command-based self-verification** (no agent pair) | meta, configuration and provider domains where the criteria converge on a single file | `utility-claude-code-skill` + `/utility-claude-code-review`, provider `*-build-skill` + the `*-build` command |
| **Direct routing** (pick the reviewer by the changed `paths`) | a single-shot review, debug or test | domain agents such as `app-php-symfony-reviewer` |

---

## 3. Workflow Playbooks

Below are the repository's six workflow roles summarised as **trigger → entry point → procedure →
output**. Section 3 of `docs/app-agent-team-docs.md` is the SoT for the detailed team definitions,
trade-offs and routing tables. `[Verified]`

> **Section-numbering convention:** 3.1–3.6 below correspond **one-to-one** with the team numbers in
> section 3 of the SoT (3.6 is a single Commit·Deploy team split into sub-teams, exactly as in the
> SoT). Use the same number when opening the SoT.

### 3.1 Review — quality verdict after a code change

- **Trigger:** after a code change. Determined by which rule's `paths` glob the changed file path matches.
- **Entry point:** pick the reviewer by the changed `paths` (direct routing). For example
  `app/src/**/*.php` → `app-php-symfony-reviewer`, `app/templates/**/*.twig` →
  `app-twig-symfony-reviewer`, `app/src/{Entity,Repository}/**` → `database-postgresql-reviewer`.
  The full routing table is in section 3.1 of the SoT.
  > **The six infrastructure reviewers split in two as of 2026-08-30.** `[Verified]` —
  > `tools-agent-team` (added that day) is anchored on the five prefixes `cache-*`, `database-*`,
  > `server-*`, `tools-aws-*` and `tools-gcp-*`, so it **direct-spawns five of the six**:
  > `cache-redis-reviewer`, `database-postgresql-reviewer`, `server-nginx-reviewer`,
  > `tools-gcp-cloudrun-reviewer` and `tools-aws-ecs-reviewer`. Those five remain reachable by direct
  > routing too — from the main session, their `/…-review` command (GCP and AWS have none), or
  > `tools-app-deploy-skill`.
  >
  > **`message-rabbitmq-reviewer` matches none of the five prefixes and stays command-only** — reach
  > it from the main session or `/message-rabbitmq-review`. `app-agent-team` and `api-agent-team` are
  > still closed to `app-*` and `api-platform-*` respectively, so an orchestrator that needs a
  > reviewer outside its own roster **refers it and marks the layer unreviewed** — see umbrella §5.3.
- **Output:** a `[MUST]`/`[SHOULD]`/`[CONSIDER]` severity report — only `[MUST]` blocks a merge. `[Verified]`

### 3.2 Security — vulnerability diagnosis (repurposed from Analyze on 2026-08-22)

- **Trigger:** a natural-language request ("security check", "find vulnerabilities", "authorization
  audit", "injection risk"), or the pre-deploy gate.
- **Entry point:** `app-php-symfony-analyzer` / `app-javascript-stimulus-analyzer` /
  `app-twig-symfony-analyzer` / `api-platform-analyzer` (the `app/src/{ApiResource,State}/` exposure
  layer). All are **read-only**, enforced at the harness level by `disallowedTools: Edit, Write`. `[Verified]`
- **Boundary against Review and Debug:** Review asks "does it follow the rules", Debug asks "why
  doesn't it work", and Security asks **"is it exploitable"** (authentication and authorization
  defects, injection, sensitive data exposure, vulnerable dependencies).
- **Handoff:** `Security (diagnose) → Build/author (implement the fix) → Review (quality gate) → Test
  (regression prevention)`; on discovering a runtime failure, `Security → Debug`.
- **Output format:** diagnosis scope → summary table (count per severity) → findings (**location,
  description and recommended fix** are mandatory, with OWASP·CWE classification) → needs
  verification → **unchecked items**. Severities are Critical/High/Medium/Low, mapping to
  Critical·High = `[MUST]`, Medium = `[SHOULD]`, Low = `[CONSIDER]`. Detail in section 3.2 of the SoT.
- **Caution — never invent a CVE:** quote only what `composer audit` or `npm audit` actually printed.
  **`app/vendor` is currently absent, so dependency CVE checking is impossible** — report it as
  "unchecked" in that case.
- **Structural analysis is no longer this axis** — route requests like "is the structure sound?" or
  "any room to refactor?" to `*-author` (design and implementation) or `*-reviewer` (a `[CONSIDER]` verdict).

### 3.3 Debug — tracing a bug's root cause

- **Trigger:** a symptom report or a natural-language request ("why isn't this working").
- **Entry point:** `app-php-symfony-debugger` / `app-javascript-stimulus-debugger` /
  `app-twig-symfony-debugger` / `api-platform-debugger` (the `app/src/{ApiResource,State}/` exposure layer).
- **Handoff:** `Debug (cause and fix) → Review (quality) → (if needed) Test (regression prevention)`.
  When a structural defect is the cause, pass it to `Debug → Build/author` to implement the refactor.
  When the cause is a security vulnerability, pass it to `Debug → Security` for a severity diagnosis.

### 3.4 Test — writing regression-preventing tests

- **Trigger:** after writing a new class, or after a Debug fix.
- **Entry point:** `app-php-symfony-tester` / `app-javascript-stimulus-tester` /
  `app-twig-symfony-tester` / `api-platform-tester` (`ApiTestCase`-based — **it holds the canonical
  per-operation test procedure in its own body**).
- **Mandatory:** `rules/app-php-symfony-09-testing-rule.md` (the Unit/Integration/Functional boundary). `[Verified]`

### 3.5 Build — verify immediately after generating

- **Trigger:** a request to generate API, provider or configuration code.
- **Entry point (author→reviewer pair):** `app-agent-team` / `api-agent-team` or a `*-build-skill` orchestrator → author →
  reviewer PASS/REDO → confirm on PASS, or on REDO re-invoke with only the instructions applied
  (max 3 times for code domains).
- **Members (added 2026-08-22):** `app-php-symfony-author` / `app-javascript-stimulus-author` /
  `app-twig-symfony-author` / `api-platform-author` — each paired with its matching `*-reviewer`.
  **A code-domain author edits `app/**` directly rather than writing a draft file** and passes
  `git diff` as the verification medium (only the Commit and Diagram teams, whose final action is
  destructive, place drafts under `.claude/tmp/`). `[Verified]`
- **Self-gates — never read exit 0 as a pass:** the author calls the existing `PostToolUse` hooks
  (`php-lint.sh`, `php-cs-fixer.sh`, `twig-lint.sh`, `js-guard.sh`) **directly with a stdin JSON
  payload** (these hooks take no `$1` argument). The hooks are non-blocking by design, so without
  `app/vendor` they **skip silently and exit 0** — check the precondition first and **explicitly mark
  any gate that did not run as "unchecked"**. Only `php -l` and `js-guard.sh` actually work at
  present. `[Verified]`
- **Variants (no agent — command-based self-verification):**
  - API Platform (resources and State / authentication and authorization) —
    `api-platform-rest-build-skill` and `api-platform-oauth2-build-skill` edit the source per the
    `## Authoring Conventions` of the `/api-platform-rest-build` and `/api-platform-oauth2-build`
    commands and reach a verdict via the same commands' `## Self-Verification` (adopted 2026-08-17,
    max 3 retries). When a third-party verdict is wanted, spawn `api-platform-reviewer` as an
    additional gate. `[Verified]`
  - Claude Code configuration artifacts — the `utility-claude-code-skill` skill drafts them and
    self-verifies against the criteria in the `/utility-claude-code-review` command (adopted
    2026-08-08). `[Verified]`
  - Providers (UPbit REST/WS, KoreaInvestment OAuth2/REST/WS) — each `*-build-skill` generates from,
    then self-verifies against, its matching `*-build` command's authoring conventions and
    verification checklist (adopted 2026-08-15, max 3 retries). `[Verified]`
  - Shell scripts (`scripts/**`) — the `utility-shell-script-skill` skill drafts from the
    `## Authoring Conventions` of the `/utility-shell-script-review` command and self-verifies via the
    same command's `## Review Procedure` (adopted 2026-08-16, max 2 retries). `[Verified]`

### 3.6 Commit·Deploy — commit standards and the pre-deploy gate

**Commit sub-team (reference standard)**

- **Trigger:** a commit request (with `git diff --cached` non-empty).
- **Entry point:** `utility-git-commit-skill` → `utility-git-commit-author` →
  `utility-git-commit-reviewer` → `git commit -F` on PASS, REDO max 2 times. `[Verified]`

**Deploy sub-team (pre-deploy security and configuration gate)**

- **Trigger:** immediately before deploying, after a change to deployment assets
  (`scripts/containers/prod/**`, `**/*.tf`, `**/Dockerfile`, etc.).
- **Entry point:** `tools-app-deploy-skill` — **fans** the deployment assets out to the domain
  reviewers (Nginx, GCP Cloud Run, AWS ECS, Shell Script), consolidates the results and returns a
  go/no-go (PASS/BLOCK). On PASS the actual deployment hands off to `tools-gcp-cloudrun-skill` or
  `tools-aws-ecs-skill`. The gate never performs a deployment or rollback itself. `[Verified]`
- **Caution:** `git push` is set to `ask` in `settings.json`, so it always goes through user
  confirmation. Destructive operations proceed only after approval.

---

## 4. When to Use a Dynamic Workflow (trade-offs)

| Situation | Recommended | Rationale |
| --- | --- | --- |
| A single-shot review, analysis, debug or test in one domain | direct routing (3.1–3.4) | no new skill needed, works immediately |
| Multi-step work with retries and gates (generate → verify → judge) | an orchestrator skill (3.5–3.6) | explicitly controls the retry, artifact and verdict loop |
| Fan-out across tens to hundreds of files, large-scale parallel exploration and verification | **Dynamic workflow** (1.1) | the runtime manages the parallel subagents and keeps the session responsive |

- **Scalability:** dynamic workflows excel at large fan-out, but they do not replace the repository's
  deterministic gate and retry conventions (max 2 retries, `tmp/` artifacts) — the two are complementary.
- **Maintainability:** the repository standard (skills + subagents) is easy to version-control and
  review. A dynamic workflow is a runtime product and leaves nothing behind in the repository.
- **Performance:** dynamic workflows win on large-scale parallelism, but carry heavy overhead for
  single-shot work.

> **The adoption procedure is owned elsewhere — do not restate it here.** `[Verified]` 2026-09-06:
> `.claude/skills/abstract-graph-engineering-skill/SKILL.md` § 9 holds the six steps to clear **before**
> a workflow script is saved into this directory — the placement re-review (which is user-approval
> territory, because a `.js` puts an executable artifact alongside this reference document), the `/`
> namespace collision check against commands, skills and built-ins, the `export const meta` constraints
> that make a workflow **silently vanish** from autocomplete when violated, the determinism restriction
> (`Date.now()`, `Math.random()` and argument-less `new Date()` throw), the runtime limits, and the
> resume cost of a mid-fan-out failure. That skill also owns the decision of **whether** the repository's
> graph should move into code at all. This section stays a trade-off comparison; the procedure lives
> there.

---

## 5. Conventions for This Directory (what belongs here and what does not)

**Belongs here:** workflow playbooks (trigger → entry point → procedure documents), team operating
conventions, and notes on using dynamic workflows. All of these are documents **people and Claude
reference with `@`**.

**Does not belong here:**

- Logic that expects to be auto-triggered — build that as a skill (`.claude/skills/`) or a subagent
  (`.claude/agents/`).
- Criteria (SoT) — those live in the rules (`.claude/rules/`). Do not restate a rule here; reference
  it with `@see`.
- A **hand-authored** workflow script. The directory *is* an official load target (section 0), but the
  supported way to put a script here is to run a dynamic workflow and save it from `/workflows` with
  `s`. Do not write a `meta` block by hand and expect it to behave like a reviewed artifact — nothing
  in this repository's rule set covers it.

**Authoring conventions:** English, per the documentation-language rule in `CLAUDE.md`; attach a source
and a confidence label to every verifiable fact; and reference `docs/app-agent-team-docs.md` with `@see`
as the SoT for design background.

---

## References

| Source | Link |
| --- | --- |
| Dynamic workflows (official docs — primary source for section 0 and 1.1) | <https://code.claude.com/docs/en/workflows> |
| Agent teams (official docs — teammate promotion & its effect on orchestration) | <https://code.claude.com/docs/en/agent-teams> |
| Dynamic Workflows announcement (Anthropic blog — background only) | <https://claude.com/blog/introducing-dynamic-workflows-in-claude-code> |
| Common Workflows (official docs) | <https://code.claude.com/docs/en/common-workflows> |
| Claude Code extensions overview (features overview) | <https://code.claude.com/docs/en/features-overview> |
| Repository workflow design (SoT) | `.claude/docs/app-agent-team-docs.md` |
