# AI tasks

## Completed phase: Workflow alignment

- [x] Add project planning documents and reusable planning templates.
- [x] Add a focused pull-request readiness skill.
- [x] Add isolated Linux, macOS, and Windows installer integration tests.
- [x] Add pull-request CI, dependency review, Dependabot, and a PR template.
- [x] Align Claude routing and workflow documentation.
- [x] Add opt-in, cross-platform installation for selected Codex plugins.
- [x] Trust all Git worktrees beneath the current user's `~/github` directory.
- [x] Run local repository, shell, installer, workflow, and skill validation.
- [x] Confirm Windows installer integration, including plugin installation and
  recursive GitHub trust generation, passes in CI.
- [x] Inspect the final diff and stage only workflow-alignment changes.

## Current phase: Claude and Codex parity

- [x] Rename `codex-home/` to `ai-home/` and split shared and per-agent files.
- [x] Link the shared instruction file to both agents' global instruction paths.
- [x] Link every skill into `~/.claude/skills/` as well as `~/.agents/skills/`.
- [x] Derive Claude permissions from `default.rules` and merge them safely.
- [x] Reduce `CLAUDE.md` to `@AGENTS.md` and move the RTK catalog to `docs/RTK.md`.
- [x] Update the specification, roadmap, layout, and skill documentation.
- [x] Rename PowerShell functions to approved verbs and singular nouns, and add
  PSScriptAnalyzer to local validation and CI.
- [x] Add a `PLAN.md` convention, template, and documentation routing.
- [x] Add the `powershell-scripting` skill.
- [x] Make skill descriptions agent-neutral and separate the host and fleet
  sysadmin triggers.
- [x] Add the `adopt-baseline` skill for standardising existing repositories.
- [x] Add the `web-development` skill and drop product-specific skills from the
  default set.
- [x] Prune stale managed skill links on every install.
- [x] Install the Superpowers plugin into Claude Code as well as Codex, adding
  its marketplace first because Claude Code registers none until first use.
- [x] Skip a missing agent's plugins with a warning instead of failing the run.
- [x] Narrow the default skill set to workflow, language, and project skills by
  dropping the systems administration, infrastructure, and container skills.
- [x] Run repository, shell, installer, and skill validation locally.
- [ ] Confirm the Windows installer integration test passes in CI. The first run
  ever to execute, dispatched manually as run `30653338945`, failed on
  `windows-latest` while `ubuntu-latest` and `macos-latest` passed. Stale-link
  pruning called `[System.IO.Directory]::Delete` on a link Windows had recorded as
  a file, because `New-Item -ItemType SymbolicLink` produces a file reparse point
  when the target does not exist, which is how `scripts/test-install.ps1`
  fabricates the stale link. `install.sh` uses `rm -f` and is unaffected. Fixed by
  deleting through the entry itself; awaiting a CI run to confirm.
- [x] Inspect the final diff and stage only parity changes.

## Current phase: Decision records

- [x] Add `DECISIONS.md`, register it in the validator's required-file list, the
  `AGENTS.md` routing list, and the `docs/WORKFLOW.md` role table.
- [x] Record the first four decisions: the closed planning set, promotion out of
  `PLAN.md`, one plugin manifest per agent, and one shared instruction file.
- [x] Add the promotion trigger to `AGENTS.md` maintenance and the
  `docs/WORKFLOW.md` lifecycle, so the log has a write step rather than only a
  read route.
- [x] Add the `DECISIONS.md` template to `ai-project-manager` and wire it into
  the skill's discovery, promotion step, safety rules, and validation.
- [x] Promote the Claude Code marketplace registration finding from `PLAN.md`
  into `SPEC.md`, and move the resolved instruction-link question out of the
  `SPEC.md` "Unresolved questions" section.
- [x] Record the commit-to-`main` rule in `AGENTS.md` so it binds both agents
  rather than living in Claude Code's memory store.
