---
paths:
  - "app/translations/**"
  - "app/templates/**/*.html.twig"
  - "app/src/**/*.php"
  - "app/config/packages/translation.yaml"
---

# Translation / i18n Rule

@see https://symfony.com/doc/current/translation.html
@see .claude/docs/app-php-symfony-docs.md §17 — catalog structure · ICU pluralization · locale switcher · extraction workflow

This application supports multiple languages (Korean by default, English as fallback). User-facing strings
are managed as catalog keys and are not hardcoded in templates or PHP.

> **Note on the English-documentation rule:** the Korean strings in the examples below are `ko` catalog
> **sample data**, not prose. `CLAUDE.md` requires documentation to be written in English; it does not
> require translating the contents of a Korean message catalog, which is the very thing being
> illustrated. Leave them as they are. The same applies to §17 of
> `.claude/docs/app-php-symfony-docs.md`.

## Locale Policy (`config/packages/translation.yaml`)

- `default_locale: ko`, `enabled_locales: [ko, en]`, `fallbacks: [en]` — these values are the SoT.
- An untranslated key falls back to `en` — add a new key to **both the `ko` and `en` catalogs together**.

## Catalog Conventions

- Path/format: `translations/app.{locale}.yml` (domain `app`, extension `.yml`).
- Organize keys as a **nested structure** and access them with dot notation — e.g. `navbar.account.user`.
- Keep the same key set as an identical tree across every locale file (a key present in only one file is exposed only via fallback).

```yaml
# translations/app.ko.yml   (values shown as "[ko] …" glosses — the real catalog holds Korean text)
navbar:
    account:
        user: "[ko] User"
        profile: "[ko] Profile"

# translations/app.en.yml
navbar:
    account:
        user: "User"
        profile: "Profile"
```

## Strings as Keys (No Hardcoding)

- Output user-facing strings as catalog keys, not literals.
- Twig: specify the domain `app` explicitly, or declare `{% trans_default_domain 'app' %}` at the top of the template.

```twig
{# Prohibited — hardcoded (a literal user-facing string, in whatever language) #}
<span>[ko] User</span>

{# Recommended — catalog key (domain app) #}
<span>{{ 'navbar.account.user'|trans({}, 'app') }}</span>
```

- PHP: use `TranslatorInterface::trans()` and pass the domain `app`. Do not translate log or exception messages (keep them in English, consistent with `08` and the quality rules).

```php
use Symfony\Contracts\Translation\TranslatorInterface;

$label = $this->translator->trans('navbar.account.user', [], 'app');
```

## Plurals · Variables — ICU MessageFormat

- Use **ICU MessageFormat** for plural/gender/conditional branching, not manual string assembly.
- ICU syntax requires the `+intl-icu` suffix on the domain — name the catalog file `app+intl-icu.{locale}.yml`.

```yaml
# translations/app+intl-icu.ko.yml   (values shown as "[ko] …" glosses)
notification.count: "{count, plural, =0 {[ko] no notifications} other {[ko] # notifications}}"
```

## Locale Switching

- The current locale is determined by the `_locale` route parameter in the URL (constrained with `requirements: {_locale: 'ko|en'}`).
- When you must change the locale at runtime, inject `LocaleSwitcher` — do not call `$request->setLocale()` directly outside a controller.

## Localization Utilities — `symfony/intl`

- Use `symfony/intl` · `IntlFormatter` for country/language/currency names and formats (numbers · dates), not a hardcoded mapping.

## Verification

```bash
cd app && php bin/console debug:translation ko --only-missing   # detect missing keys
cd app && php bin/console debug:translation en --only-missing
cd app && php bin/console translation:extract ko --domain=app --force   # extract keys from templates
```
