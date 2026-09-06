---
paths:
  - "app/assets/**/*.js"
---

# JavaScript / Stimulus Rules — Overview · Modules · Naming

@see .claude/docs/app-javascript-stimulus-docs.md

## Rule Files

| File                                          | Area of responsibility                                                     |
| --------------------------------------------- | -------------------------------------------------------------------------- |
| app-javascript-stimulus-00-overview-rule.md   | Module system, variable declaration, file naming, absolute prohibitions    |
| app-javascript-stimulus-01-controller-rule.md | Stimulus controller structure, Twig helpers, lazy loading, controller comms |
| app-javascript-stimulus-02-quality-rule.md    | Security, performance, async handling, verification checklist              |
| app-javascript-stimulus-03-realtime-rule.md   | Mercure (SSE) + Turbo Streams server → browser push                        |

## Absolute Prohibitions

- Do not use `eval()` / `new Function(str)`.
- Do not assign user input to `innerHTML` — insert via `textContent`, or sanitize with DOMPurify first.
- Do not use `document.querySelector()` / `this.element.querySelector()` — use `this.*Target`, Outlets, or custom events.
- Do not use `require()` / `module.exports` — ES Modules only.
- Do not leave `console.log` / `console.debug` in production code.
- Do not store tokens or passwords in localStorage — use HttpOnly cookies.

## Module System

- Use only `import`/`export`. A Stimulus controller is `export default class extends Controller`; utilities use named exports.
- Sort imports into two groups: (1) framework/third-party, (2) local modules — separated by a blank line.
- Do not leave unused imports behind.

```javascript
import { Controller } from "@hotwired/stimulus";

import { debounce } from "../utils/debounce";

export default class extends Controller {}
```

## Variable Declaration

- Use `const` by default, and `let` only when reassignment is required — `var` is forbidden.
- Module-level constants are `UPPER_SNAKE_CASE` — magic numbers must always be named.
- Private fields are `#camelCase` — do not use the `_prefix` notation.

## File Naming and Identifiers

| Filename                        | Stimulus identifier | `data-controller`                    |
| ------------------------------- | ------------------- | ------------------------------------ |
| `board_controller.js`           | `board`             | `data-controller="board"`            |
| `users/list_item_controller.js` | `users--list-item`  | `data-controller="users--list-item"` |

- Filename: `snake_case_controller.js`, located in `app/assets/controllers/`.
- Identifier: `kebab-case` (multi-word) or `namespace--name` (subdirectory).
- The `data-controller` value must match the filename for StimulusBundle auto-registration to work.

## Code Quality

- When a function exceeds 30 lines, split the responsibility out into a private method.
- Do not leave commented-out blocks of code behind — rely on git history.
- Extract code duplicated across 3 or more lines into a utility module under `app/assets/utils/`.
