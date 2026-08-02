# Reconcile the reusable workflows with the baseline

Approach for the change currently in flight. Replaced when the next non-trivial
change begins, so anything that must outlive it is promoted first: verified
product facts to `SPEC.md`, actionable work to `TASKS.md`, and closed choices to
`DECISIONS.md`.

The host-neutral plan this replaces was promoted before it was overwritten. Its
decision is in `DECISIONS.md` as "Both hosts are supported, only GitHub is
verified", the derivation limit and the unverified pipeline are in `SPEC.md`, and
its one remaining task, a three-platform run, is carried in `TASKS.md` with the
local evidence already recorded against it.

## Problem

Phase 6 adds an update mode to `adopt-baseline` that reports drift without
overwriting what a repository customised. Three things the two reusable
workflow skills say contradict what this repository has already decided, and an
update mode built on top of them would propagate the contradictions into every
adopting repository. A fourth is a policy the documentation states and the
installed set breaks.

Read this session rather than recalled:

- `adopt-baseline` inventories seven files in step 1 and neither `DECISIONS.md`
  nor `CHANGELOG.md`. Its step 3 table selects `PLAN.md` for three of the four
  repository types and never selects `DECISIONS.md`. The decision log records
  that promotion out of `PLAN.md` is the only thing that makes `PLAN.md` safe to
  overwrite, so a repository that adopts the plan without the log loses every
  rejected alternative the moment its next change begins.
- `ai-project-manager` writes `PLAN.md` in step 4 and updates `CHANGELOG.md` in
  step 8, and neither its discovery step nor its `rg` glob looks for either one.
  The skill cannot find the file it is expected to replace.
- `docs/SKILLS.md` and `adopt-baseline` step 5 give two different dual-agent
  wirings. The first says a pooled skill is copied to `.agents/skills/<name>` and
  to `.claude/skills/<name>`; the second says a project-local skill is authored
  once under `.agents/skills/` and exposed through a single ignored
  `.claude/skills` link. Two copies in one repository drift, and an update mode
  comparing an adopted copy against a recorded pool commit would have two copies
  to compare and no rule for what a disagreement between them means.
- `docs/SKILLS.md` states the installed-set bar as excluding a skill tied to one
  product, one environment, or one kind of project, and the installed set holds
  `show-codex-reset-expiries`, which is tied to one product. Nothing records why,
  so the bar cannot be applied to the next candidate without inventing a reason.

## Constraints discovered

- Both skills are installed into every repository, so neither may gain a rule
  that only this repository needs. That is an authoring rule in
  `docs/SKILLS.md`, and it is why the pool commit an adopting repository records
  is named here without saying where it is written: the marker format is the
  phase's first task, not this one.
- `.claude/skills` cannot be committed under either wiring. A committed symbolic
  link is checked out as a plain text file on a Windows clone without
  symbolic-link support, and skill discovery then fails with no error. The link
  is per-clone setup whichever method is chosen, which is the cost the
  two-copies method avoids.
- Adoption closes decisions of its own: which planning documents the repository
  declined, which existing skills were kept local, promoted, or retired. A
  `DECISIONS.md` created during adoption therefore has content immediately,
  which is what separates it from the empty `ROADMAP.md` the skill already warns
  against.
- This repository has no `.claude/skills` and needs none. Its `.claude/` holds
  only the ignored `settings.local.json`, because every skill here is installed
  user-wide by the installer and none is project-local. The wiring rule is for
  adopting repositories, so nothing in this change alters this tree's layout.
- Nothing in this change touches a script, a workflow, a rule file, or an
  installed path. The files it changes are read by `scripts/validate.sh`'s skill
  and documentation checks, which behave identically on all three platforms.

## Approach

- Record the two closed choices before editing, because both are policy that
  outlives this change: one dual-agent wiring method, and why an
  agent-operations skill is installed despite naming one product.
- Pair `DECISIONS.md` with `PLAN.md` in `adopt-baseline` rather than adding a
  row to the selection table. The two files are one mechanism: the plan is
  overwritten and the log is what survives it.
- Give `CHANGELOG.md` its own condition outside that table, matching the
  decision already recorded here: it is created when the project has consumers
  who install or upgrade it independently of its source, and it is not part of
  the planning set.
- Settle the wiring on one `.agents/skills/` source plus the ignored link, and
  cover the case the alignment exposes: a repository that already has a real
  `.claude/skills` directory. Its skills move to `.agents/skills/` before the
  directory is replaced, mirroring the rule that a `CLAUDE.md` is never reduced
  to an import before its content is preserved.
- State the `show-codex-reset-expiries` exception as a clause of the bar in
  `docs/SKILLS.md`, not as a note attached to that one skill, so the next
  candidate is placed by reading the bar.
- Leave the phase's other tasks alone. This change makes the two workflows
  consistent with the baseline; it does not build update mode and it does not
  decide where an adopting repository records the commits it took.

## Trade-offs

- Pairing `DECISIONS.md` with `PLAN.md` adds a document to three of the four
  repository types, against the skill's own rule that a document the repository
  has no use for goes stale. Accepted because the pairing is what makes the plan
  safe to replace, and because adoption supplies the first entries.
- One wiring method costs per-clone setup in exchange for one copy to compare.
  Two committed copies need no setup, work on a Windows clone with no link
  support, and drift silently, which is the failure this baseline already
  rejected for the instruction files.
- Recording the agent-operations exception widens the installed-set bar by one
  clause. The alternative is a bar the current set contradicts, which is worse
  than a bar with a named clause, because the contradiction has to be
  re-explained on every skill placement.
- The three tasks are taken together rather than one per commit. They contradict
  each other in pairs, so a partial pass would leave the skills disagreeing in a
  different place than they do now.

## Verification

- `./scripts/validate.sh` under WSL, which checks each skill's front matter, that
  each `name` equals its directory, that no `[TODO:` marker survives, that the
  `docs/SKILLS.md` inventory matches the skill directories, and the tracked-file
  and line-ending rules. Report which checks the run performed, since it skips
  ShellCheck, the Node syntax check, and both PowerShell checks where the tools
  are absent.
- Read both skills end to end after editing and confirm every existing rule
  survives. That is the check that caught a dropped rule during the restatement
  passes, and no automated check covers it.
- No three-platform run is requested for this change. It touches no script, no
  workflow, and no installed path, and the checks that read the changed files run
  the same way on every platform.
