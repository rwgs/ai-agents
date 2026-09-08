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

## Completed phase: Claude and Codex parity

- [x] Rename `codex-home/` to `ai-home/` and split shared and per-agent files.
- [x] Link the shared instruction file to both agents' global instruction paths.
- [x] Link every skill into `~/.claude/skills/` as well as `~/.agents/skills/`.
- [x] Derive Claude permissions from `default.rules` and add missing entries
  without replacing unrelated settings. The later removal/provenance defect is
  tracked in the current phase.
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
- [x] Confirm the Windows installer integration test passes in CI. The first run
  ever to execute, dispatched manually as run `30653338945`, failed on
  `windows-latest` while `ubuntu-latest` and `macos-latest` passed. Stale-link
  pruning called `[System.IO.Directory]::Delete` on a link Windows had recorded as
  a file, because `New-Item -ItemType SymbolicLink` produces a file reparse point
  when the target does not exist, which is how `scripts/test-install.ps1`
  fabricates the stale link. `install.sh` uses `rm -f` and is unaffected. Deleting
  through the entry itself fixed it, confirmed green on `windows-latest` by run
  `30657841763` on `main`.
- [x] Inspect the final diff and stage only parity changes.

## Completed phase: Decision records

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
- [x] Confirm validation passes in CI on Linux, macOS, and Windows. Run
  `30657841763`, dispatched on `main` at `6ba19e3`, passed `ubuntu-latest`,
  `macos-latest`, and `windows-latest`. `dependency-review` skipped, as it always
  will now.

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

## Completed phase: A versioned skill pool

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
- [x] Remove the empty `skills-optional/` directory left on disk by the commit
  that dropped the optional tree. Nothing tracked, ignored, or referenced it.

## Current phase: Hardening the guarantees the baseline claims

Every finding in `review.md` is fixed. Two were reproduced before the fix and
again after; two more were exercised directly because this environment cannot run
the suite that covers them; one was a claim rather than a defect and was corrected
in the documentation. What is left is evidence, not work: a CI run, and one
observation from the phase below that needed an agent restart.

- [x] Stop the Codex configuration merge turning valid TOML into invalid TOML.
  Both merges now classify every line of the target before touching it, and
  refuse the whole file when one is neither blank, a comment, a table header, nor
  a key, or when a table is declared twice. The merged output is checked by the
  same rule before it is written, so an editing defect is refused rather than
  saved. A refusal preserves the file, reports the line, and returns the recorded
  state unchanged, which is the path the Claude settings merge already took for
  invalid JSON.

  Reproduced first. `[features] # local choices` with `memories = false` made the
  Python merge append a second `[features]`, and `tomllib` rejected the result
  with `Cannot declare ('features',) twice`; `features.memories = false` failed
  the same way. Both now report `preserved: ... cannot parse`, leave the file
  byte-identical, and leave `memories = false` in place. Array-of-tables headers
  and multi-line values are refused by the same rule. This machine's real
  `~/.codex/config.toml`, 85 lines and 28 headers, still passes, as do all three
  shipped profiles, so the guard costs nothing here.

  Both installer tests carry the same two fixtures, asserting preservation, the
  report, and that the file still parses.

- [x] Stop a bootstrap dry run updating the source the agents read. Both scripts
  fetch, report `would update <path> to <revision>`, and leave the branch and
  working tree alone; a first run still clones, because there is nothing to
  preview from until it does.

  Verified against temporary local repositories in both languages: with upstream
  moved from `version one` to `version two`, each dry run reported the pending
  revision, left the clone at its original commit, and left the file reading
  `version one`; each run without the flag updated to `version two`. Both
  installer tests now move a real upstream commit first and assert the clone's
  revision and content are unchanged, because a dry run that changes nothing
  proves nothing when there was nothing to pull in.

- [x] Make skill validation errors reach the exit status. `validate_skill_tree`
  ran inside a command substitution, so every `fail` it called incremented a
  counter in a subshell that then exited. It now collects the inventory in a
  variable and runs in the parent shell.

  Measured both ways on the same fixture, a copy of the repository with every
  skill's `description` line deleted: the committed validator printed nine errors
  and ended `validation passed: 9 skills checked`, exit 0; the fixed one prints
  the same nine and ends `validation failed with 9 error(s)`, exit 1. The
  integration test was stubbed out for both runs, because Git Bash cannot create
  the symbolic link it needs, and stubbing it identically either side is what
  makes the two comparable.

  No automated regression test: the validator's own harness would have to run the
  full installer integration test, which needs a symbolic-link privilege and
  several minutes, so the check would be skipped exactly where it matters.

- [x] Correct the rule decision vocabulary in the fallback check, from
  `allow|deny|ask` to `allow|prompt|forbidden`. The shipped rules all use `allow`,
  so nothing was being rejected; the risk was a future tightening passing the
  fallback with a rule Codex refuses. Codex is not installed in this environment,
  so `codex execpolicy` did not re-check it. The three names come from the
  official rules documentation, fetched on 2026-09-08, and match what `review.md`
  recorded against Codex CLI 0.153.0.

- [x] Decide the approval posture the baseline advertises. It documents the one
  it has rather than narrowing to the one it claimed, recorded in `DECISIONS.md`
  as "The allowlist is a separate grant, and is documented as one". No rule
  changed. `README.md`, `SPEC.md`, and `docs/AGENT_LAYOUT.md` now separate the
  sandbox from the allowlist and state that a grant for a command that runs
  another command covers whatever it runs.

- [x] Reconcile the three documentation contradictions `review.md` named.
  `README.md` no longer describes CodeQL analysis as something that happens: the
  workflow is dispatch-only and its upload is refused until code scanning is
  enabled for this private repository. `SPEC.md` narrows its unresolved
  dependency-update question to Azure DevOps, since two accepted decisions settled
  GitHub. `docs/WORKFLOW.md` step 15 says to read the run a push starts and to
  dispatch only when there is nothing to push, which is what `AGENTS.md` already
  said.

- [x] Prove the three-platform behaviour in CI. Both installers changed, and this
  environment can no longer run the Bash integration test at all: WSL is absent
  from this machine as of 2026-09-08, where `AGENTS.md` recorded it as the way to
  run that suite in full. Git Bash reaches neither new Bash fixture, failing
  first on a symbolic link and then on trust-root normalisation, both
  pre-existing.

  Proved by push run `34257584839` on `640d14c`, which passed `ubuntu-latest`,
  `macos-latest`, and `windows-latest`. It was the only run for the commit, so
  nothing cancelled it. The Linux job is what closes the local gap: it reported
  `installer integration test passed` and `validation passed: 9 skills checked`,
  so both new Bash fixtures ran there, and it ran the ShellCheck this machine has
  no binary for. The Windows job ran `scripts/test-install.ps1` to
  `installer integration test passed` under PowerShell 7 and again under Windows
  PowerShell 5.1 as separate steps, on an elevated runner, which is what covers
  the two stale symbolic-link fixtures skipped locally.

- [x] Fix the bootstrap fixture in both installer tests, which failed every
  Dependabot pull request. Found by reading the one CI failure nothing tracked:
  run `33549247759` on pull request #1, opened 2026-09-01 and still open. Both
  fixtures read a branch name off the checkout with
  `git rev-parse --abbrev-ref HEAD`, and `actions/checkout` leaves a
  `pull_request` build on a detached HEAD, where that returns the literal string
  `HEAD`. The log reads `HEAD is now at fd27f85 Merge cd7cddf into 730217a` and
  then `fatal: Remote branch HEAD not found in upstream origin`. Each fixture now
  names its own branch and pushes the commit under test to it.

  This is why the dependency-update mechanism has produced nothing usable. The
  pins are a security control and Dependabot is the only thing that reports one
  going stale, which "Bots may open pull requests, humans may not" kept it for;
  a bump that can never go green is that report arriving unreadable.

  Reproduced on Windows rather than inferred, because this machine runs that
  suite in full: from a detached-HEAD clone, `scripts/test-install.ps1` failed
  with `git clone --quiet --branch HEAD ... failed with exit code 128`, and
  passes from the same detached clone after the fix. It still passes on a branch
  under PowerShell 7 and Windows PowerShell 5.1.

- [ ] Carried forward from the phase below, which is otherwise closed: confirm
  both agents read the installed instruction file after a restart. Claude Code
  listing `CLAUDE.md` under `/context` Memory files is what shows the
  absolute-path import resolved.

  It needs the baseline installed, and it is not installed here now.
  `~/.codex/rules/` is absent and `~/.codex/AGENTS.md` is empty on 2026-09-08,
  where the install of 2026-08-07 recorded below left 187 rules and a copy of
  `ai-home/AGENTS.md`. `~/.codex/config.toml` still holds the merged keys. What
  removed the other two was not established; rerun the installer before reading
  anything into the restart.

## Completed phase: State-preserving installation and reliable validation

Both items are done, and everything the phase asked for is verified except one
thing a restart has to show. The first item waited four days on an action outside
this environment, Windows Developer Mode or an elevated shell, because the blocker
was recorded as a property of this machine. It was a property of the installer: 20
of its 24 Windows links never needed the privilege, and the other four had answers
that are not symbolic links. The token that made CI runs unreadable is no longer a
factor, `gh` having been authenticated on 2026-08-02, and the code-scanning
repository setting belongs to the governance phase below.

