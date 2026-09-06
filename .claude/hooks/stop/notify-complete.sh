#!/bin/bash

#set -euo pipefail
# ----------------------------------------------------------------------------------------------------------------------
# Hooks - Stop - Completion sound
# ----------------------------------------------------------------------------------------------------------------------
# Registered in: .claude/settings.json → hooks.Stop (async).
# Contract: best-effort desktop chime when Claude finishes a turn. Does not read stdin.
# Strict mode is intentionally OFF and the script always exits 0 — a Stop hook exit 2 would prevent
# Claude from stopping and continue the conversation, which is not the intent here.
# ----------------------------------------------------------------------------------------------------------------------

pw-play /usr/share/sounds/freedesktop/stereo/complete.oga 2>/dev/null \
  || aplay /usr/share/sounds/alsa/Front_Center.wav 2>/dev/null \
  || true

exit 0
