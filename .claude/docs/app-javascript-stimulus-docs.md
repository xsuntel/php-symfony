# Kanban Board — Stimulus Technical Specification (Worked Example)

This document is a **worked example of a Stimulus/Turbo/AssetMapper implementation** using a Kanban
Board as the subject, and serves as a **detailed reference** for controller design, the Stimulus API,
and code conventions. The enforced judgment criteria (SoT) are the rule files — if there is a conflict
with the rules, the rules take precedence.

> Note: the product requirements and localStorage schema sections are based on the example domain
> (Kanban Board), not the actual project domain. What is reusable is the Stimulus patterns, API, and
> code conventions.

@see .claude/rules/app-javascript-stimulus-00-overview-rule.md ~ app-javascript-stimulus-02-quality-rule.md — judgment criteria (SoT)
@see .claude/output-styles/app-javascript-stimulus-style.md — code style
@see app/assets/CLAUDE.md — asset directory conventions

---

## 1. Product Requirements

### Primary Goals

1. Intuitive task management system — usable within 5 minutes
2. Clear task-status visualization — three distinct columns (Todo / In Progress / Done)
3. Reliable state management — preserve state without data loss
4. Smooth drag-and-drop experience — 60fps target

### User Stories (7)

| # | Story |
| --- | --- |
| 1 | A user can create a card and enter a title/description |
| 2 | A user can edit a card inline or delete it |
| 3 | A user can move a card to another column via drag and drop |
| 4 | A user can see the card count of each column in real time |
| 5 | A user can restore the previous state even after refreshing the page |
| 6 | A user can create/edit/delete a card using the keyboard only |
| 7 | A user can use the same UI on mobile/tablet |

### Functional Requirements (15)

#### Card Management (4)

- Create a card (title required, description optional)
- Inline-edit a card (restore original on edit cancel)
- Delete a card (immediate delete without confirmation, or a confirmation dialog)
- View cards (preserve order within a column)

#### Drag and Drop (4)

- Move a card to another column
- Visual feedback for the drop area during a drag
- Drag cancel (Esc key) support
- Touch event support (mobile)

#### Column Management (2)

- Three fixed columns (Todo / In Progress / Done)
- Real-time card-count update per column

#### UI (3)

- Responsive layout (single column on mobile, three columns on tablet/desktop)
- Operation success/failure feedback (toast notification)
- Keyboard accessibility (Tab, Enter, Esc support)

#### Data (2)

- Automatic localStorage save (500ms debounce)
- Automatic restore on page load

### Non-Functional Requirements

| Item | Criterion |
| --- | --- |
| Performance | 60fps drag, initial load within 2 seconds |
| Accessibility | WCAG 2.1 AA, full keyboard support |
| Compatibility | Latest Chrome/Firefox/Safari, mobile/tablet |
| Security | XSS/CSRF prevention, input validation, localStorage schema validation |

### Constraints

- Frontend-centric (uses localStorage, no separate backend)
- Single-user
- Maximum number of cards: 100 (controller-level guard)

---

## 2. Technical Environment

| Item | Version / Path |
| --- | --- |
| Stimulus | 3.2.2 (`@hotwired/stimulus`) |
| StimulusBundle | `symfony/stimulus-bundle` (AssetMapper integration) |
| stimulus-use | 0.52.3 |
| Asset management | Symfony AssetMapper (`app/importmap.php`) |
| Controller location | `app/assets/controllers/` |
| UX controller registration | `app/assets/controllers.json` |
| File naming | `name_controller.js` → identifier `name` |

> **Note:** dependencies are managed via `importmap.php`, not `package.json`. Do not add packages with `npm install`.

---

## 3. Symfony StimulusBundle Integration

### 3.1 Automatic Controller Registration

StimulusBundle automatically registers every `.js` file in the `assets/controllers/` directory.
`assets/stimulus_bootstrap.js` is the entry point, and `startStimulusApp()` initializes the loader.

```javascript
// assets/stimulus_bootstrap.js
import { startStimulusApp } from '@symfony/stimulus-bundle'

const app = startStimulusApp()
export { app }
```

Configuration file (`config/packages/stimulus.yaml`):

```yaml
stimulus:
    controller_paths:
        - '%kernel.project_dir%/assets/controllers'
    controllers_json: '%kernel.project_dir%/assets/controllers.json'
```

