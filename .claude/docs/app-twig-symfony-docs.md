# Twig / Symfony Templates — Technical Reference

This document provides a **detailed reference and code examples** for Twig 3.x syntax and Symfony 8
template conventions. The enforced judgment criteria (SoT) live in the rule files; this document holds
their detailed/example edition — if it conflicts with a rule, the rule wins.

@see .claude/rules/app-twig-symfony-00-overview-rule.md — Twig judgment criteria (SoT)
@see .claude/rules/app-php-symfony-07-template-rule.md — template naming, inheritance, components
@see .claude/rules/app-php-symfony-10-frontend-rule.md — AssetMapper, Stimulus, UX
@see <https://twig.symfony.com/doc/3.x/> — Twig official docs
@see <https://symfony.com/doc/current/templates.html> — Symfony templates official docs

---

## 1. Technical Environment

| Item | Version / Setting |
| --- | --- |
| Twig | 3.x |
| Symfony | 8.0.x (`symfony/twig-bundle`) |
| Template root | `app/templates/` |
| Render engine | `Twig\Environment` (`$this->render()` / `#[Template]`) |
| Auto-escaping | `html` strategy, enabled by default |
| Lint | `php bin/console lint:twig` |
| Debug | `php bin/console debug:twig`, `{{ dump() }}` |
| Frontend | AssetMapper + Stimulus/Turbo (Hotwire), Tailwind |

---

## 2. Delimiters and Comments

Twig has three kinds of delimiters.

```twig
{{ user.name }}                 {# Output: renders a variable/expression #}
{% if user.active %}...{% endif %}  {# Logic: control structures #}
{# This is a comment and is not rendered #}
```

---

## 3. Variable Access

```twig
{{ user.name }}            {# Dot notation: resolves property → getName()/isName()/hasName() → array key #}
{{ user['name'] }}         {# Subscript: array key access #}
{{ array[0] }}
{{ attribute(user, methodName) }}   {# Dynamic attribute access #}
```

- Dot notation tries property, getter, then array key in order. Use the subscript to force a specific array key.
- Accessing an undefined variable yields `null` by default (when strict_variables is off), or throws.

---

## 4. Filters

Transform a value with the pipe `|`. Filters can be chained.

```twig
{{ name|upper }}
{{ "hello"|capitalize|reverse }}
{{ list|join(', ') }}
{{ price|number_format(2, '.', ',') }}
{{ post.createdAt|date('Y-m-d H:i', 'Asia/Seoul') }}
{{ text|default('N/A') }}
{{ items|length }}
{{ description|slice(0, 100) }}
{{ collection|filter(v => v.active)|map(v => v.name)|join(', ') }}
```

Frequently used filters: `escape`/`e`, `raw`, `default`, `date`, `number_format`, `format`, `join`, `split`,
`length`, `upper`/`lower`, `capitalize`, `title`, `trim`, `nl2br`, `slice`, `first`/`last`, `keys`,
`merge`, `sort`, `reverse`, `batch`, `map`, `filter`, `reduce`, `find`, `json_encode`, `url_encode`, `abs`, `round`.

Locale/string/Markdown filters provided by extension packages (installation required):

```twig
{{ price|format_currency('KRW') }}                     {# twig/intl-extra #}
{{ post.createdAt|format_datetime('medium', 'short', locale='ko') }}
{{ count|format_number(style='percent') }}
{{ title|u.truncate(30, '…') }}                        {# twig/string-extra (u filter) #}
{{ title|slug }}                                        {# URL slug #}
{{ comment.body|markdown_to_html }}                     {# twig/markdown-extra + league/commonmark (sanitize) #}
```

- `format_*` (intl), `u`/`slug` (string), and `markdown_to_html` (markdown) are only available after
  installing `twig/intl-extra`, `twig/string-extra`, and `twig/markdown-extra` respectively.
- `markdown_to_html` on user input must go through a server-side sanitized CommonMark environment (§11 Security).

---

## 5. Functions

