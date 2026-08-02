# Bring an adopted repository up to date

Approach for the change currently in flight. Replaced when the next non-trivial
change begins, so anything that must outlive it is promoted first: verified
product facts to `SPEC.md`, actionable work to `TASKS.md`, and closed choices to
`DECISIONS.md`.

The marker plan this replaces was promoted before it was overwritten. Its decision
is in `DECISIONS.md` as "An adopting repository records what it took in
`.agents/baseline.json`", the marker itself is in `SPEC.md`, and its evidence is
recorded against the closed task in `TASKS.md`.

## Problem

A repository adopts the baseline once and the baseline keeps changing. Nothing
brings the two back together, so an adopted repository silently falls behind: it
misses a document the baseline added, a section a template gained, and a fix to a
skill it copied out of the pool.

The record needed to do that safely now exists. What is missing is the half that
reads it, and its hard constraint is stated in `ROADMAP.md`: adopted documents are
customised after they land, so an update that overwrites destroys work. Additive
semantics are a correctness requirement rather than a preference.

## Constraints discovered

- The user settled the shape this session: a sibling skill, not a second mode
  inside `adopt-baseline`. That agrees with the `docs/SKILLS.md` authoring rule to
  keep a skill to one workflow, and with the precedent that split project planning
  from pull-request readiness.
- Read this session, the templates carry stable `##` headings, so a missing
  section is computable by comparing headings rather than prose. The pool's layout
  is `skills/<name>/`, and its history is two commits with `4c6cf88` at the tip.
- `adopt-baseline` already defines what is on offer, in its selection table and
  its wiring and configuration rules. A second list here would drift from it, and
  the propagation task later in this phase is about to add to that list.
- The provenance rule this repository already accepted for shared files fits a
  pooled skill exactly and a document not at all. A pooled skill is copied
  verbatim, so byte-identical to the recorded commit means nothing here changed it
  and it is safe to refresh. An adopted document is adapted to the repository as it
  lands, so it is never byte-identical and the test would be dead code.
- A convention a repository deliberately keeps needs somewhere to be recorded, or
  it is reported as drift on every run. `DECISIONS.md` is that place, so this skill
  reads the repository's own decision log before calling a deviation drift. It
  needs no new marker field, and a repository that declined `DECISIONS.md` accepts
  a repeated report.
- Advancing the recorded commit past drift that was reported and not applied would
  hide that drift permanently, because the next run diffs from the newer commit.
  The commit is therefore a claim that nothing is outstanding, not a timestamp.
  Each pooled skill carries its own commit, so one customised skill does not hold
  the baseline commit back.

## Approach

- Add `.agents/skills/update-baseline/`, installed alongside `adopt-baseline`,
  each naming the other at its boundary. Presence of the marker is what separates
  them, and it is checkable rather than a matter of interpretation.
- Stop rather than guess on three inputs: no marker, a marker that does not parse
  or carries an unknown `version`, and a recorded commit absent from the clone's
  history. Everything below the read trusts the marker, so a half-read one is
  worse than none.
- Check the marker against the working tree before using it, and report every
  disagreement instead of normalising it. That is the drift `ROADMAP.md` calls
  worse than no marker.
- Sort each artifact on offer into adopted, declined, new since adoption, or added
  by hand, and act only on the last three. A declined artifact is reported once
  with its recorded reason and never added.
- Add two things and nothing else: a document the selection table calls for that
  the marker does not decline, and a section the template has that the adopted
  document lacks. Write a section for the repository or report it, never leave an
  empty heading, since a heading with nothing under it reads as an answered
  question.
- Report convention drift with the rule it breaks and what applying it would
  change, and let the user apply it. Read the repository's `DECISIONS.md` first, so
  a deviation it has already closed is reported as kept on purpose.
- Refresh a pooled skill only when its copy is byte-identical to the pool at the
  recorded commit. Otherwise report the pool's diff and change nothing.
- Advance the recorded commit only when nothing is outstanding, so a second run
  over an unchanged baseline reports nothing to do and a run with unapplied drift
  reports it again.
- Close the `SPEC.md` unresolved question about pool-skill reporting, which this
  builds, and leave the loop's proof on a scratch repository to the task that owns
  it.

## Trade-offs

- A ninth installed skill costs a description line in every session and an
  installer rerun. Accepted on the user's decision, and it buys two triggers that
  do not compete: adopt and standardise against update, refresh, and drift.
- Reading `adopt-baseline` for the offerable set couples the two skills, so the
  update skill is incomplete on its own. Accepted because the alternative is two
  lists that disagree, and the propagation task would have to update both.
- Reporting rather than applying convention drift leaves a repository able to stay
  non-conformant indefinitely. That is the point: each deviation has a legitimate
  reason a repository might hold it, and the alternative is a skill that edits
  files nobody asked it to touch.
- Holding the recorded commit back while drift is outstanding means a repository
  that never applies anything re-reads the same diff every run. Accepted, because
  the alternative loses the finding entirely.
- Nothing here is verified against a real repository. The phase already carries
  the scratch-repository proof as its own task, and this change is the thing that
  proof needs to exist first.

## Verification

- `./scripts/validate.sh` under WSL. Adding a skill makes it check the new front
  matter, that `name` equals the directory, that no `[TODO:` marker survives, and
  that the `docs/SKILLS.md` inventory matches the directories, which fails until
  that list is updated. Report which checks the run performed, since it skips
  ShellCheck, the Node syntax check, `codex execpolicy`, and both PowerShell checks
  where those tools are absent.
- Check that the paths the new skill names exist where it says: the pool's
  `skills/<name>/` layout and the template path under `ai-project-manager`. A
  reusable skill naming a path that is not there is a defect an adopting
  repository inherits.
- Read both skills after editing and confirm the boundary is stated in each and
  that no rule is duplicated in a form that could drift.
- No three-platform run is requested. The change touches no script, no workflow,
  and no installer behavior; it adds a skill directory, which the installer links
  identically on every platform.
