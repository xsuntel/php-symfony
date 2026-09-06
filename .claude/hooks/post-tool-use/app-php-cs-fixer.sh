#!/bin/bash

set -euo pipefail
# ----------------------------------------------------------------------------------------------------------------------
# Hooks - PostToolUse - PHP-CS-Fixer
# ----------------------------------------------------------------------------------------------------------------------
# Registered in: .claude/settings.json → hooks.PostToolUse (matcher "Edit|Write").
# Contract: Claude Code pipes the hook payload as JSON on stdin; format the just-edited file when it falls
#           inside the fixer's own finder scope, using the project php-cs-fixer.
# Runs after php-lint.sh, which reports syntax errors — the fixer is a silent no-op on a file that does not
# parse, so the lint has to speak first.
# Strict mode is ON, but every step that can realistically fail is explicitly tolerated so the script
# always reaches `exit 0` — PostToolUse must stay non-blocking so a formatter hiccup never disturbs the
# Edit/Write result (exit 2 would surface an error to Claude, and any other non-zero exit shows a
# non-blocking error notice on the very next tool call).
# ----------------------------------------------------------------------------------------------------------------------

# CLAUDE_PROJECT_DIR is exported onto the hook process by Claude Code; fall back to resolving the repository
# root relative to this script (.claude/hooks/post-tool-use/ → three levels up). The guard matters under
# worktree isolation: without it this gate and twig-lint.sh would resolve to different trees.
PROJECT_PATH="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)}"

# jq parses the hook payload; skip silently if it is unavailable.
command -v jq >/dev/null 2>&1 || exit 0

# Edit exposes tool_input.file_path; Write's response uses tool_response.filePath.
# `|| true` is load-bearing under `set -e`: a payload jq can't parse would otherwise make the assignment
# fail and abort the hook non-zero. An empty FILE_PATH falls through the case below to a clean exit 0.
# jq's own stderr is left alone on purpose — it only reaches the debug log, where it is worth having.
FILE_PATH="$(jq -r '.tool_input.file_path // .tool_response.filePath // empty' || true)"

# The branches mirror .php-cs-fixer.dist.php, whose finder is `in(__DIR__)->exclude('var')` — every PHP file
# under app/ except the runtime tree. Narrowing further here would leave config/, public/ and migrations/
# formatted only by the full `fix ./src` sweep in the Stop hook, which does not reach them either.
case "${FILE_PATH}" in
  *app/src/*.php | *app/tests/*.php | *app/config/*.php | *app/public/*.php | *app/migrations/*.php)
    if [ -x "${PROJECT_PATH}/app/vendor/bin/php-cs-fixer" ]; then
      # stderr is deliberately NOT discarded — it is the only record of why a format attempt failed, and it
      # reaches the debug log rather than Claude. `|| true` keeps the hook non-blocking.
      (cd "${PROJECT_PATH}/app" && vendor/bin/php-cs-fixer fix "${FILE_PATH}" --quiet) || true
    fi
    ;;
esac

exit 0