- [x] Stop the Windows installer needing a privilege the machine may withhold.
  Recorded in `DECISIONS.md` as "Windows installs without a privilege, by method
  per target", which supersedes in part the entry requiring a symbolic link on
  every platform. The method follows the target: the 20 skill directories become
  junctions, `~/.claude/CLAUDE.md` becomes a generated `@` import of
  `ai-home/AGENTS.md`, and `~/.codex/AGENTS.md` and the two model profiles are
  copied and recorded in the install state file, so a rerun refreshes one only
  while it matches what the installer wrote and preserves anything the machine
  changed. `scripts/install.sh` is untouched, because symbolic links need no
  privilege on Linux or macOS.

  Three things were established by running them rather than recalled. A junction
  is created unprivileged and reports `LinkType` `Junction` with a resolved
  `Target` under both PowerShell editions, which is what the idempotency and
  pruning checks read. `mklink /J` creates one to a missing target, which is what
  lets the stale-link fixtures be built without a privilege. And hard links, the
  obvious way to keep a file tracking its source, are disqualified: after a `git
  checkout` of the source the source read `version one` while the link still read
  `version two`, so Codex would silently read stale instructions after a pull.
  Codex's `model_instructions_file` is the key that looks like the answer and is
  documented as a "Replacement for built-in instructions instead of `AGENTS.md`",
  so it would discard the built-in instructions rather than point at a shared
  file.

  Verification: the complete Windows installer integration test passes locally
  under both PowerShell 5.1 and PowerShell 7, which had never been possible,
  because it needed the privilege too and CI was the only place it ran. WSL
  `./scripts/validate.sh` passed on 2026-08-06, reporting `installer integration
  test passed` and `validation passed: 10 skills checked`, which is what proves
  the Bash installer is unaffected; this WSL installation has only `python3` and
  `git` of the tools it probes, so ShellCheck, `node --check`, `codex execpolicy`,
  and both PowerShell checks were skipped and run from Windows instead, where both
  editions parse both installers and PSScriptAnalyzer reports nothing under the
  validator's own invocation.

  Running the test found one defect, in the test rather than the installer: its
  provenance harness dot-sources the installer's functions and sets its script
  variables by name, and did not set the one this change adds.

  Defender was the detour, and it is recorded as a rule in `AGENTS.md` because
  nothing else catches it. Reading a file into a byte array and writing one back
  made AMSI block the entire installer as malicious under both editions, reported
  as a parser error on line 1, invisible to the parser, to PSScriptAnalyzer, and
  to CI. Bisection against the committed version settled it rather than guesswork:
  `HEAD` was clean, the byte-array version was blocked, and the same logic written
  with `Copy-Item`, `WriteAllText`, and `Get-FileHash` is clean. It also corrected
  a wrong reading made on the way, that the installer test was blocked by a
  pre-existing condition of this machine; the test invokes the installer, and it
  has run cleanly ever since the installer stopped being flagged.

  One path stays uncovered rather than implied: `Set-ManagedFile` replacing a
  pre-existing symbolic link, because fabricating one needs the privilege this
  change removes. The junction fixture exercises the same branch through
  `Test-LinkTargetsSource`, and CI's elevated stale-link fixtures cover the
  symbolic-link branch of pruning.

  Proved on three platforms on 2026-08-07. Push run `31193633136` on `aaa323a`
  passed `ubuntu-latest`, `macos-latest`, and `windows-latest`, and the Windows job
  ran the installer integration test under both PowerShell 7 and Windows PowerShell
  5.1 as separate steps, alongside PSScriptAnalyzer. It was the only run for the
  commit, so nothing cancelled it.

- [x] Restore automatic validation on pushes to `main`. It works: the runs list
  now holds `push` events for `be8b8ea` at 04:54Z and `397241b` at 12:43Z on
  2026-08-01, where every push from `90073f0` through `0507ce2` had produced
  none. The diagnosis stands as recorded, that automatic check-suite creation was
  off for the Actions app; the setting was applied outside this session.

  Both push runs were cancelled seconds after starting, because a
  `workflow_dispatch` for the same commit landed in the same concurrency group
  and `cancel-in-progress` kills the older run. Push and read, or dispatch and
  read, but not both for one commit.
- [x] Define one ownership and provenance model for `config.toml`, Codex rules,
  and derived Claude permissions before changing installer code. Recorded in
  `DECISIONS.md` as "Shared files are merged against a recorded provenance
  manifest", superseding the 2026-06-21 link decision in part. Shared files are
  merged, never linked or replaced; a per-machine state file records what the
  installer wrote; an entry is written or withdrawn only when it is absent or
  byte-identical to that record, and anything else is preserved and reported.
  Shape carries no provenance in either format: the live `settings.json` holds 34
  agent-written entries in the derived `Tool(command *)` shape, and Codex's own
  first recorded rule is a single-token prefix like the curated ones.
- [x] Merge portable Codex defaults into `config.toml` instead of replacing the
  file, and generate exact trust entries from configurable or discovered roots
  that include where repositories actually live. Both installers merge key by
  key against the state file; `AI_TRUST_ROOTS` sets the searched roots. A trust
  table Codex wrote itself is matched whatever its quoting or case, so no
  duplicate is added. Verified on copies of this machine's real `~/.codex` and
  `~/.claude`: the merge adds only the baseline keys and seven trust entries,
  leaves marketplaces, plugins, `mcp_servers`, `[desktop]`, and the existing
  trust entries untouched, and reports `already current` on a rerun. Both
  installer tests seed that state and assert it survives.
- [x] Reconcile `ai-home/rules/default.rules` and Claude's derived
  `permissions.allow` entries using the recorded ownership model. `~/.codex/rules`
  is no longer a link, so approvals stay on the machine; an existing link is
  removed and reported. Removing a curated rule withdraws the Codex rule and both
  derived grants when the state file records the installer added them unchanged,
  and preserves and reports a grant that predates the install. Both installer
  tests cover withdrawal, preservation, a machine-changed managed key, and the
  handback when the machine reverts it. The Python and PowerShell merges were
  checked against identical real inputs and produce byte-identical `config.toml`
  and rule files, equal JSON, and equal state records.
- [x] Decide whether the portable Codex default intentionally uses the
  unrestricted `approval_policy = "never"` plus
  `sandbox_mode = "danger-full-access"` preset or changes to an
  approval-capable sandbox. It changes: `ai-home/codex/config.toml` now sets
  `sandbox_mode = "workspace-write"` and `approval_policy = "on-request"`,
  recorded in `DECISIONS.md` as "The portable Codex default asks before acting".
  `SPEC.md` and `README.md` state it, both installer tests assert it and reject
  `danger-full-access`, and `ai-home/AGENTS.md` needed no change because nothing
  in it claimed a posture.
- [x] State the minimum supported PowerShell edition and make implementation and
  CI match it. Windows PowerShell 5.1 is the floor, recorded in `DECISIONS.md`.
  `install.ps1` and `test-install.ps1` no longer use
  `ConvertFrom-Json -AsHashtable -Depth`, and the merge normalises the Unicode
  escapes 5.1 emits for `<`, `>`, `&`, and `'`, which 278 and 193 of this
  machine's 832 approved entries contain. Run `30674779854` on `main` at
  `e594128` passes the complete installer test under both editions, each step
  asserting the edition it runs on. Two 5.1-only defects were found and fixed on
  the way: `Test-JsonProperty` read `.Name` off an empty property collection,
  which PowerShell 7 strict mode rejects, and the stale-link fixture used
  `New-Item -ItemType SymbolicLink`, which 5.1 refuses when the target is
  missing.
- [x] Close executable validation gaps while changing the installers.
  `scripts/validate.sh` now rejects any `default.rules` line that is not one
  `prefix_rule` with a non-empty quoted pattern list and a known decision, which
  needs no Codex binary; the `codex execpolicy` check stays as the stronger one
  where Codex exists. It compiles `scripts/merge-agent-state.py` and runs
  `node --check` over the skills' `.mjs` and `.js` files where Node is present.
  Managed removal and populated Codex state are exercised by both installer
  tests. Checked that the new rule check flags a malformed line and that
  `show-reset-expiries.mjs` passes `node --check`.
- [x] Update `README.md`, `docs/AGENT_LAYOUT.md`, `SPEC.md`, tests, and
  `CHANGELOG.md` with the implemented behavior, then run the complete local gate
  and a manually dispatched three-platform workflow before relying on the fixed
  push trigger. The local WSL gate passes, and dispatched run `30674779854` on
  `e594128` passes `ubuntu-latest`, `macos-latest`, and `windows-latest`,
  including ShellCheck on Linux. It took three dispatches: the first found a
  PowerShell 7 strict-mode defect and a macOS path-normalisation defect in the
  test, the second found the 5.1 fixture defect.
