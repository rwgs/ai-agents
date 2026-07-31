# AI changelog

Changes that affect what installation does to a machine: the instructions,
skills, configuration, permissions, and plugins the agents receive. Read this to
decide whether to rerun the installer after pulling. Repository-internal changes
are in the commit history.

This repository publishes no versioned releases, so entries are grouped by date,
newest first. Version headings replace the dates if tagging begins.

## 2026-07-31

- Moved the shared command rules from `ai-home/codex/rules/` to `ai-home/rules/`.
  Installed paths are unchanged: `~/.codex/rules/` still links to the directory
  and Claude Code's `permissions.allow` entries still derive from the same file.
  Rerun the installer to repoint the link.
- Dropped the systems administration, infrastructure, and container skills from
  the installed default set. Rerun the installer to prune their links.

## 2026-07-30

- Installed the shared instructions, skills, and derived permissions for Claude
  Code as well as Codex. `ai-home/AGENTS.md` now links to `~/.claude/CLAUDE.md`
  in addition to `~/.codex/AGENTS.md`, and every skill links into
  `~/.claude/skills/` alongside `~/.agents/skills/`.
- Renamed `codex-home/` to `ai-home/` and separated the shared instruction file
  from Codex-specific configuration.
- Installed the recommended plugins into Claude Code as well as Codex,
  registering the Claude Code marketplace first because none is configured until
  the agent is first started interactively.
- Pruned stale managed skill links on every install, so a skill removed from the
  default set no longer lingers in either agent's skill directory.
- Reduced the repository-local `CLAUDE.md` to an `@AGENTS.md` import and moved
  the RTK catalog to `docs/RTK.md`.
- Added the `powershell-scripting`, `adopt-baseline`, and `web-development`
  skills, made skill descriptions agent-neutral, and removed the `quickshell`
  and optional skill trees from the default set.
- Ignored `.claude/settings.local.json`, which holds personally approved
  permissions.
- Pinned line endings so shell scripts stay LF on Windows checkouts.

## 2026-07-26

- Added opt-in, cross-platform plugin installation and rendered exact
  trusted-project entries for every Git worktree beneath `~/github`.

## 2026-07-15

- Added the Windows PowerShell installer.

## 2026-06-21

- Expanded the repository into an installer and added the default command rule
  file that both permission systems derive from.
