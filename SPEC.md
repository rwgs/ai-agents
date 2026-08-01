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
- Trust each configured root and every Git worktree discovered recursively
  beneath it on each installation, defaulting to the current user's `~/github`
  and configurable through `AI_TRUST_ROOTS`.
- Install on a machine with no copy of the repository by cloning it to a fixed
  location and installing from that clone, with optional token authentication
  while the repository is private. The same command updates an existing clone.
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
  on manual dispatch, and on the pull requests Dependabot opens to bump the
  pinned actions. Humans open none.

## Architecture

- `ai-home/AGENTS.md` is the shared global instruction file, linked to
  `~/.codex/AGENTS.md` and `~/.claude/CLAUDE.md`.
- `ai-home/rules/default.rules` is the single source for both permission
  systems; the installer merges it into `CODEX_HOME/rules/default.rules` and
  derives Claude Code's `permissions.allow` entries from it. It sits outside
  `ai-home/codex/` because both agents depend on it.
- `ai-home/codex/` contains the Codex-only files installed into `CODEX_HOME`.
  Claude Code has no counterpart directory, because its `settings.json` is
  merged rather than linked.
- `config.toml`, the Codex rule file, and Claude Code's `settings.json` are
  shared with the agents, so they are merged entry by entry and never linked or
  replaced. `AGENTS_HOME/ai-install-state.json` records what the installer
  wrote, and that record is what allows a later run to update or withdraw an
  entry. Everything else managed is a symbolic link.
- `scripts/merge-agent-state.py` implements the merge for the shell installer;
  `scripts/install.ps1` implements the same rules natively for Windows.
- `.agents/skills/` contains reusable workflows linked into `AGENTS_HOME` and
  `CLAUDE_CONFIG_DIR`. Skills tied to one stack, product, or environment live in
  the separate `rwgs/ai-skills` repository and are copied into the repositories
  that need them, recording the pool commit taken.
- `scripts/install.sh` and `scripts/install.ps1` perform user-scoped
  installation. `scripts/bootstrap.sh` and `scripts/bootstrap.ps1` obtain the
  clone they install from, so a machine with nothing checked out can run one
  command. Because the installer links into the clone, the bootstrap keeps it at
  a fixed location and fast-forwards it on a rerun rather than cloning again.
- `codex-plugins.txt` and `claude-plugins.txt` record the plugin selectors
  installed only through the explicit plugin option, one manifest per agent
  because the two agents publish the same plugin in different marketplaces.
- `scripts/validate.sh` and installer integration tests provide local and CI
  evidence.
- `AGENTS.md`, this specification, `ROADMAP.md`, `TASKS.md`, `PLAN.md`, and
  `DECISIONS.md` define how the repository is maintained.

## Machine-owned agent state

Verified on a Windows machine running the Codex desktop application, against
`~/.codex` and `~/.claude` as the agents left them. These facts define what the
installer must preserve.

- `~/.codex/rules/default.rules` accumulates interactively approved prefix rules,
  exactly as Claude Code's `settings.json` accumulates approved permissions. The
  observed file held 48 such rules and none of the repository's curated set. The
  rules directory is therefore the machine's and is never a link into this
  repository.
- `config.toml` carries machine-owned state well beyond trust entries: marketplace
  registrations, per-plugin enablement, an `mcp_servers` block holding runtime pipe
  and executable paths, `shell_environment_policy`, `[desktop]`, `personality`,
  `notify`, and `[windows] sandbox`. It also carries trust entries Codex wrote
  itself, in literal-string form and lower case, for repositories outside
  `~/github`.
- Neither file format records who wrote an entry, and both agents can write an
  entry spelled exactly like a curated one: the observed `settings.json` held 34
  agent-written entries in the derived `Tool(command *)` shape, and Codex's own
  first rule was a single-token prefix like the curated ones. Provenance
  therefore has to be recorded outside the files.
- Windows PowerShell 5.1 rejects `ConvertFrom-Json -AsHashtable` and serializes
  `<`, `>`, `&`, and `'` as Unicode escapes where PowerShell 7 writes the
  characters. Both editions are supported, so the installer avoids the first and
  normalizes the second.

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
- The shell installer's merges into `config.toml`, the Codex rule file, and
  `settings.json` use `python3` or `python` when present and are skipped
  together with a warning otherwise, so installation never fails for lack of an
  interpreter. The PowerShell installer implements the same merges natively.
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
- Installer tests verify that the bootstrap clones, installs from the clone, and
  fast-forwards an existing clone on a rerun, using a local copy of the
  repository so the test needs no network.
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
- A dispatched run validates the latest commit on all three platforms, and the
  Windows job runs the installer test under every supported PowerShell edition.
- CodeQL analyses every language it supports that the repository contains.
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
