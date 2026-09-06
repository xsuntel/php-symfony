# Directory Structure & Path Context

This rule defines the repository's physical structure and path conventions, and serves as the entry
point to the domain rule files. The **detailed criteria for architecture and code style are owned by
each domain rule file (SoT)**; this document does not restate them, keeping only the path context and
the rule index.

**Why there is no `paths` frontmatter:** this document is not a set of criteria auto-applied to
particular code paths — it is the **index** that every session needs in full.

**How a `paths`-less rule actually reaches context.** `[Verified]` 2026-08-29
[WebFetch: <https://code.claude.com/docs/en/memory>]: "Rules without `paths` frontmatter are loaded at
launch with the same priority as `.claude/CLAUDE.md`." Omitting `paths` is therefore not a gap to be
routed around — **it is the mechanism that makes a rule unconditional**, and the harness does the
loading with no `@see` or `CLAUDE.md` mention required. This session is the proof: both files below
arrived as project instructions at startup.

**† Exactly two rule files are exempt from `paths`, and for the same underlying reason** — neither
governs a set of files a glob could match, so no `paths` value could ever be correct, and both need to
be in context unconditionally:

- **`abstract-structure-rule.md`** (this document) — an index, not criteria. Loaded at launch because
  it declares no `paths`.
- **`utility-git-commit-rule.md`** — a commit message is not a file, so no path glob can trigger it.
  Loaded at launch for the same reason, and additionally reached via `@see` from
  `utility-git-commit-skill` and the author/reviewer agent pair when they need to cite it.

The exemption stops there: **every other file under `.claude/rules/**` must declare `paths`**, and a
missing `paths` on any of them is a `[MUST]` finding — precisely because the omission would load that
rule into every session unconditionally, spending context on criteria that apply to a narrow slice of
the tree. The basis for that verdict is the `rule paths` item in
`.claude/commands/utility-claude-code-review.md`.

@see CLAUDE.md — role · tech stack · security · testing · response guidance (global criteria)

## Directory Structure

The project infrastructure acts as a wrapper, and the actual Symfony application lives in the `./app`
directory.

```text
./                                           ← repository root
└── app/                                     ← Symfony application root
    ├── assets/                              ← Symfony AssetMapper (Stimulus/Tailwind)
    ├── bin/                                 ← Symfony console
    ├── config/                              ← Symfony configuration (packages/ services/ parameters/)
    ├── migrations/                          ← Doctrine migrations (per EntityManager)
    ├── public/                              ← web root (index.php, healthcheck.php, assets/)
    ├── src/                                 ← PHP source code (namespace: App\)
    ├── templates/                           ← Twig templates
    ├── tests/                               ← PHPUnit tests (Unit / Integration / Functional)
    ├── translations/                        ← Symfony translations
    ├── var/                                 ← runtime artifacts (cache/ log/ sessions/ tailwind/)
    └── vendor/                              ← Composer dependencies
```

Principal namespaces under `src/`: `ApiResource`, `Command`, `Controller`, `DataFixtures`, `Entity`,
`Repository`, `EventListener`/`EventSubscriber`, `Form`, `Messenger`, `MessageCommand`/
`MessageCommandHandler`/`MessageQuery`/`MessageQueryHandler`/`MessageEvent`/`MessageEventHandler`,
`Scheduler`, `Serializer`, `Service`, `Twig`.

## Provider Path Convention

Code integrating with an external provider mirrors the same deep namespace hierarchy at every layer:

```text
{Layer}/Providers/Finance/App/{Securities|DigitalAsset}/{Provider}/Domestic/{Stock|Coin}/API/{REST|Websocket}/...
```

For example: `Service/Providers/Finance/App/DigitalAsset/UPbit/Domestic/Coin/API/REST/ExtendedHttpClient.php`.
Configuration (`config/services/`, `config/parameters/`) and the cache pool and EntityManager names
follow a compressed form of the same path. For the per-provider detail rules, see the `providers/`
entries in the `## Project Rules` index below.

## Project Rules (index)

Domain rules live in `.claude/rules/` and are auto-applied when an edited file matches their `paths`
frontmatter. Each rule is the single source of truth (SoT) for its subject, and the domain skills
under `.claude/skills/` reference it.

**Layout of `.claude/**` — a flat single tier plus a hyphenated taxonomy:** every configuration
artifact, rules included, sits directly under `.claude/<type>/` in a flat tree. The domain axis is
encoded as a **hyphenated prefix** rather than a directory (`app-php-symfony-09-testing-rule.md`,
`cache-redis-rule.md`), and artifacts not bound to a domain take an `abstract-` prefix (this document,
`abstract-english-style`, `abstract-korean-style`, `abstract-orchestrator-contract-docs`, and the three
`abstract-*-engineering-skill` directories added 2026-09-06). The same domain and subject share the same slug across types, so that `@see`
references resolve to one another
(`rules/utility-shell-script-rule.md` ↔ `docs/utility-shell-script-docs.md` ↔ `skills/utility-shell-script-skill/`).
The `Placement Principles` section of `.claude/rules/utility-claude-code-rule.md` is the SoT for that
judgment.

**The one structural exception — the api domain is layout-frozen:** `rules/api-platform-rule.md` and
every `api-*` entry in `agents/`, `agent-memory/`, `commands/`, `docs/`, and `skills/` **keep their
current names**. Do not rename, re-nest, or restructure them — this overrides the layout-change
permission each tree otherwise grants, and only an explicit instruction naming these paths lifts it.

Be precise about what the freeze covers: **the api domain is flat like every other tree** (it was
flattened on 2026-08-15), so the freeze is entirely about **names, not nesting**. In a flat tree the
filename *is* the identifier Claude Code resolves — agent `name`, memory key, slash command, skill
invocation — which makes a rename a user-facing interface change rather than a cosmetic path edit.
The `## API Domain — Layout Freeze` section of `.claude/rules/utility-claude-code-rule.md` is the SoT
for that judgment, and it carries the authoritative table of frozen entries.

**Additional per-type constraints — read them separately, because what enforces them differs.** For a
skill, `SKILL.md`'s `name` equalling the parent directory name (`.claude/skills/<name>/SKILL.md`) is
**an explicit constraint of the Agent Skills standard, but the Claude Code harness does not enforce
it** — a project skill's invocation name always comes from the directory name, and `name` is only a
display label, so a mismatch produces divergent labelling without any error. Agent memory, by
contrast, has its path computed by the harness as
`.claude/agent-memory/<sanitize(name)>/MEMORY.md`, and because `sanitize` replaces `/` with `-`,
nesting means the memory **silently fails to load**. For output styles, `outputStyle` in
`settings.json` names a style by its file slug. The dedicated rule section for each of these in
`utility-claude-code-rule.md` is the SoT for the detail.

| Rule file                                                                | Scope                                                                                                                                                                    |
| ------------------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `app-agent-team-rule.md`                                                 | `app-agent-team` orchestration invariants — the 15-agent roster · handoff direction · delegation mechanism · verification loop · tmp isolation                            |
| `api-agent-team-rule.md`                                                 | `api-agent-team` orchestration invariants — the 5-agent roster · the three exposure paths · the template ② verification loop · tmp isolation                              |
| `tools-agent-team-rule.md`                                               | `tools-agent-team` orchestration invariants — prefix-preflight roster · single role axis · over-match suppression · non-ownership of the deploy gate                      |
| `api-platform-rule.md`                                                   | API Platform (Symfony) — exposing our own API: resources · operations · serialization · State · validation · security · testing                                          |
| `app-php-symfony-00~15-*-rule.md`                                        | PHP/Symfony standards (overview · architecture · configuration · controllers · services · Doctrine · forms · templates · security · testing · frontend · performance · Workflow · Mailer/Notifier · i18n · Scheduler) |
| `app-javascript-stimulus-00~03-*-rule.md`                                | JavaScript/Stimulus (modules · naming, controllers, security · performance · quality, realtime Mercure/SSE + Turbo Streams)                                              |
| `app-twig-symfony-00-overview-rule.md`                                   | Twig/Symfony template standards                                                                                                                                          |
| `cache-redis-rule.md`                                                    | Redis caching · locks · sessions · transports                                                                                                                            |
| `database-postgresql-rule.md`                                            | Entity mapping · Repository · migrations · PostgreSQL features                                                                                                           |
| `message-rabbitmq-rule.md`                                               | RabbitMQ / Symfony Messenger — transports · buses · routing · retries · failure handling · worker operation                                                              |
| `server-nginx-rule.md`                                                   | Nginx configuration (dev/prod, security, performance, deployment)                                                                                                        |
| `tools-gcp-cloudrun-rule.md`                                             | GCP / Cloud Run deployment · secrets · IAM · cost · IaC                                                                                                                  |
| `tools-aws-ecs-rule.md`                                                  | AWS ECS (Fargate) deployment · task definitions · secrets · IAM · autoscaling · cost · IaC                                                                               |
| `utility-claude-code-rule.md`                                            | Claude Code configuration artifacts (`.claude/**`) layout — flat single tier · hyphenated taxonomy · api layout freeze · scope requiring approval                        |
| `utility-drawio-diagram-rule.md`                                         | draw.io diagrams (`diagram/**/*.drawio`) — uncompressed storage · structural integrity · canvas spec · palette · multi-page editing procedure · author→reviewer verification loop |
| `utility-git-commit-rule.md`                                             | Git commit messages — Conventional Commits format · allowed types · scope derivation · subject/body rules · author→reviewer verification loop                            |
| `utility-shell-script-rule.md`                                           | Shell scripts (scripts/**) bootstrap · globals · sourcing · idempotency · taxonomy · safety (detail: `.claude/docs/utility-shell-script-docs.md`)                         |
| `abstract-structure-rule.md`                                             | this document — directory structure · path context · rule index                                                                                                          |

> ⚠️ **The table above is complete — the api provider domain has no rules.**
> `[Verified]` as of 2026-08-24: `.claude/rules/api/` does not exist, and neither do the six
> provider rules the design once called for (KoreaInvestment OAuth2 · REST · WebSocket, UPbit REST ·
> WebSocket, Agencies REST). The domain is **designed but unimplemented**, so a change under a
> provider source path (`app/src/**/Providers/Finance/**`) must be reported as **unroutable**, naming
> the rule that is missing — never silently redirected to a neighbouring domain rule such as
> `app-php-symfony-*`. See the matching `[Verified]` note in `.claude/agents/app-agent-team.md`, which
> records the same gap for the five dead skill routes it would otherwise dispatch to.

**Special case — the SoT for Claude Code configuration artifacts (`.claude/**`) is split in two.**
This domain has its criteria divided across two places.

- **Directory structure and layout** → `rules/utility-claude-code-rule.md` (auto-applied via `paths` matching).
- **Artifact spec verdicts** (frontmatter · naming · tool minimality · convention agreement) → the
  **body of the slash command** `.claude/commands/utility-claude-code-review.md` **doubles as the SoT**.
  This structure was deliberately adopted on 2026-08-08 when the author and reviewer agents were
  merged into a single command; the background and trade-offs are in section 3.5 of
  `.claude/docs/app-agent-team-docs.md`.

There is no `utility-claude-code-style.md` output style for this domain — not an omission, but a
consequence of the split above.

**A second application of the same merge pattern — the api provider domain (design only):** on
2026-08-15 the 10 provider author and reviewer agents were merged into 5 `*-build.md` commands under
`commands/api/providers/**`. The intent was that the authoring conventions, verification checklist and
known gaps sit together in each command body, with the 5 `*-build-skill` skills running a
**self-verification loop** against those commands instead of spawning agents, and the criteria (SoT)
remaining the rule files under `rules/api/**`.

> ⚠️ `[Verified]` as of 2026-08-24: **none of that survives on disk.** The 5 `*-build` commands, the 5
> `*-build-skill` directories and the `rules/api/**` files were all removed in the same flattening and
> were never rebuilt — only the 10 agents' deletion actually took effect. This paragraph describes the
> **intended** end state of the provider domain, not the current one; treat it as design history until
> the domain is implemented.

**A third application — the api-platform domain:** on 2026-08-17 `agents/api-platform-author.md` was
merged into the two commands `commands/api-platform-rest-build.md` and `api-platform-oauth2-build.md`,
and the agent itself was **repurposed** as `api-platform-analyzer` (a static structural-analysis axis).
The same change retired `commands/api-platform-test.md`, moving the per-operation test procedure into
the body of `agents/api-platform-tester.md`. Unlike the provider commands, the two build commands do
not carry their own `## Verification Checklist` — `api-platform-reviewer` and
`commands/api-platform-review.md` both survived, which would have made the criteria threefold, so
verification instead references those two and `rules/api-platform-rule.md` (SoT) via `@see`. This gave
the api-platform domain the same **four axes (analyzer · debugger · reviewer · tester)** as the app-*
domains. The history and trade-offs are in `## 6. Trade-offs and Revision History` of
`.claude/docs/api-agent-team-docs.md` (formerly section 5.1 of the consolidated document).

**Partial reversal of that third application — 2026-08-22:** `agents/api-platform-author.md`, left
empty by the merge above, was **revived**, and in the same change the 4 `*-analyzer` agents (3 app +
api-platform) were **repurposed from static structural analysis to security vulnerability diagnosis**.
The author revival came alongside filling in the 3 app-domain authors, in order to make **routing
symmetric across the 4 code domains**, and **the SoT for the authoring conventions remains the two
build commands** — the revived author references them via `@see` rather than duplicating them, so the
"avoid threefold criteria" premise of the paragraph above still holds. This gave the api-platform
domain the same **five axes (author · analyzer · debugger · reviewer · tester)** as the app-* domains.
The history is in sections 3.2 and 5.1 (revision 3) of the same document.

## Reference Documents (not rules)

Background and procedural documents that are not criteria live below. They have no `paths` matching,
so they are never auto-applied and are reached only via `@see`.

| Path                                                | Scope                                                                                                                                                                                                                     |
| --------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `.claude/docs/*-docs.md`                            | Per-domain detailed examples · reference · design background (the companion document to each rule)                                                                                                                        |
| `.claude/docs/abstract-orchestrator-contract-docs.md` | The operational contract `app-agent-team`, `api-agent-team` and `tools-agent-team` all execute — spawn contract rationale · worktree isolation and its silent-failure case · write permissions · degradation semantics · retry ownership. Carries the `abstract-` prefix because it is bound to no domain, and **pairs with three agents rather than a rule**. Holds *rationale and evidence*; the agent prompts hold the imperatives, and the authoritative agent census stays in `.claude/commands/utility-claude-code-review.md` |
| `.claude/workflows/README.md`                       | Workflow playbooks — the trigger → entry point → procedure for the 6 roles (Review · Security · Debug · Test · Build · Commit·Deploy). The design SoT is `.claude/docs/app-agent-team-docs.md` (umbrella) and `.claude/docs/api-agent-team-docs.md` (API Platform). **The directory itself is not ours alone:** `.claude/workflows/` is where Claude Code saves a dynamic workflow script, which then runs as `/<name>` `[Verified]` 2026-08-29 [WebFetch: <https://code.claude.com/docs/en/workflows>]. This `README.md` is a reference document that coexists with those scripts — it is not what makes the directory exist |
| `.claude/docs/api-providers-trade-strategy-docs.md` ⚠️ *planned* | Automated trading system design draft — a forward-looking design document that cuts across providers, so it **has no paired rule or skill** (an exception to the shared-slug convention). **Not yet written** — `[Verified]` 2026-08-24: the file does not exist. No artifact references it via `@see`; this table is its only entry point, so nothing breaks while it is absent |
| `.claude/hooks/README.md`                           | Hook wiring conventions (logic in `hooks/<event>/*.sh`, registration in `settings.json`) · the 18 directory→event mappings · the stdin/exit-code execution contract. One of the two reference documents kept outside `.claude/docs/`, alongside `workflows/README.md` — it stays co-located with the hook scripts |
| `.claude/skills/abstract-{harness,loop,graph}-engineering-skill/` | The three **meta-engineering design skills** (added 2026-09-06) — `harness` decides *what artifacts to build and how many*, `loop` decides *how a verification loop converges* (gates · verdicts · retries · stopping), `graph` decides *how nodes and edges connect* (rosters · handoffs · fan-out · routing). Listed here rather than in the rule index above because **they hold no criteria**: each explicitly disclaims being an SoT and reaches `utility-claude-code-rule.md`, `commands/utility-claude-code-review.md`, this document and the three `*-agent-team-rule.md` files by `@see`. That is also why they ship without the `rule + docs + reviewer-agent` quartet — a quartet member would be a second copy of criteria that already have an owner. The `harness` skill bundles `references/` and `examples/` (per-role agent definition templates); a skill root is flat, but the directories inside it are not constrained |