- [x] Install on this machine only after the state-preserving behavior passes.
  This is a first install, and symbolic links still require enabling Developer
  Mode or using an elevated shell. Acceptance: dry-run reports the intended
  changes, the real install preserves the pre-existing Codex and Claude state,
  the trust roots cover where this machine's repositories actually live, and both
  agents report the expected instructions and skills after restart.

  The dry-run half is done, on 2026-08-02, against this machine's real `~/.codex`
  and `~/.claude` rather than a copy. It touched nothing: a SHA-256 inventory of
  both homes taken before and after is identical, excluding only the runtime
  databases the agents were writing while it ran. What it reports it would do is
  back up the empty `~/.codex/AGENTS.md` and link it to `ai-home/AGENTS.md`, link
  the two model profiles and `~/.claude/CLAUDE.md`, set ten `config.toml` keys,
  add 139 curated rules to `~/.codex/rules/default.rules`, add 278 derived
  permissions to `~/.claude/settings.json`, and create `~/.agents/skills` and link
  all ten skills into it and into `~/.claude/skills`.

  It found the one thing a dry run is for. The default trust root is wrong for
  this machine: `~/github` does not exist, and nine Git worktrees live under
  `~/Development`. So the real install has to set `AI_TRUST_ROOTS`, and that is
  now part of the acceptance above rather than something to notice afterwards.
  Re-run with `AI_TRUST_ROOTS` set to `~/Development`, it generates the root plus
  six worktrees, and the three it leaves out -- `ai`, `fabled-lands`, and
  `wealthfolio` -- are exactly the three Codex has already trusted itself,
  recorded lower-case in literal-string form. That is the duplicate matching the
  provenance decision describes, confirmed against real machine state rather than
  against a copy of it for the first time.

  Still blocked on the same thing. `AllowDevelopmentWithoutDevLicense` is absent
  from `HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock`, checked
  on 2026-08-02, so Developer Mode is off and every `New-Item -ItemType
  SymbolicLink` the dry run listed would fail.

  That last clause was an inference from the registry, and it is now an
  observation. `New-Item -ItemType SymbolicLink` was attempted in a scratch
  directory on 2026-08-02 and failed with `Administrator privilege required for
  this operation.`, in a shell that reports itself outside the `Administrator`
  role. So the blocker is the link operation itself refusing, not a setting read
  as a proxy for it.

  Re-run on 2026-08-06 rather than carried forward, and the blocker holds: the
  same attempt fails with the same message, in a shell still outside the
  `Administrator` role. One detail above is wrong and is corrected here rather
  than edited away. The `AppModelUnlock` key exists; it is the
  `AllowDevelopmentWithoutDevLicense` value inside it that is absent. That
  changes nothing, since the attempted link is the better evidence either way.

  WSL is not a way around it, tested on 2026-08-06 because it is the obvious
  thing to reach for next and it would have failed silently. `ln -s` under
  `/mnt/c` succeeds and `ls -l` shows an ordinary symbolic link, so from Linux
  an install would look like it had worked. Windows cannot follow what it
  creates: the entry carries reparse tag `0xa000001d`,
  `IO_REPARSE_TAG_LX_SYMLINK`, which `Get-Item` reports with an empty `LinkType`
  and `Target` and which `Get-Content` refuses with `The file cannot be accessed
  by the system.` Installing that way would point both Windows-side agents at
  instruction and skill paths they cannot read, and nothing would report a
  failure. So the install waits on Developer Mode or an elevated shell, and on
  nothing else.

  It waits on neither, as of later the same day. The privilege was removed from
  the installer rather than acquired for the machine, by the task above, so this
  item is ordinary work: the acceptance is unchanged and `AI_TRUST_ROOTS` must
  still be set to `~/Development`, because the default `~/github` does not exist
  here.

  Installed on 2026-08-07, with `AI_TRUST_ROOTS` set to `~/Development`. The
  machine's state survived, measured against an inventory taken immediately
  before rather than asserted afterwards. Claude Code's `settings.json` went from
  1,176 approved permissions to 1,454, and none of the original 1,176 is missing;
  `model` and all nine `additionalDirectories` are unchanged. `config.toml` went
  from 20 section headers to 28, keeping its marketplaces, MCP servers, and the
  trust entry Codex wrote for itself. `~/.codex/rules/default.rules` went from 48
  lines to 187, which is the machine's own 48 plus the 139 curated rules. Every
  replaced file was backed up under `~/.codex/backups/ai-20260807-110458-42988/`,
  including the empty `AGENTS.md` that was there before.

  What it produced is what the per-target decision says it should. Three copies
  byte-identical to their sources, `~/.claude/CLAUDE.md` holding the generated
  import of a path that exists, ten junctions in `~/.agents/skills/` and ten in
  `~/.claude/skills/`, all readable through, and a state file recording the four
  written files beside the three merged ones. The trust entries are the root plus
  five worktrees; `ai`, `fabled-lands`, and `wealthfolio` are absent because Codex
  had already trusted them itself, which is the duplicate matching the provenance
  decision describes.

  A rerun is a no-op: 27 `already current` or `already linked` lines, no write, no
  merge, no backup, and the permission count unchanged at 1,454.

  The skills half of the acceptance needs no restart and is met by observation
  rather than by inference. Claude Code's available-skills list held none of this
  repository's skills at the start of the session that ran the install, and after
  it held exactly ten, matching `.agents/skills/` name for name. So Claude Code
  discovers a skill through a junction, which is the one thing about the new method
  that its own documentation does not state anywhere.

  What is left needs a restart this session cannot perform: both agents reading the
  instruction file. Claude Code loads `CLAUDE.md` at session start, so `/context`
  listing it under Memory files is what confirms the absolute-path import resolved,
  and that form is documented but has not been seen to work here. Codex reads a
  plain copy, so it has nothing new to prove beyond being read at all.

## Completed phase: A tree of its own

Every restatement is done, committed, and proved on three platforms. The last
item waited on nothing but readable CI: `gh` was authenticated on 2026-08-02, and
the push runs it then exposed had already validated the restated code.


This repository began as a copy of the unlicensed public `ChrisTitusTech/titus-ai`
and is not a GitHub fork. `git blame` on 2026-08-01 attributes 1,926 of 8,704
tracked lines to the upstream commits, across 31 files. `DECISIONS.md` records
why the content is replaced rather than the history rewritten, and which lines
are deliberately left alone.

- [x] Restate the two instruction files, which carried the most inherited prose
  and are the most read: `AGENTS.md` scope, operating principles, and RTK
  guidance, and `ai-home/AGENTS.md` command execution, working style, and scope
  selection. Every rule survives; the destructive-operations rule now names what
  counts as destructive.
- [x] Restate the three inherited skills: `bash-scripting` (59 lines),
  `pr-readiness` (57), and `ai-project-manager` (52) plus its project-document
  templates (134 across five files: `SPEC.md` 47, `AGENTS.md` 38, `ROADMAP.md`
  33, `TASKS.md` 16). Every rule survives, and each skill gained the `## Scope`
  section `docs/SKILLS.md` asks for, naming the sibling skill at its boundary.
  Two `pr-readiness` defects are deliberately left for the tasks that own them:
  the independent-review gate that `DECISIONS.md` contradicts, and
  `ai-project-manager`'s discovery glob, which still omits the `PLAN.md` it
  writes and the `CHANGELOG.md` it updates. `agents/openai.yaml` (4 lines) is
  left for the re-measure task below. Validation: WSL `./scripts/validate.sh`.
- [x] Delete `ai-home/default.rules`, a byte-identical stray copy of
  `ai-home/rules/default.rules` added by `397241b`, a commit about instruction
  prose that touched no other rule file. Nothing read it: every script, test,
  and document names the `rules/` path, which holds the file's continuous
  history back to the original `rules/default.rules`.
- [x] Restate the inherited planning prose in `SPEC.md` (65), `ROADMAP.md` (51),
  `docs/SKILLS.md` (50), and `docs/WORKFLOW.md` (44). Down from 210 attributed
  lines to 121, and what survives is structure rather than prose: section
  headings, table delimiters, code fences, the skill-layout tree, the skill
  names themselves, and continuation lines whose tail did not need to change.
  Section headings are deliberately kept, because `SPEC.md` shares them with the
  template in `ai-project-manager` and renaming one to shed attribution would
  desynchronize the pair for nothing. Validation: WSL `./scripts/validate.sh`.
- [x] Restate what is left in `README.md`. Most of its 159 attributed lines are
  commands and code fences that have one spelling; only the prose counts. Down
  to 113, and every line still attributed is a command invocation, a fence, a
  one-word label introducing a code block, or a file list. Validation: WSL
  `./scripts/validate.sh`.
