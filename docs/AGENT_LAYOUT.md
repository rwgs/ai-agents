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

| Repository path | Installed as | Method on Linux and macOS | Method on Windows |
| --- | --- | --- | --- |
| `ai-home/AGENTS.md` | `~/.codex/AGENTS.md` | symbolic link | copy |
| `ai-home/AGENTS.md` | `~/.claude/CLAUDE.md` | symbolic link | generated `@` import |
| `ai-home/codex/config.toml` | `~/.codex/config.toml` | merged key by key, plus generated trust entries | same |
| `ai-home/rules/default.rules` | `~/.codex/rules/default.rules` | merged rule by rule | same |
| `ai-home/codex/*.config.toml` | `~/.codex/<name>.config.toml` | symbolic link | copy |
| `ai-home/rules/default.rules` | `permissions.allow` in `~/.claude/settings.json` | derived and merged | same |
| `.agents/skills/<name>/` | `~/.agents/skills/<name>/` | symbolic link | junction |
| `.agents/skills/<name>/` | `~/.claude/skills/<name>/` | symbolic link | junction |

Windows differs because a symbolic link there needs Developer Mode or an elevated
shell, and a machine that grants neither could otherwise install nothing. A
junction and an import need no privilege. The two copies are what is left over:
Codex offers no include mechanism for `AGENTS.md`, so editing `ai-home/AGENTS.md`
does not reach Codex on Windows until the installer is run again. The `@` import
and every link propagate an edit immediately, as before.

Each copied or generated file is recorded in `AGENTS_HOME/ai-install-state.json`
with the hash the installer wrote, so a later run rewrites it only while it still
matches that record. A file the machine has changed is preserved and reported
instead, and deleting it hands ownership back.

Each run also prunes stale skill links: an entry in either skills directory that
is a link into this repository's `.agents/skills/` whose source no longer exists
is removed, so deleting a skill or making it optional does not leave a broken
link behind. Real directories, and links pointing anywhere else, are never
touched, and the prune reports what it would remove during a dry run without
removing it.

## Shared files and how ownership is proved

`~/.codex/config.toml`, `~/.codex/rules/default.rules`, and
`~/.claude/settings.json` are **shared**: this repository owns some of their
entries and the agent owns the rest. Codex records interactive approvals in the
rules file and writes marketplaces, plugin enablement, MCP servers, and its own
trust entries into `config.toml`; Claude Code appends approved permissions to
`settings.json`. None of the three is linked or replaced. The installer merges
its own entries and leaves every other byte alone.

Provenance is recorded outside those files, in `~/.agents/ai-install-state.json`
(`AGENTS_HOME`), which lists what the installer wrote and the exact value it
wrote for each entry. That record decides what a later run may do:

- an entry is written only when it is absent, or when its current value is
  byte-identical to the recorded value;
- an entry is withdrawn only when the record shows the installer introduced it
  and it is still byte-identical;
- anything else is preserved and reported, including a file that cannot be
  parsed;
- with no state file nothing is managed, so the run adds what is absent, changes
  nothing that exists, and removes nothing.

An entry that already existed when the installer first merged a file is recorded
as pre-existing and never becomes managed, which is how an independently
approved grant that happens to be spelled like a curated one survives. It is
reported when it leaves the curated set, because nothing in either file format
can distinguish the two. `DECISIONS.md` records why provenance lives outside the
files.

Each merged file is backed up under `~/.codex/backups/` before its first change
in a run, and a rerun that would change nothing reports `already current`.

The Codex config, rule, and Claude permission merges need `python3` or `python`
on Linux and macOS, where they run through `scripts/merge-agent-state.py`. If
neither interpreter is available all three are skipped with a warning and the
links are still installed. The PowerShell installer implements the same merge
natively and needs no extra tooling.

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
rerunning the installer adds it for both agents. Removing a rule withdraws the
Codex rule and both derived Claude entries on the next run, provided the state
file records that this installer added them and they are unchanged. A grant that
was already there before the first install is preserved and reported instead.

This grants Claude Code the same latitude the Codex configuration already
assumes, including system-affecting commands such as `systemctl` and `pkexec`.
Remove a `prefix_rule` line to withdraw a command from both agents.

## GitHub project trust

Codex project trust uses exact absolute project paths. A parent project entry
and wildcard entries do not automatically trust nested repositories. On each
run, the installer adds each searched root plus every Git worktree found
recursively below it. The roots default to the current user's `~/github` and are
set with `AI_TRUST_ROOTS`, colon-separated on Linux and macOS and
semicolon-separated on Windows, because repositories do not all live in one
place. Rerun the installer after adding repositories to refresh those entries.

A trust entry Codex wrote itself is recognised whatever quoting or letter case it
used, so the merge never adds a second table for a project that is already
trusted. An entry the installer added is withdrawn when its worktree is gone from
the searched roots; an entry it did not add is left alone.

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
