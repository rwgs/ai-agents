# AI specification

## Problem

A Claude Code or Codex home directory holds two things at once: configuration
worth carrying between machines, and the credentials, sessions, caches, and
runtime state that belong only to the machine it sits on. Nothing separates
them, so there is no safe way to copy the first without dragging the second
along. Both agents also need the same instructions and the same reusable
workflows everywhere, without either displacing what an individual project
requires.

## Users

One developer working across Linux, macOS, and Windows, who wants the same
Claude Code and Codex baseline in every repository, installed without putting
the agent state already on the machine at risk.

## Required behavior

- Install this repository's global instructions, configuration, rules,
  local-model profiles, and reusable skills for both agents.
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
- Show what an installation would change without touching the target system.
- Back up an existing managed target under a timestamped name before replacing
  it.
- Preserve machine-owned Codex configuration and interactively approved rules
  while applying repository-owned defaults.
- Default Codex to a workspace-write sandbox that asks before acting outside it,
  so the baseline never escalates a machine's execution posture silently.
- Touch no credential, session, history file, cache, plugin state, or runtime
  database, unless plugin installation was explicitly requested.
- Run repeatedly without rewriting a link that is already correct.
- Ship project-planning templates, and keep planning separate from pull-request
  readiness.
- Adopt the baseline into a repository, and bring an already-adopted repository
  up to date when the baseline changes, without overwriting what that repository
  customised.
- Check the repository's own structure, configuration syntax, skill metadata,
  documentation consistency, and installer behavior.
- Stop managing a permission when it is removed from the curated rule source.
  Never delete an existing grant unless installer ownership is provable; report
  an ambiguous identical grant for conservative resolution.
- Run Linux, macOS, and Windows validation on every push to the default branch,
  on manual dispatch, and on the pull requests Dependabot opens to bump the
  pinned actions. Humans open none.
- Serve a repository hosted on GitHub or on Azure DevOps, whether that is the
  hosted service or an on-premise server. Only a named host-specific artifact
  may assume a host; everything else states the capability it needs and names
  the mechanism per host.

## Architecture

- `ai-home/AGENTS.md` is the shared global instruction file, linked to
  `~/.codex/AGENTS.md` and `~/.claude/CLAUDE.md`.
- `ai-home/rules/default.rules` is the single source for both permission
  systems; the installer merges it into `CODEX_HOME/rules/default.rules` and
  derives Claude Code's `permissions.allow` entries from it. It sits outside
  `ai-home/codex/` because both agents depend on it.
- Only a single-token `prefix_rule` pattern derives a Claude Code grant. A
  multi-token pattern such as `["az", "repos"]` is valid Codex syntax and passes
  validation, but both the Python and the PowerShell derivation match one token,
  so it reaches Codex alone and Claude Code keeps prompting. A rule scoped to a
  subcommand therefore needs the derivation extended first.
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
  that need them, recording the pool commit taken. A skill about an agent's own
  operation is installed rather than pooled, because it has no repository to be
  copied into. An adopting repository holds one copy of each skill, under
  `.agents/skills/`, and exposes it to Claude Code through an ignored
  `.claude/skills` link rather than a second copy.
- An adopting repository records what it took in a committed
  `.agents/baseline.json`: the baseline clone URL, the full commit taken and its
  date, the artifacts adopted, the artifacts declined with a reason for each, and
  the pool commit behind each skill copied from `rwgs/ai-skills`. It is what an
  update compares against, so every entry names something checkable in that
  repository. This repository has no marker, because it is the baseline.
- `scripts/install.sh` and `scripts/install.ps1` install into the user's own
  directories. `scripts/bootstrap.sh` and `scripts/bootstrap.ps1` obtain the
  clone they install from, so a machine with nothing checked out can run one
  command. Because the installer links into the clone, the bootstrap keeps it at
  a fixed location and fast-forwards it on a rerun rather than cloning again.
- `codex-plugins.txt` and `claude-plugins.txt` record the plugin selectors
  installed only through the explicit plugin option, one manifest per agent
  because the two agents publish the same plugin in different marketplaces.
- `scripts/validate.sh` and the installer integration tests are where local and
  CI evidence comes from.
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

- Never track an authentication file, session history, cache, log, or runtime
  database.
