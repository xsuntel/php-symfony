---
name: utility-drawio-diagram-skill
description: "Authors, reviews, and applies draw.io diagrams (.drawio) under diagram/** as a two-agent (author/reviewer) workflow. Always use it for natural-language requests like 'draw a diagram', 'make me a drawio', 'edit this .drawio', or 'add an architecture diagram' (in any language). Do not use it when only a quality review of an existing file is needed — use the /utility-drawio-diagram-review command instead."
---

# Drawio Diagram Skill

Calls a two-agent team (`utility-drawio-diagram-author` → `utility-drawio-diagram-reviewer`) in
sequence to author and review `.drawio` XML, then applies it to the target file on a PASS verdict.

- Scope: `.drawio` files under `diagram/**`
- Intermediate artifact location: `./.claude/tmp/utility/` (registered in `.gitignore`)

@see .claude/rules/utility-drawio-diagram-rule.md — storage format · structural integrity · canvas · palette · edit procedure (SoT)
@see .claude/output-styles/utility-drawio-diagram-style.md — XML skeleton · style strings · anti-patterns (SoT)
@see .claude/docs/utility-drawio-diagram-docs.md — measured statistics · shape catalog · MCP tools · sequence recipes
@see .claude/commands/utility-drawio-diagram-review.md — standalone review of an existing file (the path that does not use this loop)
@see diagram/CLAUDE.md — directory structure · file naming (SoT)

---

## Workflow

1. **Precondition check**
   - Fix the target **file path** and **page**, and the intent (create new / replace an existing page).
   - For an existing file, confirm the page list with `mcp__drawio-tool__list_pages` and identify the
     target page.
   - If the target is unclear, **ask once and stop** — do not guess and overwrite the wrong page.
   - For a new file, confirm the placement path matches the taxonomy and naming rules in
     `diagram/CLAUDE.md`.

2. **Call the Author**
   - Call the `utility-drawio-diagram-author` agent to produce
     `./.claude/tmp/utility/drawio/diagram-draft.xml`.
   - State the target path, page, and application method (`set_page` | `Write`) fixed in step 1
     explicitly in the prompt, plus **the round number** (`round: 1`, `round: 2`, …). Both agents use the
     round for their freshness and anti-thrash gates; `.claude/tmp/` is never cleaned, so without it a
     leftover draft from an earlier run is indistinguishable from a fresh one.

3. **Call the Reviewer**
   - Call the `utility-drawio-diagram-reviewer` agent to produce
     `./.claude/tmp/utility/drawio/diagram-review.md`.
   - State the same target, page, application method, and round number, so the reviewer can check the
     draft header against what was actually requested.

4. **Branch on the verdict**
   - Read **line 1** of `./.claude/tmp/utility/drawio/diagram-review.md` and branch on that token alone —
     the reviewer writes exactly `Verdict: PASS` or `Verdict: REDO` there.
     - `Verdict: PASS` → step 4a.
     - `Verdict: REDO` → step 4b.
     - **Anything else** → the verdict is malformed. **Fail closed:** treat it as REDO, say so, and
       count the round.
   - **4a — PASS:** for `set_page`, run the **pre-apply cell-count gate** first (see
     `## Cautions When Applying`) — compare the draft's `mxCell` count against a live
     `mcp__drawio-tool__get_page`. A shortfall the revision intent does not explain means stop and report,
     not apply. Then apply the draft to the target:
     - Replacing an existing page → `mcp__drawio-tool__set_page(path, page, content)`, passing the draft
       **without its header line**
     - New file → `Write` the complete document including the `<mxfile>` wrapper
     - After applying, read back with `mcp__drawio-tool__get_page` to confirm the root cells and the
       cell count, then report the result.
   - **4b — REDO:** include the revision instructions from the review file's latest `## Round N` section
     in the prompt when re-calling the Author, and repeat from step 2. The Author also reads
     `./.claude/tmp/utility/drawio/diagram-review.md` directly, so keep your paraphrase faithful to it —
     the file is what it applies. **Maximum 2 retries.**

5. **Retry-limit handling**
   - If the verdict is still REDO after 2 retries, **do not apply anything to the target file.**
   - Present the last draft to the user and stop with the warning "auto-approval limit reached —
     manual review recommended".

---

## Cautions When Applying

- **`set_page` replaces the target page wholesale.** Even for a partial edit, every cell on that page
  must be present in the draft; an omitted cell is deleted. This is the worst failure the loop can
  produce, so it is gated three times: the Author records `baseline-cells` in the draft header, the
  Reviewer's cell-count gate compares it against the live page, and the **pre-apply gate in step 4a is
  required, not advisory** — compare the numbers yourself immediately before `set_page`, because the
  reviewer's reading is a round old and the page may have changed since.

  ```bash
  python3 -c "import sys,xml.etree.ElementTree as E; \
  d=E.fromstring(open(sys.argv[1],encoding='utf-8').read().split('\n',1)[1]); \
  print('draft cells:', len([c for c in d.iter('mxCell')]))" \
    .claude/tmp/utility/drawio/diagram-draft.xml
  ```

- **The draft's first line is a header, not XML** (`target: … | page: … | apply: … | round: …`). Strip it
  before passing the body to `set_page` or `Write`. The scripts in both agents already read past it.
- **Use a whole-file `Write` only for a new file** — overwriting an existing multi-page file produces a
  diff on pages that were not modified.
- Applying must be reversible — before working, check with `git status` whether the target file already
  has uncommitted changes, and if so tell the user before proceeding.
