#!/bin/bash

set -euo pipefail
# ----------------------------------------------------------------------------------------------------------------------
# Hooks - PostToolUse - Git commit message draft guard
# ----------------------------------------------------------------------------------------------------------------------
# Registered in: .claude/settings.json → hooks.PostToolUse (matcher "Edit|Write").
# Dual entry point — the same file is both the hook and the checker the reviewer runs by hand:
#   hook  : payload arrives as JSON on stdin, file path read with jq.
#   CLI   : utility-git-commit-draft.sh <draft path>, used by utility-git-commit-author (self gate) and
#           utility-git-commit-reviewer (the output is the evidence its verdict rests on).
# One implementation means the hook and the reviewer can never drift apart.
# This is the executable projection of .claude/rules/utility-git-commit-rule.md and the
# `## Artifact File Formats` section of .claude/output-styles/utility-git-commit-style.md — it adds no
# criteria of its own; the rule stays the SoT.
# It never rewrites the draft: `git commit -F` reads the file byte for byte, so an autofix here would
# silently change what gets committed.
# Exit 2 does NOT block — PostToolUse runs after the tool — it only surfaces stderr so the draft is
# corrected inside the same turn.
# ----------------------------------------------------------------------------------------------------------------------

FILE_PATH="${1:-}"

# No argument means the hook invoked us, so the path has to come out of the stdin payload.
# Edit exposes tool_input.file_path; Write's response uses tool_response.filePath.
# `|| true` is load-bearing under `set -e` — see php-lint.sh for the full rationale.
if [ -z "${FILE_PATH}" ]; then
  command -v jq >/dev/null 2>&1 || exit 0
  FILE_PATH="$(jq -r '.tool_input.file_path // .tool_response.filePath // empty' || true)"
fi

case "${FILE_PATH}" in
  *.claude/tmp/utility/git/commit-message-draft.md) ;;
  *) exit 0 ;;
esac

[ -f "${FILE_PATH}" ] || exit 0

MUST=""
SHOULD=""

add_must() { MUST="${MUST}  [MUST] $1"$'\n'; }
add_should() { SHOULD="${SHOULD}  [SHOULD] $1"$'\n'; }

# ----------------------------------------------------------------------------------------------------------------------
# Whole-file shape — the draft is the commit, so anything that is not message text is a defect
# ----------------------------------------------------------------------------------------------------------------------

if [ ! -s "${FILE_PATH}" ]; then
  echo "[ FAIL ] commit draft (.claude/rules/utility-git-commit-rule.md):" >&2
  echo "  [MUST] the draft is empty — there is no message to commit." >&2
  exit 2
fi

MARKDOWN_HITS="$(grep -nE '^(```|~~~|#{1,6} |[-*+] |> )' "${FILE_PATH}" || true)"
if [ -n "${MARKDOWN_HITS}" ]; then
  while IFS= read -r HIT; do
    add_must "line ${HIT%%:*}: markdown syntax (code fence, heading, bullet or quote) — git commit -F commits it verbatim."
  done <<< "${MARKDOWN_HITS}"
fi

# LC_ALL=C keeps [:print:] at ASCII, so every byte >= 0x80 (Korean, em dash, smart quote) shows up.
NONASCII_HITS="$(LC_ALL=C grep -n '[^[:print:]]' "${FILE_PATH}" || true)"
if [ -n "${NONASCII_HITS}" ]; then
  while IFS= read -r HIT; do
    add_must "line ${HIT%%:*}: non-ASCII or non-printable character — a commit message is English only."
  done <<< "${NONASCII_HITS}"
fi

TRAILER_HITS="$(grep -niE '^(Co-authored-by|Signed-off-by|Refs|Closes|Fixes|See-also):' "${FILE_PATH}" || true)"
if [ -n "${TRAILER_HITS}" ]; then
  while IFS= read -r HIT; do
    add_must "line ${HIT%%:*}: a trailer this repository does not use — only BREAKING CHANGE: is allowed."
  done <<< "${TRAILER_HITS}"
fi

# ----------------------------------------------------------------------------------------------------------------------
# Subject line
# ----------------------------------------------------------------------------------------------------------------------

SUBJECT="$(sed -n '1p' "${FILE_PATH}")"
SUBJECT_LENGTH="${#SUBJECT}"

[ "${SUBJECT_LENGTH}" -le 72 ] || add_must "the subject is ${SUBJECT_LENGTH} characters — trim it to 72 or fewer."

case "${SUBJECT}" in
  *.) add_must "the subject ends with a period." ;;
esac

TYPES='feat|fix|refactor|perf|style|test|docs|build|ci|chore|revert'
if ! printf '%s\n' "${SUBJECT}" | grep -qE "^(${TYPES})(\([a-zA-Z0-9._/-]+\))?!?: .+"; then
  add_must "the subject does not match 'type(scope): subject' — allowed types: ${TYPES//|/, }."
fi

# Scope is a convention, not a hard constraint: a new area can legitimately show up before the rule
# lists it, so an unknown scope is worth surfacing but never worth blocking a commit over.
SCOPE="$(printf '%s\n' "${SUBJECT}" | sed -nE "s/^(${TYPES})\(([^)]+)\).*/\2/p")"
if [ -n "${SCOPE}" ]; then
  case "${SCOPE}" in
    app | assets | config | scripts | rules | skills | agents | docs | nginx | hooks) ;;
    *) add_should "scope '${SCOPE}' is outside the conventional list — check the scope derivation section of the rule." ;;
  esac
fi

# ----------------------------------------------------------------------------------------------------------------------
# Body
# ----------------------------------------------------------------------------------------------------------------------

TOTAL_LINES="$(wc -l < "${FILE_PATH}" | tr -d ' ')"

if [ "${TOTAL_LINES}" -gt 1 ]; then
  SECOND_LINE="$(sed -n '2p' "${FILE_PATH}")"
  [ -z "${SECOND_LINE}" ] || add_must "line 2 is not empty — a blank line must separate the subject from the body."
fi

BODY_LINE_COUNT="$(sed -n '3,$p' "${FILE_PATH}" | grep -cve '^[[:space:]]*$' -e '^BREAKING CHANGE:' || true)"
if [ "${BODY_LINE_COUNT}" -gt 3 ]; then
  add_must "the body is ${BODY_LINE_COUNT} lines — trim it to 3 or fewer."
fi

LONG_BODY_HITS="$(awk 'NR >= 3 && length($0) > 72 { print NR }' "${FILE_PATH}" || true)"
if [ -n "${LONG_BODY_HITS}" ]; then
  while IFS= read -r LINE_NUMBER; do
    add_should "line ${LINE_NUMBER}: body exceeds 72 characters — git log output truncates it."
  done <<< "${LONG_BODY_HITS}"
fi

LAST_LINE="$(tail -n 1 "${FILE_PATH}")"
[ -n "${LAST_LINE}" ] || add_should "a blank line is left at end of file — end with a single newline."

# ----------------------------------------------------------------------------------------------------------------------
# Report
# ----------------------------------------------------------------------------------------------------------------------

if [ -n "${MUST}" ]; then
  {
    echo "[ FAIL ] commit draft (.claude/rules/utility-git-commit-rule.md):"
    printf '%s' "${MUST}"
    if [ -n "${SHOULD}" ]; then printf '%s' "${SHOULD}"; fi
  } >&2
  exit 2
fi

if [ -n "${SHOULD}" ]; then
  echo "[ WARN ] commit draft (.claude/rules/utility-git-commit-rule.md):"
  printf '%s' "${SHOULD}"
fi

exit 0
