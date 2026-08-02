---
name: update-baseline
description: Bring a repository that already adopted the shared agent baseline up to date with it, reading the recorded baseline and pool commits, adding the documents and sections that are missing without overwriting anything customised, reporting convention drift and stale pooled skills for a human to apply, and rewriting the record. Use when asked to update, refresh, re-apply, or check drift against the baseline in a repository carrying `.agents/baseline.json`.
---

# update-baseline

## Scope

One already-adopted repository, as often as the baseline changes.
`.agents/baseline.json` is what separates this from `adopt-baseline`: no marker
means the repository never adopted, and that skill owns the first pass. This one
performs no first adoption and overwrites nothing the repository customised.

`ai-project-manager` owns the content of the planning documents once they exist.
This skill decides which are missing and reports where they have drifted; it does
not plan the work they describe.

## Workflow

1. Read the marker and get something to compare against.
2. Check the marker against the repository before trusting it.
3. Sort every artifact on offer into adopted, declined, new, or unrecorded.
4. Add what is missing, and only by addition.
5. Report convention drift rather than correcting it.
6. Refresh a pooled skill only where nothing customised it.
7. Rewrite the marker, and only for what actually happened.

## 1. Read the marker

```bash
cat .agents/baseline.json
```

Stop and hand over to `adopt-baseline` when there is no marker. Stop and report
when it does not parse or its `version` is one you do not know: everything below
trusts these fields, so a half-read marker is worse than none.

Compare against a clone of the recorded `baseline.repository`. An existing clone
will do when `git -C "$clone" status --porcelain` prints nothing; otherwise clone
the recorded URL into a temporary directory. The recorded URL is the one to use,
whatever host it names.

```bash
git -C "$clone" status --porcelain            # must print nothing
git -C "$clone" pull --ff-only
git -C "$clone" cat-file -e "$recorded_commit^{commit}"
git -C "$clone" rev-parse HEAD                # the commit being compared against
git -C "$clone" diff --name-status "$recorded_commit" HEAD
```

Fast-forward the clone rather than only fetching it. The steps below read
templates and skills out of its working tree, so the files on disk and the commit
being compared against have to be the same thing; after a bare `fetch` they are
not, and a document added upstream is missing from the clone while the diff says it
arrived. A fast-forward on a clean clone is a no-op when there is nothing new.

Stop if the recorded commit is not in that history. Either the baseline's history
was rewritten or the marker names a commit from somewhere else, and there is
nothing to diff against. Report it and ask.

## 2. Check the marker against the repository

Every entry names something checkable, so check it before using it.

| Marker says | Repository shows | Report |
| --- | --- | --- |
| adopted | the file is absent | removed after adoption; ask before re-adding it |
| declined | the file exists | added by hand; offer to record it as adopted |
| a pooled skill | `.agents/skills/<name>` is absent | the copy is gone; ask before restoring it |
| any pooled skill | `.claude/skills` is missing | per-clone setup rather than drift; recreate the link |

Report every disagreement and change nothing on the strength of one. A marker that
contradicts the repository is the failure the record exists to prevent, so it is a
finding rather than something to quietly normalise.

## 3. Sort what is on offer

`adopt-baseline` defines what a repository may take: its selection table for the
planning documents, `CHANGELOG.md` on its own condition, its wiring and
configuration rules, and its development-infrastructure step, which covers
`.gitattributes`, the CI definition, and the dependency-update configuration. Read
that skill rather than keeping a second list here, so anything the baseline starts
offering is offered by both skills at once.

Put each artifact in one group and act on the last three only:

- **Recorded as adopted and present.** In scope for section and convention drift
  below.
- **Recorded as declined.** Never added. Report it once with its recorded reason,
  so the decision can be revisited deliberately rather than re-argued every run.
- **Recorded nowhere and absent.** New since adoption. Offer it against the
  selection table, and record the answer either way.
- **Recorded nowhere and present.** The repository added it by hand. Offer to
  record it as adopted.

## 4. Add what is missing

Additive only. Three things are added and nothing else.

- A document the selection table calls for, that the marker does not decline, and
  that does not exist. Adapt the template to this repository as adoption would, and
  cut what does not apply rather than leaving a placeholder.
- A section the template at the compared commit has and the adopted document does
  not. Write it for this repository from what the repository shows. Where it cannot
  be written that way, report it as drift instead: a heading with nothing under it
  reads as an answered question.
- An infrastructure artifact the marker does not decline and the repository does
  not have, written the way `adopt-baseline` writes it: the line normalisation that
  follows `.gitattributes`, and check steps derived from the checks this repository
  actually has rather than copied from the baseline's.

A host-specific artifact is added only for the host the repository is on now, read
the way `adopt-baseline` reads it. Where the marker records one for a different
host, the repository moved: report that, and never leave it carrying two CI
definitions.

