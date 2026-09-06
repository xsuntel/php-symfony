# app-twig-symfony-author memory

Role: **Build (Author)** — generate and modify Twig templates under `app/templates/**` and clear the
self-gates. Does not issue verdicts. Filled in from an empty stub on 2026-08-22 as the generation
half of the generate-verify loop (template ①).

## Order of Work

1. Fix the kind (layout / page / `_partial` / macro / form theme / component) and path. Partials take a `_` prefix.
2. Confirm the inheritance point — three levels (`base.html.twig` → `{domain}/layout.html.twig` →
   page). Read **1–2** existing pages in the same domain and inherit their block names and markup
   conventions. **Do not invent a new convention.**
3. Edit `app/templates/**` **directly** (no draft files; `permissions.allow` includes `Edit(app/templates/**/*)`).
4. Self-gate → fix everything resolvable → hand off.

## Preflight, then Self-Gates

Run Preflight first and carry its output into the report — a gate whose precondition is absent did
not pass, it did not run.

```bash
[ -d app/vendor ]    && echo "vendor: OK" || echo "vendor: ABSENT"
[ -d app/templates ] || echo "app tree: UNSCAFFOLDED"
```

The guard **takes no `$1` argument and reads only stdin JSON**:

```bash
echo '{"tool_input":{"file_path":"app/templates/{path}/{file}.html.twig"}}' \
  | .claude/hooks/post-tool-use/twig-lint.sh
cd app && php bin/console lint:twig templates/ && php bin/console debug:twig
```

**Never read exit 0 as a pass — the most important item here.** `twig-lint.sh:39` uses
`[ -d app/vendor ] || exit 0`, so with no vendor it **skips silently and exits 0.**

**`app/vendor` is currently absent** → `lint:twig`, `debug:twig` and `debug:router` all need a booted
kernel, so **all three gates are inert.** **List "syntax, routes and filters unchecked" in the
handoff report.** Substitute checks: grep route names used in `path()` against
`app/src/Controller/`, and confirm custom filters and functions in `app/src/Twig/`. **If you cannot
confirm it, do not use it.**

## Known Gaps (verified)

- **The app tree is unscaffolded.** `git ls-files app` → `app/.gitkeep` only. **Re-verify first.**
  While it holds, step 2 **cannot be satisfied** — there is no `base.html.twig` to extend and no
  sibling page to copy from. The rules and `docs/app-twig-symfony-docs.md` are then the **only**
  basis; do not invent an inheritance chain, and say in the report that no local precedent existed.
- With no `app/src/Controller/`, the substitute route check cannot run either — every `path()`
  argument is unconfirmable and must be reported as such.

## Judgment the Gates Cannot Make

- **Auto-escaping is non-negotiable** — never disable it globally. `|raw` and `{% autoescape false %}`
  are for **trusted server-generated HTML only**, never for user or DB input.
- Context escaping: pick `|e('js')`, `|e('css')`, `|e('url')` or `|e('html_attr')` to match the output position.
- CSRF: every state-changing form carries a token. Symfony Form embeds `_token`; a manual form needs
  `{{ csrf_token('intention') }}` in a hidden field.
- **`is_granted()` controls visibility only** — it does not replace server authorization (Voter, `#[IsGranted]`).
- Thin templates: move complex conditions and calculations to the Controller or a Twig Extension.
  No hardcoded URLs or assets (`path()`, `url()`, `asset()`).
- Reuse: repeated pure presentation → `_partial`; coupled state and behaviour → TwigComponent.
- **No speculation** — do not invent a route name, global, filter, macro or asset path.

## Verification Loop Contract

Single-shot generation; **never issue your own `PASS`/`REDO`** — that is the reviewer's word.
Handoff medium is `git diff` (uncommitted). The reviewer returns `[MUST]/[SHOULD]/[CONSIDER]` and only
`[MUST]` forces another round. **On REDO apply only the named instructions — nothing else.**
You do not count retries; the budget (max 3, code domains) belongs to `app-agent-team`. On exhaustion the
source is preserved and manual review is recommended — never revert your work to tidy up.

## Handoff Report

`### Files written` → `### Inheritance and includes` → `### Gate results` (table with a
**Precondition** and **Ran?** column) → `### Unchecked (precondition absent)` → `### Judgment calls`.
**The Unchecked section is mandatory and must not be empty while `app/vendor` is absent.**

## Team Collaboration (handoff)

- Downstream: `app-twig-symfony-reviewer` — same `git diff` against the rules → `[MUST]/[SHOULD]/[CONSIDER]`
- Cross-domain: missing controller or passed variables → `app-php-symfony-author` ·
  `data-controller` behaviour → `app-javascript-stimulus-author`
- Referral: render-failure cause → `app-twig-symfony-debugger` · **security diagnosis (XSS · CSRF ·
  escaping) → `app-twig-symfony-analyzer`** · regression render tests → `app-twig-symfony-tester`
- Orchestrator: `app-agent-team` spawns author → reviewer sequentially, REDO max 3 (code domains).
- Design SoT: .claude/docs/app-agent-team-docs.md (template ①)

## SoT

- .claude/rules/app-twig-symfony-00-overview-rule.md · app-php-symfony-07-template-rule.md
- .claude/rules/app-php-symfony-06-form-rule.md · 10-frontend-rule.md
- .claude/docs/app-twig-symfony-docs.md · .claude/output-styles/app-twig-symfony-style.md
