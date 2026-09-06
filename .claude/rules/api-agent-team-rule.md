---
paths:
  - ".claude/agents/api-agent-team.md"
  - ".claude/agent-memory/api-agent-team/**"
  - ".claude/docs/api-agent-team-docs.md"
---

# api-agent-team Orchestration Rules

This rule is the judgment criteria (SoT) for the **routing, roster and handoff invariants** of the
`api-agent-team` orchestrator. It covers the command boundary of the Symfony API Platform **exposure
layer** only.

@see .claude/agents/api-agent-team.md — the orchestrator this rule judges (execution directives)
@see .claude/docs/api-agent-team-docs.md — team composition · role axes · verification loop rationale (not a SoT)
@see .claude/rules/api-platform-rule.md — code verdicts for resources, operations and State (SoT)
@see .claude/rules/app-agent-team-rule.md — the sibling orchestrator (application · provider · operations) verdict SoT
@see .claude/rules/tools-agent-team-rule.md — the sibling orchestrator (infrastructure · data · deployment) verdict SoT
@see .claude/docs/abstract-orchestrator-contract-docs.md — rationale and measured values of the shared operational contract
@see .claude/rules/abstract-structure-rule.md — directory and path conventions · rule index (SoT)

## Judgment Scope (no overlap with other SoTs)

**This rule owns the orchestration invariants only** and does not restate the rest.

| Axis | SoT | What it covers |
| --- | --- | --- |
| `.claude/**` structure and placement | `rules/utility-claude-code-rule.md` | directory tiers · flattening · frozen roots |
| Artifact spec | `commands/utility-claude-code-review.md` | frontmatter · naming · tool minimality |
| **Orchestration invariants** | **this rule** | **roster boundary · handoff direction · fan-out · verdict-suspension conditions** |
| Code verdicts | `rules/api-platform-rule.md` | the resource and State standards the subagents cross-check |

**The duplication with the agent prompt is intentional.** A subagent starts from an empty context and
cannot reach this rule through `@see`, so the directives must be physically present in
`agents/api-agent-team.md`. When the two diverge **this rule is the SoT**, and they are revised
**in the same change**.

## Shared Orchestration Contract (identical across the three teams)

The six **numbered imperatives** below are worded identically across the `app`, `api` and `tools`
rules. Never fix just one. The **indented notes are deliberately team-specific** — they record what
each roster actually declares, which differs — so they are not part of the shared wording. The
rationale and measured values live in `docs/abstract-orchestrator-contract-docs.md` and are not
restated here.

1. **The three orchestrators never spawn one another.** Out-of-scope files are handed over by naming
   the responsible team under `## Handoffs`, and are **never dropped silently**.
   > **One documented exception, in one direction only:** this orchestrator delegates its non-exposure
   > half to `app-agent-team` (Mode D). It is capped at **one delegation per invocation** — see
   > `## Invariant — scope boundary and handoffs`.
2. **All seven spawn-payload fields are mandatory** — target file list · role · governing rule (SoT)
   path · **output channel** · severity vocabulary · no secrets · marking of unrun gates. A missing
   field is a `[MUST]`.
   > **The fourth field is a channel, not always a path.** An agent declaring
   > `disallowedTools: Edit, Write` **cannot write a file**, so handing it a tmp path guarantees a
   > spawn that fails at its last step. Give a tmp path only to an agent that is both write-capable
   > and non-isolated; otherwise require the findings **in the returned report**.
3. **The orchestrator itself must never take `isolation: worktree`.** Its working material is the real
   tree — uncommitted `git diff` output and the gitignored `.claude/tmp/**` — and a worktree holds
   tracked content only, so isolating it produces an empty verdict as a silent failure.
   > **This is a constraint on the orchestrator, not a blanket ban.** `[Verified]` 2026-08-30: **4 of
   > the 5 `api-platform-*` agents set `isolation: worktree`** (analyzer, author, debugger, tester);
   > **`api-platform-reviewer` alone does not**, which is precisely what lets it read a tmp artifact
   > the other four cannot. Flag an added `isolation: worktree` on the reviewer as a `[MUST]`, and see
   > `## Invariant — verification loop` for the inline-diff requirement isolation forces.
4. **Keep the tmp consolidated-report path isolated per team** — never overwrite another team's report.
5. **A gate that did not run is not a pass** — tally across three values: passed / failed / **unchecked**.
6. **Re-spawn a partial failure exactly once**; if it fails again, state it as "cannot judge (not
   performed)" and **suspend go/no-go**. Exhausting your own turns is also a partial failure, so
   record into the consolidated report incrementally.

## Invariant — roster (direct spawn targets)

- **The only direct `Agent` spawn targets are the 5 `.claude/agents/api-platform-*.md` agents**
  (`-author`, `-analyzer`, `-debugger`, `-reviewer`, `-tester`).
- **Never spawn yourself** — `api-agent-team` also matches the `api-` prefix but is excluded.
- **Never direct-spawn the 15 `app-*-*` agents, the 6 infrastructure reviewers, or the 4 `utility-*`
  pairs** — they belong to `app-agent-team`, `tools-agent-team` and their dedicated skills respectively.
- **The 5 provider build skills are not this team's roster** — since the 2026-08-29 transfer,
  `api-providers-*-build-skill` is called by `app-agent-team`. Do not call them from an old memory.
  > ⚠️ `[Verified]` 2026-08-30 — **those five skills do not exist on disk**, nor do
  > `.claude/rules/api/` or `.claude/commands/api/`. The handoff direction above is still correct, but
  > the receiving team must report a provider path as **unroutable** rather than routing it. Do not
  > describe the transfer as though the skills were live.

## Invariant — scope boundary and handoffs

