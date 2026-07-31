# Plugin parity for both agents

Approach for the change currently in flight. Replaced when the next non-trivial
change begins.

## Problem

`--plugins` installed Codex plugins only. Claude Code got the shared
instructions, skills, and permissions, but none of the workflow plugins, so a
new machine came up with Superpowers available in one agent and missing in the
other.

## Constraints discovered

Verified by running both installed command-line interfaces rather than reading
about them:

- `codex plugin add <plugin>@<marketplace>` is the non-interactive install.
  `codex plugin marketplace list` shows `openai-curated` already configured, and
  its name is reserved, so a Codex selector needs no registration step.
- `claude plugin install <plugin>@<marketplace>` is the equivalent, but
  `claude plugin marketplace list` reports `No marketplaces configured` on a
  machine that has never started Claude Code interactively. The install fails
  until the marketplace is added.
- `claude plugin marketplace add anthropics/claude-plugins-official` resolves the
  shorthand over SSH and fails without a GitHub host key. The full HTTPS URL
  works.
- Both agents' add and install commands are idempotent and exit zero on a repeat.
- Superpowers is published as `superpowers@openai-curated` for Codex and
  `superpowers@claude-plugins-official` for Claude Code, from the same upstream
  project.

## Approach

One manifest per agent, because the selectors genuinely differ and there is
nothing to share:

- `codex-plugins.txt` holds `<plugin>@<marketplace>`.
- `claude-plugins.txt` holds `<plugin>@<marketplace> <marketplace git URL>`; the
  installer adds the marketplace before installing from it.
- A missing agent command skips that agent's plugins with a warning rather than
  failing, replacing the previous hard error when Codex was absent.

## Trade-offs

- Two manifests rather than one file with an agent column. The formats differ by
  one required field, and per-agent files keep both installers free of a parsing
  layer neither language shares.
- The manifests reject comment lines. Strict validation caught a stray field
  during testing, and the format is documented next to the commands that read
  it.
- The missing-agent scenario is skipped, not asserted, where the agent under
  test is actually installed, so the suite never claims coverage the environment
  cannot produce.

## Verification

- `./scripts/validate.sh` on Linux, including the installer integration test.
- Seven negative tests confirm each new validation guard fails on the drift it
  is meant to catch.
- `claude plugin install superpowers@claude-plugins-official` run against an
  isolated `CLAUDE_CONFIG_DIR` installs version 6.2.0 and reports
  `already installed` on a rerun.
- Both installers' dry runs print the full command sequence and create nothing.
