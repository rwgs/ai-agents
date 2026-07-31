# A decisions log for this repository and the planning templates

Approach for the change currently in flight. Replaced when the next non-trivial
change begins, so anything that must outlive this change is promoted first:
decisions that constrain future work to `DECISIONS.md`, and verified facts that
change how the project is understood to `AGENTS.md` or `SPEC.md`.

## Problem

`PLAN.md` asks for rejected alternatives and abandoned approaches "so they are
not retried", then declares itself replaced when the next non-trivial change
begins. Nothing carried that rationale forward, in this repository or in the
`ai-project-manager` templates it ships. The previous plan held a verified
finding about Claude Code marketplace registration and the reasoning behind two
plugin manifests, and both were about to be overwritten. `SPEC.md` showed the
same gap from the other side: its "Unresolved questions" section contained a
closed decision, because there was nowhere else to put one.

## Constraints discovered

- `scripts/validate.sh` enforces a required-file list, so a new top-level
  document must be registered there or the repository and the validator drift.
- `docs/WORKFLOW.md` states that a coding agent must not be relied on to
  discover a document by filename, so an unrouted document is inert regardless
  of its content.
- The validator's skill checks compare `docs/SKILLS.md` against
  `.agents/skills/`, but nothing validates the contents of a skill's
  `assets/`, so template additions cost no validator change.
- `./scripts/validate.sh` fails in this environment at the installer
  integration test, which cannot create symbolic links under Git Bash on
  Windows. The failure is identical on a clean tree and is covered by
  `scripts/test-install.ps1` in CI.

## Approach

One file per repository, not one file per decision:

- `DECISIONS.md` at the repository root, append-only and newest first, with a
  status line so a reversal supersedes an entry instead of rewriting it.
- An entry bar: the decision constrains future work and its rationale cannot be
  recovered by reading the code.
- A write trigger in `AGENTS.md` maintenance and `docs/WORKFLOW.md` step 11, so
  promotion happens before `PLAN.md` is replaced rather than when someone
  remembers.
- The same template in `ai-project-manager`, wired into the skill so it is read
  (step 2 and the diagnostics glob), written (step 8), guarded (a safety rule
  against re-proposing a rejected approach), and checked (a validation item).

## Trade-offs

- A single file rather than numbered ADRs under `docs/decisions/`. The
  conventional form is file-per-decision, but that does not match a flat
  planning set, and the skill's discovery step looks at the repository root
  first. Revisit if entries outgrow one readable file.
- Six planning documents rather than five. The alternative candidates and the
  reasons they were rejected are recorded in `DECISIONS.md` rather than left to
  be re-argued.
- `DECISIONS.md` is now a required file, so every repository adopting this
  layout must have one. The templates create it only when a decision meets the
  bar, so adopting projects are not forced to carry an empty file.

## Verification

- `./scripts/validate.sh`, confirming the required-file, skill, and
  documentation checks pass and that the only failure is the pre-existing
  installer symlink error reproduced on a clean tree.
- `scripts/test-install.ps1` in CI for the installer behavior this environment
  cannot exercise.
