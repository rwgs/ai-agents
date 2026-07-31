# Repository review and planning reconciliation

Approach for the review currently in flight. Replaced when the next non-trivial
change begins, so anything that must outlive this review is promoted first:
verified product facts to `SPEC.md`, actionable work to `TASKS.md`, and closed
choices to `DECISIONS.md`.

## Problem

The repository's local gate passes, but its planning documents and user guidance
do not describe one coherent current state:

- Several sections in `TASKS.md` are labeled current although all of their work
  is complete, while the unsafe installation behavior is filed as later work.
- Phase 1 claims that installation preserves private Codex state even though the
  current installer replaces `config.toml` and links a rules directory that
  Codex writes into.
- The Claude permission merge only adds entries, so removing a curated rule does
  not withdraw its derived permission as the documentation promises.
- Accepted no-branch and no-pull-request workflow decisions conflict with
  Dependabot, dependency review, the required pull-request template, and an
  unconditional independent-review step in `pr-readiness`.
- Adoption and skill-pool guidance disagree about the planning documents to take
  and whether project-local skills are copied twice or exposed from one source.

## Constraints discovered

- The worktree began clean on `main` at
  `b6591810d3648f716624c12848a3c57c345ab32a`, matching `origin/main`.
- The complete WSL gate passed before editing:
  `installer integration test passed` and
  `validation passed: 8 skills checked`.
- The installed Codex CLI is `0.146.0-alpha.9.2`. Its strict-config-capable
  `exec` command accepted the repository's base `config.toml`, and
  `codex execpolicy check` accepted `default.rules` and allowed `rtk gain`.
- The current official Codex manual describes
  `approval_policy = "never"` plus
  `sandbox_mode = "danger-full-access"` as full access, recommends the
  workspace-write/on-request pair as the lower-risk local preset, and confirms
  that TUI approvals are written to
  `~/.codex/rules/default.rules`.
- Windows PowerShell `5.1.26100.8875` is present on the reviewed machine, and
  its `ConvertFrom-Json` has neither `AsHashtable` nor `Depth`. The
  installer uses both; CI uses PowerShell 7 through `pwsh`.
- GitHub live status could not be refreshed because the installed connector is
  not connected and `gh` is unavailable. The automatic-push task therefore
  remains pending on its recorded evidence instead of being guessed complete.
- No installer behavior changes in this review. A `CHANGELOG.md` entry would
  incorrectly imply that pulling this commit makes installation safe.

## Approach

- Add an immediate README warning against installing into a populated Codex home.
- Correct the README and `docs/AGENT_LAYOUT.md` claim that rerunning after a rule
  removal currently changes both agents.
- Extend `SPEC.md` with the verified state-ownership, permission-removal, and
  PowerShell compatibility facts plus acceptance criteria and unresolved
  decisions.
- Reconcile `ROADMAP.md`: close the historically completed workflow phases,
  reopen the false state-preservation claim, and make safe installation plus
  reliable push validation the single current phase.
- Reorganize `TASKS.md` so only one phase is current, completed work is not
  mixed with open tasks, each new defect has an observable acceptance condition,
  speculative MCP work is not scheduled, and no-PR/adoption contradictions are
  explicit future decisions.
- Leave implementation and live GitHub settings unchanged. The ownership model,
  execution posture, PowerShell support floor, and bot-PR policy each materially
  change the result and require their own recorded decision before code changes.
  Claude's unlabelled permission set may make identical managed and independent
  grants indistinguishable, so the decision must define a conservative reported
  outcome rather than assume provenance can always be reconstructed.

## Trade-offs

- The review prioritizes preventing state loss and restoring trustworthy
  validation over the re-applicable baseline. This delays new adoption features
  until the baseline being propagated is safe.
- Historical completed tasks remain visible, including work later superseded.
  Their wording is clarified where a later audit proved that the original
  "safe" claim was too broad.
- The README warning is intentionally stronger than the existing backup claim.
  Backups make replacement recoverable; they do not make replacement
  state-preserving.
- MCP management remains visible as a candidate but is removed from scheduled
  work until a concrete requirement exists.

## Verification

- Run `./scripts/validate.sh` under WSL after the documentation edits.
- Inspect the complete diff and confirm that only planning and safety guidance
  changed.
- Search for multiple current phases, stale phase numbers, and unqualified
  populated-home install guidance.
- Confirm `ROADMAP.md`, `TASKS.md`, and `SPEC.md` agree on the current phase,
  unresolved decisions, and exit criteria.
- Do not mark live GitHub settings, a real Windows install, or cross-platform CI
  as verified; none can be established by this documentation-only change.
