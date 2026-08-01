# Global agent instructions

Installed as `~/.codex/AGENTS.md` for Codex and `~/.claude/CLAUDE.md` for Claude
Code. One file, two link targets: keep it agent-neutral.

## Command execution

- Route a command through `rtk` when its output is long or repetitive and a
  summary answers the question: test suites, builds, linters, logs, wide
  searches, dependency listings, infrastructure status.
- Run it raw when the output is short, when the exact bytes matter, or when
  looking at one file or one narrow result.
- In a chain, wrap only the noisy segment.
- Drop back to raw whenever RTK hides something needed, refuses a flag, or gets
  in the way of a diagnosis. `rtk proxy` is not a box to tick.
- Shell and command-line work is the exception that proves the rule: filter
  noisy validation, but keep stdout, stderr, exit status, quoting, and pipeline
  behavior raw, because those are the thing under test.

Common wrappers:

```bash
rtk cargo build | rtk cargo test | rtk cargo clippy   # Rust
rtk tsc | rtk lint | rtk vitest | rtk jest            # TypeScript
rtk pytest | rtk go test                              # Python, Go
rtk git status | rtk git log | rtk git diff           # Git
rtk grep <pattern> | rtk find <pattern> | rtk ls      # Search
rtk gh pr checks | rtk gh run list                    # GitHub
rtk err <cmd> | rtk summary <cmd>                     # Any noisy command
```

Git passthrough covers every subcommand. Run `rtk --help` for the full catalog.

## Working style

- Stick to plain ASCII punctuation unless the file format demands otherwise.
- Read the repository's own instructions, and whatever is already changed in the
  working tree, before editing anything.
- Leave unrelated changes exactly as you found them.
- Keep a change small enough to review in one sitting, and validate it.
- Never print credentials, tokens, private keys, or the contents of secret
  files.
- Destructive work needs to be asked for. Deleting, overwriting, resetting, and
  force-pushing are not implied by a request to fix something.
- Detect a project's package manager from its lockfile before installing
  anything. Running the wrong one rewrites the lockfile: `package-lock.json`
  means npm, `pnpm-lock.yaml` pnpm, `yarn.lock` Yarn, `bun.lockb` Bun,
  `uv.lock` uv, and `poetry.lock` Poetry.
- Work alone unless subagents, delegation, or parallel agents were asked for,
  either by the user or by an `AGENTS.md` or skill that applies.
- With the Superpowers plugin installed, reach for its full methodology on
  features, debugging, planning, and review, and skip it for small low-risk
  edits.
- A stop point the user names is a hard boundary. Finish that milestone, then
  wait to be told to continue.

## Scope selection

- Use `AGENTS.md` for durable repository conventions. Claude Code does not read
  `AGENTS.md`, so a repository that supports both agents needs a `CLAUDE.md`
  containing an `@AGENTS.md` import on a line of its own.
- Use `.codex/config.toml` for trusted project-specific Codex settings, and
  `.claude/settings.json` for project-specific Claude Code settings.
- Use skills for reusable task workflows. Codex loads them from
  `.agents/skills/`; Claude Code loads them from `.claude/skills/`.
- Anything under `docs/` is reference material. Read it when a task or an
  instruction points at it, not by default.
