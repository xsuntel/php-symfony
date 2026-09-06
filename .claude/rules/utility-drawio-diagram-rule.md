---
paths:
  - "diagram/**/*.drawio"
  - ".claude/tmp/utility/drawio/diagram-draft.xml"
---

# draw.io Diagram Rules (`diagram/**`)

This rule is the judgment criteria (SoT) for `.drawio` files under `diagram/**`. It enforces both
draw.io's official generation contract and the measured conventions of this repository's 114 pages,
so that hand-edited and tool-generated diagrams do not collide inside the same file.

**Responsibility split (no duplication):** the single source of truth for **authoring style** — the
mxCell skeleton, style-string syntax, the palette table — is the output style. The single source of
truth for **directory taxonomy and file naming** is `diagram/CLAUDE.md`. This rule restates neither;
it enforces only **XML structural integrity, canvas spec, edit procedure, and the quality gate**.

@see diagram/CLAUDE.md — directory structure · file naming · category purpose (SoT)
@see .claude/output-styles/utility-drawio-diagram-style.md — XML authoring style · style strings · palette table (SoT)
@see .claude/docs/utility-drawio-diagram-docs.md — measured statistics · shape catalog · MCP tools · sequence recipes
@see .claude/commands/utility-drawio-diagram-review.md — standalone review procedure & output format for an existing `.drawio`
@see .claude/agents/utility-drawio-diagram-author.md — authoring (Author) role
@see .claude/agents/utility-drawio-diagram-reviewer.md — structural-integrity verification (Reviewer) role
@see .claude/skills/utility-drawio-diagram-skill/SKILL.md — authoring · review · apply orchestration entry point
@see <https://www.drawio.com/docs/reference/diagram-generation/> — official programmatic generation contract
@see <https://www.drawio.com/docs/reference/diagram-generation/style-reference/> — official style-string reference

## Storage Format (non-negotiable)

- **Store uncompressed XML only.** The `compressed="true"` attribute, and putting a deflate+Base64
  string in the `<diagram>` body, are both forbidden. All 114 pages in the repository are already
  uncompressed, and that state is the precondition for diff, review, and `grep`.
- **No XML comments (`<!-- -->`)** — this is an explicit DON'T in the official generation contract.
  When an explanation is needed, move it into a cell's `value` or a `<UserObject>` / `<object>`
  metadata attribute.
- Indentation is **4 spaces** for new files. When editing an existing file, **keep that file's
  existing indentation** — the repository mixes 2 spaces (`base/`) and 4 spaces (`deploy/prod/office/`),
  so re-indenting a whole file in the name of consistency spreads a meaningless diff across it.

## Structural Integrity (non-negotiable)

- **Two root cells are mandatory** — `<mxCell id="0"/>` and `<mxCell id="1" parent="0"/>`. Every other
  cell must carry `parent="1"` or the id of a group/layer cell that actually exists.
- **Ids must be unique within one diagram (page).** Duplicate ids arise most often when a page is
  cloned to create a new one.
- `vertex="1"` and `edge="1"` are **mutually exclusive**. Never put both on one cell.
- Every cell has an `<mxGeometry ... as="geometry"/>` child. A missing `as="geometry"` causes the
  coordinates to be ignored.
- **Referential integrity** — an edge's `source` and `target` must be cell ids that exist on the same
  page. For an unconnected edge, leave `source`/`target` empty and supply coordinates via
  `<mxPoint ... as="sourcePoint"/>` / `as="targetPoint"`.
- **XML-escape** HTML placed in a `value` (`&lt;` · `&gt;` · `&amp;`). An unescaped `<span>` breaks
  parsing.
- Child cells of a group or container use **coordinates relative to the parent**. The coordinate
  origin is the top-left corner (0,0).
- Match the shape to its perimeter — ellipse-family shapes take `perimeter=ellipsePerimeter`. A
  mismatch attaches edge connection points outside the shape.

## Canvas Spec

- `gridSize="10"` is fixed — 114 of 114 pages carry this value without exception.
- `pageWidth` is one of **1600** (default) · **1920** (`deploy/prod/office/` infrastructure layer) ·
  **1200**; `pageHeight` is **1200** (except the portrait 1200×1920 form). Do not invent a new value.
- Place coordinates on the grid, as **multiples of 10**.

## Pages

- **No default page names** — do not leave draw.io's locale-dependent default in place, in any of its
  forms (`Page-1`, `Page 1`, or the localized equivalent). Give a name that
  describes the page's content (existing convention: `Base` · `Client` · `Controller` · `Service` ·
  `Authorization Code`). Twelve remain in existing files, but apply this clause **only to new or
  modified pages**.
- Each `<diagram>` carries a unique `id` attribute.

## Color (fixed palette)

- Use only the five pairs below, and **always specify `fillColor` and `strokeColor` as a pair**. The
  detailed usage mapping is owned by the output style (SoT).

  | fillColor | strokeColor |
  | --------- | ----------- |
  | `#dae8fc` | `#6c8ebf`   |
  | `#d5e8d4` | `#82b366`   |
  | `#e1d5e7` | `#9673a6`   |
  | `#f8cecc` | `#b85450`   |
  | `#fff2cc` | `#d6b656`   |

- Do not introduce an arbitrary color outside that list. **The only exception is a shape library that
  requires its own brand colors** — `#8C4FFF` and `#232F3D` in the `mxgraph.aws4` stencils are part of
  the stencil definition and are not a violation.
- Background groups and inactive elements use `fillColor=none`, or `#f5f5f5` / `#666666`.

## Edit Procedure (multi-page)

- Handle a multi-page file in the order **`list_pages` → `get_page` → `set_page`**. The repository has
  files with up to 9 pages, so reading the whole file wastes context and risks rewriting unrelated pages.
- **Never rewrite the whole file** — do not overwrite a file with `Write` for a change that touches one
  page. `set_page` replaces only the target page and preserves the rest exactly as they were.
- The `content` passed to `set_page` must be a **single `<mxGraphModel>` element** with no `<diagram>` tag.
- Only when creating a new file do you `Write` the complete document including the `<mxfile>` wrapper.

## Quality Gate (required before merge)

```bash
# XML well-formed check (python3 is present on every platform in this repository)
python3 -c "import xml.etree.ElementTree as E,sys; E.parse(sys.argv[1])" "diagram/path/to/file.drawio"
```

- Well-formed passes · two root cells present · no duplicate ids within a page · `source`/`target`
  referential integrity · not stored compressed · no XML comments — these six are the `[MUST]` gate.
- Classify review severity as `[MUST]` / `[SHOULD]` / `[CONSIDER]`; only `[MUST]` blocks a merge.
  Palette deviation, default page names, and off-grid coordinates are `[SHOULD]`.
- Authoring and modification use the `utility-drawio-diagram-skill` skill (author→reviewer loop,
  max 2 retries).
- A standalone quality review of an existing file uses the `/utility-drawio-diagram-review <file-path>`
  command.
