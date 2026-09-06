# The analyzer axis — security-diagnosis agent definition guide

> This document is **a template, not judgment criteria.** Frontmatter, naming and tool-minimality
> verdicts are SoT in `commands/utility-claude-code-review.md`; structure and placement in
> `rules/utility-claude-code-rule.md`. The values below are **measured 2026-09-06**, and when writing a
> new agent you should **read one or two existing files of the same kind first**.

Supplementary reference for `SKILL.md` Phase 3. The analyzer axis **diagnoses security vulnerabilities
and proposes fixes only** — it does not fix code.

**Existing instances:** `app-php-symfony-analyzer` · `app-twig-symfony-analyzer` ·
`app-javascript-stimulus-analyzer` · `api-platform-analyzer` (4, code domains only).

---

## 1. This axis used to be something else

**On 2026-08-22 it was converted from static structural analysis to security vulnerability diagnosis.**
The grounds were a recorded gap:

> *"this repository has no dedicated security audit agent"* — the security criteria
> (`app-php-symfony-08-security-rule.md` and others) **were already in place, and only an executor to
> check code against them was missing.**

**Design lesson:** criteria existing without an executor is a normal intermediate state, and when that
gap surfaces, **converting a low-value existing axis is an option instead of creating a new one**. In
the same revision the "refactoring design" handoff, left homeless when the structural axis disappeared,
converged onto the author.

---

## 2. Frontmatter

```yaml
---
name: {domain}-analyzer
description: '{domain} security diagnosis — reads {target paths} and identifies security vulnerabilities. Detects {list 3–5 vulnerability classes} and reports each with a Critical/High/Medium/Low severity, an OWASP·CWE classification and a recommended fix. Activate on requests like ''security check'', ''find vulnerabilities''. Read-only — it never fixes code itself.'
model: opus
memory: project
isolation: worktree
maxTurns: 30
tools: Read, Grep, Glob, Bash
disallowedTools: Edit, Write
---
```

| Key | Value | Rationale |
| --- | --- | --- |
| `maxTurns` | `30` | identical across all 4 |
| `model` | `opus` | reasoning about an exploitation path is open-ended work |
| `tools` | `Read, Grep, Glob, Bash` — **no write** | the diagnosis is the deliverable. `Bash` is for investigation (`composer audit` and similar) |
| `disallowedTools` | `Edit, Write` | **this line is the enforcement** — see §3 |
| `isolation` | `worktree` | all 4 are scoped to `app/**` sources. The convention follows domain scope, not write access, so a read-only agent being isolated is **not** an inconsistency |
| `color` | **omit it** | only `tools-agent-team` sets a colour. There is no per-axis palette — do not invent one |
| `permissionMode` | **omit it** | no analyzer declares one. `disallowedTools` already enforces read-only |

**If you put a `#[...]` attribute in the `description`, it must be wrapped in single quotes** — in an
unquoted scalar `space + #` starts a comment, so **everything from that point is silently truncated.**

---

## 3. Read-only is harness-enforced here

`memory: project` makes the harness auto-grant `Write` and `Edit` regardless of the `tools` list — but
**`disallowedTools` reverses that grant per tool.** So on these four agents an `Edit` or `Write` call
**fails outright**; read-only is enforced by the harness, not by prose.

Two practical consequences:

1. **Never assign an analyzer a tmp output path.** It cannot write, so the spawn fails at its last step.
   Ask for the findings **in the returned report**.
2. **The `disallowedTools` line is load-bearing.** Omit it on a new read-only agent and the auto-grant
   stands, leaving read-only as body text only. State the norm in the body as well, but do not rely on
   it alone.

> **Do not copy `permissionMode` in from elsewhere.** `[Verified]` 2026-09-06 — no analyzer declares it,
> and no agent in the repository declares `permissionMode: plan`. Only the 14 write-path agents
> (`*-author`, `*-tester`, `*-debugger`) declare `acceptEdits`, and they do so to escape the session's
> read-only `plan` mode — which is the opposite need.

---

## 4. Canonical skeleton (identical across all 4 domains)

```markdown
## Role
## Working Principles (strictly applied)
## Criteria (single source: the rules)
## Severity Criteria
## Vulnerability Analysis Perspectives
## Investigation Commands
## Known Gaps (check before diagnosing)
## Output Format
## Role Boundaries (handoff)
## Rule Files and Helper Skill References
```

