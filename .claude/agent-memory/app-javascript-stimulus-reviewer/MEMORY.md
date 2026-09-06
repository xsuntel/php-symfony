# app-javascript-stimulus-reviewer memory

## Environment constants (verified)

- **The version SoT is `app/importmap.php`** (not package.json). If it cannot be confirmed, do not guess.
- AssetMapper convention: declare JS packages via `importmap:require` — no `npm install` / `node_modules` imports, no CDN `<script src>`.
- Stimulus controllers are auto-registered from `app/assets/controllers/`.

## Standing review checks

- Component selection favors the lowest complexity first (Twig < Stimulus < TwigComponent < LiveComponent < Turbo). A client-side SPA is forbidden without an explicit request.
- When a controller changes, confirm the corresponding Twig's `data-*` contract matches. Use `this.*Target` instead of `document.querySelector()`.
- Only `[MUST]` blocks the merge.

## Team collaboration (hand-off)

- Upstream: **`app-javascript-stimulus-author`** (the generation half of the generate-verify loop — the
  usual path) / `app-agent-team` routing / `app-javascript-stimulus-debugger` (after a fix).
- Downstream: `[MUST]` → back to `app-javascript-stimulus-author` as a REDO instruction (the
  orchestrator owns the retry budget, max 3 for code domains); regression →
  `app-javascript-stimulus-tester`; runtime causes → `app-javascript-stimulus-debugger`;
  **security findings (DOM XSS · token storage) → `app-javascript-stimulus-analyzer`** (severity
  diagnosis); **structural debt → `app-javascript-stimulus-author`**.
- `app-javascript-stimulus-analyzer` has been the **Security** axis since 2026-08-22, not a structure
  analyzer — never route structural debt to it.
- Design SoT: .claude/docs/app-agent-team-docs.md

## SoT

- .claude/rules/app-javascript-stimulus-00~02-*-rule.md
- .claude/hooks/post-tool-use/js-guard.sh (the domain's machine-verdict layer)