### 3.2 UX Package Controllers — controllers.json

Third-party Symfony UX controllers are managed via `assets/controllers.json`.

```json
{
    "controllers": {
        "@symfony/ux-live-component": {
            "live": { "enabled": true, "fetch": "eager" }
        },
        "@symfony/ux-turbo": {
            "turbo-core": { "enabled": true, "fetch": "eager" },
            "mercure-turbo-stream": { "enabled": false, "fetch": "eager" }
        },
        "@stimulus-components/dropdown": {
            "dropdown": { "enabled": true, "fetch": "lazy" }
        }
    },
    "entrypoints": []
}
```

`fetch` values:

- `"eager"` — included in the initial bundle (loaded immediately)
- `"lazy"` — dynamically loaded when the corresponding `data-controller` attribute appears in the DOM

### 3.3 Lazy Controllers

Apply to controllers that need initial-page-load optimization.
Adding the top-of-file comment `/* stimulusFetch: 'lazy' */` makes StimulusBundle recognize it automatically.

```javascript
// assets/controllers/drag_controller.js
import { Controller } from '@hotwired/stimulus'

/* stimulusFetch: 'lazy' */
export default class extends Controller {
  // ...
}
```

Application criteria:

- Controllers not used on every page → `lazy`
- App-wide UI (modals, toasts, dropdowns) → `eager`
- Controllers with heavy external SDK dependencies (maps, charts) → `lazy`

> **Note:** when using TypeScript, if `tsconfig.json` has the `removeComments: true` option, the comment is stripped and lazy loading does not work.

### 3.4 Twig Helper Functions

Symfony StimulusBundle provides helper functions to write HTML `data-*` attributes declaratively in Twig.
Use these functions rather than writing `data-controller="..."` strings directly.

#### stimulus_controller()

```twig
{# Basic #}
<div {{ stimulus_controller('board') }}>
{# → data-controller="board" #}

{# Passing values #}
<div {{ stimulus_controller('board', { 'savedAt': '', 'maxCards': 100 }) }}>
{# → data-controller="board"
      data-board-saved-at-value=""
      data-board-max-cards-value="100" #}

{# Values + CSS Classes #}
<div {{ stimulus_controller('column', { 'status': 'todo' }, { 'active': 'ring-2 ring-blue-500' }) }}>
{# → data-controller="column"
      data-column-status-value="todo"
      data-column-active-class="ring-2 ring-blue-500" #}

{# Values + Classes + Outlets #}
<div {{ stimulus_controller('board',
        { 'savedAt': '' },
        { 'saving': 'opacity-50' },
        { 'column': '.column' }) }}>
{# → data-controller="board"
      data-board-saved-at-value=""
      data-board-saving-class="opacity-50"
      data-board-column-outlet=".column" #}

{# Chaining multiple controllers #}
<div {{ stimulus_controller('board')|stimulus_controller('drag') }}>
{# → data-controller="board drag" #}

{# Applying to a form #}
{{ form_start(form, { attr: stimulus_controller('card', { 'id': card.id }).toArray() }) }}
```

#### stimulus_action()

```twig
{# Basic (uses the element default when the event is omitted) #}
<button {{ stimulus_action('card', 'startEdit') }}>Edit</button>
{# → data-action="card#startEdit" #}

{# Explicit event #}
<button {{ stimulus_action('card', 'deleteCard', 'click') }}>Delete</button>
{# → data-action="click->card#deleteCard" #}

{# Action parameters #}
<button {{ stimulus_action('board', 'removeCard', 'click', { 'id': card.id }) }}>Delete</button>
{# → data-action="click->board#removeCard"
      data-board-id-param="{{ card.id }}" #}

{# Chaining multiple actions #}
<form {{ stimulus_action('card', 'saveEdit', 'submit')|stimulus_action('card', 'cancelEdit', 'keydown.esc') }}>
{# → data-action="submit->card#saveEdit keydown.esc->card#cancelEdit" #}

{# Applying to a form field #}
{{ form_row(form.title, { attr: stimulus_action('card', 'validateTitle', 'input').toArray() }) }}
```

#### stimulus_target()

