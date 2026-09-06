---
description: "Assesses spec and convention compliance of Claude Code config artifacts (agents, skills, commands, rules, output styles, settings, CLAUDE.md) and provides structured improvement recommendations."
argument-hint: "[path to one .claude config file — or empty / .claude/**/* for a tree-wide official-doc currency sweep]"
allowed-tools: Read, Grep, Glob, WebFetch(domain:code.claude.com), WebFetch(domain:platform.claude.com)
---

Analyze the following Claude Code config artifact:

**`$ARGUMENTS`**

## Pick the Mode First

The argument decides which of two modes runs. They share the criteria below but differ in target and in
how much of the official documentation gets re-fetched.

| Argument | Mode | What it covers |
| --- | --- | --- |
| A concrete path (`.claude/agents/app-php-symfony-reviewer.md`) | **A — Single artifact** | That one file, against the per-type criteria |
| Empty, `.claude/**`, `.claude/**/*`, or any whole-tree phrasing | **B — Doc currency sweep** | Every official-doc claim in this repository, re-verified against the live documentation |

**Mode A — single artifact.** Determine the target's **artifact type** from its path, cross-check it
against the per-type criteria below, flag violations with the **exact line number**, and provide concrete
fixes (improved snippets). Before starting, read **1–2 existing files of the same kind** under
`.claude/**` to establish the baseline for frontmatter, tone, and section structure — do not invent new
conventions. Re-fetch only the one or two official pages that govern that artifact type.

In Mode A, if the path matches none of the types below (e.g. `.claude/docs/**`,
`.claude/agent-memory/**`, `.claude/workflows/**`, `.claude/scripts/**`, `.claude/hooks/README.md`),
report that it is out of scope and stop — do not improvise criteria for it.

**Mode B — doc currency sweep.** Run the `## Official Documentation Currency` procedure below **before
judging anything**. Do not fall back to scanning all 180-odd files against every criterion; the target of
Mode B is the **set of claims about Claude Code**, not the set of files. The out-of-scope list above is
**narrowed, not lifted**, in this mode: `docs/`, `workflows/README.md`, `hooks/README.md` and
`settings.json` are checked **only for doc-derived factual claims** — never for artifact-spec criteria
that do not apply to them.

> **Note — responsibility split:** the **structural** criteria (directory taxonomy, path depth, file
> placement, and the flattening/move/rename prohibitions) are owned by
> `.claude/rules/utility-claude-code-rule.md`. Everything else — the **per-type frontmatter and
> body criteria** — is owned by **this command body + the official docs below**; this domain has no
> `output-styles/` SoT file (unlike the shell-script domain). Do not flag anything outside those two
> sources as a "violation" on the basis of general advice.
>
> **Note — `.claude/skills/**` is layout-exempt:** the skills tree is flat because Claude Code takes a
> skill's command name from its directory name. Never raise a finding that a skill sits at
> `.claude/skills/<name>/SKILL.md` instead of a nested taxonomy path. Do flag a directory name that
> breaks the `<domain>-<name>` convention, a `name:` that differs from the directory, or a
> reference to a skill path that no longer exists.

@see .claude/rules/utility-claude-code-rule.md — `.claude/**` structure immutability & allowed changes (SoT)
@see .claude/skills/utility-claude-code-skill/SKILL.md — artifact authoring & self-verification entry point
@see <https://code.claude.com/docs/en/subagents> — sub-agent frontmatter spec
@see <https://code.claude.com/docs/en/skills> — skill frontmatter reference & how a skill gets its command name
@see <https://code.claude.com/docs/en/memory> — `.claude/rules/` layout & `paths` path-specific rules
@see <https://code.claude.com/docs/en/output-styles> — output-style frontmatter & `outputStyle` selection
@see <https://code.claude.com/docs/en/hooks> — hook events & the hook JSON schema
@see <https://code.claude.com/docs/en/settings-reference> — `settings.json` key reference
@see <https://code.claude.com/docs/en/agent-teams> — teammate promotion & its effect on orchestration
@see <https://code.claude.com/docs/en/workflows> — dynamic workflows & the `.claude/workflows/` save target
@see <https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview> — Agent Skills spec (SKILL.md structure)
@see <https://platform.claude.com/docs/en/build-with-claude/skills-guide> — Skills API name/description constraints

## Official Documentation Currency

