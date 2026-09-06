# TODO

Track outstanding work for the symfony-scripts repository.

## Backlog

- [ ] Author the finance-provider quartet (`rule` + `docs` + `skill` + author/reviewer agents) for
      UPbit (REST · WebSocket) and KoreaInvestment (OAuth2 · REST · WebSocket), plus Agencies (ECOS ·
      KOSIS) REST. Blocked on `app/src/` gaining provider code. Until then the routing table in
      `.claude/agents/app-agent-team.md` is marked planned, and `.claude/rules/abstract-structure-rule.md`
      carries no provider rule rows.
- [ ] Fill the two empty doc stubs: `.claude/docs/utility-claude-code-docs.md` and
      `.claude/docs/utility-git-commit-docs.md` (both 0 bytes).
- [ ] Decide whether to add a browser/JS test runner (Vitest or Playwright). Without one, the TDD cycle
      in `.claude/rules/app-php-symfony-09-testing-rule.md` has no executable Red for Stimulus runtime
      behaviour — click handlers, `connect()`/`disconnect()`, and dispatched events are permanently
      uncovered, and `app-javascript-stimulus-tester` can only pin the server-rendered DOM contract.
      Blocked on a decision, not on code: it adds a devDependency, a config, and a CI stage.
- [ ] Decide whether `app/tests` and `app/migrations` should stay in `.gitignore` — the testing rule
      (`09-testing-rule.md`), three tester agents, and the `Edit(app/tests/**)` permission all assume
      those trees are tracked.

## In Progress

- [ ] _(add items)_

## Done

- [x] _(move completed items here)_

## Notes

- Use Conventional Commit prefixes (`feat:` / `fix:` / `chore:`) when an item lands as a commit.
