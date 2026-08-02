# Decide the default-branch ruleset question

Approach for the change currently in flight. Replaced when the next non-trivial
change begins, so anything that must outlive it is promoted first: verified
product facts to `SPEC.md`, actionable work to `TASKS.md`, and closed choices to
`DECISIONS.md`.

The readiness-gate plan this replaces was already promoted. Its decision is in
`DECISIONS.md` as "Local readiness names the review it did not get", and its
evidence is recorded against the closed task in `TASKS.md`.

## Problem

`TASKS.md` asks whether a default-branch ruleset is worth configuring at all, on
the premise that "every gate previously planned here required a pull request or a
second reviewer, and neither exists in a single-maintainer flow". The premise is
worth testing before the question is answered from it, because a ruleset is not
only a merge gate.

`docs/WORKFLOW.md` has a `Default-branch enforcement` row in its per-host table
with no capability rule above it, so the one thing the table says about branch
protection is unattached to any rule the baseline asks a repository to meet.

## Approach

Read the two facts the decision turns on rather than recalling either.

- What a ruleset can enforce, and specifically which rules apply to a direct push
  rather than to a pull-request merge. Read from GitHub's own rule reference.
- Whether this repository can configure one at all. Read from the API with the
  authenticated token, not from an assumption about the plan.

Then answer both halves separately: whether the mechanism is worth having, and
whether this repository can have it. Where those two answers disagree, the result
is an accepted exception with a reopening condition, which is what the security
baseline already asks for wherever a host provides nothing.

Close the gap the question exposed in the baseline: give the
`Default-branch enforcement` row the capability rule it lacks, stated so a
single-maintainer repository can meet it.

## Findings

Both reads changed the answer.

Nine of the sixteen branch rules GitHub documents are enforced on a direct push
and need neither a pull request nor a reviewer, so the premise is wrong. The
seven that need a pull request are the merge gates: linear history, deployments,
a pull request itself, status checks, code scanning, code quality, and coverage.
The push-enforced nine include the two an accident-guard actually wants, blocking
a force push and blocking deletion, and those matter *more* without a reviewer
rather than less, because nothing else stands between a mistyped command and the
history.

This repository cannot configure any of it. Read on 2026-08-02 with a token
carrying `repo` scope, three endpoints return the same HTTP 403 with the message
`Upgrade to GitHub Pro or make this repository public to enable this feature.`:
`GET /repos/rwgs/ai/rulesets`, `GET /repos/rwgs/ai/rules/branches/main`, and
`GET /repos/rwgs/ai/branches/main/protection`. The account is a `User` with no
plan visible to the token, and the repository is private.

## Trade-offs

- The rule split is read from GitHub's documentation and cannot be tested here,
  because the API refuses the read that would show it. That is recorded rather
  than implied.
- The exception is the outcome for this repository, and an exception is weaker
  than a control. Making the repository public or buying a plan would both
  resolve it, and neither is worth doing for this reason alone, so the reopening
  condition names both.

## Verification

- `./scripts/validate.sh` under WSL, reporting which checks it performed.
- Re-read the security baseline after the edit, so the new rule and its table row
  agree and no rule is left without a mechanism.
- No three-platform run is expected: the change touches no script, no workflow,
  and no installed path.