**The criteria below are a snapshot, and snapshots rot.** Every `[Verified] <date>` stamp in this file
records what a page said on that date, not what it says now. Treat a stamp older than today as
*unverified* — never as evidence. The 2026-08-29 sweep is the worked example: a canonical URL had moved,
`isolation: worktree` had changed its branch base, `.claude/workflows/` had become an official load
target, and enabling agent teams had acquired a documented failure mode for orchestrators. None of that
was discoverable without re-fetching.

**Mode B procedure — do this before applying any criterion.**

1. **Re-fetch every `@see` URL above** with WebFetch, in one parallel batch. Ask each page for the
   frontmatter/key reference it owns, plus its **canonical URL**.
2. **Record redirects.** A page that reports a canonical URL different from the one requested is a stale
   `@see`; fix it here and everywhere else it appears (`[MUST]`).
   > **Confirm a reported canonical by fetching it before you act on it.** `[Verified]` 2026-08-30: the
   > `hooks` and `settings-reference` pages both self-reported canonicals with the `/en/` segment
   > stripped (`…/docs/hooks-reference`), across two separate sweeps. Fetching that URL returns
   > **HTTP 404** — the `/en/` form is correct and the self-report was a summarisation artifact.
   > Rewriting the `@see` lines on the strength of it would have broken two live links. A genuine move
   > looks like `sub-agents` → `subagents`, which was verified by the new URL actually serving the page.
3. **Diff the live text against the claims in this file**, using the table below to find the dependents.
   Classify each difference:
   - **Fact changed** → correct the claim, re-stamp `[Verified]` with today's date, and propagate to
     every dependent listed.
   - **New optional key / new allowed value** → add it to the per-type table or detail rules, so a valid
     artifact using it is not flagged as an unknown key. This is the most common drift, and the most
     damaging: it produces confident false positives.
   - **Key or behaviour removed** → flag every artifact still relying on it as a `[MUST]`.
   - **No change** → re-stamp the date only if you actually re-read the page.
4. **Propagate before reporting.** A corrected claim that lives only in this file, while fifteen agents
   still assert the old one, is a half-fix — the 2026-08-29 sweep hit exactly this.

| Official page | Governs | Dependents to propagate to |
| --- | --- | --- |
| `sub-agents` | agent frontmatter set & allowed values · `memory` scopes · `isolation: worktree` semantics | the agent rows and detail rules here · `.claude/agents/*.md` · `.claude/docs/abstract-orchestrator-contract-docs.md` · `## Agent Memory Layout` in the structural rule |
| `skills` (Claude Code) | skill & command frontmatter · command-name resolution · description truncation | the skill/command rows here · `## Skill Directory Layout` in the structural rule · `.claude/skills/utility-claude-code-skill/SKILL.md` |
| `memory` | `.claude/rules/` discovery · `paths` globs · unconditional load without `paths` | the rule row here · the `†` footnote in `.claude/rules/abstract-structure-rule.md` |
| `output-styles` | style frontmatter · how `outputStyle` resolves a name | the output-style row here · `## Output Style Layout` in the structural rule · the `output-styles/` row in `CLAUDE.md` |
| `hooks` | the hook event list · the hook JSON schema & `type` variants | `.claude/hooks/README.md` (event table, schema keys) · `.claude/settings.json` |
| `settings-reference` | `settings.json` keys & allowed values | `.claude/settings.json` |
| `agent-teams` | teammate promotion of named subagents | the `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` rule here · `.claude/settings.json` · all three orchestrator agents |
| `workflows` | `.claude/workflows/` as a save target · script shape · limits | `.claude/workflows/README.md` · `CLAUDE.md` · the top-level-directory list in the structural rule · the reference table in `abstract-structure-rule.md` |
| Agent Skills spec · Skills API guide | packaging/upload constraints (name charset, reserved words, 1024-char description) | the skill detail rules here — **note these bind the upload path, not Claude Code project skills** |

**Two standing cautions.** Do not let a live doc override a deliberate **project convention** — the
convention sections below say which constraints are ours rather than the spec's, and a doc that relaxes a
rule we chose to keep is not a finding. And do not restructure anything on the strength of a doc change:
`## Refactoring Suggestions` still applies, so report the before/after and stop.

## Per-type Judgment Criteria

