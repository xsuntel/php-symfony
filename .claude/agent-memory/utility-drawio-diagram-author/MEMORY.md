# utility-drawio-diagram-author memory

Standing context for drafting `.drawio` files under `diagram/**`, so it does not have to be looked up
each time. The SoT for the judgment criteria is `.claude/rules/utility-drawio-diagram-rule.md`; where
they conflict, the rule wins.

## Artifact Paths

- Draft: `./.claude/tmp/utility/drawio/diagram-draft.xml` (write here only — never modify `diagram/**`
  directly). Overwrite it in full every round; `Bash(rm:*)` is denied, so a partial write leaves the
  previous run's XML mixed into this one's.
- First-line header, all five fields:
  `target: <path> | page: <page-name> | apply: set_page|Write | round: <n> | baseline-cells: <n>`
  - `round` — the number the orchestrator states; `1` when called directly with none.
  - `baseline-cells` — the live page's `mxCell` count as read via `get_page`, required whenever
    `apply: set_page`. Never estimate it: it is what lets the reviewer detect silent cell loss, and
    recording it is what proves the page about to be overwritten was actually read.
  - A missing or mismatched header is `stale-or-missing-draft` — rejected before any check runs.
- Review file: `./.claude/tmp/utility/drawio/diagram-review.md` — from round 2 on, **read it** and apply
  its latest `## Round N` block verbatim, rather than the prompt's paraphrase of it.

## Canvas Spec (fixed)

- `gridSize="10"`, no exceptions. Coordinates are multiples of 10.
- `pageWidth`: `1600` (default) · `1920` (`deploy/prod/office/` infrastructure) · `1200`
- `pageHeight`: `1200` (only portrait uses `1920`)

## Root-Cell Skeleton

```xml
<mxGraphModel dx="1531" dy="1120" grid="1" gridSize="10" guides="1" tooltips="1" connect="1" arrows="1" fold="1" page="1" pageScale="1" pageWidth="1600" pageHeight="1200" math="0" shadow="0">
    <root>
        <mxCell id="0" />
        <mxCell id="1" parent="0" />
    </root>
</mxGraphModel>
```

`set_page` takes a single `<mxGraphModel>` with no `<diagram>`, as above; a `Write` of a new file
includes the `<mxfile>` wrapper.

## Palette (these five pairs only · fill and stroke always paired)

| fill | stroke | Usage |
| --- | --- | --- |
| `#dae8fc` | `#6c8ebf` | Default · client · request flow |
| `#d5e8d4` | `#82b366` | Normal · success · user |
| `#e1d5e7` | `#9673a6` | Service · processing layer |
| `#f8cecc` | `#b85450` | Authentication · error · caution |
| `#fff2cc` | `#d6b656` | Data · storage · waiting |

Neutral: `fillColor=none` or `#f5f5f5` / `#666666`.
`mxgraph.aws4` stencil brand colors (`#8C4FFF` · `#232F3D`) are part of the stencil definition — leave
them alone.

## Shape Selection

- Cloud · infrastructure (`deploy/prod/office/`) → `mxgraph.aws4` (`group` + `grIcon`, `group_subnet`,
  `group_availability_zone`, `group_region`, `group_vpc`). Reusing this stencil for GCP is the convention.
- Flow (`base/`, `deploy/dev/`) → `mxgraph.flowchart` (`terminator`, `start_2`, `database`, `direct_data`)
- Sequence → basic shapes `rounded=0;whiteSpace=wrap;html=1;` plus lifeline edges
- When unsure, look it up with `search_shapes` — a mistyped stencil name silently becomes an empty shape.

## Default Edge Form

```text
edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;
```

Measured across the repository: `orthogonalEdgeStyle` 711 / `none` 85. `mxGeometry relative="1"` is
mandatory. Unconnected endpoints use `<mxPoint ... as="sourcePoint"/>` / `as="targetPoint"`.

## Frequently Missed

- **No XML comments** — put explanations in `value` or `<UserObject>` metadata.
- **A missing `as="geometry"`** causes coordinates to be ignored.
- Escape HTML in a `value` as `&lt;` · `&gt;` · `&amp;`.
- `set_page` swaps the page wholesale — **every existing cell must be included in the draft** (an
  omission is a deletion).
- Do not leave draw.io's locale-dependent default page name (`Page-1`, or its localized equivalent).
- When editing an existing file, **keep that file's indentation** (`base/` is 2 spaces,
  `deploy/prod/office/` is 4 spaces).