```twig
{% for i in range(1, 5) %}{{ i }}{% endfor %}
{{ include('blog/_card.html.twig', { post: post }) }}
{{ block('title') }}          {# Output another block of the current template #}
{{ parent() }}                {# Insert the parent block's content #}
{{ cycle(['odd', 'even'], loop.index0) }}
{{ constant('App\\Entity\\Post::STATUS_PUBLISHED') }}
{{ min(users|length, 10) }} / {{ max(a, b) }}
{{ dump(post) }}              {# debug environment only #}
```

Reference backed enums (PHP 8.4) safely from templates — use `enum()`/`enum_cases()` instead of magic strings.

```twig
{{ enum('App\\Enum\\OrderStatus::Approved').value }}     {# Access a single case #}
{% for status in enum_cases('App\\Enum\\OrderStatus') %} {# Iterate all cases #}
    <option value="{{ status.value }}">{{ status.name }}</option>
{% endfor %}

{{ html_classes('badge', { 'badge-danger': order.isCanceled }) }}  {# Conditional class composition #}
{{ source('legal/_disclaimer.txt') }}          {# Insert a template verbatim without rendering it #}
{{ include(template_from_string("Hello {{ name }}"), { name: user.name }) }}
```

Key functions: `range`, `cycle`, `constant`, `enum`, `enum_cases`, `include`, `block`, `parent`,
`dump`, `min`, `max`, `random`, `date`, `attribute`, `source`, `html_classes`, `html_cva`,
`template_from_string`.

- `enum()`/`enum_cases()` take an FQCN as a string, so a typo throws at runtime — use the exact namespace.
- `html_classes`/`html_cva` are provided by `twig/html-extra` (included in `symfony/twig-pack`).

---

## 6. Control Structures (Tags)

```twig
{% for item in items %}
    {{ loop.index }}: {{ item.name }}
{% else %}
    No items.
{% endfor %}

{% if user.admin %}...{% elseif user.editor %}...{% else %}...{% endif %}

{% set fullName = user.first ~ ' ' ~ user.last %}

{% apply upper %}filtered block{% endapply %}       {# Apply a filter to the whole block #}
{% do form.handleRequest(request) %}               {# Execute an expression with no output #}

{% verbatim %}{{ printed as-is }}{% endverbatim %}

{% cache 'sidebar' ttl(300) %}...{% endcache %}    {# Cache an expensive fragment (twig/cache-extra) #}
{% deprecated 'block "old_body" is deprecated — use "body"' %}   {# Deprecation warning #}
```

- `loop` variables: `loop.index` (from 1), `loop.index0`, `loop.first`, `loop.last`, `loop.length`.
- Tags: `for`, `if`, `set`, `block`, `extends`, `include`, `embed`, `use`, `macro`/`import`/`from`,
  `with`, `apply`, `autoescape`, `verbatim`, `filter`, `do`, `cache`, `deprecated`, `sandbox`,
  `types`, `guard`.
- The `cache` tag requires `twig/cache-extra`. Use it only on heavy, repeatedly rendered fragments, and specify the cache key and TTL.
- `sandbox` restricts the allowed tags/filters when rendering untrusted templates (e.g. user-provided).

---

## 7. Tests and the `is` Operator

```twig
{% if user is defined %}...{% endif %}
{% if items is empty %}...{% endif %}
{% if value is not null %}...{% endif %}
{% if loop.index is even %}...{% endif %}
{% if number is divisible by(3) %}...{% endif %}
{% if post.status is same as(constant('App\\Entity\\Post::PUBLISHED')) %}...{% endif %}
```

Key tests: `defined`, `empty`, `null`, `even`, `odd`, `iterable`, `same as`, `divisible by`, `constant`.

---

## 8. Operators

