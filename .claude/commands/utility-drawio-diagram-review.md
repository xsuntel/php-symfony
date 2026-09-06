---
description: "Assesses the structural integrity and project-convention compliance of a draw.io diagram (.drawio) file and provides structured improvement recommendations."
argument-hint: "[path of the .drawio file to analyze]"
---

Analyze the following draw.io diagram file:

**`$ARGUMENTS`**

> **If the argument is empty**, ask once for the target file path and stop.
> Do not scan `diagram/**` exhaustively or guess a target — with 57 files / 114 pages, a full scan
> burns context while still missing the file the user meant.

The single sources of truth for the judgment criteria are **`utility-drawio-diagram-rule` for
structure, storage format, canvas, and palette, and the output style for XML authoring style and
anti-patterns**. Read them at the start, compare each clause against the target file, flag violations
with an **exact line number (or cell id)**, and propose a concrete fix (an XML fragment).

**For a multi-page file, call `mcp__drawio-tool__list_pages` first** to confirm the page list, then read
and review page by page with `get_page`. Do not `Read` the whole file.

> **Caution:** this repository has **known drift** — 2-space indentation in existing files (`base/`),
> outdated `version` attributes, and 12 remaining default page names. These are pre-existing state
> recorded in `## 1` of the docs; do not escalate them to `[MUST]` when they are parts of the target
> file this change does not touch. The `mxgraph.aws4` stencil brand colors (`#8C4FFF` · `#232F3D`) are
> likewise not a palette deviation.

@see .claude/rules/utility-drawio-diagram-rule.md — judgment criteria (SoT: storage format · structural integrity · canvas · palette · edit procedure)
@see .claude/output-styles/utility-drawio-diagram-style.md — judgment criteria (SoT: XML skeleton · style strings · anti-pattern table)
@see .claude/docs/utility-drawio-diagram-docs.md — measured statistics · shape catalog · MCP tools · known drift
@see diagram/CLAUDE.md — directory structure · file naming (SoT)
@see <https://www.drawio.com/docs/reference/diagram-generation/> — official programmatic generation contract
@see <https://www.drawio.com/docs/reference/diagram-generation/style-reference/> — official style-string reference

> This command is **for reviewing an existing file only**. Authoring and modification are performed by
> the `utility-drawio-diagram-skill` skill via its `utility-drawio-diagram-author` →
> `utility-drawio-diagram-reviewer` loop, and the generation contract is owned by the author agent.

## Review Procedure

Compare the following items in order.

- **well-formed** — does XML parsing succeed?
  `python3 -c "import xml.etree.ElementTree as E,sys; E.parse(sys.argv[1])" "$ARGUMENTS"`
- **Storage format** — is there no `compressed="true"`, no Base64 `<diagram>` body, and no XML comment
  (`<!-- -->`)?
- **Root cells** — does every page have `<mxCell id="0"/>` and `<mxCell id="1" parent="0"/>`?
- **parent validity** — is every cell's `parent` either `1` or the id of a group/layer that exists?
- **id uniqueness** — are there no duplicate ids within a page?
- **Referential integrity** — do an edge's `source`/`target` name ids that exist on the same page? Do
  unconnected edges have `mxPoint` endpoints?
- **vertex/edge exclusivity · geometry** — does no cell carry both, and does every cell have
  `<mxGeometry ... as="geometry"/>`?
- **Escaping** — is HTML in a `value` escaped as `&lt;` · `&gt;` · `&amp;`?
- **Canvas spec** — is `gridSize="10"`, `pageWidth` 1600/1920/1200, and `pageHeight` 1200/1920? Are
  coordinates aligned to multiples of 10?
- **Palette** — are only the five pairs used, with `fillColor` and `strokeColor` paired (`aws4` stencil
  brand colors exempt)?
- **Pages** — is each `<diagram>` `id` unique, and is the page name something other than draw.io's
  locale-dependent default (`Page-1`, or its localized equivalent)?
- **Shape consistency** — do shapes and perimeters match (ellipse family → `perimeter=ellipsePerimeter`)?
  Are no non-existent stencil names referenced?
- **Layout conventions** — are shape sizes, spacing, and color assignments consistent with comparable
  files in the same directory?

## Output Format

### Summary

| Category | Status (OK / WARN / FAIL) | Issues |
| --- | --- | --- |
| XML well-formed | | |
| Storage format (uncompressed · comments) | | |
| Root cells and parent | | |
| id uniqueness | | |
| Edge referential integrity | | |
| geometry and escaping | | |
| Canvas spec | | |
| Palette consistency | | |
| Page naming | | |
| Shape consistency | | |

### Critical Issues (must fix)

For each issue: **[line N · cell `id`]** `[MUST]` description → the recommended fix, including an XML
fragment.

Assign `[MUST]` only to defects that stop the file opening or make elements disappear silently —
well-formed failure, missing root cells, duplicate ids, a broken `source`/`target`, compressed storage,
XML comments, or missing escaping.

### Improvement Suggestions (fix recommended)

For each suggestion: **[line N · cell `id`]** `[SHOULD]` description → the recommended approach.

Palette deviation, default page names, off-grid coordinates, and canvas-spec deviation are `[SHOULD]`.

### Refactoring Suggestions

Describe structural changes (splitting or merging pages, regrouping, swapping shape libraries) as
`[CONSIDER]`, with before/after XML examples. Only `[MUST]` blocks a merge.