- [x] Re-measure and record the remainder, naming what stays attributed and why.
  Functional lines are expected to remain: command invocations, configuration
  keys, `.gitignore` patterns, and rule entries that are only command names.
  Measured on 2026-08-01 after the restatement passes: 1,552 of 8,991 lines
  across 31 files, from 1,926 of 8,704. It divides into four groups.

  - Executable code, 750 lines: `scripts/install.ps1` 239, `install.sh` 150,
    `test-install.ps1` 132, `test-install.sh` 124, `validate.sh` 105. Shebangs,
    `set -euo pipefail`, argument parsing, variable assignment, and control
    flow. This is the one group the phase did not schedule; the task below owns
    the decision.
  - Rule entries and configuration, 341 lines: `ai-home/rules/default.rules`
    165, `.gitignore` 76, `.github/workflows/validate.yml` 49, the two
    `ai-home/codex/*.config.toml` profiles 29, `.rtk/filters.toml` 13,
    `.github/dependabot.yml` 8, `codex-plugins.txt` 1. Every one is a rule
    entry naming a command, a pattern, or a configuration key, which is the
    remainder `DECISIONS.md` expects to keep.
  - Structure and commands in the restated documents, 291 lines: `README.md`
    113, `ROADMAP.md` 36, `docs/SKILLS.md` 35, `SPEC.md` 29, `AGENTS.md` 27,
    `TASKS.md` 21, `docs/WORKFLOW.md` 21, `ai-home/AGENTS.md` 9. Headings, table
    delimiters, code fences, and command invocations with one spelling.
  - Skill and template structure, 170 lines: front-matter delimiters, the `name:`
    line the validator requires to equal the directory, headings, the
    skill-layout tree, and the title-cased `display_name` shared by all eight
    skills.

  The prose goal is met: outside the scripts, no group holds a sentence that was
  not rewritten. Section headings are kept on purpose, because `SPEC.md` shares
  them with the `ai-project-manager` template and renaming one to shed
  attribution would desynchronize the pair for nothing.

- [x] Decide whether the 750 attributed lines of installer, test, and validator
  code are restated or left as they are. Recorded in `DECISIONS.md` as "Restate
  the installer's linking core, leave the rest of the script code": four
  functions are restated and the remaining 626 lines stay. The 750 are not 750
  lines of authored logic. 299 are a blank line, a lone `}`, `fi`, `done`, or
  `else`, a shebang, or a comment, and much of the rest is declaration
  boilerplate with one spelling. What is left is concentrated in six functions,
  measured with `git blame`: `resolve_path` 39 of 39 lines and
  `link_managed_path` 42 of 45 in `scripts/install.sh`, and
  `Get-NormalizedPath` 11 of 11, `Test-LinkTargetsSource` 20 of 20,
  `Get-BackupPath` 23 of 31, and `Write-DryRunCommand` 10 of 10 in
  `scripts/install.ps1`. Two of the six wrap a parameter block around a single
  expression and are excluded. Message strings are excluded from the whole
  restatement because both installer tests match the installer's exact output,
  so a reworded message is a four-file edit with no new evidence behind it.

- [x] Restate the four selected functions, bodies only. `resolve_path` and
  `link_managed_path` in `scripts/install.sh` first, because WSL
  `./scripts/validate.sh` runs `bash -n`, ShellCheck, and the whole Bash
  installer integration test locally, so a defect surfaces in the pass that
  caused it. Then `Test-LinkTargetsSource` and `Get-BackupPath` in
  `scripts/install.ps1`, whose integration test runs only in CI: local
  validation covers those two with the PowerShell parser and PSScriptAnalyzer
  only, because `scripts/test-install.ps1` needs symbolic-link permission this
  environment lacks. Sequenced after the pending first install above, so that
  install runs the code the three-platform runs already proved. Acceptance: the
  diff touches function bodies and nothing else, with every function name,
  parameter name, and printed string unchanged; WSL `./scripts/validate.sh`
  passes after each pass; and a three-platform run passes with the Windows job
  green under both PowerShell editions.

  Restated on 2026-08-01, ahead of the install rather than after it, because
  that install is blocked on a permission this machine still does not grant and
  the restatement gets its own three-platform proof either way. The diff is four
  function bodies and nothing else. Local evidence: WSL `./scripts/validate.sh`
  passes, and the Bash installer integration test inside it is what exercises
  `resolve_path` and `link_managed_path`. The two PowerShell functions have no
  local integration test, so they were checked differentially instead: both
  editions parse the file, PSScriptAnalyzer reports nothing, and a harness that
  loads the functions out of `HEAD` and out of the working tree returns
  identical output under 5.1 and 7 for ten `Get-BackupPath` cases and every
  reachable `Test-LinkTargetsSource` case. Its rooted-target branch needs a real
  symbolic link, so `Assert-Link` in CI remains the only thing that covers it.
  One behavior changed, on a path no call site reaches: `link_managed_path` now
  evaluates `backup_path_for` once and lets `set -e` propagate its `exit 1`,
  where three separate command substitutions used to discard that status. Every
  target passed to it is built from one of the three managed homes.

  Proved on three platforms on 2026-08-02, when `gh` was authenticated and the
  runs became readable. The restatement is `e02540b`; push run `30720357277` on
  `048309a`, the first commit pushed after it, passed `ubuntu-latest`,
  `macos-latest`, and `windows-latest`, and the Windows job ran the installer
  integration test under both PowerShell editions, each step asserting the
  edition it was on. The current tip `e98a58b` carries the same four functions and
  its push run `30732673451` passes the same three platforms, so the evidence is
  not a one-off.

## Completed phase: Host-neutral version control

The baseline must serve a repository hosted on Azure DevOps, hosted service or
on-premise server, as well as one on GitHub. Neither Azure DevOps variant is in
use, so this phase separates the host-neutral core from the host-specific edge
and ships the Azure DevOps side labelled unverified. `DECISIONS.md` records the
choice as "Both hosts are supported, only GitHub is verified"; the approach and
the seven couplings it addressed were in the `PLAN.md` since replaced.

Everything is done, committed, validated locally, and proved on three platforms.
The run was already there when `gh` was authenticated on 2026-08-02; nothing
needed pushing.

- [x] Record the requirement and the closed choice: `DECISIONS.md`, `SPEC.md`
  required behavior, compatibility, non-goals, acceptance criteria and two
  unresolved questions, `ROADMAP.md` Phase 8, and `PLAN.md`. Phase 6 gained the
  dependency it has on this one, and Phase 7 an exit criterion, because both are
  written in GitHub features. Promoted out of the replaced `PLAN.md` on the way:
  neither installer has a TOML writer available, which is why the `config.toml`
  merge is textual on both sides, now in `SPEC.md`.
- [x] Read the Azure DevOps facts the documents would otherwise state from
  recall, from Microsoft's own references rather than a live instance. Advanced
  Security is for Azure DevOps Services, and Microsoft states it has no current
  plans to bring it or its standalone products to Azure DevOps Server.
  Microsoft-hosted agents exist only in Services, so Server runs self-hosted
  agents only. A YAML `pr` trigger applies to GitHub and Bitbucket Cloud alone;
  on Azure Repos, pull-request validation is a build validation branch policy.
  The pull-request command surface is `az repos pr show|list|policy
  list|reviewer list`, with no `checks` command and no threads subcommand; the
  threads REST resource is
  `.../pullRequests/{id}/threads`, whose `status` is `active` or `pending` while
  unresolved and `fixed`, `wontFix`, `closed`, or `byDesign` once resolved. This
  replaced the planned local Azure CLI install, which would have needed a
  machine change to read the same generated reference.
- [x] Restate the `docs/WORKFLOW.md` security baseline as the capability each
  rule needs, with a seven-row table naming the mechanism on GitHub, Azure
  DevOps Services, and Azure DevOps Server, and `None` where a host offers
  nothing. It closes by saying no row has been verified against a live instance.
- [x] Stop `scripts/validate.sh` requiring the `.github/` layout by name as the
  definition of a valid repository. The CI definitions are now a separate
  `required_host_files` list with its own message, so adding a host means adding
  a definition rather than renaming one. Checked both ways: WSL
  `./scripts/validate.sh` passes, and moving `azure-pipelines.yml` aside makes
  it report `missing host CI definition azure-pipelines.yml`.
- [x] Add `azure-pipelines.yml` running the same three-platform gate as
  `.github/workflows/validate.yml`. Each pool is a parameter, because Azure
  DevOps Server has no Microsoft-hosted pool. It sets `pr: none` rather than a
  pull-request trigger that Azure Repos ignores, and its header states that it
  is unverified, what would verify it, and what a self-hosted agent needs.
  Verified only as far as is possible without an instance: PyYAML parses it and
  the parsed jobs, parameters, and Windows steps are the intended ones.
- [x] Document the Azure DevOps clone URL forms for `AI_REPO_URL` in
  `README.md`, both the hosted `dev.azure.com` form and the on-premise form
  carrying a collection, plus the internal certificate authority that makes the
  bootstrap clone fail with a certificate error naming nothing. Renamed the
  `Trust GitHub projects` section, which describes discovery that keys on a
  `.git` directory and has never cared about the host.
- [x] Make `.agents/skills/pr-readiness/SKILL.md` state its pull-request
  semantics host-neutrally and name the commands per host. Every existing rule
  survives; the `gh`-only diagnostics block became a worktree half that is the
  same everywhere and a four-row table. The skill records that the Azure DevOps
  commands are transcribed from Microsoft's reference and have not been run, so
  an unexpected result is a defect in the table before it is a finding.
- [x] Check that `AGENTS.md`'s version-control section labels its GitHub
  specifics as such. Split into the host-neutral rule, which is to ask to push
  and never open a pull request, and a second bullet naming GitHub Actions as
  where evidence comes from, since that is where this repository is hosted. It
  also states that `azure-pipelines.yml` has never run and is not evidence.
