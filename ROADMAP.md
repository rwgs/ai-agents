# AI roadmap

## Phase 1: Portable Codex foundation

Status: Complete

### Outcome

Portable global instructions, configuration, rules, local-model profiles, and
skills install without replacing private Codex runtime state.

### Exit criteria

- Linux, macOS, and Windows installers support preview and timestamped backups.
- Repository validation rejects private runtime state and malformed portable
  configuration.

## Phase 2: Workflow alignment

Status: In progress

### Outcome

The repository and reusable skills encode the complete planning, implementation,
review, manual-testing, and merge workflow.

### Included work

- Add repository planning documents and reusable project templates.
- Separate project planning from pull-request readiness.
- Add cross-platform installer integration tests and pull-request CI.
- Add Dependabot coverage, dependency review, and PR evidence prompts.
- Align Claude routing and workflow documentation.
- Add explicit, cross-platform installation for selected plugins in both agents
  without making ordinary installs mutate plugin state.
- Render exact trusted-project entries for every Git worktree beneath the
  current user's `~/github` directory.
- Record closed decisions and the alternatives they rejected in `DECISIONS.md`,
  and promote them out of `PLAN.md` before it is replaced.

### Risks

- Windows symbolic-link behavior can differ by permissions and host policy.
- Required GitHub checks cannot be configured until their final names exist on
  the default branch.

### Exit criteria

- Local validation and skill validation pass.
- Linux installer integration tests pass locally.
- Windows installer integration tests pass in CI.
- The final diff contains only workflow-alignment changes.

## Phase 3: Claude and Codex parity

Status: In progress

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

## Phase 4: Re-appliable repository baseline

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
  `.gitattributes`, and optionally the validation workflow, Dependabot
  configuration, and pull-request template.
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

## Phase 5: Enforced repository governance

Status: Planned

### Outcome

GitHub settings enforce the review and validation gates documented by the
repository.

### Included work

- Require pull requests and successful validation checks.
- Require conversation resolution.
- Require an independent approval when repository ownership makes that
  practical.
- Confirm secret scanning, push protection, Dependabot, and dependency review.

### Exit criteria

- The repository ruleset protects the default branch.
- Required checks run against the latest pull-request commit.
- The documented merge gate matches GitHub settings.
