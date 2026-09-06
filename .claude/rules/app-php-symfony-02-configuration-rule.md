---
paths:
  - "app/src/**/*.php"
---

# Configuration Rule

@see https://symfony.com/doc/current/configuration.html

## Environment Variable Processors

Use typed processors to cast and transform environment variables at the container level:

- `%env(int:MAX_ITEMS)%` — cast to integer
- `%env(json:ALLOWED_IPS)%` — parse a JSON string into an array
- `%env(resolve:APP_SECRET)%` — resolve a reference to another environment variable
- `%env(file:CERT_PATH)%` — read the file at the given path as the value
- For a database password containing special characters, prefer individual parameter variables over the URL form to avoid encoding issues.

@see https://symfony.com/doc/current/configuration/env_var_processors.html

## .env File Loading Priority (high → low)

1. `.env.local.php` (compiled cache for production)
2. `.env.{APP_ENV}.local` (e.g. `.env.dev.local`)
3. `.env.{APP_ENV}` (e.g. `.env.test`)
4. `.env.local`
5. `.env`

@see https://symfony.com/doc/current/configuration.html#config-dot-env

## Required .gitignore Entries

Never commit the following files:

- `.env.local`
- `.env.*.local`
- `.env.local.php`

## Configuration File Format

- Package configuration (`config/packages/`): prefer YAML.
- Service configuration (`config/services.yaml`): prefer YAML.
- Use one format consistently across the whole team (choose either YAML or PHP).
- XML is allowed only in the exceptional case where IDE autocompletion requires it.

## Environment Variables (Infrastructure Configuration)

Use environment variables for values that differ per machine (database credentials, external API URLs, ports).

- Use the `.env` / `.env.local` / `.env.test` file hierarchy.
- `.env` is committed — include only non-sensitive defaults and documentation.
- **Never** commit `.env.local` — it overrides `.env` on the local machine.
- In production, inject variables through the host environment or a secrets manager, not `.env.local`.

@see https://symfony.com/doc/current/configuration.html#config-env-vars

## Secrets (Sensitive Values)

Store API keys, encryption keys, and other sensitive credentials in Symfony's Secrets system.

```bash
php bin/console secrets:set MY_API_KEY
php bin/console secrets:list --reveal   # dev only
```

- Secrets are encrypted when stored under `config/secrets/{env}/`.
- The decryption key lives outside the repository — never commit it.

@see https://symfony.com/doc/current/configuration/secrets.html

## Parameters (Application Behavior)

Define options that control application behavior in the `parameters` block of `config/services.yaml`.

- Always use the `app.` prefix to avoid clashing with Symfony's own parameters.
- Format: `app.{purpose}` — e.g. `app.items_per_page`, `app.upload_dir`.

```yaml
# Correct
parameters:
    app.items_per_page: 20
    app.upload_dir: '%kernel.project_dir%/public/uploads'

# Wrong — too vague, no prefix
parameters:
    dir: '../uploads'
```

Inject parameters into services via `#[Autowire]`:

```php
public function __construct(
    #[Autowire(param: 'app.upload_dir')]
    private readonly string $uploadDir,
) {}
```

@see https://symfony.com/doc/current/best_practices.html#use-constants-to-define-options-that-rarely-change

## Constants (Values That Rarely Change)

Define values that rarely change as PHP class constants, not parameters.

```php
#[ORM\Entity]
class Post
{
    public const int ITEMS_PER_PAGE = 20;
    public const int TITLE_MAX_LENGTH = 255;
}
```

Constants are also accessible from Twig templates and Doctrine queries, so for domain-level values they offer better reusability than parameters.
