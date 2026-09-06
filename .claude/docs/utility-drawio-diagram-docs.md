# draw.io Diagrams — Detailed Reference

This document is **background, statistics, and reference** — not judgment criteria. Where it disagrees
with the rule (SoT), the rule wins, and no new judgment criteria are written here. It has no `paths`
frontmatter, so it is never auto-applied and is loaded only via `@see`.

@see .claude/rules/utility-drawio-diagram-rule.md — judgment criteria (SoT)
@see .claude/output-styles/utility-drawio-diagram-style.md — XML authoring style · palette · anti-patterns (SoT)
@see diagram/CLAUDE.md — directory structure · file naming (SoT)

---

## 1. Measured Statistics for `diagram/**`

A full census of **57 `.drawio` files / 114 pages** as of 2026-08-19. New diagrams follow this
distribution; do not invent a value absent from the statistics.

| Item | Measured |
| --- | --- |
| Compressed storage | **0** — all uncompressed XML |
| `gridSize` | `10` — 114/114, no exceptions |
| `pageWidth` | `1600` (67) · `1920` (34) · `1200` (13) |
| `pageHeight` | `1200` (101) · `1920` (13) |
| `edgeStyle` | `orthogonalEdgeStyle` (711) · `none` (85) |
| Maximum page count | 9 (`base/app/symfony/4 - Advanced Topics/4) messaging.drawio`) |
| `mxfile host` | `drawio-plugin` (32) · `Electron` (14) · `65bd71144e` (11) |

### Measured Palette

The repository's measured colors **match draw.io's official standard palette exactly** — this is not a
new rule invented for the project, but an already-observed convention pinned down.

| fill | Occurrences | stroke | Occurrences |
| --- | --- | --- | --- |
| `#dae8fc` | 256 | `#6c8ebf` | 257 |
| `#d5e8d4` | 153 | `#82b366` | 150 |
| `#e1d5e7` | 99 | `#9673a6` | 99 |
| `#f8cecc` | 53 | `#b85450` | 53 |
| `#fff2cc` | 15 | `#d6b656` | 15 |

`#8C4FFF` (54) · `#232F3D` (25) · `#A153A0` (13) and similar are brand colors from the `mxgraph.aws4`
stencils. They are part of the stencil definition and are not a palette deviation.

### Known Drift (existing files)

Deviations that remain in existing files. Apply the rules **only to new or modified targets**; do not
bulk-edit unrelated files on account of these items.

- **12 instances of the default page name** — draw.io's locale-dependent default name (`Page-1`, or its
  localized equivalent) was left in place.
- **Mixed indentation** — `base/` uses 2 spaces, `deploy/prod/office/` uses 4 spaces.
- **Mixed `version`** — `22.1.22` (32) · `24.1.0` (7) · `24.7.17` (4) · `26.0.16` (3). The editor
  records this value, so do not align it by hand.

---

## 2. Shape Library Catalog

Occurrences by library: `mxgraph.aws4` (228) · `mxgraph.flowchart` (152) · `basic` (37) ·
`cisco_safe` (13) · `office` (8) · `ibm` (1).

### `mxgraph.aws4` — Cloud and Infrastructure (`deploy/prod/office/`)

| Stencil | Occurrences | Usage |
| --- | --- | --- |
| `group` | 134 | General-purpose boundary group (kind selected via `grIcon`) |
| `group_subnet` | 48 | Subnet boundary |
| `group_availability_zone` | 36 | Availability zone |
| `resourceIcon` | 23 | Resource icon tile |
| `group_region` | 22 | Region boundary |
| `group_aws_cloud` | 15 | Outermost cloud boundary |
| `group_vpc` | 13 | VPC boundary |

The representative style for a boundary group — switch the kind by changing `grIcon` alone:

```text
sketch=0;outlineConnect=0;gradientColor=none;html=1;whiteSpace=wrap;fontSize=12;fontStyle=0;shape=mxgraph.aws4.group;grIcon=mxgraph.aws4.group_region;strokeColor=#333333;fillColor=none;verticalAlign=top;align=left;spacingLeft=30;fontColor=#333333;strokeWidth=2;dashed=1;
```

### `mxgraph.flowchart` — Processing Flow (`base/`, `deploy/dev/`)

| Stencil | Occurrences | Usage |
| --- | --- | --- |
| `terminator` | 71 | Start · end · external actor |
| `start_2` | 32 | Starting point |
| `database` | 22 | Storage |
| `direct_data` | 17 | Direct-access data |
| `document2` | 7 | Document · report |
| `decision` | 1 | Branch |

```text
strokeWidth=2;html=1;shape=mxgraph.flowchart.terminator;whiteSpace=wrap;
```

> This repository reuses the `aws4` group stencils when drawing GCP infrastructure too (see the
> `Google Cloud Platform - Project` group in `deploy/prod/office/0 - base.drawio`). That is a deliberate
> convention — the group-boundary representation is vendor-neutral — and must not be flagged as "the
> wrong library".

---

## 3. MCP Tools (`mcp__drawio-tool__`)

Seven tools are actually exposed in this environment. `settings.local.json` registers both
`drawio-tool` and `drawio-editor`, but `drawio-tool` is the one that exposes tools.

