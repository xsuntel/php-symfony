# Claude Code Config Artifacts — Detailed Reference (`.claude/**`)

This document provides the **frontmatter templates and structural examples** to consult when authoring
`.claude/**` config artifacts. The enforced judgment criteria are split across two SoTs; this document is
only their example edition and does not double as criteria — where they conflict, the SoTs below win.

- **Structure and placement SoT** → `.claude/rules/utility-claude-code-rule.md`
- **Spec, naming, tooling and convention SoT** → the body of `.claude/commands/utility-claude-code-review.md`

@see .claude/rules/utility-claude-code-rule.md — directory structure & placement criteria (SoT)
@see .claude/commands/utility-claude-code-review.md — per-type spec, naming, tooling & convention verdicts (SoT)
@see .claude/skills/utility-claude-code-skill/SKILL.md — authoring & recording orchestration entry point
@see .claude/rules/abstract-structure-rule.md — repository directory structure & rule index

---

## 1. Placement — Flat Single Tier + Hyphenated Taxonomy

Every artifact type under `.claude/**` sits in a **flat single tier directly beneath `.claude/<type>/`**.
The domain axis (`api` · `app` · `cache` · `database` · `message` · `server` · `tools` · `utility`) is
encoded as a **hyphenated prefix** rather than a directory, and one domain-plus-subject **shares the same
slug across every type**.

```text
rules/utility-shell-script-rule.md
commands/utility-shell-script-review.md
docs/utility-shell-script-docs.md
output-styles/utility-shell-script-style.md
skills/utility-shell-script-skill/SKILL.md
```

When a subdivision is needed, add another hyphen rather than digging a tier — `app`'s technical subjects
are `app-php-symfony-*` · `app-javascript-stimulus-*` · `app-twig-symfony-*`, and a numbered rule series
appends its number, as in `app-php-symfony-09-testing-rule.md`. A global artifact bound to no domain takes
the `abstract-` prefix (`abstract-structure-rule.md` · `abstract-korean-style.md`).

**The one structural exception is `api/**`** — the `api/` subtrees of `commands` · `docs` · `rules` ·
`skills` preserve their nesting in order to hold the external-provider taxonomy
(`providers/finance/{securities|digitalasset|agencies}/{provider}/`). `agents/api/**` and
`agent-memory/api/**` have not existed since 2026-08-15 — the 10 provider author/reviewer agents and
their never-loading memory were merged into the 5 `*-build` commands under `commands/api/**` (§6). The
criteria live in the structure rule SoT under `api domain structure preservation`.

Read the additional per-type constraints with **harness enforcement** and **project convention** kept
apart — a skill's `directory name = name` (§3.1) and the agent memory path computation (§6) are enforced
by the harness, whereas the suffixes and the shared slug are project convention.

## 2. Per-type Frontmatter Templates

The command body is the SoT for the criteria. What follows is only a minimal template matching the
convention.

**Sub-agent** (`.claude/agents/<name>.md` — flat single tier, no `api/**` exception)

```yaml
---
name: app-php-symfony-reviewer
description: "What it does + when it activates (including the trigger phrasing)."
model: sonnet        # sonnet | opus | haiku | fable | full model ID | inherit
memory: project      # optional; user | project | local
maxTurns: 30         # optional; requires Claude Code v2.1.246 or later
tools: Read, Grep, Glob, Bash   # least privilege only; inherits everything when omitted
---
```

