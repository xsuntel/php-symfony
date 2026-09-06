# API Agent Team Composition

> Status: **Design document (SoT)** — the **API Platform domain document**. Defines the 5-axis
> `api-platform-*` roster, the Build verification loop, the cross-domain boundaries, and the rationale
> for `api-agent-team`'s routing and handoffs.
> Written: 2026-07-11 · Last updated: 2026-08-28
>
> **Re-split 2026-08-28** — this document and `app-agent-team-docs.md` were a single consolidated file
> between 2026-08-16 and 2026-08-28, paired with the single orchestrator `agent-team`. That orchestrator
> was split back into `api-agent-team` and `app-agent-team`, and the documents followed. This file
> received the API-Platform-specific content: the sub-inventory, the Build team, the template ② worked
> example, the cross-domain boundary table, and the full revision history (formerly section 5.1).
>
> **Scope of this document:** the 5 `api-platform-*` agents and this project's **own REST exposure
> layer** — `app/src/ApiResource/**`, `app/src/State/**`, `config/packages/api_platform.yaml`,
> `config/routes/api_platform.yaml`. The shared material — the three-layer collaboration principle,
> the role-team definitions (Review · Security · Debug · Test · Build · Commit · Diagram · Deploy), the
> model and tool axes, and the orchestration reference patterns — is **not restated here**; read the
> umbrella.

@see .claude/docs/app-agent-team-docs.md — repository-wide umbrella (three-layer principle · role teams · model/tool axis · loop templates)
@see .claude/rules/api-platform-rule.md — API Platform (Symfony) resource and State verdict SoT
@see .claude/docs/api-platform-docs.md — step-by-step procedure for adding an API Platform resource
@see .claude/commands/api-platform-rest-build.md — authoring conventions (SoT)
@see .claude/commands/api-platform-oauth2-build.md — authentication/authorization authoring conventions (SoT)
@see .claude/rules/abstract-structure-rule.md — rule index (SoT)
@see .claude/output-styles/abstract-english-style.md — document style (ADR · trade-offs · citation)

---

## 1. Scope and Premises

**API Platform covers only the *exposure* of this project's own REST API.** Outbound clients that
consume external provider APIs (UPbit, KoreaInvestment) are a different concern entirely — despite the
`api` prefix on their planned artifact names, they belong to `app-agent-team`. Do not conflate the two.

The premises this domain inherits (agent-teams feature flag, `plan` default permission mode,
`abstract-english-style`, the rules/agents/skills/commands layering) are stated once in the umbrella,
section 1. The one premise specific to this domain:

- **The criteria live in three places and no more.** `rules/api-platform-rule.md` is the verdict SoT;
  `/api-platform-rest-build` and `/api-platform-oauth2-build` are the SoT for the **authoring
  conventions**; `/api-platform-review` is the standalone review entry point. Every agent in this
  domain references them via `@see` and **holds no criteria of its own** — a fourth copy would
  guarantee drift. This constraint is why the revived author (section 6, revision 3) carries no
  `## Authoring Conventions` section.

---

## 2. API Platform Sub-inventory (5 axes)

The only integration domain with the **same five axes as each app domain**. `[Verified]` 2026-08-28.

| Workflow role | Agent | Model | Isolation | Tools | Output |
| --- | --- | --- | --- | --- | --- |
| **Build** | `api-platform-author` | opus | worktree | Read · Grep · Glob · Bash · Write · Edit | code under `app/src/{ApiResource,State}/`. **The `*-build` commands are the SoT for the authoring conventions** (it holds none itself) |
| **Security** | `api-platform-analyzer` | opus | worktree | Read · Grep · Glob · Bash (+ `disallowedTools: Edit, Write`) | exposure-layer vulnerabilities (missing authorization, BOLA, sensitive field exposure, mass assignment) diagnosed by severity, with fixes (no code changes) |
| **Review** | `api-platform-reviewer` | **sonnet** | **none** | Read · Grep · Glob · Bash · WebFetch · WebSearch (+ `disallowedTools: Edit, Write`) | `[MUST]/[SHOULD]/[CONSIDER]` verdict against the SoT |
| **Debug** | `api-platform-debugger` | opus | worktree | Read · Grep · Glob · Bash · Edit · Write · WebFetch · WebSearch | root cause and minimal fix for an exposure-layer runtime failure |
| **Test** | `api-platform-tester` | opus | worktree | Read · Grep · Glob · Bash · Edit · Write · WebFetch · WebSearch | `ApiTestCase`-based operation × case test files |

