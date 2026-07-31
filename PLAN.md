# A line-ending check and comments in the plugin manifests

Approach for the change currently in flight. Replaced when the next non-trivial
change begins, so anything that must outlive this change is promoted first:
decisions that constrain future work to `DECISIONS.md`, and verified facts that
change how the project is understood to `AGENTS.md` or `SPEC.md`.

## Problem

Two gaps in the same phase, both about a file that cannot describe itself:

- `.gitattributes` declares the line ending every tracked file should have, and
  nothing checks that a checkout matches it. The last drift surfaced part-way
  through an unrelated change, when `scripts/validate.sh` could not run from WSL
  because the whole tree carried CRLF.
- `codex-plugins.txt` and `claude-plugins.txt` reject every line that is not a
  plugin entry, so neither file can say why a Claude Code entry carries a
  marketplace URL and a Codex entry does not. That reason lives in `README.md`
  and in duplicated installer comments, away from the format it explains.

## Constraints discovered

- Git Bash's Bash drops a `$'\r'` word: the pattern reaches the command empty,
  and an empty pattern matches every line of every file, so the check reported
  every tracked file rather than none. `"$(printf '\r')"` survives, and the
  difference is invisible until something is expected to match. Git Bash's grep
  also strips CR before matching, which `git grep` avoids by reading
  working-tree bytes itself.
- `git ls-files --eol` reports a file holding a lone CR as `-text` rather than
  `crlf`, so it answers which line ending a file uses and not whether it holds a
  carriage return.
- Five readers parse the manifests: both installers, the validator, and both
  installer tests. Each test derives its expected calls from the real manifest,
  so a comment in the file is only covered when the installer and the test skip
  it independently.
- `./scripts/validate.sh` passes in full under WSL, including the installer
  integration test. Git Bash's `ln -s` copies instead of linking, which is why
  the same run fails on Windows.

## Approach

- Add a git-guarded check to `scripts/validate.sh` that fails when `git grep`
  finds a carriage return in a tracked file, excluding `*.ps1`, which
  `.gitattributes` checks out as CRLF on purpose.
- Define one ignore rule for both manifests: a line is ignored when it is empty,
  whitespace only, or its first non-blank character is `#`. Express it as a
  single pattern per reader, in `grep -Ev`, `awk`, `[[ =~ ]]`, and `-match`.
- Move the format explanation into each manifest, leaving `README.md` as the
  place that compares the two agents.

## Trade-offs

- `git grep` rather than `git ls-files --eol`: the eol report is purpose-built
  but classifies a lone CR as binary, and this check exists to catch any
  carriage return.
- The exemption is by extension rather than by reading each file's `eol`
  attribute from Git. One extension is exempt today, and reading the attribute
  would let a future `eol=crlf` entry pass unnoticed.
- Comments are whole-line only. A trailing comment would have to be stripped
  before the Claude Code marketplace URL is parsed, in every reader, to save one
  line in a two-line file.

## Verification

- `./scripts/validate.sh` under WSL, which exercises the new check, both
  manifest readers, and the installer integration test that needs symbolic
  links.
- A temporary CRLF file staged in the index, under WSL and under Git Bash, to
  confirm the check names that file and only that file rather than passing
  quietly or failing everything.
- `scripts/install.ps1 -DryRun -Plugins` for the PowerShell manifest reader,
  since `scripts/test-install.ps1` cannot run on a machine without symbolic-link
  permission. CI covers the rest of that test.
