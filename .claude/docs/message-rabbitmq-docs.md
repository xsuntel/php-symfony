# RabbitMQ / Symfony Messenger — Technical Reference

This document holds the **detailed reference and configuration examples** for RabbitMQ usage in this
project (async transports, routing, retry/DLQ, worker operation). The enforced judgment criteria (SoT)
live in the rule file — if this document conflicts with the rule, the rule wins.

@see .claude/rules/message-rabbitmq-rule.md — RabbitMQ/Messenger judgment criteria (SoT)
@see .claude/docs/cache-redis-docs.md — the paired transport reference (Redis = sync only)
@see https://symfony.com/doc/current/messenger.html — Symfony Messenger (official)
@see https://symfony.com/doc/current/messenger.html#transport-configuration — AMQP transport (official)

---

## 1. Basic Async Message Flow

A message is an immutable, serializable DTO; a dedicated handler processes it off-request:

```php
// app/src/MessageCommand/RefreshCompanyReportCommand.php
namespace App\MessageCommand;

final readonly class RefreshCompanyReportCommand
{
    public function __construct(
        public int $companyId,
    ) {}
}
```

```php
// app/src/MessageCommandHandler/RefreshCompanyReportHandler.php
namespace App\MessageCommandHandler;

use App\MessageCommand\RefreshCompanyReportCommand;
use App\Repository\CompanyRepository;
use Symfony\Component\Messenger\Attribute\AsMessageHandler;

#[AsMessageHandler]
final readonly class RefreshCompanyReportHandler
{
    public function __construct(
        private CompanyRepository $repository,
    ) {}

    public function __invoke(RefreshCompanyReportCommand $message): void
    {
        // Re-fetch the entity by id — never carry a Doctrine entity in the payload.
        $company = $this->repository->find($message->companyId);
        // ... idempotent side effect ...
    }
}
```

Dispatch through the bus (never call the handler directly):

```php
use Symfony\Component\Messenger\MessageBusInterface;

public function __construct(
    private readonly MessageBusInterface $bus,
) {}

public function refresh(int $companyId): void
{
    $this->bus->dispatch(new RefreshCompanyReportCommand($companyId));
}
```

---

## 2. Transport Configuration

@see https://symfony.com/doc/current/messenger.html#transport-configuration

### Environment Variables

Defined in `app/.env` (template) and overridden in `.env.app` / `.env.local` (never commit credential
values). The AMQP DSN mirrors the Redis transport's `MESSENGER_TRANSPORT_DSN_REDIS` naming:

```dotenv
# amqp://user:pass@host:5672/%2f/messages  — AMQP protocol port (5672), NOT the management port (15672)
MESSENGER_TRANSPORT_DSN_AMQP="amqp://guest:guest@127.0.0.1:5672/%2f/messages"
```

### Transports (`app/config/packages/messenger.yaml`)

Async transports are named `async_*` (parallel to the Redis `sync_*` transports), declare exchange /
queues / retry explicitly, and share one `failed` failure transport:

```yaml
framework:
  messenger:
    failure_transport: failed

    transports:
      async:
        dsn: '%env(MESSENGER_TRANSPORT_DSN_AMQP)%'
        options:
          exchange:
            name: messages
            type: direct
          queues:
            messages: ~
        retry_strategy:
          max_retries: 3
          delay: 1000          # 1s
          multiplier: 2        # 1s, 2s, 4s
          max_delay: 10000     # cap at 10s

      # Provider-scoped async transport (mirrors the cache-pool / Redis sync_providers_* naming)
      async_providers_finance_app_securities_koreainvestment:
        dsn: '%env(MESSENGER_TRANSPORT_DSN_AMQP)%'
        options:
          exchange: { name: providers_finance, type: direct }
          queues:  { providers_finance_koreainvestment: ~ }
        retry_strategy: { max_retries: 3, delay: 1000, multiplier: 2, max_delay: 10000 }

      # Dead-letter / failure transport — durable, inspected manually, never auto-looped
      failed:
        dsn: '%env(MESSENGER_TRANSPORT_DSN_AMQP)%'
        options:
          exchange: { name: failed, type: direct }
          queues:  { failed: ~ }
```

