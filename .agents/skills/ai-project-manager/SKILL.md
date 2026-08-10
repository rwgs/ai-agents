---
name: ai-project-manager
description: Turn repository planning docs into actionable AI-agent implementation plans using AGENTS.md, SPEC.md, ROADMAP.md, TASKS.md, DECISIONS.md, approval checkpoints, validation, and incremental execution. Use when asked to plan a project, create or reconcile project docs, derive tasks, coordinate phases, update task status, record why an approach was chosen or rejected, or manage an AI-assisted development workflow.
---

# ai-project-manager

## Scope

Planning work against a repository's own documents and executing it one
authorized phase at a time. This skill decides what to build next and records
why; `pr-readiness` decides whether what was built is finished. Hand over at
that boundary rather than duplicating either side of it.

## Workflow

1. Read the repository's instructions, whatever is already changed in the
   working tree, and the active branch.
2. Work out which planning documents the task actually touches. Look for each
   `SPEC.md`, `ROADMAP.md`, `TASKS.md`, `PLAN.md`, and `DECISIONS.md` at the
   repository root first, then under `docs/`, and for a `CHANGELOG.md` where the
   project keeps one. Where both locations hold a relevant copy, read both and
   report the conflict rather than picking one. An existing `PLAN.md` is the plan
   this task is about to replace, so read it before overwriting it.
3. Identify the missing requirements, unresolved decisions, dependencies, risks,
   and implementation impact.
4. Build a phase plan that maps onto the acceptance criteria and states its
   automated validation, manual validation, rollback, and pause points. Record
   the chosen approach, the alternatives rejected, and the verification in
   `PLAN.md`, so it survives the conversation and appears in review.
5. Present the plan and stop where the user asked for planning only, or reserved
   approval for implementation.
6. Once implementation is authorized, execute one reviewable phase at a time.
7. Validate the phase, inspect the diff, summarize the evidence, and update task
   status only once the exit criteria pass.
8. Promote whatever must outlive `PLAN.md` before the next change replaces it:
   decisions that constrain future work into `DECISIONS.md` together with the
   alternatives they rejected, and verified facts that change how the project is
   understood into `AGENTS.md` or `SPEC.md`. Create `DECISIONS.md` only when a
   decision meets that bar. Record consumer-visible changes in `CHANGELOG.md`
   where the project keeps one.
9. Hand the finished implementation to a pull-request readiness workflow when the
   user asks to prepare, review, publish, or merge it.

## Diagnostics

```bash
git status --short
git branch --show-current
rg --files -g 'AGENTS.md' -g 'AGENTS.override.md' -g 'SPEC.md' -g 'ROADMAP.md' \
  -g 'TASKS.md' -g 'PLAN.md' -g 'DECISIONS.md' -g 'CHANGELOG.md'
```

Read every applicable `AGENTS.md` and each planning document the task touches.
Do not assume the planning files live under `docs/`; the search above is what
settles where they are.

When the user asks for missing planning files, adapt the templates under
`assets/project-docs/` to this repository. Cut the sections it does not have
rather than leaving placeholders behind or inventing requirements to fill them.
The `-template` suffix marks the file as a template and is not part of the name
it lands under: `SPEC-template.md` becomes the repository's `SPEC.md`.

## Safety rules

- Never rewrite project requirements unless asked to.
- Never mark a task done without validation, or without stating why validation
  was skipped.
- Never leave a conflict between the specification, roadmap, tasks, and code
  unreported.
- Never repropose an approach `DECISIONS.md` rejected without saying what
  changed.
- Never cross a user approval or a plan-only checkpoint.
- Never treat an agent's own account of its implementation as validation
  evidence.
- Keep project-specific knowledge in the project's documents, not in a reusable
  skill.
- Prefer small reviewable phases to a broad plan.

## Validation

- The plan maps onto documented requirements.
- Each task has a clear scope and acceptance criteria.
- Automated and manual validation are defined before implementation starts.
- Completed work updates task status where that applies.
- Decisions that constrain future work are recorded before `PLAN.md` is
  replaced.
- The final diff contains only the intended phase.
- The final summary lists the changed files, the checks run, the checks skipped,
  and the residual risk.
