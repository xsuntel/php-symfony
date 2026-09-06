---
paths:
  - ".claude/*.md"
  - ".claude/*.json"
  - ".claude/**/*.md"
  - ".claude/**/*.json"
  - ".claude/**/*.sh"
---

# Claude Code Config Rules (`.claude/**`)

This rule is the judgment criteria (SoT) for the **physical layout of the `.claude/` tree** — its
directory taxonomy, path depth, and file placement.

**Responsibility split (no duplication):** the per-type frontmatter and body criteria
(agent · skill · command · rule · output style · settings · CLAUDE.md) are owned by the review command
below; this rule does not restate them. It owns only the structural criteria.

@see .claude/commands/utility-claude-code-review.md — per-type frontmatter & verification checklist (SoT)
@see .claude/skills/utility-claude-code-skill/SKILL.md — artifact authoring & self-verification entry point
@see .claude/rules/abstract-structure-rule.md — repository directory structure & rule index
@see CLAUDE.md — the ``## Claude Code Tooling (`.claude/`)`` subdirectory table

## Prohibitions — Structure Immutability (non-negotiable)

Structural reorganization of `.claude/**` is forbidden unless the user **explicitly instructs it in the
current request**. "Cleanup", "consistency", "simplification", a refactoring suggestion, or a review
finding is **not** sufficient grounds.

