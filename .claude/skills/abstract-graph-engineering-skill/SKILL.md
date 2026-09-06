---
name: abstract-graph-engineering-skill
description: 'Designs and audits this repository''s orchestration graph (nodes = agents, edges = routing). Judges the three orchestrators'' roster boundaries, handoff direction, fan-out width, the 7-field spawn payload (the edge contract), the synchronization between agent-roster-guard.sh and the rules, and dead edges, circular handoffs and orphan nodes. Use it for requests like ''check the routing'', ''design the graph'', ''add an orchestrator'', ''extend a roster'', ''the handoff keeps bouncing'', ''fan-out width'', ''which team owns this'', ''adopt dynamic workflows'' (in any language). How a single loop converges belongs to abstract-loop-engineering-skill, and what artifacts to create belongs to abstract-harness-engineering-skill — hand those over.'
---

# Graph Engineering Skill

Designs and audits **how several loops connect**. How an individual loop converges is out of scope.

- This skill **holds no judgment criteria.** It points at the SoTs below with `@see` and does not
  restate them.

@see .claude/docs/abstract-orchestrator-contract-docs.md — the operating contract shared by all three teams (rationale · measurements)
@see .claude/rules/app-agent-team-rule.md — roster invariants for the app-proper axis (SoT)
@see .claude/rules/api-agent-team-rule.md — roster invariants for the exposure-layer axis (SoT)
@see .claude/rules/tools-agent-team-rule.md — roster invariants for the infrastructure · data · deployment axis (SoT)
@see .claude/hooks/pre-tool-use/agent-roster-guard.sh — the edge-enforcing hook (an executable projection of the rules)
@see .claude/rules/utility-claude-code-rule.md — `.claude/**` structure and placement verdicts (SoT)
@see <https://code.claude.com/docs/en/sub-agents> — sub-agent (node) spec
@see <https://code.claude.com/docs/en/workflows> — dynamic workflows (the graph moved into code)

---

## The three axes (read this first)

```text
abstract-harness-engineering-skill  = what to build   (artifact kinds · counts · role axes)
abstract-loop-engineering-skill     = how it converges (gates · verdicts · retries · stopping)
abstract-graph-engineering-skill    = how it connects  (this skill — nodes · edges · fan-out · routing)
```

**Whether to create a node belongs to harness, the loop running inside a node belongs to loop, and the
edges between nodes belong to this skill.** The decision to create a new agent comes from harness;
**which roster it attaches to, and how**, is decided here.

---

## 1. This repository's graph

Claude Code already supplies the graph-engineering primitives — **a sub-agent is a node, a delegating
orchestrator is a routing node, and the routing between them is an edge**. This repository uses that as
a three-root forest.

```text
        main conversation (routing)
        ├── app-agent-team   ──► app-*-{author,analyzer,debugger,reviewer,tester}, 15 agents
        │      └─(Skill)────► domain review commands · the deploy gate · commit and diagram skills
        ├── api-agent-team   ──► api-platform-{author,analyzer,debugger,reviewer,tester}, 5 agents
        └── tools-agent-team ──► cache-* · database-* · server-* · tools-aws-* · tools-gcp-*
```

**The three orchestrators never spawn one another.** The edges between them are **handoffs**, not
spawns: name the owning team explicitly and **never drop the work silently**.

| Axis | Owns | Roster definition | tmp |
| --- | --- | --- | --- |
| `app-agent-team` | the app proper (PHP · JS · Twig) · **all provider consumption** · operations and configuration | `^app-.+-(author\|analyzer\|debugger\|reviewer\|tester)$` | `.claude/tmp/app/` |
| `api-agent-team` | the API Platform exposure layer only | `^api-platform-(author\|analyzer\|debugger\|reviewer\|tester)$` | `.claude/tmp/api/` |
| `tools-agent-team` | infrastructure · data · deployment | `^(cache\|database\|server\|tools-aws\|tools-gcp)-.+$` | `.claude/tmp/tools/` |

> **`app-agent-team`'s `Skill` edges are not symmetric with its `Agent` edges.** It delegates to the
> domain `/…-review` commands, `tools-app-deploy-skill`, `utility-git-commit-skill` and
> `utility-drawio-diagram-skill` — all of which exist. The **provider `*-build-skill` route does not**:
> `[Verified]` 2026-09-06, no `api-providers-*-build-skill` directory and no `commands/api/providers/**`
> file is on disk. A change under a provider source path is **unroutable** and must be reported as
> such. See `docs/abstract-orchestrator-contract-docs.md` §8.

