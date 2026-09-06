---
name: utility-claude-code-skill
description: "Authors this project's Claude Code configuration artifacts (sub-agents, skills, slash commands, rules, output styles, settings hooks, CLAUDE.md), self-verifies them against the review checklist, then writes them to the target path. Always use it for natural-language requests like 'create an agent', 'write a skill', 'add a slash command', 'edit CLAUDE.md', or '.claude config'. Do not use it to review an existing config file (use the /utility-claude-code-review command instead), nor for simple questions about Claude Code features/usage that do not author or modify a config file."
---

# Claude Code Skill

Authors a Claude Code project configuration artifact, self-verifies it against the review checklist, and
writes it to the target path.

- Authoring language: **English** (the project `.md` convention)
- Targets: `.claude/agents/**`, `.claude/skills/**/SKILL.md`, `.claude/commands/**`, `.claude/rules/**`,
  `.claude/output-styles/**`, `.claude/settings.json`, `.claude/hooks/**/*.sh`, `CLAUDE.md`
- A hook script follows `.claude/output-styles/utility-shell-script-style.md`. Read and apply it
  manually — an output style carries no `paths` frontmatter, so it never auto-applies to the file.

**Scope distinction:** use this skill only when **authoring or modifying** a config file. Do not use it
for a simple **question** about Claude Code features/usage that does not change any config.

@see .claude/commands/utility-claude-code-review.md — per-type frontmatter rules & verification checklist (SoT)
@see .claude/rules/utility-claude-code-rule.md — `.claude/**` structure immutability & allowed changes (SoT)
@see https://code.claude.com/docs/en/subagents — sub-agent spec
@see https://code.claude.com/docs/en/skills — skill frontmatter reference & command-name resolution
@see https://code.claude.com/docs/en/memory — `.claude/rules/` layout & `paths` path-specific rules
@see https://code.claude.com/docs/en/output-styles — output-style frontmatter & `outputStyle` selection
@see https://code.claude.com/docs/en/hooks — hook events & the hook JSON schema
@see https://code.claude.com/docs/en/settings-reference — `settings.json` key reference
@see https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview — Agent Skills spec
@see https://platform.claude.com/docs/en/build-with-claude/skills-guide — Skills API name/description constraints

---

## Workflow

1. **Interpret the request (precondition)**
   - Determine the **artifact type** (agent/skill/command/rule/output style/settings/CLAUDE.md) and **target path** from the user's request.
   - If the type/path is unclear, confirm it with **one clear question** before proceeding (do not ask about multiple ambiguities at once).

2. **Learn the conventions**
   - `Read` **1–2 existing files of the same kind** under `.claude/**` and follow their frontmatter, tone, and section structure — do not invent new conventions.

3. **Author the artifact**
   - Write it per the type's required frontmatter and body rules in the review command referenced above.

4. **Self-verify before writing**
   - This domain has **no author/reviewer sub-agent pair** (unlike `utility-git-commit-skill` and `utility-drawio-diagram-skill`, the two domains that still run one); the skill verifies its own draft — there is no downstream reviewer to defer to. `utility-shell-script-skill` works the same self-verifying way since its agent pair was retired on 2026-08-16.
   - Cross-check the draft against the review command's checklist: frontmatter validity, naming & path, tool minimality, convention agreement, factuality, role boundaries.
   - **Structure immutability** — confirm the target path conforms to the existing taxonomy and that no existing file or directory is relocated (see the structure SoT above).
   - Confirm every referenced path/agent/skill/command/tool actually exists before writing.
   - If a check fails, revise and re-check. **At most 2 revision rounds.**

5. **Write to the target path**
   - Create the needed parent directory first (`mkdir -p "$(dirname <target-path>)"`), write the file, then report the written path and a summary.
   - The target path must follow the existing **flat** taxonomy — a single tier per tree, with the domain encoded as a hyphenated filename prefix (`<domain>-<name>-<kind>.md`) — and mirror the closest sibling of the same kind. **Never** re-introduce a directory tier, and never move or rename an existing file (no `mv`, and no write-to-new-path + delete-old-path).
   - If the request seems to require relocating an existing artifact, **do not write**: report it as `[CONSIDER]` with the before/after paths and get an explicit user decision first.

6. **Revision-limit handling**
   - If a check still fails after 2 revision rounds, **do not write to the target path.**
   - Present the last draft to the user and finish with the warning "auto-approval limit reached — manual review recommended".