| Type | Target path | Required frontmatter | Body |
| --- | --- | --- | --- |
| Sub-agent | `.claude/agents/**/*.md` | `name`, `description` (optional: `model`, `tools`, `disallowedTools`, `memory`, `permissionMode`, `effort`, `skills`, `maxTurns`, `isolation`, `background`, `mcpServers`, `hooks`, `color`, `initialPrompt`, `experimental`) | role · procedure · I/O protocol · role boundaries |
| Skill | `.claude/skills/<domain>-<name>-skill/SKILL.md` (flat), or `.claude/skills/abstract-<name>-skill/SKILL.md` for a skill bound to no domain | `name` (lowercase·hyphen, matches the directory name), `description` (what + when/trigger) — **`name` is required by project convention, not by the spec**: Claude Code treats every skill field as optional and falls back to the directory name | operating guide |
| Slash command | `.claude/commands/**/*.md` | `description` (optional: `argument-hint`, `allowed-tools`, `model`, and the rest of the skill frontmatter set — see the command entry in the detail rules) | instructions using the full-argument variable (`\$ARGUMENTS`) or a positional argument (`\$0` is the first, `\$1` the second) |
| Rule | `.claude/rules/**/*.md` | `paths` (glob list) | judgment criteria (SoT) |
| Output style | `.claude/output-styles/*-style.md` (flat) | `name` (matches the file slug), `description` (optional: `keep-coding-instructions`, `force-for-plugin`) — **`name` is required by project convention**: officially it falls back to the file name when omitted | domain output & code-style guide |
| settings/hook | `.claude/settings.json`, `.claude/settings.local.json`, `.claude/hooks/**/*.sh` | (JSON) hook schema — n/a for a hook script | hook script: apply `.claude/output-styles/utility-shell-script-style.md` manually (an output style has no `paths` frontmatter, so it never auto-applies to a file) |
| CLAUDE.md | `CLAUDE.md` or a subordinate one | — | higher-level context & guidance |

### Frontmatter Detail Rules (official spec)

