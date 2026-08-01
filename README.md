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

### Install on a machine with no clone

`scripts/bootstrap.sh` and `scripts/bootstrap.ps1` clone this repository and then
run the installer from the clone. Fetch and run one of them directly:

```bash
curl -fsSL https://raw.githubusercontent.com/rwgs/ai/main/scripts/bootstrap.sh | bash -s -- --dry-run
```

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/rwgs/ai/main/scripts/bootstrap.ps1))) -DryRun
```

While the repository is private, both the fetch and the clone need a token with
read access:

```bash
export AI_GIT_TOKEN=...
curl -fsSL -H "Authorization: Bearer $AI_GIT_TOKEN" \
  https://raw.githubusercontent.com/rwgs/ai/main/scripts/bootstrap.sh | bash
```

```powershell
$env:AI_GIT_TOKEN = '...'
$headers = @{ Authorization = "Bearer $env:AI_GIT_TOKEN" }
& ([scriptblock]::Create((irm -Headers $headers https://raw.githubusercontent.com/rwgs/ai/main/scripts/bootstrap.ps1)))
```

The token is passed to `git` per command and never written into the clone's
remote URL. Set `AI_REPO_URL` to an SSH remote instead to use an existing key.

**The clone is not temporary.** The installer links into it, so it is where the
managed instructions, rules, and skills live afterwards; moving or deleting it
breaks every link. It goes to `~/.local/share/ai` on Linux and macOS and
`%USERPROFILE%\Development\ai` on Windows unless `AI_INSTALL_DIR` says otherwise.
Rerunning the bootstrap fast-forwards that clone and installs again, which is
also how you update.

Restart Codex and Claude Code after installation. Existing managed files are
backed up under `~/.codex/backups/`. Credentials, sessions, history, caches, and
plugins are not changed by default.

The installer manages:

| Source | Codex | Claude Code |
| --- | --- | --- |
| `ai-home/AGENTS.md` | `~/.codex/AGENTS.md` | `~/.claude/CLAUDE.md` |
| `ai-home/codex/config.toml` | merged into `~/.codex/config.toml` | not applicable |
| `ai-home/codex/*.config.toml` | `~/.codex/` model profiles | not applicable |
| `ai-home/rules/default.rules` | merged into `~/.codex/rules/default.rules` | derived into `~/.claude/settings.json` |
| `.agents/skills/` | `~/.agents/skills/` | `~/.claude/skills/` |

The three merged files are the ones the agents write to themselves, so they are
never replaced: the installer adds its own entries and leaves everything else
alone. It records what it wrote in `~/.agents/ai-install-state.json` and uses
that record to decide what it may change or withdraw later. See
[docs/AGENT_LAYOUT.md](docs/AGENT_LAYOUT.md#shared-files-and-how-ownership-is-proved)
for the exact rules.

On Linux and macOS those merges run through `scripts/merge-agent-state.py` and
need `python3` or `python`. Without one, the merges are skipped with a warning
and the links are still installed. The PowerShell installer needs no extra
tooling.

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
- **The command allowlist has one source.** `ai-home/rules/default.rules`
  is hand-authored for Codex; the installer merges it into the machine's own
  rule file and derives Claude Code's `permissions.allow` entries from it. Edit
  that file and rerun the installer to add entries to both. Removing a rule
  withdraws the entries the installer added and left unchanged, and preserves
  and reports anything that was already approved before the first install.
- **Nothing else is shared.** The two `rules/` directories mean unrelated things,
  and the configuration formats have no overlap.

`~/.codex/config.toml`, `~/.codex/rules/default.rules`, and
`~/.claude/settings.json` are merged, not replaced. Each agent writes to its own
file: Codex records the approvals you grant interactively and its marketplaces,
plugins, MCP servers, and trust entries, and Claude Code appends approved
permissions. The installer adds only what is missing, preserves everything else,
backs each file up before its first write, and reports `already current` when a
rerun would change nothing.

See [docs/AGENT_LAYOUT.md](docs/AGENT_LAYOUT.md) for the complete discovery
tables.

### Codex execution posture

`ai-home/codex/config.toml` sets `sandbox_mode = "workspace-write"` and
`approval_policy = "on-request"`. Codex works inside the project directory and
asks before acting outside it, which is also what fills
`~/.codex/rules/default.rules` with the approvals this repository's allowlist is
written in terms of. The baseline deliberately does not ship Codex's
unrestricted `danger-full-access` and `never` pair; choose that per machine if
you want it.

### Trust GitHub projects

Every installation adds trusted-project entries to `~/.codex/config.toml` for
each searched root and every Git worktree found recursively beneath it. This
includes repositories inside organization or grouping subdirectories.

The roots default to that user's `~/github`. Set `AI_TRUST_ROOTS` to search
somewhere else, colon-separated on Linux and macOS and semicolon-separated on
Windows:

```bash
AI_TRUST_ROOTS="$HOME/github:$HOME/Development" ./scripts/install.sh
```

```powershell
$env:AI_TRUST_ROOTS = "$env:USERPROFILE\github;$env:USERPROFILE\Development"
.\scripts\install.ps1
```

Codex trust entries match exact project roots rather than directory globs, so
the installer discovers each repository instead of relying on a parent or `*`
entry. A project Codex already trusts is left as Codex wrote it. Rerun the
installer after creating or cloning repositories so new worktrees are added.
Common dependency and build directories are skipped during discovery.

### Install recommended plugins

Plugin installation is opt-in because plugins can add instructions, hooks, and
connections to external services. Preview or install the repository's selected
[Codex](https://learn.chatgpt.com/docs/plugins) and
[Claude Code](https://code.claude.com/docs/en/discover-plugins) plugins on Linux
or macOS with:

```bash
./scripts/install.sh --dry-run --plugins
./scripts/install.sh --plugins
```

On Windows:

```powershell
.\scripts\install.ps1 -DryRun -Plugins
.\scripts\install.ps1 -Plugins
```

Each agent has its own manifest, because the two publish the same plugin through
different marketplaces. The initial selection is Superpowers for both:

| Agent | Manifest | Entry |
| --- | --- | --- |
| Codex | `codex-plugins.txt` | `superpowers@openai-curated` |
| Claude Code | `claude-plugins.txt` | `superpowers@claude-plugins-official` and its marketplace URL |

A Codex entry is the selector on its own, because `openai-curated` is one of
Codex's built-in marketplaces and its name is reserved. A Claude Code entry also
carries the marketplace source: Claude Code registers no marketplace until its
first interactive start, so an installer that runs before that has to add it.
The source is written as a full HTTPS URL because `owner/repo` shorthand
resolves over SSH. Every command involved is idempotent, so rerunning the
installer re-clones and reinstalls nothing.

Both manifests ignore blank lines and lines whose first non-blank character is
`#`, so each file records its own format.

Only the agents actually present are touched. A missing `codex` or `claude`
command skips that agent's plugins with a warning rather than failing the run,
so a machine with one agent installed still gets a complete installation.

Start a new session in each agent after installation so the plugin's skills
become available. The managed global instructions tell both agents to skip the
full Superpowers methodology for trivial, low-risk edits.

For GitHub-heavy projects, the broader priority order is:

1. **Superpowers plugin** for planning, TDD, debugging, and delivery workflows.
2. **GitHub plugin** for pull requests, issues, reviews, and repository
   operations.
3. **Context7 MCP server** for current framework and dependency documentation.
4. **Playwright or Chrome DevTools MCP server** for frontend testing and
   browser debugging.
5. **Codex Security plugin** for vulnerability analysis and remediation.
6. **Sentry plugin** for production debugging.

Only the entries in the two manifests are installed by `--plugins`. Context7,
Playwright, and Chrome DevTools are
[MCP servers](https://learn.chatgpt.com/docs/extend/mcp) rather than plugins and
require separate configuration. GitHub, Codex Security, and Sentry remain
opt-in until they are added to a manifest because they can require service
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
$bash-scripting harden this deployment script
/pr-readiness
```

Both agents also select skills automatically based on their descriptions.

## AI development workflow

The reusable workflow separates planning from pull-request readiness:

- `$ai-project-manager` reads or creates `AGENTS.md`, `SPEC.md`, `ROADMAP.md`,
  and `TASKS.md`, records the chosen approach in `PLAN.md`, pauses at
  plan-approval boundaries, and executes one reviewable phase at a time.
- `$pr-readiness` validates the final diff, records manual testing, and verifies
  CI and review state before merge.

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
GitHub Actions runs the same validation on Linux and macOS and exercises the
PowerShell installer on Windows under both PowerShell 7 and Windows PowerShell
5.1. A separate CodeQL workflow analyses the Python and JavaScript in the
repository; the shell and PowerShell installers are covered by ShellCheck and
PSScriptAnalyzer instead, because CodeQL does not support them.

## Repository layout

- `AGENTS.md`: instructions for maintaining this repository
- `CLAUDE.md`: an `@AGENTS.md` import, because Claude Code does not read
  `AGENTS.md`
- `SPEC.md`, `ROADMAP.md`, and `TASKS.md`: requirements, phase order, and
  validated task status
- `PLAN.md`: the approach behind the change currently in flight, replaced when
  the next non-trivial change begins
- `DECISIONS.md`: closed decisions and the alternatives they rejected
- `.agents/skills/`: reusable skills installed into both agents. Skills tied to
  one stack, product, or environment live in the separate `rwgs/ai-skills` pool
  and are drawn into the repositories that need them
- `codex-plugins.txt` and `claude-plugins.txt`: opt-in plugin selections, one
  manifest per agent
- `ai-home/AGENTS.md`: shared global instructions for both agents
- `ai-home/rules/default.rules`: the command allowlist both agents derive from
- `ai-home/codex/`: Codex configuration and local model profiles
- `scripts/merge-agent-state.py`: the shell installer's merge into the files the
  agents also write
- `scripts/bootstrap.sh` and `scripts/bootstrap.ps1`: clone this repository on a
  machine that has no copy of it, then install from that clone
- `docs/`: reference documentation loaded only when explicitly requested
- `scripts/`: installation and validation

See [docs/AGENT_LAYOUT.md](docs/AGENT_LAYOUT.md) for detailed discovery and
configuration behavior.
