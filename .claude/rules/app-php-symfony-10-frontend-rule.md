---
paths:
  - "app/assets/**/*.js"
---

# Frontend Rule

@see https://symfony.com/doc/current/frontend.html

## AssetMapper (Default Choice)

- Use AssetMapper for every new project — no bundler (Webpack Encore) required.
- Write modern JS/CSS directly; AssetMapper handles the importmap and versioning automatically.
- Configure it via `config/packages/asset_mapper.yaml`.

```bash
php bin/console asset-map:compile   # production build
php bin/console importmap:require @hotwired/stimulus
```

@see https://symfony.com/doc/current/frontend/asset_mapper.html

## Stimulus Controllers

Implement all JavaScript behavior as Stimulus controllers:

```javascript
// assets/controllers/toggle_controller.js
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["content"];
  static values = { open: Boolean };

  connect() {
    this.openValue = false;
  }

  toggle() {
    this.openValue = !this.openValue;
    this.contentTarget.hidden = !this.openValue;
  }
}
```

```twig
{# Usage in Twig #}
<div data-controller="toggle">
    <button data-action="toggle#toggle">Show / Hide</button>
    <div data-toggle-target="content" hidden>Hidden content</div>
</div>
```

- Register controllers via `assets/controllers.json` (Symfony UX bundle controllers) or `assets/app.js` (custom controllers).
- Use the `data-controller`, `data-action`, `data-{identifier}-target`, and `data-{identifier}-{name}-value` HTML attributes as documented.
- Do not manipulate the DOM outside a Stimulus controller.

## Symfony UX Bundles

Prefer a Symfony UX package over custom JavaScript when it covers the use case:

| Package                     | Use case                              |
| --------------------------- | ------------------------------------- |
| `symfony/ux-turbo`          | SPA-like navigation without full reloads |
| `symfony/ux-live-component` | Reactive components with no JS         |
| `symfony/ux-twig-component` | Reusable Twig+PHP components           |
| `symfony/ux-chart-js`       | Chart.js charts                        |
| `symfony/ux-dropzone`       | File-upload dropzone                   |

## Realtime Updates (Mercure / SSE)

For server → browser realtime state push (e.g. order status), use **Mercure (SSE) + Turbo Streams** — do not introduce polling or a raw WebSocket server.

- Server: publish a `<turbo-stream>` to a topic with `Symfony\Component\Mercure\HubInterface` (an `Update` value object). Fail the publish gracefully in a `try/catch` so a Hub failure does not break domain logic.
- Browser: subscribe by rendering a `<turbo-stream-source>` in the template with `{{ turbo_stream_listen(topic) }}`. For multiple resources, subscribe in bulk with a single URI-template topic (`.../{id}`) instead of per-row subscriptions.
- Configuration: `symfony/mercure-bundle` + `config/packages/mercure.yaml` + `MERCURE_URL`/`MERCURE_PUBLIC_URL`/`MERCURE_JWT_SECRET`. Do not commit secrets; inject them via `.env.local`/Secrets.

@see .claude/docs/app-php-symfony-docs.md §13 — publish/subscribe/authorization/testing details

## Webpack Encore (Legacy / Complex Bundling Only)

Use Webpack Encore only when complex bundling (code splitting, SASS compilation, etc.) is required:

- JS/CSS sources live in `assets/`.
- `public/build/` is in `.gitignore` — never commit compiled assets.
- Run `yarn encore dev --watch` during development.

## Asset Naming

- CSS entry point: `assets/styles/app.css`.
- JS entry point: `assets/app.js`.
- Stimulus controllers: `assets/controllers/{name}_controller.js`.
- Shared utilities: `assets/utils/{name}.js` (modules reused across controllers; consistent with JS rule 00-overview).

## Tailwind CSS

- Use utility-first classes — do not write custom CSS unless it genuinely cannot be expressed with utility classes.
- Configure the `content` paths in `tailwind.config.js` to include every Twig template.
- Do not use `@apply` for a style used only once — write the utilities inline.

@see https://symfony.com/bundles/StimulusBundle/current/index.html
