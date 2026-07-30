# ai

Portable Claude Code and Codex configuration, rules, and reusable skills.

Instructions, skills, and the command allowlist are each written once and
installed into whichever locations each agent actually reads.

## Install

Preview and install on Linux or macOS:

```bash
./scripts/install.sh --dry-run
./scripts/install.sh
```

On Windows, run the PowerShell installer from the repository root:

```powershell
.\scripts\install.ps1 -DryRun
.\scripts\install.ps1
```

Restart Codex and Claude Code after installation. Existing managed files are
backed up under `~/.codex/backups/`. Credentials, sessions, history, caches, and
plugins are not changed by default.

The installer manages:

| Source | Codex | Claude Code |
| --- | --- | --- |
| `ai-home/AGENTS.md` | `~/.codex/AGENTS.md` | `~/.claude/CLAUDE.md` |
| `ai-home/codex/` | `~/.codex/` configuration, profiles, and rules | not applicable |
| `ai-home/codex/rules/default.rules` | `~/.codex/rules/` | derived into `~/.claude/settings.json` |
| `.agents/skills/` | `~/.agents/skills/` | `~/.claude/skills/` |

Set `CODEX_HOME` or `CLAUDE_CONFIG_DIR` to install somewhere other than the
defaults.

### Shared and agent-specific configuration

The two agents read different files, so only what is genuinely portable is
shared:

- **Instructions are shared.** `ai-home/AGENTS.md` is linked to both
  `~/.codex/AGENTS.md` and `~/.claude/CLAUDE.md`. Claude Code does not read
  `AGENTS.md`, which is why the link is renamed rather than copied.
- **Skills are shared.** One directory under `.agents/skills/` is linked into
  both agents' skill locations. Claude Code cannot see `.agents/skills/`, so the
  second link is required.
- **The command allowlist has one source.** `ai-home/codex/rules/default.rules`
  is hand-authored for Codex; the installer derives Claude Code's
  `permissions.allow` entries from the same file. Edit that file and rerun the
  installer to change both.
- **Nothing else is shared.** The two `rules/` directories mean unrelated things,
  and the configuration formats have no overlap.

`~/.claude/settings.json` is merged, not replaced. Claude Code writes to that
file itself and it accumulates permissions you approve interactively, so the
installer adds only missing entries, preserves everything else, and backs the
file up before its first write. Rerunning reports `already current` when nothing
would change.

See [docs/AGENT_LAYOUT.md](docs/AGENT_LAYOUT.md) for the complete discovery
tables.

### Trust GitHub projects

Every installation renders `~/.codex/config.toml` with trusted-project entries
for that user's `~/github` directory and every Git worktree found recursively
beneath it. This includes repositories inside organization or grouping
subdirectories.

Codex trust entries match exact project roots rather than directory globs, so
the installer discovers each repository instead of relying on a parent or `*`
entry. Rerun the installer after creating or cloning repositories so new
worktrees are added. Common dependency and build directories are skipped during
discovery.

### Install recommended plugins

