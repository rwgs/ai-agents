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
- Leave unrelated changes exactly as you found them. Every changed line traces to
  something the request asked for, so raise a simpler approach or an unrelated
  defect rather than acting on it.
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

## Change discipline

- Say what success looks like before editing, as a check that can fail rather
  than a description: the test that reproduces the bug, the test for the input
  that must be rejected, the same tests passing either side of a refactor. Pair
  each step of multi-step work with the check that confirms it, so the loop closes
  without asking.
- Make the smallest change that solves the stated problem. Add no speculative
  feature, abstraction for a single call site, configuration knob, or handling for
  a case that cannot occur, and rewrite your own work before showing it when the
  same result fits in substantially less code.
- Match the naming, layout, and style already in the file, even where a different
  approach would be the better call in a new project.
- Remove what your change orphans, such as an import nothing uses or a helper
  nothing calls. Leave pre-existing dead code alone unless asked to remove it, and
  mention it where it matters.
- Settle an ambiguous request yourself where reading the code or running a command
  answers it, and state the reading taken. Ask where the readings lead to
  materially different work, and name what is unknown rather than filling the gap.

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
