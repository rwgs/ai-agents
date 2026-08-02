# AI roadmap

## Phase 1: Portable Codex foundation

Status: Reopened. The state-preserving remediation is the current Phase 4.

### Outcome

Global instructions, configuration, rules, local-model profiles, and skills
install from this repository without displacing the private runtime state Codex
keeps beside them.

### Exit criteria

- The Linux, macOS, and Windows installers each offer a preview and take
  timestamped backups.
- Validation rejects private runtime state and malformed portable configuration.

## Phase 2: Workflow alignment

Status: Complete as originally scoped. The pull-request artifacts it added were
reconciled on 2026-07-31: bots may open pull requests, humans may not.

### Outcome

The repository and its reusable skills carry the whole workflow: planning,
implementation, review, manual testing, and merge.

### Included work

- Add the repository's planning documents and the reusable project templates.
- Split project planning from pull-request readiness.
- Add cross-platform installer integration tests and validation CI.
- Add Dependabot coverage, dependency review, and change-evidence prompts. The
  later no-pull-request decision kept Dependabot, whose pull requests are the
  only way an action pin gets refreshed, and removed the unreachable
  dependency-review job and the pull-request template.
- Bring the Claude routing and the workflow documentation into agreement.
- Add explicit, cross-platform installation for selected plugins in both agents
  without making ordinary installs mutate plugin state.
- Generate exact trusted-project entries for every Git worktree beneath the
  current user's `~/github` directory. Phase 4 replaced the rendered file with a
  merge and made the searched roots configurable.
- Record closed decisions and the alternatives they rejected in `DECISIONS.md`,
  and promote them out of `PLAN.md` before it is replaced.

### Risks

- Windows symbolic-link behavior varies with permissions and host policy.
- A repository-level GitHub Actions app setting can prevent push runs even when
  the workflow YAML has the correct trigger; Phase 4 owns live verification.

### Exit criteria

- Local validation passes, skills included.
- The Linux installer integration tests pass locally.
- The Windows installer integration tests pass in CI.
- The final diff carries nothing but workflow-alignment changes.

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

Status: Blocked. Everything implementable is done and verified on three
platforms. What remains needs code scanning enabled on the repository and
Windows Developer Mode or an elevated shell.

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
  dispatch. Met on 2026-08-01.
- A dry run and then a real install on the reviewed Windows machine complete
  without losing its pre-existing state.

## Phase 5: A tree of its own

Status: Complete. Every restatement is done, and push run `30720357277` proved the
four restated installer functions on all three platforms.

### Outcome

Every line in the repository is either written for this repository or too
functional to have an author, so publishing it depends on nobody else's licence.

### Included work

- Replace the inherited prose file by file, prioritised by how much of it
  survives, starting with the two instruction files.
- Leave functional lines alone: command invocations, configuration keys, rule
  entries that are only command names, ignore patterns, workflow boilerplate.
- Re-measure at the end and record what stays attributed and why.

### Dependencies and risks

- These are working instructions that `scripts/validate.sh` partly enforces, so
  a restatement that quietly drops a rule is a regression, not a rewrite.
- Rewriting for its own sake is churn. A file is touched because its prose is
  inherited, not because a line is attributed to an upstream commit.

### Exit criteria

- The instruction files, skills, planning documents, and README carry no
  inherited prose.
- A `git blame` census shows only functional remainders, each named.
- Local validation and a three-platform run pass with the restated files.

## Phase 6: Re-appliable repository baseline

Status: Complete. Three skills partition the work by precondition:
`start-repository` for a repository with nothing to reconcile, `adopt-baseline` for
one that already holds work, and `update-baseline` for one carrying the marker the
first two write. The loop was run end to end on a scratch repository on 2026-08-02,
which found and fixed four defects in the instructions, one of them the reason the
convergence criterion could not have been met as written.

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
- Propagating CI and dependency-update configuration is host-specific, so this
  phase depends on Phase 8's separation despite the higher number. Adopting a
  GitHub-shaped propagation first and unpicking it afterwards costs more than
  taking the host branch before the propagation is written.

### Exit criteria

- A scratch repository adopts the baseline, the baseline then changes, and
  re-applying brings the repository up to date without losing any customisation.
- Re-applying a second time with no baseline change reports nothing to do.
- Adoption and update are covered by the same validation the installer has.

## Phase 7: Enforced repository governance

Status: Planned

### Outcome

GitHub settings enforce the validation and scanning the repository documents,
without gates a single maintainer committing to `main` cannot satisfy.

### Included work

- Confirm secret scanning, push protection, and the selected dependency-update
  mechanism.
- Enable code scanning so the CodeQL workflow can report on this private
  repository.
- Reconcile reusable readiness guidance with the single-maintainer path where an
  independent human review is unavailable.

### Exit criteria

- Every push to `main` produces a validation run, and its conclusion is visible
  without a manual dispatch.
- Secret scanning and push protection are confirmed enabled, and the retained
  dependency-update mechanism is verified operational.
- Dependency updates have a documented path that does not contradict the
  accepted workflow.
- No documented gate or required repository artifact depends on a human pull
  request or a second reviewer.
- CodeQL results are visible, or the reason they cannot be is recorded.
- Each enforced gate says whether Azure DevOps offers it, and an adopting
  repository on that host is told what it gets instead of being told to
  configure a GitHub feature.

## Phase 8: Host-neutral version control

Status: Complete. Push run `30724005165` on `3749b3e` passed `ubuntu-latest`,
`macos-latest`, and `windows-latest`, which was the last thing outstanding. It ran
before Phase 6's propagation work despite the higher number, because that work is
host-specific and the numbering is historical.

### Outcome

The baseline serves a repository hosted on GitHub or on Azure DevOps, hosted
service or on-premise server, without a GitHub name appearing anywhere the host
is irrelevant.

### Included work

- State the security baseline as capabilities, with a table naming the mechanism
  on each host and the cases where one host has none.
- Stop `scripts/validate.sh` treating the `.github/` layout as the definition of
  a valid repository.
- Ship `azure-pipelines.yml` running the same three-platform gate as the Actions
  workflow, with a parameterised agent pool so an on-premise server can supply
  its own, labelled unverified.
- Make `pr-readiness` state its pull-request semantics host-neutrally and name
  the commands per host, after reading the Azure CLI command surface rather than
  recalling it.
- Allow the Azure DevOps command-line tooling in the curated rules alongside
  `gh`.
- Document the Azure DevOps clone forms for `AI_REPO_URL`, including the
  on-premise certificate-authority case.

### Dependencies and risks

- Neither Azure DevOps variant is in use, so nothing host-facing can be verified
  end to end. The pipeline is expected to need correction on its first real run.
- The Azure CLI is installed on neither shell here. Writing an `az` command
  without reading its surface first would violate the repository's own rule
  against recalled commands, so two tasks are blocked behind installing it.
- Azure DevOps Server has no Microsoft-hosted agents, no Dependabot, and no
  confirmed code-scanning product. Rules that assume any of them cannot simply
  be renamed.

### Exit criteria

- No file outside a named host-specific artifact requires, is named for, or
  states a rule only reachable on one Git host.
- Local validation and a three-platform GitHub run pass with the changes.
- Every Azure DevOps artifact states that it is unverified and what would verify
  it.
