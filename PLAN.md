# Propagate the development infrastructure adoption skips

Approach for the change currently in flight. Replaced when the next non-trivial
change begins, so anything that must outlive it is promoted first: verified
product facts to `SPEC.md`, actionable work to `TASKS.md`, and closed choices to
`DECISIONS.md`.

The update-skill plan this replaces was already promoted. Its decision is in
`DECISIONS.md` as "Updating is a sibling skill, and only a verbatim copy is
refreshed", the marker and the update semantics are in `SPEC.md`, and its
evidence is recorded against the closed task in `TASKS.md`.

## Problem

Adoption reconciles instructions, planning documents, and skills, and stops
there. Three things this repository depends on are never propagated:
`.gitattributes`, the CI definition that validates a change, and the
dependency-update configuration that keeps the CI definition's action pins
current. An adopted repository therefore gets the conventions and none of the
machinery that enforces them.

`.gitattributes` is the one with a failure rather than a gap behind it. Without
it a contributor on Windows commits CRLF, and a Bash script checked out with CRLF
fails with `syntax error near unexpected token`. This repository hit exactly that
in its own checkout, which is why the file exists here at all.

## Constraints discovered

- The CI definition cannot be copied. This repository's
  `.github/workflows/validate.yml` runs `shellcheck scripts/*.sh`,
  `./scripts/validate.sh`, and the PowerShell installer test under both editions.
  Every one of those is a check only this repository has, so a verbatim copy is a
  workflow that fails on its first run in the adopting repository.
- Two of the three artifacts are host-specific, which is why `ROADMAP.md`
  sequences this behind Phase 8. `azure-pipelines.yml` is the Azure DevOps
  counterpart of the workflow, and `docs/WORKFLOW.md`'s table records that Azure
  DevOps has no Dependabot counterpart at all.
- The host cannot always be read from the remote. `github.com`, `dev.azure.com`,
  and `*.visualstudio.com` name a product; an on-premise Azure DevOps Server is
  reached at whatever hostname the organisation gave it, and a repository may
  have no remote yet. A hostname that names no product is a question, not a
  default.
- Dependabot and the `pull_request` trigger stand or fall together. `DECISIONS.md`
  keeps both here under "Bots may open pull requests, humans may not", and the
  reason is one condition: whether the repository accepts a pull request a bot
  opens. A repository that does not wants neither.
- Verified this session in a scratch repository, because the sequence is what the
  skill will tell an agent to run. Adding `.gitattributes` to a repository that
  already has commits changes nothing already committed: `git status` prints
  nothing. `git add --renormalize .` is what stages the conversion, and it touches
  every affected file, so it belongs in a commit of its own. After that commit
  `git ls-files --eol` still reports `w/crlf`, because the working tree keeps its
  old endings until the paths are checked out again, and
  `git rm --cached -r . && git reset --hard` is what refreshes them. Rerunning
  `git add --renormalize .` on a converged tree stages nothing, which is the
  check.
- `update-baseline` deliberately keeps no list of its own, so it reads
  `adopt-baseline` for what is on offer. Adding a section there is enough for the
  update half to offer these three, provided the sentence that enumerates the
  offerable set names the new section.

## Approach

- Add one step to `adopt-baseline`, between the project-scoped configuration step
  and the step that writes the marker, so what it propagates is recorded like
  everything else. Renumber the two steps after it and the three references to
  them.
- Install `.gitattributes` unconditionally, and add only the missing lines where
  the repository already has one. Give the renormalisation its own commit and the
  working-tree refresh after it, both as the verified commands.
- Identify the host from the remote before offering either host-specific
  artifact, and ask rather than infer wherever the hostname names no product.
  Offer neither and record the reason on a host that has no counterpart.
- Derive the CI definition rather than copy it: keep the parts that are baseline
  convention -- the triggers, the least-privilege permission block, the
  concurrency group, actions pinned by commit SHA, the timeout -- and write the
  check steps from the checks the repository actually has. Add no workflow to a
  repository with no check to run, because a green run that runs nothing reports
  success it did not earn.
- Ask once whether the repository accepts pull requests from bots, and let that
  one answer decide both Dependabot and the `pull_request` trigger. Where the
  answer is no, the action pins are maintained by hand, which is an accepted
  exception with a reason, an owner, and a review date rather than an unnamed gap.
- Record all three in the marker, adopted or declined with a reason, and extend
  the marker example so an adopting repository sees the shape.
- Extend `update-baseline` in two places only: the sentence that points at the
  offerable set, so the new section is in scope, and the additive rule, so a
  repository that changed host is reported rather than handed a second CI
  definition.

## Trade-offs

- Deriving the CI definition means the adopting repository's workflow is written
  rather than copied, so two adopting repositories will not get identical files.
  Accepted: the alternative is a workflow whose steps name checks the repository
  does not have.
- No template asset is added for the workflow. A template would be a second copy
  of the shape this repository's own workflow already carries, and the two would
  drift with nothing comparing them, which is the argument this baseline has
  already accepted twice for instructions and for skills.
- Asking two questions during adoption -- the host where it is not readable, and
  bot pull requests -- costs an interactive step in a workflow that otherwise
  reads the repository. Both change what is written, and guessing either wrong
  writes a file that fails or a file nobody wanted.
- `.gitattributes` is installed rather than offered, so a repository that
  deliberately commits CRLF has to remove it afterwards. Accepted on the failure
  behind it, and the file is one line plus per-extension exemptions.
- Nothing here is verified against a real repository. The phase's
  scratch-repository proof is the task that does that, and this is the last piece
  it needs to exist first.

## Verification

- `./scripts/validate.sh` under WSL. It checks both skills' front matter, that
  each `name` matches its directory, that no `[TODO:` marker survives, and that
  the `docs/SKILLS.md` inventory still matches the directories. Report which
  checks the run performed, since it skips ShellCheck, the Node syntax check,
  `codex execpolicy`, and both PowerShell checks where those tools are absent.
- Check that every path the new step names exists in this repository:
  `.gitattributes`, `.github/workflows/validate.yml`, `.github/dependabot.yml`,
  and `azure-pipelines.yml`. A reusable skill naming a path that is not there is a
  defect every adopting repository inherits.
- Re-parse the marker example with `json.loads` after editing it, and check that
  every declined artifact still carries a non-empty reason. A malformed example is
  the one defect no check here would catch and every adopting repository would
  copy.
- Read both skills end to end and confirm every existing rule survives, the
  boundary is still stated in each, and the offerable set is named in one place.
- No three-platform run is requested. The change touches no script, no workflow,
  and no installer behavior; it edits two skill files the installer links
  identically on every platform.