- [x] Decide against adding a blanket `az` rule to `ai-home/rules/default.rules`
  for now, and record why, because the investigation changed the answer. The
  scoped rule the job wants, `["az", "repos"]`, passes validation and is valid
  Codex syntax but derives no Claude Code grant: both derivations match a
  single-token pattern only, so it would reach one agent and silently leave the
  other prompting. The unscoped `["az"]` that does derive grants the whole Azure
  control plane, `az vm` and `az storage` included, to save approval prompts for
  a service that is not yet in use. Promoted the derivation limit to `SPEC.md`,
  since it is a silent gap rather than a visible one. Revisit when Azure DevOps
  is actually in use, or when multi-token derivation exists; the cost meanwhile
  is one approval prompt per `az` command.
- [x] Run WSL `./scripts/validate.sh` and report which checks it performed, then
  ask to push and read a three-platform run. Acceptance: the run passes
  `ubuntu-latest`, `macos-latest`, and `windows-latest`, with the Windows job
  green under both PowerShell editions.

  The local run passed on 2026-08-01 at `3749b3e`, reporting `installer
  integration test passed` and `validation passed: 8 skills checked`. Of the
  optional tools it probes, this WSL installation has only `python3` and `git`,
  so the run performed the required-file and host-CI-file checks, both plugin
  manifests, the `CLAUDE.md` import and size checks, the `default.rules` syntax
  and derived-rule checks, the skill tree against `docs/SKILLS.md`, the tracked
  runtime-file, executable-bit, and carriage-return checks, the Python compile
  and the three TOML parses, `bash -n` over the four Bash scripts, and the whole
  Bash installer integration test. It skipped ShellCheck, `node --check`, `codex
  execpolicy`, the PowerShell parser check, and PSScriptAnalyzer. The two
  PowerShell checks were run from Windows instead, as `AGENTS.md` requires: both
  installers parse under 5.1 and 7, and PSScriptAnalyzer reports nothing.

  The three-platform run needed no push. `3749b3e` was already on `origin/main`
  and its push had already produced run `30724005165`, which passed
  `ubuntu-latest`, `macos-latest`, and `windows-latest` with the Windows job
  running the installer test under both PowerShell editions. It was unreadable
  until `gh` was authenticated on 2026-08-02, which is the only thing that was
  ever blocking this item.

## Completed phase: Re-appliable repository baseline

The marker, the two skills that write it, the update skill that reads it, and the
development infrastructure all three propagate are in place, and the loop has been
run end to end on a scratch repository. That run is what closed the phase: it found
four defects in the instructions, including one that made the phase's own
convergence criterion unreachable. `PLAN.md` carries the proof and its findings.

The third exit criterion, that adoption and update are covered by the same
validation the installer has, is met as `scripts/validate.sh` covers every skill's
front matter, name, placeholder markers, and the documented inventory, and CI runs
that script on three platforms. Nothing automated can run the skills themselves:
they are instructions an agent follows, which is why the scratch proof exists.

- [x] Reconcile the reusable workflows before building update mode.
  `adopt-baseline` now inventories `DECISIONS.md` and `CHANGELOG.md`, notes
  whether `.claude/skills` is a directory or a link, pairs `DECISIONS.md` with
  `PLAN.md` in its selection table because promotion out of the plan is the only
  thing that survives the plan, and gives `CHANGELOG.md` its own condition
  outside that table. It also covers the case the wiring alignment exposed: a
  repository whose `.claude/skills` is already a real directory moves those
  skills to `.agents/skills/` before the directory is replaced. The first
  `DECISIONS.md` entries are not empty, because adoption itself closes which
  documents were declined and which skills were kept, promoted, or retired.
  `ai-project-manager` now discovers the `PLAN.md` it replaces and the
  `CHANGELOG.md` it updates, in both its workflow step and its `rg` glob, which
  omitted the two files the skill writes.
- [x] Align `docs/SKILLS.md` with `adopt-baseline` on one dual-agent wiring
  method. One source under `.agents/skills/` plus the ignored `.claude/skills`
  link wins, recorded in `DECISIONS.md` as "One skill source per repository,
  exposed by an ignored link". Two copies drift silently, and they would give the
  planned update mode two inputs to compare against one recorded pool commit with
  no rule for a disagreement. The accepted cost is per-clone setup, now stated in
  the skill: a fresh clone has no Claude Code skills until the link is recreated.
- [x] Resolve the installed-skill policy exception for
  `show-codex-reset-expiries`. Recorded in `DECISIONS.md` as "A skill about the
  agent's own operation is installed, not pooled", and stated as a clause of the
  bar in `docs/SKILLS.md` rather than a note on the skill. The product test is
  about the repository a skill is drawn into; this one reports the signed-in
  account's Codex reset-credit expiries and has no repository dependency, so
  pooling it would leave a user-wide answer available only where someone copied
  it. The installed set stays at eight.
- [x] Validate the reconciliation locally. WSL `./scripts/validate.sh` passed on
  2026-08-01, reporting `installer integration test passed` and `validation
  passed: 8 skills checked`, which is what covers each skill's front matter, every
  `name` matching its directory, the absence of a `[TODO:` marker, and the
  `docs/SKILLS.md` inventory still matching the skill directories. Of the optional
  tools this WSL installation has only `python3` and `git`, so the run skipped
  ShellCheck, `node --check`, `codex execpolicy`, and both PowerShell checks, none
  of which reads a file this change touched. Both skills were then read end to end,
  because no check catches a rule dropped during an edit. No three-platform run
  was asked for: the change touches no script, no workflow, and no installed path.
- [x] Record in an adopting repository which baseline commit it took, which
  documents it adopted, which pieces it declined, and the pool commit behind any
  skill copied from `rwgs/ai-skills`. It is a committed `.agents/baseline.json`,
  written by a new `adopt-baseline` step and recorded in `DECISIONS.md` as "An
  adopting repository records what it took in `.agents/baseline.json`". It carries
  a `version`, the baseline clone URL rather than an `owner/repo` shorthand
  because nothing host-neutral asserts a host, the full 40-character commit and
  the date it was taken, the artifacts adopted, the artifacts declined with a
  reason for each, and each pooled skill's source URL and commit. Only baseline
  and pool content is recorded: a skill authored in the repository has no upstream
  to compare against, and step 4's keep-or-promote decisions stay in that
  repository's `DECISIONS.md`.

  Three things fell out of the design. The decline reasons are the load-bearing
  field, because a declined document and one the baseline added after adoption are
  the same absent file, and without a reason update mode offers the refusal back
  on every run. Both commits are read only from a clone with an empty `git status
  --porcelain`, since content copied out of a dirty tree is not the commit
  recorded, which is the drift `ROADMAP.md` warns is worse than no marker at all.
  Step 1 now stops when a marker exists, which nothing prevented before although
  the skill's scope has always said one repository, once.

  The workflow list was aligned with the body sections while adding the step: it
  omitted the project-scoped configuration section and carried a verify step with
  no section, so a new numbered step could not be placed correctly without it.

  Validation: WSL `./scripts/validate.sh` passed on 2026-08-01, reporting
  `installer integration test passed` and `validation passed: 8 skills checked`.
  Of the tools it probes, this WSL installation has only `python3` and `git`, so
  it skipped ShellCheck, `node --check`, `codex execpolicy`, and both PowerShell
  checks, none of which reads a file this change touches. The marker example was
  parsed out of the skill with `json.loads` and checked for a 40-character commit
  in both places and a non-empty reason on every decline, because a malformed
  example is the one defect no check here would catch and every adopting
  repository would copy. `adopt-baseline` was then read end to end and every
  existing rule survives.
- [x] Add an update mode to `adopt-baseline`, or a sibling skill, that adds
  missing documents and sections and reports drift without overwriting an
  adopted document. It reads both recorded commits, so a copied pool skill is
  reported alongside a stale document.

  It is a sibling skill, `update-baseline`, chosen by the user when both shapes
  were put side by side, and recorded in `DECISIONS.md` as "Updating is a sibling
  skill, and only a verbatim copy is refreshed". Presence of the marker separates
  the two, and each names the other at its boundary. The offerable set of artifacts
  stays in `adopt-baseline` alone, so this phase's propagation task extends one list
  rather than two. The installed set is nine, so the installer needs rerunning, which
  is the first change in this phase to require it.

  Three rules carry the additive semantics. A missing document or template section
  is added, and a section that cannot be written for the repository is reported
  instead of leaving an empty heading. No line an adopted document already carries
  is rewritten, and convention drift is reported with the rule it breaks. A pooled
  skill is refreshed only while its copy is byte-identical to the pool at the
  recorded commit, which is the provenance rule this repository already uses for
  shared files, applied where it fits: a pooled skill is copied verbatim, where an
  adopted document is adapted as it lands and so is never byte-identical.

  `baseline.commit` advances only when nothing the run surfaced is outstanding,
  because it is the point the next run diffs from, so advancing it past unapplied
  drift would hide that drift for good. A deviation the repository means to keep is
  recorded in its own `DECISIONS.md`, which the skill reads before calling anything
  drift; that is what makes the loop converge without a second vocabulary inside the
  marker.

  Validation: WSL `./scripts/validate.sh` passed on 2026-08-01, reporting
  `installer integration test passed` and `validation passed: 9 skills checked`,
  which is what covers the new skill's front matter, its `name` matching its
  directory, the absence of a `[TODO:` marker, and the `docs/SKILLS.md` inventory
  matching the directories. This WSL installation has only `python3` and `git` of
  the tools it probes, so ShellCheck, `node --check`, `codex execpolicy`, and both
  PowerShell checks were skipped, and none reads a file this change touches.

  Every command the skill tells an agent to run was run against the real pool
  before it shipped, which caught two defects in what would otherwise have been
  recalled commands. `git fetch` alone leaves `HEAD` at the old tip, so a clone
  fetched but not fast-forwarded reports a document as added upstream while that
  document is absent from the working tree the next two steps read templates out
  of; the skill fast-forwards instead, verified on a throwaway clone pinned one
  commit back. And `git archive | tar -xO` concatenates file contents to stdout
  rather than producing anything comparable, so the byte-identical test extracts to
  a temporary directory and uses `diff -r`, verified returning clean on an
  unmodified `skills/hugo` at `3e6d387`.

  Remaining for the phase: this is unverified against a real repository, which is
  what the scratch-repository proof below is for.
