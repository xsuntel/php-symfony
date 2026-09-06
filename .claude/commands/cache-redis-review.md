---
description: "Assesses the quality of Symfony Cache / Redis usage code and provides structured improvement recommendations."
argument-hint: "[path to the file to analyze (a PHP file or cache.yaml)]"
---

Analyze the following cache-related file:

**`$ARGUMENTS`**

> **When the argument is empty**, review the Symfony Cache config files as a single set (the SoT for cache
> pools, adapters, and per-environment overrides):
>
> - `app/config/packages/cache.yaml`
> - `app/config/packages/dev/cache.yaml`
> - `app/config/packages/prod/cache.yaml`
>
> When code-level judgment is needed (cache-pool injection, TTL, tag invalidation, distributed locks,
> etc.), pass the target file as the argument — e.g. `app/src/Service/**`, `app/config/packages/lock.yaml`.
> Do not blindly scan files outside the list above or the argument you were given, and do not guess a
> target.

The single source of truth (SoT) for the judgment criteria is the rule file. At the start, read the rule
below, cross-check each provision against the target code, flag violations with the **exact line number**,
and provide concrete fixes (improved code snippets). Do not restate the criteria in this command.

Before flagging, read the `cache.yaml` dev/prod pair first to establish the project's pool topology
(pool names, providers, per-environment overrides) and avoid generic-Cache false positives.

@see .claude/rules/cache-redis-rule.md — judgment criteria (SoT: pools, TTL, injection, locks, sessions, transport)
@see .claude/rules/message-rabbitmq-rule.md — paired transport rule (async work → RabbitMQ, never Redis)
@see <https://symfony.com/doc/current/cache.html> — Symfony Cache (official)

> **Note:** this project intentionally differs from some generic Redis advice — the "never call `\Redis`
> directly" rule targets **cache** code, but the **session store and the distributed lock stores
> deliberately use the raw `Redis` service** (not `app.cache_redis_provider`), and the **Redis Messenger
> transport is sync/in-process only** (all async work is routed to RabbitMQ by design). Do not flag these
> against general advice — judge only against the SoT rule.

## Review Procedure

Cross-check each section of the rule in order: general rules (interface choice · `#[Target]` pool
injection · explicit TTL · no direct `\Redis` calls) · Redis config · non-cache uses of Redis (session ·
lock · transport) · cache-pool conventions · injection patterns · TTL references. In particular, check
environment-aware TTLs (the `kernel.debug` branch) and that asynchronous messages are routed to RabbitMQ.

## Output Format

### Summary

| Category | Status (OK / WARN / FAIL) | Issue count |
| --- | --- | --- |
| General rules | | |
| Redis config | | |
| Non-cache uses of Redis | | |
| Cache-pool conventions | | |
| Injection patterns | | |
| TTL references | | |

### Critical Issues (must fix)

For each issue: **[Line N]** `[MUST]` description → recommended fix including a code snippet.

### Improvement Suggestions (recommended)

For each suggestion: **[Line N]** `[SHOULD]` description → recommended approach.

### Refactoring Suggestions

Mark structural changes (splitting a pool, introducing tags, applying environment-aware TTLs, etc.) as
`[CONSIDER]` and describe them with before/after code examples. Only `[MUST]` blocks a merge.
