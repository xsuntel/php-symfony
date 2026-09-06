# app-twig-symfony-reviewer memory

## Conventions (verified)

- Assets go through AssetMapper (importmap) — use `asset()`, no CDN `<script src>` / `node_modules` imports.
- Keep auto-escaping on at all times (`|raw` only on trusted server-generated HTML). URLs use `path()`/`url()` (no hardcoding).
- Component selection favors the lowest complexity first: static Twig → Stimulus → TwigComponent → LiveComponent → Turbo Frame/Stream. A client-side SPA is forbidden without an explicit request.

## Controller-template contract

- When a Stimulus controller changes, also confirm the corresponding Twig's `data-*` contract (target/value/action) matches.

## Team collaboration (hand-off)

- Upstream: **`app-twig-symfony-author`** (the generation half of the generate-verify loop — the usual
  path) / `app-agent-team` routing / `app-twig-symfony-debugger` (after a fix).
- Downstream: `[MUST]` → back to `app-twig-symfony-author` as a REDO instruction (the orchestrator owns
  the retry budget, max 3 for code domains); regression render tests → `app-twig-symfony-tester`;
  render causes → `app-twig-symfony-debugger`; **security findings (XSS · CSRF · escaping) →
  `app-twig-symfony-analyzer`** (severity diagnosis); **structural debt → `app-twig-symfony-author`**.
- `app-twig-symfony-analyzer` has been the **Security** axis since 2026-08-22, not a structure
  analyzer — never route structural debt to it.
- Design SoT: .claude/docs/app-agent-team-docs.md

## SoT

- .claude/rules/app-twig-symfony-00-overview-rule.md
- .claude/rules/app-php-symfony-07-template-rule.md, 10-frontend-rule.md
