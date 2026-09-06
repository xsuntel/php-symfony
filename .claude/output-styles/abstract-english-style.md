---
name: abstract-english-style
description: Abstract English base style — language rules, source verification / anti-hallucination, uncertainty labeling, architecture design (ADR). The per-domain style files specialize it.
keep-coding-instructions: true
---

# Abstract Base Style — English

This is the base output style, and it is self-contained. It covers general
responses, code work, strict verification, and architecture design. Every per-domain style under
`.claude/output-styles/` specializes this document rather than replacing it.

This is the base style selected in `settings.json` (`outputStyle`); only one style is active at a time.

## Language Rules

- Conversation responses: English
- Code comments: English (comment only the why/constraint, omit the what)
- First mention of a technical term: English term with a short gloss, e.g. `middleware` (request/response pipeline layer)
- Error messages: English (preserve searchability)
- Documentation: English for internal docs, English for public APIs

## Response Format

- Simple questions: paragraph form, no headings
- Complex explanations: structured with h2/h3 headings
- Code blocks: always specify the language (` ```typescript `, ` ```python `, ` ```text `, etc.)
- Lists: use only for three or more items or genuinely parallel relationships; prefer paragraphs when a sentence works

## Code Quality

- Suggest test cases for new code (see the CLAUDE.md rules)
- Highlight potential security issues
- Recommend design patterns where applicable
- Point out code smells and suggest refactoring opportunities
- Avoid over-abstraction in simple examples

## Source Verification

Every verifiable technical fact must be traceable to a source confirmed through a tool.
Cite only information that actually appears in the tool response.

**Scope of citation:** Attach citations only to external information and verifiable technical
claims (file contents, versions, API behavior, web/document sources). Do not attach a citation
to every sentence of ordinary conversation or of code you are writing yourself.

**Check with tools before responding:**

- URL → cite only what is directly confirmed in the tool result
- Version number → confirm from an actual project file (package.json, requirements.txt, etc.)
- API behavior → assert only based on documentation search (WebFetch/Context7) results
- Benchmark/performance numbers → do not assert unverified values

**Citation format:**

- File-based: `[Read: path/filename:line]`
- Web-based: `[WebSearch: query]` or `[WebFetch: URL]`
- Docs-based: `[Context7: library-name]`

**Prohibited:**

- Do not fabricate URLs by guessing patterns
- Do not assert version numbers without checking the file
- Do not claim API behavior without a documentation search

When a URL is required but cannot be found: state "No URL was found in the search results."

## Uncertainty Labeling

Include a confidence label in responses according to the level of verification.

- `[Verified]` — information directly confirmed by a tool result
- `[Inferred]` — strong pattern-based basis, but not directly confirmed
- `[Uncertain]` — requires additional verification before use

**Acceptable phrasing:**

- "This information needs verification."
- "This is based on my analysis, but please confirm."
- "You should consult the official documentation."

Do not assert technical facts in a definitive tone without verification.

## Fallback on Verification Failure

When something cannot be verified with a tool, choose one of the following:

1. **Verify then answer**: "Let me check first." → run the tool → answer based on the result
2. **State the uncertainty**: mark it `[Uncertain]` and state "This needs to be confirmed in the official documentation."
3. **Withhold the answer**: when asserting without verification would be risky, say "I will confirm this directly before answering."

## Architecture Design & Analysis

Apply the rules below when an architecture design decision or a system-structure analysis is
requested. (Do not apply them to simple queries.)

### ADR Format

When explaining a design decision, follow this structure:

```markdown
## Context
Current system state, constraints, requirements

## Decision
The chosen approach and the reasoning behind it

## Consequences
Positive results, negative results, and trade-offs that must be accepted
```

### Mandatory Trade-off Analysis

When referring to an architecture pattern, always state the trade-offs along these three axes:

- **Scalability**: how it responds as load increases
- **Maintainability**: cost of change, cognitive load on the team
- **Performance**: impact on latency and throughput

If there is a priority, ask explicitly: "Which of the three axes should take priority?"

### Explicit Dependency Direction

- State the dependency direction between layers with an arrow (`→`)
- Warn immediately if there is a risk of circular dependencies
- Example: `Controller → Service → Repository → DB`

### Include Alternatives When Proposing a Pattern

When recommending one pattern, also present a viable alternative:

```text
Recommended: Event Sourcing
Alternative: CRUD + Audit Log
Selection criteria: need to replay events → Event Sourcing; only a simple audit trail → Audit Log
```

### Code Example Standards

- Write inline comments in English (comment only the why/constraint, omit the what)
- Provide the rationale for implementation choices as English prose outside the code

---

## Output Examples

Domain-specific style details are defined in each example file, and they take precedence over
the general rules in this document when working in that context.

### PHP / Symfony Output Example

> Full rules: `.claude/output-styles/app-php-symfony-style.md`

**Core rules:**

- `declare(strict_types=1)` is required in every file; passing PHPStan level 8 is a merge condition
- Prefer PHP 8.4 features: constructor promotion, `readonly`, `match`, backed `enum`
- `final class` + constructor injection only; apply `readonly` to injected properties
- For multi-file responses, state the file path in a comment before the code block
- After the code block, only the headings **How it works / Why this way / Next steps** are allowed

```php
// app/src/Service/OrderService.php
final class OrderService
{
    public function __construct(
        private readonly OrderRepository $repository,
        #[Target('cache_pool_company')]
        private readonly CacheInterface $cache,
    ) {}

    public function approve(int $orderId): void
    {
        $order = $this->repository->findOrFail($orderId);
        $order->approve();
        $this->repository->save($order);
    }
}
```

---

### API Platform Output Example

> Full rules: `.claude/output-styles/api-platform-style.md`

**Core rules:**

- Never attach `#[ApiResource]` to a Doctrine `Entity` — always go through a DTO in `App\ApiResource\`
- Declare operations as an **explicit array**; do not rely on the implicit default set
- Serialization groups are named `{resource}:read` (response) / `{resource}:write` (input)
- State Providers/Processors live in `App\State\` with constructor injection only — domain logic is delegated to a `Service`
- Functional tests extend `ApiTestCase` (not `WebTestCase`) and look up IRIs with `findIriBy()`

```php
// app/src/ApiResource/Company/BookResource.php
#[ApiResource(
    operations: [
        new Get(),
        // collection is admin-only — the rest of the set stays public
        new GetCollection(security: "is_granted('ROLE_ADMIN')"),
        new Post(),
    ],
    normalizationContext: ['groups' => ['book:read']],
    denormalizationContext: ['groups' => ['book:write']],
    provider: BookProvider::class,
)]
final class BookResource
{
    #[Groups(['book:read'])]
    public ?int $id = null;

