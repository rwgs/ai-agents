# Skills for Claude and Codex

## Purpose

A skill is one reusable workflow: focused instructions, plus references and
scripts where they earn their place.

Knowledge belongs in a skill when it is:

- reused across repositories
- independent of any one project's requirements
- specific enough that its trigger fires reliably
- too detailed to sit in global or repository instructions

## Discovery locations

This repository authors every skill once, under `.agents/skills/`. The two agents
scan different directories, so the installer links each skill into both:

```text
.agents/skills/<skill-name>/SKILL.md    source of truth in this repository
~/.agents/skills/<skill-name>/SKILL.md  installed for Codex
~/.claude/skills/<skill-name>/SKILL.md  installed for Claude Code
```

Both agents scan repository skill directories from the working directory upward,
Codex under `.agents/skills/` and Claude Code under `.claude/skills/`. The
installer links this repository's skills into the user locations so they are
available in every other repository without per-project setup.

A skill written for one agent works in the other. The front matter below is
understood by both, and in each tool the invocable name comes from the directory
name rather than the `name` field.

## Required layout

```text
.agents/skills/skill-name/
├── SKILL.md
├── agents/
│   └── openai.yaml
├── references/
└── scripts/
```

Only `SKILL.md` is required. It must open with YAML front matter carrying a
`name` matching its directory and a `description` saying when to use the skill.
`./scripts/validate.sh` checks both, and rejects a leftover `[TODO:` marker.

## Authoring rules

- Keep a skill to one workflow.
- Put the trigger terms and the boundaries in the description. It is all either
  agent reads when deciding whether to load the skill.
- Keep descriptions agent-neutral. Both agents select skills from the
  description, so wording such as "Use when Codex is asked to" biases selection
  against the other agent. Name an agent only when the skill genuinely applies
  to just that one, as `show-codex-reset-expiries` does.
- Cross-reference sibling skills whose scope is adjacent, so the boundary is
  explicit in both descriptions.
- Write the steps as imperatives, each with its inputs, outputs, and validation.
- Pull in a reference only where the task needs it.
- Prefer instructions to scripts, unless the automation has to be deterministic.
- Keep a project's requirements in that project's documents, never in a reusable
  skill.
- Use `agents/openai.yaml` only for UI metadata that helps, or for declared
  dependencies.

## Which skills belong in the default set

A skill is installed on every machine when it is reusable across repositories,
used often enough to justify an always-loaded description, and specific enough
that its trigger will not misfire.

A skill tied to one product, one environment, or one kind of project does not
meet that bar. Those live in the `rwgs/ai-skills` pool, described below, and are
drawn into the repositories that use them.

That bar is about the repository a skill is drawn into. A skill about an agent's
own operation is placed by machine reach instead, because it has no repository
dependency at all: pooling it would leave a user-wide answer available only in
the repositories that happened to copy it. `show-codex-reset-expiries` is
installed for that reason despite naming one product, and its description is
gated on the user asking for it, so the trigger cannot misfire.

For a language skill, the test is what the language is used for. Install it when
an agent reaches for that language as a tool in a repository of any kind,
including one containing none of it, which is true of shell and Python. Pool it
when the language is the project's stack and the skill only applies to projects
written in it, which is true of Rust and TypeScript.

A skill that reads as broader than it is fails the bar in a way an absent skill
does not, because it makes a gap look covered. `python-ai` was installed while
covering only Python AI applications, so general Python work matched nothing;
`python-scripting` covers that and `python-ai` moved to the pool.

When a pooled skill holds one rule that matters without the skill loaded, put
that rule in `ai-home/AGENTS.md` rather than keeping the skill installed for it.
Detecting a package manager from its lockfile got there that way.

## Repository skills

Installed into both agents by the installer.

- `adopt-baseline`
- `ai-project-manager`
- `bash-scripting`
- `powershell-scripting`
- `pr-readiness`
- `python-scripting`
- `show-codex-reset-expiries`
- `update-baseline`
- `web-verification`

Run `./scripts/validate.sh` after adding, moving, or changing a skill.
Validation fails when this list and the skill directories drift apart, and
removing a skill also requires rerunning the installer so its links are pruned.

## The optional pool

`rwgs/ai-skills` holds the skills that fail the bar above: `forgejo-maintainer`,
`hugo`, `infrastructure`, `linux-sysadmin`, `mdbook`, `podman-operator`,
`python-ai`, `rust-cli`, `web-development`, and `windows-sysadmin`.

A repository draws one in by copying it to `.agents/skills/<name>` and recording
the pool commit it took in `.agents/baseline.json`, the marker `adopt-baseline`
writes. That is the only copy it makes. Claude Code reaches the skill through the
single ignored `.claude/skills` link that `adopt-baseline` wires, never through a
second copy under `.claude/skills/<name>`.

The commit is the point: an installed skill is symlinked, so a pull updates every
machine at once, while a pool skill is a copy and a copy drifts. Without a
recorded commit there is nothing to compare an adopted copy against, and with two
copies there is no rule saying which one the comparison should use.

Moving a skill in either direction changes the installed set, so it needs the list
above updated, the installer rerun to add or prune links, and a `CHANGELOG.md`
entry.
