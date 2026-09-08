# ai

Portable Claude Code and Codex configuration, rules, and reusable skills.

Instructions, skills, and the command allowlist are each written once and
installed into whichever locations each agent actually reads.

## Install

Preview the change first, then install, on Linux or macOS:

```bash
./scripts/install.sh --dry-run
./scripts/install.sh
```

On Windows the PowerShell installer does the same, run from the repository root:

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

`AI_REPO_URL` also selects a different host entirely. Nothing in the installer
contacts a Git host, so a fork or mirror in Azure DevOps installs the same way:

```bash
# Azure DevOps Services
AI_REPO_URL=https://dev.azure.com/<organization>/<project>/_git/ai ./scripts/bootstrap.sh

# Azure DevOps Server, whose URL carries the collection
AI_REPO_URL=https://<server>/<collection>/<project>/_git/ai ./scripts/bootstrap.sh
```

An on-premise server usually presents a certificate from an internal authority.
Git rejects it until that authority is trusted, and the bootstrap fails at the
clone with a certificate error rather than anything that names the cause. Trust
the authority in the system store, or point Git at its bundle with
`git config --global http.sslCAInfo /path/to/ca.pem`, before running the
bootstrap. Turning verification off is not the fix.

**The clone is not temporary.** The installer links into it, so it is where the
managed instructions, rules, and skills live afterwards; moving or deleting it
breaks every link. It goes to `~/.local/share/ai` on Linux and macOS and
`%USERPROFILE%\Development\ai` on Windows unless `AI_INSTALL_DIR` says otherwise.
Rerunning the bootstrap fast-forwards that clone and installs again, which is
also how you update.

Restart Codex and Claude Code after installation. Existing managed files are
backed up under `~/.codex/backups/`. Credentials, sessions, history, caches, and
plugins are not changed by default.

What the installer manages, and where each piece lands:

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

- **Instructions are shared.** `ai-home/AGENTS.md` reaches both
  `~/.codex/AGENTS.md` and `~/.claude/CLAUDE.md`. Claude Code does not read
  `AGENTS.md`, which is why it is renamed rather than duplicated.
- **Skills are shared.** One directory under `.agents/skills/` is linked into
  both agents' skill locations. Claude Code cannot see `.agents/skills/`, so the
  second link is required.
- **On Windows nothing needs a privilege.** A symbolic link there requires
  Developer Mode or an elevated shell, so the installer uses junctions for the
  skill directories, a generated `@` import for `~/.claude/CLAUDE.md`, and copies
  for `~/.codex/AGENTS.md` and the model profiles. One consequence is worth
  knowing: **on Windows, editing `ai-home/AGENTS.md` does not reach Codex until
  you rerun the installer.** Claude Code resolves its import at session start, so
  it needs no rerun, and neither does any platform where the file is a link.
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

The allowlist is the other half, and it is separate from the sandbox rather than
a refinement of it. Codex's own documentation defines an `allow` decision as
running the command "outside the sandbox without prompting", so every command in
`ai-home/rules/default.rules` is a standing grant of unattended execution with
no workspace boundary. That is the intended posture here, not an oversight: this
baseline is for machines where both agents are meant to work without a prompt
for each step.

Read the list as broader than the commands it names. Codex matches a
`prefix_rule` on its leading tokens, so allowing a command that runs another
command allows whatever it runs. `rtk` is the clearest case, since `rtk` wraps
any command and this repository's instructions route noisy commands through it:
`rtk cargo build` and `rtk git push --force` match the same rule. `xargs` has the
same shape, and `pkexec` runs its argument as root. The same grants reach Claude
Code, derived into `permissions.allow` as `Bash(...)` and `PowerShell(...)`
entries.

Delete a `prefix_rule` line and rerun the installer to withdraw a command from
both agents.

### Trust local Git projects

Every installation adds trusted-project entries to `~/.codex/config.toml` for
each searched root and every Git worktree found recursively beneath it. This
includes repositories inside organization or grouping subdirectories.

Discovery keys on the presence of a `.git` directory, so where a repository was
cloned from makes no difference: a GitHub clone and an Azure DevOps clone under
the same root are trusted alike.

The roots default to that user's `~/github`, which is a path convention rather
than a statement about the host. Set `AI_TRUST_ROOTS` to search somewhere else,
colon-separated on Linux and macOS and semicolon-separated on Windows:

```bash
AI_TRUST_ROOTS="$HOME/github:$HOME/Development" ./scripts/install.sh
```

```powershell
$env:AI_TRUST_ROOTS = "$env:USERPROFILE\github;$env:USERPROFILE\Development"
.\scripts\install.ps1
```

