---
name: utility-drawio-diagram-style
description: Output presentation and formatting style for authoring and reviewing draw.io diagrams (.drawio mxGraphModel XML). Prioritizes structural integrity, palette consistency, and a minimal diff.
keep-coding-instructions: true
---

# draw.io Diagram Output Style

This style applies when authoring or reviewing `.drawio` files in the `diagram/` directory.
**Structural integrity**, **consistency**, and **minimal diff** are always the top criteria.

@see .claude/rules/utility-drawio-diagram-rule.md — storage format · structural integrity · canvas · edit procedure · quality gate (SoT)
@see .claude/docs/utility-drawio-diagram-docs.md — measured statistics · shape catalog · MCP tools · sequence recipes
@see diagram/CLAUDE.md — directory structure · file naming (SoT)

---

## Response Format

- Always specify the language identifier on a code block: ` ```xml `
- **State the target file path in markdown immediately above the code block, not as an XML comment** —
  a `.drawio` body cannot contain XML comments:

  > `diagram/base/cache/redis.drawio` — page `Base`

- For a multi-page file, **always state which page is being addressed**. An XML fragment with no page
  named has an ambiguous application point and can overwrite the wrong page.
- When modifying an existing file, present **only the range of cells being replaced**; do not rewrite
  the whole document.
- A proposal that changes coordinates or sizes shows the before and after values side by side.
- Flag destructive or delicate operations (deleting a page, replacing a whole file) with a warning in
  `> ⚠️ **Caution:**` form beneath the code block.

---

## XML Skeleton

### New file (with the `mxfile` wrapper)

```xml
<mxfile host="Electron" type="device">
    <diagram id="uniqueDiagramId01" name="Base">
        <mxGraphModel dx="1531" dy="1120" grid="1" gridSize="10" guides="1" tooltips="1" connect="1" arrows="1" fold="1" page="1" pageScale="1" pageWidth="1600" pageHeight="1200" math="0" shadow="0">
            <root>
                <mxCell id="0" />
                <mxCell id="1" parent="0" />
            </root>
        </mxGraphModel>
    </diagram>
</mxfile>
```

### Replacing an existing page (the `content` of `set_page`)

Pass a **single `<mxGraphModel>`** with no `<diagram>` tag:

```xml
<mxGraphModel dx="1531" dy="1120" grid="1" gridSize="10" guides="1" tooltips="1" connect="1" arrows="1" fold="1" page="1" pageScale="1" pageWidth="1600" pageHeight="1200" math="0" shadow="0">
    <root>
        <mxCell id="0" />
        <mxCell id="1" parent="0" />
    </root>
</mxGraphModel>
```

> ⚠️ **Caution:** `set_page` replaces the target page wholesale. Even for a partial edit, the complete
> `mxGraphModel` you pass must contain **every cell** on that page — an omitted cell is deleted.

---

## Style-String Rules

`key=value;` separated by semicolons, no spaces, keys are case-sensitive, booleans are `0`/`1`, colors
are `#RRGGBB`. draw.io silently ignores an unknown key, so a typo surfaces as **no effect** rather than
an error.

### Vertex

```xml
<mxCell id="node1" value="Cache Pool" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#dae8fc;strokeColor=#6c8ebf;" parent="1" vertex="1">
    <mxGeometry x="160" y="120" width="160" height="80" as="geometry" />
</mxCell>
```

Frequently used keys: `rounded=0|1` · `whiteSpace=wrap` · `html=1` · `dashed=0|1` · `strokeWidth` ·
`fontSize` · `fontStyle` (1=bold, 2=italic, 4=underline) · `align` · `verticalAlign` · `opacity`.

### Edge

```xml
<mxCell id="edge1" style="edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;" parent="1" source="node1" target="node2" edge="1">
    <mxGeometry relative="1" as="geometry" />
</mxCell>
```

- The default routing is `edgeStyle=orthogonalEdgeStyle` — a repository-wide convention.
- An edge's `mxGeometry` carries `relative="1"`.
- Give an unconnected endpoint coordinates via a child `<mxPoint ... as="sourcePoint"/>` /
  `as="targetPoint"`.
- Use `exitX`/`exitY`/`entryX`/`entryY` only when a connection point must be pinned — the default is
  automatic connection points.

### Containers and Groups

```xml
<mxCell id="group1" value="Region" style="rounded=1;whiteSpace=wrap;html=1;strokeWidth=2;dashed=1;fillColor=none;verticalAlign=top;align=left;spacingLeft=30;" parent="1" vertex="1">
    <mxGeometry x="400" y="440" width="800" height="160" as="geometry" />
</mxCell>
```

- Pin a group label to the top-left with `verticalAlign=top;align=left;spacingLeft=30`.
- A boundary group takes `fillColor=none` + `dashed=1` so it does not obscure its contents.
- When container behavior is needed use `container=1;collapsible=1`; for a swimlane, `startSize` and
  `horizontal`.

