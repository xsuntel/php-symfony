---
paths:
  - "app/src/**/*.php"
  - "app/config/packages/workflow.yaml"
---

# Workflow Rule

@see https://symfony.com/doc/current/workflow.html
@see .claude/docs/app-php-symfony-docs.md §15 — state diagram · guard listener · testing details

Symfony Workflow is a state machine that declaratively defines an entity's states (places) and its
allowed transitions. This project manages the automated-trading order status (`orders`) with this
component.

## State Transitions Only via `apply()`

- **Do not set** the entity's status property (`status`) directly — prohibited in Service, Controller, and Handler alike.
- Perform transitions only with `WorkflowInterface::apply($subject, 'transition')`.
- This ensures invalid transitions are blocked at runtime and that guard events and the audit trail behave consistently.

```php
// Prohibited — changing status directly
$order->setStatus(OrdersStatusEnum::Waiting);

// Recommended — transition through the Workflow
$this->ordersWorkflow->apply($order, 'submit');
```

## `apply()` Only Inside a `MessageCommandHandler`

- A state transition is a write operation, so perform it only inside a `MessageCommandHandler` (no direct calls from a Controller or Service).
- Rationale: the two handlers `App\MessageCommandHandler\...\App\Trading\Orders` (UPbit · KoreaInvestment) are the only `apply()` points.

## Inject with `#[Target('{workflow_name}')]`

- Inject the workflow service by name (`orders`) — specify it explicitly with `#[Target]` instead of relying on the argument-name convention.

```php
use Symfony\Component\DependencyInjection\Attribute\Target;
use Symfony\Component\Workflow\WorkflowInterface;

public function __construct(
    #[Target('orders')]
    private readonly WorkflowInterface $ordersWorkflow,
) {}
```

## Pre-check with `can()` Before a Transition (Idempotency)

- Before `apply()`, check whether the transition is possible with `can($subject, 'transition')`.
- Use it as an idempotency guard so a redelivered message (at-least-once) does not reprocess an already-transitioned order.

```php
// If the order was already submitted/transitioned, stop even on redelivery (idempotent)
if (!$this->ordersWorkflow->can($order, 'submit')) {
    return;
}
$this->ordersWorkflow->apply($order, 'submit');
$this->entityManager->flush();   // flush to the domain-scoped EM after the transition
```

## Configuration Conventions (`config/packages/workflow.yaml`)

- `type: state_machine` — holds only one place at a time (use `type: workflow` only when multiple places are needed).
- `marking_store: { type: method, property: status }` — reads and writes the BackedEnum `status` property via a method.
- `audit_trail.enabled: '%kernel.debug%'` — logs transitions only in dev.
- Specify `initial_marking` along with `places` and `transitions` — do not leave a state-change path with no transition.

## Guards (Blocking a Transition) via Guard Events

- Handle conditional transition blocking in the `workflow.orders.guard[.transition]` event with `GuardEvent::setBlocked()`, not in a Service `if/else`.
- Separate the side effects that accompany a transition (notifications, logs) into a `workflow.orders.entered[.place]` event listener — do not mix them into the handler body.

## Debugging

```bash
cd app && php bin/console workflow:dump orders --dump-format=mermaid   # output the state diagram
cd app && php bin/console debug:autowiring workflow                    # check injectable workflow services
```

## Out of Scope

- Do not introduce a Workflow for a state that a single simple boolean flag (e.g. `is_active`) can cover — use it only when there are 3 or more places and transition rules.
