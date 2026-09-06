#!/bin/bash

set -euo pipefail
# ----------------------------------------------------------------------------------------------------------------------
# Hooks - PreToolUse - Agent roster guard
# ----------------------------------------------------------------------------------------------------------------------
# Registered in: .claude/settings.json → hooks.PreToolUse (matcher "Agent|Task").
# Contract: Claude Code pipes the hook payload as JSON on stdin. `agent_type` names the agent making the
# call and is present only when the hook fires inside a subagent, so it identifies the caller; the spawn
# target is `tool_input.subagent_type`.
# Exit 2 blocks the spawn and shows stderr to the caller — this is the whole point of the guard. Every
# other exit code is non-blocking.
#
# Why this exists: the three orchestrators each carry an "only spawn my roster" invariant, but a subagent
# definition cannot enforce it. `tools: Agent(a, b)` looks like an allowlist and is not — that syntax
# applies only to an agent running as the main thread with `claude --agent`, and in a subagent definition
# the type list inside the parentheses is ignored. `permissions.deny` can block agents by name, but it is
# a denylist applied repo-wide, so expressing "only these five prefixes, and only for this one caller"
# would mean enumerating every other agent and would also block the sibling orchestrators' legitimate
# spawns. Matching caller against target here is the only mechanism that scopes the allowlist per team.
#
# Judgment SoT: the roster invariant section of .claude/rules/{app,api,tools}-agent-team-rule.md. The three
# files word that heading differently, so each case branch below carries its own RULE_SECTION rather than a
# single shared string.
# This script is an executable projection of those rules and holds no criteria of its own; when a roster
# changes, the rule and this table change in the same commit.
# ----------------------------------------------------------------------------------------------------------------------

# CLAUDE_PROJECT_DIR is exported onto the hook process by Claude Code; fall back to resolving the repository
# root from this script's location (.claude/hooks/pre-tool-use/ → three levels up). This is load-bearing for
# the agent-file test at the bottom: a cwd-relative path would silently pass every spawn whenever the hook
# runs from anywhere but the repository root, which for a guard is the worst possible failure mode.
PROJECT_PATH="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)}"

# jq parses the hook payload. Degrade non-blocking rather than refusing every spawn, but say so out loud —
# a guard that silently stops guarding is the failure this repo treats as most harmful.
if ! command -v jq >/dev/null 2>&1; then
  echo "[ WARN ] agent roster guard skipped: jq not found. Roster constraint is UNENFORCED for this call." >&2
  exit 1
fi

PAYLOAD="$(cat)"

# `|| true` is load-bearing under `set -e`: jq exits non-zero on malformed input and would kill the script
# before it can report anything.
CALLER="$(printf '%s' "${PAYLOAD}" | jq -r '.agent_type // empty' 2>/dev/null || true)"
TOOL_NAME="$(printf '%s' "${PAYLOAD}" | jq -r '.tool_name // empty' 2>/dev/null || true)"
TARGET="$(printf '%s' "${PAYLOAD}" | jq -r '.tool_input.subagent_type // empty' 2>/dev/null || true)"

# The Task tool was renamed to Agent in CLI 2.1.63; Task still resolves as a backward-compatible alias, so
# both names have to be matched here even though new artifacts only write Agent.
case "${TOOL_NAME}" in
  Agent | Task) ;;
  *) exit 0 ;;
esac

[ -n "${TARGET}" ] || exit 0

# Only the three orchestrators carry a roster invariant. Anything else — the main thread, a domain agent
# spawning a helper, a bundled agent — is out of this guard's scope and passes through untouched.
case "${CALLER}" in
  app-agent-team)
    ALLOW_PATTERN='^app-.+-(author|analyzer|debugger|reviewer|tester)$'
    ROSTER_DESC='the 15 app-*-* agents (PHP / JS / Twig x author, analyzer, debugger, reviewer, tester)'
    RULE_PATH='.claude/rules/app-agent-team-rule.md'
    RULE_SECTION='## Invariant — roster (direct spawn targets)'
    HANDOFF='infrastructure, data and deployment -> hand off to tools-agent-team / API Platform -> api-agent-team / Diagram, Commit and the deploy gate -> the Skill tool'
    ;;
  api-agent-team)
    ALLOW_PATTERN='^api-platform-(author|analyzer|debugger|reviewer|tester)$'
    ROSTER_DESC='the 5 api-platform-* agents'
    RULE_PATH='.claude/rules/api-agent-team-rule.md'
    RULE_SECTION='## Invariant — roster (direct spawn targets)'
    HANDOFF='the app itself, providers and operations -> hand off to app-agent-team / infrastructure, data and deployment -> tools-agent-team'
    ;;
  tools-agent-team)
    ALLOW_PATTERN='^(cache|database|server|tools-aws|tools-gcp)-.+$'
    ROSTER_DESC='cache-* / database-* / server-* / tools-aws-* / tools-gcp-* (as resolved by preflight)'
    RULE_PATH='.claude/rules/tools-agent-team-rule.md'
    RULE_SECTION='## Invariant — the roster is fixed by preflight'
    HANDOFF='message-rabbitmq -> the /message-rabbitmq-review command under app-agent-team / deploy go-no-go -> tools-app-deploy-skill'
    ;;
  *) exit 0 ;;
esac

block() {
  {
    echo "[ BLOCKED ] ${CALLER} may not spawn '${TARGET}'."
    echo "  reason : $1"
    echo "  roster : ${ROSTER_DESC}"
    echo "  rule   : ${RULE_PATH} → '${RULE_SECTION}'"
    echo "  route  : ${HANDOFF}"
  } >&2
  exit 2
}

# Reject anything that is not a plain agent slug before it reaches the filesystem test below.
printf '%s' "${TARGET}" | grep -qE '^[a-z0-9-]+$' \
  || block "'${TARGET}' is not a valid agent slug (lowercase alphanumerics and hyphens only)."

# Condition 1 — the name matches this orchestrator's roster pattern.
# A team's own slug never matches its pattern (app-agent-team lacks a role suffix; tools-agent-team starts
# with tools- but not tools-aws-/tools-gcp-), so self-spawning and sibling-spawning are refused here
# without needing a separate rule.
printf '%s' "${TARGET}" | grep -qE "${ALLOW_PATTERN}" \
  || block "name is outside this orchestrator's roster pattern."

# Condition 2 — the agent actually resolves in the tree. The rules state the roster as a conjunction of
# pattern and preflight resolution, so a stale roster entry is refused rather than spawned blindly.
[ -f "${PROJECT_PATH}/.claude/agents/${TARGET}.md" ] \
  || block "no such agent file (.claude/agents/${TARGET}.md) — report this axis as 'cannot judge (target missing)'."

exit 0
