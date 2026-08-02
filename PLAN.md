# Reconcile the readiness gate with the single-maintainer path

Approach for the change currently in flight. Replaced when the next non-trivial
change begins, so anything that must outlive it is promoted first: verified
product facts to `SPEC.md`, actionable work to `TASKS.md`, and closed choices to
`DECISIONS.md`.

The scratch-repository plan this replaces was already promoted. Its decision is in
`DECISIONS.md` as "Heading text is the contract between a template and an adopted
document", its four defects and their fixes are recorded against the closed task
in `TASKS.md`, and the two branches it did not exercise are named there too.

## Problem

`pr-readiness` step 7 says "Require a fresh independent review", with no condition
on it. `DECISIONS.md` records that this repository has one maintainer and that
preserving the shape of a review gate by self-approval is worse than having no
gate. The skill is installed into every repository, so it currently states a gate
that this repository cannot satisfy and that a single maintainer anywhere can only
satisfy by faking.

The contradiction has been recorded twice without being resolved: once when the
no-pull-request decision was taken, and again when the skill was restated, where
it was deliberately left for the task that owns it. Phase 7's exit criteria
include that no documented gate depends on a second reviewer.

`docs/WORKFLOW.md` step 12 points at "the skill's no-pull-request path", which the
skill does not name as a path. That is the same misalignment in the other
direction, and it is on a different axis: whether a pull request exists and
whether a second party exists are independent of each other.

## Approach

Make the gate conditional on something readable, and replace it with named
substitutes rather than removing it.

- Keep the strong gate wherever an independent review is genuinely required, and
  say what makes it required: the repository's own instructions or decisions, or
  an enforcement its host applies to the changed paths.
- Where nothing settles the question, report the requirement as undetermined. An
  agent picking whichever answer suits the change under review is the failure to
  design against.
- Where the author is the only party, define what local readiness requires
  instead. The substitutes must be things a single maintainer can actually
  produce, and none of them may be called a review.
- Report the absence as a limitation of the readiness claim. This is the part
  `DECISIONS.md` already argues for and the skill does not say: a gate whose shape
  survives without its substance reads like one that held.
- Name the path in the skill so `docs/WORKFLOW.md` can point at it, and correct
  that pointer to name both reduced paths, since this repository is on both.

Every existing rule survives. The change is a condition on one workflow step, one
new section, and the two places that report the outcome.

## Trade-offs

- The condition is read rather than configured. A repository that has reviewers
  and never wrote that down gets the reduced path, which is the wrong answer for
  it. Configuring it would mean a field in a marker that this repository has no
  business writing into every adopting repository, and the undetermined case is
  reported rather than assumed, so the wrong answer is visible in the report.
- A separate pass over the finished diff is weaker than a second reader and is
  worth having anyway. It is placed and worded so it cannot be reported as a
  review, which is the whole risk it carries.
- An agent review is not promoted to the independent one. In this repository the
  agent is usually the author, and a rule that depends on which session wrote the
  code is not checkable from the diff.

## Verification

- Read the skill end to end after the edit and confirm every rule that was there
  before is still there, since no automated check reads its prose.
- `./scripts/validate.sh` under WSL, reporting which checks it performed. It
  covers the skill's front matter, its `name` matching its directory, the absence
  of a `[TODO:` marker, and the `docs/SKILLS.md` inventory.
- Check that no file still states the gate unconditionally, by searching for the
  terms the old wording used.
- No three-platform run is expected: the change touches no script, no workflow,
  and no installed path beyond a skill file the installer links identically
  everywhere.
