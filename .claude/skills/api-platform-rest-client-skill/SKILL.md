---
name: api-platform-rest-client-skill
description: Use when generating, with the API Platform Client Generator (create-client), a frontend client that consumes the REST API this project's API Platform exposes. Triggered by questions about scaffolding React/Next.js/Nuxt/Vue/Quasar/Vuetify/React Native apps (list·detail·create/edit forms·delete·client-side validation) from a Hydra or OpenAPI 3 spec, the --generator/--resource/--format options, and the npx @api-platform/client-generator and new create-client (pnpm create @api-platform/client) commands. For building (exposing) the API use api-platform-rest-build-skill.
---

# API Platform REST Client Skill (Client Generator)

This skill is the entry point for scaffolding a frontend application that **consumes** the API this
project exposes, using API Platform's **Client Generator (create-client)**. Building the API itself
(declaring resources & State) is out of scope for this skill (→ `api-platform-rest-build-skill`).

The Client Generator reads a **Hydra or OpenAPI 3 spec** and generates a TypeScript app with list,
detail, create/edit forms, delete, client-side validation, and server error display.

@see https://api-platform.com/docs/create-client/ — Client Generator (official)
@see .claude/rules/api-platform-rule.md — resource·serialization·error criteria for the consumed API (SoT)
@see .claude/skills/api-platform-rest-build-skill/SKILL.md — use this instead when building (exposing) the API
@see .claude/skills/api-platform-oauth2-client-skill/SKILL.md — the authentication flow when the generated client accesses a protected API

## ⚠️ Project Stack Alignment (check first)

- This project's main frontend is **Stimulus/Hotwire**, and CLAUDE.md keeps React/Vue/Angular SPAs
  out of scope unless explicitly requested. The Client Generator's React/Next/Nuxt/Vue output is
  **not adopted as the frontend of the main Symfony app.**
- Use this skill only for a **standalone consumer app (a separate repo/external consumer·mobile app)**
  or for **contract (schema) verification scaffolding**. If the goal is the main app UI, implement it
  with Twig + Stimulus.

## Preconditions

- The consumed API must expose a **Hydra document (`/api/docs.jsonld` or the entrypoint)** or an
  **OpenAPI 3 spec (`/api/docs.json`)** — the Client Generator derives the client from this spec.
- The output is a frontend project, so place it in a separate directory **outside `app/` (Symfony)** —
  do not mix it into the Symfony source tree.

## Generation Commands

```bash
# New recommended way (create-client) — <ENTRYPOINT> <OUTPUT_DIR>
pnpm create @api-platform/client https://demo.api-platform.com . --generator next --resource book
# npm init @api-platform/client ... / yarn create @api-platform/client ... are equivalent

# Existing way (client-generator)
npx @api-platform/client-generator <ENTRYPOINT_URL> <OUTPUT_DIR> --generator <GENERATOR> --resource <RESOURCE>

# Example: React, single resource
npx @api-platform/client-generator https://demo.api-platform.com src/ --resource book -g react

# Generate from an OpenAPI 3 spec (instead of Hydra)
npx @api-platform/client-generator https://demo.api-platform.com/docs.json?spec_version=3 output/ --resource Book --format openapi3
```

- `--generator` (`-g`): `next` / `react` / `react-native` / `nuxt` / `vue` / `quasar` / `vuetify` / `typescript`, etc.
- `--resource`: generate only a single resource. **If omitted, generates for all exposed resources.**
- `--format` (`-f`): Hydra by default; use `openapi3` for the OpenAPI spec.
- **[Needs verification]** The available generator list/flags vary by the installed package version, so confirm with `--help`.

## Core Checks

- [ ] Is the output directory a separate frontend project outside `app/` (Symfony)
- [ ] Does the entrypoint actually return a Hydra/OpenAPI spec (confirm with the verification below)
- [ ] For a protected API, is the authentication (Bearer/OAuth2) flow wired into the client (→ `api-platform-oauth2-client-skill`)
- [ ] Does the generated code not replace the main Symfony app's Stimulus frontend (standalone/scaffolding use)

## Verification (Bash)

```bash
# First confirm the consumed spec is actually exposed (no guessing)
curl -fsS https://<host>/api/docs.jsonld | head -c 400   # Hydra
curl -fsS "https://<host>/api/docs.json?spec_version=3" | head -c 400   # OpenAPI 3

# In the frontend project directory after generation
# (optional) typecheck/build follows the generated generator's scripts
```

## Prohibitions

- Do not **adopt the generated React/Vue/Next client as the frontend of the main Symfony app** — the
  main UI is Twig + Stimulus/Hotwire (out of scope per CLAUDE.md).
- Do not present commands assuming a spec that is not exposed — confirm the entrypoint with `curl` first.
- Do not commit the generated artifacts into the `app/` source tree — keep them as a separate project.
