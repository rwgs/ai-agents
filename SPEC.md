# AI specification

## Problem

Claude/Codex installations mix portable configuration with credentials, sessions,
caches, and other machine-local state. Coding agents also need consistent
instructions and reusable workflows without replacing project-specific
requirements.

## Users

The primary user is a developer who works across Linux, macOS, and Windows and
wants the same safe Claude/Codex baseline in multiple repositories.

## Required behavior

- Install global Claude/Codex instructions, configuration, rules, local-model
  profiles, and reusable skills from this repository.
- Install one shared instruction file as the global instructions for both agents,
  and one skill directory into both agents' skill locations.
- Derive Claude Code's command permissions from the same rule file Codex uses, so
  the allowlist has a single hand-authored source.
- Merge managed Claude Code permissions into an existing `settings.json` without
  discarding interactively approved permissions or unrelated settings.
- Optionally install an explicit list of recommended plugins into both agents,
  registering a marketplace first where the agent requires it.
- Trust the current user's `~/github` directory and every Git worktree
  discovered recursively beneath it on each installation.
- Preview installation without changing the target system.
- Preserve existing managed targets in timestamped backups before replacement.
- Leave credentials, sessions, history, caches, plugin state, and runtime
  databases untouched unless plugin installation is explicitly requested.
- Support repeated installation without replacing already-correct links.
- Provide project-planning templates and separate planning from pull-request
  readiness.
- Validate repository structure, configuration syntax, skill metadata,
  documentation consistency, and installer behavior.
- Run Linux, macOS, and Windows validation for pull requests and default-branch
  pushes.

## Architecture

- `ai-home/AGENTS.md` is the shared global instruction file, linked to
  `~/.codex/AGENTS.md` and `~/.claude/CLAUDE.md`.
- `ai-home/codex/` contains portable files installed into `CODEX_HOME`.
- `ai-home/codex/rules/default.rules` is the single source for both permission
  systems; the installer derives Claude Code's `permissions.allow` entries from
  it.
- The installer renders `config.toml` with machine-specific exact trust entries,
  merges Claude Code's `settings.json`, and links the other managed files.
- `.agents/skills/` contains reusable workflows linked into `AGENTS_HOME` and
  `CLAUDE_CONFIG_DIR`.
- `scripts/install.sh` and `scripts/install.ps1` perform user-scoped
  installation.
- `codex-plugins.txt` and `claude-plugins.txt` record the plugin selectors
  installed only through the explicit plugin option, one manifest per agent
  because the two agents publish the same plugin in different marketplaces.
- `scripts/validate.sh` and installer integration tests provide local and CI
  evidence.
- `AGENTS.md`, this specification, `ROADMAP.md`, and `TASKS.md` define how the
  repository is maintained.

## Security and privacy

- Never track authentication files, session history, caches, logs, or runtime
  databases.
- Do not require administrator privileges for normal installation.
- Keep destructive actions narrowly scoped and require explicit authorization.
- Give GitHub Actions the minimum permissions required by each job.
- Pin third-party actions and let Dependabot keep those pins current.

## Compatibility

- The shell installer targets Bash on Linux and macOS.
- The PowerShell installer targets supported Windows PowerShell environments
  capable of creating symbolic links.
- Optional tools may add validation but must not make ordinary installation
  depend on unrelated developer tooling.
- The Claude permission merge uses `python3` or `python` when present and is
  skipped with a warning otherwise, so installation never fails for lack of a
  JSON tool.

## Non-goals

- Mirroring the complete Claude/Codex home directory.
- Managing credentials, plugin caches or authentication, sessions, or caches.
- Installing plugins without an explicit opt-in.
- Replacing project-specific `AGENTS.md` or requirements.
- Installing Codex, Claude Code, CodeRabbit, RTK, or local model servers.
- Adding security scanners that do not support the repository's languages.

## Acceptance criteria

- `./scripts/validate.sh` passes from a clean checkout.
- Linux and macOS installer integration tests verify dry-run safety, backup
  preservation, correct links, generated GitHub trust entries, and idempotence
  in isolated temporary directories.
- Windows CI verifies the equivalent PowerShell installer behavior.
- Installer tests verify plugin opt-in and dry-run behavior without contacting
  a live marketplace.
- Every skill has valid front matter and the documented skill inventory matches
  the actual directories.
- Installer tests verify that a Claude permission merge preserves existing
  settings and pre-existing allow entries, and that rerunning adds nothing.
- Pull requests run validation and dependency review on the latest commit.
- Workflow documentation covers planning, implementation, review, manual
  testing, and merge gates.

## Unresolved questions

None currently open. The previous question about user-wide Claude Code
instructions is resolved: the installer links the shared `ai-home/AGENTS.md` to
`~/.claude/CLAUDE.md`, and the repository-local `CLAUDE.md` is a one-line
`@AGENTS.md` import.