---

## 2. Edges are decided by path, not by name

**Routing ownership is decided by the target code path.** Inferring it from a prefix gets it wrong.

| Target code path | Owner |
| --- | --- |
| `app/src/ApiResource/**` · `app/src/State/**` · `api_platform.yaml` | `api-agent-team` |
| every other `app/src/**` (providers included) · `app/assets/**` · `app/templates/**` · `scripts/**` · `diagram/**` · `.claude/**` | `app-agent-team` |
| Redis · Doctrine/PostgreSQL · Nginx · Cloud Run · ECS assets | `tools-agent-team` |

The verdict SoT for this table is `rules/app-agent-team-rule.md`,
`## Invariant — scope boundary and handoffs`, and its two siblings.

**Three boundary cases that are repeatedly got wrong:**

1. **Provider consumption belongs to `app-`** (transferred 2026-08-29). Be precise about what that
   transfer did and did not achieve: routing ownership moved, but the provider **artifacts were never
   built** — the rules, commands and skills the route points at do not exist, so the correct outcome
   for a provider-path change is "unroutable", not "handled by `app-agent-team`".
2. **`message-rabbitmq-reviewer` is outside the `tools-agent-team` roster** — it matches none of the
   five prefixes, so it is reached through `app-agent-team`'s `/message-rabbitmq-review` command. Do
   not pull it in because the name looks like infrastructure.
3. **`tools-agent-team` itself starts with `tools-` but does not match its own roster** — the pattern
   is `tools-aws-` / `tools-gcp-` only, so it is excluded at the glob level.

**A roster is defined by prefix rather than by a fixed list, and is resolved by preflight on every
invocation.**

---

## 3. The edge contract — the 7-field spawn payload

**Every sub-agent starts from an empty context.** It inherits nothing from the orchestrator's context,
and `@see` is a notation rather than an import, so **it only arrives if the agent `Read`s it**. The
edge is the contract that fills that gap.

```text
1. target file list (no summarizing, no eliding)   5. severity notation convention
2. exactly one role                                6. no secrets
3. the governing rule (SoT) path                   7. how to report an unrun gate
4. output path
```

Which failure each field prevents is owned by the table in
`docs/abstract-orchestrator-contract-docs.md` §1. It is not restated here.

**Field 1 carries a second obligation under worktree isolation.** 19 of the domain agents run in their
own worktree and therefore **cannot see the parent session's uncommitted edits** — so when the spawn is
the reviewer half of an author→reviewer loop, the author's **full unified diff must be inlined as text**
in the prompt. Routing a reviewer to a path and assuming it can reach the bytes is the highest-cost
silent failure available here. Details in `abstract-loop-engineering-skill` §5-1 and contract §2.

**Do not mix layers in field 3.** `app-agent-team` holds both the app proper
(`app-php-symfony-*-rule.md`) and provider consumption in one team. Since no provider rule file exists
yet, a provider-path spawn has **no SoT to name** — report the gap rather than substituting a
neighbouring rule such as `app-php-symfony-*`, which holds no criteria for it.

---

## 4. Edges are enforced by a hook

`.claude/hooks/pre-tool-use/agent-roster-guard.sh` compares `agent_type` (the caller) against
`tool_input.subagent_type` (the target) and **blocks an out-of-roster spawn with `exit 2`**.

**Why the hook is necessary** — every other mechanism is unfit:

| Alternative | Why it fails |
| --- | --- |
| a `tools: Agent(a, b)` parenthesised allowlist | it looks like an allowlist and is not. It applies only to an agent arriving on the main thread via `claude --agent`; **in a sub-agent definition the type list inside the parentheses is silently ignored** |
| `permissions.deny` | a repo-wide denylist, so expressing "only these five prefixes, and only for this caller" means enumerating everything else — and it would also block a sibling orchestrator's legitimate spawns |

**The rule is SoT and the hook follows it.** The hook holds no criteria of its own; it is an executable
projection of the rules, so when a roster changes, **fix the rule and the hook's `case` table in the
same commit**.

**There is one path where the guard silently stops guarding** — when `jq` is missing it prints a warning
and exits `1` (non-blocking). The roster constraint is **unenforced** for that call. If you see the
warning, say so in the report.

---

## 5. Fan-out — the width has a limit

`maxTurns` is the whole orchestration budget (`[Verified]` 2026-09-06 — **app 50 · api 50 · tools 40**),
and **a spawn and its return each consume a turn**.

