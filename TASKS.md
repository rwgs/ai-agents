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

## Current phase: State-preserving installation and reliable validation

- [ ] Restore automatic validation on pushes to `main`. Actions is enabled, all
  actions are allowed, and `Validate` has a `push: branches: [main]` trigger, but
  pushing `90073f0` created check suites for the `claude` and
  `cloudflare-workers-and-pages` apps and none for GitHub Actions. Manual dispatch
  works. The evidence points to automatic check-suite creation being disabled for
  the Actions app, a per-repository per-app setting with no read endpoint or web
  UI. With a personal access token in `GH_TOKEN` (the Git Credential Manager
  OAuth token receives HTTP 403), run:

  ```
  gh api --method PATCH repos/rwgs/ai/check-suites/preferences \
    -f 'auto_trigger_checks[][app_id]=15368' -F 'auto_trigger_checks[][setting]=true'
  ```

  Acceptance: the response identifies `15368` as GitHub Actions, and the next
  push creates a three-platform `Validate` run without manual dispatch. The
  GitHub connector was not connected during the 2026-07-31 review, so current
  live state remains unverified.
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
- [ ] State the minimum supported PowerShell edition and make implementation and
  CI match it. Decided: Windows PowerShell 5.1 is the floor, recorded in
  `DECISIONS.md`. `install.ps1` and `test-install.ps1` no longer use
  `ConvertFrom-Json -AsHashtable -Depth`, and the merge normalises the Unicode
  escapes 5.1 emits for `<`, `>`, `&`, and `'`, which 278 and 193 of this
  machine's 832 approved entries contain. Verified locally by running the
  installer's own merge functions under 5.1.26100.8875 and 7.6.4: same entries,
  same key order, idempotent, characters intact. The Windows CI job now runs the
  complete installer test under both editions; that run is the remaining
  evidence, because symbolic-link creation needs Developer Mode or elevation and
  fails here in both editions.
- [x] Close executable validation gaps while changing the installers.
  `scripts/validate.sh` now rejects any `default.rules` line that is not one
  `prefix_rule` with a non-empty quoted pattern list and a known decision, which
  needs no Codex binary; the `codex execpolicy` check stays as the stronger one
  where Codex exists. It compiles `scripts/merge-agent-state.py` and runs
  `node --check` over the skills' `.mjs` and `.js` files where Node is present.
  Managed removal and populated Codex state are exercised by both installer
  tests. Checked that the new rule check flags a malformed line and that
  `show-reset-expiries.mjs` passes `node --check`.
- [ ] Update `README.md`, `docs/AGENT_LAYOUT.md`, `SPEC.md`, tests, and
  `CHANGELOG.md` with the implemented behavior, then run the complete local gate
  and a manually dispatched three-platform workflow before relying on the fixed
  push trigger. The documents, tests, and changelog are updated and the local WSL
  gate passes. The dispatched run is outstanding: it needs a push, and it is the
  only evidence available for the Windows installer, because this machine cannot
  create symbolic links without Developer Mode or elevation.
- [ ] Install on this machine only after the state-preserving behavior passes.
  This is a first install, and symbolic links still require enabling Developer
  Mode or using an elevated shell. Acceptance: dry-run reports the intended
  changes, the real install preserves the pre-existing Codex and Claude state,
  and both agents report the expected instructions and skills after restart.

## Later phase: Re-appliable repository baseline

- [ ] Record in an adopting repository which baseline commit it took, which
  documents it adopted, which pieces it declined, and the pool commit behind any
  skill copied from `rwgs/ai-skills`.
- [ ] Add an update mode to `adopt-baseline`, or a sibling skill, that adds
  missing documents and sections and reports drift without overwriting an
  adopted document. It reads both recorded commits, so a copied pool skill is
  reported alongside a stale document.
- [ ] Reconcile the reusable workflows before building update mode:
  `adopt-baseline` must inventory and select `DECISIONS.md` whenever it adopts
  `PLAN.md`, treat `CHANGELOG.md` conditionally, and expose a pooled skill to
  both agents from one project-local source. `ai-project-manager` must discover
  the existing `PLAN.md` and conditional `CHANGELOG.md` it is expected to use.
- [ ] Align `docs/SKILLS.md` with `adopt-baseline` on one dual-agent wiring
  method. The current pool instructions say to copy a skill into both
  `.agents/skills/` and `.claude/skills/`, while the adoption skill requires one
  `.agents/skills/` source plus an ignored link, and the two approaches have
  different drift behavior.
- [ ] Resolve the installed-skill policy exception for
  `show-codex-reset-expiries`: either record why a user-wide agent-operations
  skill is allowed despite being product-specific, or move it to the pool.
- [ ] Extend adoption to install `.gitattributes` and offer the validation
  workflow plus whichever dependency-update configuration Phase 6 retains. Do
  not propagate the current pull-request template into a no-pull-request flow.
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
- [ ] Reconcile the no-branch, no-pull-request decision with all PR-only
  artifacts. Dependabot opens branches and pull requests, `dependency-review`
  is gated on `pull_request`, and `.github/pull_request_template.md` is still a
  validator-required file. Choose and record either a narrowly stated bot-PR
  exception or a non-PR replacement/removal for all three.
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
