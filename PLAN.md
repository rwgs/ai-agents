# Harden the guarantees the baseline already claims

Approach for the change currently in flight. Replaced when the next non-trivial
change begins, so anything that must outlive it is promoted first: verified
product facts to `SPEC.md`, actionable work to `TASKS.md`, and closed choices to
`DECISIONS.md`.

The Windows installation plan this replaces is finished and already promoted. Its
decision is in `DECISIONS.md` as "Windows installs without a privilege, by method
per target", and its evidence sits against the closed tasks in `TASKS.md`,
including the one check still waiting on an agent restart.

## Problem

`review.md` records five demonstrated findings against this repository at
`730217a`. Each one is a case where a stated guarantee does not hold, so the work
is to make the claims true rather than to add anything.

Two were reproduced again here before planning, because a finding recalled is not
a finding read:

- The Codex configuration merge identifies tables and keys with line-based
  regular expressions that reject a table header carrying a trailing comment and
  a dotted key. Given the valid target `[features] # local choices` with
  `memories = false`, both merges append a second `[features]` table, and
  `tomllib` rejects the result with `Cannot declare ('features',) twice`. The
  installer therefore breaks Codex startup while claiming to preserve
  machine-owned settings. `features.memories = false` fails the same way.
- `validate_skill_tree` runs inside a command substitution, so every `fail` it
  calls increments `errors` in a subshell that then exits. A skill missing its
  description prints an error and the validator exits 0.

The other three were read rather than run. Both bootstraps fetch, check out, and
fast-forward the permanent clone before forwarding `--dry-run`, so a preview
changes the source both agents read. The fallback rule check accepts
`allow|deny|ask`; the official documentation, fetched during planning, gives the
decisions as `allow`, `prompt`, and `forbidden`.

The fifth is not an implementation defect. `README.md` says Codex "asks before
acting outside" the workspace, which is true of the sandbox and misleading about
the result, because 139 `prefix_rule` grants run "outside the sandbox without
prompting" in the documentation's own words, and `rtk` is a wrapper matched on
its first token alone, so it covers whatever it runs.

## Approach

### The merge stops at syntax it cannot read

One predicate in each implementation, applied to the same document twice. A TOML
document is unsupported when a line that is neither blank nor a comment is
neither a recognised table header nor a recognised key line, or when a table
header is declared twice. That single rule covers the commented header, the
dotted key, `[[array]]` tables, and any value continued across lines, because
each of them produces a line the merge cannot classify.

It runs on the target before merging, where an unsupported document is preserved
whole and reported, and again on the merged output, where a failure discards the
merge instead of writing it. Bailing out returns the state record unchanged, so
the run claims nothing it did not write, exactly as the existing invalid-JSON
path in the Claude settings merge already does.

Rejected: teaching the regular expressions the two forms. It answers the two
inputs in the review and leaves the next unhandled form silently corrupting, and
the decision to keep the merge textual is recorded and unchanged.

### A dry run leaves the installed source alone

The clone is where the installed links point, so it is part of the target system
a dry run must not touch. On a dry run with a clone already present, both
bootstraps fetch and report the revision the update would move to, then leave the
branch and working tree alone and preview from the current content.

A fetch writes remote-tracking refs only, which is not what an agent reads, and
keeping it is what lets the preview say whether an update is pending. Cloning
into a temporary directory instead was rejected: the installer's preview would
then print link targets in a path that will not exist, which is the wrong preview
of the wrong install. A first run still clones to the permanent location, because
there is nothing to preview from until it does.

### Validation counts what it reports

`validate_skill_tree` collects names into a variable instead of standard output,
so the parent shell runs it and its `fail` calls survive. The decision vocabulary
becomes `allow|prompt|forbidden`.

### The approval posture is documented rather than narrowed

Every grant stays. `README.md`, `SPEC.md`, and `docs/AGENT_LAYOUT.md` state the
two halves separately: the sandbox asks before acting outside the workspace, and
the allowlist is a deliberately broad grant of unattended execution outside that
sandbox, including wrappers that reach whatever they run.

Chosen with the maintainer over tightening the list, which would fight this
repository's own instruction to route noisy commands through `rtk` and needs the
single-token Claude derivation extended first. Recorded in `DECISIONS.md` with
that alternative.

### Documentation reconciled and shortened

Three contradictions, each verified: `README.md` describes CodeQL analysis in the
present tense while `.github/workflows/codeql.yml` is dispatch-only and its
upload is refused; `SPEC.md` still lists dependency updates as unresolved after
two accepted decisions settled them for GitHub; `docs/WORKFLOW.md` step 15 says
to dispatch after pushing, which `AGENTS.md` says cancels one of the two runs.

`TASKS.md` and `DECISIONS.md` lose repeated history, not entries. No decision,
rejected alternative, or piece of evidence is removed.

## Verification

- Both TOML repros rerun against the fixed merges, asserting the output parses
  under `tomllib` and still holds `memories = false`.
- The same commented-header and dotted-key fixtures in `scripts/test-install.sh`
  and `scripts/test-install.ps1`, asserting preservation and a report rather than
  a silent skip.
- A bootstrap test in both, with a real upstream commit, asserting the installed
  clone's revision and working tree are unchanged after a dry run.
- The skill validator exercised with a deliberately malformed skill, asserting a
  nonzero exit rather than the presence of a message.
- `./scripts/validate.sh`, reporting which checks ran. Git Bash cannot create the
  symbolic link its Unix integration test needs, so the full run is WSL; the
  PowerShell checks run from Windows because WSL has neither edition.
- `scripts/test-install.ps1` under both PowerShell editions.
- Codex is not installed here, so `codex execpolicy` cannot re-check the decision
  vocabulary. The change follows the fetched official documentation and the
  version recorded in `review.md`; say so rather than implying a parser run.
- A three-platform CI run, because this changes both installers. Push to be asked
  for.
