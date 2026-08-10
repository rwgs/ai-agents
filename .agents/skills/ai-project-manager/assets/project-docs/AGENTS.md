# Project instructions

The conventions an agent needs in every session for this repository, loaded
automatically rather than pointed at. Keep it short enough to follow: a rule
earns its place by preventing a repeat mistake or recording durable project
behavior, and reference material belongs under `docs/`.

## Purpose

What this project is, who uses it, and the outcome it delivers.

## Architecture

- The directories and components that matter, and what each one owns.
- Which files are generated, so they are regenerated rather than edited.
- The supported toolchain and the target environments.

## Working boundaries

- Leave unrelated changes exactly as found. Every changed line traces to
  something the request asked for, so raise a simpler approach or an unrelated
  defect rather than acting on it.
- Make the smallest change that solves the stated problem. Add no speculative
  feature, abstraction for a single call site, configuration knob, or handling for
  a case that cannot occur.
- Match the naming, layout, and style already in the file, even where a different
  approach would be the better call in a new project.
- Remove what the change orphans, such as an import nothing uses. Leave
  pre-existing dead code alone unless asked to remove it, and mention it where it
  matters.
- Never commit or print credentials, sessions, private data, or environment
  files.
- Ask before destructive work. Deleting, overwriting, resetting, force-pushing,
  migrating, and deploying are not implied by a request to fix something.
- Ask before a change that settles a product or architecture question, rather
  than implementing one already settled.

## Before editing

- State the plan, or what success looks like, before editing, as a check that can
  fail rather than a description: the test that reproduces the bug, the test for
  the input that must be rejected, the same tests passing either side of a
  refactor. Pair each step of multi-step work with the check that confirms it.
- Settle an ambiguity by reading the code or running a command wherever that is
  practical, and state any assumption that changes the result. Ask where the
  readings lead to materially different work.
- Say when a simpler approach than the one asked for would do, and challenge a
  wrong premise before building on top of it.

## Commands

The exact setup, formatting, lint, type-check, test, build, and run commands
this repository uses. Exact, because a command that is nearly right fails in a
way that looks like a broken project.

## Validation

- Run the focused check while implementing.
- Run the complete required local gate before reporting done.
- Inspect the final status and diff, and confirm every changed line traces to
  something the task asked for.
- Verify visible behavior with screenshots or equivalent rendered output.
- Report skipped checks and outstanding manual testing rather than omitting
  them.

## Documentation routing

- `SPEC.md` for requirements and acceptance criteria.
- `ROADMAP.md` for phase order and exit criteria.
- `TASKS.md` for current work and validation status.
- `PLAN.md` for the approach behind the change currently in flight.
- `DECISIONS.md` before changing an area it constrains, and before proposing an
  approach it already rejected.
- `README.md` is where a human or an agent arriving cold starts, and it owns none
  of the above. It links to these documents, and to the files it describes,
  rather than restating them: an explanation kept away from what it explains
  drifts from it silently.
