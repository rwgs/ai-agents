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
- Challenge a wrong premise before building on top of it, and say when a simpler
  approach than the one asked for would do.
- Stop at any ambiguity in the request, before editing anything. Name what is
  unclear and the readings it admits, and wait for an answer rather than picking
  one silently or proceeding on the likeliest reading.
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

- Say what the plan is, or what success looks like, before editing. For
  non-trivial work name the verification you expect to run, and put the approach
  in `PLAN.md`, where it outlives the conversation and shows up in review.
- State success as a check that can fail rather than as a description: the test
  that reproduces the bug, the test for the input that must be rejected, the same
  tests passing either side of a refactor. Pair each step of a multi-step plan
  with the check that confirms it, so the loop closes without asking.
- Read the files you are about to change, and whatever nearby defines their
  behavior: callers, consumers, documentation.
- Follow the patterns, naming, layout, and style already here, even where a
  different approach would be the better call in a new project.
- An unread fact is not an ambiguity. Read the code or run the command that
  settles it, and state any assumption that changes the result.

## Editing

- Stick to plain ASCII punctuation unless the file format demands otherwise.
- No credential, token, session, history file, cache, log, or runtime database
  belongs in this repository.
- A reusable workflow goes in `.agents/skills/<name>/SKILL.md`.
- Put instructions that apply to every repository in `ai-home/AGENTS.md`; it is
  installed as the global instructions for both agents.
- Put configuration shared by both agents in `ai-home/`, and Codex-specific
  portable configuration in `ai-home/codex/`. Claude Code has no equivalent
  directory: its `settings.json` is merged by the installer rather than linked,
  because it accumulates interactively approved permissions.
- Instructions for maintaining this project go in this file.
- Nothing under `docs/` is loaded automatically; assume it is unread until
  something points at it.
- Make the smallest code or documentation change that solves the stated problem,
  and rewrite your own work before reporting it when the same result fits in
  substantially less code.
- Add no speculative feature, abstraction for a single call site, configuration
  knob, hook, or handling for a case that cannot occur.
- Clean up whatever your own change orphans, such as an import nothing uses or a
  helper nothing calls.
- Leave pre-existing dead code alone unless asked to remove it, and mention it
  in the summary when it matters.

## Documentation routing

Read the documents the task needs, and no others:

- `SPEC.md` for the requirements, the boundaries, and the acceptance criteria.
- `ROADMAP.md` for the order of outcomes, their risks, and each phase's exit
  criteria.
- `TASKS.md` for the current phase, what has been validated, and what is left.
- `PLAN.md` for the approach behind the change currently in flight.
- `DECISIONS.md` before changing an area it constrains, and before proposing an
  approach it already rejected.
- `docs/AGENT_LAYOUT.md` for Claude and Codex discovery and installation
  boundaries.
- `docs/RTK.md` for the full RTK command catalog.
- `docs/SKILLS.md` when writing or changing a skill.
- `docs/WORKFLOW.md` when changing how development in this repository works.

## Verification

- Run the smallest meaningful check while iterating, and the requested or
  relevant full one before reporting done.
- When a check fails, fix what it caught rather than weakening the check.
- Read the final diff before reporting done, and confirm every changed line
  traces to something the task asked for.
- Verify a UI or visual change by looking at it: a screenshot, or equivalent
  rendered output.
- Run `./scripts/validate.sh` after touching configuration, a skill, an install
  script, or the repository layout.
- Run `./scripts/test-install.sh` on its own when diagnosing Linux or macOS
  installer behavior. Run `./scripts/test-install.ps1` from Windows for the
  Windows installer, under both editions; it needs no privilege and no longer
  depends on CI. It reports the two stale-link fixtures it skips when the shell
  cannot create a symbolic link, which CI covers because it runs elevated.
- The Bash installer integration test creates symbolic links, so run
  `./scripts/validate.sh` from an environment that can. Git Bash on Windows
  cannot, so it fails there on a clean tree; WSL passes in full.
- Avoid reading a file into a byte array and writing one back in the PowerShell
  installer. Defender's AMSI blocks the whole script as malicious when it does,
  which reads as a parser error on line 1. `Copy-Item`, `WriteAllText`, and
  `Get-FileHash` do the same work and are not flagged.
- `./scripts/validate.sh` skips ShellCheck, the Node syntax check, and both
  PowerShell checks wherever those tools are absent, and the WSL installation
  here has none of the three. Report which checks a run performed rather than
  that validation passed, and run the PowerShell ones from Windows.

## Version control

- Commit each completed change to `main` once its verification passes, without
  waiting to be asked. This repository has one maintainer: do not create a branch
  or a pull request, and do not propose either as a review step.
- Push only when asked.
- When a change needs evidence only CI can produce, such as installer behavior on
  a platform this environment cannot exercise, say so and ask to push. Never open
  a pull request for it.
- CI evidence here means GitHub Actions, because that is where this repository is
  hosted. A push to `main` starts the validation workflow by itself, so read that
  run. Dispatch only when there is nothing to push; dispatching for a commit that
  was just pushed cancels one of the two runs, because both land in the same
  concurrency group. `azure-pipelines.yml` runs the same gate on Azure DevOps and
  has never run, so it is not a source of evidence and a green claim must not
  rest on it.

## Maintenance

- Keep this file short enough to follow. A rule earns its place by preventing a
  mistake that actually recurred, or by recording durable project behavior.
- When the user corrects an approach, tighten the rule it belongs to rather than
  appending another vague warning.
- Before replacing `PLAN.md`, promote the decisions that constrain future work
  into `DECISIONS.md` with the alternatives they rejected, and the verified facts
  that change how the project is understood into `SPEC.md` or this file.
- Add a `CHANGELOG.md` entry when a change alters what installation does to a
  machine. Repository-internal changes stay in the commit history.
