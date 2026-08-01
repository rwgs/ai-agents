# AI development workflow

## Project file roles

| File | Purpose |
| --- | --- |
| `AGENTS.md` | Durable instructions the coding agent loads automatically |
| `CLAUDE.md` | An `@AGENTS.md` import, because Claude Code ignores `AGENTS.md` |
| `SPEC.md` | Product and technical requirements and acceptance criteria |
| `ROADMAP.md` | Ordered outcomes, dependencies, risks, and exit criteria |
| `TASKS.md` | Current actionable work and validated status |
| `PLAN.md` | How the change in flight is being implemented, and why |
| `DECISIONS.md` | Closed decisions that constrain future changes, and what they rejected |
| `CHANGELOG.md` | What changed for anyone installing this repository |
| `.agents/skills/` | Reusable workflows, installed into both agents' skill locations |
| `docs/` | Reference material loaded only when requested or linked |

## Complete lifecycle

1. Install this repository's global instructions, configuration, rules, and
   reusable skills. Use `$adopt-baseline` once per repository to standardise an
   existing project on these conventions.
2. Inspect the real repository, branch, worktree, architecture, runtime paths,
   and existing validation.
3. Put durable project conventions and boundaries in `AGENTS.md`.
4. Define observable requirements, non-goals, and acceptance criteria in
   `SPEC.md`.
5. Order outcomes, risks, exit criteria, and validation in `ROADMAP.md`.
6. Break the current phase into reviewable work in `TASKS.md`.
7. Use `$ai-project-manager` to produce a requirement-linked plan with automated
   and manual validation, and record the chosen approach in `PLAN.md`.
8. Stop for plan approval when the user reserved that checkpoint.
9. Implement one approved phase, run focused checks, and inspect the diff.
10. Run the complete local gate and update task status only after it passes.
11. Promote what must outlive `PLAN.md`: decisions that constrain future work
    into `DECISIONS.md` with the alternatives they rejected, and verified facts
    into `SPEC.md` or `AGENTS.md`.
12. Use `$pr-readiness` to inspect the final diff and confirm the local gate. This
    repository has one maintainer, so use the skill's no-pull-request path and
    stop at local readiness.
13. Fix actionable findings, rerun validation, and repeat until clean or every
    remaining item has a documented reason.
14. Commit the focused change to `main` once its verification passes. Neither a
    branch nor a pull request is part of this flow.
15. When a change needs evidence only CI can produce, ask to push, then dispatch
    the validation workflow and read the run. Apply the same security checks that
    the security baseline below establishes for the repository.
16. Fix or explain every finding and repeat the checks after every push.
17. Complete and document required manual testing on the real target
    environment.

## Security baseline

Establish the security checks that apply to the repository instead of adding
irrelevant gates. Each rule carries the condition that makes it apply:

- Enable secret scanning and push protection wherever the host offers them.
- Configure Dependabot for the package ecosystems the repository actually has,
  including GitHub Actions when any workflow pins an action.
- Configure CodeQL for the languages it supports that the repository actually
  contains. Shell and PowerShell are not among them, so a repository written in
  those relies on ShellCheck and PSScriptAnalyzer instead.
- Run dependency review only where pull requests exist for it to gate. It is a
  `pull_request` check and does nothing in a flow without one.
- Pin third-party actions by commit and keep the pins current through whichever
  update path the repository's workflow accepts.
- Document accepted exceptions with a reason, owner, and review date.

Bots may open pull requests even where humans do not: Dependabot has no other
delivery mechanism, and its pull request is a change to review rather than a
gate on the maintainer's own work. Keep the validation workflow's
`pull_request` trigger so those bumps are validated before they are merged.

## Required change evidence

Record the problem, approach, important decisions, exact automated checks,
manual tests, screenshots for visible changes, limitations, skipped validation,
and follow-up work. With no pull request to hold it, this belongs in the commit
message, and in `DECISIONS.md` when it constrains future work.

## Documentation rule

Do not rely on a coding agent discovering arbitrary documents by filename.
Reference supporting documents from `AGENTS.md`, a selected skill, or the task
prompt. Keep the specification, roadmap, tasks, and implementation synchronized
when requirements or architecture change.
