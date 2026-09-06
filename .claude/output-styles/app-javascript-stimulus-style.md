---
name: app-javascript-stimulus-style
description: ES Modules + Stimulus (Hotwire) — style guide applied to every file under app/assets/controllers/
keep-coding-instructions: true
---

# JavaScript Style Guide

This document governs **output presentation and formatting**. The details of the coding standards
(modules · variables · modern syntax · class design · Stimulus conventions · async error handling) and
the code examples are owned by the rules as the single source of truth (SoT) — not restated here.

@see .claude/rules/app-javascript-stimulus-00-overview-rule.md ~ 03-realtime-rule.md — coding standards (SoT)
@see .claude/rules/app-php-symfony-10-frontend-rule.md — AssetMapper · importmap · bootstrap
@see .claude/docs/app-javascript-stimulus-docs.md — StimulusBundle integration · component examples

## Standards Compliance (Summary)

- ES Modules only (`import`/`export`), `const` by default · no `var`, `async/await` (no raw `.then()`).
- Modern syntax (`?.` · `??` · logical assignment · destructuring · spread · template literals · private `#field`).
- Stimulus: one controller = one behavior, `static targets/values/classes/outlets` declared at the top,
  `connect()/disconnect()` hooks (no `constructor`), `this.*Target` (no `document.querySelector`),
  `{name}ValueChanged()` · outlets · `this.dispatch()`. See the rules above for details and examples.
- Add third-party packages with `importmap:require` (no `<script src>` · no `node_modules` import), use the
  `.js` extension on relative imports, and no path aliases.

## Formatting

The single source of truth (SoT) for formatting is `app/.prettierrc.json`; the list below reflects that
configuration and the existing code under `app/assets/**` as-is. Never change just one of the three —
`.prettierrc.json` · `app/.editorconfig` · this document move together in the same change.

- Semicolons: **used** (`semi: true`).
- Quotes: single quotes `'` for strings, backticks for template literals (`singleQuote: true`).
- Indentation: 4 spaces (`tabWidth: 4`). Soft line-length limit of 120 characters (`printWidth: 120`).
- Trailing comma on multi-line arrays · objects.
- A space before the opening brace `{` of a function body, and no space between the name and `(`.

## Code Block Format

- Wrap JavaScript code in a fenced code block with the `javascript` language identifier.
- When creating a controller file, state the path relative to the repository root as a comment right
  before the block:

```
// app/assets/controllers/toggle_controller.js
```

## Multi-File Responses

When creating multiple files, put one path comment per file immediately before its opening fence,
followed by the full file content.

## Inline Explanation Format

Use only the following headings after a code block:

- **How it works** — what the code does, 3–5 items
- **Why this way** — the architectural or performance rationale
- **Next steps** — `importmap:require`, Twig wiring, etc. (only when relevant)

Prohibited: preambles like "Here is the code:", summaries of what was written, phrases like
"Great question!" · "Certainly!".
