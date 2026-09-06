#!/bin/bash

set -euo pipefail
# ----------------------------------------------------------------------------------------------------------------------
# Hooks - PostToolUse - JavaScript quality guard
# ----------------------------------------------------------------------------------------------------------------------
# Registered in: .claude/settings.json → hooks.PostToolUse (matcher "Edit|Write").
# Contract: Claude Code pipes the hook payload as JSON on stdin; grep the just-edited asset for the banned
# patterns listed in .claude/rules/app-javascript-stimulus-02-quality-rule.md (security table + checklist).
# grep only — the project has no JS linter or formatter installed and deliberately takes on no new
# dependency, so this hook reports and never rewrites.
# Exit 2 does NOT block anything here — PostToolUse cannot block because the tool already ran — it only
# surfaces stderr to Claude so the violation is corrected inside the same turn.
# ----------------------------------------------------------------------------------------------------------------------

# jq parses the hook payload; skip silently if it is unavailable.
command -v jq >/dev/null 2>&1 || exit 0

# Edit exposes tool_input.file_path; Write's response uses tool_response.filePath.
# `|| true` is load-bearing under `set -e` — see php-lint.sh for the full rationale.
FILE_PATH="$(jq -r '.tool_input.file_path // .tool_response.filePath // empty' || true)"

case "${FILE_PATH}" in
  # vendor/ is downloaded by importmap and bundles/ is published by Symfony bundles — both are third-party
  # trees that get overwritten, so linting them would only produce noise nobody can act on.
  *app/assets/vendor/*) exit 0 ;;
  *app/assets/bundles/*) exit 0 ;;
  *app/assets/*.js) ;;
  *) exit 0 ;;
esac

[ -f "${FILE_PATH}" ] || exit 0

FILE_NAME="${FILE_PATH##*/}"
VIOLATIONS=""

# Line-comment hits are dropped: several controllers document their Twig wiring in a header block that
# legitimately mentions the very attributes and calls being searched for.
scan() {
  local PATTERN="$1"
  local ADVICE="$2"
  local HITS
  local HIT

  HITS="$(grep -nE "${PATTERN}" "${FILE_PATH}" | grep -vE '^[0-9]+:[[:space:]]*(//|\*|/\*)' || true)"
  [ -n "${HITS}" ] || return 0

  while IFS= read -r HIT; do
    VIOLATIONS="${VIOLATIONS}  ${FILE_NAME}:${HIT%%:*} — ${ADVICE}"$'\n'
  done <<< "${HITS}"
}

# --------------------------------------------------------------------------------------------------------------------
# Security — applies to every asset module
# --------------------------------------------------------------------------------------------------------------------
scan '\.innerHTML[[:space:]]*=' 'innerHTML assignment → use textContent, or sanitise with DOMPurify for server HTML'
scan '\beval[[:space:]]*\(' 'eval() is banned outright'
scan 'new[[:space:]]+Function[[:space:]]*\(' 'new Function(str) is banned outright'
scan '(localStorage|sessionStorage)\.setItem\([^)]*(token|password|secret)' 'no credentials in web storage → use an HttpOnly cookie'

# --------------------------------------------------------------------------------------------------------------------
# Module conventions — applies to every asset module
# --------------------------------------------------------------------------------------------------------------------
scan '\brequire[[:space:]]*\(' 'CommonJS require() → use an ES module import'
scan '^[[:space:]]*var[[:space:]]' 'var declaration → use const (or let when reassigned)'
scan 'console\.log[[:space:]]*\(' 'console.log left in place → remove it, or use console.error with context'

# --------------------------------------------------------------------------------------------------------------------
# Stimulus controllers only
# --------------------------------------------------------------------------------------------------------------------
# The "no direct DOM lookup" rule is scoped to controllers, which have targets to use instead. Plain modules
# under themes/ and turbo/ have no controller scope and query the document legitimately.
case "${FILE_PATH}" in
  *app/assets/controllers/*)
    scan 'document\.(querySelector|querySelectorAll|getElementById)' 'direct DOM lookup in a controller → use this.*Target'
    ;;
esac

if [ -n "${VIOLATIONS}" ]; then
  {
    echo "[ FAIL ] JavaScript quality rule violations (.claude/rules/app-javascript-stimulus-02-quality-rule.md):"
    printf '%s' "${VIOLATIONS}"
  } >&2
  exit 2
fi

exit 0
