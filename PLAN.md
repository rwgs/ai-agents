# Make the dependency-update mechanism work and cost what it is worth

Approach for the change currently in flight. Replaced when the next non-trivial
change begins, so anything that must outlive it is promoted first: verified
product facts to `SPEC.md`, actionable work to `TASKS.md`, and closed choices to
`DECISIONS.md`.

The ruleset plan this replaces was already promoted. Its decision is in
`DECISIONS.md` as "The default branch is worth protecting and cannot be protected
here", and its evidence is recorded against the closed task in `TASKS.md`.

## Problem

Phase 7 wants the retained dependency-update mechanism verified operational.
Reading it produced three findings instead of a confirmation.

Dependabot has never opened a pull request on this repository. The first reading
attributed that to there being nothing to bump, which was wrong: the pinned
`github/codeql-action` commit is five commits behind the `v4.37.4` release
commit, and the difference includes the action's default CodeQL bundle. So the
mechanism has had work available and has produced nothing.

The likely cause is in this repository rather than in Dependabot. The two pins
follow different tag streams: `actions/checkout` names a version tag and
`github/codeql-action` names `codeql-bundle-v2.26.2`. Dependabot reads the
trailing comment to decide what version an action is currently pinned at, and a
bundle tag is not a point on the semver stream it compares against.

Separately, the cadence is wrong for this repository, and the measurement is what
shows it. In the thirteen weeks to 2026-07-30, `github/codeql-action` published
twelve version tags and `actions/checkout` published two on the line it tracks.
Weekly, ungrouped updates over a two-action dependency surface annualise to
roughly fifty pull requests, each firing a ten-minute three-platform run, on a
repository with one maintainer.

Dependabot on GitHub is also two switches and the documents here describe one.
Version updates come from `.github/dependabot.yml`, which is configured; security
updates are a repository setting, which is off while Dependabot alerts are on.

## Approach

Fix the cause before tuning the cadence, because a mechanism that produces
nothing cannot be judged by how often it would produce it.

- Repin both `github/codeql-action` steps to the `v4.37.4` release commit with a
  version comment, so both pins name the same kind of ref and "current" has one
  meaning. This makes the pin current and removes the suspected reason Dependabot
  is silent in the same edit.
- Set the schedule to monthly and group every `github-actions` bump into one pull
  request, which turns roughly fifty reviews a year into twelve.
- Enable Dependabot security updates, which matters more once routine bumps are
  monthly, because it becomes the only thing that will not wait up to a month for
  an advisory.
- State the two switches in the security baseline and record the whole shape in
  `DECISIONS.md`, including the rule that a pin names a version tag.

## Trade-offs

- Monthly and grouped means a bump can sit unmerged for up to a month. Accepted:
  the pins are a supply-chain control against an action moving under a mutable
  ref, not a patch cadence, and security updates cover the case where waiting is
  wrong.
- Repinning to the release commit changes the action's default CodeQL bundle.
  Nothing observable here depends on which bundle runs, because code scanning is
  disabled on this repository and the workflow cannot upload results at all.
- The Dependabot diagnosis stays a hypothesis. No REST endpoint exposes a
  version-update job, so the fix is also the test: if the pin comment was the
  cause, the next monthly run behaves normally. That is recorded as unproven
  rather than claimed.

## Verification

- `./scripts/validate.sh` under WSL, reporting which checks it performed.
- Parse both changed YAML files and confirm the pinned commit is the one the
  comment names, read from the API rather than from this plan.
- Confirm the security-updates setting reports enabled after the change.
- No three-platform run is expected from the configuration edits themselves. The
  CodeQL workflow is dispatch-only until code scanning is enabled, so the repinned
  steps are exercised by a dispatch rather than by a push.
