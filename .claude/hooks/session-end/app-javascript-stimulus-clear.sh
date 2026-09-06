#!/bin/bash

set -euo pipefail
# ----------------------------------------------------------------------------------------------------------------------
# Hooks - SessionEnd - JavaScript Stimulus Clear
# ----------------------------------------------------------------------------------------------------------------------
# Registered in: .claude/settings.json → hooks.SessionEnd, matcher "logout|prompt_input_exit|other"
#                (async, timeout 60). The matcher keeps the rebuild off /clear and resume, which end the
#                session mid-work.
# Contract: once the session ends, refresh the dev frontend assets the session may have invalidated —
#           importmap:install (only when missing), tailwind:build, asset-map:compile — in that order.
#           Runs in the background; stdout goes to the debug log only.
# This hook is the sole owner of asset-map:compile. app-php-symfony-clear.sh used to run it too, which both
# duplicated the work and published stale CSS: its copy ran before tailwind:build had written
# app/var/tailwind, so the compiled output never contained the session's style changes.
# Exit code is always 0. SessionEnd is not a blockable event and exit 2 has no reader here — asyncRewake
# wakes Claude for a turn that no longer exists once the session is over.
# php bin/console, not `symfony console` — the Symfony CLI binary is an unguarded external dependency, and
# every console call below already carries an explicit APP_ENV.
# Concurrency: an flock guard stops a second firing from racing the first on app/var/cache and
# app/public/assets. The lock is shared with session-end/app-php-symfony-clear.sh and
# stop/app-php-symfony-gate.sh, whose composer auto-scripts empty the very cache the console commands below
# boot. Both SessionEnd hooks contend for that lock with -w, so which one runs first is NOT fixed — this is
# mutual exclusion only, not ordering. Nothing below depends on the order: asset-map:compile reads
# app/var/tailwind and assets/vendor, neither of which the sibling touches.
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
# Without vendor/, bin/console aborts with an uncaught LogicException and every step below would dump a PHP
# fatal to stderr once per session. app-toolchain-status.sh already reports the missing tree at startup.
[ -d vendor ] || exit 0

# ----------------------------------------------------------------------------------------------------------------------
# Lock
# ----------------------------------------------------------------------------------------------------------------------

# -w (wait), not -n: the PHP sibling normally holds this lock first, and giving up immediately would mean
# the assets are never rebuilt. The 45s ceiling keeps the hook inside the budget Claude Code grants a
# SessionEnd handler — if composer install is still running by then, this session skips the rebuild.
if command -v flock >/dev/null 2>&1 && [ -w "${PROJECT_PATH}/app/var" ]; then
  exec 9>"${PROJECT_PATH}/app/var/.claude-app-clear.lock"
  flock -w 45 9 || exit 0
fi

# ----------------------------------------------------------------------------------------------------------------------
# Assets
# ----------------------------------------------------------------------------------------------------------------------

# Report a failed step and keep going — one broken tool must not skip the steps behind it.
warn_step() {
  echo "[ WARN ] step failed (continuing): $1" >&2
}

# --------------------------------------------------------------------------------------------------------------------
# H) Other Things - AssetMapper - importmap:install
# --------------------------------------------------------------------------------------------------------------------
# Guarded on the directory being absent, not run unconditionally: with assets/vendor present this command
# still reaches out to the CDN for every importmap entry. app-toolchain-status.sh reports the missing tree
# at session start; this heals it at session end.
if [ ! -d assets/vendor ]; then
  echo ">>>> JavaScript - AssetMapper - importmap:install"
  APP_ENV=dev APP_DEBUG=1 php bin/console importmap:install || warn_step "importmap:install"
  echo
fi

# --------------------------------------------------------------------------------------------------------------------
# H) Other Things - TailwindBundle                       https://symfony.com/bundles/TailwindBundle/current/index.html
# --------------------------------------------------------------------------------------------------------------------
# First run downloads the standalone tailwind binary into app/var/tailwind. No -v: this runs in the
# background where verbose output is noise nobody reads.
if [ -d vendor/symfonycasts/tailwind-bundle ]; then
  echo ">>>> JavaScript - TailwindBundle - tailwind:build"
  APP_ENV=dev APP_DEBUG=1 php bin/console tailwind:build || warn_step "tailwind:build"
  echo
fi

# --------------------------------------------------------------------------------------------------------------------
# H) Other Things - AssetMapper - asset-map:compile
# --------------------------------------------------------------------------------------------------------------------
# Must stay last: it publishes what the two steps above produced (app/var/tailwind, assets/vendor).
echo ">>>> JavaScript - AssetMapper - asset-map:compile"
APP_ENV=dev APP_DEBUG=1 php bin/console asset-map:compile || warn_step "asset-map:compile"
echo

exit 0