- **Agent `model`**: one of `sonnet` | `opus` | `haiku` | `fable` | `inherit`, or a full model ID (e.g. `claude-opus-5`). Defaults to `inherit` when omitted. `tools` lists **only the least privilege** (inherits all when omitted).
- **Agent `tools` / `disallowedTools` — two accepted shapes, and a new entry form.** `[Verified]` 2026-09-02 [WebFetch: <https://code.claude.com/docs/en/subagents>]: both are now documented as **arrays**, and `tools` additionally accepts an **`Agent(subagent-name)` allowlist entry** that restricts which subagents this agent may spawn. All 33 agents here use the comma-separated string form and all 33 resolve, so **the comma form still works and is not a finding** — but do not flag the YAML-list form or an `Agent(...)` entry as invalid either. An `Agent(...)` allowlist is the precise way to express an orchestrator's closed roster, which the `agent-roster-guard.sh` hook currently enforces at runtime instead.
- **Agent `experimental`**: an object; supports `cacheTtl: 5m | 1h` (prompt-cache lifetime). `[Verified]` 2026-09-02. No agent here sets it — do not flag its absence, nor flag it as unknown if added.
- **Agent `memory`**: `user` | `project` | `local`. This project uses `memory: project`, which pairs the agent with **`.claude/agent-memory/<agent-name>/MEMORY.md`** — a **flat** path keyed by the frontmatter `name`, with no domain/tier segment (Claude Code resolves it that way; see the exemption section in the structural SoT). Do not flag it as an unknown key, and **do** flag a memory directory that sits under a domain tier or whose name differs from the agent's `name` — it silently never loads.
- **Agent `permissionMode`**: official (`default` | `acceptEdits` | `auto` | `dontAsk` | `bypassPermissions` | `plan` | `manual`), and a project convention as of 2026-08-25. The **14 write-path agents** — the 6 `*-author`, 4 `*-tester` and 4 `*-debugger` — set `permissionMode: acceptEdits`. The reason is that subagents inherit the parent session's permission mode and `settings.json` sets `permissions.defaultMode: "plan"`, under which an author's edits and a tester's Green phase are refused; the frontmatter override is what makes those roles executable at all. Do not flag it as an unknown key, and **do** flag its absence on a write-path agent as a `[SHOULD]`. The read-only agents (4 `*-analyzer`, 12 `*-reviewer`) deliberately omit it — they must not acquire edit acceptance — and **the three orchestrators (`app-agent-team`, `api-agent-team`, `tools-agent-team`) omit it** because they orchestrate rather than edit. `[Verified]` 2026-08-30 — 14 + 4 + 12 + 3 accounts for all **33** agents on disk; the count moved 32 → 33 when `tools-agent-team` was added.

  > **The orchestrators' omission has a cost, and it is deliberate.** All three hold `Write` and are told to persist a consolidated report under `.claude/tmp/<team>/`, but with no `permissionMode` they inherit the session's mode, and `permissions.defaultMode` is `"plan"` — a read-only mode — so that write is **refused while the session is in plan mode**. `[Verified]` 2026-08-30. The resolution taken on 2026-08-30 was **not** to grant them `acceptEdits` (that would auto-approve writes by agents that also hold unrestricted `Bash` and scope `Write` by prose alone) but to make the **returned report the required channel** and the tmp copy best-effort — nothing in this repository reads those tmp files. **Do not flag the missing `permissionMode` on an orchestrator as a `[SHOULD]`**, and **do** flag as a `[MUST]` any orchestrator that reports a tmp path as written when the write was refused, retries a refused write, or reaches for `Bash` redirection to defeat the permission mode. The earlier reading of this bullet ("12 write-path … 4 `*-author` … 10 `*-reviewer`") summed to 28 because it counted only the four code domains and silently dropped the `utility-drawio-diagram-*` and `utility-git-commit-*` pairs; the `isolation` bullet below has always accounted for all 32, so that is the arithmetic to trust. Note that the two `utility-*-reviewer` agents carry `Write` (with `disallowedTools: Edit`) yet are counted read-only: their role is to return a PASS/REDO verdict, not to author, so they stay without `acceptEdits`.
- **Agent `effort` / `color` / `background`**: all official. `effort` is one of `low` | `medium` | `high` | `xhigh` | `max` (available levels depend on the model); `color` is one of `red` | `blue` | `green` | `yellow` | `purple` | `orange` | `pink` | `cyan`; `background: true` keeps the subagent in the background even when Claude asks for the foreground. `[Verified]` 2026-08-30 — **exactly one agent sets any of the three**: `tools-agent-team` carries `color: orange`; no agent sets `effort` or `background`. Do not flag their absence, do not flag them as unknown keys if one is added, and **do not flag the lone `color` as an inconsistency** — a display colour on one agent and not its siblings is cosmetic, not a convention breach. (This bullet read "No agent here sets any of the three" until 2026-08-30, which stopped being true when `tools-agent-team` was created.)
- **Agent `isolation` / `maxTurns`**: both official and both project conventions — every agent here sets `maxTurns` (30, **45 for the 4 `*-tester`** whose Red-Green-Refactor cycle runs six or more gate commands per invocation, 50 for each of `app-agent-team` and `api-agent-team`, and **40 for `tools-agent-team`** — its single Review axis runs one fan-out plus consolidation with no author→reviewer loop to fund, so do not flag the lower value as a deviation), and the 19 domain agents scoped to `app/**` sources set `isolation: worktree` (the 15 `app-*` agents plus `api-platform-analyzer`, `api-platform-author`, `api-platform-debugger`, `api-platform-tester`). The convention follows the **agent's domain scope, not whether it writes**: `app-php-symfony-analyzer` and `api-platform-analyzer` are read-only (`tools: Read, Grep, Glob, Bash`, `disallowedTools: Edit, Write`) yet still carry `isolation: worktree`, so do not flag a read-only agent's worktree isolation as inconsistent. Do not flag either key as unknown. The omissions are deliberate: **the three orchestrators (`app-agent-team`, `api-agent-team`, `tools-agent-team`) orchestrate rather than edit**, `api-platform-reviewer` and the six infrastructure reviewers (`cache-redis-reviewer`, `database-postgresql-reviewer`, `message-rabbitmq-reviewer`, `server-nginx-reviewer`, `tools-aws-ecs-reviewer`, `tools-gcp-cloudrun-reviewer`) are read-only reviewers outside that scope, and the `utility-git-commit-*` pair **must** see the real working tree (`git diff --cached`) — flag an added `isolation: worktree` on those two as a `[MUST]`. `api-platform-reviewer` is the same case for a different reason: it is the only non-isolated member of its own domain roster, which is what lets it read a tmp artifact the other four cannot — flag an added `isolation: worktree` there as a `[MUST]` too. The `utility-drawio-diagram-author` / `utility-drawio-diagram-reviewer` pair is likewise omitted by design: the author reads real `diagram/**` files to learn existing conventions, and both write only under `.claude/tmp/`. Those **14** omissions plus the 19 above account for all **33** agents. `[Verified]` 2026-08-30 — the count moved 31 → 32 when `agent-team` was split into `app-agent-team` and `api-agent-team`, then 32 → 33 when `tools-agent-team` was added; the **specialist** count is unchanged at 30.
- **Consequence of `isolation: worktree` — do not "fix" the handoff back to `git diff`.** `[Verified]` 2026-08-30 [WebFetch: <https://code.claude.com/docs/en/subagents>]: the worktree is branched **by default from the repository's default branch rather than the parent session's `HEAD`**, and holds **tracked content only** — so an isolated agent sees neither a sibling agent's uncommitted work nor `.claude/tmp/` (gitignored).
  > **New on 2026-08-30 — isolation can be imposed from above, so "no `isolation` key" does not guarantee a shared tree.** The live page adds: "When the main conversation runs isolated in a worktree, the same checks apply to every subagent, **including those without `isolation: worktree`**." Every claim in this repository that a non-isolated agent "shares the working tree" (the six infrastructure reviewers, `api-platform-reviewer`, the four `utility-*` agents) therefore holds **only when the main session is not itself worktree-isolated**. Do not flag those claims as wrong — they describe the normal case — but do not treat a missing `isolation` key as a guarantee either, and never let a tmp-path handoff be the *only* channel when the session might be isolated. (This bullet previously said "checked out from HEAD"; the corrected base makes the isolation stronger, not weaker, so every consequence below still stands.) Two consequences are now written into the agents and are correct: the 4 `*-author` agents hand off by **inlining the full `git diff` text in their returned report** rather than leaving it in the working tree, and vendor-dependent gates (`php-cs-fixer`, `phpstan`, `phpunit`, `bin/console`) are unrunnable in a worktree unless the agent installs dependencies there. Flag any edit that reverts an author to "the reviewer reads the same diff" as a `[MUST]`.
- **Subagent nesting depth — the constraint the orchestrators spend.** `[Verified]` 2026-08-30 [WebFetch: <https://code.claude.com/docs/en/subagents>]: nesting is capped at **3 layers below the main conversation** by default (v2.1.219+; v2.1.172–216 allowed 5, v2.1.217–218 allowed 1), configurable with `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH`. **At the cap the `Agent` tool is withheld rather than erroring** — the agent silently does the work itself and returns one summary — **except for forks, which do error**. A separate cap of **20 concurrent subagents** applies (`CLAUDE_CODE_MAX_CONCURRENT_SUBAGENTS`); exceeding it fails the spawn with `Concurrent subagent limit reached`, background forks (`/subtask`), resumed subagents and every spawned subagent count toward it, and **sessions running ultracode** bypass it (`[Verified]` 2026-09-02 — the live page exempts ultracode only; this bullet read "ultracode/max effort" until then, and max effort is *not* exempt). This binds `api-agent-team`, which delegates to `app-agent-team`, which routes to a specialist: `main → api-agent-team (1) → app-agent-team (2) → specialist (3)` fits with **zero headroom**. `tools-agent-team` does not lengthen that chain — it spawns no orchestrator, so `main → tools-agent-team (1) → reviewer (2)` keeps one layer spare. Flag as a `[MUST]` any edit that adds a fourth nesting layer, or that lowers `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH` below 3 without removing the delegation. Neither variable is set in `settings.json` today, so the default 3 applies. Omitting `Agent` from `tools`, or listing it in `disallowedTools`, is the documented way to stop a given agent nesting at all.
- **Rule `paths` — glob semantics, and two ways a pattern silently matches nothing.** `[Verified]` 2026-09-02 [WebFetch: <https://code.claude.com/docs/en/memory>]. Brace expansion is supported (`src/**/*.{ts,tsx}`), but **a rule's whole `paths` list shares one budget of 1,000 expanded patterns and 4 MiB**; a pattern that would exceed it is used **unexpanded**, so its literal braces match no files. Each brace group multiplies: `{a,b}/{c,d}/*.{ts,tsx}` is already 8. **Patterns without braces do not count against the budget at all** (added to the live page by 2026-09-02), so a long brace-free list is never at risk — only brace-heavy patterns are. Separately, glob treats `[` as opening a bracket expression — a pattern like `photos [2024/**` is **invalid and matches nothing**, while the rule's other patterns keep working; escape it as `photos \[2024/**`. Flag either shape as a `[MUST]`, because both fail silently: the rule loads, matches no file, and its criteria are never applied. (Version notes, for older checkouts: before v2.1.217 a many-brace `paths` stalled or crashed the CLI at startup, and before v2.1.207 one invalid pattern made the Read tool fail for *every* file the rule was evaluated against.)
- **Skill `name`**: lowercase/digits/hyphen only, ≤ 64 chars, matches the directory name. The directory name is the flat taxonomy encoding `<domain>-<name>-skill` (see the structural rule) — for a project skill `name` is only a display label, so the directory is what `/…` invocation actually uses. The **`-skill` suffix is mandatory**; a directory (and therefore `name`) missing it is a `[MUST]` finding.
- **Skill prefix — `abstract-` is permitted and is not a taxonomy violation.** `[Verified]` 2026-09-06: three skills carry it (`abstract-harness-engineering-skill`, `abstract-loop-engineering-skill`, `abstract-graph-engineering-skill`), on exactly the footing that lets `abstract-structure-rule.md` and `abstract-*-style.md` skip a domain prefix — the skill is bound to no domain. **Do not flag the prefix**, and do not flag the missing `rule + docs + reviewer-agent` quartet: they are design skills that hold no criteria and reference the existing SoTs by `@see`, so a quartet member would duplicate an owned criterion. **Do** flag a missing `-skill` suffix, a `name` diverging from the directory, or an `abstract-` prefix on a skill that plainly belongs to one domain.
- **Which skill constraints come from where — do not conflate them.** The ≤ 64-char limit, the character set and the **reserved words (`anthropic`, `claude`)** are requirements of the **Agent Skills spec and the Skills API**, i.e. the packaging and upload path (`package_skill.py`, claude.ai, `/v1/skills`). `[Verified]` 2026-08-30 [WebFetch: <https://platform.claude.com/docs/en/build-with-claude/skills-guide>]. **Claude Code does not enforce them on a project skill**, which is why `utility-claude-code-skill` legitimately carries a reserved word in its own name — never raise that as a finding. Do flag it as a `[SHOULD]` only if a skill is being prepared for upload/packaging.
- **Skill `description`**: ≤ 1024 chars per the Skills API spec above, stating "what it does + when it triggers" in the third person (include the natural-language trigger phrasing). Separately, **Claude Code truncates `description` plus `when_to_use` at 1,536 characters** in the skill listing, so put the key use case first. `[Verified]` 2026-09-02 — that cap is **configurable** via the `skillListingMaxDescChars` setting, and the listing budget itself via `skillListingBudgetFraction`; treat 1,536 as the default, not a hard limit. **Correction, 2026-09-06 — this bullet read "(this repository runs `0.02`)", which was wrong.** Neither `settings.json` nor `settings.local.json` sets `skillListingBudgetFraction`, so the harness default applies and the repository has no measured local value. Do not cite `0.02` as this project's setting, and do not flag the key's absence — it is unset deliberately. Note the spec marks `description` **"Recommended", not required** (it falls back to the first paragraph of the body); this project requires it by convention, and a doc that relaxes a rule we chose to keep is **not** a finding.
- **Command frontmatter — commands are skills now, with two exceptions.** `[Verified]` 2026-09-02 [WebFetch: <https://code.claude.com/docs/en/skills>]: "Custom commands have been merged into skills. A file at `.claude/commands/deploy.md` and a skill at `.claude/skills/deploy/SKILL.md` both create `/deploy` and work the same way." A command file accepts nearly the full skill frontmatter set — beyond `description` / `argument-hint` / `allowed-tools` / `model`, that includes `when_to_use`, `disable-model-invocation`, `user-invocable`, `disallowed-tools`, `effort`, `context` (`fork`), `agent`, `background`, `hooks`, `shell`, `metadata`. Do **not** flag any of these as an unknown key on a command or a skill.

  > ⚠️ **`name` and `paths` are the exceptions — Claude Code *ignores* both in a command file.** The live page: "Files in `.claude/commands/` support the same frontmatter, **except `name` and `paths`, which Claude Code ignores in a command file**. You invoke a command file by its file name." This bullet listed `paths` as accepted until 2026-09-02, which would have blessed a key that silently does nothing — a `paths`-scoped command does **not** become path-triggered. Flag a `paths` or `name` key on a command as a `[SHOULD]` dead key, and point to converting it to a skill (`.claude/skills/<name>/SKILL.md`) if path-scoped auto-activation is actually wanted, since `paths` *is* live there.
- **Command `allowed-tools`**: hyphen notation. Do not include a tool name that does not exist.
- **`settings.json` — `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` must stay `"0"`.** `[Verified]` 2026-09-02 [WebFetch: <https://code.claude.com/docs/en/agent-teams>]. The premise still holds — "while agent teams are enabled, a subagent that Claude **names** launches as a teammate, so teams can form even when you didn't ask for one" — but **the stated reason has been corrected**, see the box below. The operative reasons are now:
  - **"No nested teams: teammates cannot spawn their own teammates."** This is decisive here: all three orchestrators (`app-agent-team`, `api-agent-team`, `tools-agent-team`) exist to spawn other agents, and `api-agent-team` additionally spawns `app-agent-team` as its one cross-boundary delegation. Promoted to teammates, that whole routing layer stops working.
  - **"No background subagents from in-process teammates"** — Claude Code errors when a teammate spawns a subagent whose definition sets `background: true`.
  - Teammates carry a **higher token cost** (each is a full Claude Code session) for orchestration that only needs a returned report.

  It was `"1"` until 2026-08-29. Flag any edit back to `"1"` as a `[MUST]` unless the orchestration layer is first rewritten to stop nesting.

  **Two scope notes re-confirmed 2026-09-02.** Teammates are never spawned in **non-interactive (`-p`) or Agent SDK sessions** — a named subagent runs as an ordinary subagent there even with teams enabled, so headless runs are unaffected either way. And the `"0"` here lives in **project** settings: per the live page, a user-level `"0"` overrides a shell export, but project, local and `--settings` layers apply *after* user settings, so this project value wins over a user-level `"1"`. That ordering is what makes the setting reliable here.

- **`settings.json` — commit attribution is controlled by `attribution`, not `includeCoAuthoredBy`.** `[Verified]` 2026-09-02 [WebFetch: <https://code.claude.com/docs/en/settings-reference>]. `attribution` is an **object** with three optional sub-keys: `commit` (string; `""` hides the commit trailer), `pr` (string; `""` hides the PR attribution line) and `sessionUrl` (boolean, default `true`; `false` omits the claude.ai session link from cloud and Remote Control commits). The deprecated `includeCoAuthoredBy: false` maps to exactly **`attribution.commit: ""`**.

  **Migrated on 2026-08-30.** This repository now sets `"attribution": { "commit": "" }` and no longer carries `includeCoAuthoredBy`; `pr` and `sessionUrl` were deliberately left at their defaults, because the documented mapping covers the commit trailer only and widening it would change behaviour the old key never governed. The three artifacts that cite the setting as the reason no `Co-authored-by` trailer is written (`abstract-english-style.md`, `abstract-korean-style.md`, `utility-git-commit-style.md`) were updated in the same change. **Flag a re-introduced `includeCoAuthoredBy` as a `[SHOULD]` dead key**, and flag any artifact still citing it as the live control as a `[SHOULD]` stale reference.

  Two neighbouring keys, recorded so neither is mistaken for a live control: **`teammateDefaultModel` was removed in v2.1.234** and a leftover value is ignored — flag it as a `[SHOULD]` dead key if it appears, and point to `CLAUDE_CODE_SUBAGENT_MODEL` or a model named in the spawn prompt instead. **`teammateMode`** (`in-process` | `auto` | `tmux` | `iterm2`, default `in-process`) is the live display-mode setting and is *not* what enables teams. Neither key is set in this repository. `[Verified]` 2026-08-30

  > ⚠️ **Correction — the earlier reading of this bullet was wrong on the mechanism.** It asserted that "a teammate returns only an idle notification", quoting *"the notification doesn't carry the teammate's output"* and *"an orchestration flow that waits on subagent results can stall"*. **Neither phrase appears on the live page**, and the current text says the opposite: "when a teammate finishes and stops, it automatically notifies the lead and **includes its final answer in the notification**", plus "Claude receives each subagent's result when it completes." Do **not** flag an agent for "awaiting a teammate's report" on the strength of the retired claim — that would be a confident false positive of exactly the kind this section warns about. The `"0"` verdict is unchanged; only its justification is.
- **Output style `name`**: matches the file slug. The tree is **flat** and the slug encodes the taxonomy as `<domain>-<name>-style` (see the exemption section in the structural SoT) — flag a style placed under a domain directory, or one whose `name` differs from its file slug. Be precise about the mechanism: `settings.json` (`outputStyle`) resolves a style **by its name, and the name falls back to the file name only when `name:` is absent** `[Verified]` 2026-08-30 [WebFetch: <https://code.claude.com/docs/en/output-styles>]. Keeping `name` equal to the slug is what makes the two interchangeable here — it is a project convention that removes the ambiguity, not a restatement of the resolver. To avoid overriding the coding instructions, set `keep-coding-instructions: true` (the existing-style convention). `force-for-plugin` is plugin-only and overrides the user's `outputStyle`; it has no use in a project style here.

  **There is no `/output-style` command — do not tell a user to run one.** It was deprecated in v2.1.73 and **removed in v2.1.91**; selection is `/config` → **Output style**, or editing `outputStyle` in a settings file directly. `[Verified]` 2026-08-30 [WebFetch: <https://code.claude.com/docs/en/output-styles>]. Flag any artifact instructing the user to run `/output-style` as a `[MUST]` — it is an instruction to type a command that no longer exists, the same class of defect as a stale `/domain:name` slash-command reference.

## Review Procedure

Cross-check the items below in order.

- **Doc currency (first, and mandatory in Mode B)** — has every official page that governs the target been re-fetched **today**? Is every `@see` URL still canonical, and every `[Verified]` claim still what the page says? A criterion applied from a stale snapshot is worse than no criterion, because it produces a confident false positive.
- **Frontmatter validity** — is it valid YAML wrapped in `---`, with the required keys present per type? For settings/hooks, is it valid JSON conforming to the hook schema?
- **Naming & path** — do the filename and directory conventions match the same-kind file (skill `name` = directory name **and ends with `-skill`**, command invocation name = path slug)?
- **Tool minimality** — no unnecessarily broad `tools`/`allowed-tools`, and **no non-existent tool name**?
- **Convention agreement** — does it follow the documentation language (**English**, per `CLAUDE.md`; the conversation language is set separately by the active output style), the `@see` SoT reference style, and the tone/section structure of the same-kind file? Does it avoid drift by duplicating or restating criteria owned by an SoT?
- **Factuality** — does the body avoid referencing non-existent rules, paths, agents, skills, commands, or tools (verify that referenced paths actually exist)?
- **Role boundaries** — for an agent or skill, are the upstream/downstream, orchestrator, and output paths stated, and do they match the actual caller?
- **Structure immutability** — does the file sit at its taxonomy-conforming **flat** path (one tier per tree, with the domain as a hyphenated filename prefix), with no re-nesting, move, rename, merge, or split relative to its siblings of the same kind? See the structure SoT referenced above.

## Output Format

### Official Doc Currency

Mode B must open with this table; Mode A includes only the rows it re-fetched. State the fetch date, and
never list a page as `current` on the strength of an existing `[Verified]` stamp alone.

| Official page | Re-fetched | URL still canonical | Drift found | Dependents updated |
| --- | --- | --- | --- | --- |
| sub-agents | | | | |
| skills | | | | |
| memory | | | | |
| output-styles | | | | |
| hooks | | | | |
| settings-reference | | | | |
| agent-teams | | | | |
| workflows | | | | |
| Agent Skills / Skills API | | | | |

### Summary

| Category | Status (OK / WARN / FAIL) | Issue count |
| --- | --- | --- |
| Official doc currency | | |
| Frontmatter validity | | |
| Per-type required keys | | |
| Naming & path conventions | | |
| Tool minimality | | |
| Project convention agreement | | |
| Reference factuality | | |
| Role boundaries & hand-off | | |
| Structure immutability | | |

### Official Doc Synchronization

Report the step-0 result first. With no drift, close it in a single line:
`canonical sources re-fetched — no drift (verification dates refreshed only)`. With drift, list it item
by item:

- **[Line N]** `canonical value` ← `the value in this file` — before/after, together with which canonical
  source and which section of it confirmed the change.
- List link-liveness results for **non-200 responses only**, and rule a link broken only after three
  retries have all failed.
- State explicitly whether this run updated the command body or its snapshots — never change a verdict
  without making the corresponding update.

### Critical Issues (must fix)

For each issue: **[Line N]** `[MUST]` description → recommended fix including a code snippet.

### Improvement Suggestions (recommended)

For each suggestion: **[Line N]** `[SHOULD]` description → recommended approach.

### Refactoring Suggestions

Mark structural changes (section reordering, moving duplicated criteria to their SoT, converting the
artifact type, etc.) as `[CONSIDER]` and describe them with before/after examples. Only `[MUST]` blocks a merge.

A `[CONSIDER]` note is a **suggestion, never an authorization**: relocating, renaming, merging, or
flattening any file or directory under `.claude/**` requires an explicit user instruction. Report the
before/after paths and stop there — do not perform the move as part of the review.