- [x] Extend adoption to install `.gitattributes` and offer the validation
  workflow and the Dependabot configuration. There is no pull-request template
  to propagate any more, and an adopting repository that accepts no bot pull
  requests should be offered neither Dependabot nor the `pull_request` trigger.
  Both artifacts are host-specific, so adoption offers the one matching the
  adopting repository's host and says so when the host has no equivalent. This
  is why the phase depends on the host-neutral phase above.

  It is one new `adopt-baseline` step, placed between the project-scoped
  configuration step and the marker so that what it propagates is recorded like
  everything else, and recorded in `DECISIONS.md` as "Adoption installs line
  endings and derives the host's CI definition". The three artifacts turned out to
  be three decisions rather than one. `.gitattributes` is installed
  unconditionally, because a Bash script checked out with CRLF fails outright and
  this repository hit that in its own checkout. The CI definition is derived rather
  than copied, because this repository's workflow runs `shellcheck scripts/*.sh`,
  `./scripts/validate.sh`, and the PowerShell installer test under both editions,
  so a verbatim copy fails on its first run anywhere else: the shape travels and
  the steps are written from the checks the adopting repository has. No workflow is
  added to a repository with no check to run, because a green run that runs nothing
  reports success it did not earn.

  The host is read from the remote and asked for whenever the hostname names no
  product, which an on-premise Azure DevOps Server always is and a repository with
  no remote also is. One question, whether the repository accepts a pull request
  from a bot, decides both Dependabot and the `pull_request` trigger, and a no
  carries an accepted exception for the pins it leaves to be refreshed by hand.
  `update-baseline` needed no list of its own: it reads the offerable set from
  `adopt-baseline`, so it gained the pointer to the new section and one rule, that
  a host-specific artifact is added only for the host the repository is on now.

  Verification: WSL `./scripts/validate.sh` passed on 2026-08-02, reporting
  `installer integration test passed` and `validation passed: 9 skills checked`,
  which is what covers both skills' front matter, each `name` matching its
  directory, the absence of a `[TODO:` marker, and the `docs/SKILLS.md` inventory
  still matching the directories. Of the tools it probes, this WSL installation has
  only `python3` and `git`, so it skipped ShellCheck, `node --check`, `codex
  execpolicy`, and both PowerShell checks, none of which reads a file this change
  touches. Every path the new step names was checked to exist here:
  `.gitattributes`, `.github/workflows/validate.yml`, `.github/dependabot.yml`,
  `azure-pipelines.yml`, and `docs/WORKFLOW.md`. The marker example was re-parsed
  with `json.loads` and still holds a 40-character commit in both places and a
  non-empty reason on every decline.

  The line-ending commands were run in a scratch repository before they were
  written, which is what separated them into three operations. Committing
  `.gitattributes` changes nothing already committed, `git status` printing nothing
  even where the index holds CRLF; `git add --renormalize .` stages the conversion
  and touches every affected file, so it needs a commit of its own; the working
  tree still reports `w/crlf` from `git ls-files --eol` after that commit until
  `git rm --cached -r .` and `git reset --hard` check the paths out again; and a
  rerun of `git add --renormalize .` staging nothing is what proves the tree
  converged. No three-platform run was asked for: the change touches no script, no
  workflow, and no installed path.
- [x] Give a new repository its own entry point instead of a skill named for
  adopting an existing one. It is `start-repository`, a tenth installed skill,
  recorded in `DECISIONS.md` as "A new repository is started, and its refusals
  carry a reopening condition". The shape needed no deciding: the sibling-skill
  entry had already settled that this is a third workflow with a third
  precondition, an empty repository, rather than a mode of either existing one.
  Three preconditions now partition cleanly, and each skill names the other two
  where a reader could land in the wrong one: the marker separates a first pass
  from every later one, and whether the repository holds work separates the two
  first passes. The offerable set of artifacts is still in `adopt-baseline` alone,
  so this skill points at it for the selection table, the skill wiring, the host
  reading, the CI derivation, and the marker's fields.

  Three rules are its own, and each came out of the design rather than into it.
  The line-ending and ignore rules are the first commit, ahead of the instruction
  files, which is the one thing a new repository gets cheaply that an adopting one
  cannot: the renormalising commit and the working-tree refresh never happen at
  all. What can be written at creation divides into intent and history, so
  `SPEC.md`, `ROADMAP.md`, and `TASKS.md` are written and `PLAN.md` and
  `CHANGELOG.md` are not, with `DECISIONS.md` the exception among the history
  documents because the stack, host, and shape are being chosen right then and are
  unrecoverable from the code later. And almost everything a new repository leaves
  out is "not yet" rather than "no", so each is recorded in the marker's existing
  `declined` field with the condition that reopens it. That last one closes a real
  hole: `update-baseline` reports a decline once per run and never adds it, so a CI
  definition declined on day one for having no check to run would never have been
  offered again. It now reads the reason and says whether the condition is met.

  Verification: WSL `./scripts/validate.sh` passed on 2026-08-02, reporting
  `installer integration test passed` and `validation passed: 10 skills checked`,
  which is what covers the new skill's front matter, its `name` matching its
  directory, the absence of a `[TODO:` marker, and the `docs/SKILLS.md` inventory
  matching the skill directories. Of the tools it probes, this WSL installation has
  only `python3` and `git`, confirmed rather than assumed this session, so it
  skipped ShellCheck, `node --check`, `codex execpolicy`, and both PowerShell
  checks; none of them reads a file this change touches, which adds one Markdown
  skill, one YAML metadata file, and edits Markdown documents.

  Every command the skill tells an agent to run was run in a scratch repository
  first. `git init -b main` works on Git 2.55; `git log` exits non-zero in a
  repository with no commits, so the inventory tolerates that. With
  `.gitattributes` in the first commit, a file then written with CRLF is staged as
  LF and `git add --renormalize .` stages nothing, which is what proves the claim
  that a repository starting with the file never converts anything. `git
  check-ignore -v` names the matching rule for a path that does not exist yet,
  which is what makes the ignore rules checkable in that first commit. The marker
  fragment was parsed with `json.loads` and every deferral checked for a non-empty
  reason. No three-platform run was asked for: the change touches no script, no
  workflow, and no installed path beyond the skill directory the installer links
  identically everywhere.