```twig
{# Single target #}
<span {{ stimulus_target('column', 'counter') }}>0</span>
{# → data-column-target="counter" #}

{# Multiple targets #}
<div {{ stimulus_target('card', 'viewMode') }} {{ stimulus_target('drag', 'item') }}>
{# → data-card-target="viewMode" data-drag-target="item" #}

{# Chaining #}
<div {{ stimulus_target('card', 'viewMode')|stimulus_target('drag', 'item') }}>
{# → data-card-target="viewMode" data-drag-target="item" #}

{# Applying to a form field #}
{{ form_row(form.title, { attr: stimulus_target('card', 'titleInput').toArray() }) }}
```

#### Full Twig Template Example (card)

```twig
{# templates/kanban/_card.html.twig #}
<div {{ stimulus_controller('card', { 'id': card.id, 'status': card.status }) }}
     class="card bg-white rounded shadow p-3">

  <div {{ stimulus_target('card', 'viewMode') }}>
    <span {{ stimulus_target('card', 'title') }}
          class="font-medium">{{ card.title }}</span>
    <p {{ stimulus_target('card', 'description') }}
       class="text-sm text-gray-500">{{ card.description }}</p>

    <div class="flex gap-2 mt-2">
      <button {{ stimulus_action('card', 'startEdit') }}
              class="text-xs text-blue-600">Edit</button>
      <button {{ stimulus_action('card', 'deleteCard') }}
              class="text-xs text-red-600">Delete</button>
    </div>
  </div>

  <form {{ stimulus_target('card', 'editForm') }}
        {{ stimulus_action('card', 'saveEdit', 'submit')|stimulus_action('card', 'cancelEdit', 'keydown.esc') }}
        hidden>
    <input {{ stimulus_target('card', 'titleInput') }}
           type="text" value="{{ card.title }}">
    <textarea {{ stimulus_target('card', 'descriptionInput') }}>{{ card.description }}</textarea>
    <button type="submit">Save</button>
    <button type="button" {{ stimulus_action('card', 'cancelEdit') }}>Cancel</button>
  </form>
</div>
```

---

## 4. Controller Design

The Kanban board is composed of 4 Stimulus controllers. Each controller has a single UI responsibility.

```text
app/assets/controllers/
├── board_controller.js    ← whole board, localStorage serialize/restore   (eager)
├── column_controller.js   ← per column (status distinction, card count)    (eager)
├── card_controller.js     ← card CRUD, inline editing                      (eager)
└── drag_controller.js     ← drag-and-drop handling                         (lazy)
```

Dependency direction: `board → column → card` (one-way). `drag` is independent.

### 4.1 board_controller

Manages the whole board. Has the single responsibility of localStorage serialization/restoration.

```javascript
// assets/controllers/board_controller.js
import { Controller } from '@hotwired/stimulus'

const STORAGE_KEY  = 'kanban-board'
const DEBOUNCE_MS  = 500

export default class extends Controller {
  static targets = ['status']
  static values  = { savedAt: { type: String, default: '' } }
  static outlets = ['column']

  connect() {
    this.#debouncedSave = this.#debounce(() => this.#saveToStorage(), DEBOUNCE_MS)
    this.#loadFromStorage()
  }

  // Receives card:updated / card:deleted / card:moved events
  save() {
    this.#debouncedSave()
  }

  #debouncedSave = null

  #saveToStorage() {
    try {
      const state = { version: 1, savedAt: new Date().toISOString(), columns: {}, cards: {} }
      this.columnOutlets.forEach(col => { state.columns[col.statusValue] = col.serialize() })
      localStorage.setItem(STORAGE_KEY, JSON.stringify(state))
      this.savedAtValue = state.savedAt
    } catch (error) {
      console.error('Failed to save board state', { error })
    }
  }

  #loadFromStorage() {
    try {
      const raw  = localStorage.getItem(STORAGE_KEY)
      const data = raw ? JSON.parse(raw) : null
      if (!this.#isValidSchema(data)) return
      this.columnOutlets.forEach(col => col.restore(data.columns[col.statusValue] ?? {}))
    } catch (error) {
      console.error('Failed to load board state', { error })
    }
  }

  #isValidSchema(data) {
    return data && data.version === 1 && typeof data.columns === 'object'
  }

  #debounce(fn, ms) {
    let timer
    return (...args) => { clearTimeout(timer); timer = setTimeout(() => fn(...args), ms) }
  }
}
```

