# app-javascript-stimulus-debugger memory

## Environment constants (verified)

- Stimulus controllers are **auto-registered** from `app/assets/controllers/` via `stimulus_bootstrap.js`.
- The SoT for JS package versions is `app/importmap.php` (not package.json). importmap resolution failure is a common cause of load errors.

## Frequent root causes

- Controller not registered / `data-controller` name mismatch / target (`this.xTarget`) mismatch / listener not re-bound after a Turbo update (memory leak) / importmap not resolved.
- Confirm `this.*Target` is used instead of `document.querySelector()`.

## SoT

- .claude/rules/app-javascript-stimulus-00~02-*-rule.md
- .claude/docs/app-javascript-stimulus-docs.md
