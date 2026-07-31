# Agent configuration layout

## What each agent loads automatically

Codex and Claude Code discover different files from different directories. The
installer targets both.

| Purpose | Codex | Claude Code |
| --- | --- | --- |
| User instructions | `~/.codex/AGENTS.md` | `~/.claude/CLAUDE.md` |
| Repository instructions | `AGENTS.md` from the repository root to the working directory | `CLAUDE.md`, `.claude/CLAUDE.md`, `CLAUDE.local.md` |
| User configuration | `~/.codex/config.toml` | `~/.claude/settings.json` |
| Repository configuration | `.codex/config.toml` in trusted projects | `.claude/settings.json`, `.claude/settings.local.json` |
| User skills | `~/.agents/skills/` | `~/.claude/skills/` |
| Repository skills | `.agents/skills/` from the working directory to the repository root | `.claude/skills/` from the working directory upward |
| Command permissions | `~/.codex/rules/*.rules` | `permissions.allow` inside `settings.json` |
| Home override | `CODEX_HOME` | `CLAUDE_CONFIG_DIR` |

Neither agent recursively reads arbitrary files under `docs/`. A loaded
instruction file, selected skill, or user prompt must point the agent at the
relevant document.

## Cross-agent differences that matter

**Claude Code does not read `AGENTS.md`.** It reads only `CLAUDE.md`. A
repository that serves both agents keeps its instructions in `AGENTS.md` and adds
a `CLAUDE.md` importing it with a bare `@AGENTS.md` line, which is Anthropic's
documented bridge. This repository does exactly that.

**Claude Code cannot see `.agents/skills/`.** That path is a Codex convention and
is not among the directories Claude Code scans. The installer links every skill
into both `~/.agents/skills/` and `~/.claude/skills/` so one skill directory
serves both agents. `SKILL.md` front matter is compatible as written; the
invocable name comes from the directory name in both tools.

**`rules/` means different things in each agent.** `~/.codex/rules/` holds Codex
execpolicy entries in the `prefix_rule(...)` DSL, while `~/.claude/rules/` holds
Markdown instruction fragments. The names collide but the contents are unrelated,
so these directories are never shared or cross-linked.

**Claude Code writes personal state into the repository; Codex does not.**
Claude Code creates `.claude/settings.local.json` as soon as a permission is
approved for a project, and it records absolute paths. It must be ignored by
Git. Codex keeps project trust in the machine-wide `config.toml`, so nothing
personal lands in `.codex/`. Neither directory should be created up front; add a
file only when a project needs something the machine-wide baseline lacks.

**Permissions have no shared runtime format.** Codex reads its own DSL; Claude
Code reads `permissions.allow` strings inside `settings.json`. There is no file
both can parse, so `ai-home/rules/default.rules` is the single
hand-authored source and the installer derives the Claude form from it.

## Why this repository is not a full home-directory mirror

The active agent home directories mix portable configuration with private and
ephemeral runtime state. Examples include:

- `auth.json` and `.credentials.json`
- installation identifiers
- session transcripts and history
- SQLite state and write-ahead logs
- model and application caches
- downloaded plugins
- shell snapshots

Tracking or replacing those files would expose credentials, create noisy
changes, and make the setup less portable.

This repository manages only:

- shared global instructions
- user configuration defaults
- optional local model profiles
- command permissions
- reusable skills
- opt-in lists of recommended plugin selectors, one per agent

## How the installer applies each file

| Repository path | Installed as | Method |
| --- | --- | --- |
| `ai-home/AGENTS.md` | `~/.codex/AGENTS.md` | symbolic link |
| `ai-home/AGENTS.md` | `~/.claude/CLAUDE.md` | symbolic link |
| `ai-home/codex/config.toml` | `~/.codex/config.toml` | rendered file with trust entries |
| `ai-home/rules/` | `~/.codex/rules/` | symbolic link |
| `ai-home/codex/*.config.toml` | `~/.codex/<name>.config.toml` | symbolic link |
| `ai-home/rules/default.rules` | `permissions.allow` in `~/.claude/settings.json` | derived and merged |
| `.agents/skills/<name>/` | `~/.agents/skills/<name>/` | symbolic link |
| `.agents/skills/<name>/` | `~/.claude/skills/<name>/` | symbolic link |

Each run also prunes stale skill links: an entry in either skills directory that
is a link into this repository's `.agents/skills/` whose source no longer exists
is removed, so deleting a skill or making it optional does not leave a broken
link behind. Real directories, and links pointing anywhere else, are never
touched, and the prune reports what it would remove during a dry run without
removing it.

`~/.codex/config.toml` is rendered rather than linked so the installer can add
machine-specific trust entries.

`~/.claude/settings.json` is **merged rather than linked** because Claude Code
writes to it itself and it accumulates permissions approved interactively. The
installer parses the existing file with a real JSON library, appends only the
derived entries that are not already present, and leaves every other key
untouched. It backs the file up before the first write, and reports
`already current` when a rerun would change nothing.

