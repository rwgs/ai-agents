# Skills for Claude and Codex

## Purpose

A skill is a reusable workflow with focused instructions, optional references,
and optional scripts.

Use a skill for knowledge that is:

- reused across repositories
- independent of one project's requirements
- specific enough to have a reliable trigger
- too detailed for global or repository instructions

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

Only `SKILL.md` is required. It must start with YAML front matter containing a
clear `name` and `description`.

## Authoring rules

- Keep each skill focused on one workflow.
- Put trigger terms and boundaries in the description.
- Keep descriptions agent-neutral. Both agents select skills from the
  description, so wording such as "Use when Codex is asked to" biases selection
  against the other agent. Name an agent only when the skill genuinely applies
  to just that one, as `show-codex-reset-expiries` does.
- Cross-reference sibling skills whose scope is adjacent, so the boundary is
  explicit in both descriptions.
- Write imperative steps with explicit inputs, outputs, and validation.
- Load references only when the task needs them.
- Prefer instructions over scripts unless deterministic automation is useful.
- Keep project requirements in project documentation, not reusable skills.
- Use `agents/openai.yaml` only for useful UI metadata or dependencies.

## Which skills belong in the default set

A skill is installed on every machine when it is reusable across repositories,
used often enough to justify an always-loaded description, and specific enough
that its trigger will not misfire.

A skill tied to one product, one environment, or one kind of project does not
meet that bar. Keep it with the repositories that use it, as a project-local
skill, rather than installing it on every machine.

## Repository skills

Installed into both agents by the installer.

- `adopt-baseline`
- `ai-project-manager`
- `bash-scripting`
- `powershell-scripting`
- `pr-readiness`
- `python-ai`
- `rust-cli`
- `show-codex-reset-expiries`
- `web-development`

Run `./scripts/validate.sh` after adding, moving, or changing a skill.
Validation fails when this list and the skill directories drift apart, and
removing a skill also requires rerunning the installer so its links are pruned.