```twig
{{ 1 + 2 }} {{ 6 / 2 }} {{ 7 // 2 }} {{ 11 % 3 }} {{ 2 ** 3 }}  {# Arithmetic (// is integer division) #}
{{ a and b }} {{ a or b }} {{ not a }}                 {# Logic #}
{{ x == y }} {{ x === y }} {{ x != y }} {{ x >= y }}   {# Comparison (=== is strict, type-aware) #}
{{ "Hello " ~ name }}                                   {# ~ string concatenation #}
{% for i in 1..5 %}{{ i }}{% endfor %}                 {# .. range #}
{{ active ? 'yes' : 'no' }} {{ label ?: 'default' }}   {# Ternary / elvis #}
{{ value ?? 'fallback' }}                              {# Null coalescing #}
{% if 'a' in list %}...{% endif %}                     {# Containment #}
{% if roles has some ['ROLE_ADMIN', 'ROLE_EDITOR'] %}{% endif %}   {# Contains at least one #}
{% if flags has every ['a', 'b'] %}{% endif %}         {# Contains all #}
{% if name starts with 'A' %}{% endif %}               {# starts with / ends with / matches #}
```

### Whitespace Control and String Interpolation

```twig
{{- value -}}          {# Hyphen: strip whitespace before/after the tag #}
{%- if x -%}...{%- endif -%}
{{ "Hello #{user.name}, welcome" }}   {# Interpolation: evaluate the expression inside #{...} (double quotes only) #}
```

- `-` strips the whitespace on the adjacent side(s) — use it to remove unwanted gaps between inline elements.
- String interpolation (`#{}`) works only in **double-quoted** strings. Single quotes are treated literally.

---

## 9. Template Inheritance (3 levels)

```twig
{# templates/base.html.twig — layout root #}
<!DOCTYPE html>
<html>
    <head>
        <title>{% block title %}My App{% endblock %}</title>
        {% block stylesheets %}{% endblock %}
    </head>
    <body>
        {% block body %}{% endblock %}
        {% block javascripts %}{% endblock %}
    </body>
</html>
```

```twig
{# templates/blog/layout.html.twig — section layout #}
{% extends 'base.html.twig' %}
{% block body %}
    <h1>Blog</h1>
    {% block page_contents %}{% endblock %}
{% endblock %}
```

```twig
{# templates/blog/index.html.twig — page #}
{% extends 'blog/layout.html.twig' %}
{% block title %}Blog Index{% endblock %}
{% block page_contents %}
    {% for article in articles %}
        <h2>{{ article.title }}</h2>
    {% endfor %}
{% endblock %}
```

- Use `{{ parent() }}` to keep the parent block's content.
- `{% extends %}` — one per template, at the top of the file.

---

## 10. Include · Embed · Macro

```twig
{# Partial template (filename _ prefix) #}
{{ include('blog/_user_profile.html.twig', { user: post.author }) }}
{{ include('sidebar.html.twig', with_context = false) }}   {# Block the parent context #}

{# embed: include + block override #}
{% embed 'components/_modal.html.twig' %}
    {% block modal_body %}<p>Content</p>{% endblock %}
{% endembed %}

{# macro: reusable HTML fragment (no access to outer variables — pass them as arguments) #}
{% macro input(name, value = '', type = 'text') %}
    <input type="{{ type }}" name="{{ name }}" value="{{ value }}">
{% endmacro %}

{% import 'forms/_macros.html.twig' as forms %}
{{ forms.input('username') }}

{% from 'forms/_macros.html.twig' import input %}
{{ input('email', user.email) }}
```

---

## 11. Auto-escaping and Security

Auto-escaping is **enabled by default** with the `html` strategy. It is the core of XSS prevention.

```twig
{{ comment.content }}          {# Safe: auto-escaped #}
{{ comment.content|raw }}      {# Dangerous: never on user input #}

{{ value|e('js') }} {{ value|e('css') }} {{ value|e('url') }} {{ value|e('html_attr') }}
```

- Use `|raw`/`{% autoescape false %}` **only on trusted, server-generated HTML**. Never on user/DB input.
- To display untrusted HTML, sanitize it server-side (`league/commonmark`, etc.) before `|raw`.
- Choose the escape strategy (`js`/`css`/`url`/`html_attr`) that matches the output context.

---

## 12. Symfony-specific Functions