A Codex trust entry names an exact project root and does not accept a directory
glob, which is why the installer walks the tree and writes one entry per
repository rather than a single parent or `*` entry. A project Codex already
trusts is left exactly as Codex wrote it. New worktrees are picked up by
rerunning the installer after creating or cloning them, and the walk skips the
usual dependency and build directories.

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

On a GitHub-heavy project, the wider set worth having, in the order it earns its
place:

1. **Superpowers plugin**, carrying the planning, TDD, debugging, and delivery
   methodology.
2. **GitHub plugin**, for working pull requests, issues, reviews, and the
   repository itself.
3. **Context7 MCP server**, for framework and dependency documentation current
   enough to trust.
4. **Playwright or Chrome DevTools MCP server**, for driving a frontend and
   debugging it in a real browser.
5. **Codex Security plugin**, for finding vulnerabilities and fixing them.
6. **Sentry plugin**, for debugging what production actually did.

`--plugins` installs the two manifests and nothing else from that list.
Context7, Playwright, and Chrome DevTools are
[MCP servers](https://learn.chatgpt.com/docs/extend/mcp) rather than plugins, so
they are configured separately. GitHub, Codex Security, and Sentry stay out of a
manifest until someone adds them, because each can need service authorization or
per-project setup. No plugin directory publishes trustworthy installation
counts, so this order reflects fit for this workflow and not popularity anyone
can check.

### Install RTK

[RTK](https://github.com/rtk-ai/rtk) is an optional Rust CLI proxy. It sits in
front of a noisy command and compresses the output before it reaches the agent's
context window. Install it straight from GitHub:

```bash
cargo install --git https://github.com/rtk-ai/rtk
```

Not `cargo install rtk`: that name on crates.io belongs to an unrelated project.

Cargo's binary directory has to be on `PATH`:

```bash
export PATH="$HOME/.cargo/bin:$PATH"
```

Check both the binary and the command that reports what it saves:

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

Two skills split the work, one deciding what to build and the other deciding
whether it is finished:

- `$ai-project-manager` reads or creates `AGENTS.md`, `SPEC.md`, `ROADMAP.md`,
  and `TASKS.md`, records the chosen approach in `PLAN.md`, pauses at
  plan-approval boundaries, and executes one reviewable phase at a time.
- `$pr-readiness` validates the final diff, records manual testing, and verifies
  CI and review state before merge.

The project-document templates are under
`.agents/skills/ai-project-manager/assets/project-docs/`. Adapt one to the
project it is going into; a placeholder left behind reads as a requirement.

[docs/WORKFLOW.md](docs/WORKFLOW.md) has the complete lifecycle.

## Local models

The local model profiles are optional, and adding them leaves the default
provider alone.

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

Either profile takes a different model through `--model`:

```bash
codex --profile ollama --model another-model
codex --profile llamacpp --model another-model
```

A local model is only useful to Codex if its structured tool calling is
reliable, which is the thing to check before blaming the profile. The llama.cpp
profile expects a Responses-compatible endpoint at `http://127.0.0.1:8080/v1`.

## Validate

```bash
./scripts/validate.sh
```

That run includes an installer integration test, isolated in temporary
directories, on Linux or macOS.
GitHub Actions runs the same validation on Linux and macOS and exercises the
PowerShell installer on Windows under both PowerShell 7 and Windows PowerShell
5.1. A separate CodeQL workflow covers the Python and JavaScript in the
repository; the shell and PowerShell installers are covered by ShellCheck and
PSScriptAnalyzer instead, because CodeQL does not support them. That workflow is
dispatch-only and cannot yet report: code scanning has to be enabled for this
private repository before the upload is accepted, so it builds its databases and
then fails at the end.

## Repository layout

- `AGENTS.md`: how this repository itself is maintained
- `CLAUDE.md`: an `@AGENTS.md` import, because Claude Code does not read
  `AGENTS.md`
- `SPEC.md`, `ROADMAP.md`, and `TASKS.md`: the requirements, the order the
  phases run in, and which tasks have passed their validation
- `PLAN.md`: the approach behind the change currently in flight, replaced when
  the next non-trivial change begins
- `DECISIONS.md`: closed decisions and the alternatives they rejected
- `CHANGELOG.md`: the changes that alter what installation does to a machine;
  repository-internal changes stay in the commit history
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
- `docs/`: reference material, read when something links to it rather than by
  default
- `scripts/`: the installers and the validation

[docs/AGENT_LAYOUT.md](docs/AGENT_LAYOUT.md) covers discovery and configuration
behavior in detail.
