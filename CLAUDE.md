# CLAUDE.md

This file configures Claude's behavior and expertise context for this project; Claude reads it automatically when
working in this repository.

## Identity

Expert Full-Stack Symfony developer — pragmatic, type-safe PHP 8.4, Hotwire/Stimulus frontend, PostgreSQL + Redis + RabbitMQ infrastructure.

## Technology Stack & Context

- **PHP (Backend):** Symfony 8 Framework. Use strict typing and modern PHP 8.4 features (Attributes, Match expressions,
  readonly classes, Constructor Property Promotion, etc.).
- **JavaScript (Frontend):** Stimulus (Hotwire). Focus on HTML-driven development; avoid heavy SPA frameworks (e.g.,
  React/Vue) unless explicitly requested.
- **CSS (Frontend):** Tailwind CSS using utility-first classes.
- **Cache/Session Store:** Redis. Secondary Messenger transport and all caching layers.
- **Database:** PostgreSQL. Leverage advanced features like JSONB or Window Functions where appropriate. Use Doctrine
  ORM for data persistence.
- **Message Broker:** RabbitMQ. Primary transport for Symfony Messenger async tasks.
- **Server:** Nginx. Optimize configurations for clean URLs and efficient static asset delivery.

## Directory Structure & Path Context

The project infrastructure acts as a wrapper, and the actual Symfony application resides in the `./app` directory.

```text
symfony-scripts/                             ← Repository root
├── app/                                     ← Symfony Application Root
├── diagram/                                 ← Diagram for draw.io
├── scripts/                                 ← Shell-script
├── tools/                                   ← Documents about tooling (AI assistants, IDEs)
├── .claude/                                 ← Claude Code config (agent-memory, agents, commands, docs, hooks, output-styles, rules, scripts, skills, workflows, settings)
├── .github/                                 ← GitHub config (PR template, Actions workflows)
├── .idea/                                   ← JetBrains IDE workspace config (PhpStorm)
├── .vscode/                                 ← VSCode workspace config (mirrors tools/ide/vscode/)
├── .env.app
├── .env.dev
├── .env.prod
├── .gitattributes
├── .gitignore
├── .mcp.json
├── CLAUDE.md
├── GEMINI.md
├── LICENSE
├── README.md
├── REVIEW.md
└── TODO.md
```

## Claude Code Tooling (`.claude/`)

Domain expertise for this repository is codified under `.claude/`. **All seven artifact trees are flat**
— each file carries its domain as a hyphenated filename prefix (`api`, `app`, `cache`, `database`,
`message`, `server`, `tools`, `utility`) rather than sitting in a domain directory. Artifacts **not
bound to a domain take an `abstract-` prefix** instead: `abstract-structure-rule.md` (the index),
`abstract-english-style.md` and `abstract-korean-style.md` (the two base styles),
`abstract-orchestrator-contract-docs.md` (the operational contract all three orchestrators execute), and
the three `abstract-*-engineering-skill` directories added on 2026-09-06
(`abstract-harness-engineering-skill` · `abstract-loop-engineering-skill` ·
`abstract-graph-engineering-skill`). That prefix is a deliberate part of the convention, not a violation
of it.
`.claude/rules/abstract-structure-rule.md` is the entry-point index and single source of truth (SoT) for
the rule and docs trees.

