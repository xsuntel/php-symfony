---
description: "Assesses the quality of Symfony Messenger / RabbitMQ usage code and provides structured improvement recommendations."
argument-hint: "[path to the file to analyze (a PHP file or messenger.yaml)]"
---

Analyze the following message-related file:

**`$ARGUMENTS`**

> **When the argument is empty**, review the single Messenger config file
> `app/config/packages/messenger.yaml` (the SoT for transport, bus, routing, and retry settings).
>
> When PHP-code judgment is needed (bus injection, DTO messages, handler idempotency, etc.), pass the
> target file as the argument — e.g. `app/src/MessageCommand/**`, `app/src/MessageCommandHandler/**`,
> `app/src/Messenger/**`. Do not blindly scan files outside the rule's `paths` or guess a target.

The single source of truth (SoT) for the judgment criteria is the rule file. At the start, read the rule
below, cross-check each provision against the target code, flag violations with the **exact line number**,
and provide concrete fixes (improved code snippets). Do not restate the criteria in this command.

Before flagging, read `app/config/packages/messenger.yaml` first (together with the paired Redis
transport rule) to establish the project's transport topology and avoid generic-Messenger false positives.

@see .claude/rules/message-rabbitmq-rule.md — judgment criteria (SoT: bus, transport, routing, retry, failure, worker)
@see .claude/rules/cache-redis-rule.md — paired transport rule (Redis = sync/in-process only)
@see <https://symfony.com/doc/current/messenger.html> — Symfony Messenger (official)

> **Note:** this project intentionally splits transports — RabbitMQ (AMQP) is the primary async transport
> and the **Redis transport is sync/in-process only** (routing heavy async work off Redis is by design,
> not a misconfiguration), and the **default PHP serializer** is used for internal messages (switch to
> JSON only for external/non-Symfony producers). Do not flag these against general advice — judge only
> against the SoT rule.

## Review Procedure

Cross-check each section of the rule in order: general rules (bus injection, DTO messages, namespaces,
`#[AsMessageHandler]`, secrets) · transport config (async RabbitMQ / sync Redis / failed Doctrine ·
naming conventions) · bus & middleware (command/query/event · `doctrine_transaction`) · retry & failure
handling · routing references · worker operation. In particular, check the **queue-name ↔ own-domain
match**, **async work routed to RabbitMQ**, **handler idempotency**, and any **reference to a
non-existent transport name**.

## Output Format

### Summary

| Category | Status (OK / WARN / FAIL) | Issue count |
| --- | --- | --- |
| General rules | | |
| Transport config | | |
| Bus & middleware | | |
| Retry & failure handling | | |
| Routing references | | |
| Worker operation | | |

### Critical Issues (must fix)

For each issue: **[Line N]** `[MUST]` description → recommended fix including a code snippet.

### Improvement Suggestions (recommended)

For each suggestion: **[Line N]** `[SHOULD]` description → recommended approach.

### Refactoring Suggestions

Mark structural changes (bus separation, transport renaming, introducing an idempotency key, adjusting
the retry strategy, etc.) as `[CONSIDER]` and describe them with before/after code examples. Only `[MUST]`
blocks a merge.
