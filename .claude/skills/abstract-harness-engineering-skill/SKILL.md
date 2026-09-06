---
name: abstract-harness-engineering-skill
description: 'Designs, extends and audits **what to build and how much of it** in this repository''s harness (the `.claude/**` artifact system). Judges decisions that span several artifacts — whether to open a new domain axis, whether to add an agent or merge it into a command, which of the five role axes (author · analyzer · debugger · reviewer · tester) to fill — and delegates the file writing. Use it for requests like ''set up the harness'', ''design the harness'', ''audit the harness'', ''harness status'', ''sync the agents and skills'', ''add a new provider axis'', ''check for empty role axes'' (in any language). A request to write or edit a **single** artifact (''create an agent'', ''write a skill'') belongs to utility-claude-code-skill; how a loop converges (gates · retries · stopping) to abstract-loop-engineering-skill; and node/edge wiring and routing to abstract-graph-engineering-skill — hand those over.'
---

# Harness Design Skill

Designs this repository's harness **at the system level**. Writing, verifying and recording an
individual file is delegated to `utility-claude-code-skill`; this skill decides only **what to build,
how many, along which axes, and where to attach it**.

- Intermediate output: `./.claude/tmp/utility/harness/` (gitignored — not removable, since `rm` is denied)
- This skill **holds no judgment criteria.** It points at the SoTs below with `@see` and does not
  restate them.

@see .claude/rules/utility-claude-code-rule.md — `.claude/**` structure and placement verdicts (SoT)
@see .claude/commands/utility-claude-code-review.md — artifact spec · frontmatter · tool minimality verdicts (SoT)
@see .claude/rules/abstract-structure-rule.md — repository structure and rule index (SoT)
@see .claude/docs/abstract-orchestrator-contract-docs.md — the operating contract shared by the three orchestrators
@see .claude/rules/app-agent-team-rule.md — orchestration invariants for the app-proper axis (SoT)
@see .claude/rules/api-agent-team-rule.md — orchestration invariants for the exposure-layer axis (SoT)
@see .claude/rules/tools-agent-team-rule.md — orchestration invariants for the infrastructure · data · deployment axis (SoT)
@see .claude/skills/utility-claude-code-skill/SKILL.md — the delegate for writing and recording a single artifact
@see .claude/skills/abstract-loop-engineering-skill/SKILL.md — owns loop convergence (gates · retries · stopping)
@see .claude/skills/abstract-graph-engineering-skill/SKILL.md — owns nodes · edges · routing · fan-out

---

## Role boundaries (read this first)

Several artifacts cover the same domain. Cross the boundary and either judgment criteria get duplicated
or a safety gate gets skipped.

**Horizontal axis — the three layers of the public discourse, mapped onto this repository. None of the
three restates another.**

```text
abstract-harness-engineering-skill  = what to build   (this skill — artifact kinds · counts · role axes)
abstract-loop-engineering-skill     = how it converges (gates · verdicts · retries · stopping)
abstract-graph-engineering-skill    = how it connects  (nodes · edges · fan-out · routing · rosters)
```

**Vertical axis — once the design is settled, it descends to file writing.**

```text
abstract-harness-engineering-skill  (this skill. It never writes files itself)
        │ delegates file by file with the Skill tool
        ↓
utility-claude-code-skill      = draft a single artifact → self-verify → record at the target path
        │ reads its verification criteria from
        ↓
commands/utility-claude-code-review.md  = artifact spec verdicts (SoT)
rules/utility-claude-code-rule.md       = directory structure and placement verdicts (SoT)
```

**This skill never writes a file into `.claude/**` itself.** Once the design is fixed, it invokes
`utility-claude-code-skill` with the `Skill` tool, once per file. That skill owns the draft guard, the
retry limit (2) and the user-approval gate, so bypassing it skips all three.

**If a request ends at one artifact, do not use this skill** — go straight to
`utility-claude-code-skill`. This skill only earns its cost when the decision **spans several files**.

---

## Phase 0: Status audit (always first)

The harness goes stale faster than the code. **Do not read the inventory — count it.**

```bash
cd .claude
for d in agents commands rules docs; do printf '%-14s %s\n' "$d" "$(find $d -name '*.md' | wc -l)"; done
printf '%-14s %s\n' skills        "$(ls -d skills/*/ | wc -l)"
printf '%-14s %s\n' output-styles "$(ls output-styles/*.md | wc -l)"
printf '%-14s %s\n' hooks         "$(find hooks -name '*.sh' | wc -l)"
printf '%-14s %s\n' agent-memory  "$(ls -d agent-memory/*/ | wc -l)"
```