Twig example:

```twig
<div {{ stimulus_controller('board', {}, {}, { 'column': '.column' }) }}
     data-action="card:updated->board#save card:deleted->board#save card:moved->board#save">
```

### 4.2 column_controller

Manages each column (Todo / In Progress / Done).

```javascript
// assets/controllers/column_controller.js
import { Controller } from '@hotwired/stimulus'

const MAX_CARDS = 100

export default class extends Controller {
  static targets = ['cards', 'counter', 'addButton', 'addForm', 'titleInput']
  static values  = {
    status:  { type: String, default: 'todo' },
    count:   { type: Number, default: 0 },
    adding:  { type: Boolean, default: false },
  }
  static outlets = ['card']

  countValueChanged(count) {
    this.counterTarget.textContent = count
  }

  addingValueChanged(adding) {
    this.addFormTarget.hidden   = !adding
    this.addButtonTarget.hidden = adding
    if (adding) this.titleInputTarget.focus()
  }

  showAddForm() {
    if (this.countValue >= MAX_CARDS) return
    this.addingValue = true
  }

  hideAddForm() {
    this.titleInputTarget.value = ''
    this.addingValue = false
  }

  addCard(event) {
    event.preventDefault()
    const title = this.titleInputTarget.value.trim()
    if (!title) return
    this.dispatch('requested', { detail: { title, status: this.statusValue } })
    this.hideAddForm()
  }

  serialize() {
    return { cards: this.cardOutlets.map(c => c.idValue) }
  }

  restore(data) { /* called by board_controller */ }
}
```

Twig example:

```twig
{# templates/kanban/_column.html.twig #}
<div {{ stimulus_controller('column', { 'status': status }, { 'active': 'ring-2' }, { 'card': '.card' }) }}
     class="column flex flex-col gap-2">

  <header class="flex items-center justify-between">
    <h2>{{ label }}</h2>
    <span {{ stimulus_target('column', 'counter') }}>0</span>
  </header>

  <div {{ stimulus_target('column', 'cards') }} class="flex flex-col gap-2 min-h-16">
    {% for card in cards %}
      {% include '_card.html.twig' %}
    {% endfor %}
  </div>

  <button {{ stimulus_target('column', 'addButton') }}
          {{ stimulus_action('column', 'showAddForm') }}>
    + Add card
  </button>

  <form {{ stimulus_target('column', 'addForm') }}
        {{ stimulus_action('column', 'addCard', 'submit')|stimulus_action('column', 'hideAddForm', 'keydown.esc') }}
        hidden>
    <input {{ stimulus_target('column', 'titleInput') }} type="text" placeholder="Card title">
    <button type="submit">Add</button>
  </form>
</div>
```

### 4.3 card_controller

Handles CRUD and inline editing of an individual card.

```javascript
// assets/controllers/card_controller.js
import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['title', 'description', 'viewMode', 'editForm', 'titleInput', 'descriptionInput']
  static values  = {
    id:      String,
    status:  String,
    editing: { type: Boolean, default: false },
  }

  #originalTitle       = ''
  #originalDescription = ''

  editingValueChanged(editing) {
    this.viewModeTarget.hidden = editing
    this.editFormTarget.hidden = !editing
    if (editing) this.titleInputTarget.focus()
  }

  startEdit() {
    this.#originalTitle       = this.titleTarget.textContent
    this.#originalDescription = this.descriptionTarget.textContent
    this.editingValue = true
  }

  saveEdit(event) {
    event.preventDefault()
    const title = this.titleInputTarget.value.trim()
    if (!title) return

    // textContent is required — innerHTML is an XSS risk
    this.titleTarget.textContent       = title
    this.descriptionTarget.textContent = this.descriptionInputTarget.value.trim()
    this.editingValue = false
    this.dispatch('updated', { detail: { id: this.idValue, status: this.statusValue } })
  }

  cancelEdit() {
    this.titleInputTarget.value       = this.#originalTitle
    this.descriptionInputTarget.value = this.#originalDescription
    this.editingValue = false
  }

  deleteCard() {
    this.dispatch('deleted', { detail: { id: this.idValue } })
    this.element.remove()
  }

  serialize() {
    return { id: this.idValue, title: this.titleTarget.textContent, status: this.statusValue }
  }
}
```