---

## Palette

Always specify `fillColor` and `strokeColor` **as a pair**. The five pairs below are draw.io's standard
palette and also this repository's measured palette (the rule is the SoT).

| fill | stroke | Usage |
| --- | --- | --- |
| `#dae8fc` | `#6c8ebf` | Default · client · request flow (most common) |
| `#d5e8d4` | `#82b366` | Normal · success · user |
| `#e1d5e7` | `#9673a6` | Service · processing layer |
| `#f8cecc` | `#b85450` | Authentication · error · caution |
| `#fff2cc` | `#d6b656` | Data · storage · waiting |

- Neutral background and inactive: `fillColor=#f5f5f5;strokeColor=#666666;` or `fillColor=none`.
- Brand colors in the `mxgraph.aws4` stencils (`#8C4FFF`, `#232F3D`, etc.) are part of the stencil
  definition — leave them as they are.

---

## Choosing a Shape Library

| Diagram kind | Library | Example style |
| --- | --- | --- |
| Cloud · infrastructure deployment | `mxgraph.aws4` | `sketch=0;outlineConnect=0;shape=mxgraph.aws4.group;grIcon=mxgraph.aws4.group_region;` |
| Flowchart · processing flow | `mxgraph.flowchart` | `shape=mxgraph.flowchart.terminator;` · `shape=mxgraph.flowchart.database;` |
| Sequence · general shapes | Basic shapes | `rounded=0;whiteSpace=wrap;html=1;` |
| Network security | `mxgraph.cisco_safe` | the stencil's style string as-is |

When an exact style string is needed, do not guess — look it up with
`mcp__drawio-tool__search_shapes`. A mistyped stencil name renders silently as an empty shape.

---

## Sequence Diagram Conventions

This repository draws sequence diagrams as lifelines plus vertical edges
(source: `diagram/deploy/dev/app/abstract/connect/kakao/login.drawio`).

```xml
<mxCell id="4" value="Authorization Server" style="rounded=0;whiteSpace=wrap;html=1;fillColor=#f8cecc;strokeColor=#b85450;" parent="1" vertex="1">
    <mxGeometry x="920" y="120" width="160" height="40" as="geometry" />
</mxCell>
<mxCell id="3" style="edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;strokeWidth=2;endArrow=none;endFill=0;fillColor=#f8cecc;strokeColor=#b85450;" parent="1" source="4" edge="1">
    <mxGeometry relative="1" as="geometry">
        <mxPoint x="1000" y="1120" as="targetPoint" />
    </mxGeometry>
</mxCell>
```

- An actor header is a `160×40` rectangle; the lifeline is an `endArrow=none;endFill=0` edge descending
  from the header.
- Assign one palette pair per actor and use the same color for the header and its lifeline.
- Secondary or inactive lifelines take `dashed=1` plus neutral colors (`#f5f5f5` / `#666666`).

---

## Anti-patterns

Whenever one of these patterns is found, call it out and propose the alternative:

| Anti-pattern | Why | Alternative |
| --- | --- | --- |
| Compressed storage (`compressed="true"` · Base64 body) | Impossible to diff, grep, or review | Store as uncompressed XML |
| XML comments `<!-- -->` | Official DON'T — editors strip them or parsing breaks | `value` or `<UserObject>` metadata |
| Duplicate ids within a page | Cells vanish silently or edges attach to the wrong target | Reissue every id after cloning a page |
| Missing root cells (`id="0"` · `id="1"`) | The page will not open | Always place the two cells first |
| An id reference with no `source`/`target` | The edge does not render | Reference a real id, or use `mxPoint` endpoints |
| Unescaped `value="<span>..."` | XML parsing fails | Escape as `&lt;span&gt;` |
| A whole-file `Write` for a one-page edit | Produces a diff on unrelated pages | `list_pages` → `get_page` → `set_page` |
| Introducing arbitrary colors | Collapses the semantic color scheme across diagrams | The five palette pairs above |
| Leaving the default page name (`Page-1`, or its localized equivalent) | Undiscoverable in a multi-page file | A page name that describes the content |
| Off-grid coordinates (7, 13, …) | Shapes fall subtly out of alignment | Multiples of 10 |
| Re-indenting an entire existing file | Buries the actual change in the diff | Keep that file's existing indentation |

---

## Response Structure

When delivering a diagram, respond in this order:

1. **One-line statement of purpose** — what this diagram represents
2. **Target path and page** — the file path plus the page name (new vs. existing)
3. **XML code block** — a complete, applicable fragment
4. **How to apply it** — whether to use `set_page` (existing page) or `Write` (new file)
5. **Caveats** (when applicable) — what gets overwritten, and how to revert
