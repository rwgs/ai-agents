# Claude and Codex parity

Approach for the change currently in flight. Replaced when the next non-trivial
change begins.

## Problem

The repository served Codex only. The installers linked `codex-home/` into
`~/.codex/` and `.agents/skills/` into `~/.agents/skills/`, and nothing reached
Claude Code.

## Constraints discovered

Verified against the shipped Claude Code binary and the official documentation:

- Claude Code reads `CLAUDE.md`, never `AGENTS.md`.
- Claude Code cannot see `.agents/skills/`; it scans `~/.claude/skills/` and
  `.claude/skills/`.
- `~/.codex/rules/` and `~/.claude/rules/` share a name but hold unrelated
  content, so they must never be shared.
- Permissions have no shared runtime format between the two agents.
- `~/.claude/settings.json` accumulates interactively approved permissions, so it
  must be merged rather than replaced or linked.

## Approach

One hand-authored source per concern, installed into whichever locations each
agent actually reads:

- `ai-home/AGENTS.md` links to `~/.codex/AGENTS.md` and `~/.claude/CLAUDE.md`.
- `.agents/skills/<name>/` links into both agents' skill directories.
- `ai-home/codex/rules/default.rules` stays the only command list; the installer
  derives `Bash(x *)` and `PowerShell(x *)` entries from it for Claude Code.
- The repository-local `CLAUDE.md` is the single line `@AGENTS.md`.

## Trade-offs

- The settings merge needs a JSON library, so it depends on `python3` or
  `python`. It is skipped with a warning rather than failing the installation.
- A `jq` fallback was written and then removed because it could not be tested in
  this environment, and an unverified branch writing to that file was not worth
  the coverage.
- Parity grants Claude Code the latitude the Codex configuration already assumes,
  including `systemctl` and `pkexec`.

## Verification

- `./scripts/validate.sh` on Linux, including the installer integration test.
- A merge into a populated `settings.json` preserves every existing key, entry
  order, and escaping, and a rerun reports `already current`.
- An installation without any Python leaves `settings.json` byte-identical.
- `scripts/test-install.ps1` covers the same behavior on Windows in CI.
