# Host-neutral version control

Approach for the change currently in flight. Replaced when the next non-trivial
change begins, so anything that must outlive it is promoted first: verified
product facts to `SPEC.md`, actionable work to `TASKS.md`, and closed choices to
`DECISIONS.md`.

## Problem

The baseline has to work for a developer whose repositories live in Azure
DevOps, both the hosted service and an on-premise server, as well as GitHub. It
does not, and the reason is not that GitHub support was built deliberately: the
host leaked into places that have nothing to do with hosting.

Seven couplings, each read this session rather than recalled:

- `scripts/validate.sh` requires `.github/dependabot.yml`,
  `.github/workflows/codeql.yml`, and `.github/workflows/validate.yml` by name,
  so the repository's own structural check asserts one host's layout.
- The three-platform gate exists only as GitHub Actions. The gate underneath it
  is `scripts/validate.sh`, `scripts/test-install.sh`, and
  `scripts/test-install.ps1`, which care about nothing but the operating system.
- `.agents/skills/pr-readiness/SKILL.md` runs `gh pr view` and `gh pr checks`,
  and reasons in GitHub's `statusCheckRollup` and thread-resolution model. This
  skill is installed into every repository, so it misfires in exactly the case
  this change is about.
- `ai-home/rules/default.rules` allows `gh` and nothing equivalent, so an agent
  working an Azure DevOps repository is prompted for every host command.
- `docs/WORKFLOW.md` states the security baseline in product names, not
  capabilities: Dependabot, CodeQL, dependency review. An adopting repository on
  another host is told to configure things that do not exist there.
- `scripts/bootstrap.sh` and `scripts/bootstrap.ps1` default to the GitHub clone
  URL. `AI_REPO_URL` already overrides it, and nothing documents what to
  override it with, or that an on-premise server behind an internal certificate
  authority fails the clone until that authority is trusted.
- `SPEC.md` and `ROADMAP.md` state requirements and exit criteria in terms of
  GitHub Actions runs.

The installer itself is clean. `scripts/install.sh`, `scripts/install.ps1`, and
`scripts/merge-agent-state.py` contact no host, and trust discovery finds any
directory containing `.git` under the configurable `AI_TRUST_ROOTS`, so a
worktree cloned from anywhere is trusted the same way.

## Constraints discovered

- Neither an Azure DevOps organisation nor an Azure DevOps Server instance is in
  use. Nothing host-facing can be verified end to end in this change.
- The Azure CLI is installed in neither shell on this machine, so no `az`
  command surface has been read yet. Its `azure-devops` extension exposes
  `az repos pr` without a live organisation, so command shapes are verifiable
  locally even though behavior is not.
- `gh` is installed at `C:\Program Files\GitHub CLI\gh.exe` and unauthenticated,
  with no `GH_TOKEN` or `GITHUB_TOKEN` set, so no CI run can be read from this
  session either.
- Azure DevOps Server has no Microsoft-hosted agent pool. Any pipeline this
  repository ships has to name its pool in a way an on-premise instance can
  replace with a self-hosted one, or it is cloud-only by construction.
- The repository is hosted on GitHub and stays there. The GitHub Actions
  workflows remain the only CI evidence the maintainer can actually obtain.

## Approach

- Record the closed choice first, because every task below follows from it:
  both hosts are supported, GitHub is the verified one, and Azure DevOps
  artifacts ship labelled as unverified rather than being withheld until an
  instance exists. In `DECISIONS.md` as "Both hosts are supported, only GitHub
  is verified".
- Separate the host-neutral core from the host-specific edge rather than adding
  a second host to each GitHub-shaped rule. A rule states the capability it
  needs; a table underneath names the mechanism on each host, including where
  there is none.
- Take the changes that are verifiable here first: the validator's required-file
  list, `docs/WORKFLOW.md`, `README.md`, `AGENTS.md`, and the pipeline
  definition. Each is checked by `./scripts/validate.sh` under WSL and by a
  three-platform GitHub run.
- Take the two that need a command surface read second: the `az` permission rule
  and the `pr-readiness` host table. Both need the Azure CLI and its
  `azure-devops` extension installed locally, because `AGENTS.md` forbids
  writing a recalled command into a file that an agent will then run.
- Leave the trust-root default at `~/github`. It is a path convention, not a
  host dependency, and both installer tests seed it; renaming it would change
  installed behavior on this machine to shed a word.
- Carry the host branch into Phase 6 rather than implementing it now.
  `adopt-baseline` does not propagate CI or dependency-update configuration yet,
  so there is nothing host-coupled there to fix, only a requirement to record
  before that work starts.

## Trade-offs

- Shipping an unverified pipeline is a documented liability. The alternative is
  shipping nothing until an Azure DevOps instance exists, which makes the
  requirement unmet for as long as that takes and loses the design work. It is
  labelled in the file, in `TASKS.md`, and in `CHANGELOG.md`, and its first real
  run is expected to need corrections.
- Parameterising the agent pool makes the cloud case slightly noisier to read in
  exchange for the on-premise case being possible at all. A pipeline hard-coding
  Microsoft-hosted pools cannot run on Azure DevOps Server.
- Stating the security baseline as capabilities rather than product names costs
  a table and makes the GitHub case one row rather than the whole rule. The
  current wording is shorter and tells an adopting repository on another host to
  configure things that do not exist.
- Adding `az` to the curated rules grants a broad allowance, matching the
  existing `gh` entry. Narrowing either one is a separate question and is not
  opened here.

## Verification

- `./scripts/validate.sh` under WSL after each pass, which is the only local
  environment here that can create symbolic links. Report which checks it
  actually performed, since it skips ShellCheck, the Node syntax check, and both
  PowerShell checks where the tools are absent.
- A three-platform GitHub run on `main`, read directly, for the passes that
  touch the validator or the scripts.
- `az repos pr --help` and `az devops --help`, read locally with the
  `azure-devops` extension installed, before any `az` command line is written
  into a rule or a skill.
- The Azure DevOps pipeline gets no verification in this change. That is the
  known gap, and the task carrying it says so rather than claiming a check it
  did not run.