`## Role` **cuts away what is out of scope first** — state that structural health (layer boundaries,
complexity, refactoring opportunities) belongs to the author (design and implementation) and the
reviewer (rule-compliance verdict), not to this axis.

---

## 5. The six working principles (wording is shared across all 4)

1. **Operate read-only** (§3 above).
2. **Classify every vulnerability by severity** — Critical / High / Medium / Low.
3. **Produce all three of location, description and recommended fix.** If any one cannot be filled, do
   not report it — **separate it into a "needs verification" item**. Locate with `file:line`.
4. **Reference CVE and OWASP criteria** — classify by OWASP Top 10 2021 category and CWE number.
   **Cite only CVE numbers that `composer audit` actually printed** — never invent one. If the tool
   could not be run, write "dependency vulnerabilities unchecked".
5. **Use sources only** — assert only facts confirmed in project files. When something cannot be
   confirmed, state "this information was not confirmed in the project files".
6. **Do not speculate** — do not invent service IDs, routes, role names or column names that were not
   confirmed. Distinguish code that **looks** vulnerable from code that is genuinely **exploitable**,
   and if you cannot describe the exploitation path, lower the severity or mark it `[Uncertain]`.

---

## 6. Severity — a rule violation is not automatically High

| Severity | Definition | Repository mapping |
| --- | --- | --- |
| **Critical** | an unauthenticated remote attacker can exfiltrate, tamper with data, or execute code | `[MUST]` — blocks a merge |
| **High** | an authenticated user can cross a privilege boundary to access or tamper, or sensitive data is directly exposed | `[MUST]` — blocks a merge |
| **Medium** | conditionally exploitable (needs a specific configuration or user interaction), or missing defence in depth | `[SHOULD]` |
| **Low** | minimal information disclosure, or a hardening recommendation | `[CONSIDER]` |

**Severity is exploitability × impact.** Do not assign High on the strength of a rule violation alone —
**High or above requires being able to describe the exploitation path.**

This mapping is what lets the orchestrator **merge and sort against the other axes'
`[MUST]`/`[SHOULD]`** on one scale. Omit the table from a new analyzer and severities get mixed at
consolidation.

---

## 7. Per-domain vulnerability perspectives

`## Vulnerability Analysis Perspectives` is the only section that differs by domain.

| Domain | Principal detection targets |
| --- | --- |
| PHP backend | authentication/authorization defects (missing Voter or `#[IsGranted]`, `access_control` bypass) · SQL injection · validation-bypassing input · token and PII logging · plaintext credentials · vulnerable dependencies |
| Twig | `\|raw` or `autoescape false` applied to user/DB input · missing `\|e('js')` or `\|e('html_attr')` · missing CSRF token · mistaking `is_granted` for server-side authorization |
| JS/Stimulus | DOM XSS (`innerHTML` assignment, `eval`, `new Function`) · credentials in web storage · missing CSRF token · unvalidated `postMessage` or SSE origin · vulnerable importmap dependencies |
| API Platform | missing operation `security` · ownership transfer from confusing `security` with `securityPostDenormalize` · secrets or PII in a read group · mass assignment (over-broad write groups) · missing rate limiting · internal information leaked in error responses |

---

## 8. Role boundaries (handoff)

```text
upstream: main routing · orchestrator · {domain}-reviewer (on spotting a suspected security issue)
  ↓
{domain}-analyzer  ← diagnoses and proposes only. It does not fix
  ↓
downstream: {domain}-author (implements the fix) → {domain}-reviewer (judges the fix)
            {domain}-tester when regression prevention is needed
```

---

## 9. Checklist for creating a new analyzer

- [ ] **Do the security criteria (rules) already exist?** If not, create the rule first — diagnosis
      without criteria is improvised judgment
- [ ] Is the severity ↔ `[MUST]`/`[SHOULD]`/`[CONSIDER]` mapping table present?
- [ ] Are `Write` and `Edit` **absent from `tools`**, and is `disallowedTools: Edit, Write` **present**?
      The second half is what actually enforces it
- [ ] Does the body state the read-only norm as well, so the model has the reason and not just the block?
- [ ] Is `permissionMode` **absent**? No analyzer declares one
- [ ] Is `color` **absent**? There is no per-axis palette
- [ ] Does `isolation` match the domain scope — `worktree` for an `app/**`-scoped agent?
- [ ] Is the `description` wrapped in single quotes (mandatory when it contains `#[...]`)?
- [ ] Do the referenced OWASP and CWE URLs exist?
