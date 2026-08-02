# AI changelog

Changes that affect what installation does to a machine: the instructions,
skills, configuration, permissions, and plugins the agents receive. Read this to
decide whether to rerun the installer after pulling. Repository-internal changes
are in the commit history.

This repository publishes no versioned releases, so entries are grouped by date,
newest first. Version headings replace the dates if tagging begins.

## 2026-08-02

- `adopt-baseline` now carries the development infrastructure into a repository as
  well as the documents and skills. It installs `.gitattributes` unconditionally,
  with the renormalising commit and the working-tree refresh that adding the file
  to an existing history needs, because a Bash script checked out with CRLF fails
  outright. It then offers the CI definition and the dependency-update
  configuration belonging to the repository's host, reading the host from the
  remote and asking wherever the hostname names no product, as an on-premise Azure
  DevOps Server never does. The CI definition is derived rather than copied: the
  triggers, permission block, concurrency group, pinned actions, and timeout
  travel, while the steps are written from the checks the repository actually has,
  and no workflow is added to a repository with no check to run. One question,
  whether the repository accepts a pull request from a bot, decides both Dependabot
  and the `pull_request` trigger. `update-baseline` offers the same three artifacts
  because it reads the offerable set from `adopt-baseline`, and adds a
  host-specific one only for the host the repository is on now. Both skills are
  linked rather than copied, so pulling is enough; there is no reason to rerun the
  installer.

## 2026-08-01

- Added `update-baseline`, a ninth installed skill, so a repository that adopted
  the baseline can be brought back up to date with it. Rerun the installer to add
  its link in both agents. It reads `.agents/baseline.json`, fast-forwards a clone
  of the recorded baseline, and works only by addition: it adds a document or a
  template section that is missing and not declined, refreshes a skill copied from
  the pool while that copy is still byte-identical to the commit recorded for it,
  and reports everything else for a human to apply rather than rewriting a line an
  adopted document already carries. The recorded commit advances only when nothing
  is left outstanding, so drift that was reported and not applied is found again on
  the next run, and a deviation the repository closed in its own `DECISIONS.md` is
  reported as kept on purpose. `adopt-baseline` hands over to it whenever a marker
  already exists.
- Adoption now leaves a record of itself. `adopt-baseline` writes a committed
  `.agents/baseline.json` holding the baseline clone URL and the full commit
  taken, the artifacts adopted, the artifacts declined with a reason for each, and
  the pool commit behind every skill copied from `rwgs/ai-skills`. The reasons are
  what let a later update tell a document the repository refused from one the
  baseline has since added, and the commits are what let it report a copied skill
  as stale. The skill also stops when a marker already exists, because adopting
  twice is not what an already-adopted repository needs. Nothing here changes a
  permission, a configuration value, or a link the installer writes, so there is no
  reason to rerun it.
- The `adopt-baseline` and `ai-project-manager` skills now agree with the
  decisions this repository has recorded. `adopt-baseline` inventories
  `DECISIONS.md` and `CHANGELOG.md`, never adopts `PLAN.md` without
  `DECISIONS.md`, because promoting the plan's closed decisions is the only thing
  that survives the plan being replaced, and creates `CHANGELOG.md` on its own
  condition rather than by repository type. `ai-project-manager` now looks for the
  `PLAN.md` it replaces and the `CHANGELOG.md` it updates, which its discovery
  step and its search glob both omitted.
- A repository now draws a pooled skill into `.agents/skills/<name>` and nowhere
  else, and Claude Code reaches it through the single ignored `.claude/skills`
  link rather than a second copy. `docs/SKILLS.md` described one wiring and
  `adopt-baseline` the other, and the two drift differently. The installed set is
  unchanged: `show-codex-reset-expiries` stays, and `docs/SKILLS.md` now says why
  a skill about an agent's own operation is installed rather than pooled. Nothing
  here changes a permission, a configuration value, or a link the installer
  writes, so there is no reason to rerun it.
- The `pr-readiness` skill now covers Azure DevOps as well as GitHub. Its
  diagnostics separate the worktree checks, which are the same everywhere, from
  a per-host table giving the commands for pull-request state, checks against
  the head commit, reviewer positions, and thread resolution. Azure DevOps has
  no equivalent of `gh pr checks`, because build validation arrives as a branch
  policy, and no `az` subcommand for comment threads at all, so the skill names
  the REST endpoint and the thread states that count as unresolved. The Azure
  DevOps commands are transcribed from Microsoft's reference and have not been
  run against a live organisation; the skill says so where an agent will read
  it. No permission, configuration, or link behavior changed, so there is
  nothing here that requires rerunning the installer.

