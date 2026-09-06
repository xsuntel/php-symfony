# utility-drawio-diagram-reviewer memory

Standing context for issuing a verdict on `./.claude/tmp/utility/drawio/diagram-draft.xml`.
The SoT for the judgment criteria is `.claude/rules/utility-drawio-diagram-rule.md`; where they
conflict, the rule wins.

## Artifact Paths

- Input: `./.claude/tmp/utility/drawio/diagram-draft.xml`. Its first line is a header carrying
  `target` / `page` / `apply` / `round`, plus `baseline-cells` whenever `apply: set_page`.
- Output: `./.claude/tmp/utility/drawio/diagram-review.md`.
  - **Line 1 is exactly `Verdict: PASS` or `Verdict: REDO`** — the orchestrator branches on that token
    and reads nothing else on the line.
  - **Append each round, and rewrite line 1 to the current verdict.** With `Write` only, that means
    Read the file, then Write it back whole: new verdict line + blank + prior `## Round N` blocks
    unchanged + this round's block.

## Order of Work (the body is the SoT — this is the reminder)

1. **Freshness gate** — header present, and `target`/`page`/`apply`/`round` matching what the
   orchestrator asked for. Any mismatch is `stale-or-missing-draft` REDO, and Step 2 is not reached.
2. **Mechanical checks** — the two `## Step 2` scripts decide structure and conventions. **Assign
   `DRAFT=` inside each snippet**: every Bash call is a fresh shell, so a variable set in an earlier call
   arrives empty and the script dies before checking anything.
3. **Judged checks** — only `## Step 3` (application format, which cells were swapped, shape ↔ perimeter,
   whether a `NOTE` escalates). Everything else was settled by the scripts.

A `FAIL` from the structure script is a REDO. A `NOTE` from the convention script is `[SHOULD]` on its
own, and escalates only when it is this round's own work or a draft-wide pattern.

## The Failure That Matters Most

**Missing cells on `apply: set_page`.** The page is swapped wholesale, so an omitted cell is a deletion,
and it is silent. Compare three numbers — the header's `baseline-cells`, the live `get_page` count, and
the structure script's per-page count. A shortfall the stated intent does not explain is an automatic
REDO, as is a `baseline-cells` that disagrees with the live page (the author never read what it is
overwriting). Any doubt here is a REDO.

## Palette (the five permitted pairs)

`#dae8fc`/`#6c8ebf` · `#d5e8d4`/`#82b366` · `#e1d5e7`/`#9673a6` · `#f8cecc`/`#b85450` ·
`#fff2cc`/`#d6b656`. Neutrals are `none` / `#f5f5f5` / `#666666`.

## Do Not False-Positive (these are not violations)

- **`mxgraph.aws4` stencil brand colors** — `#8C4FFF` (54) · `#232F3D` (25) · `#A153A0` (13) are part
  of the stencil definition.
- **Drawing GCP with the `aws4` group stencils** — a deliberate convention since
  `deploy/prod/office/0 - base.drawio`.
- **Known drift in existing files** — not subject to a finding when the draft did not touch it:
  - Mixed 2-space indentation (`base/`) vs. 4-space (`deploy/prod/office/`)
  - Outdated `version` attributes (`22.1.22` · `24.1.0` · `24.7.17` · `26.0.16`) — a value the editor records
  - The 12 existing default page names (draw.io's localized default) — the clause applies only to new or modified pages
- **`edgeStyle=none`** — 85 measured occurrences; a normal usage.

## Verdict Principles

- Layout aesthetics and whether to add more shapes are not subject to a verdict. Use only the objective
  criteria the scripts and `## Step 3` define.
- **Artifact-only.** The draft file and the live page are the evidence; what the author says it did is
  not. Every REDO reason quotes pasted check output, or names a line number and a cell id.
- **Round 1 must be complete.** A finding visible in round 1 but first raised in round 2 is recorded as
  `[SHOULD]` and must not become a REDO — the budget is 2 rounds, and moving the goalposts exhausts it
  without converging.
- **Never modify the draft.** `disallowedTools: Edit` enforces it; do not work around it with `Write`.
  Diagnosing is the job, fixing is the author's.
- When uncertain, choose REDO over PASS — a miss costs more than a false alarm.
- Each call is an independent single-shot verdict. Retry management and application are the
  responsibility of `utility-drawio-diagram-skill`.
