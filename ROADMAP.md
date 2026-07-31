# AI roadmap

## Phase 1: Portable Codex foundation

Status: Reopened. The state-preserving remediation is the current Phase 4.

### Outcome

Portable global instructions, configuration, rules, local-model profiles, and
skills install without replacing private Codex runtime state.

### Exit criteria

- Linux, macOS, and Windows installers support preview and timestamped backups.
- Repository validation rejects private runtime state and malformed portable
  configuration.

## Phase 2: Workflow alignment

Status: Complete as originally scoped. No-pull-request governance cleanup is in
Phase 6.

### Outcome

The repository and reusable skills encode the complete planning, implementation,
review, manual-testing, and merge workflow.

### Included work

- Add repository planning documents and reusable project templates.
- Separate project planning from pull-request readiness.
- Add cross-platform installer integration tests and validation CI.
- Add Dependabot coverage, dependency review, and change-evidence prompts. The
  later no-pull-request decision leaves the PR-only pieces for Phase 6.
- Align Claude routing and workflow documentation.
- Add explicit, cross-platform installation for selected plugins in both agents
  without making ordinary installs mutate plugin state.
- Render exact trusted-project entries for every Git worktree beneath the
  current user's `~/github` directory.
- Record closed decisions and the alternatives they rejected in `DECISIONS.md`,
  and promote them out of `PLAN.md` before it is replaced.

### Risks

- Windows symbolic-link behavior can differ by permissions and host policy.
- A repository-level GitHub Actions app setting can prevent push runs even when
  the workflow YAML has the correct trigger; Phase 4 owns live verification.

### Exit criteria

- Local validation and skill validation pass.
- Linux installer integration tests pass locally.
- Windows installer integration tests pass in CI.
- The final diff contains only workflow-alignment changes.

## Phase 3: Claude and Codex parity

Status: Complete as originally scoped. Newly discovered ownership and removal
defects are in Phase 4.

### Outcome

One repository serves both agents. Instructions, skills, and the command
allowlist have a single hand-authored source installed into whichever locations
each agent actually reads.

### Included work

- Split `ai-home/` into a shared instruction file and per-agent configuration.
- Link the shared instruction file to `~/.codex/AGENTS.md` and
  `~/.claude/CLAUDE.md`.
- Link every skill into `~/.claude/skills/` alongside `~/.agents/skills/`.
- Derive Claude Code permissions from `default.rules` and merge them into
  `settings.json` without discarding existing state.
- Reduce the repository-local `CLAUDE.md` to an `@AGENTS.md` import and move the
  RTK catalog into `docs/RTK.md`.

### Risks

- `~/.claude/settings.json` accumulates interactively approved permissions, so a
  careless write would destroy real user state.
- Windows symbolic-link creation still depends on Developer Mode or elevation.
- Claude Code's `CLAUDE_CONFIG_DIR` override is undocumented, so installer tests
  must set it explicitly to stay off the real home directory.

### Exit criteria

- Local validation and installer integration tests pass on Linux and macOS.
- Windows installer integration tests pass in CI.
- A merge into a populated `settings.json` preserves every existing key and
  allow entry, and reruns report no change.

## Phase 4: State-preserving installation and reliable validation

Status: In progress

### Outcome

Installing into an active Claude/Codex setup changes only repository-owned
defaults, preserves machine-owned state and independent approvals, and produces
validation automatically on every push to `main`.

### Included work

- Merge portable Codex configuration into the active `config.toml` instead of
  replacing unrelated keys, and discover trust roots that match where
  repositories actually live.
- Reconcile curated Codex rules and derived Claude permissions with explicit
  ownership, so additions and removals are both safe.
- Decide whether the installed Codex default is an unrestricted personal preset
  or a sandboxed, approval-capable baseline, then align the specification,
  instructions, and configuration with that choice.
- State the supported PowerShell editions and exercise them in validation.
- Make malformed rules and executable skill scripts fail validation in CI.
- Restore and verify automatic GitHub Actions runs for pushes to `main`.
- Perform a real first install only after the state model is safe and Windows
  symbolic-link creation is available.

### Dependencies and risks

- `config.toml`, Codex rules, and Claude permissions mix repository defaults with
  state written by the applications. Replacing a set or file can silently lose
  data; append-only behavior can silently retain a withdrawn permission.
- Windows link creation requires Developer Mode or elevation on the reviewed
  machine.
- The GitHub Actions automatic check-suite preference has no read endpoint, so
  proving the push trigger requires changing the live setting and observing a
  subsequent push.

### Exit criteria

- Seeded machine-owned config keys, trust entries, Codex approvals, Claude
  settings, and independent permissions all survive installation and reruns.
- Removing one curated rule removes only provably installer-owned grants in both
  agents and reports any ambiguous identical grant without deleting it.
- Every supported PowerShell edition passes its installer test.
- A push to `main` creates a three-platform validation run without a manual
  dispatch.
- A dry run and then a real install on the reviewed Windows machine complete
  without losing its pre-existing state.

## Phase 5: Re-appliable repository baseline

Status: Planned

### Outcome

A repository can adopt the baseline and later be brought up to date with it. The
same path serves a new project, a project already written, and one cloned or
forked and since developed further.

### Included work

- Record what a repository adopted: the baseline commit, the documents taken,
  and the pieces declined. Without a marker an update cannot tell customisation
  from drift.
- Add an update mode, separate from first adoption, with additive semantics. It
  adds documents and sections that are missing and reports convention drift for
  a human to apply. It never overwrites an adopted document.
- Propagate the development infrastructure that adoption currently skips:
  `.gitattributes`, the optional validation workflow, and the dependency-update
  configuration retained by Phase 6.
- Name a location for optional skills and document how a repository draws from
  it, so a stack-specific skill can be added per project rather than installed
  everywhere.
- Give a new repository an entry point of its own, rather than reaching for a
  skill named for adopting an existing one.

### Dependencies and risks

- Adopted documents are customised after they land, so an update that overwrites
  destroys work. Additive-only semantics are a correctness requirement, not a
  preference.
- A marker that drifts from what is actually in the repository is worse than no
  marker, because it would report an update as applied when it was not.
- `.gitattributes` is the highest-value item: without it CRLF makes Bash fail
  outright, which this repository hit in its own checkout.

### Exit criteria

- A scratch repository adopts the baseline, the baseline then changes, and
  re-applying brings the repository up to date without losing any customisation.
- Re-applying a second time with no baseline change reports nothing to do.
- Adoption and update are covered by the same validation the installer has.

## Phase 6: Enforced repository governance

Status: Planned

### Outcome

GitHub settings enforce the validation and scanning the repository documents,
without gates a single maintainer committing to `main` cannot satisfy.

### Included work

- Confirm secret scanning, push protection, and the selected dependency-update
  mechanism.
- Reconcile Dependabot, dependency review, and the pull-request template with the
  accepted no-branch, no-pull-request workflow.
- Reconcile reusable readiness guidance with the single-maintainer path where an
  independent human review is unavailable.

### Exit criteria

- Every push to `main` produces a validation run, and its conclusion is visible
  without a manual dispatch.
- Secret scanning and push protection are confirmed enabled, and the retained
  dependency-update mechanism is verified operational.
- Dependency updates have a documented path that does not contradict the
  accepted workflow.
- No documented gate or required repository artifact depends on a pull request
  or a second reviewer.