```twig
{# Routing — never hardcode URLs #}
<a href="{{ path('blog_show', { slug: post.slug }) }}">{{ post.title }}</a>
<link rel="canonical" href="{{ url('blog_show', { slug: post.slug }) }}">   {# Absolute URL #}

{# Assets (AssetMapper) #}
<img src="{{ asset('images/logo.png') }}" alt="Logo">
<img src="{{ absolute_url(asset('images/logo.png')) }}">   {# Email/RSS #}

{# CSRF #}
<form method="post" action="{{ path('order_approve', { id: order.id }) }}">
    <input type="hidden" name="_token" value="{{ csrf_token('approve_order') }}">
</form>

{# Authorization — controls visibility only, does not replace server-side authorization #}
{% if is_granted('ROLE_ADMIN') %}<a href="{{ path('admin') }}">Admin</a>{% endif %}
{% if is_granted('edit', article) %}...{% endif %}
```

### Fragment Rendering (Sub-requests)

Render a fragment that needs controller logic from a template — it runs as a separate sub-request.

```twig
{{ render(controller('App\\Controller\\BlogController::recentArticles', { max: 3 })) }}
{{ render(path('latest_articles', { max: 3 })) }}   {# Via a route #}
{{ render_esi(controller('App\\Controller\\BlogController::recentArticles')) }}  {# Reverse-proxy ESI #}
{{ render_hinclude(controller('...'), { default: 'spinner.html.twig' }) }}       {# Async load #}
```

Using `controller()` requires a fragment path in `config/packages/framework.yaml`:

```yaml
framework:
    fragments: { path: /_fragment }
```

- Every fragment render is a sub-request — repeated use is costly. Use it **only when you need
  independent caching**; for simple reuse prefer `include`/components (§10, §19).
- `render_esi` acts as a real separate cache only when a reverse proxy (e.g. Symfony HttpCache/Varnish) supports ESI.

---

## 13. The `app` Global Variable

```twig
{{ app.user.username ?? 'Anonymous' }}
{{ app.request.pathinfo }} {{ app.request.method }}
{% for message in app.flashes('notice') %}<div class="notice">{{ message }}</div>{% endfor %}
{{ app.environment }} {{ app.debug }} {{ app.locale }}
{{ app.current_route }}
```

`app` is not `App\...` but the `GlobalVariables` object injected by Symfony: `app.user`, `app.request`,
`app.session`, `app.flashes`, `app.environment`, `app.debug`, `app.locale`, `app.token`,
`app.current_route`, `app.enabled_locales`.

---

## 14. Form Rendering

```twig
{{ form_start(form) }}
    {{ form_row(form.title) }}
    {{ form_row(form.body) }}
    {{ form_rest(form) }}       {# Unrendered fields + CSRF _token #}
{{ form_end(form) }}

{# Granular #}
{{ form_label(form.title) }}
{{ form_widget(form.title) }}
{{ form_errors(form.title) }}
```

- Symfony Form embeds the CSRF token (`_token`), so `form_rest()`/`form_end()` include it automatically.
- Set the form theme via `form_themes` in `twig.yaml` or `{% form_theme form 'theme.html.twig' %}`.

---

## 15. Controller Rendering

```php
// Standard
return $this->render('blog/index.html.twig', ['articles' => $articles]);

// When only a string is needed (email body, etc.)
$html = $this->renderView('email/notification.html.twig', ['user' => $user]);

// #[Template] attribute — return an array → automatic Response
#[Template('blog/index.html.twig')]
public function index(): array
{
    return ['articles' => $articles];
}

// Render a single block only (useful for Turbo Stream/AJAX partial updates)
return $this->renderBlock('blog/show.html.twig', 'price_block', ['product' => $product]);
$fragment = $this->renderBlockView('blog/show.html.twig', 'price_block', ['product' => $product]);

// A single block can also be specified via #[Template]'s block parameter
#[Template('blog/show.html.twig', block: 'price_block')]
public function price(): array
{
    return ['product' => $product];
}
```

- `renderBlock()`/`renderBlockView()` render only the named block, not the whole page — use them to
  return just a fragment without layout inheritance in a Turbo Stream response or partial update.
- When a service needs to render, inject `Twig\Environment` and call `$twig->render(...)`.

---

## 16. Template Namespaces and twig.yaml Configuration

Configure extra paths, global variables, and strict mode in `config/packages/twig.yaml`.

