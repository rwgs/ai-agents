# Repository review

Reviewed on 2026-09-08 at commit
`730217aa4a03b2990e187279f1239e0130855d3e`.

## Assessment

The direction is right for one developer using two agents across operating
systems. Keep the separation between portable configuration and machine state,
one source for shared instructions and skills, and explicit installer ownership.
Those choices solve real problems.

The implementation needs hardening before further expansion. Both installers
can corrupt an existing valid Codex configuration, the command allowlist is much
broader than the stated approval posture, and parts of validation can report
success despite errors. The documentation also costs more to maintain than the
current workflow consistently supports.

This review recommends changes; it does not implement them. Priorities below
mean: P1 should be addressed before the next installer rollout; P2 should be
addressed in the next maintenance pass.

## Findings

### 1. P1: Valid TOML can become invalid during installation

Sources: [merge-agent-state.py](scripts/merge-agent-state.py), lines 34, 103 and
161; [install.ps1](scripts/install.ps1), lines 455, 530 and 586.

Both implementations identify TOML tables and keys with line-based regular
expressions. They do not recognize a table header with a trailing comment or a
dotted key. Neither checks that the resulting document parses before writing it.

This valid existing configuration reproduces the problem:

```toml
[features] # local choices
memories = false
```

Using the repository's actual source configuration, both merge functions append
another `[features]` table. Python's `tomllib` rejects the result with
`Cannot declare ('features',) twice`. The Python implementation also fails on
the valid input `features.memories = false`.

The installer can therefore break Codex startup while violating its central
promise to preserve machine-owned settings. A backup makes recovery possible
but does not make the merge correct. The existing PowerShell integration test
passes despite this defect.

Recommendation: preserve the entire target and report unsupported syntax until
it can be handled correctly. Validate the proposed output before replacing the
target. Add the same commented-header and dotted-key fixtures to both installer
tests, asserting parseability and preservation of the user's `memories = false`.
The existing decision to use textual edits can remain; silently treating
unrecognized syntax as an absent setting cannot.

### 2. P1: The allowlist undermines the advertised approval boundary

Sources: [default.rules](ai-home/rules/default.rules), especially lines 3, 7,
24 and 156; [README.md](README.md), line 151;
[SPEC.md](SPEC.md), line 42.

The baseline promises to ask before acting outside the workspace. It also
permits every invocation of `rtk`, `pkexec`, `xargs`, package runners, and
infrastructure tools such as `terraform`. These prefixes cover far more than
inspection and local development.

This policy-only check returned `decision: allow` with Codex CLI 0.153.0:

```text
codex execpolicy check --rules ai-home/rules/default.rules rtk git push --force
```