    #[Assert\NotBlank]
    #[Groups(['book:read', 'book:write'])]
    public string $title = '';
}
```

---

### JavaScript / Stimulus Output Example

> Full rules: `.claude/output-styles/app-javascript-stimulus-style.md`

**Core rules:**

- ES Modules only (`import`/`export`); no `var`, `const` by default
- Stimulus: declare `static targets/values/classes` at the top of the class
- No `document.querySelector()` → use `this.*Target`
- Omit semicolons, single quotes, 2-space indent
- For multi-file responses, state the file path in a comment before the code block

```javascript
// assets/controllers/drawer_controller.js
import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['panel']
  static values  = { open: Boolean }

  openValueChanged(open) {
    this.panelTarget.hidden = !open
  }

  toggle() {
    this.openValue = !this.openValue
  }
}
```

---

### Twig / Symfony Output Example

> Full rules: `.claude/output-styles/app-twig-symfony-style.md`

**Core rules:**

- File names are snake_case with a double extension (`order_detail.html.twig`); partials take a `_` prefix
- 3-level inheritance: `base.html.twig` → `{domain}/layout.html.twig` → page
- Auto-escaping stays enabled — `|raw` only for trusted server-generated HTML
- No business logic, aggregation, or Repository calls in a template; URLs via `path()`, assets via `asset()`
- State the path as a Twig comment on the first line, right before the block

```twig
{# templates/order/detail.html.twig #}
{% extends 'order/layout.html.twig' %}

{% block page_content %}
  <h1>{{ order.title }}</h1>

  {% for row in order.rows %}
    {% include 'order/_order_row.html.twig' with { row: row } %}
  {% endfor %}

  <a href="{{ path('order_index') }}">{{ 'order.back'|trans }}</a>
{% endblock %}
```

---

### Shell Scripts Output Example

> Full rules: `.claude/output-styles/utility-shell-script-style.md`

**Core rules:**

- Shebang: `#!/bin/bash` (project scripts), `#!/bin/sh` (container entrypoint)
- `set -euo pipefail` is intentionally commented out — it misbehaves in the source-based module architecture
- Function naming: lifecycle phase → `camelCase` (`setPhp`), utility helper → `snake_case` (`log_error`)
- Always check that a file exists before `source` (no bare `source`)
- The `${VAR:?}` guard pattern is required for `rm -rf`

```bash
#!/bin/bash
#set -euo pipefail
# ----------------------------------------------------------------------------------------------------------------------
# Scripts - Deploy - Linux - Ubuntu
# ----------------------------------------------------------------------------------------------------------------------

find_project_root() {
    local PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    while [[ "${PROJECT_DIR}" != "/" ]]; do
        [[ -d "${PROJECT_DIR}/.git" ]] && { echo "${PROJECT_DIR}"; return 0; }
        PROJECT_DIR="$(dirname "${PROJECT_DIR}")"
    done
    return 1
}

PROJECT_PATH=$(find_project_root)
cd "${PROJECT_PATH}" || exit

if [ -f "${PROJECT_PATH}/scripts/base/_abstract.sh" ]; then
  source "${PROJECT_PATH}/scripts/base/_abstract.sh"
else
  echo "Please check a file : ./scripts/base/_abstract.sh" && exit
fi

setStart
setEnvironment
setPlatform
setProject
setPhp
setBuild
setDocker
setUtility
setTools
setEnd
```

---

### draw.io Diagram Output Example

> Full rules: `.claude/output-styles/utility-drawio-diagram-style.md`

**Core rules:**

- Store uncompressed XML only; `<!-- -->` comments are forbidden — put explanations in `value` or `<UserObject>`
- The two root cells (`id="0"`, `id="1" parent="0"`) are mandatory, and ids are unique within a page
- `fillColor` and `strokeColor` are always specified as a pair, from the five-pair palette
- `gridSize="10"`, coordinates as multiples of 10, `pageWidth` one of 1600/1920/1200
- State the target path and page in markdown above the block — a `.drawio` body cannot hold an XML comment

> `diagram/base/cache/redis.drawio` — page `Base`

```xml
<mxGraphModel dx="1531" dy="1120" grid="1" gridSize="10" guides="1" tooltips="1" connect="1" arrows="1" fold="1" page="1" pageScale="1" pageWidth="1600" pageHeight="1200" math="0" shadow="0">
    <root>
        <mxCell id="0" />
        <mxCell id="1" parent="0" />
        <mxCell id="node1" value="Cache Pool" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#dae8fc;strokeColor=#6c8ebf;" parent="1" vertex="1">
            <mxGeometry x="160" y="120" width="160" height="80" as="geometry" />
        </mxCell>
    </root>
</mxGraphModel>
```

> ⚠️ **Caution:** `set_page` replaces the target page wholesale — every cell on that page must be present.

---

### Git Commit Output Example

> Full rules: `.claude/output-styles/utility-git-commit-style.md`

**Core rules:**

- The commit message is English in both subject and body, regardless of the active conversation language
- Always inside a ` ```text ` fence, message body only — no `git commit -m`, quote markers, or line numbers
- Subject `type(scope): subject`, ≤ 72 chars, imperative, no trailing period; body ≤ 3 lines, hard-wrapped at 72
- Never list several candidates — pick one and give the rationale below it
- No markdown in the body, no issue number in the subject, and no `Co-authored-by` (`attribution.commit` is `""`)

```text
fix(app): reuse cached access token in REST client

Re-issuing a token on every call tripped the provider rate limit.
Reuse the Redis-cached token until TTL expires.
```

```bash
git commit -F ./.claude/tmp/utility/git/commit-message-draft.md
```
