---
description: "Assesses the quality of a JavaScript file and provides structured improvement recommendations."
argument-hint: "[path to the JavaScript file to analyze]"
---

Analyze the following JavaScript file:

**`$ARGUMENTS`**

> **When the argument is empty**, review the frontend wiring files as one set (the SoT for the
> AssetMapper dependency ↔ Stimulus controller registration pairing):
>
> - `app/assets/app.js`
> - `app/assets/stimulus_bootstrap.js`
> - `app/assets/controllers.json`
> - `app/importmap.php`
>
> To judge an individual Stimulus controller, pass the target file as an argument instead
> (e.g. `app/assets/controllers/**`). Do not blindly scan `app/assets/**` outside the list above or the
> argument you were given, and do not guess a target.
>
> **Verify before reading:** the Symfony app is not scaffolded yet (`app/` holds only `.gitkeep`), so
> treat the paths above as the target layout and report which are missing rather than assuming they exist.

The single source of truth (SoT) for the judgment criteria is the rule files and the output-style. At
the start, read the following, cross-check each provision against the target code, flag violations with
the **exact line number**, and provide concrete fixes (improved code snippets). Do not restate the
criteria in this command.

@see .claude/rules/app-javascript-stimulus-00-overview-rule.md ~ app-javascript-stimulus-02-quality-rule.md — judgment criteria (SoT)
@see .claude/output-styles/app-javascript-stimulus-style.md — code style (semicolons, quotes, indentation)
@see .claude/rules/app-php-symfony-10-frontend-rule.md — AssetMapper/importmap

## Review Procedure

Cross-check each item of the rules/style: module system & imports (00), variable declarations & naming
(00), modern syntax, functions & async, class design, Stimulus controller conventions (01: targets/values/outlets/lifecycle),
error handling, security (XSS, CSRF, secrets), performance & memory (listener leaks), code quality (02).
When a controller changes, also check that the `data-*` contract matches in the corresponding Twig.

## Output Format

### Summary

| Category | Status (OK / WARN / FAIL) | Issue count |
| --- | --- | --- |
| Module system & imports | | |
| Variable declarations | | |
| Modern syntax (ES2020-2022) | | |
| Functions & async | | |
| Class design | | |
| Stimulus conventions | | |
| Error handling | | |
| Security | | |
| Performance & memory | | |
| Code quality | | |

### Critical Issues (must fix)

For each issue: **[Line N]** description → recommended fix including a code snippet.

### Improvement Suggestions (recommended)

For each suggestion: **[Line N]** description → recommended approach.

### Refactoring Suggestions

Describe structural changes (controller separation, utility extraction, async refactoring, etc.) with before/after code examples.
