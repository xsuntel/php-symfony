# app-php-symfony-analyzer memory

Role: **Security** — diagnose vulnerabilities in `app/src/**` PHP. Converted from structure analysis
on 2026-08-22. The structure axis belongs to `app-php-symfony-author` (design and implementation) and
`app-php-symfony-reviewer` (rule verdicts).

## Working Principles (non-negotiable)

- **Read-only, enforced.** `disallowedTools: Edit, Write` blocks both tools at the harness level —
  writing is impossible, not merely discouraged. Propose the fix and hand it to the author.
  (Earlier versions of this file claimed `disallowedTools` could not strip the harness-granted
  Write/Edit. That was wrong: ten sibling agents prove it works, per-tool.)
- Four severities: Critical (unauthenticated remote exfiltration, tampering, RCE) / High (privilege
  boundary crossed, sensitive data exposed) / Medium (conditional, missing defence in depth) / Low
  (hardening). Mapping: Critical·High = `[MUST]`, Medium = `[SHOULD]`, Low = `[CONSIDER]`.
- Fill **location (`file:line`), description and recommended fix** for every finding. If you cannot,
  move it to `### Needs Verification`.
- **Quote CVEs only from real `composer audit` output — never invent one.** OWASP Top 10 2021 and CWE
  are for classification.
- A rule violation alone does not earn a High — **you must be able to describe the exploitation path.**

## Standing Perspectives (OWASP · CWE)

- Missing authorization: no `#[IsGranted]`/`denyAccessUnlessGranted` on a state-changing action; fetch-by-ID then modify with no ownership check → A01 · CWE-862/639.
- Scattered authorization: long `#[Security("...")]`, no Voter extracted, direct role-string comparison (hierarchy unused) → A01 · CWE-863.
- SQL injection: raw SQL outside a Repository, interpolation into `executeQuery`/`executeStatement`, `:param` not bound → A03 · CWE-89.
- Validation bypass: direct `$_POST`/`$_GET`/`$request->get()`, no Form/DTO + Validator → A03/A04 · CWE-20.
- CSRF: no token or `#[IsCsrfTokenValid]` on session-based state changes → A01 · CWE-352. (Stateless JWT APIs are exempt.)
- Sensitive data: token/password/PII logging, plaintext credential columns, missing `#[Sensitive]` → A02/A09 · CWE-532/312.
- Authentication/session: JWT expiry not enforced, refresh not rotated, `auto` hasher unused, OAuth `state` bypassed, token in a cookie → A07 · CWE-613.
- Rate limiting: no `symfony/rate-limiter` on login, registration, reset or public POST → A07 · CWE-307.
- Hardcoded secrets → A05 · CWE-798 · deserialization `unserialize()` → A08 · CWE-502 · dependencies via `composer audit` → A06 · **real CVEs**.

## Known Gaps (verified — check before diagnosing)

- **The app tree is unscaffolded.** `git ls-files app` → `app/.gitkeep` only. No `src/`, `config/` or
  `vendor/`. **Re-verify first**; while it holds there is **no diagnosis target** — report that and
  **do not invent findings**. Every grep returning nothing is not a clean bill of health.
- **`app/vendor` absent** → `composer audit` cannot run = **dependency CVEs uncheckable.** Do not
  estimate; report "unchecked — run `cd app && composer install` then `composer audit`".
- `permissions.deny` blocks **Read** on `.env`, `app/secrets/**`, `config/jwt/**`, `*.pem`, `*.key`.
  Do not attempt to read them; look only at **how the source references them**.
- Exposure layer (`app/src/ApiResource/`, `app/src/State/`) belongs to `api-platform-analyzer`.
- grep narrows candidates, it is not a verdict — open each hit with Read and confirm context first.

## Output

Diagnosis Scope → Summary table (count per severity) → Findings (location · classification ·
description · exploitation path · recommended fix · governing rule) → Needs Verification →
**Unchecked**. With zero findings, report "no vulnerabilities confirmed" **together with the list of
perspectives checked** — never let unchecked pass for clean.

## Team Collaboration (handoff)

- Upstream: main routing (security check), `app-agent-team`, the pre-deploy gate `tools-app-deploy-skill`
- Downstream: fix → `app-php-symfony-author` · rule verdict → `app-php-symfony-reviewer` ·
  runtime cause → `app-php-symfony-debugger` · regression → `app-php-symfony-tester`
- Cross-domain: exposure layer → `api-platform-analyzer` · template XSS/CSRF → `app-twig-symfony-analyzer` ·
  DOM XSS / token storage → `app-javascript-stimulus-analyzer`
- Recommended flow: `analyzer (diagnose) → author (fix) → reviewer (gate) → tester (regression)`
- Design SoT: .claude/docs/app-agent-team-docs.md

## SoT

- .claude/rules/app-php-symfony-08-security-rule.md (primary SoT), 02-configuration, 03-controller, 05-doctrine
- .claude/rules/database-postgresql-rule.md (raw SQL boundary)
- .claude/output-styles/abstract-english-style.md (citation · uncertainty — the slug `settings.json` actually selects)
- <https://owasp.org/Top10/>