The command being checked was not executed. The result demonstrates that the
wrapper rule approves a force push, irrespective of the absence of a direct
Git force-push grant. OpenAI documents `allow` as permitting a matching command
outside the sandbox without prompting. Other enforced policies may still
restrict execution. [Official rules documentation](https://learn.chatgpt.com/docs/agent-configuration/rules)

The broad latitude is acknowledged in `docs/AGENT_LAYOUT.md`, so this is a
design inconsistency rather than a hidden implementation choice. Sharing the
same grants with Claude Code also spreads that choice to both agents.

Recommendation: choose and document one posture. For the stated conservative
baseline, remove blanket grants for wrappers and general command runners, and
scope approvals to operations actually intended to run unattended. Extend the
Claude derivation first: the current implementation only translates single-token
allow patterns, a limitation already recorded in `SPEC.md`. Add policy checks
for both permitted operations and operations that must require approval.

### 3. P2: Bootstrap dry runs update the live installation source

Sources: [bootstrap.sh](scripts/bootstrap.sh), lines 38-56;
[bootstrap.ps1](scripts/bootstrap.ps1), lines 59-85.

Both bootstraps fetch, check out, and fast-forward the permanent clone before
forwarding the dry-run flag to the installer. That clone is also the source of
the installed symbolic links, junctions, and Claude instruction import.

Reproduced with temporary local Git repositories: after an upstream commit
changed an instruction file from `version one` to `version two`, both
`bootstrap.sh --dry-run` and `bootstrap.ps1 -DryRun` changed the existing clone
to `version two`. The fixture installer only printed `dry run complete`; the
bootstrap itself performed the update.

Consequently a preview can change the source that agents read, even though it
does not write their home directories. The existing tests explicitly allow a
clone during bootstrap dry runs, but they do not establish that an already
installed source stays unchanged when upstream has a new commit.

Recommendation: preview updates from a temporary checkout, leaving the active
clone's branch and working tree unchanged. Add a test with a real upstream
change and assert that both the installed source and its revision remain
unchanged after a dry run.

### 4. P2: Skill validation errors do not reach the final exit status

Source: [validate.sh](scripts/validate.sh), lines 173-207 and 324.

`validate_skill_tree` calls `fail`, which increments `errors`. The function runs
inside `$(validate_skill_tree .agents/skills | sort)`, so those increments occur
in a subshell and disappear. The function still prints the skill directory
name, allowing the documented inventory comparison to succeed.

An isolated harness using the actual validator functions and a skill missing
its description produced:

```text
error: .agents/skills/example/SKILL.md has no description
parent errors=0; inventory=example
exit: 0
```

The same mechanism affects other content checks inside that function, including
the opening front-matter delimiter and TODO markers. Missing directories or
files can still be caught by separate checks; this is not a claim that every
skill error is ignored.

Recommendation: propagate an explicit failure status or validate in the parent
shell. Exercise the complete validator with deliberately malformed skills and
assert a nonzero exit, not just the presence of an error message.

### 5. P2: The fallback rule validator accepts invalid decision names

Source: [validate.sh](scripts/validate.sh), lines 144-154 and 283-298.

The regular expression accepts `allow|deny|ask`. Codex CLI 0.153.0 rejects
`deny` and `ask` as invalid decisions, while accepting `prompt` and `forbidden`.
Those are also the names in the
[official rules documentation](https://learn.chatgpt.com/docs/agent-configuration/rules).

The shipped rules all use `allow`, so this does not currently prevent loading
them. It does mean a future attempt to tighten the policy can pass the fallback
check with a rule Codex refuses, or fail with a rule Codex accepts. The real
parser check is conditional on Codex being installed, and the CI workflow does
not install it.

Recommendation: correct the accepted vocabulary and test all supported decisions
plus invalid ones. Keep a real parser compatibility check against an explicitly
recorded Codex version; a regular expression is only a limited format check.

## What to keep and what to simplify

- **Keep the ownership model.** Recording which entries the installer introduced
  is substantially safer than replacing entire agent homes. Preserving edits,
  backing up shared files, and testing reruns are appropriate investments.
- **Keep the platform distinction.** Junctions, imports, and copies solve the
  Windows privilege problem. Native PowerShell avoids an interpreter dependency
  there. A rewrite solely to share code would have to justify losing that
  benefit. First share behavioral fixtures, especially rejection cases, between
  the two implementations.
- **Revisit the dedicated Codex rules-file option.** The provenance decision in
  `DECISIONS.md` left this open because discovery of additional rule files was
  unverified. Current official documentation describes `.rules` files under
  active configuration layers and distinguishes them from the interactive
  `default.rules`. That is new evidence for keeping baseline rules in their own
  file and reducing interaction with Codex's approvals. Claude settings would
  still need a merge, and existing installs would need a provenance-aware
  migration. [Official rules documentation](https://learn.chatgpt.com/docs/agent-configuration/rules)
- **Reduce repeated documentation.** At the reviewed revision, `TASKS.md` has
  1,219 lines and `DECISIONS.md` has 2,227. Length alone is not a defect, but
  observable drift is: the README describes CodeQL analysis without mentioning
  that the workflow is dispatch-only and its upload is unavailable; SPEC still
  lists bot dependency updates as unresolved after the accepted bot-PR decision;
  WORKFLOW step 15 says to dispatch after pushing, while AGENTS explicitly says
  that cancels a competing run. Keep the existing document roles, shorten
  repeated histories, and reconcile these claims. No new planning system is
  needed.
- **Measure the skills' practical value.** The installed set is reasonably
  focused and the adoption skill already scales documentation to repository
  type. Structural validation does not establish that agents select the right
  skill or finish tasks with less intervention. Before adding more process,
  compare a few representative tasks in each agent: selection, successful
  completion, unnecessary stops, and user corrections. This review did not run
  such a behavioral evaluation.

## Verification and limits

- Windows PowerShell 5.1: `scripts/test-install.ps1` passed. It reported the two
  expected skipped symbolic-link fixtures because the shell lacks the required
  privilege. All three PowerShell scripts parsed without errors.
- Python 3.14.7: the merge helper parsed, and all three shipped Codex TOML files
  parsed. These checks validate the source files, not every possible merge.
- Codex CLI 0.153.0: the shipped policy parsed; the wrapper approval and decision
  vocabulary checks above were executed without running the checked commands.
- `scripts/validate.sh` was run through Git Bash. It exited 1 when the Unix
  integration test expected a symbolic link that Git Bash had not created. Its
  preceding repository, Bash syntax, Python compilation, TOML, and Codex policy
  checks reported no errors. Node was available, but there are no current skill
  JavaScript files to check. ShellCheck, PowerShell 7, PSScriptAnalyzer, RTK, and
  an installed WSL distribution were unavailable in this environment.
- Targeted temporary fixtures reproduced the TOML corruption, bootstrap update,
  and lost validator error status described above. The skill harness isolated
  that validation path; it was not a successful full-suite run.
- No live installation, plugin installation, agent restart verification, new
  GitHub Actions run, or Azure DevOps verification was performed. Existing
  documentation's historical CI results were not treated as current evidence.

The next work should be a focused hardening pass on these five findings. The
repository does not need a broader framework to justify its existence; it needs
its existing preservation, approval, and validation guarantees to hold.