The other optional keys are `disallowedTools` · `permissionMode` · `skills` · `effort` · `color` ·
`isolation` · `background` · `mcpServers` · `hooks` · `initialPrompt`.
`permissionMode` accepts `default` · `acceptEdits` · `auto` · `dontAsk` · `bypassPermissions` · `plan`
and `manual` (an alias for `default`). As of v2.1.218, frontmatter booleans accept `yes` · `no` · `on` ·
`off` · `1` · `0` (in any letter case) in addition to `true`/`false`.
`[Verified]` [WebFetch: https://code.claude.com/docs/en/subagents]

If `tools` contains typos such that **no entry resolves to a tool**, the harness names the unresolved
entries and **refuses to start the sub-agent at all** — an immediate failure, not a silent degradation.
`[Verified]` [WebFetch: https://code.claude.com/docs/en/subagents]
`isolation: worktree` hands the agent **an isolated copy branched from the default branch**, so do not
use it on an author or reviewer that hands off through `git diff` or a shared `.claude/tmp/**` filesystem
(the verdict belongs to the command SoT).

The tool that spawns a sub-agent is **`Agent`** — `Task` was renamed in CLI 2.1.63 and survives only as a
backward-compatibility alias. `[Verified]` [WebFetch: https://code.claude.com/docs/en/subagents]
The parenthesised allowlist form `tools: Agent(a, b)` applies only to a main-thread agent arriving via
`claude --agent`; **in a sub-agent definition the list inside the parentheses is ignored**, so this
repository's three orchestrators write bare `Agent` without parentheses.

**Skill** (`.claude/skills/<name>/SKILL.md`)

```yaml
---
name: utility-git-commit-skill   # lowercase/digits/hyphen, matches the directory name, `-skill` suffix, 1–64 chars
                                 # no leading or trailing hyphen, no consecutive hyphens (`--`)
description: 'What + when (natural-language trigger). 1–1024 chars, third person. Key use case first.'
---
```

**Wrap `description` in single quotes by default.** Without quoting, a **space followed by `#`** inside
the value is parsed as a YAML comment and **everything from that point to the end of the line is
discarded without an error** — which bites when a PHP 8 attribute (`#[ApiResource]` · `#[ORM\Column]` ·
`#[Target]`) appears in the trigger phrasing. Double quotes are not the answer either: they treat `\` as
an escape and break `#[ORM\Column]` again. The verdict follows the command SoT.

The upper bounds on `name` and `description` above are hard constraints set by the **Agent Skills
standard** (<https://agentskills.io/specification>). On top of the standard's six fields (`name` ·
`description` · `license` · `compatibility` · `metadata` · `allowed-tools`), Claude Code layers extension
fields (`when_to_use` · `argument-hint` · `arguments` · `disable-model-invocation` · `user-invocable` ·
`disallowed-tools` · `model` · `effort` · `context` · `agent` · `background` · `hooks` · `paths` ·
`shell`) and applies a looser listing-truncation threshold of 1,536 characters. This repository **holds to
the standard's limits** for portability.

A `description` survives from the front — with many skills installed, the listing budget
(`skillListingBudgetFraction` in `settings.json`) starts dropping whole descriptions beginning with the
least-used skills, so trigger phrasing placed at the end disappears first.

The budget defaults to **1%** of the context window, but that is not a fixed value — **this repository
runs `0.02` (2%)**, so do not judge budget overrun against the 1% figure.
`[Verified]` [Read: .claude/settings.json:9]

**Overrun is detectable without `/doctor`** — when the budget is exceeded the harness drops whole
descriptions starting from the least-used skills, so **an entry in the session's loaded skill listing that
carries only a `name` and no description** means you are over. Use `/doctor` when you want the cost
figures and the largest contributors.

**Measured baseline (2026-08-28):** 19 loaded skills = 6,525 chars, 28 commands = 3,147 chars, total
**9,672 chars**. The largest single entry is 424 chars, leaving 1,112 chars of headroom against the 1,536
limit. Every entry was confirmed via the listing to load together with its description.

> **A skill missing from the listing entirely is a discovery failure, not a budget problem.** Compare
> `find .claude/skills -name SKILL.md | wc -l` (the repository's actual count) against
> `ls -d .claude/skills/*/ | wc -l` (the count in the single-tier flat layout the harness discovers) — any
> difference is that many uninvocable skills, and raising the budget will not fix it. The criteria follow
> the command SoT.

**Slash command** (`.claude/commands/**/*.md`)

```yaml
---
description: "One line on what the command does."
argument-hint: "[file-path]"     # optional
allowed-tools: Read, Grep, Bash  # optional; hyphen notation, existing tool names only
---
```

Custom commands have been merged into skills, so `.claude/commands/**` also accepts the **full skill
frontmatter set** (`when_to_use` · `arguments` · `user-invocable` · `disallowed-tools` · `effort` ·
`context` · `agent` · `background` · `hooks` · `paths` · `shell` · `metadata`). The three keys above are
merely the ones this repository actually uses — they are not the extent of what is supported, so do not
misjudge the rest as "unsupported".
`[Verified]` [WebFetch: <https://code.claude.com/docs/en/skills>]

Use **`$ARGUMENTS`** as the argument placeholder in the body — it expands to the entire argument string as
entered. The positional form `$N` is **0-based**, so `$0` is the first argument and `$1` the second (a
shorthand for `$ARGUMENTS[N]`). Because custom commands were merged into skills, the same substitution
engine applies under `.claude/commands/**`, so writing `$1` in a single-argument command yields an empty
value and falls through to the "no argument" branch without an error. Every command in this repository
takes a single argument, so they standardise on `$ARGUMENTS`.
`[Verified]` [WebFetch: <https://code.claude.com/docs/en/skills> — "Available string substitutions"]

**When no placeholder receives an argument**, the harness appends `ARGUMENTS: <value>` to the end of the
body — the argument is not lost outright. But because it lands at the end, separated from the procedural
instructions, keeping the placeholder in position is preferable. When **explaining** a substitution token
in prose, block it with a backslash (`\$1`) — this works only with a single backslash immediately before
the token, and a doubled form such as `\\$1` does not escape.
`[Verified]` [WebFetch: <https://code.claude.com/docs/en/skills> — "Available string substitutions"]

**Rule** (`.claude/rules/**/*.md`)

```yaml
---
paths:
  - "app/src/**/*.php"
---
```

`paths` determines what the rule is auto-applied to, so it is mandatory for a domain rule — the sole
exemption is the index-like `rules/abstract-structure-rule.md` (the verdict belongs to the command SoT).

**Output style** (`.claude/output-styles/<name>.md` — flat single tier)

```yaml
---
name: app-php-symfony-style      # matches the file slug, unique within a session
description: "The domain this style applies to and its output conventions."
keep-coding-instructions: true   # keep the coding instructions
---
```

**settings/hooks** (`.claude/settings.json`) — valid JSON, and the `.claude/hooks/**` script that a hook's
`command` points at must exist and be executable.

**CLAUDE.md** — no frontmatter. Higher-level context and guidance only.

## 3. Naming for the Flat-tier Types (Hyphenated Taxonomy)

### 3.1 Skills

- Path: `.claude/skills/<name>/SKILL.md`, no nesting.
- Directory name = `name` (an Agent Skills standard constraint — but **the Claude Code harness does not
  enforce it**. A project skill's invocation name comes from the directory name and `name` is only a
  display label, so a mismatch merely splits the labelling, without an error. Because nothing enforces it,
  review is the only line of defence).
- The taxonomy is encoded as a hyphenated prefix rather than directories:
  `{domain}-{tier}-{subject}-{role}-skill`. For example:
  `api-providers-digitalasset-upbit-api-rest-client-skill`, `cache-redis-skill`.
- The `-skill` suffix is mandatory (a project convention; neither the standard nor the harness requires
  it) — every skill name ends in `-skill`. This is not mere notational distinction but a **namespace
  collision guard**: `.claude/commands/<name>.md` and `.claude/skills/<name>/` create the same `/` entry
  point, so a name clash silently masks one of them.
- If 64 characters is a risk (counted including the suffix), abbreviate by dropping classification
  sub-tiers (e.g. `finance` · `securities`), but keep the core axes (domain · `providers` · the provider
  identifier).
- When another artifact mentions a skill, reference it by the **full directory name**, not an
  abbreviation.

### 3.2 Output Styles

- Path: `.claude/output-styles/<name>.md`, no subdirectories.
- File slug = `name`. `outputStyle` in `settings.json` designates a style by this slug.
- The taxonomy is encoded as a hyphenated prefix: `{domain}-{subject}-style`. For example:
  `app-php-symfony-style`, `app-twig-symfony-style`, `utility-shell-script-style`.
- A global style bound to no domain takes the `abstract-` prefix: `abstract-korean-style` (the currently
  active style).
- The `-style` suffix is mandatory (a project convention) — it distinguishes the type by name from the
  other artifact types.
- **On a rename, update `settings.json`, the `@see` paths and the in-body slug references in the same
  change.** Miss any one of them and the style fails to resolve.

## 4. Common Mistakes (Verdicts Come From Comparing Against the SoT)

| Mistake | The correct direction |
| --- | --- |
| Digging a new domain directory outside `api/**` (`rules/cache/redis-rule.md`) | Flat + hyphenated (`rules/cache-redis-rule.md`) |
| Stripping the domain prefix from a slug (`commands/php-symfony-review.md`) | Keep the domain prefix (`commands/app-php-symfony-review.md`) |
| Renaming one type only, breaking another type's `@see` or `paths` | Update every related type in the same change |
| Flattening or hyphen-compressing the `api/**` tiers | Preserve the structure (no change without approval) |
| Skill `directory name ≠ name` / nested placement / missing `-skill` suffix / over 64 chars / consecutive hyphens (`--`) | Follow the skill-specific rules |
| Overly broad privileges or non-existent tool names in an agent's `tools` | Least privilege only, real tool names only |
| Copying or restating SoT criteria in the body (drift) | Reference the SoT with `@see`; do not restate |
| Referencing a non-existent rule, path, agent or skill | Confirm existence before referencing |
| Citing an SoT section number whose content does not match | Check that the cited section really says that |

## 5. Authoring Orchestration

Use the `utility-claude-code-skill` skill (an author-verify loop) for new work and modifications, and the
`/utility-claude-code-review` command to review an existing file's spec and convention compliance.

## 6. Agent Memory (`agent-memory/`)

An agent's frontmatter `memory:` value (`user` · `project` · `local`) sets the memory scope to auto-load.
The resolution path for `memory: project`, which this repository uses, is as follows.
`[Verified]` [Bash: CLI 2.1.220 symbols `Itr` · `sou`]

- The path is **`.claude/agent-memory/<sanitize(name)>/MEMORY.md`** — a **flat single tier**, as with
  skills.
- `sanitize` replaces every character matching `[^a-zA-Z0-9\-_]` with `-`. Since `/` is also replaced,
  **nesting directories does not produce a sub-path** (which is why mirroring the domain axis does not
  work here).
- The name it keys off is the frontmatter **`name`** value, not the filename.
- The index filename is fixed as `MEMORY.md`.
- Only the **first 200 lines or 25KB** of `MEMORY.md` is injected into the system prompt, so keep it
  concise enough that the essentials fall inside that window.
  `[Verified]` [WebFetch: https://code.claude.com/docs/en/subagents]

### `memory:` Defeats Tool Minimality

Declaring `memory:` makes the harness **grant `Read`, `Write` and `Edit` automatically, independent of the
`tools` list**, so that it can manage the memory file — and `disallowedTools` does not remove them.
`[Verified]` [WebFetch: https://code.claude.com/docs/en/subagents]

The effect is visible in this repository — 13 reviewer and analyzer agents that declare only
`tools: Read, Grep, Glob, Bash` also hold `Write` and `Edit` at runtime because of `memory: project`.
**All 25 agents declare `memory: project`, so no agent in this repository holds only the tools it
declares** — the 6 infrastructure reviewers (`cache-redis` · `database-postgresql` · `message-rabbitmq` ·
`server-nginx` · `tools-aws-ecs` · `tools-gcp-cloudrun`) are no exception.
`[Verified]` [Bash: `grep -l '^memory:' .claude/agents/*.md | wc -l` → 25]

Accordingly, **the absence of `Edit`/`Write` from the `tools` of a reviewer that declares `memory:` is not
a violation** — do not raise it in review. To actually block writes, drop `memory:` or control it through
`permissionMode` or `permissions.deny`. If `autoMemoryEnabled` in `settings.json` is `false`, `memory:`
itself becomes inert and the automatic grant disappears with it (this repository has it `true`).
`[Verified]` [Read: .claude/settings.json:3]

### Background — Why the Domain Axis Is Not Mirrored

The memory of the agents declaring `memory: project` was originally nested along the same domain axis as
the other artifact types (`agent-memory/app/...` · `agent-memory/api/providers/...`), which diverged from
the resolution path above, so it **never loaded even once.**

| Agent `name` | Path the harness reads | (old) nested location |
| --- | --- | --- |
| `app-php-symfony-reviewer` | `agent-memory/app-php-symfony-reviewer/` | `agent-memory/app/app-php-symfony-reviewer/` |

**Resolution — the current layout (unified as a flat single tier):**

- **25 auto-loading** — moved to the flat `agent-memory/<name>/MEMORY.md` tier and now loading correctly
  (`app-*` 15 · `api-platform-*` 5 · infrastructure reviewers 6 · `utility-git-commit-*` 2 ·
  `utility-drawio-diagram-*` 2 · orchestrators `app-agent-team` · `api-agent-team` 2).
  A new `## Agent memory specific rules` section was added to the structure rule SoT to fix this layout as
  criteria.

This failure happens **silently, without an error** — when the path is absent the harness simply proceeds
without memory. It therefore never surfaces unless a structure review catches it, which is why it is a
`[MUST]` finding.