- [x] Prove the loop on a scratch repository: adopt, change the baseline,
  re-apply, and confirm no customisation is lost and a second re-apply reports
  nothing to do. Done on 2026-08-02, and it found four defects, which is what the
  task was for. Every rule in the three skills had been reasoned from this
  repository's own history and none had been run.

  The scratch repository was built to fire the interesting branches rather than the
  clean ones: a `CLAUDE.md` carrying content with no `AGENTS.md`, a real
  `.claude/skills` directory holding a project-specific skill, a `run-tests.sh`
  committed with CRLF so the renormalisation had work, a `github.com` remote, and
  pytest and ruff so the CI definition was derived rather than declined. The
  baseline and the pool were cloned first and moved forward afterwards, so the
  update run had to fast-forward an existing clone. The baseline change added two
  template sections on purpose: `## Dependencies`, writable from what the
  repository shows, and `## Deployment targets`, which is not, because nothing
  releases the project.

  Adoption came out clean against the skill's own validation list: `AGENTS.md`
  carries every rule the old `CLAUDE.md` held, `CLAUDE.md` is a bare import, the
  local skill moved to `.agents/skills/` before the directory became a junction,
  the pooled `linux-sysadmin` copy was byte-identical to the pool, every path the
  marker records as adopted exists and every declined one does not, and
  `git add --renormalize .` stages nothing after the conversion commit and the
  working-tree refresh. The update run added `## Dependencies` only, reported
  `## Deployment targets` rather than writing an empty heading, refreshed the
  pooled skill to the new pool commit, and held `baseline.commit` back because
  something was outstanding. `git diff --numstat` on the adopted documents reported
  `6 0 AGENTS.md`: additions only, no customisation touched. Recording the dropped
  section in the scratch repository's own `DECISIONS.md` then let the next run
  advance the commit, and a third run reported nothing to add and nothing
  outstanding.

  The four defects, all in the instructions rather than the design, and all fixed:

  - The Windows wiring command never worked. `New-Item -ItemType Junction -Target
    .agents/skills` fails with "Creating a junction requires an absolute path for
    the target" and creates nothing, so every Windows adoption would have stopped
    there. Fixed with `(Resolve-Path .agents/skills)`. The deliberately relative
    `ln -s ../.agents/skills .claude/skills` form was checked under WSL and is
    correct, so the asymmetry is now stated in the skill.
  - Adoption never said to keep the template's heading text, only to adapt the
    template and delete what does not apply. The adapted `AGENTS.md` therefore
    carried three headings of its own against the template's six, and the update
    run reported the entire template as missing.
  - The heading comparison is valid for four of the seven templates.
    `DECISIONS.md` and `CHANGELOG.md` hold one placeholder entry heading, and
    `ROADMAP.md`'s are example phase names, so comparing those three reports noise
    that reads exactly like a missing section.
  - The loop could not converge. "Read `DECISIONS.md` before calling it drift" sat
    only in the convention-drift section, so a template section a repository
    deliberately does not have was re-reported every run and the recorded commit
    could never advance past it. Adoption tells every repository to delete the
    sections that do not apply, so this affected all of them.

  The last three are one contract, recorded in `DECISIONS.md` as "Heading text is
  the contract between a template and an adopted document". Validation: WSL
  `./scripts/validate.sh` passed after the fixes, reporting `installer integration
  test passed` and `validation passed: 10 skills checked`; this WSL installation has
  only `python3` and `git` of the tools it probes, so ShellCheck, `node --check`,
  `codex execpolicy`, and both PowerShell checks were skipped, and none of them
  reads a skill file.

  Two paths stay unexercised and are worth naming rather than implying: the
  repository was adopted rather than started from empty, and its host was read from
  a `github.com` remote rather than asked for. The proof also recorded local paths
  as the baseline and pool URLs, because the baseline commit under test is not on
  `origin`, so an HTTPS clone of either repository is untested.

## Candidate work: MCP server management

Not scheduled. Add this to `SPEC.md` and the roadmap only after a concrete
cross-machine MCP requirement justifies it.

- [ ] Add an opt-in MCP server manifest and install it with `codex mcp add` and
  `claude mcp add`, leaving MCP state untouched without the explicit option.
- [ ] Choose a manifest format that survives both interfaces: `codex mcp add`
  and `claude mcp add` take different arguments, and Claude Code also accepts
  `claude mcp add-json`.
- [ ] Keep tokens, headers, and credentials out of the repository. Record only
  the command, arguments, and non-secret configuration.

## Completed phase: Enforced repository governance

Everything reachable is done. The two scanning items were written as settings to
visit and turned out to be purchases to make: the API refuses to enable either
product on this private repository, in the product's own words, so both are closed
as one accepted exception in `DECISIONS.md` with the conditions that reopen them.
Nothing in this phase now waits on an external setting.

- [x] Confirm secret scanning and push protection are enabled.

  Read on 2026-08-02, once `gh` was authenticated, with a token the API reports as
  having `admin` on the repository: neither is on. `GET /repos/rwgs/ai` returns
  `security_and_analysis: null`, `GET /repos/rwgs/ai/secret-scanning/alerts`
  returns HTTP 404 `Secret scanning is disabled on this repository`, and
  `GET /repos/rwgs/ai/code-scanning/alerts` still returns HTTP 403 as the CodeQL
  task below records. So this item is not a confirmation but an enablement, and it
  needs the repository settings changed outside this environment. Whether either
  product is available for a private repository on this account's plan was not
  established here and is the first thing to check in those settings.

  A related boundary was established on 2026-08-02 by the ruleset task below:
  rulesets and branch protection both return HTTP 403 on this repository with
  `Upgrade to GitHub Pro or make this repository public to enable this feature.`,
  so this account has no paid repository features here. That is not proof about
  these two products, which are sold separately as GitHub Secret Protection and
  GitHub Code Security, but it is the same boundary and it says what to expect
  before the settings are opened.

  Both reads were repeated on 2026-08-02 rather than carried forward:
  `security_and_analysis` is still `null`, the secret-scanning alerts endpoint still
  returns HTTP 404 `Secret scanning is disabled on this repository`, and the
  code-scanning alerts endpoint still returns HTTP 403.

  Closed on 2026-08-03 by writing instead of reading, which is what three identical
  reads could never settle. A read reports the products off and says nothing about
  why; the refusal of a write names the reason. `PATCH /repos/rwgs/ai` setting
  `security_and_analysis.secret_scanning.status` to `enabled` returns HTTP 422
  `Secret scanning is not available for this repository.`, with the token that
  carries `repo` scope and `permissions.admin` here and wrote the security-updates
  switch the day before. So this is not a checkbox nobody had ticked, and the item
  is an accepted exception rather than an enablement, recorded in `DECISIONS.md` as
  "Scanning is unavailable here, and an accepted write is not a change" alongside
  the code-scanning half below.

  Push protection is the half that would have been reported wrongly. The same
  `PATCH` for `secret_scanning_push_protection` returns HTTP 200 with the full
  repository object, and that object reports push protection still `disabled`: it
  depends on the secret scanning that is unavailable, so GitHub accepts the request
  and applies nothing. The status code alone would have closed this as enabled.
  That is now a rule in the `docs/WORKFLOW.md` security baseline, because an
  accepted write that changes nothing is indistinguishable from a successful one at
  the moment somebody records that a control is on.

  Two smaller things were established on the way. `GET /repos/rwgs/ai` reports
  `security_and_analysis: null` before and after every attempt, so that field's
  absence is not evidence about any individual switch, and the per-product statuses
  appeared only inside the accepted `PATCH` response. That response is also the
  only confirmation from any endpoint that the Dependabot security-updates switch
  enabled on 2026-08-02 is still on, reading `enabled` next to four `disabled`
  secret-scanning keys. And the plan name was not read: `GET /user` returns `plan:
  null` for a token without `user` scope, so the boundary rests on the refusals
  rather than on the plan, which is the better evidence of the two.

- [x] Confirm the retained dependency-update mechanism actually delivers. It was
  gated behind deciding how updates could be delivered under the accepted
  workflow, and "Bots may open pull requests, humans may not" settled that on
  2026-07-31. Read on
  2026-08-02: the dependency graph detects all three pinned actions in its SBOM,
  which is the prerequisite Dependabot reads manifests through, and Dependabot
  alerts are on, `GET /repos/rwgs/ai/vulnerability-alerts` returning HTTP 204 with
  no open alerts.

  Dependabot has opened no pull request, ever, and it took two wrong readings to
  find out why. The first said every pin was current. The second said the CodeQL pin
  was behind and quoted `ea14db8a` as the newer commit, which is not a commit at
  all: `v4.37.4` and `v4` are annotated tags, so `git/ref/tags` returns their tag
  object, and comparing a commit against a tag object is what produced both the
  wrong SHAs and an HTTP 404 from the compare endpoint. `codeql-bundle-v2.26.2` and
  `v7.0.1` are lightweight tags pointing straight at commits, which is why they
  looked comparable.

  Dereferenced properly, the conclusion held and the numbers behind it did not.
  `v4.37.4` resolves to commit `f205ea1c`, and the moving `v4` tag resolves to the
  same commit, so the major is at 4.37.4 too. `actions/checkout` is pinned at
  `3d3c42e5`, which is exactly what `v7.0.1` points at and `v7.0.1` is the latest
  release, so that pin is current. Both `github/codeql-action` steps were pinned at
  `18420e32`, the commit behind `codeql-bundle-v2.26.2`, and the compare endpoint
  reports that commit five behind `f205ea1c` in `CHANGELOG.md`,
  `src/defaults.json`, `lib/defaults.json`, and `lib/entry-points.js`. The two
  `defaults.json` files are the action's default CodeQL bundle, so this was a real
  update and not a tag-shuffling artefact.

  So work was available and nothing was produced, which is a defect in this
  repository's pin rather than a fact about Dependabot. It reads the trailing comment
  to decide what version an action sits at, and `codeql-bundle-v2.26.2` is not a
  point on the semver stream it compares against, so the pin was immutable, correct
  for every supply-chain reason, and invisible to the updater. That is now recorded
  as a baseline rule: a pin names a ref the update path can compare against, because
  one that cannot be placed on a version stream is silently never updated and looks
  exactly like a pin that is current.

  Acted on rather than left as a finding, under "Dependency updates are monthly,
  grouped, and pinned to a version tag" in `DECISIONS.md`. Both CodeQL steps are
  repinned to `f205ea1c` with a `# v4.37.4` comment, verified by dereferencing the
  tag through the API rather than from the edit. `.github/dependabot.yml` is monthly
  with every `github-actions` bump grouped into one pull request, because the
  measured cadence -- twelve `codeql-action` version tags and two `actions/checkout`
  releases in the thirteen weeks to 2026-07-30 -- annualises to roughly fifty pull
  requests over a two-action surface for one maintainer. Dependabot security updates
  are enabled: `PUT /repos/rwgs/ai/automated-security-fixes` now reports
  `{"enabled":true,"paused":false}`, which is what makes a monthly routine cadence
  safe.

  One gap was found rather than confirmed, and closing it is what the enablement
  above was. `GET /repos/rwgs/ai/automated-security-fixes` returned
  `{"enabled":false,"paused":false}` while alerts were on and version updates were
  configured, so the mechanism the security baseline and `DECISIONS.md` both called
  "Dependabot" was one of the two switches GitHub has: `dependabot.yml` for routine
  bumps, a repository setting for advisory-driven ones. Unlike secret scanning and
  code scanning, that switch is reachable from the API with the current token and is
  not plan-gated.

  The comment was the cause, proved on 2026-08-02 rather than left as the
  hypothesis the plan expected to carry for a month. The claim that only the
  repository's Dependabot tab reports a version-update job is wrong: each job is an
  Actions workflow run named `Dependabot Updates`, which `gh run list` shows and
  `gh run view --job=<id> --log` reads in full. Two jobs bracket the repin and
  differ in one thing.

  Run `30762102588`, job `91534370435` at 18:52Z, ran `"command":"version"` under
  the pre-change configuration, which its job definition shows as
  `"dependency-groups":[]`. It logged `Checking if github/codeql-action/analyze `
  with no version at all, resolved `Latest version is
  18420e3271f74589575af831a523c833acda327f`, which is the pinned commit itself, and
  concluded `No update needed`. Run `30762519578`, job `91535490362` at 19:03Z, ran
  on the push that repinned, with
  `"dependency-groups":[{"name":"github-actions","rules":{"patterns":["*"]}}]` in
  its job definition. It logged `Checking if github/codeql-action/init 4.37.4 needs
  updating`, resolved `Latest version is 4.37.4`, and concluded `No update needed
  for github/codeql-action/init 4.37.4`, then the same for `analyze`. So a bundle
  tag in the trailing comment left Dependabot with no version to place on a stream
  and comparing the pin against itself, and a version tag puts it on the release
  stream where an update would be visible. `actions/checkout 7.0.1` parsed
  correctly in both runs, which is the control that makes it the comment rather
  than the ecosystem.

  Three things follow. Version updates do run on this repository, so the remaining
  alternative explanation is eliminated. The grouped configuration is live in the
  job definition rather than only in the file. And no pull request is expected now,
  because both pins are current: `gh pr list --state all` returns nothing, and this
  repository has never had one. The deliberately downgraded pin considered as an
  experiment stays rejected and is now unnecessary.
