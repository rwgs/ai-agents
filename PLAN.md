# Install on Windows without asking for a privilege

Approach for the change currently in flight. Replaced when the next non-trivial
change begins, so anything that must outlive it is promoted first: verified
product facts to `SPEC.md`, actionable work to `TASKS.md`, and closed choices to
`DECISIONS.md`.

The scanning plan this replaces was already promoted. Its decision is in
`DECISIONS.md` as "Scanning is unavailable here, and an accepted write is not a
change", and its evidence is recorded against the two closed tasks in `TASKS.md`.

## Problem

The first install on this machine is the last open item in Phase 4, blocked since
2026-08-02 because `New-Item -ItemType SymbolicLink` refuses without Developer
Mode or elevation. Re-run on 2026-08-06, it refuses the same way.

The blocker was read as a property of this machine. It is a property of the
installer: any Windows machine that grants neither can install nothing, which a
baseline meant to be portable cannot accept. Nothing had established how much of
the install actually needs the privilege.

Measured rather than assumed, from the call sites at the end of
`scripts/install.ps1`: 24 links, of which 20 are skill directories, two per skill
across `~/.agents/skills/` and `~/.claude/skills/`. Only four are files, and one
of those four has a documented answer that is not a link at all.

## Approach

Windows only. `scripts/install.sh` keeps symbolic links, which need no privilege
on Linux or macOS, so nothing about those platforms changes.

Choose the method by what the target is, not by what the machine happens to
allow, so one install produces one result everywhere:

- The 20 skill directories become junctions. `New-Item -ItemType Junction`
  needs no privilege, and both PowerShell editions report the result as
  `LinkType` `Junction` with a resolved `Target`, which is what the installer's
  existing idempotency and pruning checks read.
- `~/.claude/CLAUDE.md` becomes a real file holding one `@` import of the
  repository's `ai-home/AGENTS.md`, by absolute path with forward slashes. This
  is what Claude Code's own documentation prescribes for Windows without
  Developer Mode, and it never goes stale, because the import is resolved at
  session start.
- `~/.codex/AGENTS.md` and the two `*.config.toml` model profiles are copied.
  Codex has no include mechanism and no key that points at a global instruction
  file: `model_instructions_file` replaces the built-in instructions instead of
  `AGENTS.md`, so it is the wrong key rather than a smaller version of the right
  one.

A copied or generated file is machine-writable where a link was not, so each is
recorded in the install state file exactly as `config.toml`, the Codex rules, and
`settings.json` already are. The installer rewrites one only when it is absent or
byte-identical to what the state file records it wrote, and preserves and reports
anything else. That is the provenance model this repository already uses, applied
where copying now makes it necessary.

Four call sites in `scripts/install.ps1` read `LinkType -eq 'SymbolicLink'`:
`Test-LinkTargetsSource`, `Initialize-RulesDirectory`, `Remove-StaleManagedSkill`,
and the test's `Assert-Link`. Each widens to accept a junction, so an install that
predates this change is recognised rather than backed up and replaced.

## Trade-offs

- A copy goes stale. Editing `ai-home/AGENTS.md` leaves Codex reading the old
  text until the installer is re-run, where a symbolic link needed nothing.
  Accepted because there is no alternative that both works unprivileged and
  tracks the source: hard links create unprivileged but are orphaned by `git
  checkout`, tested on 2026-08-06, which would leave Codex on stale content with
  nothing reporting it. Stated in `README.md` rather than absorbed.
- Three files stop being links, so `~/.codex` no longer shows at a glance which
  files the repository owns. The state file records exactly that, and the
  installer reports every write.
- Rejected: try a symbolic link first and fall back. It makes the installed
  result depend on machine state, doubles what the tests must cover, and leaves
  two shapes in the field for every later run to recognise.
- Rejected: use junctions only, and leave the four files needing the privilege.
  It would fix 20 of 24 links and still refuse to complete on a machine without
  Developer Mode, which is the whole failure being removed.

## Verification

- `./scripts/validate.sh` under WSL, reporting which checks it performed.
- Both PowerShell editions parse the installers, and PSScriptAnalyzer reports
  nothing under the validator's own invocation, run from Windows because WSL has
  neither.
- `scripts/test-install.ps1` gains coverage for each of the three methods and for
  the preservation and handback of a machine-edited copy. It needs no privilege
  once this change lands, so it becomes runnable here rather than only in CI.
- A three-platform run, because this changes an installer. Push to be asked for.
- Then the install itself, with `AI_TRUST_ROOTS` set to `~/Development`: dry run,
  real install, and both agents confirmed after a restart. Claude Code's
  `/context` lists loaded memory files, which is what confirms the import
  resolved; the absolute-path form is documented but unverified here.

### Results

The complete Windows installer integration test passes locally under both
PowerShell 5.1 and PowerShell 7, which has never been possible before: it needed
a symbolic-link privilege this machine does not grant, and CI was the only place
it ran. It reports the two stale symbolic-link fixtures it skips, which CI still
covers because its runners are elevated.

One defect was found by running it, in the test rather than the installer. The
provenance harness dot-sources the installer's functions and sets its script
variables by name, and it did not set the one this change adds, so
`Invoke-AgentStateMerge` failed on an unset variable.

The detour worth recording is Defender. Reading a file into a byte array and
writing one back made AMSI block the whole installer as malicious, reported as a
parser error on line 1, under both editions. It was diagnosed by bisection
against the committed version rather than guessed: `HEAD` was clean, the
byte-array version was blocked, and the same logic written with `Copy-Item`,
`WriteAllText`, and `Get-FileHash` is clean. That also corrected a wrong reading
along the way. The installer test appeared to be blocked too and was recorded as
a pre-existing condition of this machine; it was not, because the test invokes
the installer, and it has run cleanly ever since the installer stopped being
flagged. The rule is now in `AGENTS.md`, because nothing else would catch it: the
block is invisible to the parser, to PSScriptAnalyzer, and to CI.

One path stays uncovered rather than implied. `Set-ManagedFile` replacing a
pre-existing *symbolic* link is untested, because fabricating one needs the
privilege this change removes; the junction fixture exercises the same branch
through `Test-LinkTargetsSource`, and CI's elevated stale-link fixtures cover the
symbolic-link branch of pruning.
