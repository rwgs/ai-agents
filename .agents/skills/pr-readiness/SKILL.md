---
name: pr-readiness
description: Validate local or published changes from final diff through pull-request merge readiness, including project gates, CI, automated and independent review, thread resolution, and manual-test evidence. Use when asked to review uncommitted work, prepare or open a pull request, check whether a PR is ready, address final review feedback, or verify merge readiness.
---

# PR readiness

## Scope

The last pass over a change, from the final diff to a merge-ready pull request.
`ai-project-manager` plans the work and hands it here once it is built; this
skill decides whether it is finished and says so with evidence. It applies to
uncommitted work as much as to a published pull request, and a repository whose
workflow has no pull requests still uses everything up to the point where a
remote is involved.

Two things vary between repositories, independently of each other: whether there
is a pull request, and whether there is anyone but the author to review the
change. Neither changes what is checked. Both change what can be claimed, and an
absent gate is reported as absent rather than quietly passed.

## Workflow

1. Read the repository instructions, the requirements, the accepted plan, and
   the current task status.
2. Inspect the branch, the worktree, untracked files, and the complete diff.
   Separate pre-existing unrelated changes from the requested one.
3. Run the focused checks first, then the repository's full required local gate.
   Record the exact commands, their results, anything skipped, and the risk left
   over.
4. Commit, push, or open a pull request only where the user authorized that state
   change. Keep the pull request in draft while a known gate or a manual test is
   outstanding.
5. On a published pull request, check that the checks and reviews belong to the
   latest commit. Read thread resolution state rather than the flat comment list,
   which shows a reply to a thread nobody resolved as if it were an answer.
6. Fix what CI and review actually found, add regression coverage where it is
   practical, rerun the affected validation, and push again. Where a finding is a
   verified false positive, explain it instead of changing correct code.
7. Establish whether an independent review is required here, and obtain a fresh
   one where it is. The author's own read of the diff and a green CI run are not
   a substitute for it. Where the repository has no second party, take the path
   below instead of skipping the step.
8. Work through the repository's manual-test checklist on the real target
   environment where that is practical, and write down what was run.
9. After every push, recheck the final diff, the required checks, the reviews,
   and the unresolved threads. A push invalidates all four.

## Hard gates

Do not call a pull request ready to merge while any of these holds:

- a required check is failing, pending, missing, or attached to an older commit
- actionable review feedback is unresolved
- a required independent or automated review has not finished
- required manual testing is incomplete or undocumented
- the branch carries unrelated changes, secrets, debug code, or generated junk
- the planning documents no longer describe what was built

Do not merge unless the user asks for the merge itself. Never invent a commit
hash, a review state, a command, or a test result: an unrun check is reported as
unrun. For uncommitted work, report `HEAD` alongside the worktree and
untracked-file state, since `HEAD` alone describes none of what was reviewed.
Where no pull request exists, report the remote checks, reviews, threads, and
pull-request status as not applicable rather than as passing.

## Readiness without an independent reviewer

An independent review is required where the repository asks for one in its
instructions or its recorded decisions, or where its host enforces one over the
changed paths: a required-reviewer branch policy, a ruleset demanding an
approval, or a code-owner rule. Read that before choosing a path. Where nothing
settles it, report the requirement as undetermined and leave the readiness claim
conditional on it, rather than picking the answer that suits the change.

Where the author is the only party, a second look from the same person does not
satisfy the gate and nothing else pretends to. Four things stand in its place:

- the repository's complete required gate, run to completion, reported by the
  exact command rather than by name, with anything skipped named as skipped
- every automated review the repository does have, by name, each confirmed to
  have run against the commit under review: a scanner, a linter, a type checker,
  a CI job
- a separate pass over the whole diff, made after the change is finished rather
  than while writing it, read against the requirements and the plan rather than
  against the intent that produced the code
- the risk left over, named: what this change could break, what is untested, and
  what a reviewer would have been asked to look at hardest

Report the result as local readiness, and report the missing review as a stated
limitation of that claim. Never record an approval, a review state, or a
reviewer that does not exist, and never approve your own change to give the
report the shape of a reviewed one. A gate whose shape survives without its
substance is worse than a missing gate, because it reads like one that held.

## Diagnostics

The worktree half is the same wherever the repository is hosted:

```bash
git status --short --untracked-files=all
git diff                                   # unstaged
git diff --stat origin/main...HEAD         # the branch's scope
```

The published half is host-specific in its commands and not in what it has to
establish. Read the pull request's state, the checks that ran against its head
commit rather than a summary, the reviewer positions, and thread resolution
state rather than the flat comment list.

| Read | GitHub | Azure DevOps |
| --- | --- | --- |
| State, draft, review decision | `gh pr view --json state,isDraft,reviewDecision,statusCheckRollup` | `az repos pr show --id <id>` |
| Checks against the head commit | `gh pr checks`, plus `statusCheckRollup` above | `az repos pr policy list --id <id>` |
| Reviewer positions | `reviewDecision` above | `az repos pr reviewer list --id <id>` |
| Thread resolution | the thread view, never the comment list | the threads endpoint below |

`statusCheckRollup` carries the commit each check ran against; compare it with
the branch head rather than trusting a green summary. Azure DevOps has no
equivalent of `gh pr checks`, because build validation reaches a pull request as
a branch policy: `az repos pr policy list` is where a required check that failed
or never evaluated shows up, and a stale policy evaluation is the same defect as
a GitHub check attached to an older commit.

Comment listings carry no resolution state on either host, and Azure DevOps has
no `az repos pr` subcommand for threads at all. Its REST endpoint is

```text
GET {org}/{project}/_apis/git/repositories/{repositoryId}/pullRequests/{id}/threads?api-version=7.1
```

and a thread is unresolved while its `status` is `active` or `pending`. The
resolved values are `fixed`, `wontFix`, `closed`, and `byDesign`.

The Azure DevOps commands belong to the Azure CLI `azure-devops` extension and
take `--organization`, which is the organisation URL on the hosted service and
the collection URL on an on-premise server. They are transcribed from
Microsoft's CLI and REST reference and have not been run against a live
organisation, so treat an unexpected result as a defect in this table before
treating it as a finding. The GitHub commands are in regular use.

## Pull request evidence

The pull request itself should record:

- the problem and the approach taken
- the decisions made and any deviation from the plan
- the automated checks that ran, by name
- the manual tests and the environment they ran on
- screenshots or recordings for anything visible
- known limitations, skipped validation, and follow-up work

## Final report

Report `HEAD`, the worktree and untracked-file state, the changed-file scope, the
local checks, the manual-test state, which review path applied and on what
evidence, and every remaining blocker. For a published pull request also report
its latest commit, the remote checks, the review state, the unresolved threads,
and whether it is draft, review-ready, or merge-ready.
