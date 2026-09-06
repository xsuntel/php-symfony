---
paths:
  - "app/src/Scheduler/**/*.php"
---

# Scheduler Rule

@see https://symfony.com/doc/current/scheduler.html
@see .claude/docs/app-php-symfony-docs.md §18 — ScheduleProvider · RecurringMessage · custom Trigger details

Define recurring tasks with Symfony Scheduler. Instead of an attribute task (`#[AsCronTask]`), this project
composes schedules as **`ScheduleProviderInterface` + `#[AsSchedule]`** classes and delegates execution to Messenger.

## Schedule Definition — `ScheduleProviderInterface` + `#[AsSchedule]`

- Place schedules under `src/Scheduler/{Domain}/...` as a class that implements `ScheduleProviderInterface` (mirroring the domain tree).
- Annotate the class with `#[AsSchedule('{unique_name}')]` — the name is a snake_case domain path, like the route convention.
- Bind the trigger and the message together with a `RecurringMessage` in `getSchedule()`.

```php
use Symfony\Component\DependencyInjection\Attribute\Target;
use Symfony\Component\Scheduler\Attribute\AsSchedule;
use Symfony\Component\Scheduler\RecurringMessage;
use Symfony\Component\Scheduler\Schedule;
use Symfony\Component\Scheduler\ScheduleProviderInterface;
use Symfony\Contracts\Cache\CacheInterface;

#[AsSchedule('providers_property_app_vworld_api_adsigg')]
final class AdSigg implements ScheduleProviderInterface
{
    private Schedule $schedule;

    public function __construct(
        #[Target('cache_pool_providers_property_app_agencies_vworld')]
        private readonly CacheInterface $cache,
    ) {}

    public function getSchedule(): Schedule
    {
        return $this->schedule ??= (new Schedule())
            ->with(
                RecurringMessage::cron('@daily', new MessageCommandAdSigg(self::ADSIGG_ID)),
            )
            ->stateful($this->cache)          // recover missed runs after a worker restart
            ->processOnlyLastMissedRun(true); // run only the last of accumulated missed runs
    }
}
```

## A Task Only Dispatches a `MessageCommand`

- What a `RecurringMessage` carries is a **`MessageCommand`** — do not call a Service or Repository directly from the schedule class.
- The actual work is performed by the corresponding `MessageCommandHandler` (keeping the CQRS boundary, consistent with `08` and overview).

## The Schedule Says "When"; the Execution Guard Is the Handler

- The schedule class describes only **when to trigger**. Put the domain guard for "may we run now?" in the `MessageCommandHandler`.
- However, a **calendar/timezone-based firing condition** (weekends · holidays · regular market hours, i.e. "when to trigger") can be
  expressed with a custom `TriggerInterface` wrapper — this is the shape of the schedule itself, not an execution guard.

```php
// TradingDayTrigger — wraps an inner trigger to skip non-trading days / off-market hours.
final class TradingDayTrigger implements \Stringable, TriggerInterface
{
    public function __construct(private readonly TriggerInterface $inner) {}

    public function getNextRunDate(\DateTimeImmutable $run): ?\DateTimeImmutable
    {
        // If it is a weekend/holiday or outside market hours, jump to the next trading day 09:00 and recompute
    }
}
```

## State Retention · Duplicate Prevention

- Use `->stateful($cache)` to recover missed runs across worker restarts (inject a dedicated cache pool).
- Default to `->processOnlyLastMissedRun(true)` so accumulated missed runs are not all run at once.

## Operations

```bash
cd app && php bin/console debug:scheduler                          # registered schedules · next run time
cd app && php bin/console messenger:consume scheduler_{name} -vv   # consume the schedule transport
```

- The schedule transport also needs retry / failure handling — the transport criteria are owned by `.claude/rules/message-rabbitmq-rule.md` (SoT).
