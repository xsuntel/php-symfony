# api-agent-team memory

> Re-split on 2026-08-28 from the single `agent-team` orchestrator back into `api-agent-team` and
> `app-agent-team`, restoring the pairing that existed before the 2026-08-16 merge. This file now
> covers **only** the API Platform exposure layer; everything else moved to
> `agent-memory/app-agent-team/MEMORY.md`. The stale four-role quartet, the claim that no author agent
> exists, and the Analyze-axis description of `api-platform-analyzer` were all corrected in the same
> pass.

## Role (verified)

- Coordinator/dispatcher for **one** agent family — routes, drives the Build loop, and consolidates;
  does **not** perform domain judgment itself (that belongs to the sub-agents).
- **Scope: this project's own REST exposure layer only** — `app/src/ApiResource/**`,
  `app/src/State/**`, `config/packages/api_platform.yaml`, `config/routes/api_platform.yaml`.
- **API Platform family — 5 agents:** `api-platform-{author,analyzer,debugger,reviewer,tester}`. Since
  2026-08-22 this is the **same five-axis set as each app domain** (Build · Security · Debug · Review ·
  Test).
- Agents resolve by frontmatter `name`, not filename.

## Corrections carried forward (do not regress)

- **`api-platform-analyzer` is the Security axis, not Analyze.** Repurposed 2026-08-22 — it diagnoses
  exposure-layer vulnerabilities (missing operation authorization, BOLA, `security:` vs
  `securityPostDenormalize:` timing confusion, sensitive fields in a read group, mass assignment).
  A "is the structure sound?" request sent here returns a security diagnosis. Structural design goes
  to `api-platform-author`; rule-compliance verdicts to `api-platform-reviewer`.
- **`api-platform-author` exists.** It was merged into the build commands on 2026-08-17 and **revived
  on 2026-08-22**. The earlier note in this file that "no author agent exists in any code domain" is
  false and has been removed.
- **The build commands remain SoT for the authoring conventions** — the author references
  `/api-platform-rest-build` and `/api-platform-oauth2-build` via `@see` and holds no conventions of
  its own. Do not let a fourth copy of the criteria appear.
- **Retry limit is 3, not 2** — API Platform is a code domain.

## Routing constants

- **Everything outside the exposure layer → hand off to `app-agent-team`.** Do not route PHP services,
  Twig, Stimulus, infrastructure, deployment, commit or provider paths yourself.
- **Role axis (by intent):** generate/modify/refactor → `api-platform-author`; security or
  vulnerability diagnosis → `api-platform-analyzer`; bug/root cause → `api-platform-debugger`; quality
  gate → `api-platform-reviewer`; regression tests or a TDD cycle → `api-platform-tester` (it owns
  Green/Refactor itself, like every `app-*-tester`).
- **Create/modify a resource:** call `api-platform-rest-build-skill` (authorization and authentication
  → `api-platform-oauth2-build-skill`); test-first → `api-platform-tester`. Gate any of them with
  `api-platform-reviewer`.
- **Config-only change** (`api_platform.yaml`, `routes/api_platform.yaml`): skip the Build loop, spawn
  a lone `api-platform-reviewer`.
- **The roster is closed (2026-08-29).** The only permitted `Agent` targets are the 5 `api-platform-*`
  agents **plus `app-agent-team`**. Spawning `database-postgresql-reviewer`, `app-php-symfony-*` or an
  infrastructure reviewer directly is a role violation — there are no adjuncts any more.
- **Non-exposure work → one `app-agent-team` delegation.** Gather **every** out-of-scope path into a
  single spawn (max **one per invocation**, counted against the 6-per-batch cap) and merge the returned
  findings into the consolidated report. It routes internally to `app-php-symfony-reviewer`/`-author`
  (the domain logic a State delegates to). **Its roster closed to `app-*` on 2026-08-29**, so the
  persistence half (`stateOptions` Entity reuse, N+1, JOIN FETCH, migrations) comes back as a
  **referral to `/database-postgresql-review`, not a verdict** — relay it and mark that layer
  unreviewed. Neither orchestrator can reach `database-postgresql-reviewer` any more.
- **The delegation prompt must carry the scope lock**, or it loops: `app-agent-team`'s own step 2 splits
  exposure-layer paths off *to you*. State the enumerated file list, "Operate in Mode D
  (sub-delegation)", and "do not re-expand scope and do not hand any exposure-layer path back".
