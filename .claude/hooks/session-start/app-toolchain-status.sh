#!/bin/bash

#set -euo pipefail
# ----------------------------------------------------------------------------------------------------------------------
# Hooks - SessionStart - Toolchain status
# ----------------------------------------------------------------------------------------------------------------------
# Registered in: .claude/settings.json → hooks.SessionStart (no matcher — fires on
#                startup / resume / clear / compact / fork).
# Contract: SessionStart stdout is injected into Claude's context, so report anything missing that silently
#           disables a quality gate. Without this, php-cs-fixer / lint:twig / PHPStan hooks degrade to no-ops
#           and Claude has no way of knowing the gates are not actually running.
# Prints nothing when the toolchain is complete — an empty report must not add noise to every session.
# Strict mode is intentionally OFF, matching node.sh: the whole point is tolerating absent state.
# ----------------------------------------------------------------------------------------------------------------------

# CLAUDE_PROJECT_DIR is exported onto the hook process by Claude Code; fall back to resolving the repository
# root from this script's location (.claude/hooks/session-start/ → three levels up).
PROJECT_PATH="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)}"

MISSING=""

note_missing() {
  MISSING="${MISSING}- $1"$'\n'
}

[ -d "${PROJECT_PATH}/app/vendor" ] \
  || note_missing 'app/vendor is not installed — php-cs-fixer, PHPStan and lint:twig gates are all inert. Run: cd app && composer install'

[ -d "${PROJECT_PATH}/app/assets/vendor" ] \
  || note_missing 'app/assets/vendor is not installed — importmap assets are missing. Run: cd app && php bin/console importmap:install'

command -v jq >/dev/null 2>&1 \
  || note_missing 'jq is not on PATH — every hook that parses the stdin payload exits early and does nothing.'

if [ -n "${MISSING}" ]; then
  echo "Hook toolchain status — the following are missing, so their quality gates are not running:"
  printf '%s' "${MISSING}"
fi

exit 0
