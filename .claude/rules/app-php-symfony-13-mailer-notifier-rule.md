---
paths:
  - "app/src/**/*.php"
  - "app/config/packages/mailer.yaml"
  - "app/config/packages/notifier.yaml"
---

# Mailer & Notifier Rule

@see https://symfony.com/doc/current/mailer.html
@see https://symfony.com/doc/current/notifier.html
@see .claude/docs/app-php-symfony-docs.md §16 — TemplatedEmail · async sending · custom Notification · Webhook details

Send email with **Mailer**, and multi-channel (email/chat/sms) notifications with **Notifier**.
System notifications sent to operators go through the Notifier's `admin_recipients`.

## Mailer — `TemplatedEmail` + Twig Body

- Compose the body with a **`TemplatedEmail` + Twig template** (`htmlTemplate` + `context`), not string concatenation.
- Wrap recipient/sender addresses in `Symfony\Component\Mime\Address` — do not pass raw strings directly.
- URLs inside an email template need an absolute path, so use **`url()`** rather than `path()`.

```php
use Symfony\Bridge\Twig\Mime\TemplatedEmail;
use Symfony\Component\Mailer\MailerInterface;
use Symfony\Component\Mime\Address;

$email = (new TemplatedEmail())
    ->to(new Address($user->getEmail()))
    ->subject('Welcome')
    ->htmlTemplate('controller/tools/email/base/_welcome.html.twig')
    ->context(['user' => $user]);

$this->mailer->send($email);
```

- Do not hardcode the From/Envelope sender in code — manage it in `mailer.yaml` (`MAILER_DSN` · `envelope.sender`).
- Keep the sending logic in a dedicated Service (e.g. `WelcomeVerifier`), not in a controller — the controller only calls it.

## Notifier — Admin Notifications via `admin_recipients`

- Do not hardcode recipients for a system-wide (user-independent) notification — calling **`send()` with no recipient**
  delivers to the entire `admin_recipients` list in `notifier.yaml`.
- The per-severity channels are owned by the `channel_policy` (urgent/high/medium/low) in `notifier.yaml` (SoT) — do not branch on channels arbitrarily in code.

```php
use Symfony\Component\Notifier\Notification\Notification;
use Symfony\Component\Notifier\NotifierInterface;

$notification = (new Notification('KoreaInvestment OAuth2 authentication failed', ['email']))
    ->content('Check the validity of appkey/appsecret and whether the key needs rotation.');

// No recipient specified → delivered to all admin_recipients
$this->notifier->send($notification);
```

- Specify a recipient with `->send($notification, new Recipient($email))` only when sending to a specific user.
- When you need per-channel custom rendering (Slack blocks, email template), extend `Notification` and implement
  `ChatNotificationInterface` · `EmailNotificationInterface` (details in docs §16).

## Delegating Sending Asynchronously (Optional)

- Process bulk / delay-tolerant sending asynchronously with Messenger — route `SendEmailMessage` · `ChatMessage` · `SmsMessage`
  to the domain async transport. The transport / retry / failure-handling criteria are owned by
  `.claude/rules/message-rabbitmq-rule.md` (SoT) (not restated here).
- Sending is synchronous if no routing is specified — review routing on paths sensitive to request-response latency.

## Webhook (Inbound Events)

- Receive provider callbacks such as delivery failures, bounces, and delivery receipts with `symfony/webhook` + `RequestParserInterface`
  and normalize them into a `RemoteEvent` — do not parse the raw payload directly in a controller.
- Signature verification is mandatory (provider secret) — reject a payload that fails verification instead of processing it.

## Sensitive Data

- Do not put passwords, tokens, or API keys in the email body, notification context, or logs (consistent with `app-php-symfony-08-security-rule.md`).
- An authentication-failure notification carries only identifiable context (source · environment · status_code) and excludes credential values.

## Debugging

```bash
cd app && php bin/console debug:messenger              # message→handler mapping
cd app && php bin/console debug:config framework mailer
cd app && php bin/console debug:config framework notifier
```