- **A failed delegation degrades, it does not fall back.** Report the non-exposure half as *unreviewed*
  with incomplete coverage — never "just spawn the reviewer instead".

## Build verification loop

- Two equivalent paths, same criteria (the build commands + `api-platform-rule.md`):
  - **① agent pair** — `api-platform-author` → `api-platform-reviewer`, when an independent-context
    verdict is wanted. Spawn **sequentially**, and **paste the author's full unified diff inline** into
    the reviewer prompt: the author is `isolation: worktree`, so the reviewer cannot reach its bytes.
  - **② build-skill self-verification** — `api-platform-rest-build-skill` /
    `api-platform-oauth2-build-skill` generate and self-verify in one session.
- On REDO re-invoke **the same entry point** with **only the `[MUST]` items**; retry limit 3, then stop
  **without reverting the source** and recommend manual review.
- Intermediate drafts under `./.claude/tmp/api/` (gitignored); consolidated report at
  `./.claude/tmp/api/api-agent-team-report.md`. Only `[MUST]` blocks the merge / forces a REDO.

## Isolation constraint (the failure mode that bites)

`[Verified]` 2026-08-28 — of 32 agents, 19 set `isolation: worktree` and 13 do not. **Four of the five
roster agents are isolated** (`author`, `analyzer`, `debugger`, `tester`); only `api-platform-reviewer`
shares the working tree. A worktree holds **tracked content only**, and `.claude/tmp/` is gitignored, so:

- Never assign a tmp output path to an isolated agent — it writes where nobody will read.
- Never assign a tmp path to `api-platform-analyzer` or `api-platform-reviewer` at all; both declare
  `disallowedTools: Edit, Write`. Ask for findings **in the returned report**.

## Hand-off flows

- `author/debugger → reviewer (quality gate) → tester (regression)`.
- `analyzer (security) → author (fix) → reviewer → tester`.
- `debugger → author` when structural debt is the cause; `analyzer → debugger` when a runtime failure
  surfaces; `reviewer/debugger → analyzer` when a security vulnerability surfaces.
- Do not chain past the user's intent — chain only when the sub-agent's result calls for it.

## Consolidation & dedupe

- Merge by severity; keep `[MUST]/[SHOULD]/[CONSIDER]`; **only `[MUST]` blocks the merge**.
- Cross-boundary duplicates arrive **inside `app-agent-team`'s returned report**, not from a reviewer
  you spawned. Merging them is why the delegation exists rather than a bare referral.
- `stateOptions` Entity reuse → `api-platform-reviewer` and (via the delegation)
  `database-postgresql-reviewer` may flag the same mapping or N+1; collapse into one entry at the
  strictest severity.
- A resource behind token auth or with sensitive `#[Groups]` → the exposure half is
  `api-platform-analyzer`, the Symfony security configuration half is
  `app-php-symfony-08-security-rule.md` reached **through the `app-agent-team` delegation**. Do not
  silently drop either half.
- A **delegated `[MUST]` blocks the merge** exactly as a roster agent's does. Never downgrade a finding
  for coming from the sibling, and never drop one because its file is outside your scope.
- Report which agents ran and how many loop iterations occurred, so routing is auditable.
- **Never report an unrun branch as clean** — "did not run" and "no findings" are different verdicts.

## Team collaboration (hand-off)

- Role: API Platform orchestrator · downstream: the 5 `api-platform-*` sub-agents **plus
  `app-agent-team`**, the sole cross-boundary spawn.
- Sibling: `app-agent-team` owns the 15 `app-*` agents, the 6 infrastructure reviewers, Deploy, Commit
  and the (unimplemented) provider routes. It is both the **referral** target for independent work and
  the **delegation** target for non-exposure work entangled with your verdict.
- Deploy is **not** this agent's job at any level — hand off to `app-agent-team`.

## SoT

- `.claude/docs/api-agent-team-docs.md` (API Platform team composition & Build-loop axis)
- `.claude/docs/app-agent-team-docs.md` (repository-wide umbrella: three-layer principle, role teams)
- `.claude/rules/api-platform-rule.md` (API Platform judgment criteria)
- `.claude/rules/abstract-structure-rule.md` (rule index & path context)
