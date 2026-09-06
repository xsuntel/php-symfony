## Summary of changes

<!-- Concisely describe what changed and why -->

## Type of change

- [ ] feat (new feature)
- [ ] fix (bug fix)
- [ ] refactor (improvement with no behavior change)
- [ ] chore / docs / test

## How to test

<!-- Steps a reviewer can follow to reproduce -->

## Checklist

- [ ] PHPStan level 8 passes (`cd app && vendor/bin/phpstan analyse`)
- [ ] PHP-CS-Fixer formatted (`cd app && vendor/bin/php-cs-fixer fix --dry-run --diff`)
- [ ] PHPUnit passes (Unit / Integration / Functional as applicable)
- [ ] All new PHP files include `declare(strict_types=1)`
- [ ] No secrets or credentials included (use `.env.local` / Secret Manager)
- [ ] For schema changes, migration impact and rollback procedure are documented