- [x] Add `CHANGELOG.md`, backfill the installer-visible history, and add the
  conditional template and skill step to `ai-project-manager`. Record the
  superseding decision, because an earlier entry rejected the file.
- [x] Remove the untracked-by-purpose `.serena/` configuration and ignore it. It
  named a different project, declared TypeScript for a repository that has none,
  and nothing here referenced it.
- [x] Move `default.rules` out of `ai-home/codex/` to `ai-home/rules/` so the
  shared permission source is not filed under one agent, and correct the
  `AGENTS.md` claim that `ai-home/claude/` exists.
- [x] Run repository, shell, installer, and skill validation on a platform where
  the installer integration test can create symbolic links. Git Bash on Windows
  cannot, and that failure reproduces on a clean tree. WSL passes in full.
- [ ] Confirm validation passes in CI on Linux, macOS, and Windows. Linux and
  macOS are confirmed by run `30653338945`; Windows waits on the pruning fix above.
- [ ] Find out why no push has ever triggered the workflow. Actions is enabled,
  all actions are allowed, `Validate` is registered and active with a
  `push: branches: [main]` trigger, and commits have been pushed to `main`, yet
  the repository had zero workflow runs and zero check runs until one was
  dispatched by hand. Until this is explained, no push-triggered run can be
  treated as evidence, and every CI confirmation here rests on a manual dispatch.

## Completed phase: Line endings and manifest ergonomics

- [x] Refresh this checkout so the working tree matches `.gitattributes`. It
  predated that file and carried CRLF throughout, so `scripts/validate.sh` could
  not run from WSL. Re-checking the tree out also cleared stale index stat data
  that reported thirteen byte-identical files as modified.
- [x] Fail validation when a tracked file other than `*.ps1` contains a carriage
  return, so line-ending drift is caught by a check instead of discovered
  part-way through an unrelated change. The pattern is built with `printf`
  because Git Bash's Bash drops a `$'\r'` word, and an empty pattern matched
  every tracked file instead of none.
- [x] Allow `#` comments and blank lines in `codex-plugins.txt` and
  `claude-plugins.txt`, so each manifest can explain why a Claude Code entry
  carries a marketplace URL and a Codex entry does not. Both installers, the
  validator, and both installer tests read these files and all of them skip the
  new lines. This reverses part of the manifest decision recorded in
  `DECISIONS.md`, so a superseding entry was added rather than editing that one.

## Current phase: A versioned skill pool

- [x] Decide where the optional skill pool lives. It was in an unversioned
  `~/OneDrive/Development/ai/skills-optional/`, holding nine skills, and nothing
  recorded that. It is now its own repository, because a pool skill is copied into
  a repository and only a commit gives drift something to compare against.
- [x] Build the pool repository locally at `~/Development/ai-skills`, outside
  OneDrive so no `.git` directory is synced, with a README covering how a
  repository draws a skill in.
- [x] Move `python-ai` and `rust-cli` to the pool. `python-ai` reads as a Python
  skill and covers only Python AI applications.
- [x] Add `python-scripting` for the general Python work that nothing covered.
- [x] Split `web-development`, extracting its stack-agnostic browser and
  local-server rules into `web-verification`. Those rules apply to a site with any
  backend but fired only on `.js` and `.ts`, and two of the browser-facing
  repositories here have no `package.json` at all.
- [x] Move `web-development` to the pool as well, and record why. It was kept
  installed at first on reach, two of eight local repositories, which is a
  frequency test with no threshold. The criterion recorded instead is whether an
  agent reaches for the language as a tool in any repository or works in it because
  it is the project's stack, which keeps shell and Python and pools Rust and
  TypeScript.
- [x] Promote the one rule in `web-development` that matters without the skill
  loaded, detecting the package manager from the lockfile, to `ai-home/AGENTS.md`.
- [x] Push the pool to the private `rwgs/ai-skills` remote. All ten skills are on
  `origin/main` at `4c6cf88`. `gh` is installed in neither Git Bash nor PowerShell
  here, so the repository was created outside this environment.