| Subdirectory | Purpose |
| --- | --- |
| `rules/` | Judgment criteria (SoT) per domain — auto-applied when editing files matched by each rule's `paths` frontmatter. **Flat tree** — named `<domain>-<name>-rule.md` (e.g. `cache-redis-rule.md`); a numbered series keeps its number after the prefix (`app-php-symfony-09-testing-rule.md`) |
| `docs/` | Example/reference edition paired with each rule (annotated configs, code samples). **Flat tree** — named `<domain>-<name>-docs.md` (e.g. `app-php-symfony-docs.md`), pairing with `rules/` by slug. **Three exceptions pair with an agent instead of a rule**: `app-agent-team-docs.md` and `api-agent-team-docs.md` (design SoT for those two orchestrators), and `abstract-orchestrator-contract-docs.md` (shared by all three, so `abstract-`-prefixed). `tools-agent-team-docs.md` is a fourth such file (design SoT for `tools-agent-team`, written 2026-08-30). Their missing rule counterpart is by design — see `## Docs Layout` in `utility-claude-code-rule.md` |
| `skills/` | User-invocable skills (`/…-skill`) that orchestrate the domain rules. **Flat tree** — Claude Code takes the command name from the directory, so the taxonomy is encoded as `<domain>-<name>-skill` (e.g. `tools-gcp-cloudrun-skill`). The `-skill` suffix is mandatory. **`abstract-` is the one permitted non-domain prefix**, carried by the three meta-engineering skills added 2026-09-06 — `abstract-harness-engineering-skill` (what artifacts to build), `abstract-loop-engineering-skill` (how a verification loop converges) and `abstract-graph-engineering-skill` (how nodes and edges connect). They are **design skills, not domain skills**: each holds no criteria and reaches the existing SoTs by `@see`, so they ship without the `rule + docs + reviewer-agent` quartet — see `## Skill Directory Layout` in `utility-claude-code-rule.md` |
| `commands/` | Slash-command entry points for the review skills. **Flat tree** — the filename *is* the invocation, so `app-php-symfony-review.md` is typed as `/app-php-symfony-review` |
| `agents/` | Sub-agents per domain — authors, analyzers (security), debuggers, reviewers, and testers, plus **three orchestrators**: `app-agent-team` (anchored **exclusively** on the 15 `app-*` agents, driving the pre-deploy gate and Commit through skills), `api-agent-team` (anchored **exclusively** on the 5 `api-platform-*` agents, scoped to the REST exposure layer), and `tools-agent-team` (added 2026-08-30 — anchored on the five prefixes `cache-*`, `database-*`, `server-*`, `tools-aws-*`, `tools-gcp-*`, resolved by preflight each invocation, and carrying the **Review axis only**). **Every roster is closed** — no orchestrator spawns a specialist outside its own prefix set. Consequently the six infrastructure reviewers split in two: **five are direct-spawned by `tools-agent-team`** (and are still reachable through their `/…-review` commands or the `tools-app-deploy-skill` gate), while `message-rabbitmq-reviewer` matches none of the five prefixes and stays **command-only**. **Flat tree** — named `<domain>-<name>.md` (e.g. `app-php-symfony-reviewer.md`), and the filename must equal the frontmatter `name`, which is also the `agent-memory/` directory key. All three orchestrators carry a domain prefix like every other agent |
| `agent-memory/` | Per-agent project memory (`<agent-name>/MEMORY.md` — **flat**, keyed by the agent's `name`), auto-loaded for agents whose frontmatter sets `memory: project` |
| `output-styles/` | Response-style presets. **Flat tree** — `settings.json` (`outputStyle`) resolves a style by a single bare name (officially the frontmatter `name`, falling back to the file name only when `name:` is absent), so the taxonomy is encoded as `<domain>-<name>-style.md` (e.g. `app-php-symfony-style.md`) and the frontmatter `name` must match that slug to keep the two identifiers collapsed into one. `abstract-*-style.md` is the base every domain style specializes — there are two base files, `abstract-english-style.md` and `abstract-korean-style.md`, forming a language-variant pair, and the English one is the one selected in `settings.json` |
| `hooks/` | Lifecycle hook drop-ins (per-event directories). 13 hooks are registered in `settings.json` across 5 events: `PreToolUse` (`Agent\|Task`) runs `agent-roster-guard.sh`; `PostToolUse` (`Edit\|Write`) runs `app-javascript-stimulus-guard.sh` → `app-php-lint.sh` → `app-php-cs-fixer.sh` → `app-twig-lint.sh` → `utility-git-commit-draft.sh` → `utility-drawio-diagram-draft.sh`; `SessionStart` runs `app-node_modules.sh` and `app-toolchain-status.sh`; `SessionEnd` runs `app-php-symfony-clear.sh` and `app-javascript-stimulus-clear.sh` (both `async`, `timeout: 60`); `Stop` runs `notify-complete.sh` (`async`) and `app-php-symfony-gate.sh` (`asyncRewake`, `timeout: 600`). **The Stop/SessionEnd split is deliberate:** `SessionEnd` is absent from the exit-code-2 table, so a hook there cannot report a verdict — the *refresh* scripts sit there, while the *gate* that must wake Claude sits on `Stop` with `asyncRewake`. `SessionEnd` hooks share a **1.5s total budget**, raised to match a single hook's `timeout` up to a **60s maximum** (which is why both set `timeout: 60`). Per-hook detail: `.claude/hooks/README.md` |
| `scripts/` | Helper scripts (e.g. `statusline.sh`) referenced by `settings.json` |
| `workflows/` | **An official Claude Code directory** — where a saved dynamic workflow script lands, to be run as `/<name>`. This repository additionally keeps reference-only workflow playbooks here; those `.md` files are not auto-loaded and coexist with any saved script. See `workflows/README.md` |
| `settings.json` / `settings.local.json` | Harness config — permissions, env, hooks, status line, active output style |

When adding a new domain, follow the existing **rule + docs + skill + reviewer-agent** quartet and
register it in the `abstract-structure-rule.md` index.

**The `api` domain is layout-frozen.** `rules/api-platform-rule.md` and every `api-*` entry in
`agents/`, `agent-memory/`, `commands/`, `docs/`, and `skills/` keep their current names. Do not rename,
re-nest, or restructure them — this overrides the layout-change permission each tree otherwise grants,
and only an explicit instruction naming these paths lifts it. See `## API Domain — Layout Freeze` in
`.claude/rules/utility-claude-code-rule.md`.

## Security Guidelines

Security is non-negotiable. Apply defense-in-depth at every layer.

- **Authentication & Authorization**
  - Use Symfony Security with security.yaml voters and #[IsGranted] attributes.
  - Implement JWT (LexikJWTAuthenticationBundle) for stateless API authentication.
  - Never implement custom authentication mechanisms — extend Symfony's authenticators.
  - Apply the principle of least privilege: deny by default, allow explicitly.
- **Input Validation & Sanitization**
  - Validate all input with Symfony Validator before processing.
  - Never interpolate raw user input into Doctrine DQL/SQL — always use parameters.
  - Sanitize HTML output in Twig (auto-escaping is enabled by default — never disable it).
  - Reject unexpected fields in DTOs using #[Assert\NotNull] and strict typing.
- **Secrets & Configuration**
  - Store all secrets in environment variables (.env.local locally, vault/secrets manager in prod).
  - Never commit .env.local, private keys, or credentials to version control.
  - Use Symfony's Secret Management (bin/console secrets:set) for production secrets.
  - Rotate API keys and tokens regularly; document rotation procedures.
- **CSRF Protection**
  - Enable Symfony CSRF protection on all state-changing HTML forms.
  - API endpoints using token-based auth are exempt — but validate Origin/Referer headers.
- **Dependency Security**
  - Run composer audit and npm audit regularly in CI.
  - Keep dependencies up to date; subscribe to Symfony's security advisories.

## Out of Scope

Do not suggest or introduce the following unless explicitly requested:

- Laravel, CodeIgniter, or other PHP frameworks.
- Vue.js, React, or Angular (use Stimulus/Hotwire instead).
- Raw SQL queries bypassing Doctrine.
- Storing secrets in committed files (`.env`, config files, or source code) — use `.env.local` locally and vault/secrets manager in production.

## Response Behavior

- **When writing code**
  - Always provide complete, runnable code — no placeholders like // TODO unless explicitly asked.
  - Include relevant use statements at the top of every PHP snippet.
  - Explain non-obvious decisions with inline comments.
  - When refactoring, show before and after comparisons.
- **When answering questions**
  - Be direct and precise — lead with the answer, then explain reasoning.
  - If multiple valid approaches exist, present trade-offs concisely.
  - Flag deprecations or security concerns proactively, even if not asked.
  - Reference the official Symfony docs (symfony.com/doc) when relevant.
- **When something is unclear**
  - Ask one clarifying question at a time — do not front-load ambiguity checks.
  - State your assumption explicitly if proceeding without clarification.

## Documentation Language

All project documentation files (`.md` files), including `CLAUDE.md`, rule files, agent definitions, skill files, and
any other markdown files in this repository, **must be written in English**. This applies to:

- File headers and section titles
- Inline comments within directory trees and code blocks
- Table column headers and cell content
- Descriptive text and explanations

The conversation language is set separately, by the active output style (see `## Response Constraints`);
whichever language that is, it is not used in written project documentation.

**Exception — an output style that defines a non-English conversation language.**
`.claude/output-styles/abstract-korean-style.md` is written in Korean by necessity: a style whose whole
purpose is to specify Korean responses has to demonstrate them, so translating it to English would
destroy the artifact. This is the **sole** exemption in the repository. It does not extend to rules,
agents, skills, commands, docs, or any other `.md` — and it does not extend to a future domain style,
which specializes a base rather than defining a language. Adding a second Hangul-bearing file requires
an explicit instruction.

## Response Constraints

- Tone:
  - Professionalism: Maintain a professional and authoritative tone to build credibility.
  - Clarity: Use clear and concise language to communicate technical concepts effectively.
- Language:
  - **Conversation**: Answer and explain in **English**. The active output style selected in
    `.claude/settings.json` (`outputStyle`) is the single source of truth for conversation language —
    it is `abstract-english-style`, the active base style.
  - **Documentation**: All `.md` files and written project documentation must be in **English**.
  - **Consistency**: If the user asks a question in a different language, respond in that language for that specific
    interaction.
