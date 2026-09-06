#!/bin/bash

set -euo pipefail
# ----------------------------------------------------------------------------------------------------------------------
# Hooks - Stop - PHP Symfony Quality Gate
# ----------------------------------------------------------------------------------------------------------------------
# Registered in: .claude/settings.json → hooks.Stop (asyncRewake, timeout 600).
# Contract: once Claude finishes a turn, run the merge-blocking quality gates over the working tree —
#           PHPStan (changed files only), lint:twig, lint:container, lint:yaml — and report failures to
#           Claude via exit 2. Runs in the background so the conversation is never stalled; stdout goes to
#           the debug log only.
# Split from session-end/app-php-symfony-clear.sh, which keeps the housekeeping half (php-cs-fixer,
# composer install, cache:clear). The gates belong on Stop because that is the only event where their
# report can reach Claude: SessionEnd cannot be blocked and has no turn left to wake, so an exit 2 there
# is written to nobody. The housekeeping stays on SessionEnd because composer install and cache:clear are
# too heavy to repeat once per turn.
# asyncRewake is what makes exit 2 usable here: it wakes Claude with stderr as a system reminder instead of
# blocking the stop. A plain Stop exit 2 would prevent Claude from stopping at all, and Claude Code
# documents no loop-prevention mechanism for that path.
# Everything degrades to "skipped" when the toolchain is absent — an uninstalled project must not be
# reported as a quality failure.
# Concurrency: Stop fires on every turn and Claude Code does NOT de-duplicate async hook executions, so an
# flock guard stops overlapping runs from racing on app/var/cache. The lock is shared with the two
# SessionEnd hooks: lint:container rebuilds the container cache that composer's auto-scripts empty next door.
# A skipped turn is NOT silently dropped. The in-flight run took its git snapshot before this turn's edits
# existed, so skipping outright would leave them unanalysed while looking exactly like a pass — Claude is
# only ever woken on exit 2, so "gate did not run" and "gate passed" are the same observation. The skipping
# turn leaves a rerun marker and the holder makes one more pass, coalescing any number of skips into a
# single extra run.
# ----------------------------------------------------------------------------------------------------------------------

find_project_root() {
  local PROJECT_DIR
  PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  while [[ "${PROJECT_DIR}" != "/" ]]; do
    if [[ -d "${PROJECT_DIR}/.git" ]] || [[ -f "${PROJECT_DIR}/.env.app" ]]; then
      echo "${PROJECT_DIR}"
      return 0
    fi
    PROJECT_DIR="$(dirname "${PROJECT_DIR}")"
  done
  return 1
}

# CLAUDE_PROJECT_DIR is exported onto the hook process by Claude Code; fall back to the walk-up search.
PROJECT_PATH="${CLAUDE_PROJECT_DIR:-$(find_project_root || true)}"

# Every precondition below degrades to exit 0 — a Stop hook must never report an error for a state
# that simply means "nothing to do here".
[ -n "${PROJECT_PATH}" ] || exit 0
[ -d "${PROJECT_PATH}/app" ] || exit 0
cd "${PROJECT_PATH}/app" || exit 0
[ -f bin/console ] || exit 0
# Without vendor/, bin/console aborts with an uncaught LogicException and every gate below would report a
# PHP fatal as a quality failure. app-toolchain-status.sh already reports the missing tree at startup.
[ -d vendor ] || exit 0

# ----------------------------------------------------------------------------------------------------------------------
# Lock
# ----------------------------------------------------------------------------------------------------------------------

# Hand this turn over to the run already in flight — this hook's or a SessionEnd sibling's. -n
# (non-blocking) is deliberate: queueing would pile up one pending pipeline per turn. The marker is what
# keeps the handover honest; see the header.
GATE_RERUN_MARKER="${PROJECT_PATH}/app/var/.claude-gate-rerun"

if command -v flock >/dev/null 2>&1 && [ -w "${PROJECT_PATH}/app/var" ]; then
  exec 9>"${PROJECT_PATH}/app/var/.claude-app-clear.lock"
  if ! flock -n 9; then
    : > "${GATE_RERUN_MARKER}" 2>/dev/null || true
    exit 0
  fi
