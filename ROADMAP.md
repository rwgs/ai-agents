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
- Add explicit, cross-platform installation for selected Codex plugins without
  making ordinary installs mutate plugin state.
- Render exact trusted-project entries for every Git worktree beneath the
  current user's `~/github` directory.

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

## Phase 4: Enforced repository governance

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
