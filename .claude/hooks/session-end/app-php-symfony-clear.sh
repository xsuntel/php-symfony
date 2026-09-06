#!/bin/bash

set -euo pipefail
# ----------------------------------------------------------------------------------------------------------------------
# Hooks - SessionEnd - PHP Symfony Clear
# ----------------------------------------------------------------------------------------------------------------------
# Registered in: .claude/settings.json → hooks.SessionEnd, matcher "logout|prompt_input_exit|other"
#                (async, timeout 60). The matcher keeps this pipeline off /clear and resume, which end the
#                session mid-work and would pay the full cost once per clear.
# Contract: once the session ends, refresh the dev Symfony app — php-cs-fixer over the changed files, then
#           composer install, whose auto-scripts clear the cache. Runs in the background so nothing is
#           stalled; stdout goes to the debug log only.
# This hook is housekeeping only, and every step degrades to warn_step: SessionEnd cannot be blocked and
# has no turn left to wake, so nothing here can reach Claude and the script always exits 0.
# The quality gates that used to live here moved to stop/app-php-symfony-gate.sh, the only event where
# their exit 2 report has a reader. The housekeeping stayed behind because composer install and
# cache:clear are too heavy to repeat once per turn.
# Frontend assets are not this hook's business either: session-end/app-javascript-stimulus-clear.sh owns
# importmap:install, tailwind:build and asset-map:compile.
# Concurrency: SessionEnd fires again on clear/resume within one process, so an flock guard stops
# overlapping runs from racing on app/var/cache and the composer vendor tree. The lock is shared with the
# JavaScript sibling and the Stop gate — cache:clear empties the very cache their console commands boot.
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

# Every precondition below degrades to exit 0 — a SessionEnd hook must never report an error for a state
# that simply means "nothing to do here".
[ -n "${PROJECT_PATH}" ] || exit 0
[ -d "${PROJECT_PATH}/app" ] || exit 0
cd "${PROJECT_PATH}/app" || exit 0
[ -f bin/console ] || exit 0

# ----------------------------------------------------------------------------------------------------------------------
# Lock
# ----------------------------------------------------------------------------------------------------------------------

# -w (wait), not -n: this hook fires once per session and the Stop gate it may queue behind is short-lived,
# so waiting is what makes the housekeeping actually run instead of being dropped. The 45s ceiling keeps
# the hook inside the budget Claude Code grants a SessionEnd handler.
if command -v flock >/dev/null 2>&1 && [ -w "${PROJECT_PATH}/app/var" ]; then
  exec 9>"${PROJECT_PATH}/app/var/.claude-app-clear.lock"
  flock -w 45 9 || exit 0
fi

# ----------------------------------------------------------------------------------------------------------------------
# Project
# ----------------------------------------------------------------------------------------------------------------------

# Report a failed step and keep going — one broken tool must not skip the steps behind it.
warn_step() {
  echo "[ WARN ] step failed (continuing): $1" >&2
}

# --------------------------------------------------------------------------------------------------------------------
# App - Symfony Framework - Deployment - Other Things                  https://symfony.com/doc/current/deployment.html
# --------------------------------------------------------------------------------------------------------------------
# Working-tree changes only. Fixing all of src/ takes ~10s on this codebase (2031 files) and SessionEnd hooks
# share a budget that tops out at 60s, so a full pass can starve the sibling hook's asset rebuild. Explicit
# paths override the `finder` in .php-cs-fixer.dist.php but not its rule set.
if [ -x ./vendor/bin/php-cs-fixer ]; then
  FIXER_TARGETS=()
  while IFS= read -r CHANGED_FILE; do
    case "${CHANGED_FILE}" in *.php) ;; *) continue ;; esac
    [ -f "${PROJECT_PATH}/${CHANGED_FILE}" ] || continue
    FIXER_TARGETS+=("${PROJECT_PATH}/${CHANGED_FILE}")
  done <<< "$({
    git -C "${PROJECT_PATH}" diff --name-only HEAD -- app/src 2>/dev/null
    git -C "${PROJECT_PATH}" ls-files --others --exclude-standard -- app/src 2>/dev/null
  } || true)"

  if [ ${#FIXER_TARGETS[@]} -gt 0 ]; then
    echo ">>>> PHP - Symfony Framework - Bundles - PHP-CS-Fixer (${#FIXER_TARGETS[@]} changed files)"
    ./vendor/bin/php-cs-fixer fix "${FIXER_TARGETS[@]}" || warn_step "php-cs-fixer fix (changed files)"
    echo
  fi
fi

# --------------------------------------------------------------------------------------------------------------------
# C) Install/Update your Vendors  +  D) Clear your Symfony Cache
# --------------------------------------------------------------------------------------------------------------------
# The two steps are one branch on purpose: composer.json wires post-install-cmd → @auto-scripts, which runs
# cache:clear, assets:install and importmap:install on EVERY install — including a no-op one that reports
# "Nothing to install, update or remove". A separate cache:clear here would clear a cache composer just
# rebuilt, so it is only reached when composer is unavailable.
if command -v composer >/dev/null 2>&1; then
  echo ">>>> PHP - Symfony Framework - Deployment - C) Install/Update your Vendors (auto-scripts: cache:clear)"
  APP_ENV=dev APP_DEBUG=1 composer install \
    --ignore-platform-req=ext-redis \
    --ignore-platform-req=ext-amqp \
    --ignore-platform-req=ext-pdo_pgsql || warn_step "composer install"
  echo
elif [ -d vendor ]; then
  # The vendor guard belongs on this step alone, never at the top of the script: composer install above is
  # what creates vendor/ in the first place, so an early guard would disable the self-healing path. Without
  # vendor, bin/console aborts with an uncaught LogicException instead of clearing anything.
  echo ">>>> PHP - Symfony Framework - Deployment - D) Clear your Symfony Cache"
  APP_ENV=dev APP_DEBUG=1 php bin/console cache:clear || warn_step "cache:clear"
  echo
fi

# --------------------------------------------------------------------------------------------------------------------
# H) Other Things - Webpack Encore or AssetMapper
# --------------------------------------------------------------------------------------------------------------------
# asset-map:compile lives in session-end/app-javascript-stimulus-clear.sh, which owns it outright. Running it
# here as well duplicated the work and published stale CSS — this copy ran before that hook's tailwind:build
# had written app/var/tailwind.

exit 0