**Every artifact tree is flat.** As of 2026-08-15 all seven — `rules/`, `docs/`, `skills/`, `commands/`,
`agents/`, `agent-memory/`, `output-styles/` — are a **single tier** that encodes the domain taxonomy as
a hyphenated filename prefix (`<domain>-<name>-<kind>.md`). The only directories that remain are
`.claude/skills/<name>/`, `.claude/agent-memory/<name>/` (each artifact's own container), and the
per-event `.claude/hooks/<event>/` directories. Be precise about that last one: `settings.json`
references every hook script by explicit path, so nothing in the hook spec resolves these directory
names — the layout is a **project convention owned by `.claude/hooks/README.md`**, not a spec
requirement. `sub-agent-start/` is the proof: the official event is `SubagentStart`, whose kebab form
would be `subagent-start`. Do not justify the layout as a resolver requirement, the same way
`## Docs Layout` does not.

Per-tree naming criteria live in the sections below: `## Rules Layout`, `## Docs Layout`,
`## Skill Directory Layout`, `## Commands Layout`, `## Agents Layout`, `## Agent Memory Layout`,
`## Output Style Layout`.

Six of the seven are flat **by necessity** — Claude Code resolves the artifact's identity from the file
or directory name itself (skill command, agent `name`, memory key, output-style slug, slash-command
name), so no domain tier can be imposed on them. `rules/` and `docs/` are flat **by convention**, for
consistency with the rest; their sections explain why that distinction still matters.

**History — the `-config` / `-gate` segment was dropped on 2026-08-19**, by explicit user instruction,
in two steps within one session. First the seven skill directories lost it
(`cache-redis-config-skill` → `cache-redis-skill`, `tools-app-deploy-gate-skill` →
`tools-app-deploy-skill`, …), which also retired the `<tier>` slot from the skill naming convention.
Then, to remove the cross-tree asymmetry that first step created, the same segment was dropped from the
six infrastructure domains in `rules/`, `agents/`, `commands/`, `docs/`, and `agent-memory/`
(`cache-redis-config-rule.md` → `cache-redis-rule.md`, `server-nginx-config-reviewer` →
`server-nginx-reviewer`, `/message-rabbitmq-config-review` → `/message-rabbitmq-review`, …). Every
domain artifact now reads `<domain>-<name>-<kind>` with no tier word. Two consequences to keep in mind:
the four `*-review` slash commands are **user-facing invocations that changed**, and the six reviewer
agents' `name` + `agent-memory/` directory moved together — the paired move is what kept the memories
from orphaning. `app-php-symfony-02-configuration-rule.md` is unrelated and keeps its name.

**Carve-out — the `api` domain is frozen.** See `## API Domain — Layout Freeze`.

- **Never re-introduce a directory tier.** Flat is the structure, not a transitional state. Do not
  "restore" `rules/app/php-symfony/01-architecture-rule.md` from
  `rules/app-php-symfony-01-architecture-rule.md`, and do not group files into a new `base/`, `cloud/`,
  or `agent/` subdirectory.
- **Never move, rename, or merge an existing file or directory** — no `mv` / `git mv`, and no
  Write-to-new-path followed by deleting the old path. In a flat tree the filename _is_ the identifier,
  so a rename is an interface change; see each tree's section for what must move with it.
- **Never merge a numbered rule series** (`00~15-*-rule.md`) into a single file, and never split one
  file across several.
- **Never delete a directory**, including the empty scaffolds — the `.gitkeep` placeholders under
  `.claude/hooks/**` are deliberate.
- **Never break a rule↔docs pairing.** Every domain rule has a `-docs.md` counterpart; adding, removing,
  or renaming one without the paired change to the other is a structure change. Both trees are now flat,
  so the two pair by **slug** and the slugs must stay aligned:
  `app-php-symfony-*-rule.md` ↔ `app-php-symfony-docs.md`.
- **Never add a new top-level directory** under `.claude/`. The 10 directories in the CLAUDE.md table
  (`rules`, `docs`, `skills`, `commands`, `agents`, `agent-memory`, `output-styles`, `hooks`, `scripts`,
  `workflows`) are the complete committed set; the gitignored `tmp/` below is the only permitted
  addition.
  > `workflows/` is the one entry Claude Code writes to on its own. `[Verified]` 2026-08-29
  > [WebFetch: <https://code.claude.com/docs/en/workflows>] — saving a dynamic workflow run writes a
  > JavaScript file into `.claude/workflows/`, which then runs as `/<name>`. So a new file appearing
  > there is **normal harness operation, not a structure violation**, and the reference-only
  > `README.md` this repository keeps there simply coexists with it. See `.claude/workflows/README.md`.

**Exception — `.claude/tmp/**`:** the gitignored runtime scratch tree that author/reviewer agents create
on demand is exempt from all of the above. Creating and overwriting paths under it is normal operation —
`mkdir -p` the **full parent** of the target file, not just `.claude/tmp` (a nested draft path such as
`.claude/tmp/utility/git/` needs the whole chain, or a Bash write fails). Removal is not part of the
exemption: `settings.json` denies `Bash(rm:*)` outright and a deny rule outranks any allow, so the
`cleanupPeriodDays` retention and `.gitignore` coverage are what keep the tree from accumulating.

## Rules Layout

`.claude/rules/**` is a **single flat tier**, flattened on 2026-08-15 — the last tree to be. Nothing in
Claude Code resolves a rule by path: a rule is auto-applied when an edited file matches its `paths`
frontmatter glob, and is otherwise reached via `@see`. So, like `docs/`, this tree is flat **by
convention** rather than necessity — adopted so that all seven artifact trees name themselves the same
way.

**That "not necessity" is now positively evidenced, not merely inferred.** `[Verified]` 2026-08-29
[WebFetch: <https://code.claude.com/docs/en/memory>]: "All `.md` files are discovered **recursively**,
so you can organize rules into subdirectories like `frontend/` or `backend/`." A nested
`rules/app/php-symfony/01-architecture-rule.md` would therefore **load perfectly well** — the flat
layout buys naming consistency, and nothing else. Two consequences worth being precise about:

- **Do not defend the flat tree as a resolver requirement.** It is a choice, and the prohibition above
  rests on `## Prohibitions — Structure Immutability`, not on a technical constraint. This is the same
  footing as `## Docs Layout`, and the opposite of `skills/`, `agent-memory/`, `commands/` and
  `output-styles/`, where nesting genuinely breaks resolution.
- **The prohibition is unchanged.** Evidence that re-nesting *would work* is not licence to do it;
  only an explicit user instruction is.

- **File names are `<domain>-<name>-rule.md`**, ending in the mandatory `-rule.md` suffix:
  `cache/redis-config-rule.md` → `cache-redis-rule.md`;
  `utility/shell-script-config-rule.md` → `utility-shell-script-rule.md`. Where the domain prefix
  already heads the name, do not double it — `api/api-platform-rule.md` → `api-platform-rule.md`.
- **A numbered series keeps its number after the domain prefix**:
  `app/php-symfony/09-testing-rule.md` → `app-php-symfony-09-testing-rule.md`. The number orders the
  series and must not be renumbered to close a gap.
- **`paths` frontmatter is unaffected by the flattening.** Those globs match the _source files the rule
  governs_ (`app/src/**/*.php`, `scripts/**/*.sh`), not the rule's own location. Never rewrite a `paths`
  glob to point at `.claude/rules/`.
- **`abstract-structure-rule.md` carries no domain prefix**, deliberately: it is the always-loaded index,
  not a domain rule. Do not "fix" it into `utility-abstract-structure-rule.md`. The same applies to any
  future `abstract-*` index.
- **Two rules have no `paths` frontmatter and that is intentional** — `abstract-structure-rule.md` (an
  index) and `utility-git-commit-rule.md` (applies to a commit message, which is not a file). Do not
  invent a glob for either.
- **Layout changes are permitted here (except for `api` — see `## API Domain — Layout Freeze`)**,
  provided the naming convention holds and every `@see` / prose reference is updated in the same change.
  A rule is the SoT for its domain, so a stale pointer to one sends a reader to no criteria at all.
- **Deleting a rule file is still prohibited** without an explicit instruction — that removes a domain's
  single source of truth. Its `-docs.md` counterpart must not be orphaned either.

## Skill Directory Layout

`.claude/skills/**` cannot follow the `<domain>/<tier>/…` taxonomy: Claude Code derives a project
skill's command name from **the directory name**, and it discovers only `.claude/skills/<name>/SKILL.md`
— a `SKILL.md` nested one level deeper is never loaded. The tree is therefore **flat by necessity**, and
this is not a taxonomy violation to be "fixed".

@see https://code.claude.com/docs/en/skills — "How a skill gets its command name" (directory name is the command)

- **Encode the taxonomy in the directory name**, joining the path segments with hyphens and ending
  with the mandatory `-skill` suffix: `<domain>-<name>-skill`. `tools/gcp-cloudrun` →
  `tools-gcp-cloudrun-skill`; `utility/git-commit` → `utility-git-commit-skill`. Never invent
  a prefix outside the rule-tree domains (`api`, `app`, `cache`, `database`, `message`, `server`,
  `tools`, `utility`) — with the `abstract-` carve-out below — and **never omit the `-skill` suffix**;
  it is what keeps a skill invocation distinguishable from a slash command at the `/` prompt. A
  directory missing the suffix is a `[MUST]` finding in `/utility-claude-code-review`.
- **`abstract-<name>-skill` is the one permitted non-domain prefix**, on exactly the footing
  `## Rules Layout` grants `abstract-structure-rule.md` and `## Output Style Layout` grants
  `abstract-*-style.md`: a skill bound to **no domain** takes `abstract-` rather than borrowing a
  domain prefix it does not belong to. Three exist as of 2026-09-06 —
  `abstract-harness-engineering-skill` (what artifacts to build), `abstract-loop-engineering-skill`
  (how a verification loop converges) and `abstract-graph-engineering-skill` (how nodes and edges
  connect). Do not "fix" any of them into a domain-prefixed name, and do not read the prefix as a
  taxonomy violation. Note what the carve-out does **not** relax: the `-skill` suffix, the ≤ 64-char
  `name`, and `name:` equalling the directory name all still apply.
- **`name:` must equal the directory name.** For a project skill the frontmatter `name` is only a
  display label, so a mismatch silently produces two identities for one skill.
- **Layout changes are permitted here (except for `api` — see `## API Domain — Layout Freeze`)** — flatten, move, rename, merge, split — without a separate
  instruction, provided that: (a) the result follows the naming convention above and `name:` is kept in
  sync, and (b) **every `@see` / prose reference to the skill is updated in the same change** (search
  `.claude/**` for both the old path and the old bare name). Reference rot is the actual failure mode
  this exemption trades against.
- **A cross-cutting orchestration skill has no quartet, and that is not a gap.** `CLAUDE.md` requires a
  new *domain* to ship the `rule + docs + skill + reviewer-agent` quartet, but a skill that fans out
  over domains it does not own is exempt — it has no criteria of its own to be SoT for.
  **Four such skills exist as of 2026-09-06**, in two shapes:
  - `tools-app-deploy-skill` — a pre-deploy gate that delegates to `server-nginx-reviewer`,
    `tools-gcp-cloudrun-reviewer`, `tools-aws-ecs-reviewer` and `/utility-shell-script-review`, so it
    deliberately has no `tools-app-deploy-rule.md`, no `-docs.md` and no reviewer agent.
  - The three `abstract-*-engineering-skill` files — harness, loop and graph. They are **design
    skills, not domain skills**: each one explicitly disclaims holding criteria and reaches the
    existing SoTs (`utility-claude-code-rule.md`, `commands/utility-claude-code-review.md`,
    `abstract-structure-rule.md`, the three `*-agent-team-rule.md` files) by `@see`. A quartet member
    would be a **second copy of criteria that already have an owner**, which is the drift this repo
    pays for repeatedly — so their absence is the design, not an omission.

  Do not flag any of the four for missing quartet members — the same carve-out `## Docs Layout`
  grants the `*-agent-team-docs.md` files.
- **Deleting a skill directory is still prohibited** without an explicit instruction — that is a
  capability removal, not a layout change.

## Agents Layout

`.claude/agents/**` is a **single flat tier**, flattened on 2026-08-15. Claude Code identifies a
sub-agent by its frontmatter `name`, not by its path — the `Agent` call, the agent-type listing, and the
`agent-memory/` lookup all key off `name`. A domain tier organizes nothing, so the taxonomy is carried
in the filename instead.

- **File names are `<domain>-<name>.md`** and the **filename must equal the frontmatter `name`**:
  `app/php-symfony-reviewer.md` → `app-php-symfony-reviewer.md` / `name: app-php-symfony-reviewer`.
  Use only the rule-tree domains (`api`, `app`, `cache`, `database`, `message`, `server`, `tools`,
  `utility`). Where the domain prefix already heads the name, do not double it —
  `api/api-platform-analyzer.md` → `api-platform-analyzer.md`.
- **Renaming an agent is a three-part change**: the file, the frontmatter `name`, and
  `agent-memory/<name>/`. Doing fewer than all three orphans the memory **silently** — see the next
  section.
- **A rename is an interface change, not a layout change.** Anything that dispatches by agent name — an
  orchestrator's routing table, a skill's `Agent` step, a workflow playbook — breaks when `name` changes.
  Update every dispatcher in the same change, not just the `@see` lines.
- **Layout changes are permitted here (except for `api` — see `## API Domain — Layout Freeze`)**,
  provided the naming convention holds and the three-part rename above is done atomically.
- **Deleting an agent file is still prohibited** without an explicit instruction — that is a capability
  removal, and its `agent-memory/` directory must not be deleted either.

## Agent Memory Layout

`.claude/agent-memory/**` cannot follow the `<domain>/<tier>/…` taxonomy either. Claude Code resolves an
agent's memory directory **from the agent's `name` alone**, with no domain segment:

```text
memory: user     →  ~/.claude/agent-memory/<agentType>/MEMORY.md
memory: project  →  .claude/agent-memory/<agentType>/MEMORY.md      ← this project
memory: local    →  .claude/agent-memory-local/<agentType>/MEMORY.md  (gitignored)
```

`<agentType>` is the frontmatter `name`, passed through a sanitizer that replaces every character
outside `[A-Za-z0-9_-]` with `-`. Our agent names are already slug-safe, so the directory is simply the
name verbatim. The entry file is always `MEMORY.md`.

`[Verified]` 2026-08-29 [WebFetch: <https://code.claude.com/docs/en/subagents>] — the three scopes are now
published as a table in the official "Enable persistent memory" section, matching the paths above exactly.
That citation is the primary evidence. It is corroborated by, not replaced by, the earlier reading of the
resolver out of the Claude Code 2.1.220 binary on 2026-08-14
(`function Itr(e,t){…join(root,".claude","agent-memory",sanitize(name))…}`), which remains the only
evidence for the **sanitizer** step — the documentation does not describe it.

- **The tree is flat by necessity.** Inserting a domain tier —
  `agent-memory/app/app-php-symfony-reviewer/MEMORY.md` — means the file is never read; Claude Code looks
  only at `agent-memory/app-php-symfony-reviewer/MEMORY.md`. A domain tier here does not organize the
  memory, it **silently disables** it, with no error at any point.
- **The directory name must equal the agent's `name`** — not the file path of the agent, and not a
  variant of it. Renaming an agent orphans its memory; move the directory in the same change. The
  2026-08-15 rename (`php-symfony-reviewer` → `app-php-symfony-reviewer`, etc.) required exactly that
  paired move for all 16 memory-bearing agents.
- **This is not a mirror of `agents/`.** Since `agents/` was flattened on 2026-08-15 the two trees happen
  to look alike, but they still correspond by **slug, not by path**: the memory directory is keyed off the
  frontmatter `name`, so renaming an agent file without renaming its `name` — or vice versa — silently
  breaks the pairing no matter how similar the two trees look.
- **Layout changes are permitted here (except for `api` — see `## API Domain — Layout Freeze`)** to keep the directory name in sync with an agent `name`, without
  a separate instruction. Deleting a memory directory is still prohibited — that discards accumulated
  project knowledge.
- An agent with no `memory:` key has no `agent-memory/` counterpart. That is expected, not a missing file.

## Output Style Layout

`.claude/output-styles/**` cannot follow the `<domain>/<tier>/…` taxonomy either. `settings.json`
selects a style by a **single bare name** (`"outputStyle": "abstract-english-style"`), with no domain
segment and no path — so a style nested under a domain directory cannot be named in that setting. The
tree is **flat by necessity**, and this is not a taxonomy violation to be "fixed".

Be precise about what that name is. `[Verified]` 2026-08-29
[WebFetch: <https://code.claude.com/docs/en/output-styles>]: the resolver matches the style's **`name`**,
and **the file name is only the fallback when `name:` is absent**. This project keeps `name` equal to the
file slug, which collapses the two into one identifier — that is the whole point of the convention below,
not an incidental detail. An earlier reading of this paragraph said the setting resolves "by file slug
alone"; that is wrong as a mechanism, and a style whose `name` diverges from its slug would be selected
by the `name`, leaving the slug inert.

- **Domain styles are named `<domain>-<name>-style.md`**, joining the taxonomy segments with hyphens and
  ending in the mandatory `-style.md` suffix: `app/php-symfony-style.md` → `app-php-symfony-style.md`;
  `api/api-platform-style.md` → `api-platform-style.md`. Use only the rule-tree domains (`api`, `app`,
  `cache`, `database`, `message`, `server`, `tools`, `utility`). The slug may compress the source path
  rather than transliterate it — `utility/shell-script-config-style.md` became
  `utility-shell-script-style.md` to match its `utility-shell-script-skill` sibling — but it must stay
  a single hyphenated slug ending in `-style`.
- **`abstract-*-style.md` is the one exception to that naming rule**, and deliberately so: the base is
  not a domain style, so it carries an `abstract-` prefix instead of a domain one. Do not "fix" either
  into a domain-prefixed name.
- **There are two base files, forming a language-variant pair:** `abstract-english-style.md` and
  `abstract-korean-style.md`. They are peers — each is self-contained, and each is specialized by the
  same set of domain styles. **`abstract-english-style` is the one selected in `settings.json`**; the
  Korean base is present but inactive, and switching to it is a one-line `outputStyle` change.
  `abstract-korean-style.md` is written in Korean by necessity — an output style that specifies Korean
  responses has to demonstrate them — and is the **sole file under `.claude/**` exempt from the
  English-only documentation rule. See the `## Documentation Language` exception in `CLAUDE.md`.**
- **Frontmatter `name` must equal the file slug** — `app-php-symfony-style.md` /
  `name: app-php-symfony-style`. A mismatch produces two identities for one style and breaks the
  `settings.json` lookup.
- **Only one output style is active at a time** — the one named in `settings.json` (`outputStyle`),
  currently `abstract-english-style`. There is no runtime layering or inheritance: a domain style is _not_ auto-loaded
  on top of the base. "Specializes" is a documentation relationship — the base links to each domain
  style under `## Output Examples`, and agents/commands pull one in explicitly via `@see` + Read when
  working in that domain. Do not write a domain style that assumes the base is also in context.
- **This is not a mirror of `rules/`.** Since `rules/` was flattened on 2026-08-15 the two trees happen
  to look alike, but they still correspond by **slug, not by path**: a style is resolved from the
  `settings.json` slug and a rule from its `paths` glob, so neither tree can be derived from the other.
- **Layout changes are permitted here (except for `api` — see `## API Domain — Layout Freeze`)** — flatten, move, rename — without a separate instruction,
  provided that: (a) the result follows the naming convention above and `name:` is kept in sync, and
  (b) **every `@see` / prose reference is updated in the same change** (search `.claude/**` and
  `settings.json` for both the old path and the old slug). Reference rot is the failure mode this
  exemption trades against — the same trade-off as `## Skill Directory Layout`.
- **Deleting a style file is still prohibited** without an explicit instruction — that removes a
  documented convention, not a layout detail.

## Docs Layout

`.claude/docs/**` is a **single flat tier**, flattened on 2026-08-15. Be precise about why: unlike the
three trees above, nothing in Claude Code resolves a docs path — these files are reached only through
an `@see` reference someone wrote by hand. So the flat layout is **a convention, not a technical
constraint**, adopted so that `docs/`, `skills/`, and `output-styles/` all encode their taxonomy the
same way. Do not justify it as a resolver requirement.

- **File names are `<domain>-<name>-docs.md`**, joining the taxonomy segments with hyphens and ending in
  the mandatory `-docs.md` suffix: `app/php-symfony-docs.md` → `app-php-symfony-docs.md`;
  `cache/redis-config-docs.md` → `cache-redis-docs.md`. Where the domain prefix is already the
  head of the name, do not double it — `api/api-platform-docs.md` → `api-platform-docs.md`, never
  `api-api-platform-docs.md`.
- **`docs/` pairs with `rules/` by slug, not by path.** Both trees are flat, so they happen to look
  alike, but nothing derives one from the other — a docs file is reached only by a hand-written `@see`.
  Each domain rule still needs its `-docs.md` counterpart, and the two slugs must stay aligned; this is
  the same shape as the `rules/` ↔ `output-styles/` pairing. **The pairing is rule→docs, not
  docs→rule:** every rule needs a docs counterpart, but a docs file may pair with something other than
  a rule (the orchestrator contract document below). Do not read this bullet as requiring a rule for
  every docs file.
- **An orchestrator document is the exception to the pairing rule**: it is not a domain rule's
  reference edition, so its rule counterpart must not be assumed. Two shapes exist today, and **the
  split moved on 2026-08-30** when the three `*-agent-team-rule.md` files were created:
  - **Paired with both an agent and a rule** — `app-agent-team-docs.md`, `api-agent-team-docs.md` and
    `tools-agent-team-docs.md`. Each is the design SoT (background, inventory, trade-offs) for its
    `agents/*-agent-team.md`, and each now also has a slug-matched
    `rules/*-agent-team-rule.md` holding the orchestration invariants (the verdict SoT). All three
    carry a **domain prefix**. Because the rule counterpart now exists, these are ordinary rule↔docs
    pairs — **do not flag them as missing a rule, and do not delete the rule as redundant**: the docs
    file holds rationale, the rule holds criteria.
  - **Paired with neither a rule nor a single agent** — `abstract-orchestrator-contract-docs.md`, the
    shared operational contract that *all three* orchestrators reference. It is now the **only**
    rule-less docs file. Being bound to no domain it takes the **`abstract-` prefix**, the same
    convention `## Rules Layout` and `## Output Style Layout` apply to `abstract-structure-rule.md`
    and `abstract-*-style.md`. Do not "fix" it into a domain-prefixed name, and do not flag it for
    having three `@see` parents instead of one.

  `[Verified]` 2026-08-28 — before the orchestrator split there was a single `agent-team-docs.md` that
  carried **no prefix at all**, and this clause used to grant that. That carve-out is retired with the
  file: every `*-docs.md` now carries either a domain prefix or `abstract-`, so a **prefix-less**
  `*-docs.md` is a `[MUST]` finding.
- **A docs file is a reference, never a SoT.** It holds the example/detail edition of its rule; when the
  two disagree, the rule wins. Do not move judgment criteria into `docs/`.
- **Layout changes are permitted here (except for `api` — see `## API Domain — Layout Freeze`)** — flatten, move, rename — without a separate instruction,
  provided the result follows the naming convention above and **every `@see` / prose reference is
  updated in the same change** (search `.claude/**`, `CLAUDE.md`, and `TODO.md` for the old path).
  Because nothing resolves these paths automatically, a stale reference fails silently at read time
  rather than erroring — reference rot is the whole risk this exemption trades against.
- **Deleting a docs file is still prohibited** without an explicit instruction. An empty stub
  (`utility-claude-code-docs.md`, `utility-git-commit-docs.md` are both 0 bytes) is a deliberate
  placeholder tracked in `TODO.md`, not a file to clean up.

## Commands Layout

`.claude/commands/**` is a **single flat tier**, flattened on 2026-08-15. A slash command has no `name`
frontmatter — **the path is the invocation name**, so nesting was not neutral: `commands/app/
php-symfony-review.md` invoked as `/app:php-symfony-review`, with the directory becoming a `:`-separated
namespace. Flattening therefore _changed every command's invocation name_.

- **File names are `<domain>-<name>-review.md`** (or `-test.md`), and the filename minus `.md` is exactly
  what the user types: `app-php-symfony-review.md` → `/app-php-symfony-review`. Where the domain prefix
  already heads the name, do not double it — `api/api-platform-review.md` → `api-platform-review.md` →
  `/api-platform-review`.
- **Renaming or moving a command changes the user-facing invocation.** Treat it as an interface change:
  update every `@see`, every prose mention of the old `/domain:name` form, and any skill or agent that
  instructs the user to run it. A stale `/domain:name` reference is not a broken link — it is an
  instruction to type a command that no longer exists.
- **Layout changes are permitted here (except for `api` — see `## API Domain — Layout Freeze`)**,
  provided the naming convention holds and every invocation reference is updated in the same change.
- **Deleting a command file is still prohibited** without an explicit instruction — that removes a
  user-facing entry point.

## API Domain — Layout Freeze (overrides every "layout changes are permitted" clause above)

**The `api` domain is frozen at its current shape as of 2026-08-15.** Every other tree grants a
layout-change permission in its section; **that permission stops at the `api` entries.** Restructuring,
re-nesting, renaming, or merging any of the files below is prohibited without an explicit instruction
naming them.

Now that every tree is flat, the freeze is entirely about **names**, and that is the stronger constraint:
in a flat tree the filename _is_ the identifier Claude Code resolves — agent `name`, memory key, slash
command, skill invocation. Renaming one of these is a user- or dispatcher-facing interface change, not a
cosmetic path edit.

| Frozen path                          | Entries                                        | Why the name is load-bearing                                      |
| ------------------------------------ | ---------------------------------------------- | ----------------------------------------------------------------- |
| `.claude/rules/api-platform-rule.md` | 1                                              | the domain's SoT; every `@see` in the domain points here          |
| `.claude/agents/api-*.md`            | `api-agent-team`, `api-platform-author`, `api-platform-analyzer`, `api-platform-reviewer`, `api-platform-debugger`, `api-platform-tester` | filename = frontmatter `name` = agent-type identifier             |
| `.claude/agent-memory/api-*/`        | same six                                       | directory must equal the agent `name`, or memory silently orphans |
| `.claude/commands/api-*.md`          | `api-platform-review`, `api-platform-rest-build`, `api-platform-oauth2-build` | filename = the slash command the user types                       |
| `.claude/docs/api-*-docs.md`         | `api-platform-docs`, `api-agent-team-docs`     | reached only by `@see`; a stale pointer fails silently            |
| `.claude/skills/api-*-skill/`        | 5 directories                                  | directory name = skill invocation                                 |

- **A consistency argument is explicitly not grounds.** That the sibling domains in a tree were renamed
  or restructured does not license doing the same to `api`.
- **Adding a new `api` artifact is still allowed** — it must follow the shape of its frozen siblings.
- **Content edits are unaffected.** The freeze covers paths and names only; editing the body of any
  `api` file at its existing path is normal work.
- **Only an explicit user instruction naming the `api` paths lifts this.** A review finding, a
  consistency cleanup, or a blanket "flatten the tree" request does not.

> Three notes on how this section got here. It was requested as `.claude/agent/api/**`; there is no
> `.claude/agent/` directory, so it covers `.claude/agents/` instead. And it was first written against
> `agents/api/` and `rules/api/` while both were still nested — the user then flattened each by explicit
> instruction, so the table records the resulting flat names rather than the original nesting.
>
> Finally, the table lost two entries on 2026-08-16. The agent row: `api-agent-team` was merged into
> `agent-team` (along with `app-agent-team` and `tools-app-deploy-agent-team`), and its
> `agent-memory/api-agent-team/` directory went with it. The docs row: `api-agent-team-docs` was merged
> into `agent-team-docs.md` to mirror that. Both are the "explicit user instruction naming the
> `api` paths" carve-out above — each request named the `api` file directly.
>
> The table changed again on 2026-08-17, under the same carve-out. The user renamed
> `agents/api-platform-author.md` → `agents/api-platform-analyzer.md` (with the paired
> `agent-memory/` move) and deleted `commands/api-platform-test.md`, then instructed that the api domain
> be brought into agreement with the rename. Two rows moved: the agents row now reads
> `api-platform-analyzer`, and the commands row lost `api-platform-test`. The change was not
> cosmetic — the renamed agent was **converted from the Build(Author) role to the read-only Analyze
> axis**, giving `api` the same analyzer/debugger/reviewer/tester quartet as each `app` domain and
> leaving no author→reviewer agent pair in any code domain. The deleted command's per-operation test
> procedure moved into `agents/api-platform-tester.md`, which now owns the full TDD cycle.
>
> **Correction, 2026-08-25 — the commands row was under-reported for eight days.** The 2026-08-17 note
> above originally read "the commands row drops to `api-platform-review` alone", which recorded that
> change's *deletion* but not its *additions*: the same change created
> `commands/api-platform-rest-build.md` and `commands/api-platform-oauth2-build.md` as the SoT for the
> authoring conventions (see `abstract-structure-rule.md`, "A third application — the api-platform
> domain"). Both are `api-*` command files and both were frozen from the moment they were created —
> `CLAUDE.md` has always said so, freezing "every `api-*` entry in … `commands/`" — so this is a
> bookkeeping fix to the table, **not** a new freeze. `[Verified]` 2026-08-25: `.claude/commands/`
> contains exactly three `api-*` files, and the row now lists all three.
>
> The agents row grew back on 2026-08-22, and this one is **not** a carve-out — it is the
> `## API Domain — Layout Freeze` clause "Adding a new `api` artifact is still allowed" operating as
> designed. `agents/api-platform-author.md` was re-created (with the paired
> `agent-memory/api-platform-author/`), restoring the author→reviewer pair the 2026-08-17 note above
> records as having been left with none. It follows the shape of its frozen siblings: filename =
> frontmatter `name` = memory directory. **The revived author does not own the authoring
> conventions** — `/api-platform-rest-build` and `/api-platform-oauth2-build` remain SoT for those, so
> the 2026-08-17 rationale for merging them is untouched. The agents row therefore lists five and the
> memory row reads "same five"; nothing was renamed, re-nested or merged.
>
> On 2026-08-23 the four `*-analyzer` agents added `disallowedTools: Edit, Write` so their read-only
> role is enforced by the harness rather than by prose. That is a **content edit at an existing path**
> under `## Allowed Changes`, and it touches no frozen name — recorded here only because
> `api-platform-analyzer` is one of the four.
>
> **2026-08-28 — `api-agent-team` and `api-agent-team-docs` returned, under the explicit-instruction
> carve-out.** The user split the single `agent-team` orchestrator back into `app-agent-team` and
> `api-agent-team`, naming the `api` paths directly, and the paired design document
> `docs/api-agent-team-docs.md` was restored with it. Both had been merged away on 2026-08-16 (see the
> note four paragraphs above) and are now **re-created and frozen again**: the agents row gained
> `api-agent-team`, the memory row reads "same six", and the docs row lists `api-agent-team-docs`
> alongside `api-platform-docs`.
>
> Note what this change did **not** do — nothing was renamed, re-nested or merged, and the five
> `api-platform-*` agents kept their names, memory directories and criteria. The split changed **which
> orchestrator routes into them**, not the roster itself. Do not read it as licence to restructure the
> domain.
>
> The remaining `api` entries (`api-platform-rule`, the five `api-platform-*` agents and their memory,
> the three `api-platform-*` commands, `api-platform-docs`, and the five `api-*-skill` directories) are
> untouched and remain frozen; none of these precedents extends to them.

## Allowed Changes

- Editing the **contents** of an existing file at its existing path.
- **Adding** a new file at a path that follows the existing taxonomy, mirroring the closest sibling of
  the same kind.
- Adding a new **domain** directory — provided the `rule + docs + skill + reviewer-agent` quartet is
  created together and registered in the `abstract-structure-rule.md` index (per CLAUDE.md). The skill member of
  the quartet is a flat `.claude/skills/<domain>-<name>-skill/` directory, not a nested one.

## When a Structure Change Seems Warranted

Report it; do not perform it. State the finding as `[CONSIDER]` with the before/after paths and the
reason, then wait for an explicit user decision. A `[CONSIDER]` note never authorizes the move.

## Which Tool to Use

- Authoring a new `.claude/**` artifact uses the `utility-claude-code-skill` skill (self-verification loop);
  quality review of an existing artifact uses the `/utility-claude-code-review` command.
- Classify review severity as `[MUST]` / `[SHOULD]` / `[CONSIDER]`; only `[MUST]` blocks a merge.