### 4.4 drag_controller

Wraps the HTML5 Drag and Drop API. Since drag events are non-standard, use `addEventListener` in
`connect()` and always remove them in `disconnect()`.

```javascript
// assets/controllers/drag_controller.js
import { Controller } from '@hotwired/stimulus'

/* stimulusFetch: 'lazy' */
export default class extends Controller {
  static targets = ['item', 'zone']
  static values  = { dragging: { type: Boolean, default: false } }
  static classes = ['over', 'dragging']

  // Preserve the bound handler references — removeEventListener needs the same reference
  #handlers = null

  connect() {
    this.#handlers = {
      dragstart: this.#onDragStart.bind(this),
      dragend:   this.#onDragEnd.bind(this),
      dragover:  this.#onDragOver.bind(this),
      drop:      this.#onDrop.bind(this),
    }
    this.itemTargets.forEach(item => {
      item.addEventListener('dragstart', this.#handlers.dragstart)
      item.addEventListener('dragend',   this.#handlers.dragend)
    })
    this.zoneTargets.forEach(zone => {
      zone.addEventListener('dragover', this.#handlers.dragover)
      zone.addEventListener('drop',     this.#handlers.drop)
    })
  }

  disconnect() {
    this.itemTargets.forEach(item => {
      item.removeEventListener('dragstart', this.#handlers.dragstart)
      item.removeEventListener('dragend',   this.#handlers.dragend)
    })
    this.zoneTargets.forEach(zone => {
      zone.removeEventListener('dragover', this.#handlers.dragover)
      zone.removeEventListener('drop',     this.#handlers.drop)
    })
    this.#handlers = null
  }

  #onDragStart(event) {
    event.dataTransfer.setData('text/plain', event.currentTarget.dataset.cardId)
    this.draggingValue = true
    event.currentTarget.classList.add(...this.draggingClasses)
  }

  #onDragEnd(event) {
    this.draggingValue = false
    event.currentTarget.classList.remove(...this.draggingClasses)
  }

  #onDragOver(event) {
    event.preventDefault()
    event.currentTarget.classList.add(...this.overClasses)
  }

  #onDrop(event) {
    event.preventDefault()
    event.currentTarget.classList.remove(...this.overClasses)
    const cardId = event.dataTransfer.getData('text/plain')
    const targetStatus = event.currentTarget.dataset.columnStatusValue
    this.dispatch('moved', { detail: { cardId, targetStatus }, bubbles: true })
  }
}
```

---

## 5. Stimulus API Specification

### 5.1 Lifecycle Hooks

| Hook | When to use | Prohibitions |
| --- | --- | --- |
| `initialize()` | One-time setup (debounce binding, singleton init) | No DOM access (not connected yet) |
| `connect()` | Initialize after the DOM is ready (localStorage restore, event registration) | — |
| `disconnect()` | Always clean up: `clearInterval`, `removeEventListener`, `observer.disconnect()` | Memory leak if omitted |
| `constructor()` | **Do not use** | Absolutely forbidden when extending a Stimulus Controller |

Target lifecycle callbacks (fire even before `connect()`):

```javascript
titleTargetConnected(element)    { /* when the target is added to the DOM */ }
titleTargetDisconnected(element) { /* when the target is removed from the DOM */ }
```

### 5.2 Values API

```javascript
// The type + default expanded syntax is recommended
static values = {
  count:   { type: Number,  default: 0 },
  status:  { type: String,  default: 'todo' },
  editing: { type: Boolean, default: false },
  config:  { type: Object,  default: {} },
  tags:    { type: Array,   default: [] },
}

// Change callback — receives the current and previous value (auto-called right after init + on change)
countValueChanged(value, previousValue) { }

// Access after checking existence
if (this.hasCountValue) { ... }

// Assigning undefined removes the data attribute
this.countValue = undefined
```

HTML attribute conversion: camelCase → kebab-case automatically

```html
<!-- editingValue → data-card-editing-value -->
<div data-card-editing-value="false">
```

### 5.3 Targets API

