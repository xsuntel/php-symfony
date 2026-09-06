# Orchestrator Artifact Guide

Supplementary reference for `SKILL.md` Phases 1 and 4. **An orchestrator is an artifact too, so whether
to build one is a harness decision** — this document covers only the bundle of files that must be
created alongside it.

> **This document does not cover routing.** Since the three-axis split on 2026-09-06 everything below
> belongs to another skill and is not restated here.
>
> | Topic | Owner |
> | --- | --- |
> | roster boundaries · handoff direction · the edge contract (7 spawn fields) · fan-out width · hook sync · graph integrity | `abstract-graph-engineering-skill` |
> | generate-verify loops · self-verification loops · three-valued gates · retry budgets · stopping conditions | `abstract-loop-engineering-skill` |
> | rationale and measurements | `docs/abstract-orchestrator-contract-docs.md` |

@see .claude/skills/abstract-graph-engineering-skill/SKILL.md — routing · rosters · fan-out (owner)
@see .claude/skills/abstract-loop-engineering-skill/SKILL.md — loop convergence protocol (owner)
@see .claude/docs/abstract-orchestrator-contract-docs.md — the operating contract shared by the three teams (rationale)
@see .claude/rules/utility-claude-code-rule.md — `.claude/**` structure and placement verdicts (SoT)

---

## 1. Whether to create an orchestrator

**Ask first whether three is insufficient.** Creating one adds the cost of maintaining the boundary
description across three files, so **if routing misjudgment has not actually been observed, widening an
existing roster is cheaper.**

The two grounds behind the only case that justified it (2026-08-29, `tools-agent-team`):

1. **The rules and tools did not overlap** — infrastructure, data and deployment judge by different
   criteria than the code domains.
2. **A handoff loop was observed** — Agencies (ECOS · KOSIS) fell between two teams and neither could
   handle it. That it was an **observed failure** rather than an anticipated risk is what matters.

The detailed criteria and the routing design are owned by `abstract-graph-engineering-skill` §8.

---

## 2. Artifacts to create alongside one

**Create all three slugs plus the memory in one change.** The three teams have been symmetric on this
composition since 2026-08-30; leaving one out makes that team shaped differently from the others and
impossible to compare against them.

| Path | Nature | If omitted |
| --- | --- | --- |
| `agents/{axis}-agent-team.md` | the execution instructions themselves | the orchestrator does not exist |
| `rules/{axis}-agent-team-rule.md` | roster invariants (**verdict SoT**) | routing is improvised with no criteria |
| `docs/{axis}-agent-team-docs.md` | team composition · role axes · trade-offs (not criteria) | the account of the decision disappears |
| `agent-memory/{axis}-agent-team/MEMORY.md` | when `memory: project` is declared | it **simply fails to load, with no error** |

Adding a branch to the `case` in `hooks/pre-tool-use/agent-roster-guard.sh` comes with it — the hook is
an executable projection of the rules, so fix it in **the same commit as the rule**.

**`rules/{axis}-agent-team-rule.md`'s `paths` points at that team's agents, memory and documents** — that
is what makes the invariants auto-apply when those artifacts are edited.

---

## 3. Measured orchestrator frontmatter

`[Measured]` 2026-09-06.

| Axis | `maxTurns` | `model` | `tools` | `disallowedTools` | `color` |
| --- | --- | --- | --- | --- | --- |
| `app-agent-team` | 50 | opus | `Agent, Bash, Read, Grep, Glob, Write, Skill` | `Edit` | — |
| `api-agent-team` | 50 | opus | same | `Edit` | — |
| `tools-agent-team` | **40** | opus | same | `Edit` | `orange` |

- **`maxTurns` is decided by roster size** — `tools-agent-team` has only 5 members and a single Review
  axis with no author→reviewer loop to fund, so it gets 40. Do not copy from the axis.
- **`Skill` must be in `tools`** — all three teams have a path that delegates to a skill or command.
  Omit it and the call does not fail; it degrades into reading `SKILL.md` with `Read` and improvising.
- **Write `Agent` without parentheses** — a `tools: Agent(a, b)` allowlist is **silently ignored** in a
  sub-agent definition. The roster is enforced by `agent-roster-guard.sh` instead.
- **`color` is not a convention.** Only `tools-agent-team` sets one, and the review command says not to
  flag the lone value as an inconsistency. Do not add a colour for symmetry's sake.
- **No `permissionMode`, deliberately.** The three orchestrate rather than edit, so they inherit the
  session's mode — and `permissions.defaultMode` is `plan`, a read-only mode. The consequence is that an
  orchestrator's consolidated tmp report is **best-effort and the returned report is the required
  channel**. Never report a tmp path as written when the write was refused, and never reach for `Bash`
  redirection to defeat the permission mode.
- **No `isolation`.** Unlike the 19 domain agents scoped to `app/**` sources, an orchestrator must see
  the real working tree to fix file paths and consolidate.

---

## 4. Six contract items whose wording the three rules share

The `app`, `api` and `tools` rules carry the following in **identical wording**. **Never fix just one.**

1. The three orchestrators never spawn one another.
2. The 7-field spawn payload is mandatory.
3. `isolation` is not granted to an orchestrator, and a domain agent's isolation follows its **domain
   scope**, which obliges the orchestrator to inline the author's full unified diff into the reviewer's
   prompt.
4. tmp consolidated report paths are isolated per team.
5. A gate that did not run is not a pass (three values: pass / fail / not run).
6. A failed branch is re-spawned once; if it fails again, the verdict is withheld.

**Duplication between an agent prompt and a rule is intentional** — a sub-agent starts from an empty
context and cannot reach a rule through `@see`, so the instruction must physically be present. When the
two disagree, **the rule is SoT**, and both are revised in the same change. **Rationale and measurements
are not duplicated**, though — those go in one place, `docs/abstract-orchestrator-contract-docs.md`.
