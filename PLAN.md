# Ask the API to enable scanning, and record whichever answer comes back

Approach for the change currently in flight. Replaced when the next non-trivial
change begins, so anything that must outlive it is promoted first: verified
product facts to `SPEC.md`, actionable work to `TASKS.md`, and closed choices to
`DECISIONS.md`.

The dependency-update plan this replaces was already promoted. Its decision is in
`DECISIONS.md` as "Dependency updates are monthly, grouped, and pinned to a
version tag", and its evidence is recorded against the closed task in `TASKS.md`.

## Problem

Phase 7 has two items left and both are written as a setting to visit: confirm
secret scanning and push protection, and enable code scanning for this private
repository. Each has been read three times, on 2026-08-02 twice and again today,
and every read reports the same disabled state.

The reads cannot answer the question. `security_and_analysis: null`, HTTP 404 from
the secret-scanning alerts endpoint, and HTTP 403 from the code-scanning alerts
endpoint say the products are off; none of them distinguishes a switch nobody has
flipped from a product this account does not have. So the phase has sat blocked on
a settings visit whose sufficiency was never established, and the ruleset entry in
`DECISIONS.md` had already predicted the plan boundary would be the first thing to
check, because both products are sold for a private repository.

Nobody had tried to write them. The same token wrote the Dependabot
security-updates switch on 2026-08-02, so a write is available and its refusal
carries a reason where a read carries only a state.

## Approach

Attempt the enablement, one product per request so a failure attributes to one
product, then record whichever answer comes back.

- `PATCH /repos/rwgs/ai` for `secret_scanning`, then
  `secret_scanning_push_protection`, then `advanced_security`, and
  `PATCH /repos/rwgs/ai/code-scanning/default-setup` for CodeQL, reading the state
  back after each rather than trusting the status code.
- If the API enables them, confirm through the alerts endpoints and close both
  items as the enablements they are.
- If it refuses, record both as one accepted exception in `DECISIONS.md` with a
  reason, an owner, and the conditions that reopen it, which is the shape the
  ruleset entry already uses for the same plan boundary.
- State in the `docs/WORKFLOW.md` security baseline that a settings change is
  confirmed by reading the state back, and that this repository has the exception.
- Restate the Phase 7 exit criterion so a recorded reason can meet it, as its
  CodeQL criterion already allows, and close the phase if nothing else is
  outstanding.

## Trade-offs

- A write against live repository settings is not a read. Accepted: enabling these
  two products is what the tasks ask for, each is reversible through the same
  endpoint, and the token has already been used this way for security updates.
- An accepted exception leaves this repository with nothing scanning for committed
  secrets and nothing analysing its Python and JavaScript. Named rather than
  absorbed: the compensating controls are the `AGENTS.md` rule that no credential
  belongs here and the `scripts/validate.sh` check that rejects the specific Codex
  credential and runtime files by name, which is narrower than secret scanning by
  every measure except those filenames.
- Closing Phase 7 on a recorded reason means the repository documents a control it
  does not run. That is the baseline's own answer where a host offers nothing, and
  the alternative is a phase that stays open until a purchase decision is made.

## Verification

- Quote each response, not the intent: the status code and the message from the
  API, and the state read back afterwards.
- `./scripts/validate.sh` under WSL, reporting which checks it performed.
- No three-platform run. The change touches no script, no workflow, and no
  installed path.

Done. All four writes were refused or ineffective, so the exception is what
shipped. Secret scanning returns HTTP 422 `Secret scanning is not available for
this repository.`, advanced security HTTP 422 `Advanced security has not been
purchased.`, the code-scanning default setup HTTP 403, and push protection returns
HTTP 200 while leaving itself disabled. The evidence is recorded against both
closed tasks in `TASKS.md`, and the read-it-back rule the 200 produced is in the
security baseline.