Compare headings, not prose. The templates carry stable headings, and the prose
below them is meant to have been rewritten:

```bash
grep '^## ' SPEC.md
grep '^## ' "$clone/.agents/skills/ai-project-manager/assets/project-docs/SPEC.md"
```

Never rewrite a line an adopted document already carries. Those documents are
customised after they land, which is the rule this whole workflow exists to keep.

## 5. Report convention drift

These are the conventions adoption establishes. Report each with the rule it
breaks and what applying it would change, then let the user apply it. Read the
repository's own `DECISIONS.md` first: a deviation recorded there is a closed
decision, so report it as kept on purpose rather than as drift.

- `CLAUDE.md` carries instructions of its own instead of a bare `@AGENTS.md`
  import. Say so even when a tool such as `rtk init` regenerates the file, and name
  the tool.
- `PLAN.md` exists without `DECISIONS.md`. The two are one mechanism, and the plan
  is overwritten.
- A skill exists twice, under `.agents/skills/<name>` and `.claude/skills/<name>`.
  The second copy drifts and only one can be compared against a recorded commit.
- `.claude/skills` is committed rather than ignored. Cloned on a Windows machine
  without symbolic-link support it becomes a text file, and skill discovery then
  fails silently.
- `.claude/settings.local.json` is tracked, or is not ignored. It holds
  interactively approved permissions and absolute paths.
- An adopted planning document is a stub: headings with nothing written under
  them. It teaches an agent nothing and reads as answered.
- `git add --renormalize .` stages changes, so the tracked content disagrees with
  the repository's own `.gitattributes`. The file was added and the conversion never
  committed, which leaves the failure it exists to prevent in place.

Correct none of these silently. Each has a reason a repository might legitimately
hold it, and the report is what lets the user say which.

## 6. Refresh the skills copied from the pool

Each entry in the marker's `skills` carries its own `repository` and its own
`commit`, so the clone and the commit compared against here are the skill's, not
the baseline's. Get the clone the same way as in step 1. The pool keeps each skill
at `skills/<name>/`, so compare that path against the copy under
`.agents/skills/<name>/`.

```bash
git -C "$pool" status --porcelain             # must print nothing
git -C "$pool" pull --ff-only
git -C "$pool" diff --name-status "$skill_commit" HEAD -- "skills/$name"

# what was taken, against what is here now
tmp=$(mktemp -d)
git -C "$pool" archive "$skill_commit" "skills/$name" | tar -x -C "$tmp"
diff -r "$tmp/skills/$name" ".agents/skills/$name"
```

- An empty `diff -r` means nothing here customised the copy, so refresh it to the
  compared commit and record that commit.
- Any output means the copy was customised. Report the pool's diff and change
  nothing.

That test is safe for a skill and never applies to a document: a pooled skill is
copied verbatim, where an adopted document is adapted as it lands, so a document is
never byte-identical to its template and the check would always fail.

## 7. Rewrite the marker

Update `baseline.commit` and `baseline.taken` to the commit compared against, add
every newly adopted artifact, add a reason for anything newly declined, and move a
refreshed skill's commit forward. Leave every existing decline reason as it is.

Advance `baseline.commit` only when nothing is left outstanding: every artifact on
offer is adopted, declined with a reason, or covered by a decision recorded in this
repository's `DECISIONS.md`, and every document and section that was added is
written. Leave it at the recorded value when drift was reported and not applied, so
the next run finds it again. A pooled skill is separate, because it carries its own
commit: one customised copy does not hold the baseline commit back.

Finish by reporting four things, and say plainly when a group is empty:

- what was added
- what was reported for the user to apply
- what was skipped by a recorded decision, and the reason recorded for it
- where the marker and the repository disagree

## Safety rules

- Never run this without `.agents/baseline.json`. That is `adopt-baseline`.
- Never rewrite or remove a line an adopted document already carries.
- Never add an artifact the marker declines.
- Never add a heading without content written for this repository.
- Never refresh a pooled skill whose copy differs from its recorded commit.
- Never advance the recorded commit while anything is outstanding.
- Never correct convention drift silently.
- Never resolve a disagreement between the marker and the repository by trusting
  the marker.
- Never record a commit read from a clone with uncommitted changes.
- Never repropose something `DECISIONS.md` closed without saying what changed.

## Validation

- The marker parses, its `version` is known, and its recorded commit is in the
  baseline's history.
- Every document and section added was missing, and none was declined.
- `git diff` shows adopted documents gaining whole sections only, with no line
  they already carried changed or removed.
- Each pooled skill either matched its recorded commit and was refreshed, or is
  reported as customised and untouched.
- `baseline.commit` advanced only if nothing was left outstanding.
- Running again immediately reports nothing to do.