[Codex plugin](https://learn.chatgpt.com/docs/plugins) installation is opt-in
because plugins can add instructions, hooks, and connections to external
services. Preview or install the repository's selected plugins on Linux or
macOS with:

```bash
./scripts/install.sh --dry-run --plugins
./scripts/install.sh --plugins
```

On Windows:

```powershell
.\scripts\install.ps1 -DryRun -Plugins
.\scripts\install.ps1 -Plugins
```

The selected plugin IDs live in `codex-plugins.txt`. The initial selection is
`superpowers@openai-curated`. Start a new Codex session after installation so
its skills become available. The managed global instructions tell Codex to
skip the full Superpowers methodology for trivial, low-risk edits.

For GitHub-heavy projects, the broader priority order is:

1. **Superpowers plugin** for planning, TDD, debugging, and delivery workflows.
2. **GitHub plugin** for pull requests, issues, reviews, and repository
   operations.
3. **Context7 MCP server** for current framework and dependency documentation.
4. **Playwright or Chrome DevTools MCP server** for frontend testing and
   browser debugging.
5. **Codex Security plugin** for vulnerability analysis and remediation.
6. **Sentry plugin** for production debugging.

Only the entries in `codex-plugins.txt` are installed by `--plugins`. Context7,
Playwright, and Chrome DevTools are
[MCP servers](https://learn.chatgpt.com/docs/extend/mcp) rather than plugins and
require separate configuration. GitHub, Codex Security, and Sentry remain
opt-in until they are added to the manifest because they can require service
authorization or project-specific setup. Plugin directories do not provide
reliable public installation counts, so the ranking is based on fit for this
workflow rather than unverifiable popularity.

### Install RTK

[RTK](https://github.com/rtk-ai/rtk) is an optional Rust CLI proxy that
compresses verbose command output before it reaches Codex's context window.
Install it directly from GitHub:

```bash
cargo install --git https://github.com/rtk-ai/rtk
```

Do not use `cargo install rtk`. The `rtk` package name on crates.io belongs to
a different project.

Ensure Cargo's binary directory is on `PATH`:

```bash
export PATH="$HOME/.cargo/bin:$PATH"
```

Then verify both the binary and its output-savings command:

```bash
rtk --version
rtk gain
```

The managed `ai-home/AGENTS.md` already instructs both agents to use RTK
selectively for commands whose large or repetitive output benefits from
filtering, so no separate `rtk init` step is required after running this
repository's installer. Short commands and commands that require exact output
remain raw. [docs/RTK.md](docs/RTK.md) holds the full command catalog.

## Use

Start either agent normally to use the default configuration:

```bash
codex
claude
```

Invoke a skill explicitly when needed. Codex uses a `$` prefix and Claude Code
uses a `/` prefix:

```text
$linux-sysadmin diagnose this service failure
/pr-readiness
```

Both agents also select skills automatically based on their descriptions.

## AI development workflow

The reusable workflow separates planning from pull-request readiness:

- `$ai-project-manager` reads or creates `AGENTS.md`, `SPEC.md`, `ROADMAP.md`,
  and `TASKS.md`, records the chosen approach in `PLAN.md`, pauses at
  plan-approval boundaries, and executes one reviewable phase at a time.
- `$pr-readiness` validates the final diff, runs local CodeRabbit review,
  records manual testing, and verifies CI and review state before merge.

Project-document templates live under
`.agents/skills/ai-project-manager/assets/project-docs/`. Adapt them to the
project instead of leaving placeholder requirements.

See [docs/WORKFLOW.md](docs/WORKFLOW.md) for the complete lifecycle.

## Local models

Local model profiles are optional and do not change the default provider.

Ollama:

```bash
ollama pull qwen3-coder
codex --profile ollama
```

llama.cpp:

```bash
llama-server --model /path/to/model.gguf --jinja --port 8080
codex --profile llamacpp
```

Override either profile's model with `--model`:

```bash
codex --profile ollama --model another-model
codex --profile llamacpp --model another-model
```

Local models need reliable structured tool calling for effective Codex use.
The llama.cpp profile expects a Responses-compatible endpoint at
`http://127.0.0.1:8080/v1`.

## Validate

```bash
./scripts/validate.sh
```

The validation includes an isolated Linux or macOS installer integration test.
GitHub Actions also exercises the PowerShell installer on Windows and runs
dependency review for pull requests.

## Repository layout

- `AGENTS.md`: instructions for maintaining this repository
- `CLAUDE.md`: an `@AGENTS.md` import, because Claude Code does not read
  `AGENTS.md`
- `SPEC.md`, `ROADMAP.md`, and `TASKS.md`: requirements, phase order, and
  validated task status
- `PLAN.md`: the approach behind the change currently in flight, replaced when
  the next non-trivial change begins
- `.agents/skills/`: reusable skills installed into both agents
- `codex-plugins.txt`: opt-in Codex plugin selections
- `ai-home/AGENTS.md`: shared global instructions for both agents
- `ai-home/codex/`: Codex configuration, profiles, and command rules
- `docs/`: reference documentation loaded only when explicitly requested
- `scripts/`: installation and validation

See [docs/AGENT_LAYOUT.md](docs/AGENT_LAYOUT.md) for detailed discovery and
configuration behavior.
