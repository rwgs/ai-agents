---
name: start-repository
description: Start a repository that holds no work yet on the shared agent baseline, creating it where there is none, putting the line-ending and ignore rules in the first commit so no conversion is ever needed, writing the instruction files, choosing the planning documents from what the project will be rather than from what it contains, and recording what was taken and what is only deferred with the condition that reopens it. Use when asked to start, create, scaffold, initialise, or set up a new project or repository. A repository that already holds work is `adopt-baseline`; one carrying `.agents/baseline.json` is `update-baseline`.
---

# start-repository

## Scope

One repository, before it holds any work. This is the first of three baseline
workflows and the only one that may create the repository itself. Hand over
rather than improvise:

- The repository already holds work of its own -- source, instructions, planning
  documents, or skills: that is `adopt-baseline`, whatever the repository's age.
- The repository carries `.agents/baseline.json`: it has adopted already, so it
  is `update-baseline`, working against that marker.

`adopt-baseline` defines what a repository may take: its selection table, its
skill wiring, its host reading, its CI derivation, and the fields of the marker
below. Read it for those rather than expecting a second copy here. What this skill
decides differently is what a repository with no content can take *yet*.

It does not install the machine-wide configuration. `scripts/install.sh` and
`scripts/install.ps1` in the baseline repository do that, and
`scripts/bootstrap.sh` obtains the clone they install from. None of them is part
of starting a project.

## Workflow

1. Confirm the repository holds no work, and create it where there is none.
2. Put the line endings and the ignore rules in the first commit.
3. Write the instruction files.
4. Choose the planning documents from what the project will be.
5. Copy in a pooled skill only where the stack calls for one.
6. Read the host, and add a CI definition only once there is a check to run.
7. Record what was taken, and what is only deferred.
8. Verify each agent loads what is expected.

## 1. Confirm the repository is new

```bash
ls -A
git rev-parse --is-inside-work-tree 2>/dev/null
git log --oneline -5 2>/dev/null
ls .agents/baseline.json AGENTS.md CLAUDE.md 2>/dev/null
```

`git log` exits non-zero in a repository with no commits, which is an answer
rather than a failure.

Count content, not commits. `gh repo create` and its Azure DevOps counterpart
leave a README, a licence, and a `.gitignore` in an initial commit, and that
repository is still new. A repository holding one source file, one instruction
file, or one planning document is not: hand it to `adopt-baseline`, which
reconciles what is there instead of writing over it.

Create the repository where there is none:

```bash
git init -b main
```

The remote is the maintainer's to create, not this workflow's. Where none exists
yet, step 6 records the intended host rather than guessing one.

## 2. First commit: line endings and ignore rules

Copy the baseline's `.gitattributes` before anything else is committed. This is
the one thing a new repository gets cheaply that an adopting one does not:
`adopt-baseline` has to stage a conversion with `git add --renormalize .`, give it
a commit of its own, and then check the whole tree out again, and a repository
that starts with the file never converts anything, because nothing is ever
committed under the wrong endings. Without it a contributor on Windows commits
CRLF and a Bash script checked out with CRLF fails with `syntax error near
unexpected token`.

The ignore rules the baseline requires belong in the same commit, because
`.claude/settings.local.json` appears the moment anyone approves a permission and
it holds interactively approved permissions and absolute paths:

```text
.claude/settings.local.json
.claude/skills
```

Ignore `.claude/skills` whether or not step 5 creates the link, so it cannot be
committed by accident later. A committed link is checked out as a plain text file
on a Windows clone without symbolic-link support, and skill discovery then fails
silently. Everything else in `.gitignore` follows the stack and is not the
baseline's to supply.

```bash
git add .gitattributes .gitignore
git commit -m "Add line-ending and ignore rules"
git add --renormalize .    # must stage nothing, now and after every later commit
```

## 3. Write the instruction files