- [x] Delete `~/OneDrive/Development/ai/skills-optional/`, after confirming all
  thirty files were content-identical to the pushed pool and differed only in line
  endings. The emptied parent directory went with it.
- [ ] Install on this machine, which needs symbolic links: Developer Mode has never
  been enabled here, the `AppModelUnlock` key is absent, and the shell is
  unelevated, so every link fails with an administrator-privilege error. Nothing is
  installed yet either, so this is a first install and not a rerun: there are no
  stale `python-ai`, `rust-cli`, or `web-development` links to prune.
- [ ] Decide what the installer does about the Codex state recorded in the
  `SPEC.md` "Machine-owned agent state" section before installing here. The
  additive steps are safe; linking `rules/` and rendering `config.toml` are not.

## Later phase: Reconcile installation with machine-owned Codex state

- [ ] Merge `config.toml` rather than rendering it, preserving every key the
  machine owns, and generate trust entries for the roots repositories actually
  live under instead of `~/github` alone.
- [ ] Settle whether `ai-home/rules/` can be linked at all, given that Codex
  writes approved prefix rules into `default.rules`. Linking makes this repository
  the store for one-off session approvals; the alternative is the merge treatment
  `settings.json` already gets.
- [ ] Record the outcome in `DECISIONS.md` as a superseding entry. The accepted
  2026-06-21 entry lists the rules directory as fully repository-owned and
  justifies rendering `config.toml` by trust entries alone, and both halves of
  that premise are now known to be wrong.
- [ ] Cover the new behavior in `scripts/test-install.sh`,
  `scripts/test-install.ps1`, and `scripts/validate.sh`, and add a `CHANGELOG.md`
  entry, because this changes what installation does to a machine.

## Later phase: Re-appliable repository baseline

- [ ] Record in an adopting repository which baseline commit it took, which
  documents it adopted, which pieces it declined, and the pool commit behind any
  skill copied from `rwgs/ai-skills`.
- [ ] Add an update mode to `adopt-baseline`, or a sibling skill, that adds
  missing documents and sections and reports drift without overwriting an
  adopted document. It reads both recorded commits, so a copied pool skill is
  reported alongside a stale document.
- [ ] Extend adoption to install `.gitattributes`, and offer the validation
  workflow, Dependabot configuration, and pull-request template.
- [ ] Give a new repository its own entry point instead of a skill named for
  adopting an existing one.
- [ ] Prove the loop on a scratch repository: adopt, change the baseline,
  re-apply, and confirm no customisation is lost and a second re-apply reports
  nothing to do.
- [x] Remove the empty `skills-optional/` directory left on disk by the commit
  that dropped the optional tree. Nothing tracked, ignored, or referenced it.

## Later phase: MCP server management

- [ ] Add an opt-in MCP server manifest and install it with `codex mcp add` and
  `claude mcp add`, leaving MCP state untouched without the explicit option.
- [ ] Choose a manifest format that survives both interfaces: `codex mcp add`
  and `claude mcp add` take different arguments, and Claude Code also accepts
  `claude mcp add-json`.
- [ ] Keep tokens, headers, and credentials out of the repository. Record only
  the command, arguments, and non-secret configuration.

## Later phase: Enforced repository governance

- [ ] Confirm secret scanning, push protection, and Dependabot are enabled.
- [ ] Decide what replaces dependency review. It is gated on
  `github.event_name == 'pull_request'`, so with no pull requests it never runs.
  Either trigger it another way or drop the job rather than leave a check that
  reads as covered.
- [ ] Decide whether a default-branch ruleset is worth configuring at all. Every
  gate previously planned here required a pull request or a second reviewer, and
  neither exists in a single-maintainer flow.

## Completion rule

Move current-phase tasks to completed only after their acceptance criteria and
required validation pass. Keep external GitHub settings pending until verified
through the live repository.
