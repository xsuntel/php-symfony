---
name: app-javascript-stimulus-skill
description: Use when analyzing the frontend code structure, guiding JavaScript library usage, or reviewing frontend code changes in this Stimulus 3 / Turbo 8 / AssetMapper project. Covers Stimulus controllers (actions, targets, values, outlets), Turbo Frame/Stream, importmap package management, Symfony UX bundles, and Tailwind CSS. Triggered by data-controller, data-action, static targets/values, connect()/disconnect(), this.dispatch, importmap:require, controllers.json, turbo-frame, or frontend review / bug identification requests.
---

# JavaScript / Stimulus Skill

The unified entry point for frontend analysis, library usage guidance, and code review.
Apply the relevant part depending on the nature of the request.

| Request type                                                            | Applicable section           |
| ----------------------------------------------------------------------- | ---------------------------- |
| Structure analysis, controller topology mapping, bootstrap flow tracing | Part 1 — Codebase Analysis   |
| JS library install/config/usage, package recommendations                | Part 2 — Library Usage Guide |
| Reviewing changes, identifying bugs, PR improvement suggestions         | Part 3 — Code Review         |

## Information Source (single source of truth: the rule file)

The detailed Stimulus/ES module/quality criteria are owned by **the rule files and the output-style as
the single source of truth (SoT)**. This skill does not restate them; it only provides the analysis
methodology, operational commands, and output format.

@see .claude/rules/app-javascript-stimulus-00-overview-rule.md ~ app-javascript-stimulus-02-quality-rule.md — module/controller/quality criteria (SoT)
@see .claude/rules/app-php-symfony-10-frontend-rule.md — AssetMapper/UX bundles
@see .claude/output-styles/app-javascript-stimulus-style.md — code style (semicolons, quotes, indentation)
@see app/assets/CLAUDE.md — asset directory conventions

**Note:** the SoT for frontend library versions is `app/importmap.php` — not `package.json`
(`app/package.json` only holds browser-compatibility data). If unconfirmed, do not guess — state it.

---

# Part 1 — Codebase Analysis

Map top-down. Confirm directory existence with Glob. Read `app/assets/CLAUDE.md` first.

1. **Root layout** → `app/assets/` (controllers/ styles/ themes/ turbo/ vendor/ app.js controllers.json stimulus_bootstrap.js).
2. **Controller topology** → root shared controllers (dropdown/modal/popover, etc.) + domain subdirectories (mirroring the `app/src/` domains). See `app-php-symfony-skill` for backend boundaries.
3. **Bootstrap flow** → when diagnosing a registration issue, determine which of the 3 paths:

```text
importmap.php (entrypoint) → app.js → stimulus_bootstrap.js
  ├ startStimulusApp()  : auto-registers everything under controllers/
  └ app.register(...)   : manual third-party registration
controllers.json         : Symfony UX bundles (fetch: lazy/eager)
```

4. **Controller contract** → read the class-top `static targets/values/classes/outlets` + `this.dispatch()`, and cross-check the `data-controller="{id}"` connections in Twig (`app/templates/`) with Grep.
5. **Config order** → `importmap.php` → `controllers.json` → `asset_mapper.yaml` → `styles/app.css`, `themes/`.

## Output Format

- **Controller summary**: per-domain Controller Contract (targets/values/outlets/dispatches) → Twig Bindings → Turbo Usage.
- **Dependency map**: a directional list of `{controller} outlet→/dispatches→/imports→`. Do not generate UML without a request.
- **Gap report**: report unmatched `data-controller`, unreferenced controllers, undeclared bare imports, and unused targets under `## Gaps Found`.

---

# Part 2 — Library Usage Guide

## Checks Before Recommending