- Require no administrator privileges for an ordinary installation.
- Keep a destructive action narrowly scoped, and require it to be asked for.
- Grant each GitHub Actions job only the permissions it needs.
- Pin third-party actions and keep those pins current through a dependency-update
  path compatible with the accepted repository workflow.

## Compatibility

- The shell installer runs under Bash on Linux and macOS.
- The PowerShell installer targets Windows PowerShell 5.1 and PowerShell 7, in
  an environment capable of creating symbolic links. Symbolic-link creation
  requires Developer Mode or elevation in both editions.
- An optional tool may add validation, but ordinary installation must never come
  to depend on unrelated developer tooling.
- The shell installer's merges into `config.toml`, the Codex rule file, and
  `settings.json` use `python3` or `python` when present and are skipped
  together with a warning otherwise, so installation never fails for lack of an
  interpreter. The PowerShell installer implements the same merges natively.
- Claude Code registers no plugin marketplace until it is first started
  interactively, so the installer adds one before installing from it. The
  `owner/repo` shorthand resolves over SSH and fails without a GitHub host key,
  so `claude-plugins.txt` carries the full HTTPS URL.
- Neither installer has a TOML writer to call. Python's `tomllib` reads TOML and
  does not write it, and PowerShell has no TOML support at all, so the
  `config.toml` merge is textual on both sides and refuses whatever it cannot
  locate rather than reformatting the file.
- This repository is hosted on GitHub, and its GitHub Actions workflows are the
  verified three-platform gate. `azure-pipelines.yml` runs the same gate on
  Azure DevOps and is unverified, because neither an organisation nor a server
  is in use. Its agent pool is parameterised: Azure DevOps Server has no
  Microsoft-hosted pool, so a hard-coded one would be cloud-only.
- The installer contacts no Git host. Trust discovery keys on the presence of a
  `.git` directory beneath `AI_TRUST_ROOTS`, so a worktree is trusted the same
  way whatever it was cloned from, and `AI_REPO_URL` selects where the bootstrap
  clones this repository from.

## Non-goals

- Mirroring the complete Claude/Codex home directory.
- Managing credentials, sessions, caches, or plugin authentication.
- Installing a plugin that was not explicitly opted into.
- Replacing a project's own `AGENTS.md` or its requirements.
- Installing Codex, Claude Code, RTK, or local model servers.
- Adding a security scanner that does not support the languages this repository
  is written in.
- Verifying any Azure DevOps behavior against a live organisation or server
  while neither is in use.
- Abstracting the Git host behind one interface, or dispatching on the remote
  URL. The hosts differ in which features exist, not only in how they are
  spelled, so the differences are named rather than hidden.

## Acceptance criteria

- A clean checkout passes `./scripts/validate.sh`.
- The Linux and macOS installer integration tests cover dry-run safety, backup
  preservation, correct links, generated GitHub trust entries, and idempotence,
  all inside isolated temporary directories.
- Windows CI covers the equivalent PowerShell installer behavior.
- The installer tests cover plugin opt-in and dry-run behavior without
  contacting a live marketplace.
- Installer tests verify that the bootstrap clones, installs from the clone, and
  fast-forwards an existing clone on a rerun, using a local copy of the
  repository so the test needs no network.
- Every skill has valid front matter, and the documented inventory matches the
  directories that exist.
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
- No file outside a named host-specific artifact requires, is named for, or
  states a rule only reachable on one Git host.

## Unresolved questions

- How an adopting repository is told that a skill it copied from the pool has
  changed. Both inputs to the comparison now exist, the pool's commits and the
  copy's recorded commit in `.agents/baseline.json`; the reporting is not built.
- How dependency updates and dependency review work after the accepted decision
  to create no branches or pull requests. Dependabot and the current dependency
  review action both deliver through pull requests. Azure DevOps is the same
  question again with no Dependabot to answer it.
- Which Azure DevOps features stand in for the GitHub ones the security baseline
  names. The hosted service sells GitHub Advanced Security for Azure DevOps;
  whether an equivalent reaches Azure DevOps Server was not established here,
  and none of it has been verified against a live instance.

Closed decisions and the alternatives they rejected are recorded in
`DECISIONS.md`, including the resolved questions about user-wide Claude Code
instructions, where the optional skill pool lives, and how managed entries in a
shared file record their ownership.
