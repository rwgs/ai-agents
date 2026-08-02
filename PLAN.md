# Record what an adopting repository took

Approach for the change currently in flight. Replaced when the next non-trivial
change begins, so anything that must outlive it is promoted first: verified
product facts to `SPEC.md`, actionable work to `TASKS.md`, and closed choices to
`DECISIONS.md`.

The reconciliation plan this replaces was promoted before it was overwritten.
Both its decisions are in `DECISIONS.md`, as "One skill source per repository,
exposed by an ignored link" and "A skill about the agent's own operation is
installed, not pooled", and its tasks are closed in `TASKS.md` with the local
evidence recorded against them.

## Problem

Phase 6's update mode adds missing documents and sections, reports drift, and
overwrites nothing. It cannot do any of that without knowing what the repository
took and what it deliberately refused, and nothing an adopting repository
contains records either.

Two absences look identical in a repository and mean opposite things. A `SPEC.md`
that is missing because the repository declined it must never be offered again; a
`SPEC.md` that is missing because the baseline added it after adoption is exactly
what an update exists to add. The same holds for a skill copied from
`rwgs/ai-skills`: without the commit it was taken at there is nothing to compare
the copy against, which `DECISIONS.md` already records as the reason the pool is
a repository with commits rather than a directory.

`ROADMAP.md` states the risk this change has to avoid: a marker that drifts from
what is actually in the repository is worse than no marker, because it reports an
update as applied when it was not.

## Constraints discovered

- Read this session: `adopt-baseline` step 1 does not look for a marker of its
  own, so a second run on an already-adopted repository has nothing to stop it,
  and the skill's own scope line says one repository, once.
- The marker has to exist in a repository that declines every planning document.
  The `docs/SKILLS.md` table gives a documentation repository nothing beyond
  `AGENTS.md` and `CLAUDE.md`, so the marker cannot be a section of a document
  that is itself declinable, which rules out `DECISIONS.md` and every other
  planning file.
- `DECISIONS.md` is append-only by its own header, and a re-apply changes the
  recorded commit. A marker kept there would have to be rewritten, which that
  file forbids.
- `SPEC.md` already records that Python's `tomllib` reads TOML and does not write
  it and that PowerShell has no TOML support at all. JSON is the one format
  `python3` and Windows PowerShell 5.1 both parse with nothing installed, and
  both installers already parse JSON for `settings.json`.
- The installer's own provenance model is the precedent for the shape: one
  per-machine state file at `~/.agents/ai-install-state.json`, carrying a
  `version`, recording what was written outside the files it describes. The
  marker differs in one way that matters, and it is the reason it cannot simply
  reuse that file: it is per-repository and committed, because a fresh clone must
  be able to say what the repository adopted.
- `.claude/skills` is per-clone setup under the wiring decision, so a fresh clone
  of an adopting repository has no Claude Code skills. A recorded skill list is
  therefore also what tells an update run that the link is missing rather than
  the skills.
- This repository gets no marker. It is the baseline, not an adopter, and nothing
  here reads or writes one.

## Approach

- Add one committed file per adopting repository, `.agents/baseline.json`, beside
  the `.agents/skills/` directory that adoption already writes into. It carries a
  `version`, the baseline clone URL, the full commit taken and the date, the
  artifacts adopted, the artifacts declined with a reason for each, and each
  skill copied from the pool with its source URL and full commit.
- Record the clone URL rather than `rwgs/ai`, because the host-neutral phase
  settled that nothing host-neutral asserts a host and the same content can be
  cloned from Azure DevOps.
- Record full 40-character commits. A short hash goes ambiguous as either
  repository grows, and the marker is read years after it is written.
- Require a reason on every declined artifact. That string is the only thing that
  stops update mode offering a declined document on every run, and it is the
  field the drift risk turns on.
- Read both commits with `git -C <clone> rev-parse HEAD`, after checking
  `git -C <clone> status --porcelain` is empty. Content copied out of a dirty
  clone is not the commit recorded, which is the drift the marker exists to
  prevent.
- Record only what came from the baseline or the pool. A skill authored in the
  repository has no entry, because it has no upstream to compare against, and the
  keep-or-promote decisions adoption makes stay in that repository's
  `DECISIONS.md` where the reconciliation already put them.
- Make step 1 stop when the marker already exists, so adoption is not run twice
  over a repository that has already adopted.
- Align the workflow list with the body sections while adding the step, because
  the list currently omits the project-scoped configuration section and carries a
  verify step with no section, so a new numbered step cannot be placed correctly
  without it.
- Build no update mode here. This change defines and writes the record; reading
  it is the next task.

## Trade-offs

- A committed JSON file is a fifth artifact adoption leaves behind, in a
  repository that may have taken only two documents. Accepted because the
  declined list is the valuable half and it is largest exactly there.
- JSON holds the decline reasons as strings, which a human reads less easily than
  a Markdown table. Accepted because a table has no parser in any language here,
  so every reader would hand-roll one, and the reasons are read by an agent.
- The marker duplicates facts that are visible in the repository: an adopted
  document is a file that exists. That duplication is deliberate and is what
  makes the marker checkable, since a disagreement between the two is reportable
  where a marker recording only unverifiable facts is not.
- Requiring a clean clone to read a commit blocks adoption from a working tree
  mid-change. Accepted: the alternative is a recorded commit that does not
  describe the content copied.

## Verification

- `./scripts/validate.sh` under WSL, which checks the skill front matter, that
  each `name` equals its directory, that no `[TODO:` marker survives, that the
  `docs/SKILLS.md` inventory matches the skill directories, and the required
  files, tracked-file, and line-ending rules. Report which checks the run
  performed, since it skips ShellCheck, the Node syntax check, `codex execpolicy`,
  and both PowerShell checks where those tools are absent.
- Parse the marker example in the skill with `python3 -m json.tool`, because a
  malformed example is the one defect no check here would catch and every
  adopting repository would copy.
- Read `adopt-baseline` end to end after editing and confirm every existing rule
  survives. That is what caught a dropped rule during the restatement passes, and
  no automated check covers it.
- No three-platform run is requested. The change touches no script, no workflow,
  and no installed path, and the checks that read the changed files behave
  identically on every platform.