1. Already installed? → `app/importmap.php` (not package.json).
2. Covered by a UX bundle? → check autocomplete/chartjs/leaflet-map/live-component/turbo in `controllers.json`.
3. Compatible with Stimulus 3 / Turbo 8?
4. Rule conflict? → React/Vue/Angular prohibited (`CLAUDE.md`), bundlers (Webpack/Vite) prohibited, no `<script src>` (`rules/app-php-symfony-10-frontend-rule.md`, output-style).
5. Already abstracted? → e.g. dropdown is registered as `@stimulus-components/dropdown`.

If any check fails, report it before providing examples.

## Version Check & Install (Bash)

```bash
# Version (SoT: importmap.php). Do not assert without confirming
grep -A 2 "'package-name'" app/importmap.php

# JS package (not npm, AssetMapper)
cd app && php bin/console importmap:require package-name
grep 'package-name' app/importmap.php

# Symfony UX bundle (Composer + controllers.json activation)
cd app && composer require symfony/ux-{name}
grep '"@symfony/ux-{name}"' app/assets/controllers.json
```

Third-party `@stimulus-components/*` are manually registered with `app.register()` in `stimulus_bootstrap.js` after `importmap:require`.
UX bundle `fetch`: global=eager, specific page=lazy.

## Prohibited/Replacement Libraries

| Prohibited                                          | Replacement / rationale                                  |
| --------------------------------------------------- | -------------------------------------------------------- |
| `react`/`vue`/`angular`                             | Stimulus/Hotwire (`CLAUDE.md`)                           |
| `jquery`                                            | Stimulus targets/actions + native DOM                    |
| `axios`                                             | Native `fetch` + `async/await`, updates via Turbo Stream |
| webpack/Vite/esbuild                                | AssetMapper                                              |
| `npm install` frontend packages, `<script src>` CDN | `importmap:require`                                      |

For UI widgets, charts/maps/autocomplete, prefer existing registrations (shared controllers, UX bundles) before introducing new ones.
Use the installed `debounce` for throttling and Tailwind (+ Flowbite) for styling. When blocking, cite the underlying rule.

---

# Part 3 — Code Review

## Procedure

```bash
git diff main...HEAD --name-only -- app/assets/ app/templates/
git diff main...HEAD -- app/assets/ app/templates/
```

When a controller changes, also review the `data-*` attributes in the corresponding Twig — both sides of the contract must match.
**Apply the detailed judgment criteria based on the rules below** — the skill does not restate the criteria.

| Target                                         | Judgment criteria (SoT)                                            |
| ---------------------------------------------- | ------------------------------------------------------------------ |
| Modules/naming                                 | `rules/app-javascript-stimulus-00-overview-rule.md`                |
| Controllers (targets/values/outlets/lifecycle) | `app-javascript-stimulus-01-controller-rule.md`                                            |
| Security/performance/quality                   | `app-javascript-stimulus-02-quality-rule.md`                                               |
| Code style                                     | `output-styles/app-javascript-stimulus-style.md`                   |
| Twig/frontend                                  | `rules/app-php-symfony-07-template-rule.md`, `app-php-symfony-10-frontend-rule.md` |

## Cross-Cutting Key Checks (quickly, only for rule violations)

- Does `disconnect()` clean up the listeners/timers/observers from `connect()` (Turbo leak)?
- Is user data kept out of `innerHTML` (XSS)? / Do state-changing fetches include CSRF?
- Do the Twig `data-*` attributes match the controller's `static targets`/action names?
- Are new bare imports declared in `importmap.php`, and is the controller registration path correct?
- `this.*Target` instead of `document.querySelector`, `response.ok` check after `fetch`.

## Severity · Output

| Severity     | When to use                                                                            |
| ------------ | -------------------------------------------------------------------------------------- |
| `[MUST]`     | Bug, security (XSS, CSRF, secret exposure), rule violation, memory leak (blocks merge) |
| `[SHOULD]`   | Performance, maintainability, convention deviation                                     |
| `[CONSIDER]` | Optional improvement, style                                                            |

Output order: **Summary → [MUST] → [SHOULD] → [CONSIDER] → positive feedback (at least 1, with file:line citation)**.