fi

# ----------------------------------------------------------------------------------------------------------------------
# Gate
# ----------------------------------------------------------------------------------------------------------------------

GATE_REPORT=""

gate_fail() {
  GATE_REPORT="${GATE_REPORT}--- $1"$'\n'"$2"$'\n'
}

run_gates() {
# --------------------------------------------------------------------------------------------------------------------
# PHPStan (level 8) — working-tree changes only
# --------------------------------------------------------------------------------------------------------------------
# Analysing only what changed keeps the gate to seconds instead of minutes on 2000+ files. Explicit paths
# override the `paths:` key but not `ignoreErrors:` or the 13k-line baseline, so pre-existing debt stays
# suppressed and only newly introduced violations are reported.
if [ -x ./vendor/bin/phpstan ]; then
  PHPSTAN_TARGETS=()
  while IFS= read -r CHANGED_FILE; do
    case "${CHANGED_FILE}" in *.php) ;; *) continue ;; esac
    [ -f "${PROJECT_PATH}/${CHANGED_FILE}" ] || continue
    PHPSTAN_TARGETS+=("${PROJECT_PATH}/${CHANGED_FILE}")
  done <<< "$({
    git -C "${PROJECT_PATH}" diff --name-only HEAD -- app/src app/tests 2>/dev/null
    git -C "${PROJECT_PATH}" ls-files --others --exclude-standard -- app/src app/tests 2>/dev/null
  } || true)"

  if [ ${#PHPSTAN_TARGETS[@]} -gt 0 ]; then
    echo ">>>> PHP - Symfony Framework - Quality Gate - PHPStan (${#PHPSTAN_TARGETS[@]} changed files)"
    PHPSTAN_OUTPUT="$(./vendor/bin/phpstan analyse --no-progress --error-format=raw --memory-limit=1G \
      "${PHPSTAN_TARGETS[@]}" 2>&1)" || gate_fail "PHPStan (level 8)" "${PHPSTAN_OUTPUT}"
    echo
  fi
fi

# --------------------------------------------------------------------------------------------------------------------
# Console linters
# --------------------------------------------------------------------------------------------------------------------
# --show-deprecations lives here rather than in the per-edit app-twig-lint.sh hook: Symfony promotes
# deprecations to lint errors, so at edit time a single pre-existing one would fire on every unrelated
# template.
echo ">>>> PHP - Symfony Framework - Quality Gate - lint:twig / lint:container / lint:yaml"

LINT_OUTPUT="$(APP_ENV=dev php bin/console lint:twig --show-deprecations templates/ 2>&1)" \
  || gate_fail "lint:twig templates/" "${LINT_OUTPUT}"

LINT_OUTPUT="$(APP_ENV=dev php bin/console lint:container 2>&1)" \
  || gate_fail "lint:container" "${LINT_OUTPUT}"

LINT_OUTPUT="$(APP_ENV=dev php bin/console lint:yaml config/ 2>&1)" \
  || gate_fail "lint:yaml config/" "${LINT_OUTPUT}"
echo
}

# The marker is cleared BEFORE each pass, never after: a turn that skips while the pass is running must set
# it again and be honoured by the next iteration. Two passes cap the work — the second one already sees a
# working tree that includes every edit made while the first was running.
for _ in 1 2; do
  rm -f "${GATE_RERUN_MARKER}" 2>/dev/null || true
  GATE_REPORT=""
  run_gates
  [ -e "${GATE_RERUN_MARKER}" ] || break
  echo ">>>> PHP - Symfony Framework - Quality Gate - rerun requested by a skipped turn"
done
rm -f "${GATE_RERUN_MARKER}" 2>/dev/null || true

# stderr, not stdout: asyncRewake shows stderr to Claude as a system reminder and falls back to stdout only
# when stderr is empty — and stdout here is full of progress chatter.
if [ -n "${GATE_REPORT}" ]; then
  {
    echo "[ GATE ] Quality gates failed after the last turn — fix these before the change can merge:"
    printf '%s' "${GATE_REPORT}"
  } >&2
  exit 2
fi

exit 0
