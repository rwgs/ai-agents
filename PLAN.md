# An entry point for a repository that holds no work yet

Approach for the change currently in flight. Replaced when the next non-trivial
change begins, so anything that must outlive it is promoted first: verified
product facts to `SPEC.md`, actionable work to `TASKS.md`, and closed choices to
`DECISIONS.md`.

The propagation plan this replaces was already promoted. Its decision is in
`DECISIONS.md` as "Adoption installs line endings and derives the host's CI
definition", the propagated set is in `SPEC.md`, and its evidence is recorded
against the closed task in `TASKS.md`.

## Problem

Someone starting a project has two skills to choose between, and neither fits.
`adopt-baseline` is named, described, and written for a repository that already
holds work: it opens by inventorying files that do not exist, reconciling a
`CLAUDE.md` that was never written, and deciding keep-or-promote for skills
nobody has authored. `update-baseline` refuses to run without a marker. So a new
repository is either pushed through a workflow whose first four steps are no-ops,
or set up by hand and never recorded, which leaves it outside the update loop
this phase exists to close.

## Constraints discovered

- The shape is already settled. `DECISIONS.md` records under "Updating is a
  sibling skill" that this work "is a third workflow with a third precondition,
  an empty repository, not a mode of either of these two". So the question is
  what the third skill contains, not whether it exists.
- The offerable set of artifacts lives in `adopt-baseline` alone. That rule was
  recorded when the update skill was written, and it was the right call for the
  same reason twice: this phase's propagation task had to extend one list rather
  than two. A third skill repeating the set would guarantee three lists disagree.
- What an empty repository can take divides differently from what it wants, and
  it divides only at creation. A document that states intent -- `SPEC.md`,
  `ROADMAP.md`, `TASKS.md` -- has its content before any code exists. A document
  that records history -- `PLAN.md`, `CHANGELOG.md` -- has none yet.
  `DECISIONS.md` is the exception, and writable now for the opposite reason: the
  stack, the host, and the shape are chosen while the repository is created, and
  those are precisely the choices whose rationale cannot be recovered from the
  code later.
- Almost every artifact a new repository leaves out is "not yet" rather than
  "no", and the marker has one field for both. `update-baseline` reports a
  declined artifact once per run with its recorded reason, so a reason that names
  the condition reopening it arrives back in front of someone when the condition
  is met, and a flat "not needed" reads as closed and stays closed.
- A new repository has no automated check, and `adopt-baseline` forbids adding a
  workflow to a repository with no check to run. So the usual outcome is that
  both host-specific artifacts wait for the first test, which is a deferral with a
  condition rather than a refusal.
- Verified this session in a scratch repository, because the sequence is what the
  skill will tell an agent to run. `git init -b main` works on Git 2.55, and
  `git log` in a repository with no commits exits non-zero, so an inventory
  command has to tolerate that. With `.gitattributes` in the first commit, a file
  subsequently written with CRLF is staged as LF and `git add --renormalize .`
  stages nothing, so the conversion `adopt-baseline` documents never has to
  happen. `git check-ignore -v` names the matching rule for a path that does not
  exist yet, which is what makes the ignore rules checkable in the first commit.

## Approach

- Add `.agents/skills/start-repository/`, a tenth installed skill, with the same
  `SKILL.md` plus `agents/openai.yaml` shape as its two siblings. Seven numbered
  body sections, a verify item covered by the validation section, safety rules.
- Keep it to what differs for an empty repository, and point at `adopt-baseline`
  for the selection table, the skill wiring, the host reading, the CI derivation,
  and the marker's fields. No second copy of the offerable set.
- Order the steps so the line-ending and ignore rules are the first commit, ahead
  of the instruction files. That is the concrete payoff of a new repository over
  an adopting one: nothing is ever committed under the wrong endings, so the
  renormalising commit and the working-tree refresh never happen.
- State the intent-against-history split as the rule for which documents are
  created, with `DECISIONS.md` named as the exception and its first entries being
  the creation choices themselves.
- Write every deferral into the marker's `declined` field with the condition that
  reopens it, and show the shape rather than duplicating the whole example.
- Name the new skill at both siblings' boundaries, in `docs/SKILLS.md`, in the
  `docs/WORKFLOW.md` lifecycle, and in `SPEC.md` where the two-skill split is
  stated.

## Trade-offs

- A tenth installed skill costs a description in every agent's always-loaded set
  and an installer rerun. Accepted on the recorded decision, and the triggers
  separate cleanly: start, create, scaffold, and initialise against adopt,
  standardise, and roll out against update, refresh, and drift.
- Pointing at `adopt-baseline` for five sections means an agent starting a
  repository loads two skills. Accepted for the same reason the update skill
  keeps no list: three copies of the offerable set would disagree by the next
  change that extends it.
- The usual new repository gets no CI definition on the first day. Accepted,
  because the alternative is a workflow with no step in it, and the deferral is
  recorded with the condition that reopens it rather than forgotten.
- Deferrals share the marker's `declined` field rather than getting one of their
  own. A second field would need `update-baseline` to learn a second vocabulary,
  which is the argument already accepted for keeping convention deviations in the
  repository's own `DECISIONS.md`. The reason text carries the difference.

## Verification

- `./scripts/validate.sh` under WSL. It checks the new skill's front matter, that
  its `name` matches its directory, that no `[TODO:` marker survives, and that the
  `docs/SKILLS.md` inventory matches the skill directories, which is what catches
  the tenth entry being missed. Report which checks the run performed, since it
  skips ShellCheck, the Node syntax check, `codex execpolicy`, and both PowerShell
  checks where those tools are absent.
- Run every command the skill tells an agent to run, in a scratch repository,
  before it ships. Done for the create, first-commit, renormalise, and
  check-ignore sequences above.
- Parse the marker fragment with `json.loads` and check every deferral carries a
  non-empty reason, as the two existing marker examples are checked.
- Read all three skills afterwards and confirm the three preconditions partition
  cleanly, each names the other two where a reader could land in the wrong one,
  and the offerable set is still stated in exactly one place.
- No three-platform run is requested. The change adds a skill file and edits
  documentation; it touches no script, no workflow, and no installer behavior. The
  installer links a skill directory identically on every platform.