```yaml
# config/packages/twig.yaml
twig:
    default_path: '%kernel.project_dir%/templates'
    paths:
        '%kernel.project_dir%/templates/email': 'email'   # @email namespace
        '%kernel.project_dir%/vendor/acme/theme': 'Theme'  # @Theme namespace
    globals:
        ga_tracking: '%env(GA_TRACKING_ID)%'               # Static global value
        app_version: '@App\Service\VersionProvider'        # Service reference
    strict_variables: '%kernel.debug%'                     # Throw on undefined variables in dev
    form_themes: ['form/theme.html.twig']
```

```twig
{{ include('@email/_layout.html.twig') }}   {# Reference a namespaced path #}
{{ include('@Theme/header.html.twig') }}
```

- Manage global values via `globals` — do not hardcode them in templates.
- Setting `strict_variables` to `true` (`%kernel.debug%`) in dev catches typos and undelivered variables early.
- A namespace path typo causes `Unable to find template`, so keep the `paths` keys exact.
- To conditionally check template existence, use `$twig->getLoader()->exists('theme/_layout.html.twig')` in PHP.

## 17. TemplateController — Rendering a Route Without Logic

For static pages with no controller logic at all (terms, policies, etc.), render directly from the route with `TemplateController`.

```yaml
# config/routes.yaml
privacy_policy:
    path: /privacy
    controller: Symfony\Bundle\FrameworkBundle\Controller\TemplateController
    defaults:
        template: 'static/privacy.html.twig'
        maxAge: 86400            # HTTP cache (seconds)
        sharedAge: 86400
        context: { site_name: 'XSUN' }   # Variables passed to the template
```

- Use it only when the data is static and there is no logic — use a regular controller if a query or authorization is needed.

## 18. Twig Extensions (Filters/Functions)

For pure transformations with no dependencies, use attribute-based extensions (recommended).

```php
// app/src/Twig/AppExtension.php
namespace App\Twig;

use Twig\Attribute\AsTwigFilter;
use Twig\Attribute\AsTwigFunction;

final class AppExtension
{
    #[AsTwigFilter('price')]
    public function formatPrice(float $number, int $decimals = 0): string
    {
        return '$'.number_format($number, $decimals);
    }

    #[AsTwigFunction('area')]
    public function area(int $w, int $h): int
    {
        return $w * $h;
    }
}
```

- When dependency injection or lazy loading is needed, use the `AbstractExtension` + `RuntimeExtensionInterface` (Runtime class) pattern.
- Keep extension logic in PHP, not templates — do not perform heavy computation in templates.

---

## 19. Twig Components (UX)

```php
// app/src/Twig/Components/Alert.php
namespace App\Twig\Components;

use Symfony\UX\TwigComponent\Attribute\AsTwigComponent;

#[AsTwigComponent]
final class Alert
{
    public string $type = 'success';
    public string $message = '';
}
```

```twig
<twig:Alert type="danger" message="Save failed" />
```

- Use TwigComponent/LiveComponent for reusable UI with behavior; use `include`/`embed`/`macro` for static fragments.

---

## 20. Debugging · Performance

```bash
# Syntax/deprecation lint (CI gate)
cd app && php bin/console lint:twig templates/
cd app && php bin/console lint:twig --show-deprecations --format=github templates/

# Look up filters/functions/globals/paths
cd app && php bin/console debug:twig
cd app && php bin/console debug:twig --filter=date
cd app && php bin/console debug:twig blog/index.html.twig

# Cache warming (production)
cd app && php bin/console cache:warmup
```

```twig
{# debug environment only — remove before commit #}
{{ dump(article) }}
{% dump articles, app.user %}
```

Performance principles: do not call the Repository/DB from templates (prepare data in the
controller/Extension), minimize repeated includes, and warm the Twig compile cache in production.

---

## 21. Verification Checklist

The review checklist derives from the rules (SoT), so it is not duplicated here. After implementation,
review each Twig file with the `/app-twig-symfony-review {file}` command; the judgment criteria are
single-sourced in `.claude/rules/app-twig-symfony-00-overview-rule.md` and `.claude/rules/app-php-symfony-07-template-rule.md`.