- [x] Reconcile the no-branch, no-pull-request decision with all PR-only
  artifacts. Recorded in `DECISIONS.md` as "Bots may open pull requests, humans
  may not": Dependabot stays and the `Validate` workflow keeps its
  `pull_request` trigger so its bumps are checked, while the unreachable
  `dependency-review` job and `.github/pull_request_template.md` are removed.
  `docs/WORKFLOW.md` now states each security rule with the condition that makes
  it apply.
- [x] Enable code scanning for this private repository, then restore the
  `CodeQL` workflow's `push` and `schedule` triggers. Confirmed by dispatched run
  `30676585363` on `5ed2536`: both jobs check out, initialise, and build their
  databases, then fail uploading with `Resource not accessible by integration`
  after warning `Code scanning is not enabled for this repository`. On a private
  repository that needs GitHub's code security product enabled in settings. The
  workflow is dispatch-only meanwhile, so it does not fail on a schedule the way
  the `dependency-review` job silently never ran. Acceptance: a dispatched run
  uploads results and the alerts endpoint stops returning HTTP 403.

  That acceptance cannot be met from here, established on 2026-08-03 rather than
  assumed. "Enabled in settings" was the wrong description: `PATCH /repos/rwgs/ai`
  setting `security_and_analysis.advanced_security.status` to `enabled` returns HTTP
  422 `Advanced security has not been purchased.`, and both `GET` and `PATCH
  /repos/rwgs/ai/code-scanning/default-setup` return HTTP 403 `Code scanning is not
  enabled for this repository. Please enable code scanning in the repository
  settings.` The product is sold for a private repository and this account has not
  bought it, which is the same boundary as the rulesets and the secret scanning
  above.

  Closed as part of the accepted exception recorded in `DECISIONS.md` as "Scanning
  is unavailable here, and an accepted write is not a change", with the maintainer
  as owner and two reopening conditions: the repository is made public, or the
  product is bought. The workflow stays as it is. Its `push` and `schedule`
  triggers stay commented, and that comment already names this task as the step
  that restores them, so the file needs no edit for the exception; deleting the
  workflow was rejected because it analyses both languages correctly on dispatch
  and `scripts/validate.sh` requires it. Nothing replaces it: ShellCheck and
  PSScriptAnalyzer cover the scripts that hold nearly all of this repository's
  logic, but the two files CodeQL was configured for get `python3 -m py_compile`
  and `node --check`, which are syntax checks and not analysis.
- [x] Reconcile `pr-readiness` with the single-maintainer path. Its workflow
  required a fresh independent review while `DECISIONS.md` rejects a gate that
  needs a second party. Recorded in `DECISIONS.md` as "Local readiness names the
  review it did not get": the gate keeps its strength and gains a condition, which
  is that the repository asks for a review in its instructions or decisions, or
  its host enforces one over the changed paths. Where nothing settles the
  question, the requirement is reported as undetermined rather than resolved to
  whichever answer suits the change.

  Where the author is the only party, a new `Readiness without an independent
  reviewer` section replaces the gate with four things one person can produce: the
  complete required gate run and reported by command, every automated review the
  repository does have confirmed against the commit under review, a separate pass
  over the finished diff read against the requirements rather than the intent, and
  the leftover risk named. Three of the four are commands and their output; the
  fourth is the only judgment in the set, and it is worded so it cannot be reported
  as a review. The result is local readiness with the missing review stated as a
  limitation, and self-approval is refused outright, which is the argument the
  superseded no-pull-request entry already made and the skill did not carry.

  `docs/WORKFLOW.md` step 12 pointed at "the skill's no-pull-request path", which
  the skill never named and which is a different axis anyway; it now names both
  reduced paths, because this repository is on both and a repository can be on
  either alone.

  Verification: the skill was read end to end after the edit, because no check
  reads its prose, and every rule that was there before is still there. WSL
  `./scripts/validate.sh` passed on 2026-08-02, reporting `installer integration
  test passed` and `validation passed: 10 skills checked`, which is what covers the
  skill's front matter, its `name` matching its directory, the absence of a
  `[TODO:` marker, and the `docs/SKILLS.md` inventory. Of the tools it probes, this
  WSL installation has only `python3` and `git`, so it skipped ShellCheck, `node
  --check`, `codex execpolicy`, and both PowerShell checks, none of which reads a
  file this change touches. No three-platform run was asked for: the change touches
  no script, no workflow, and no installed path beyond one skill file the installer
  links identically everywhere.
- [x] Decide whether a default-branch ruleset is worth configuring at all. Both
  halves of the question were read rather than recalled, and both answers moved.
  Recorded in `DECISIONS.md` as "The default branch is worth protecting and cannot
  be protected here".

  The premise is wrong. Nine of the sixteen branch rules GitHub documents are
  enforced when a commit is pushed and need neither a pull request nor a reviewer:
  restricting creations, updates, and deletions, requiring signed commits,
  blocking force pushes, and the four file restrictions on path, path length,
  extension, and size. The seven that need a pull request are the merge gates, and
  they are not the useful part. Blocking a force push and blocking deletion matter
  more without a reviewer, not less, because nothing else stands between a
  mistyped command and the history.

  This repository can configure none of it. Read on 2026-08-02 with a token
  carrying `repo` scope, `GET /repos/rwgs/ai/rulesets`,
  `GET /repos/rwgs/ai/rules/branches/main`, and
  `GET /repos/rwgs/ai/branches/main/protection` each return HTTP 403 with
  `Upgrade to GitHub Pro or make this repository public to enable this feature.`
  The account is a `User` and the repository is private. That is an accepted
  exception with the maintainer as owner, reopened if the repository is made
  public or the account moves to a plan that includes the feature. Neither is
  worth doing for two branch rules.

  `docs/WORKFLOW.md` gained the capability rule its `Default-branch enforcement`
  row never had, so the baseline asks for the protection rather than only naming
  the mechanism, and the row and the paragraph under the table now state the plan
  boundary and the push-against-merge split. Nothing about that split is verified
  here, because the API refuses the read that would show it.

  Verification: WSL `./scripts/validate.sh` passed on 2026-08-02, reporting
  `installer integration test passed` and `validation passed: 10 skills checked`.
  This WSL installation has only `python3` and `git` of the tools it probes, so
  ShellCheck, `node --check`, `codex execpolicy`, and both PowerShell checks were
  skipped, and none of them reads a file this change touches. The security
  baseline was re-read afterwards to confirm every rule has a mechanism in the
  table and every row has a rule above it.

## Completion rule

Move current-phase tasks to completed only after their acceptance criteria and
required validation pass. Keep external GitHub settings pending until verified
through the live repository.
