# Development workflow

How a change moves through this repository, from installing the conventions to
the commit that closes it. The file roles say where each kind of knowledge
lives, the lifecycle is the order the work happens in, and the security baseline
says which gates apply to a repository rather than which ones exist.

## Project file roles

| File | Purpose |
| --- | --- |
| `AGENTS.md` | Durable conventions, loaded automatically in every session |
| `CLAUDE.md` | An `@AGENTS.md` import, because Claude Code ignores `AGENTS.md` |
| `SPEC.md` | What the project must do, and what counts as done |
| `ROADMAP.md` | Ordered outcomes, with their dependencies, risks, and exit criteria |
| `TASKS.md` | The work in flight, and the validation that closed what is finished |
| `PLAN.md` | How the change in flight is being implemented, and why |
| `DECISIONS.md` | Closed decisions that constrain future changes, and what they rejected |
| `CHANGELOG.md` | What changed for anyone installing this repository |
| `.agents/skills/` | Reusable workflows, installed into both agents' skill locations |
| `docs/` | Reference material, read when linked rather than by default |

## Complete lifecycle

1. Install this repository's global instructions, configuration, rules, and
   reusable skills. Then run the one skill the repository's state calls for, once:
   `$start-repository` for a project that holds no work yet, `$adopt-baseline` to
   bring an existing project onto these conventions, and `$update-baseline`
   afterwards, as often as the baseline changes.
2. Read the real repository first: its branch, worktree, architecture, runtime
   paths, and the validation it already has.
3. Write the durable project conventions and boundaries into `AGENTS.md`.
4. Write observable requirements, non-goals, and acceptance criteria into
   `SPEC.md`.
5. Order the outcomes in `ROADMAP.md`, each with its risks, exit criteria, and
   validation.
6. Cut the current phase into reviewable work in `TASKS.md`.
7. Use `$ai-project-manager` to produce a requirement-linked plan with automated
   and manual validation, and record the chosen approach in `PLAN.md`.
8. Stop for plan approval wherever the user reserved that checkpoint.
9. Implement one approved phase, run the focused checks, and inspect the diff.
10. Run the complete local gate, and update task status only once it passes.
11. Promote what must outlive `PLAN.md`: decisions that constrain future work
    into `DECISIONS.md` with the alternatives they rejected, and verified facts
    into `SPEC.md` or `AGENTS.md`.
12. Use `$pr-readiness` to inspect the final diff and confirm the local gate. This
    repository has one maintainer and no pull requests, so both of the skill's
    reduced paths apply: stop at local readiness, and report the review nobody
    was available to give as a limitation rather than as a gate that passed.
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

Establish the checks that apply to this repository rather than collecting the
ones that exist. Each rule states the capability it needs and the condition that
makes it apply; the table underneath says what provides that capability on each
host. Where a host provides nothing, the answer is to record an accepted
exception, not to configure the other host's product.

- Scan for committed secrets, and block a push that adds one.
- Keep dependencies current for the ecosystems the repository actually declares,
  including the CI definition itself when it pins third-party automation.
- Scan the code for vulnerabilities in the languages the repository actually
  contains. Shell and PowerShell are not languages CodeQL supports, so a
  repository written in those relies on ShellCheck and PSScriptAnalyzer instead.
- Review a dependency change only where pull requests exist for it to gate. It
  does nothing in a flow without one.
- Pin third-party automation to an immutable version, and keep the pins current
  through whichever update path the repository's workflow accepts.
- Validate every change that reaches the default branch, and validate a bot's
  pull request before it merges.
- Document an accepted exception with its reason, its owner, and the date it
  comes up for review again.

| Capability | GitHub | Azure DevOps Services | Azure DevOps Server |
| --- | --- | --- | --- |
| Secret scanning and push protection | Native; free on a public repository, and sold as GitHub Secret Protection on a private one | GitHub Secret Protection for Azure DevOps, a paid add-on | None |
| Dependency updates | Dependabot | No native equivalent. Advanced Security brings Dependabot security updates; routine version bumps need a third-party runner | Self-hosted third-party runner, unverified here |
| Code scanning | CodeQL; free on a public repository, and sold as GitHub Code Security on a private one | GitHub Code Security for Azure DevOps, a paid add-on | None |
| Dependency review gating a pull request | `dependency-review-action` | Advanced Security dependency scanning | None |
| Default-branch enforcement | Rulesets and branch protection | Branch policies: build validation, required reviewers | Branch policies |
| CI on a change | Actions workflow | Pipeline on Microsoft-hosted or self-hosted agents | Pipeline on self-hosted agents only |
| Immutable pin for third-party automation | Action pinned by commit SHA | Task pinned by version; marketplace extensions are versioned | As Services |

Microsoft states that Advanced Security and its standalone products are for
Azure DevOps Services and that there are no current plans to bring them to
Azure DevOps Server, so those `None` entries are the present state rather than
something waiting to be switched on. A repository on an on-premise server meets
the first three rules with whatever its organisation already runs, or records an
accepted exception naming the gap.

Nothing in this table has been verified against a live Azure DevOps
organisation or server. It is compiled from Microsoft's published
documentation, and the first person to use it should expect to correct a row.

Bots may open pull requests even where humans do not: Dependabot has no other
delivery mechanism, and its pull request is a change to review rather than a
gate on the maintainer's own work. Keep the validation workflow's
`pull_request` trigger so those bumps are validated before they are merged.

## Required change evidence

Record the problem, the approach, the decisions that mattered, the automated
checks by name, the manual tests, screenshots for anything visible, the known
limitations, the validation skipped, and the follow-up work. With no pull
request to hold it, this belongs in the commit message, and in `DECISIONS.md`
when it constrains future work.

## Documentation rule

An agent will not find a document by guessing its filename. Reference every
supporting document from `AGENTS.md`, from a skill that selects it, or from the
task prompt. When requirements or architecture change, bring the specification,
roadmap, tasks, and implementation back into agreement in the same pass, rather
than leaving one of them describing the old shape.
