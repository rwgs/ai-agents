# Prove the adoption loop on a scratch repository

Approach for the change currently in flight. Replaced when the next non-trivial
change begins, so anything that must outlive it is promoted first: verified
product facts to `SPEC.md`, actionable work to `TASKS.md`, and closed choices to
`DECISIONS.md`.

The entry-point plan this replaces was already promoted. Its decision is in
`DECISIONS.md` as "A new repository is started, and its refusals carry a reopening
condition", the three-skill split is in `SPEC.md`, and its evidence is recorded
against the closed task in `TASKS.md`.

## Problem

Three skills now describe a loop -- start or adopt, record a marker, re-apply as
the baseline changes -- and not one line of it had ever been run against a
repository. Every rule in them was reasoned from this repository's own history.
`ROADMAP.md` names the risk directly: an update that overwrites destroys work, and
a marker that drifts from the repository is worse than no marker, because it
reports an update as applied when it was not.

## Approach

Run the loop for real, in a scratch repository, acting as the agent the skills are
written for, and fix what it exposes rather than what it might expose.

- Build a project that fires the interesting branches rather than a clean one: a
  `CLAUDE.md` carrying content and no `AGENTS.md`, a real `.claude/skills`
  directory holding a project-specific skill, a file committed with CRLF so the
  renormalisation has work, a GitHub remote, and real checks so the CI definition
  is derived rather than declined.
- Clone the baseline and the pool, then move both forward *after* cloning, so the
  update run has to fast-forward an existing clone rather than read a fresh one.
- Change the baseline in a way that tests both halves of the additive rule: one
  new template section that can be written from what the repository shows, and one
  that cannot.
- Follow each skill step by step and record every command's real output. A step
  that cannot be performed as written is a defect in the skill, not something to
  work around.
- Re-apply until it converges, which is the exit criterion, and treat failure to
  converge as a defect rather than as the loop's nature.

## Findings and fixes

Four defects, all in the instructions rather than in the design.

- The Windows wiring command never worked. `New-Item -ItemType Junction -Path
  .claude/skills -Target .agents/skills` fails with "Creating a junction requires
  an absolute path for the target" and creates nothing. Fixed with `(Resolve-Path
  .agents/skills)`, and the asymmetry with the deliberately relative `ln -s` form
  is now stated. Both forms were then run: junction on Windows, symbolic link under
  WSL.
- Adoption never said to keep the template's heading text. It said to adapt the
  template and delete what does not apply, so an adapted `AGENTS.md` came out with
  `## Scope`, `## Working style`, and `## Verification` against the template's six
  headings, and the update run reported the entire template as missing. Heading
  text is the only join left once the prose beneath is rewritten, so adoption now
  requires it, `start-repository` says the same, and renaming a kept heading is a
  safety rule.
- The heading comparison is valid for four of the seven templates.
  `DECISIONS.md` and `CHANGELOG.md` are append-only logs whose template holds one
  placeholder entry heading, and `ROADMAP.md`'s headings are example phase names, so
  comparing those three reports noise that reads exactly like a missing section.
  `update-baseline` now names the four it applies to and how to check the other
  three.
- The loop could not converge. "Read `DECISIONS.md` before calling it drift" sat
  only in the convention-drift section, so a template section the repository
  deliberately does not have was re-reported on every run, and the recorded commit
  could never advance past it. Since adoption tells a repository to delete the
  sections that do not apply, that affects every adopting repository. The rule now
  covers missing sections too, and the outstanding test in the marker step with it.

## Trade-offs

- The proof uses local paths as the recorded baseline and pool URLs, because the
  baseline commit under test is not on `origin`. The skills say the recorded URL is
  the one to use whatever host it names, so this exercises the same code path, but
  it does not prove an HTTPS clone of either repository.
- One scratch repository cannot cover every branch. This one adopted; it did not
  start from empty, and the host was read rather than asked for. Those paths are
  still unexercised, and saying so is worth more than a second scratch repository
  built to make the coverage claim look complete.
- The fixes were verified by re-reading the same scratch repository rather than by
  a second adoption from scratch. Each one is an instruction defect whose correction
  is checkable directly: the junction command runs, the heading sets match, the
  three excluded templates are excluded, and the converged run reports nothing
  outstanding.

## Verification

- Every command in the three skills, run against the scratch repository, with its
  real output read rather than assumed.
- Adoption checked against `adopt-baseline`'s own validation list, including that
  every path the marker records as adopted exists and every declined one does not.
- `git diff --numstat` on the adopted documents after the update run, to show
  additions only. It reported `6 0 AGENTS.md`.
- A third pass under the corrected rules, which must report nothing to add and
  nothing outstanding.
- `./scripts/validate.sh` under WSL after the skill fixes, reporting which checks
  it performed.