- **The scope is exactly three inbound (exposure) paths.**

  ```text
  app/src/ApiResource/**
  app/src/State/**
  app/config/{packages,routes}/api_platform.yaml
  ```

- **Every other path belongs to a sibling team without exception**, and when the call is unclear it
  goes to `app-agent-team`. Infrastructure, data and deployment assets belong to `tools-agent-team`.
- **A path containing `Service/Providers/` is an immediate handoff.** Provider and statistics-agency
  code alike goes to `app-agent-team`; never attempt to call a build skill here.
- **The domain logic and Doctrine layer behind what a State delegates to are out of scope** →
  `app-agent-team` (Doctrine mapping, queries and indexes themselves → `tools-agent-team`).
- **At most one `app-agent-team` delegation per invocation.** A nested orchestrator is the single most
  expensive spawn available — it runs its own budget and its own fan-out. Gather every non-exposure
  path into one delegation, and if more surfaces afterwards, report it as deferred rather than
  re-spawning.
  > **This consumes the last of the spawn-depth budget.** `main → api-agent-team (1) →
  > app-agent-team (2) → specialist (3)` fits the default cap of 3 with **zero headroom**, and at the
  > cap the `Agent` tool is withheld silently rather than erroring.
- **On a mixed change**, handle your own scope first and list the remainder under `## Handoffs`, by
  responsible team.
- **Never drop a routing-unmatched file silently** — state its path verbatim under `## Summary` in the
  consolidated report. A file handed to a sibling team is a **handoff**, not an unmatched file.

## Invariant — verification loop and artifacts

- **Build defaults to template ② (command-based self-verification)** — `api-platform-rest-build-skill`
  and `api-platform-oauth2-build-skill` edit per the `## Authoring Conventions` of the matching
  `*-build` command and judge per the same command's `## Self-verification`. When a third-party
  verdict is needed, spawn `api-platform-reviewer` as an additional gate.
- **The SoT for the authoring conventions is the two build commands.** The revived
  `api-platform-author` references them via `@see` rather than copying them — this constraint exists
  to stop the criteria becoming threefold, so never transcribe the conventions into the author's body.
- **An isolated author cannot hand off through the working tree.** `[Verified]` 2026-08-30:
  `api-platform-author`, `-analyzer`, `-debugger` and `-tester` all set `isolation: worktree`, so when
  a reviewer is spawned as an extra gate, **paste the author's full unified diff inline** into its
  prompt. `api-platform-reviewer` is the one non-isolated member and is therefore the only one able to
  read a shared tmp artifact.
- **The retry limit is 3** (a code domain). Past the limit, do not revert the source; stop as-is.
  **The orchestrator owns this counter.**
- **Never pass downstream to the tester while a `[MUST]` remains.**
- **The consolidated report is returned in the response; the tmp copy is best-effort.** The path,
  when written, is `./.claude/tmp/api/api-agent-team-report.md`. A `Write` there is **denied while the
  session is in plan mode** (inherited, since the orchestrator declares no `permissionMode`), and
  nothing reads the file — a refused write is a non-event and must never be reported as persisted.
  Never overwrite `tmp/app/**` or `tmp/tools/**`.

## Invariant — safety boundary

- **The orchestrator never modifies code directly.** `disallowedTools: Edit` enforces the
  no-modification half at the harness level; writes are confined to `./.claude/tmp/**`. Note that
  `Bash` is unrestricted and can write (redirection, `tee`, `sed -i`, `git apply`) — the same boundary
  covers all of those.
- **`api-platform-analyzer` is read-only** — it never fixes a vulnerability itself; the fix goes to
  `api-platform-author`. Its `disallowedTools: Edit, Write` enforces that at the harness level.
- **Never blur the timing difference between `security` and `securityPostDenormalize`** in an
  authorization verdict — ownership-transfer vulnerabilities arise from exactly that distinction. The
  detailed criteria are owned by `rules/api-platform-rule.md` (SoT).
- **API Platform security is a shared verdict** — `app-php-symfony-08-security-rule.md` is SoT for the
  underlying Symfony configuration (firewalls, Voters, `stateless` tokens, rate limiter), so that half
  is reached together with `app-agent-team`.
- Never include a secret, token or credential value in plaintext in any output.
- Never guess an unconfirmed path, service ID or `tr_id` — settle it against the real files before
  routing.

## Violation Severity

- **`[MUST]`** — direct-spawning outside the roster; the three teams spawning one another (the single
  Mode D delegation excepted); issuing more than one `app-agent-team` delegation per invocation;
  handling `Service/Providers/**` here; calling a provider build skill; granting the orchestrator
  `isolation: worktree`; **adding `isolation: worktree` to `api-platform-reviewer`**; routing a
  reviewer to a path instead of pasting the author's diff inline; trespassing on another team's tmp
  path; a missing spawn-payload field; assigning a tmp path to an agent that declares
  `disallowedTools: Write`; tallying unchecked as passed; issuing go while an axis is unjudged;
  failing to report a routing-unmatched file; exposing a secret.
- **`[SHOULD]`** — failing to spawn independent agents in parallel; failing to merge duplicate
  findings; failing to name the handoff team.
- **`[CONSIDER]`** — improvements that carry a structural change, such as rearranging a role axis or
  creating a new agent. Never apply without approval.

## Companion Updates

- `.claude/agents/api-agent-team.md` — execution directives (boundary table · routing table · checklist)
- `.claude/agent-memory/api-agent-team/MEMORY.md` — the always-loaded context summary
- `.claude/docs/api-agent-team-docs.md` — background · inventory · trade-offs
- The sibling teams' rules, agents and memory (`app-agent-team`, `tools-agent-team`) — a boundary is described from both sides
- `.claude/workflows/README.md` — per-role entry points
