# State-preserving installation

Approach for the change currently in flight. Replaced when the next non-trivial
change begins, so anything that must outlive it is promoted first: verified
product facts to `SPEC.md`, actionable work to `TASKS.md`, and closed choices to
`DECISIONS.md`.

## Problem

Installation replaces state the agents own. `~/.codex/config.toml` is rendered
from the repository, discarding marketplace registrations, plugin enablement,
`mcp_servers`, `shell_environment_policy`, `[desktop]`, `personality`, `notify`,
`[windows] sandbox`, and every trust entry outside `~/github`. `~/.codex/rules`
is replaced by a link into this repository, so the machine keeps only the curated
file and every approval Codex records afterwards lands in this working tree.
`~/.claude/settings.json` is merged but append-only, so removing a rule from the
curated source cannot withdraw the permission it granted.

## Constraints discovered

- The worktree began clean on `main` at `f0a0c6f`, matching `origin/main`.
- `~/.codex/rules/default.rules` on this machine holds 48 interactively approved
  rules, no comments, and none of the curated set. Its first rule,
  `prefix_rule(pattern=["Get-Content"], decision="allow")`, is a single-token
  prefix, the same shape the curated file uses.
- `~/.claude/settings.json` on this machine holds 832 allow entries with no
  duplicates. Thirty-four are the `Tool(command *)` shape the installer derives,
  including `Bash(git add *)`. None of the 278 currently derived entries is
  present, because the installer has never run here.
- The Codex CLI is on the path in neither PowerShell nor Git Bash nor WSL on this
  machine. Whether Codex loads every `*.rules` file in its rules directory, and
  whether it preserves comments when it appends an approval, cannot be verified
  from here. `scripts/validate.sh` already skips its `codex execpolicy` check
  when the binary is absent.
- Both PowerShell editions are present: `pwsh` 7.6.4 and Windows PowerShell
  5.1.26100.8875. The installer's `ConvertFrom-Json -AsHashtable -Depth 100` runs
  only under the first.
- Neither `gh` nor a personal access token is available here, so the Actions
  check-suite preference cannot be set or read in this session.
- Python's `tomllib` reads TOML and does not write it, and PowerShell has no TOML
  support at all. A `config.toml` merge has to be textual on both sides.

## Approach

- Record the ownership and provenance model first, because every remaining task
  in the phase depends on it. Done: `DECISIONS.md`, "Shared files are merged
  against a recorded provenance manifest".
- Implement the state file, then the three merges against it, in both installers:
  `config.toml` keys and generated trust tables, curated `prefix_rule` lines, and
  derived Claude permissions. Keep the write, withdraw, and preserve-and-report
  rule identical across all three so one behavior is tested three times.
- Stop linking `ai-home/rules`. Replace an existing link with a real directory and
  report the approvals recorded through it rather than adopting or discarding
  them.
- Decide the execution posture and the minimum PowerShell edition before the code
  that depends on them: the posture decides what `config.toml` merges, and the
  edition decides whether the JSON path may use `-AsHashtable`.
- Close the validation gaps in the same pass, so managed removal and populated
  state are exercised on both platforms rather than described.
- Update `README.md`, `docs/AGENT_LAYOUT.md`, `SPEC.md`, and `CHANGELOG.md` last,
  when the behavior they describe exists.

## Trade-offs

- Merging is more code than rendering, in two languages, with no TOML library on
  either side. The managed key set is small and fixed, so a textual merge that
  refuses to guess is preferred to a parser that rewrites the file.
- An identical grant approved after the installer wrote it is treated as
  installer-owned and withdrawn. That costs one re-approval prompt and is
  reported by name; the alternative is that a rule removed from the curated
  source can never be revoked.
- The first run after this change adopts nothing on an existing installation,
  because no state file exists yet. Managed removal only starts working from the
  run after that.
- Installing on this machine is deliberately last. It is a first install into a
  populated Codex home, which is exactly the case the current installer damages.

## Verification

- `./scripts/validate.sh` under WSL, which is the only local environment here
  that can create symbolic links.
- Installer tests must cover a populated `config.toml`, a populated rules file,
  and a populated `settings.json`: machine entries survive, a rerun changes
  nothing, removing a curated rule withdraws only the recorded managed grants,
  and a pre-existing identical grant is preserved and reported.
- A manually dispatched three-platform run on `main`, read directly, before
  relying on the push trigger that has never fired.
- A dry run on this machine, inspected against the real `~/.codex` and
  `~/.claude`, before any real install.
