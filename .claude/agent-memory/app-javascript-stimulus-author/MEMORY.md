# app-javascript-stimulus-author memory

Role: **Build (Author)** — generate and modify JavaScript under `app/assets/**` and clear the
self-gate. Does not issue verdicts. Filled in from an empty stub on 2026-08-22 as the generation half
of the generate-verify loop (template ①).

## Order of Work

1. Fix the kind (Stimulus controller / general theme or turbo module / importmap entry) and path.
   Controllers live at `app/assets/controllers/{domain}/{name}_controller.js`; the identifier derives
   from the filename (drop `_controller.js`, `_` → `-`).
2. Read **1–2** existing controllers in the same directory — inherit their `static targets`
   placement, lifecycle handling and event-dispatch conventions. **Also check the `data-controller`
   and `data-*-target` attributes on the Twig template being wired.**
3. Edit `app/assets/**` **directly** (no draft files). Add external packages with
   `php bin/console importmap:require`, never by hand. **`app/assets/vendor/**` is `permissions.deny`
   — never edit it directly.**
4. Self-gate → fix until zero violations → hand off.

## Preflight, then Self-Gate (this domain works without vendor)

The project has **no JS linter or formatter** (a deliberate decision not to take on a new
dependency) — the greps in `js-guard.sh` are the only and complete machine-verdict layer. Run
Preflight first:

```bash
command -v jq >/dev/null && echo "jq: OK"     || echo "jq: ABSENT"
[ -d app/vendor ]        && echo "vendor: OK" || echo "vendor: ABSENT"
[ -d app/assets ]        || echo "app tree: UNSCAFFOLDED"
```

The guard **takes no `$1` argument and reads only stdin JSON**:

```bash
echo '{"tool_input":{"file_path":"app/assets/controllers/{path}/{name}_controller.js"}}' \
  | .claude/hooks/post-tool-use/js-guard.sh
echo "exit=$?"
```

exit 0 = pass (**only if Preflight showed `jq: OK`**) · **exit 2 = violations** on stderr as
`filename:line — advice`. Fix and re-run. Never hand off with a violation outstanding.

**`js-guard.sh` exits 0 silently when `jq` is missing** (`js-guard.sh:18`). `jq` is currently at
`/usr/bin/jq`, but Preflight is what proves it for this run. **Never read exit 0 as a pass** without
it. The guard's checks are not re-listed — their basis is `app-javascript-stimulus-02-quality-rule.md`.
If you touched the importmap, run `php bin/console importmap:audit` (needs vendor; note as unchecked otherwise).

## Known Gaps (verified)

- **The app tree is unscaffolded.** `git ls-files app` → `app/.gitkeep` only. **Re-verify first.**
  While it holds, step 2 **cannot be satisfied** — no sibling controllers, and no template whose
  `data-*` attributes you can confirm. The rules and `docs/app-javascript-stimulus-docs.md` are then
  the **only** basis; do not invent an identifier or target name, and say in the report that no local
  precedent existed.
- With `app/vendor` absent, `importmap:require` and `importmap:audit` cannot run — a new external
  package **cannot be added properly.** Do not hand-write an `importmap.php` entry as a workaround;
  report the blocker.

## Judgment the Gates Cannot Make

- Declarative access: DOM via `this.xTarget`, configuration via `static values` from the template (not code constants).
- **Lifecycle symmetry**: every listener, observer and timer registered in `connect()` is released in
  `disconnect()` **using the same reference**. Keep bound functions in a private field.
  **Turbo caches and restores pages, so asymmetry is a leak.**
- Single responsibility · inter-controller communication via `outlets`/`this.dispatch` (avoid shared global state)
- Async safety: `try/catch` around async handlers, check `response.ok` on `fetch`, `try/catch` around `JSON.parse`
- Separate presentation from logic: do not assemble markup strings in a controller (use Turbo Stream or a template)
- CSRF: send a token with state-changing requests. Follow the existing `csrf_protection_controller.js`
  convention rather than inventing a new mechanism.
- **No speculation** — do not invent a controller identifier, target name, package version or Turbo Stream action name.

## Verification Loop Contract

Single-shot generation; **never issue your own `PASS`/`REDO`** — that is the reviewer's word.
Handoff medium is `git diff` (uncommitted) plus the same guard output. The reviewer returns
`[MUST]/[SHOULD]/[CONSIDER]` and only `[MUST]` forces another round. **On REDO apply only the named
instructions — nothing else.** You do not count retries; the budget (max 3, code domains) belongs to
`app-agent-team`. On exhaustion the source is preserved and manual review is recommended.

## Handoff Report

`### Files written` → `### Controller contract` (identifier, targets, values, classes, outlets, wiring
template) → `### Gate results` (table with a **Precondition** and **Ran?** column) →
`### Unchecked (precondition absent)` → `### Judgment calls`. **The Unchecked section is mandatory
and must not be empty while `app/vendor` is absent.**

## Team Collaboration (handoff)

- Deterministic gate: `.claude/hooks/post-tool-use/js-guard.sh` — the entirety of this domain's machine verdict
- Downstream: `app-javascript-stimulus-reviewer` — same `git diff` and same guard output → `[MUST]/[SHOULD]/[CONSIDER]`
- Cross-domain: templates adding `data-controller`/`data-*-target` → `app-twig-symfony-author` ·
  the server side emitting Turbo Streams → `app-php-symfony-author`
- Referral: runtime (controller not registered, target undefined, importmap resolution failure) →
  `app-javascript-stimulus-debugger` · **security diagnosis (DOM XSS · token storage) →
  `app-javascript-stimulus-analyzer`** · regression → `app-javascript-stimulus-tester`
- Orchestrator: `app-agent-team` spawns author → reviewer sequentially, REDO max 3 (code domains).
- Design SoT: .claude/docs/app-agent-team-docs.md (template ①)

## SoT

- .claude/rules/app-javascript-stimulus-00~03-*-rule.md (00-overview, 01-controller, 02-quality, 03-realtime)
- .claude/rules/app-php-symfony-10-frontend-rule.md (AssetMapper · importmap)
- .claude/docs/app-javascript-stimulus-docs.md · .claude/output-styles/app-javascript-stimulus-style.md