- Cap parallel spawns at **6 per batch**.
- With more targets than that, split into batches by priority (code domains → infrastructure) and report
  the remainder as **deferred** — never drop it silently.
- Never spawn the same agent on the same file twice in one invocation.
- **Run independent branches in parallel.** The only sequential edge is the author→reviewer loop.
- When the budget runs out, stop spawning, consolidate what returned, and name the targets left untouched.
- **Nested spawn depth is 3 layers** (`CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH`, default 3). At the cap the
  harness **withholds** the `Agent` tool rather than erroring, so the agent quietly does the work itself.
- **A separate cap of 20 concurrent sub-agents applies** (`CLAUDE_CODE_MAX_CONCURRENT_SUBAGENTS`).
  Exceeding it fails the spawn with `Concurrent subagent limit reached` — unlike the depth cap, this one
  is loud.

`api-agent-team → app-agent-team → specialist` already fills the depth budget with **zero headroom**;
`tools-agent-team` spawns no orchestrator, so it keeps one layer spare.

**The agent-teams experiment is off** (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS: "0"`), and the reason
matters because it was once recorded wrongly. The operative reasons are:

- **No nested teams — teammates cannot spawn teammates of their own.** This is the decisive one: all
  three orchestrators exist to spawn, and `api-agent-team` additionally delegates to `app-agent-team`.
  Promoted to teammates, that entire routing layer stops working.
- **No background sub-agents from in-process teammates** — a teammate spawning a `background: true`
  agent errors.
- A teammate is a full Claude Code session, so it costs more tokens than orchestration that only needs a
  returned report.

> **Retired claim, do not repeat it:** that a teammate returns "an idle notification instead of its
> result". The live documentation says the opposite — a finishing teammate notifies the lead and
> **includes its final answer**. The `"0"` verdict stands; only its justification changed.

The `agent-team` in the three orchestrators' names is **just their name** and has nothing to do with that
harness feature.

---

## 6. Consolidation — where the nodes converge

- Duplicate findings on the same file and line **merge into one at the strictest severity**. Several
  reviewers matching at once across domains is normal.
- Sort `[MUST]` > `[SHOULD]` > `[CONSIDER]`, and **only `[MUST]` blocks a merge**.
- **A sub-agent's final report is not shown to the user.** Restate anything they need to know in the
  consolidated report — never write "see the reviewer's output".
- **Do not forget the scope verdict** — if files were handed off to a sibling orchestrator, do not issue
  a go/no-go over that scope.
- The three teams' consolidated report paths are separate, so they cannot overwrite one another.

> **The tmp report is best-effort, not guaranteed.** The orchestrators hold `Write` but declare no
> `permissionMode`, so they inherit the session's mode — and `permissions.defaultMode` is `plan`, which
> is read-only. **The returned report is the required channel.** Never report a tmp path as written when
> the write was refused, never retry a refused write, and never reach for `Bash` redirection to defeat
> the permission mode.

---

## 7. Graph integrity check

**Routing tables go stale faster than the tree does.** Treat every rule, agent, skill and command a
spawn prompt cites as **unverified until checked**.

```bash
# 1. Orphan nodes — agents matching no roster regex
for f in .claude/agents/*.md; do n=$(basename "$f" .md)
  echo "$n" | grep -qE '^(app-.+-(author|analyzer|debugger|reviewer|tester)|api-platform-(author|analyzer|debugger|reviewer|tester)|(cache|database|server|tools-aws|tools-gcp)-.+|(app|api|tools)-agent-team)$' \
    || echo "  outside every roster: $n"
done

# 2. Dead edges — do the artifacts the orchestrators point at actually exist?
grep -rhoE '\.claude/[A-Za-z0-9/._-]+\.(md|sh)' .claude/agents/*-agent-team.md | sort -u | \
  while read -r p; do [ -e "$p" ] || echo "  MISSING: $p"; done

# 3. Roster ↔ hook sync — do the rules' prefixes match the hook's case table?
grep -n 'ALLOW_PATTERN' .claude/hooks/pre-tool-use/agent-roster-guard.sh

# 4. Preflight — does every delegation target skill actually load?
find .claude/skills -name SKILL.md | wc -l
ls -d .claude/skills/*/ | wc -l          # a mismatch is the defect
```

**"Outside every roster" in check 1 is not automatically a defect** — `message-rabbitmq-reviewer` and
the four `utility-*` agents are deliberately outside and are reached through command and skill entry
points. It is an orphan node **only when no path reaches it at all**.

**When a target is missing, do not substitute a near-match and do not skip it silently** — name the path
that was expected and **report it as unroutable**. A missing artifact is a defect worth surfacing, not
an obstacle to route around.

**Checking that a file exists is not enough.** Ten provider skills once existed on disk yet **never
loaded**, because they were nested (19 of 29 loaded). Commands of the same name registered correctly
under a `:` namespace, so the listing mixed the two and the skills read as present — and the instruction
"route only through the build skills" **failed silently**. That is why check 4 runs every time.

### Review checklist

- [ ] Does the new node match **exactly one** roster regex (or is it deliberately outside)?
- [ ] If a roster changed, were **the rule · the orchestrator's routing table · the hook `case`** all
      fixed together?
- [ ] Do handoffs **not cycle** — two teams passing to each other so nobody handles the work?
      (Agencies actually fell into this loop, and it is what prompted creating `tools-agent-team`.)
- [ ] Is fan-out width ≤ 6 per batch, and within the 20-concurrent cap?
- [ ] Do the tmp paths separate by team?
- [ ] Does `isolation` on each node match the **domain-scope** convention (see
      `abstract-loop-engineering-skill` §5-1), rather than being copied from a role axis?
- [ ] Does a node that must delegate carry `Skill` in `tools`?

---

## 8. Creating a new orchestrator

**Ask first whether three is insufficient.** It has been done once (2026-08-29, `tools-agent-team`), on
two grounds:

1. **The rules and tools did not overlap** — infrastructure, data and deployment judge by different
   criteria than the code domains.
2. **A handoff loop had formed** — Agencies (ECOS · KOSIS) fell between two teams and neither handled it.
   That it was an **observed** failure rather than an anticipated risk is the important part.

Creating one means **maintaining the boundary description across three files**. If routing misjudgment
has not actually been observed, widening an existing roster is cheaper.

The three slugs to create together (all three teams have been symmetric since 2026-08-30), plus memory:

```text
agents/{axis}-agent-team.md               ← the execution instructions themselves
rules/{axis}-agent-team-rule.md           ← roster invariants (verdict SoT)
docs/{axis}-agent-team-docs.md            ← team composition · role axes · trade-offs (not criteria)
agent-memory/{axis}-agent-team/MEMORY.md  ← if it declares memory: project
```

Then add a new branch to the `case` in `hooks/pre-tool-use/agent-roster-guard.sh`.

---

## 9. Dynamic workflows — this repository does not use them yet

**A dynamic workflow is what the official documentation means by "the graph moved into code".** The
script itself holds the loops, branches and intermediate results, so only the final answer lands in
Claude's context.

`[Verified]` 2026-09-06 — **`.claude/workflows/` holds `README.md` and nothing else; there are zero
`.js` files.** Neither `disableWorkflows`, `workflowSizeGuideline` nor `ultracode` is set in
`settings.json`.

**So this skill does not presuppose workflows.** Adopting them requires the following first.

### Steps required before adoption

1. **Re-examining the placement requires user approval.** `utility-claude-code-rule.md` states it:
   saving a `.js` puts **a reference document (`README.md`) and an executable artifact in one
   directory**, which triggers a placement review, and that falls under `## When a Structure Change
   Seems Warranted`.
2. **Check for `/` namespace collisions.** A saved workflow becomes `/<name>` from its `meta.name` and
   shares **one namespace with commands, skills and built-ins**. This repository has zero collisions
   only because of the `-skill` / `-review` · `-build` · `-test` suffix split, so a workflow name must
   follow the same convention.
3. **Respect the `meta` block constraints.** `export const meta` must be the **first statement** and a
   **plain object literal** with `name` and `description`. A variable, function call or spread makes it
   **silently vanish** from `/` autocomplete.
4. **Know the determinism constraint.** The runtime **throws** on `Date.now()`, `Math.random()` and
   argument-less `new Date()`, so a re-run repeats the same `agent()` calls. Pass timestamps in through
   `args`.
5. **Design around the runtime limits** — 16 concurrent agents, 4,096 items per `parallel()` /
   `pipeline()` call, 1,000 agents total per run, no module loading (`import()` fails before execution),
   and no filesystem or shell access from the script itself.
6. **Know the resume cost** — a failure mid-fan-out **re-runs every agent after it**. In an A·B·C·D
   sequence, a failure at B serves A from cache and re-runs B·C·D.

**Until then this repository's graph is three orchestrators plus sub-agent fan-out, and sections 1–8 are
the whole of it.**