```javascript
static targets = ['title', 'description', 'editForm']

// Singular — throws an error if absent
this.titleTarget

// Plural — returns an empty array (no error)
this.titleTargets

// Existence check (required before accessing an optional target)
if (this.hasTitleTarget) { this.titleTarget.focus() }
```

HTML attribute: `data-[controller]-target="[name]"`

Scope rule: targets are searched only within the controller element. Nested controller scopes are excluded.

### 5.4 Outlets API

Use when direct method calls between controllers are needed. Specify the target element with a CSS selector.
Unlike targets, it can be referenced anywhere on the page.

```javascript
static outlets = ['column', 'card']

// The first outlet controller instance (throws if absent)
this.columnOutlet.addCard(data)

// An array of all outlet controllers
this.cardOutlets.forEach(card => card.highlight())

// Existence check (required)
if (this.hasColumnOutlet) { ... }

// Connect/disconnect callbacks
columnOutletConnected(outlet, element) { }
columnOutletDisconnected(outlet, element) { }
```

HTML attribute: `data-[controller]-[outlet-name]-outlet="[CSS selector]"`

```html
<div data-controller="board" data-board-column-outlet=".column">
```

### 5.5 Actions API

```javascript
// Basic syntax: event->controller#method
// data-action="click->card#startEdit"

// Event defaults (can be omitted)
// button / a / input[type=submit] → click
// form                            → submit
// input / textarea                → input
// select                          → change
// details                         → toggle

// Action options (colon suffix)
// :once     — run once then remove the listener
// :stop     — event.stopPropagation()
// :prevent  — event.preventDefault()
// :self     — handle only events originating from itself
// :capture  — handle in the capture phase

// Keyboard filters (dot notation)
// keydown.enter->card#saveEdit
// keydown.esc->card#cancelEdit
// keydown.ctrl+enter->card#saveEdit

// Global events
// resize@window->board#layout
// turbo:load@document->board#reconnect

// Action parameters (automatic type casting)
// <button data-action="click->board#remove" data-board-id-param="123">
// remove({ params: { id } }) { /* id: number */ }
```

### 5.6 CSS Classes API

Externalize CSS class names in HTML rather than hardcoding them in JavaScript.

```javascript
static classes = ['loading', 'active', 'over', 'dragging']

// Access
this.loadingClass        // → 'opacity-50 cursor-wait'
this.loadingClasses      // → ['opacity-50', 'cursor-wait'] (split on whitespace)
this.hasLoadingClass     // → true/false
```

Inject from Twig:

```twig
<div {{ stimulus_controller('column', {}, { 'active': 'ring-2 ring-blue-500', 'loading': 'opacity-50' }) }}>
```

### 5.7 Controller-to-Controller Communication Strategy

```text
card:updated / card:deleted / card:moved → board#save    (custom event, bubbling)
column ←→ card                            (Outlet direct call)
drag → board (move-complete notification) (custom event dispatch)
```

```javascript
// Emit an event (card_controller.js)
this.dispatch('updated', {
  detail:     { id: this.idValue, status: this.statusValue },
  bubbles:    true,
  cancelable: false,
})
// Emitted event name: "card:updated"

// Receive the event (HTML)
// data-action="card:updated->board#save"

// Cancelable event
const event = this.dispatch('deleting', { cancelable: true })
if (event.defaultPrevented) return   // if another controller canceled it
```

**Prohibited:** direct calls to `document.querySelector()`, `this.element.querySelector()`, `application.getControllerForElementAndIdentifier()` → always use an Outlet or a custom event.

---

## 6. Code Conventions

### 6.1 Module System

```javascript
// Group 1: framework / third-party
import { Controller }   from '@hotwired/stimulus'
import { useTransition } from 'stimulus-use'        // import only when actually used

// Group 2: local modules (separated by a blank line)
import { debounce } from '../utils/debounce'

export default class extends Controller { }   // Stimulus controller → default export
// export const helper = ...                  // utility → named export
```

**Prohibited:** `require()`, `module.exports`, unused imports.

### 6.2 Variable Declarations

```javascript
const DEBOUNCE_MS = 500   // module-level constant → UPPER_SNAKE_CASE
const MAX_CARDS   = 100

export default class extends Controller {
  #originalTitle = ''     // private field → #camelCase (never _prefix)
  #observer      = null

  connect() {
    const { id, status } = this.element.dataset   // prefer const
    let retryCount = 0                             // let only when reassignment is needed
  }
}
```