`maxTurns` is 30 for four of the five; **`api-platform-tester` is 45**, because a Red-Green-Refactor
cycle runs six or more gate commands per invocation. The three write-path agents (author, debugger,
tester) set `permissionMode: acceptEdits` — without it their edits are refused under the `plan` default
mode. `[Verified]` 2026-08-28 [Read: .claude/agents/api-platform-*.md]

> ⚠️ **Correction 2026-08-28 — this domain is *not* "all opus, symmetric".** Previous revisions of this
> table asserted that all five agents were `opus`. Measured against the tree, **`api-platform-reviewer`
> is `sonnet`**, exactly like the three app-domain reviewers and the six infrastructure reviewers — all
> ten reviewers in the repository are sonnet. The domain remains **structurally** symmetric with the app
> domains (five axes, same roles); it is the *model* claim that was wrong. See the corrected
> `### Model and Tool Distribution` in the umbrella for the role axis that actually governs.

**Two isolation facts that determine how the orchestrator must spawn these agents:**

- **Four of the five are `isolation: worktree`.** A worktree checkout contains **tracked content only**,
  and `.claude/tmp/` is gitignored, so an isolated agent cannot see the author's uncommitted edits and
  cannot exchange a tmp artifact. `api-platform-reviewer` is the only one sharing the real working tree.
- **Consequently the author→reviewer handoff must pass the diff inline.** A reviewer told to run
  `git diff` in its own worktree sees an empty diff and returns **a clean pass on work it never read** —
  the most dangerous failure mode in this domain. `api-agent-team` carries an explicit checklist item.

> The former Author and Reviewer `isolation: worktree` settings were removed wholesale on 2026-08-15
> for exactly this reason, then partially reintroduced as the roster grew. The reviewer's omission is
> deliberate and load-bearing; **flag any added `isolation: worktree` on `api-platform-reviewer` as a
> `[MUST]`.**

**Axis history in brief** (full rationale in section 6):

- **Debug and Test joined 2026-08-17.** Both files had been 10-line stubs whose `description` was copied
  from the reviewer, leaving the harness no basis to route a Debug or Test intent.
- **The Analyze axis joined 2026-08-17**, by repurposing `api-platform-author` rather than creating a
  file. **On 2026-08-22 it was repurposed again, to Security.**
- **The Build/Author axis rejoined 2026-08-22** — `api-platform-author` revived, with the commands still
  owning the conventions.

---

## 3. Build Team (API Platform)

### Routing

- Changed paths `app/src/ApiResource/**` and `app/src/State/**` → **the Build loop**.
- A configuration-only change (`config/packages/api_platform.yaml`, `config/routes/api_platform.yaml`)
  → **a standalone `api-platform-reviewer` cross-check**, skipping the unnecessary generation step.
  `[Verified]`
- Anything outside the exposure layer → **hand off to `app-agent-team`**, including the domain logic a
  State delegates to.

### Canonical owner

The `api-platform-rest-build-skill` and `api-platform-oauth2-build-skill` build skills own the canonical
path (template ②). The `api-agent-team` orchestrator can also run the **agent pair** (template ①)
directly when an independent-context verdict is wanted. `[Verified]`

**The two paths are equivalent in criteria and different only in isolation** — both read the same build
commands and the same rule (SoT). Choose ① when a verdict uncontaminated by the generation context
matters; choose ② when a single session is cheaper and drift is the larger risk.

### The anti-patterns the reviewer exists to catch

Exposing a Doctrine `Entity` directly instead of a DTO in `App\ApiResource\`; relying on the implicit
default operation set instead of an explicit array; hand-implementing filters API Platform already
provides; hand-assembling custom error payloads instead of RFC 7807/Hydra; confusing `security:` with
`securityPostDenormalize:` (an ownership-transfer vulnerability, not a style issue). The rule (SoT) is
`api-platform-rule.md`; this list is a pointer, not a second copy of the criteria.

---

## 4. The API Platform Build Loop (template ② applied)

The retry limit is **3**, this being a code domain. (Template ① and ② themselves are defined in the
umbrella, section 4.)

```text
build skill (api-platform-rest-build-skill | api-platform-oauth2-build-skill)
  ├─ 1. Fix the scope (changed ApiResource/State files and intent; variant = rest | oauth2)
  ├─ 2. Generate     → edit app/src/ApiResource/ and app/src/State/ per the build command's `## Authoring Conventions`
  ├─ 3. Self-verify  → cross-check git diff per the same command's `## Self-Verification`
  │                    → ./.claude/tmp/api/api-platform-<variant>-review.md (PASS/REDO)
  ├─ 4. Branch on the verdict
  │      PASS → note the static gates (phpstan, php-cs-fixer) + recommend api-platform-tester
  │      REDO → apply only the review instructions and repeat from step 2
  └─ 5. Past the retry limit (max 3) → stop with the source preserved + recommend manual review
