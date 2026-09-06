#!/bin/bash

set -euo pipefail
# ----------------------------------------------------------------------------------------------------------------------
# Hooks - PostToolUse - Twig lint
# ----------------------------------------------------------------------------------------------------------------------
# Registered in: .claude/settings.json → hooks.PostToolUse (matcher "Edit|Write").
# Contract: Claude Code pipes the hook payload as JSON on stdin; run `lint:twig` on the just-edited template.
# This is the same gate .claude/rules/app-twig-symfony-00-overview-rule.md declares as a merge requirement.
# Exit 2 does NOT block anything here — PostToolUse cannot block because the tool already ran — it only
# surfaces stderr to Claude so the broken template is fixed inside the same turn.
# `--show-deprecations` is deliberately NOT passed: Symfony promotes deprecations to lint errors, so a single
# pre-existing deprecation would fire on every unrelated template edit. The full sweep in
# stop/app-php-symfony-clear.sh carries that flag instead, where it reports once per turn.
# Every precondition degrades to exit 0 — an uninstalled vendor tree means "nothing to check", not an error.
# ----------------------------------------------------------------------------------------------------------------------

# CLAUDE_PROJECT_DIR is exported onto the hook process by Claude Code; fall back to resolving the repository
# root from this script's location (.claude/hooks/post-tool-use/ → three levels up).
PROJECT_PATH="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)}"

# jq parses the hook payload, php runs the console; skip silently if either is unavailable.
command -v jq >/dev/null 2>&1 || exit 0
command -v php >/dev/null 2>&1 || exit 0

# Edit exposes tool_input.file_path; Write's response uses tool_response.filePath.
# `|| true` is load-bearing under `set -e` — see php-lint.sh for the full rationale.
FILE_PATH="$(jq -r '.tool_input.file_path // .tool_response.filePath // empty' || true)"

case "${FILE_PATH}" in
  *.twig) ;;
  *) exit 0 ;;
esac

[ -f "${FILE_PATH}" ] || exit 0

# lint:twig boots the Symfony kernel, so both the console and an installed vendor tree are required.
[ -f "${PROJECT_PATH}/app/bin/console" ] || exit 0
[ -d "${PROJECT_PATH}/app/vendor" ] || exit 0

# APP_ENV is set explicitly rather than inherited — the hook process does not go through the dev shell.
if ! LINT_OUTPUT="$(cd "${PROJECT_PATH}/app" && APP_ENV=dev php bin/console lint:twig "${FILE_PATH}" 2>&1)"; then
  {
    echo "[ FAIL ] Twig lint error — fix this template before continuing:"
    echo "${LINT_OUTPUT}"
  } >&2
  exit 2
fi

exit 0