- Do **not** rely on Messenger auto-setup in production — run `messenger:setup-transports` at deploy time.
- Reserve the Redis transport (`sync_*`, DSN `MESSENGER_TRANSPORT_DSN_REDIS`) for synchronous work only.

---

## 3. Routing

@see https://symfony.com/doc/current/messenger.html#routing-messages-to-a-transport

Every message class is routed explicitly — an unrouted message runs synchronously and silently:

```yaml
framework:
  messenger:
    routing:
      'App\MessageCommand\RefreshCompanyReportCommand': async
      'App\MessageCommand\Providers\Finance\KoreaInvestment\FetchDomesticQuoteCommand':
        async_providers_finance_app_securities_koreainvestment
```

Naming pattern (parallel to the cache/Redis conventions):

| Message namespace | Transport |
|---|---|
| Core domain command/event | `async` |
| Provider integration | `async_providers_{provider_path}` |

---

## 4. Retry, Failure Transport & DLQ

@see https://symfony.com/doc/current/messenger.html#retries-failures

The `retry_strategy` bounds automatic retries with exponential backoff; exhausted messages land in the
`failed` transport, which is treated as a dead-letter queue.

```php
// Permanent failure — skip retries, go straight to the failure transport:
use Symfony\Component\Messenger\Exception\UnrecoverableMessageHandlingException;

if (!$company) {
    throw new UnrecoverableMessageHandlingException(
        sprintf('Company %d no longer exists — dropping message.', $message->companyId),
    );
}
```

DLQ operations (manual, never auto-looped):

```bash
cd app
php bin/console messenger:failed:show            # list dead-lettered messages
php bin/console messenger:failed:show <id> -vv   # inspect one (payload + exception)
php bin/console messenger:failed:retry <id>      # replay after fixing the cause
php bin/console messenger:failed:remove <id>     # drop a poison message explicitly
```

---

## 5. Handler Idempotency & Locks

A redelivered message must not double-apply side effects. Guard non-idempotent work with the per-domain
distributed lock (see the Redis rule), keyed on a **stable business identifier**:

```php
use Symfony\Component\DependencyInjection\Attribute\Target;
use Symfony\Component\Lock\LockFactory;

public function __construct(
    #[Target('company.lock')]
    private readonly LockFactory $lockFactory,
) {}

public function __invoke(RefreshCompanyReportCommand $message): void
{
    $lock = $this->lockFactory->createLock('report_company_'.$message->companyId, ttl: 30);
    if (!$lock->acquire()) {
        return; // another worker owns this business key — safe to drop the duplicate
    }
    try {
        // ... transactional, idempotent side effect ...
    } finally {
        $lock->release();
    }
}
```

---

## 6. Worker Operation

@see https://symfony.com/doc/current/messenger.html#deploying-to-production

Workers are bounded and managed by supervisor/systemd — not left to grow:

```bash
# One command per transport; both limits bounded so the process manager recycles the worker.
php bin/console messenger:consume async \
    --time-limit=3600 --memory-limit=128M -vv
```

Deploy sequence (graceful, no killing mid-message):

```bash
php bin/console cache:clear
php bin/console cache:warmup
php bin/console messenger:setup-transports
php bin/console messenger:stop-workers   # running workers finish the current message, then exit
# supervisor/systemd restarts them on the new code
```

Never run `messenger:consume` with `APP_DEBUG=true` in production — the profiler collector leaks memory
across consumed messages.

---

## 7. Verification & Inspection

```bash
cd app
php bin/console debug:messenger      # list buses, message → handler mappings
php bin/console messenger:stats      # queued message count per transport
php bin/console messenger:consume async -vv --limit=1   # process one message with full trace
```