Write `AGENTS.md` from the template, and a `CLAUDE.md` whose only instruction
content is an `@AGENTS.md` import on a line of its own. Claude Code reads
`CLAUDE.md` and never `AGENTS.md`, so that import is what gives both agents one
source. A short note explaining the file is fine; instructions are not.

None of `adopt-baseline`'s reconciliation applies. There is no existing file to
merge, no contradiction to resolve, and nothing to preserve before reducing
`CLAUDE.md` to the import.

Write what is true now and leave the rest out. The stack, the layout, and how to
run and test the project can be stated as soon as they are chosen; a convention
the project has not established yet is written when it establishes one. A heading
with nothing under it reads as an answered question.

Keep the heading text of every template section that is kept, and drop the ones
that do not apply. `update-baseline` joins a document to its template on heading
text, so a renamed heading reads as the template's section missing and this
repository's as one the baseline never had, on every run from here on.

## 4. Choose the planning documents

Select from `adopt-baseline`'s table by what the project will be. The table keys
on repository type, and a new repository has a type as soon as someone decides
what they are building.

Which of the selected documents can be written is a second question, and at
creation it divides in a way it never does again.

- **Writable now: `SPEC.md`, `ROADMAP.md`, `TASKS.md`.** These state intent, and
  the intent exists before the code does. The requirements, the order of the
  phases, and the first phase's tasks are the reason the repository is being
  created, so writing them first is the planning set working as designed rather
  than paperwork ahead of the work.
- **Not yet: `PLAN.md`, `CHANGELOG.md`.** These record history. `PLAN.md`
  describes the change currently in flight, and there is none; `CHANGELOG.md`
  records what changed for consumers who install or upgrade independently of the
  source, and there are none. Defer both, and step 7 records the condition.
- **`DECISIONS.md` is the exception, and it is writable now for the opposite
  reason.** The choices made while a repository is created -- the language, the
  framework, the host, the shape, what the project deliberately will not do --
  are exactly the ones whose rationale cannot be recovered from the code a year
  later, and they are being made right now. Record them as the first entries,
  each with the alternatives it rejected.

`PLAN.md` and `DECISIONS.md` are one mechanism, and the rule is never to adopt the
plan without the log, not the reverse. So `DECISIONS.md` lands alone here and the
first non-trivial change brings `PLAN.md` with it.

Create nothing there is nothing to write in. A document of headings teaches an
agent nothing, goes stale, and reads as answered, and a later update run reports
it as a stub. The heading rule from step 3 applies to each of these too: keep the
template's heading text where the section is kept, and drop the section otherwise.
A section deliberately dropped is worth an entry in `DECISIONS.md`, which is what
stops a later update offering it back on every run.

`ai-project-manager` owns what goes in these documents once they exist. This skill
decides which exist; that one writes them and keeps them current.

## 5. Copy in a pooled skill only where the stack calls for one

A new repository has authored no skill, so there is no keep-or-promote-or-retire
decision to make. What it may have is a stack that one of the `rwgs/ai-skills`
pool skills already covers.

Copy that skill to `.agents/skills/<name>` and nowhere else, wire the ignored
`.claude/skills` link the way `adopt-baseline` wires it, and record the pool
commit in the marker so a later update can tell a stale copy from a customised
one. Say that the link is per-clone setup: a fresh clone has no Claude Code skills
until someone recreates it.

Skip the step entirely where the stack calls for nothing. An empty
`.agents/skills/` directory is not worth committing, and step 7's marker records
no skills.

## 6. Read the host, and add CI only once there is a check to run

Read the host from the remote the way `adopt-baseline` reads it, and ask wherever
the hostname names no product. A new repository is the case that skill calls
always a question: it frequently has no remote at all yet. Record the host that
was read or given, because the marker's host-specific paths are what say which
host was in use.

A new repository also has no automated check, and no workflow is added to a
repository with no check to run: a green run that runs nothing reports success it
did not earn. So both host-specific artifacts usually wait for the first test.

- Defer the CI definition, and write it with the first check the repository gains,
  derived as `adopt-baseline` derives it rather than copied.
