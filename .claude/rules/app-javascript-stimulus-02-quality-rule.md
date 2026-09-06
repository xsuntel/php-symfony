---
paths:
  - "app/assets/**/*.js"
---

# JavaScript / Stimulus Rules — Security · Performance · Quality

@see .claude/docs/app-javascript-stimulus-docs.md — §6 (Code Conventions), §9 (Verification Checklist)

## Security

| Dangerous pattern                       | Replacement pattern               |
| --------------------------------------- | --------------------------------- |
| `element.innerHTML = userInput`         | `element.textContent = userInput` |
| `innerHTML = serverHtml`                | insert after DOMPurify sanitizing |
| `eval()` / `new Function(str)`          | absolutely forbidden              |
| storing a token/password in localStorage | use an HttpOnly cookie            |

- User-originated text (title, description, and the like) must be rendered with `textContent`.

## Async Handling

- Always wrap an async event handler in `try/catch` — an unhandled rejection is swallowed silently. In the catch, `console.error` with structured context and re-throw if needed.
- Check `response.ok` on a `fetch` response and promote a failure with `throw new Error(...)`.
- Always wrap `JSON.parse` in `try/catch` — malformed JSON throws synchronously.
- Validate data restored from localStorage against a schema (a `version` field is mandatory, check upper bounds, ignore unknown fields) before using it.

## Performance

- Manage listener registration and removal as a pair — keep the bound reference in a private field and remove it with that same reference in `disconnect()`:

```javascript
connect() {
  this.#boundOnResize = this.#onResize.bind(this)
  window.addEventListener('resize', this.#boundOnResize)
}

disconnect() {
  window.removeEventListener('resize', this.#boundOnResize)
}
```

- Do not start a `setInterval` / `setTimeout` without keeping its reference — guarantee `clearInterval` / `clearTimeout` in `disconnect()`.
- Prevent layout thrashing — batch the DOM reads (`offsetHeight` and friends), then batch the writes.

## Verification Checklist

Check this after finishing a controller implementation (review with the `/app-javascript-stimulus-review` command):

```text
[ ] ES modules only — no require()
[ ] static targets/values/classes/outlets declared at the top of the class
[ ] no constructor() override
[ ] event listeners / intervals / observers cleaned up in disconnect()
[ ] no document.querySelector() — this.*Target only
[ ] no innerHTML — textContent or DOMPurify
[ ] try/catch in async handlers
[ ] try/catch around JSON.parse
[ ] no console.log (production code)
[ ] no commented-out code
[ ] no magic numbers — UPPER_SNAKE_CASE const
[ ] private fields are #camelCase (no _prefix)
[ ] stimulus_controller() / stimulus_action() / stimulus_target() used in Twig
[ ] /* stimulusFetch: 'lazy' */ applied to heavy controllers
[ ] lazy controllers checked against the TypeScript removeComments conflict
```