**Preflight — never skip this comparison.** A file that exists but the harness cannot find is the same
as a file that does not exist.

```bash
find .claude/skills -name SKILL.md | wc -l   # skills in the repository
ls -d .claude/skills/*/ | wc -l              # flat first-tier entries the harness scans — these must match
```

A difference means that many artifacts are **uninvocable**. They are absent from autocomplete, cannot be
called by name, and **nothing errors**. Ten provider skills were once in exactly this state (19 of 29);
the account is in `docs/abstract-orchestrator-contract-docs.md` §8.

Then branch on execution mode:

| Branch | Condition | Path |
| --- | --- | --- |
| **audit / sync** | a status check or drift check | report Phase 0 results → run Phase 6 verification only |
| **extend an existing axis** | add a role or entry point to a domain that already exists | Phase 1 → 2 → 3 → 5 → 6 |
| **create a new axis** | a new domain, provider or orchestrator | Phases 1–7 in full |

For the existing inventory, the boundaries and the verified premises, read `references/harness-inventory.md`.

---

## Phase 1: Identify the owning orchestrator

**The target code path decides the routing owner** — not a prefix and not a name. The 2026-08-29
transfer, which left the path prefix and the ownership disagreeing for a while, is why this rule exists.

| Target code path | Owning orchestrator | tmp path |
| --- | --- | --- |
| `app/src/ApiResource/**` · `app/src/State/**` · `api_platform.yaml` | `api-agent-team` | `.claude/tmp/api/` |
| every other `app/src/**` (provider consumption included) · `app/assets/**` · `app/templates/**` · `scripts/**` · `diagram/**` · `.claude/**` | `app-agent-team` | `.claude/tmp/app/` |
| Redis cache · Doctrine/PostgreSQL · Nginx · Cloud Run · ECS assets | `tools-agent-team` | `.claude/tmp/tools/` |

- **The three orchestrators never spawn one another.** Out-of-scope work is a handoff and is never
  dropped silently.
- `message-rabbitmq-*` matches none of `tools-agent-team`'s five prefixes (`cache-`, `database-`,
  `server-`, `tools-aws-`, `tools-gcp-`), so it belongs to **`app-agent-team`**. Do not pull it in on
  the strength of a similar-looking name.
- The routing verdict SoT is `rules/app-agent-team-rule.md`,
  `## Invariant — scope boundary and handoffs`, and its two siblings.

**This table exists to decide where to attach an artifact.** Roster boundaries, handoff direction and
the boundary cases that are repeatedly got wrong are owned by `abstract-graph-engineering-skill`. If a
new axis belongs to none of the three orchestrators, **decide whether to create one first** — the four
artifacts that come with creating one are in `references/orchestration-guide.md`, and the grounds and
routing design are in `abstract-graph-engineering-skill` §8.

---

## Phase 2: Choose the artifact

**Adding an agent is not the default.** This repository has three precedents for merging agents into
commands, and that direction is what prevents judgment criteria from being triplicated.

Decision order:

1. **Do the judgment criteria (SoT) already exist?** If not, create the `rules/` file first — an
   executor with no criteria improvises its verdicts.
2. **Is generate-and-verify needed, or only a verdict?** If only a verdict, one command is enough.
3. **Does an independent context actually raise verdict quality?** If not, a skill's self-verification
   loop is cheaper.
4. Only if it is still needed, create the agent.

The division of labour across the 8 artifact kinds, the 3 merge precedents, and the duplication/reuse
criteria are owned in detail by `references/artifact-selection-guide.md`.

**Structural constraints are not judged here** — the flat single tier, the hyphenated taxonomy, the
`-skill` suffix and the 64-character cap are all SoT in `rules/utility-claude-code-rule.md`. If a
violation looks possible, read that rule.

---

## Phase 3: Place the role axes

Code domains use **five axes (author · analyzer · debugger · reviewer · tester)**. When deciding which
to fill, first check **whether it is symmetric with the other axes of the same domain** — api-platform
reaching five axes on 2026-08-22, alongside filling the three app-domain authors, was a change made for
that symmetry.

`[Verified]` 2026-09-06 — the measured frontmatter, which is **not** uniform per axis:

| Axis | Nature | `maxTurns` | `model` | `permissionMode` | `isolation` |
| --- | --- | --- | --- | --- | --- |
| `-author` | generation (self-gate → reviewer verdict) | 30 | opus (`utility-git-commit-author` is sonnet) | `acceptEdits` | worktree if the domain is `app/**`-scoped |
| `-analyzer` | security vulnerability diagnosis (read-only by norm) | 30 | opus | — | same |
| `-debugger` | root-cause tracing of runtime bugs | 30 | opus | `acceptEdits` | same |
| `-reviewer` | quality verdict (`[MUST]`/`[SHOULD]`/`[CONSIDER]`) | 30 | **sonnet — every reviewer** | — | same, except `api-platform-reviewer` |
| `-tester` | regression-preventing tests | **45** | opus | `acceptEdits` | same |
| `-agent-team` | orchestrator | 50 (app · api) · **40 (tools)** | opus | — | never |

- **`maxTurns` is decided by workload, not by axis.** The testers' 45 funds a Red-Green-Refactor cycle
  that runs six or more gate commands per invocation; `tools-agent-team`'s 40 reflects a single Review
  axis with one fan-out and no author→reviewer loop to fund. Take a new agent's value from **the one or
  two existing agents whose workload is closest**, not from the axis.
- **`model` splits on the nature of the verdict, not the axis** — sonnet goes to work that compares
  against explicit written criteria, which is **every one of the 12 reviewers**, plus
  `utility-git-commit-author`. The split is opus 20 / sonnet 13.
- **`color` is not an axis convention.** Exactly one agent sets it (`tools-agent-team`, `color: orange`),
  and the review command says not to flag the lone value as an inconsistency. Do not invent a per-axis
  palette.
- **`isolation` follows domain scope, not the role.** 19 agents scoped to `app/**` sources carry
  `isolation: worktree`, read-only analyzers included. What that costs the verification loop, and the
  inline-diff handoff that pays for it, is owned by `abstract-loop-engineering-skill` §5-1.
- **No agent uses the `skills:` frontmatter key.** It is a preload axis and does not substitute for
  putting `Skill` in `tools`.

**Infrastructure and utility domains are not forced into five axes** — `cache-`, `database-`, `server-`,
`tools-aws-` and `tools-gcp-` are reviewer-only, and `utility-git-commit` and `utility-drawio-diagram`
keep only an author+reviewer pair. An empty axis is not automatically a defect; **fill one only when
there are grounds to**.

Each axis's frontmatter conventions, body skeleton, gate protocol and handoffs are in
`examples/agent-{role}-guide.md`.

---

## Phase 4: Wire up entry points and routing

**An artifact that is never invoked is the same as one that does not exist.** Handle the following in
the same change.

- **Entry-point naming** — skills take `-skill`, commands take `-review` / `-build` / `-test`. That
  suffix split is the only thing preventing `/` namespace collisions (commands, skills, workflows and
  built-ins share one namespace).
- **Update the orchestrator roster** — when an agent is added or renamed, fix the routing table in the
  relevant `agents/*-agent-team.md` **and** the `case` table in
  `hooks/pre-tool-use/agent-roster-guard.sh` **together**. The hook blocks out-of-roster spawns with
  `exit 2`, so fixing only one side blocks the new agent the instant it is spawned.
- **Agent memory** — if it declares `memory: project`, then
  `.claude/agent-memory/<agent name>/MEMORY.md` must exist at the flat path. Missing or nested, it
  **simply fails to load, with no error**.
- **Rule `paths`** — verify the glob actually causes the new rule to auto-apply. A missing `paths` is a
  `[MUST]` (only `rules/abstract-structure-rule.md` and `rules/utility-git-commit-rule.md` are exempt).
- **Shared `@see` slugs** — the same domain and subject use the same slug across kinds. Renaming one
  kind alone breaks the others' `@see` and `paths` at the same time.

**The details of wiring are not owned by this skill** — rosters, the edge contract, fan-out width and
hook synchronization belong to `abstract-graph-engineering-skill`; the convergence protocol for
generate-verify and self-verification loops belongs to `abstract-loop-engineering-skill`. Only the
**list of artifacts to create alongside a new orchestrator** is in `references/orchestration-guide.md`.

---

## Phase 5: Delegate the writing

Once the design is fixed, invoke `utility-claude-code-skill` with the `Skill` tool, **once per file**.

- State the **artifact kind and target path** in the invocation — that skill determines the kind from
  the target path, not from the draft filename.