| Tool | Usage | Caveat |
| --- | --- | --- |
| `list_pages` | List pages (index · id · name · size) without their bodies | **Always call first on a multi-page file** |
| `get_page` | Read one page's `mxGraphModel` XML (auto-decompresses if compressed) | `page` is a 0-based index, a name, or an id |
| `set_page` | Replace one page, preserving all others | `content` is a single `<mxGraphModel>` with no `<diagram>` |
| `open_drawio_xml` | Open the editor with XML | `routing="libavoid"` can reroute connectors alone |
| `open_drawio_csv` | Generate from the CSV import format | Tabular data such as org charts and trees |
| `open_drawio_mermaid` | Generate from Mermaid syntax | 28 diagram types; the header keyword picks the type |
| `search_shapes` | Search stencils — returns the exact style string and size | Only when a brand or industry icon is needed. Not for basic shapes |

### Edit Procedure

```text
list_pages(path)                 → confirm the target page's index/name
  └─ get_page(path, page)        → load only that page's mxGraphModel into context
       └─ set_page(path, page, content)   → replace only that page
```

Reading a whole file pulls unrelated pages into context on a 9-page file, and overwriting with `Write`
produces a diff on pages that were not modified. Use `Write` only when creating a new file.

### `routing="libavoid"`

An optional argument to `open_drawio_xml`. It leaves vertex coordinates untouched and recomputes
**connectors only** as orthogonal paths that avoid obstacles. draw.io's default router does no obstacle
avoidance, so use this when edges cut through shapes in a hand-laid-out infrastructure or deployment
diagram. Omit it for sparse layouts where edges cannot overlap.

---

## 4. Sequence Diagram Recipe

Source: `diagram/deploy/dev/app/abstract/connect/kakao/login.drawio` (page `Authorization Code`).

There are only two building blocks.

1. **Actor header** — a `160×40` rectangle aligned at `y=120`, one palette pair assigned per actor.
2. **Lifeline** — an edge with the header as its `source`, descending to a `targetPoint` below.
   `endArrow=none;endFill=0` removes the arrowhead.

```xml
<mxCell id="8" value="User" style="rounded=0;whiteSpace=wrap;html=1;fillColor=#d5e8d4;strokeColor=#82b366;" parent="1" vertex="1">
    <mxGeometry x="120" y="120" width="160" height="40" as="geometry" />
</mxCell>
<mxCell id="7" style="edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;strokeWidth=2;endArrow=none;endFill=0;fillColor=#d5e8d4;strokeColor=#82b366;" parent="1" source="8" edge="1">
    <mxGeometry relative="1" as="geometry">
        <mxPoint x="200" y="1120" as="targetPoint" />
    </mxGeometry>
</mxCell>
```

Draw a secondary divider with two `mxPoint`s and no `source`, giving it `dashed=1` plus neutral colors:

```xml
<mxCell id="2" style="edgeStyle=orthogonalEdgeStyle;rounded=0;html=1;strokeWidth=1;endArrow=none;endFill=0;dashed=1;fillColor=#f5f5f5;strokeColor=#666666;" parent="1" edge="1">
    <mxGeometry relative="1" as="geometry">
        <mxPoint x="799.5" y="160" as="sourcePoint" />
        <mxPoint x="799.5" y="1120" as="targetPoint" />
    </mxGeometry>
</mxCell>
```

Lay actors out horizontally starting at `x=120`, and align the lifeline endpoints with the bottom of
the page (`y=1120` for a `pageHeight` of 1200).

---

## 5. Compression, Variables, Metadata

### Compression

A `.drawio` file may store its `<diagram>` body as deflate+Base64, and the draw.io desktop app sometimes
saves that way by default. This repository **enforces uncompressed** storage (currently 0 instances).
The official documentation likewise recommends uncompressed output for generation — compressed content
costs more tokens, cannot be read by a human, and cannot be verified without decompressing it.

When compression is unavoidable, the conversion order is `encodeURIComponent` → raw DEFLATE (no zlib
header) → Base64.

### File Variables

Put JSON in the `vars` attribute of `<mxfile>` and reference it from a label as `%name%`. The cell needs
`placeholders="1"`. This works only in the full `<mxfile>` form.

```xml
<mxfile vars='{"project":"products-app","env":"prod"}'>
    <UserObject id="2" label="%project% — %env%" placeholders="1">
        <mxCell style="text;html=1;" vertex="1" parent="1">
            <mxGeometry x="100" y="100" width="200" height="40" as="geometry" />
        </mxCell>
    </UserObject>
</mxfile>
```

### Metadata

To attach structured attributes to a cell, wrap the `<mxCell>` in a `<UserObject>` or `<object>`.
Because a `.drawio` file cannot contain XML comments, this is **the only way to leave an explanation, a
source, or a ticket link**.

---

## 6. Verification

### well-formed

```bash
python3 -c "import xml.etree.ElementTree as E,sys; E.parse(sys.argv[1])" "diagram/base/cache/redis.drawio"
```

### Structural Check (per-page duplicate ids · root cells · referential integrity)

Read the target page with `mcp__drawio-tool__get_page` and compare by eye, or — since nothing is
compressed — count duplicates with `grep -o 'id="[^"]*"'`.

### Official Schema

`mxfile.xsd` — <https://github.com/jgraph/drawio-mcp/blob/main/shared/mxfile.xsd>. It validates the
element hierarchy and attribute types. Style strings are outside this schema's scope; the official
Style Reference covers them.