The merge needs `python3` or `python` on Linux and macOS. If neither is available
the step is skipped with a warning so the rest of the installation still
succeeds. The PowerShell installer uses built-in JSON support and needs no extra
tooling.

## Deriving Claude permissions

Each Codex rule of the form:

```text
prefix_rule(pattern=["cargo"], decision="allow")
```

becomes two Claude entries, because `Bash` and `PowerShell` are separate
permission namespaces and a rule for one does not cover the other:

```json
"Bash(cargo *)",
"PowerShell(cargo *)"
```

The trailing ` *` is the prefix wildcard for command tools, so one entry per
namespace covers the bare command and every argument list. Adding a rule and
rerunning the installer adds it for both agents. Removing a rule does not yet
withdraw the previously derived Claude entry because `settings.json` also holds
independently approved permissions; the state-preserving phase in `TASKS.md`
owns that provenance defect.

This grants Claude Code the same latitude the Codex configuration already
assumes, including system-affecting commands such as `systemctl` and `pkexec`.
Remove a `prefix_rule` line to withdraw a command from both agents.

## GitHub project trust

Codex project trust uses exact absolute project paths. A parent project entry
and wildcard entries do not automatically trust nested repositories. On each
run, the installer adds the current user's `~/github` path plus every Git
worktree found recursively below it to the generated config. Rerun the
installer after adding repositories to refresh those entries.

Claude Code has no equivalent per-project trust list, so this step applies to
Codex only.

## Plugins and MCP servers

Run the installer with `--plugins` on Linux or macOS, or `-Plugins` on Windows,
to install the selectors in `codex-plugins.txt` and `claude-plugins.txt`.
Without that option, plugin state is untouched. Restart the agent or start a new
session after installing a plugin so its bundled skills and tools can load.

Both agents ship the same plugin under different marketplace names, so each has
its own manifest rather than one shared list:

| Agent | Manifest entry | Installer commands |
| --- | --- | --- |
| Codex | `<plugin>@<marketplace>` | `codex plugin add <selector>` |
| Claude Code | `<plugin>@<marketplace> <marketplace git URL>` | `claude plugin marketplace add <url>` then `claude plugin install <selector>` |

The extra field is not redundancy. Codex ships `openai-curated` as a built-in
marketplace and reserves the name, so a selector resolves on its own. Claude
Code reports `No marketplaces configured` until its first interactive start and
adds the official marketplace then, so an installer that runs before that first
launch has to add the source itself. That source is written as a full HTTPS URL
because `owner/repo` shorthand resolves over SSH, which fails on a host with no
GitHub key in `known_hosts`.

Both agents' commands are idempotent. A second `marketplace add` reports the
marketplace is already on disk, and a second `install` reports the plugin is
already installed; neither is an error, so rerunning the installer is safe.

Plugin installation needs the agent's own command-line interface on `PATH`,
which an editor-embedded installation does not necessarily provide. A missing
`codex` or `claude` command skips that agent's plugins with a warning instead of
failing, so one agent's absence cannot block the other's installation.

Plugins can package skills, connectors, MCP servers, hooks, and other assets.
Standalone services such as Context7, Playwright, and Chrome DevTools are MCP
servers, not entries managed by these manifests. Configure those separately when
a project needs them.

## Local model profiles

Codex profile files live directly under `CODEX_HOME` and use the name
`<profile>.config.toml`.

This repository includes:

- `ollama.config.toml` for Codex's built-in Ollama provider.
- `llamacpp.config.toml` for a local llama.cpp Responses API endpoint.

Profiles layer over `config.toml` only when selected with `--profile`, so local
model settings do not affect ordinary Codex sessions. Claude Code has no
equivalent profile mechanism.

## Skill location migration

Older local layouts may place skills under `.codex/skills`. Current Codex
documentation uses `.agents/skills` for user and repository skills. This
repository uses `.agents/skills` as its canonical source and links into the
locations each agent scans.

## Direct home-directory use

Do not point `CODEX_HOME` or `CLAUDE_CONFIG_DIR` at this repository. Both agents
write runtime state into those directories, while this repository intentionally
separates managed files from runtime data. Use `scripts/install.sh` on Linux or
macOS and `scripts/install.ps1` on Windows instead.

## Verification

After installation, restart each agent and ask:

```text
List the instruction sources and relevant skills active for this repository.
```

The expected Codex instruction order is:

1. `~/.codex/AGENTS.md`
2. the repository root `AGENTS.md`
3. any closer nested `AGENTS.md` or `AGENTS.override.md`

The expected Claude Code instruction order is:

1. `~/.claude/CLAUDE.md`
2. the repository root `CLAUDE.md`, which imports `AGENTS.md`
3. any closer nested `CLAUDE.md` or `CLAUDE.local.md`