## 2026-07-31

- Added a bootstrap for a machine with no clone. `scripts/bootstrap.sh` and
  `scripts/bootstrap.ps1` clone this repository to `~/.local/share/ai` or
  `%USERPROFILE%\Development\ai`, then install from that clone; rerunning
  fast-forwards it and installs again. `AI_INSTALL_DIR`, `AI_REPO_URL`,
  `AI_BRANCH`, and `AI_GIT_TOKEN` override the defaults. The clone is permanent,
  because the installer links into it.
- Stopped replacing the files the agents write. `~/.codex/config.toml` is merged
  key by key instead of rendered, so marketplaces, plugin enablement, MCP
  servers, `[desktop]`, `shell_environment_policy`, and trust entries Codex wrote
  itself all survive. `~/.codex/rules/` is no longer a link into this repository:
  the curated rules are merged into the machine's own `default.rules`, and an
  existing link is removed on the next install with a note saying that the
  approvals recorded through it are in this repository's working tree.
  `~/.claude/settings.json` is merged as before.
- Started withdrawing what a removed rule granted. The installer records what it
  wrote in `~/.agents/ai-install-state.json`; deleting a rule from
  `ai-home/rules/default.rules` now removes the Codex rule and both derived
  Claude entries on the next run, as long as they are unchanged since the
  installer wrote them. A grant that was already approved before the first
  install is kept and reported instead. The first run after upgrading records
  state and withdraws nothing, because nothing was recorded before it.
- Made the searched trust roots configurable with `AI_TRUST_ROOTS`, colon
  separated on Linux and macOS and semicolon separated on Windows. It still
  defaults to `~/github`.
- The shell installer's merges now need `python3` or `python`, and are all
  skipped with a warning when neither is present. Previously only the Claude
  permission merge did.
- Changed the Codex execution posture the installer writes. `config.toml` now
  carries `sandbox_mode = "workspace-write"` and `approval_policy = "on-request"`
  instead of `danger-full-access` and `never`, so Codex works inside the project
  directory and asks before acting outside it. A machine that installed an
  earlier version keeps the unrestricted pair until it reinstalls, because the
  keys sit in the machine's own `config.toml`.
- Made the Windows installer run under Windows PowerShell 5.1, the edition
  Windows ships, as well as PowerShell 7. The Claude permission merge previously
  used a parameter 5.1 does not have and failed there. The merge also keeps
  `<`, `>`, `&`, and `'` as written, which 5.1 would otherwise rewrite as escape
  sequences throughout `settings.json`.
- Fixed stale skill-link pruning on Windows. Pruning a link whose target no
  longer exists could fail with "The directory name is invalid", aborting the
  installer after it had linked the current skills but before it finished
  removing the obsolete ones. Rerun the installer on Windows if a removed skill
  is still listed. Linux and macOS were never affected.
- Changed the composition of the installed skill set. Rerun the installer to add
  the new links and prune the removed ones.
  - Added `python-scripting` for general Python work: environment detection, ruff,
    pytest, type checking, and cross-platform path and encoding handling.
  - Added `web-verification`, the stack-agnostic half of `web-development`:
    serving locally, port hygiene, cache and service-worker staleness, and
    browser evidence for user-visible changes. It applies to a site with any
    backend, where the rules were previously reachable only behind a JS/TS
    trigger.
  - Removed `python-ai`, `rust-cli`, and `web-development`. All three moved to the
    new optional pool at `rwgs/ai-skills`, which also holds the sysadmin,
    infrastructure, container, Forgejo, Hugo, and mdBook skills. A language skill
    is installed when an agent reaches for that language as a tool in any
    repository, and pooled when the language is the project's stack.
    `python-ai` covered Python AI applications only, so `python-scripting` rather
    than its removal is what changes general Python coverage.
- Added one rule to the shared global instructions: detect a project's package
  manager from its lockfile before installing, because running the wrong one
  rewrites it. This was the only rule in `web-development` that mattered without
  the skill loaded, and it now also covers a repository carrying a lockfile
  without being a JavaScript or TypeScript project.
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
