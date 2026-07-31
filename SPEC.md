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
- Preserve machine-owned Codex configuration and interactively approved rules
  while applying repository-owned defaults.
- Default Codex to a workspace-write sandbox that asks before acting outside it,
  so the baseline never escalates a machine's execution posture silently.
- Leave credentials, sessions, history, caches, plugin state, and runtime
  databases untouched unless plugin installation is explicitly requested.
- Support repeated installation without replacing already-correct links.
- Provide project-planning templates and separate planning from pull-request
  readiness.
- Adopt the baseline into a repository, and bring an already-adopted repository
  up to date when the baseline changes, without overwriting what that repository
  customised.
- Validate repository structure, configuration syntax, skill metadata,
  documentation consistency, and installer behavior.
- Stop managing a permission when it is removed from the curated rule source.
  Never delete an existing grant unless installer ownership is provable; report
  an ambiguous identical grant for conservative resolution.
- Run Linux, macOS, and Windows validation on every push to the default branch,
  and on manual dispatch. There is no pull-request flow to gate.

## Architecture

- `ai-home/AGENTS.md` is the shared global instruction file, linked to
  `~/.codex/AGENTS.md` and `~/.claude/CLAUDE.md`.
- `ai-home/rules/default.rules` is the single source for both permission
  systems; the installer derives Claude Code's `permissions.allow` entries from
  it and links the directory into `CODEX_HOME`. It sits outside `ai-home/codex/`
  because both agents depend on it.
- `ai-home/codex/` contains the Codex-only files installed into `CODEX_HOME`.
  Claude Code has no counterpart directory, because its `settings.json` is
  merged rather than linked.
- The installer renders `config.toml` with machine-specific exact trust entries,
  merges Claude Code's `settings.json`, and links the other managed files.
- `.agents/skills/` contains reusable workflows linked into `AGENTS_HOME` and
  `CLAUDE_CONFIG_DIR`. Skills tied to one stack, product, or environment live in
  the separate `rwgs/ai-skills` repository and are copied into the repositories
  that need them, recording the pool commit taken.
- `scripts/install.sh` and `scripts/install.ps1` perform user-scoped
  installation.
- `codex-plugins.txt` and `claude-plugins.txt` record the plugin selectors
  installed only through the explicit plugin option, one manifest per agent
  because the two agents publish the same plugin in different marketplaces.
- `scripts/validate.sh` and installer integration tests provide local and CI
  evidence.
- `AGENTS.md`, this specification, `ROADMAP.md`, `TASKS.md`, `PLAN.md`, and
  `DECISIONS.md` define how the repository is maintained.

## Machine-owned agent state

Verified on a Windows machine running the Codex desktop application, against
`~/.codex` as Codex left it. These facts contradict what the installer currently
assumes, and `TASKS.md` carries the work to reconcile them.

- `~/.codex/rules/default.rules` accumulates interactively approved prefix rules,
  exactly as Claude Code's `settings.json` accumulates approved permissions. The
  observed file held 48 such rules and none of the repository's curated set. The
  installer links the rules directory, so after installation every approval Codex
  records is written into this repository's working tree, and the curated file is
  the only thing the machine keeps.
- `config.toml` carries machine-owned state well beyond trust entries: marketplace
  registrations, per-plugin enablement, an `mcp_servers` block holding runtime pipe
  and executable paths, `shell_environment_policy`, `[desktop]`, `personality`,
  `notify`, and `[windows] sandbox`. Rendering the file from
  `ai-home/codex/config.toml` discards all of it. Trust entries are also lost
  wherever repositories live outside `~/github`, because the render generates
  entries only from that root.
- Claude Code's permission merge is append-only. Removing a rule from
  `ai-home/rules/default.rules` leaves its derived `Bash(...)` and
  `PowerShell(...)` entries in `settings.json`, so the documented single source
  can grant a permission but cannot currently withdraw one. The file also holds
  independently approved entries, so set replacement is not safe without
  provenance.
- The PowerShell installer uses `ConvertFrom-Json -AsHashtable -Depth 100`.
  Windows PowerShell 5.1 on the reviewed machine supports neither parameter,
  while CI exercises PowerShell 7 through `pwsh`. The supported edition is not
  currently stated.

## Security and privacy

- Never track authentication files, session history, caches, logs, or runtime
  databases.
- Do not require administrator privileges for normal installation.
- Keep destructive actions narrowly scoped and require explicit authorization.
- Give GitHub Actions the minimum permissions required by each job.
- Pin third-party actions and keep those pins current through a dependency-update
  path compatible with the accepted repository workflow.

## Compatibility

- The shell installer targets Bash on Linux and macOS.
- The PowerShell installer targets Windows PowerShell 5.1 and PowerShell 7, in
  an environment capable of creating symbolic links. Symbolic-link creation
  requires Developer Mode or elevation in both editions.
- Optional tools may add validation but must not make ordinary installation
  depend on unrelated developer tooling.
- The Claude permission merge uses `python3` or `python` when present and is
  skipped with a warning otherwise, so installation never fails for lack of a
  JSON tool.
- Claude Code registers no plugin marketplace until it is first started
  interactively, so the installer adds one before installing from it. The
  `owner/repo` shorthand resolves over SSH and fails without a GitHub host key,
  so `claude-plugins.txt` carries the full HTTPS URL.

## Non-goals

- Mirroring the complete Claude/Codex home directory.
- Managing credentials, plugin caches or authentication, sessions, or caches.
- Installing plugins without an explicit opt-in.
- Replacing project-specific `AGENTS.md` or requirements.
- Installing Codex, Claude Code, RTK, or local model servers.
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
- Installer tests verify that populated Codex configuration and rule files keep
  every machine-owned entry. Removing a curated permission withdraws every
  provably installer-owned grant and preserves and reports any identical grant
  whose ownership cannot be established.
- Windows validation names and exercises every supported PowerShell edition.
- CI rejects malformed Codex rule syntax without depending on a developer's
  locally installed Codex executable.
- A dispatched run validates the latest commit on all three platforms. The
  `dependency-review` job is gated on `pull_request` and so never runs; `TASKS.md`
  carries the decision on what replaces it.
- Workflow documentation covers planning, implementation, local review, manual
  testing, and the CI evidence a single maintainer can produce.

## Unresolved questions

- How an adopting repository is told that a skill it copied from the pool has
  changed. The pool now has commits to record, so the comparison is possible; the
  reporting is not built.
- How dependency updates and dependency review work after the accepted decision
  to create no branches or pull requests. Dependabot and the current dependency
  review action both deliver through pull requests.

Closed decisions and the alternatives they rejected are recorded in
`DECISIONS.md`, including the resolved questions about user-wide Claude Code
instructions, where the optional skill pool lives, and how managed entries in a
shared file record their ownership.