- Pass the design rationale along (which SoT to reference, who is upstream and downstream).
- **Never bundle several files into one invocation.** Self-verification runs per artifact.
- The retry limit (2) and the user approval for the final write belong to that skill — do not count them
  again here.

For the caps, the listing budget and the YAML traps that apply when writing a `description` yourself,
read `references/skill-authoring-guide.md`. Silently truncated trigger phrasing originates there.

---

## Phase 6: Verify

```bash
# 1. Re-run the preflight — the two values must match
find .claude/skills -name SKILL.md | wc -l
ls -d .claude/skills/*/ | wc -l

# 2. Suffix convention — empty output is correct
ls -d .claude/skills/*/ | grep -v -- '-skill/$'

# 3. Reference factuality — do the SoT paths the new artifact cites exist?
grep -rhoE '\.claude/[A-Za-z0-9/._-]+\.md' <target-file> | sort -u | \
  while read -r p; do [ -f "$p" ] || echo "MISSING: $p"; done
```

- **Delegate the spec verdict to `/utility-claude-code-review <path>`.** This skill does not judge
  frontmatter, naming or tool minimality itself.
- **Trigger verification** — after restarting the session, check that the new entry appears in the skill
  listing **with its description**. Name-only means the listing budget was exceeded; entirely absent
  means discovery failed (a placement problem).
- **Near-miss check** — confirm that triggers do not overlap the existing 22 skills, and that an
  ambiguous request lands on the intended side. An obviously unrelated query has no verification value.

The detailed procedure and the dry-run checklist are in `references/harness-verification-guide.md`.

---

## Phase 7: Record the evolution

**Do not create a change-history table in `CLAUDE.md`.** This repository already has designated places
to record things.

| What is recorded | Where |
| --- | --- |
| adding or renaming a rule or artifact index entry | the index tables in `rules/abstract-structure-rule.md` |
| the account and trade-offs of a role-axis, routing or merge decision | the relevant section of `docs/{app,api,tools}-agent-team-docs.md` |
| rationale and measurements for the contract shared by the three teams | `docs/abstract-orchestrator-contract-docs.md` |
| a change to the judgment criteria themselves | the relevant `rules/*-rule.md` |

Write the account **with a date and a reason** (`2026-08-29 — changed to …, because …`). That narration
is why this repository's documents can retrace past decisions; fixing only the table loses the why.

**Signals that evolution should be proposed first:** the same class of finding recurring twice or more,
a particular axis repeatedly returning "cannot judge", or the user being observed bypassing the
orchestrator to work directly.

---

## Output checklist

- [ ] Phase 0 preflight values match (`find` = `ls -d`)
- [ ] Owning orchestrator identified — by path, not by prefix
- [ ] The **command-merge alternative** was considered before adding an agent (Phase 2)
- [ ] The judgment criteria (SoT) rule exists before the executor does
- [ ] Role-axis symmetry reviewed — is there a reason for each axis left unfilled?
- [ ] Frontmatter values taken from the **nearest-workload existing agent**, not copied from the axis
- [ ] Entry-point suffix (`-skill` / `-review` · `-build` · `-test`) assigned, with no `/` collision
- [ ] Orchestrator routing table **and** `agent-roster-guard.sh`'s `case` table updated **together**
- [ ] Where `memory: project` is declared, `agent-memory/<name>/MEMORY.md` exists at the flat path
- [ ] New rule has `paths`
- [ ] Slug sharing preserved across kinds for the same domain and subject; renames update `@see` with them
- [ ] Every file write delegated to `utility-claude-code-skill` (nothing written directly)
- [ ] `/utility-claude-code-review` confirms 0 `[MUST]`
- [ ] The account recorded in `docs/*-agent-team-docs.md` or `rules/abstract-structure-rule.md`

---

## References

| Document | What it covers |
| --- | --- |
| `references/harness-inventory.md` | measured status of this repository's harness · verified premises · the 5 role axes × domain matrix |
| `references/artifact-selection-guide.md` | division of labour across the 8 artifact kinds · the selection decision tree · merge precedents |
| `references/orchestration-guide.md` | whether to create an orchestrator · the 4 artifacts that come with one (routing belongs to the graph skill) |
| `references/skill-authoring-guide.md` | `description` caps · listing budget · YAML traps · body-writing principles |
| `references/harness-verification-guide.md` | preflight · trigger verification · dry run · full-sweep scripts |
| `examples/agent-{author,analyzer,debugger,reviewer,tester}-guide.md` | agent definition templates per role axis |