### 6.3 Async Handling

```javascript
// async event listener — must use try/catch (rejections are silently swallowed)
async saveEdit(event) {
  event.preventDefault()
  try {
    const response = await fetch('/api/cards', { method: 'POST', body: JSON.stringify(payload) })
    if (!response.ok) throw new Error(`HTTP ${response.status}`)
    const data = await response.json()
    this.dispatch('saved', { detail: data })
  } catch (error) {
    console.error('Failed to save card', { id: this.idValue, error })
    throw error   // re-throw so the caller can also handle it
  }
}

// JSON.parse — must use try/catch (invalid JSON throws synchronously)
#loadFromStorage() {
  try {
    const raw  = localStorage.getItem('kanban-board')
    const data = raw ? JSON.parse(raw) : null
    if (!this.#isValidSchema(data)) return
    this.#restore(data)
  } catch (error) {
    console.error('Failed to load board state', { error })
  }
}
```

### 6.4 Security

| Dangerous pattern | Replacement pattern |
| --- | --- |
| `element.innerHTML = userInput` | `element.textContent = userInput` |
| `innerHTML = serverHtml` | Insert after DOMPurify sanitization |
| `eval()` / `new Function(str)` | **Never allowed** |
| Storing tokens/passwords in localStorage | Use HttpOnly cookies |

Always render card titles/descriptions with `textContent`.

### 6.5 Performance

```javascript
// Event listener register/remove pair — always preserve the bound reference
connect() {
  this.#boundOnResize = this.#onResize.bind(this)
  window.addEventListener('resize', this.#boundOnResize)
}

disconnect() {
  window.removeEventListener('resize', this.#boundOnResize)
}

// Prevent layout thrashing — separate reads from writes
const heights = this.itemTargets.map(el => el.offsetHeight)             // batch reads
this.itemTargets.forEach((el, i) => el.style.height = `${heights[i]}px`) // batch writes
```

**Prohibited:** starting `setInterval` / `setTimeout` without keeping a reference, omitting `clearInterval` in `disconnect()`.

### 6.6 Code Quality

- Split responsibilities (extract a private method) when a function exceeds 30 lines
- Name magic numbers as module-level `const`
- No `console.log` / `console.debug` in production code
- No commented-out code blocks (rely on git history)
- Code duplicated across 3 or more lines → extract into a utility module under `assets/utils/`

---

## 7. localStorage Data Schema

```json
{
  "version": 1,
  "savedAt": "2026-06-30T12:00:00.000Z",
  "columns": {
    "todo":        { "cards": ["id1", "id2"] },
    "in-progress": { "cards": ["id3"] },
    "done":        { "cards": ["id4", "id5"] }
  },
  "cards": {
    "id1": {
      "id": "id1",
      "title": "Card title",
      "description": "Description",
      "status": "todo",
      "createdAt": "2026-06-30T10:00:00.000Z"
    }
  }
}
```

Schema validation rules:

- `version` field required (for future migrations)
- Reject restoration and warn if card count > 100
- Ignore unknown fields (no strict parsing)

---

## 8. File Naming and Identifier Rules

| File name | Stimulus identifier | `data-controller` |
| --- | --- | --- |
| `board_controller.js` | `board` | `data-controller="board"` |
| `column_controller.js` | `column` | `data-controller="column"` |
| `card_controller.js` | `card` | `data-controller="card"` |
| `drag_controller.js` | `drag` | `data-controller="drag"` |
| `users/list_item_controller.js` | `users--list-item` | `data-controller="users--list-item"` |

- File name: `snake_case_controller.js`
- Identifier: `kebab-case` (multi-word) or `namespace--name` (subdirectory)
- The `data-controller` value and the file name must match for Symfony UX auto-registration to work

---

## 9. Verification Checklist

The review checklist is derived from the rules (SoT), so it is not duplicated in this document. After
finishing an implementation, review each controller with the `/app-javascript-stimulus-review {file}`
command; the judgment criteria have their single source of truth in
`.claude/rules/app-javascript-stimulus-00-overview-rule.md` ~ `app-javascript-stimulus-02-quality-rule.md` and
`.claude/output-styles/app-javascript-stimulus-style.md`.