```

**Template ① — the agent-pair alternative:**

```text
api-agent-team
  ├─ 1. Spawn api-platform-author  → edits app/src/{ApiResource,State}/ per the build commands
  ├─ 2. Capture `git diff` and PASTE IT INLINE into the reviewer prompt (the author is worktree-isolated)
  ├─ 3. Spawn api-platform-reviewer → [MUST]/[SHOULD]/[CONSIDER] against api-platform-rule.md
  ├─ 4. 0 [MUST] → recommend api-platform-tester │ 1+ [MUST] → re-invoke the author with those items only
  └─ 5. Past 3 retries → stop with the source preserved + recommend manual review
```

> Before 2026-08-17 this slot held the agent pair alone. Between 2026-08-17 and 2026-08-22 it held the
> skill loop alone. **Since 2026-08-22 both exist and coexist** — the pair is an *additional* gate, not
> a replacement for self-verification.

- Intermediate artifacts are exchanged under `./.claude/tmp/api/` (gitignored); the consolidated report
  is `./.claude/tmp/api/api-agent-team-report.md`. Variant = `rest` | `oauth2`.
- **Only the reviewer can read a tmp artifact**; the other four are isolated. Ask the read-only agents
  (`analyzer`, `reviewer`) for findings **in their returned report** — both declare
  `disallowedTools: Edit, Write` and a tmp path assignment makes the spawn fail at its final step.
- Secret values (tokens, credentials, JWTs) are never included in any artifact or output.
- **Static gates are advisory here.** `app/vendor` is currently absent, so PHPStan and php-cs-fixer do
  not run; report them as **"unchecked"** rather than as passes.

---

## 5. Cross-domain Boundaries (outside api — delegated)

| Overlapping concern | Delegate to | Basis |
| --- | --- | --- |
| Structure of the domain logic a State delegates to | **`app-agent-team`** (delegated; it routes to `app-php-symfony-reviewer` / `-author`, `app/src/Service/**`) | `app-php-symfony-*-rule.md` |
| DTO `stateOptions` (Entity reuse), N+1, migrations | **`app-agent-team`** (delegated) — but its roster closed to `app-*` on 2026-08-29, so it **returns a referral to `/database-postgresql-review`, not a verdict**. Relay it and mark the layer unreviewed | `database-postgresql-rule.md` |
| operation `security:`, Voter, `stateless` tokens, rate limiter | **`app-agent-team`** (delegated; rule cross-check via `app-php-symfony-reviewer`) | `app-php-symfony-08-security-rule.md` |
| Regression tests | `api-platform-tester` (canonical procedure + file authoring). Domain service and Doctrine layers only → `app-php-symfony-tester` | `api-platform-rule.md` · `app-php-symfony-09-testing-rule.md` |
| Runtime failure diagnosis | `api-platform-debugger`. If the cause lies in a service, Doctrine or Messenger that a State delegates to → `app-php-symfony-debugger` | `api-platform-rule.md` |
| Everything else — Stimulus, Twig, infrastructure, providers, Deploy, Commit | **`app-agent-team`** | that orchestrator's routing table |

**`api-agent-team` spawns no specialist outside its own roster** (revision 5, 2026-08-29). Its `Agent`
target list is closed to the 5 `api-platform-*` agents **plus the sibling orchestrator
`app-agent-team`** — the single cross-boundary spawn it is permitted, and at most once per invocation.

That distinction is what separates the two rows' handling:

- **Delegated** — the first three rows above. Their subject matter is entangled with a verdict
  `api-agent-team` is already forming, so it spawns `app-agent-team` with the enumerated non-exposure
  file list and **merges the returned findings into one consolidated report**. This preserves the
  single-invocation duplicate merge that the former direct adjuncts existed to provide.
- **Referred** — the last three rows. Independent of the exposure-layer verdict, so they are named in
  `## Handoffs` and not spawned at all.

**The delegation must carry a scope lock.** `app-agent-team`'s own routing splits exposure-layer paths
off *to `api-agent-team`*, so a delegation without an explicit instruction not to re-expand scope or
hand those paths back is reentrant. The prompt therefore states the file list verbatim and forbids the
bounce; `app-agent-team` receives it as **Mode D (sub-delegation)** in its Input Contract.

**Duplicate findings to merge:** a DTO reusing an Entity through `stateOptions` will draw the same N+1
or mapping finding from `api-platform-reviewer` and — via the delegation — from
`database-postgresql-reviewer`; collapse into one entry at the strictest severity. Findings about
post-delegation domain logic overlap with `app-php-symfony-reviewer` in the same way. A delegated
`[MUST]` blocks the merge exactly as a roster agent's does.

---

## 6. Trade-offs and Revision History

The API Platform domain's initial roster held only one author→reviewer pair, so rather than copying the
multi-role (Analyze/Debug/Test) axes wholesale it **consolidated into a single Build verification
loop**. That decision was then revised three times.

> **Revision (2026-08-17):** the Debug and Test axes joined as `api-platform-debugger` and
> `api-platform-tester`. The premise of the consolidation decision (delegating to the app domain with
> no dedicated agents) turned out not to hold — diagnostic and testing knowledge such as serialization
> group ↔ context mismatches, undeclared operations, the semantic difference between `security:` and
> `securityPostDenormalize:`, and `ApiTestCase` (≠ `WebTestCase`) and `findIriBy` does not overlap the
> SoT of `app-php-symfony-*` (Doctrine, Messenger, WebTestCase), so the delegate had no basis for a
> judgment.
> **The Analyze axis did not join at that point** — structural analysis targets the domain logic a
> State delegates to, which was judged to overlap `app-php-symfony-analyzer`'s SoT.

> **Revision 2 (2026-08-17, later the same day):** that judgment was reversed — **the Analyze axis
> joined** and, at the same time, **the Build/Author agent was merged into commands**.
>
> - **Rationale for adding Analyze** — what had been judged to overlap was the domain logic *after* a
>   State delegates. The stage before it, **structural debt specific to the exposure layer**
>   (resource–Entity coupling, State bloat, serialization group proliferation, excessive operation
>   surface, scattered security expressions), cannot be judged from `app-php-symfony-analyzer`'s SoT
>   (Doctrine, Messenger, Service). The same logic that brought in Debug and Test.
> - **How it was implemented** — no new file was created; `api-platform-author` was **repurposed**.
>   Its tools gave back `Edit`/`Write` to become read-only (`Read, Grep, Glob, Bash`), and its memory
>   was converted with it.
> - **Rationale for the Build merge** — moving the Author to Analyze would empty the generation axis,
>   so the `/api-platform-rest-build` and `/api-platform-oauth2-build` commands were created as a
>   **fourth application of the same pattern** as `utility-claude-code` (2026-08-08), the providers
>   (2026-08-15) and shell script (2026-08-16). The authoring conventions and known gaps gather in one
>   command, and the 2 build skills run a self-verification loop against them.
> - **Avoiding duplicate criteria** — unlike the provider build commands, these two do not carry their
>   own `## Verification Checklist`. Because both the `api-platform-reviewer` agent and the
>   `/api-platform-review` command survived, verification references those two and the rule (SoT) via `@see`.
> - **Unifying the test procedure** — the same change retired the `/api-platform-test` command and
>   moved the procedure into the `api-platform-tester` body (`## Test Procedure`), matching the shape
>   of the 3 app-domain testers.

> **Revision 3 (2026-08-22):** **partially reverses** revision 2 by reviving `api-platform-author` and
> **repurposing the Analyze-axis `api-platform-analyzer` to the Security axis**. This gave the domain
> **five axes (Build · Security · Review · Debug · Test)**.
>
> - **Rationale for reviving the author** — revision 2 moved the Author to Analyze and handed the
>   generation axis to the commands. But when authors were filled in for the 3 app domains on
>   2026-08-22, leaving API Platform without an agent on the generation axis would force the
>   orchestrator to route differently per domain (agent vs. skill). It was revived for **routing
>   symmetry across the 4 code domains**.
> - **Duplicate criteria are still avoided** — the revived author **does not hold its own
>   `## Authoring Conventions`.** This domain already has its criteria in three places (the build
>   commands, `api-platform-reviewer`, `/api-platform-review`), so a fourth copy would guarantee
>   drift. The author merely references the two build commands via `@see`.
> - **It coexists with the skills** — it **does not replace** the self-verification loop (template ②)
>   of `api-platform-rest-build-skill` and `-oauth2-build-skill`. It adds the path the orchestrator
>   takes when an independent-context third-party verdict is wanted, spawning the pair (template ①);
>   the criteria on both paths are the same commands and rules.
> - **Rationale for the Analyze → Security change** — the "structural debt specific to the exposure
>   layer" that revision 2 brought in is absorbed by `api-platform-author` (design at generation time)
>   and `api-platform-reviewer` (rule verdicts). Exposure-layer **security**, by contrast, is not
>   substitutable — missing operation authorization, BOLA, `security:` ↔ `securityPostDenormalize:`
>   timing confusion, and sensitive fields exposed in a read group cannot be judged from
>   `app-php-symfony-analyzer`'s SoT, and **a vulnerability here is an internet-facing surface**, which
>   makes it the most critical case as well.

> **Revision 4 (2026-08-28) — the orchestrator split.** `agent-team` was split into `api-agent-team`
> and `app-agent-team`, giving this domain back a **paired orchestrator and design document** for the
> first time since 2026-08-16. The roster itself did not change: the same five agents, the same
> criteria, the same two Build paths. What changed is that routing into them no longer competes for
> prompt space with the provider rows, the Deploy gate and the infrastructure fan-out.
> The full ADR — including the identical-`description` defect that made the initial copy-based split
> unroutable — is **section 5.2 of the umbrella**, `app-agent-team-docs.md`.

> **Revision 5 (2026-08-29) — the roster was closed to `api-platform-*`.** By explicit user
> instruction, `api-agent-team` now handles **only** Symfony API Platform: its `Agent` target list is
> the 5 `api-platform-*` agents and nothing else. The two cross-boundary adjuncts it had been allowed
> to spawn directly — `database-postgresql-reviewer` for `stateOptions` Entity reuse, and
> `app-php-symfony-reviewer`/`-author` for the domain logic a State delegates to — were removed from
> the roster, from the routing table and from the three reciprocal claims in those agents' own prompts.
>
> - **Why the adjuncts existed** — not convenience, but the **duplicate-finding merge**. An API change
>   that reuses a Doctrine Entity draws the same N+1 finding from two domains, and collapsing those
>   into one entry is the thing an orchestrator exists to do. The 2026-08-28 ADR (umbrella §5.2)
>   rejected a strict partition for exactly this reason.
> - **What replaced them — delegate to the sibling, not to the specialist.** The non-exposure half is
>   handed to **`app-agent-team`** as a single `Agent` spawn, and its returned findings are merged into
>   the consolidated report. This is the third option that ADR did not weigh: the merge survives in one
>   invocation, while the roster now matches the agent's stated scope. The umbrella's rejected
>   alternative is marked **superseded** rather than deleted.
> - **The cost is one nested orchestrator spawn** per mixed change — the most expensive single spawn
>   available, running its own 50-turn budget. Mitigated by a hard cap of **one delegation per
>   invocation**: every non-exposure path is gathered into it, and anything surfacing afterwards is
>   reported as deferred rather than re-spawned.
> - **The new failure surface is recursion.** `app-agent-team` routinely splits exposure-layer paths
>   off *to `api-agent-team`*, so an unguarded delegation bounces back and burns both budgets without
>   producing a verdict. Guarded on both sides: the caller's prompt carries an explicit scope lock, and
>   `app-agent-team` gained **Mode D (sub-delegation)** in its Input Contract — take the file list
>   verbatim, no `git diff` re-expansion, never split back to the caller.
> - **A failed delegation degrades, it does not fall back.** If the sibling fails or returns nothing,
>   `api-agent-team` reports the non-exposure half as **unreviewed** with incomplete coverage. It must
>   not "just spawn the reviewer" — that is the roster violation the revision exists to prevent.
> - **The design spends the entire spawn-depth budget, and this is the constraint to watch.**
>   `[Verified]` 2026-08-29 [WebFetch: <https://code.claude.com/docs/en/subagents>]: nesting is capped
>   at **3 layers below the main conversation** by default, and **at the cap the `Agent` tool is
>   withheld rather than erroring** — the agent does the work itself and returns a summary. The chain
>   `main → api-agent-team (1) → app-agent-team (2) → specialist (3)` fits with **zero headroom**, so
>   the delegation only works when `api-agent-team` is spawned from the main conversation. Spawned
>   nested, or with `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH` lowered (the official docs use `"2"` as
>   their example value), the sibling silently reviews the non-exposure half itself instead of routing
>   it — a real verdict, but from an orchestrator prompt rather than the domain specialist, and with
>   nothing in the output to signal the downgrade. `api-agent-team` therefore checks the setting and
>   **refers instead of delegating** when the budget is short. `[Verified]` 2026-08-29: the variable is
>   unset in `.claude/settings.json`, so the default 3 applies today.
> - **The delegation also depends on `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` staying `"0"`.**
>   `[Verified]` 2026-08-29 [Read: .claude/settings.json:12]. Under agent teams, a subagent Claude
>   *names* launches as a teammate and returns only an idle notification carrying none of its output —
>   which would discard the sibling's findings and leave the merge silently empty. This revision adds a
>   second orchestrator to the set of things that flag protects.
>
> No file was added, renamed, moved or deleted, so this is a content-only change under the
> `## API Domain — Layout Freeze` clause "Content edits are unaffected", and the 32-agent census is
> unchanged.

### Three-axis analysis

- **Scalability:** the agent count is invariant as resources and operations grow — the criteria live in
  the rules and the build commands (SoT), so those extend without touching the prompts.
- **Maintainability:** the verdict, diagnosis, testing and generation focuses are each single, keeping
  cognitive load low. The authoring conventions are owned by the build commands rather than an agent
  prompt, so convention changes gather in one file. Only the structure of the domain logic *after* a
  State delegates is left to the app domain. **Since revision 5 the roster is also closed**, so
  "which agents can this orchestrator reach?" has a one-line answer instead of a roster plus a list of
  exceptions — the boundary is now checkable rather than remembered.
- **Performance:** a one-off review spawns only the reviewer (sonnet, no isolation), skipping the
  generation step entirely. Conversely, multiple matches across domains (section 5) create redundant
  review load, which the orchestrator mitigates by merging and delegating. **Revision 5 makes a mixed
  change measurably more expensive** — the non-exposure half now costs a nested orchestrator spawn
  rather than a direct reviewer spawn. That is the deliberate price of the closed roster, bounded by
  the one-delegation-per-invocation cap; a pure exposure-layer change is unaffected.

---

## 7. Domain Gaps

| # | Finding | Status |
| --- | --- | --- |
| 1 | A DTO reusing an Entity via `stateOptions` matches both `api-platform-rule.md` and `database-postgresql-rule.md` | ⚠️ **Live, and widened 2026-08-29** — `app-agent-team`'s roster closed to `app-*` hours after revision 5, so **neither orchestrator can spawn `database-postgresql-reviewer`**. There is no second verdict to merge: the delegation returns a **referral** to `/database-postgresql-review` that a human closes out. Relay it and mark the persistence layer unreviewed — never report the merge as done. See umbrella §5.3 |
| 2 | With `app/vendor` absent, `composer audit`, PHPStan and php-cs-fixer cannot run | ⚠️ **Live** — `api-platform-analyzer` reports dependency CVEs as **unchecked** rather than estimating; the Build loop reports its static gates as unchecked |
| 3 | The exposure layer has no dedicated *structural* analysis axis since the 2026-08-22 Security repurposing | ⚠️ **Accepted** — absorbed by `api-platform-author` (design time) and `api-platform-reviewer` (`[CONSIDER]` findings) |

---

## Appendix: API Domain Reference Assets

| Asset | Path | Role |
| --- | --- | --- |
| Orchestrator | `.claude/agents/api-agent-team.md` | routing and handoffs for the exposure layer |
| Umbrella design SoT | `.claude/docs/app-agent-team-docs.md` | three-layer principle · role teams · model/tool axis · loop templates |
| Verdict SoT | `.claude/rules/api-platform-rule.md` | resource · State · security verdict criteria |
| Authoring SoT | `.claude/commands/api-platform-rest-build.md` · `api-platform-oauth2-build.md` | authoring conventions (no agent duplicates these) |
| Review entry point | `.claude/commands/api-platform-review.md` | `/api-platform-review` standalone verdict |
| Procedure | `.claude/docs/api-platform-docs.md` | step-by-step guide to adding a resource |
| Build skills | `.claude/skills/api-platform-{rest,oauth2}-build-skill/` | template ② self-verification loops |
| Agent memory | `.claude/agent-memory/api-agent-team/MEMORY.md` | orchestrator routing constants |