- Defer the dependency-update configuration with it. It exists to keep the CI
  definition's action pins current, so it has nothing to update until that file
  exists. On a host with no counterpart, decline it outright with the host named,
  which is a refusal rather than a deferral.

Add both now instead wherever the repository genuinely arrives with a check, as it
does when a generator or a template ships a test suite in the first commit. The
rule is about whether a check exists, not about how old the repository is.

## 7. Record what was taken, and what is only deferred

Write and commit `.agents/baseline.json` exactly as `adopt-baseline` specifies:
the same fields, the same full 40-character commits in both places, and the same
requirement that each commit is read from a clone whose `git status --porcelain`
prints nothing.

One thing differs, and it is why this step is not a pointer like the others. What
an adopting repository declines, it mostly declines for good, and its reason says
why the repository does not want the artifact. What a new repository leaves out,
it mostly leaves out because there is nothing to put in it yet. Both are the same
absent file, and the marker is the only thing that separates them.

So write each deferral's reason as the condition that reopens it, in the same
`declined` field:

```json
  "declined": {
    "PLAN.md": "deferred: no change in flight yet; it arrives with the first non-trivial change, and DECISIONS.md is already here",
    "CHANGELOG.md": "deferred: nothing installs or upgrades this independently of its source yet",
    ".github/workflows/validate.yml": "deferred: no automated check to run yet; derive it with the first test",
    ".github/dependabot.yml": "deferred: nothing pinned to keep current until the workflow exists"
  }
```

An update run reports every declined artifact once with its recorded reason, so a
condition written this way comes back in front of someone as soon as it is met. A
flat "not needed" reads as closed and stays closed, which for a repository whose
answer was only "not yet" loses the artifact permanently.

## Safety rules

- Never run this in a repository that holds work of its own. That is
  `adopt-baseline`, and it reconciles rather than overwrites.
- Never run this over an existing `.agents/baseline.json`.
- Never commit anything before `.gitattributes`, and never fold a later
  renormalisation into another change.
- Never commit `.claude/skills` or `.claude/settings.local.json`. Ignore both in
  the first commit, before either can exist.
- Never create a document there is nothing to write in yet, and never leave a
  heading with nothing under it.
- Never adopt `PLAN.md` without `DECISIONS.md`.
- Never leave a deferral without the condition that reopens it.
- Never add a CI definition to a repository with no check to run, and never copy
  one that runs the baseline's own checks.
- Never infer a host from a hostname that names no product, and never offer a
  host's artifact to a repository on another host.
- Never leave a second copy of a skill under `.claude/skills/<name>`.
- Never record a commit read from a clone with uncommitted changes.
- Never keep a second list of what a repository may take. `adopt-baseline` holds
  it, so extending the baseline extends one list.

## Validation

- `git status --porcelain` prints nothing: everything created is committed,
  including the marker.
- `git add --renormalize .` stages nothing, so nothing was committed under the
  wrong line endings.
- `git check-ignore -v .claude/settings.local.json .claude/skills` names the rule
  matching each, whether or not either exists yet.
- `CLAUDE.md` imports `AGENTS.md` on a line of its own and carries no
  instructions, and `AGENTS.md` describes this repository rather than a template.
- Every planning document created says something about this project under every
  heading it keeps.
- `DECISIONS.md` exists wherever `PLAN.md` does, and holds the choices made while
  creating the repository.
- Each pooled skill exists once, under `.agents/skills/`, and the marker records
  the pool commit it came from.
- Any CI definition added names only checks this repository has, and a dispatched
  or pushed run passes rather than being assumed to.
- `.agents/baseline.json` parses, is committed, and holds the baseline commit,
  every artifact taken, a reason for every one left out, and a pool commit for
  each copied skill.
- Every reason recorded for a deferral names the condition that reopens it, so a
  later update run can act on it.
- Every path the marker records as taken exists, and every path it records as
  declined does not.
- Each agent, asked to list its active instruction sources and skills, reports the
  repository instructions and the expected skills.
