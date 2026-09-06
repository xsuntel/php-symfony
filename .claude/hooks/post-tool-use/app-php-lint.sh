#!/bin/bash

set -euo pipefail
# ----------------------------------------------------------------------------------------------------------------------
# Hooks - PostToolUse - PHP syntax lint
# ----------------------------------------------------------------------------------------------------------------------
# Registered in: .claude/settings.json → hooks.PostToolUse (matcher "Edit|Write"), ahead of php-cs-fixer.sh.
# Contract: Claude Code pipes the hook payload as JSON on stdin; run `php -l` on the just-edited PHP file.
# Ordering is load-bearing — php-cs-fixer is a no-op on a file that does not parse, so the syntax check has
# to report first.
# Exit 2 does NOT block anything here: PostToolUse cannot block because the tool already ran, so exit 2 only
# surfaces stderr to Claude, which is exactly the feedback path wanted for a broken edit.
# Everything else (non-PHP file, missing binary, unparseable payload, deleted file) degrades to exit 0.
# ----------------------------------------------------------------------------------------------------------------------

# jq parses the hook payload, php performs the lint; skip silently if either is unavailable.
command -v jq >/dev/null 2>&1 || exit 0
command -v php >/dev/null 2>&1 || exit 0

# Edit exposes tool_input.file_path; Write's response uses tool_response.filePath.
# `|| true` is load-bearing under `set -e`: a payload jq can't parse would otherwise make the assignment
# fail and abort the hook non-zero. An empty FILE_PATH falls through the case below to a clean exit 0.
FILE_PATH="$(jq -r '.tool_input.file_path // .tool_response.filePath // empty' || true)"

case "${FILE_PATH}" in
  *.php) ;;
  *) exit 0 ;;
esac

# A path that no longer exists means the edit was undone or the file was moved — nothing to lint.
[ -f "${FILE_PATH}" ] || exit 0

# `php -l` writes its diagnostic to stdout; it has to be moved to stderr because only stderr is shown to
# Claude on exit 2.
if ! LINT_OUTPUT="$(php -l "${FILE_PATH}" 2>&1)"; then
  {
    echo "[ FAIL ] PHP syntax error — fix this file before continuing:"
    echo "${LINT_OUTPUT}"
  } >&2
  exit 2
fi

exit 0
