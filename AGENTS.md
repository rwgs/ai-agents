# Repository instructions

## Scope

This repository holds the portable Claude Code and Codex setup: one shared
instruction file, the Codex configuration, the command rules both permission
systems derive from, and the skills installed on every machine. This file is the
maintenance guide for the repository itself, and both agents load it from the
repository root without being told to.

## Operating principles

- Deliver working code. Looking right is not evidence; run it.
- Say what is unknown instead of filling the gap. Paths, APIs, commit hashes,
  command output, and test results are read or run, never recalled.
- Challenge a wrong premise before building on top of it.
- Settle an ambiguous request yourself, and ask only when the readings lead to
  materially different work.
- Change what the task needs and nothing beside it. No drive-by refactors,
  reformatting, or tidying.
- Write plainly: no preamble, no flattery, no emoji.

## Command execution

- Route a command through `rtk` when its output is long or repetitive and a
  summary answers the question: test suites, builds, linters, logs, wide
  searches, dependency listings, infrastructure status.
- Run it raw when the output is short, when the exact bytes matter, or when
  looking at one file or one narrow result.
- In a chain, wrap only the noisy segment.
- Drop back to raw whenever RTK hides something needed, refuses a flag, or gets
  in the way of a diagnosis. `rtk proxy` is not a box to tick.
- Shell and command-line work is the exception that proves the rule: filter
  noisy validation, but keep stdout, stderr, exit status, quoting, and pipeline
  behavior raw, because those are the thing under test.
- Run the code, the tests, the linter, the type checker rather than predicting
  what they would say.
- Read the whole error, log, or stack trace before changing anything.

## Before editing

- State the plan or success criteria before editing. For non-trivial work,
  include the verification you expect to run and record the approach in
  `PLAN.md` so it survives the conversation and appears in review.
- Read the files you will touch and the nearby callers, consumers, or docs that
  define their behavior.
- Match existing project patterns, naming, layout, and style even if a different
  approach would be appealing in a new project.
- Resolve ambiguity by reading code or running commands when practical; surface
  assumptions out loud when they affect the result.

## Editing

- Use simple ASCII punctuation unless a file format requires otherwise.
- Keep credentials, tokens, sessions, history, caches, logs, and runtime
  databases out of this repository.
- Put reusable workflows in `.agents/skills/<name>/SKILL.md`.
- Put instructions that apply to every repository in `ai-home/AGENTS.md`; it is
  installed as the global instructions for both agents.
- Put configuration shared by both agents in `ai-home/`, and Codex-specific
  portable configuration in `ai-home/codex/`. Claude Code has no equivalent
  directory: its `settings.json` is merged by the installer rather than linked,
  because it accumulates interactively approved permissions.
- Put project maintenance instructions in this file.
- Do not assume files in `docs/` are loaded automatically.
- Use the minimum code or documentation change that solves the stated problem.
- Do not add speculative features, abstractions, configurability, or hooks.
- Do clean up orphans created by your own change, such as unused imports or
  obsolete helper functions.
- Do not delete pre-existing dead code unless asked; mention it in the summary
  if it matters.

## Documentation routing

Read only the documents needed for the task:

- `SPEC.md` for product requirements, boundaries, and acceptance criteria.
- `ROADMAP.md` for ordered outcomes, risks, and phase exit criteria.
- `TASKS.md` for the current phase, validation status, and remaining work.
- `PLAN.md` for the approach behind the change currently in flight.
- `DECISIONS.md` before changing an area it constrains, and before proposing an
  approach it already rejected.
- `docs/AGENT_LAYOUT.md` for Claude and Codex discovery and installation
  boundaries.
- `docs/RTK.md` for the full RTK command catalog.
- `docs/SKILLS.md` when creating or changing skills.
- `docs/WORKFLOW.md` when changing the repository development workflow.

## Verification

- Run the smallest meaningful verification during iteration and the requested or
  relevant final verification before reporting done.
- If verification fails, fix the cause instead of weakening the check.
- For UI or visual changes, verify visually with screenshots or equivalent
  rendered output.
- Run `./scripts/validate.sh` after changing configuration, skills, install
  scripts, or repository layout.
- Run `./scripts/test-install.sh` directly when diagnosing Linux or macOS
  installer behavior. Windows installer behavior is covered by
  `./scripts/test-install.ps1` in CI.
- Run validation from an environment that can create symbolic links. Git Bash on
  Windows cannot, so the installer integration test fails there on a clean tree;
  WSL passes in full.

## Version control

- Commit each completed change to `main` once its verification passes, without
  waiting to be asked. This repository has one maintainer: do not create a branch
  or a pull request, and do not propose either as a review step.
- Push only when asked.
- When a change needs evidence only CI can produce, such as installer behavior on
  a platform this environment cannot exercise, say so and ask to push. A push to
  `main` now starts the validation workflow by itself, so read that run. Dispatch
  only when there is nothing to push; dispatching for a commit that was just
  pushed cancels one of the two runs, because both land in the same concurrency
  group. Never open a pull request for it.

## Maintenance

- Keep this file short enough to follow. Add rules only when they prevent a real
  repeat mistake or document durable project behavior.
- When the user corrects an approach, tighten the relevant rule instead of
  appending a vague warning.
- Before replacing `PLAN.md`, promote the decisions that constrain future work
  into `DECISIONS.md` with the alternatives they rejected, and the verified facts
  that change how the project is understood into `SPEC.md` or this file.
- Add a `CHANGELOG.md` entry when a change alters what installation does to a
  machine. Repository-internal changes stay in the commit history.
