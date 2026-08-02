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

## Blocked phase: State-preserving installation and reliable validation

Everything implementable here is done and verified on three platforms. The three
items left need an action outside this environment: a personal access token, a
repository setting, and Windows Developer Mode or an elevated shell.

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
- [ ] Install on this machine only after the state-preserving behavior passes.
  This is a first install, and symbolic links still require enabling Developer
  Mode or using an elevated shell. Acceptance: dry-run reports the intended
  changes, the real install preserves the pre-existing Codex and Claude state,
  and both agents report the expected instructions and skills after restart.

## Blocked phase: A tree of its own

Every restatement is done and committed. What is left is the three-platform run
that proves the four restated functions, which needs a push and a run to read.
`gh` is installed here but unauthenticated, with no token in the environment, so
the run cannot be read from this session.


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

- [ ] Restate the four selected functions, bodies only. `resolve_path` and
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
  target passed to it is built from one of the three managed homes. Remaining:
  the three-platform run, which needs a push.

## Blocked phase: Host-neutral version control

The baseline must serve a repository hosted on Azure DevOps, hosted service or
on-premise server, as well as one on GitHub. Neither Azure DevOps variant is in
use, so this phase separates the host-neutral core from the host-specific edge
and ships the Azure DevOps side labelled unverified. `DECISIONS.md` records the
choice as "Both hosts are supported, only GitHub is verified"; the approach and
the seven couplings it addressed were in the `PLAN.md` since replaced.

Everything implementable is done, committed, and validated locally. What is left
is the three-platform run, which needs a push and a run to read. `gh` here is
unauthenticated with no token in the environment.

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
- [ ] Run WSL `./scripts/validate.sh` and report which checks it performed, then
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
  Remaining: the three-platform run. `3749b3e` is already on `origin/main`, and
  `gh` here is unauthenticated with no token in the environment, so no run can
  be read from this session.

## Current phase: Re-appliable repository baseline

The marker and the update skill that reads it are both in place. `PLAN.md` carries
the update skill's approach. What is left is the propagation adoption still skips,
an entry point for a new repository, and the proof of the loop on a scratch
repository, which is the only one of the three that verifies any of this against a
real repository.

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
- [ ] Extend adoption to install `.gitattributes` and offer the validation
  workflow and the Dependabot configuration. There is no pull-request template
  to propagate any more, and an adopting repository that accepts no bot pull
  requests should be offered neither Dependabot nor the `pull_request` trigger.
  Both artifacts are host-specific, so adoption offers the one matching the
  adopting repository's host and says so when the host has no equivalent. This
  is why the phase depends on the host-neutral phase above.
- [ ] Give a new repository its own entry point instead of a skill named for
  adopting an existing one.
- [ ] Prove the loop on a scratch repository: adopt, change the baseline,
  re-apply, and confirm no customisation is lost and a second re-apply reports
  nothing to do.

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

## Later phase: Enforced repository governance

- [ ] Confirm secret scanning and push protection are enabled. Confirm
  Dependabot only after deciding how it can deliver updates under the accepted
  workflow.
- [x] Reconcile the no-branch, no-pull-request decision with all PR-only
  artifacts. Recorded in `DECISIONS.md` as "Bots may open pull requests, humans
  may not": Dependabot stays and the `Validate` workflow keeps its
  `pull_request` trigger so its bumps are checked, while the unreachable
  `dependency-review` job and `.github/pull_request_template.md` are removed.
  `docs/WORKFLOW.md` now states each security rule with the condition that makes
  it apply.
- [ ] Enable code scanning for this private repository, then restore the
  `CodeQL` workflow's `push` and `schedule` triggers. Confirmed by dispatched run
  `30676585363` on `5ed2536`: both jobs check out, initialise, and build their
  databases, then fail uploading with `Resource not accessible by integration`
  after warning `Code scanning is not enabled for this repository`. On a private
  repository that needs GitHub's code security product enabled in settings. The
  workflow is dispatch-only meanwhile, so it does not fail on a schedule the way
  the `dependency-review` job silently never ran. Acceptance: a dispatched run
  uploads results and the alerts endpoint stops returning HTTP 403.
- [ ] Reconcile `pr-readiness` with the single-maintainer path. Its workflow
  currently requires a fresh independent review while `DECISIONS.md` rejects a
  gate that needs a second party. Define what local readiness requires when no
  independent reviewer exists, and keep the stronger gate for repositories that
  do require one.
- [ ] Decide whether a default-branch ruleset is worth configuring at all. Every
  gate previously planned here required a pull request or a second reviewer, and
  neither exists in a single-maintainer flow.

## Completion rule

Move current-phase tasks to completed only after their acceptance criteria and
required validation pass. Keep external GitHub settings pending until verified
through the live repository.
