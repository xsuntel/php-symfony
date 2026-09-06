---
paths:
  - "app/assets/controllers/**/*.js"
  - "app/templates/**/*.twig"
---

# JavaScript / Stimulus Rules — Controllers

@see .claude/docs/app-javascript-stimulus-docs.md — §3 (StimulusBundle Integration) · §5 (Stimulus API Specification), §4 (Controller Design)
@see https://stimulus.hotwired.dev/

## Controller Structure

- Declare `static targets` / `static values` / `static classes` / `static outlets` at the very top of the class.
- Do not override `constructor()` — perform initialization in `initialize()` / `connect()`.
- Event listeners, intervals, and observers registered in `connect()` must be cleaned up in `disconnect()`.
- Access the DOM only through `this.*Target` / `this.*Targets` — `querySelector` is forbidden (see 00-overview).

## Registration and Loading

- Place a controller in `app/assets/controllers/` and StimulusBundle registers it automatically — manual `application.register()` is forbidden.
- Manage third-party Symfony UX controllers in `assets/controllers.json` (`fetch: eager|lazy`).
- Lazy-loading criteria:
  - A controller not used on every page → add the `/* stimulusFetch: 'lazy' */` comment at the top of the file
  - App-wide UI (modal · toast · dropdown) → `eager`
  - Heavy external SDK dependency (maps · charts) → `lazy`
- When using TypeScript, check that `removeComments: true` does not strip the lazy comment.

## Twig Helpers (mandatory)

Do not hand-write `data-*` attribute strings — use the StimulusBundle Twig helpers:

```twig
<div {{ stimulus_controller('column', { 'status': 'todo' }, { 'active': 'ring-2 ring-blue-500' }) }}>
  <span {{ stimulus_target('column', 'counter') }}>0</span>
  <button {{ stimulus_action('board', 'removeCard', 'click', { 'id': card.id }) }}>Delete</button>
</div>

{# pass to a form with .toArray() #}
{{ form_row(form.title, { attr: stimulus_action('card', 'validateTitle', 'input').toArray() }) }}
```

- Combine several controllers/actions/targets by chaining the `|stimulus_*` filters.

## Communication Between Controllers

- Child → parent: custom event `this.dispatch('updated', { detail: {...}, bubbles: true })`, received in HTML via `data-action="card:updated->board#save"`.
- Parent → child direct call: use an Outlet (`static outlets`).
- For a cancelable flow, call `this.dispatch('deleting', { cancelable: true })` and then check `event.defaultPrevented`.
- Calling `application.getControllerForElementAndIdentifier()` directly is forbidden.
