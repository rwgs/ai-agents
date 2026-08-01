# AI decisions

Closed decisions that constrain future changes, newest first. Entries are
appended and never rewritten; a reversal is recorded by adding a new entry and
marking the old one superseded.

Record a decision only when it constrains future work and its rationale cannot
be recovered by reading the code. Routine implementation choices belong in the
diff.

## 2026-07-31 Bots may open pull requests, humans may not

Status: Accepted. Supersedes in part "No branches and no pull requests in this
repository" below, which left Dependabot, the `dependency-review` job, and the
pull-request template stranded. The rule for human work is unchanged.

### Decision

Dependabot keeps opening pull requests to bump the pinned actions, and the
`Validate` workflow keeps its `pull_request` trigger so those bumps are checked
before merging. The `dependency-review` job and `.github/pull_request_template.md`
are removed. CodeQL analyses the languages it supports that this repository
actually contains, which is Python and JavaScript.

### Why

The stranded pieces were three different things, and the earlier entry treated
them as one. Dependabot is the only mechanism that notices a pinned action has
moved, and its pull request is a change to review, not a gate on the
maintainer's own work; refusing it would mean either unpinning the actions or
checking them by hand on no trigger. `dependency-review` is a `pull_request`
check whose findings come from dependency manifests, and this repository has
none: nothing here declares a dependency except the action pins Dependabot
already watches. The template describes a review conversation that never
happens.

CodeQL was recommended by `docs/WORKFLOW.md` and configured nowhere. Until this
phase the repository had no language CodeQL supports; the merge program added
one Python file and a skill ships one JavaScript module, so the rule now applies
to something and the workflow follows it.

### Rejected alternatives

- Dropping Dependabot as well: consistent, but nothing would then report that a
  pinned action had gone stale, and the pins are the security control.
- Keeping `dependency-review` for a future manifest: an unreachable job that
  reports success by never running is worse than no job, and it can be added
  back with the manifest that needs it.
- Keeping the pull-request template for Dependabot's pull requests: it asks a
  bot to describe manual testing and independent review.
- Leaving all three to the governance phase: the contradiction was already
  documented twice and cost more to keep explaining than to resolve.

### Consequences

`scripts/validate.sh` no longer requires the template and now requires the
CodeQL workflow. The security baseline in `docs/WORKFLOW.md` states each rule
with the condition that makes it apply, so an adopting repository is not told to
scan languages it does not have or to gate on pull requests it does not open.
Code scanning has to be enabled for a private repository before the CodeQL
workflow can upload results.

## 2026-07-31 Windows PowerShell 5.1 is the supported floor

Status: Accepted.

### Decision

`scripts/install.ps1` and `scripts/test-install.ps1` run under Windows
PowerShell 5.1 and under PowerShell 7. Neither uses a parameter, cmdlet, or
syntax that 5.1 lacks, and CI runs the complete installer integration test under
both editions.

### Why

5.1 is the edition Windows ships. `pwsh` is a separate installation, so the
`.\scripts\install.ps1` line in `README.md` is read by most Windows users as an
instruction for the shell they already have.

Verified on this machine on 2026-07-31: Windows PowerShell 5.1.26100.8875
rejects `ConvertFrom-Json -AsHashtable` outright, and the installer uses it to
merge `settings.json`. CI runs only `pwsh` 7, so the documented Windows install
fails in the default shell while the Windows job stays green.

The compatibility cost is small and bounded. Plain `ConvertFrom-Json` behaves the
same in both editions, returning a `PSCustomObject` that preserves the order of
the keys in the file, which `-AsHashtable` does not. The one real difference is
serialization: 5.1 writes `<`, `>`, `&`, and `'` as six-character Unicode
escapes, where PowerShell 7 writes the characters themselves. Of the 832 approved
entries in the live `settings.json`, 278 contain `'` and 193 contain `&`, so this
is not hypothetical. The merged JSON has to be normalized before it is written,
or changing edition would rewrite characters inside permissions the user
approved. Both editions escape `"` and `\` identically.

Also verified: symbolic-link creation fails identically in both editions on a
machine without Developer Mode or elevation, so this floor neither adds nor
removes the existing prerequisite.

### Rejected alternatives

- PowerShell 7 as the minimum, with a version guard that fails fast: cheaper, one
  Windows CI job, and honest. Rejected because it makes the documented Windows
  install fail in the shell Windows provides, to avoid replacing one cmdlet
  parameter.
- Keeping `-AsHashtable` and warning when it is unavailable: the same failure,
  reached less clearly, and it leaves the merge unperformed on the edition most
  likely to run it.
- Relying on PSScriptAnalyzer's compatibility rules instead of a second CI job:
  they check known cmdlet and syntax surfaces, not whether the installer's own
  merge works. Running the real integration test under 5.1 subsumes them.

### Consequences

The Windows CI job runs the installer test twice, once per edition, and each run
asserts the edition it is on. Any future use of a 7-only feature has to be caught
there, so the test must exercise the populated merge paths rather than only a
clean home. `scripts/validate.sh` keeps analysing the scripts with whichever
`pwsh` is present, because that step checks syntax rather than runtime edition.

The two editions indent JSON differently, so alternating between them rewrites
the whitespace of `settings.json` once per switch and backs the previous file up.
The content is identical, which is what the merge compares.

## 2026-07-31 The portable Codex default asks before acting

Status: Accepted. Resolves the `SPEC.md` question about whether the baseline is
Codex's unrestricted preset.

### Decision

`ai-home/codex/config.toml` sets `sandbox_mode = "workspace-write"` and
`approval_policy = "on-request"`, replacing `danger-full-access` and `never`. It
sets no `[sandbox_workspace_write]` overrides, so Codex's own defaults apply
inside the sandbox and the agent asks when it needs to leave it.

### Why

The reviewed machine has never had either key set: its `~/.codex/config.toml`
carries a model, trust entries, marketplaces, plugins, MCP servers, and a
`[desktop]` block, and no execution posture at all. Codex has therefore been
running on its own defaults there and has recorded 48 interactive approvals.
Installing the previous baseline would have silently replaced that with
unrestricted execution and no prompts, which is the opposite of what a user
installing a "safe baseline" expects, and `SPEC.md` separately requires explicit
authorization for destructive work.

The approval stream is also what this repository's permission model is built on.
`~/.codex/rules/default.rules` accumulates approvals, and the curated file is
derived into Claude Code's allowlist from the same vocabulary. Under
`approval_policy = "never"` Codex never asks, so nothing is ever approved and the
mechanism the baseline documents has nothing to record.

### Rejected alternatives

- Keeping the unrestricted preset and rewriting the documentation to match: it is
  a real posture some users want, but it escalates every machine that installs
  the baseline, and the escalation is invisible afterwards because the keys look
  like ordinary configuration.
- Managing neither key and leaving the posture to each machine: the baseline
  would have no opinion on the one setting that decides what an agent may do
  without asking, and an upstream default change would move every machine with no
  diff here.
- Adding `[sandbox_workspace_write] network_access = true` so package managers
  keep working inside the sandbox: plausible, but unverifiable in this session
  because the Codex CLI is installed nowhere on this machine, and
  `on-request` already lets the agent ask to escalate rather than fail.

### Consequences

A machine that installs the baseline now gets approval prompts where the previous
config would have run everything unattended. That is the intended change.

A machine that installed the previous baseline already has
`approval_policy = "never"` in its rendered `config.toml`. Under the provenance
model no state file records those keys, so the installer will not rewrite them.
It reports them as unmanaged values that differ from the baseline, and the user
decides. This is the general preserve-and-report rule, not an exception to it.

## 2026-07-31 Shared files are merged against a recorded provenance manifest

Status: Accepted. Supersedes in part "Link managed files instead of copying them"
below, which linked the Codex rules directory. The rest of that entry stands.

### Decision

Every managed target belongs to exactly one of three classes.

- Repository-owned: the machine never writes it. The shared instruction file, the
  model profiles, and every skill stay symbolic links, unchanged by this entry.
- Shared: both this repository and the agent write it. `~/.codex/config.toml`,
  `~/.codex/rules/default.rules`, and `~/.claude/settings.json` are never linked
  and never replaced. The installer merges its own entries and leaves every other
  byte of the file as it found it.
- Machine-owned: any entry of a shared file the installer did not write. It is
  never edited, reordered, or removed.

Provenance lives outside the shared files, in one per-machine state file at
`$AGENTS_HOME/ai-install-state.json`, defaulting to
`~/.agents/ai-install-state.json`. For each shared file it records the entries the
installer wrote and the exact value it wrote for each. An entry that already
existed when the installer first merged that file is recorded as pre-existing and
never becomes managed.

One rule governs all three files:

- Write an entry only when it is absent, or when its current value is
  byte-identical to the value the state file says the installer last wrote.
- Withdraw an entry only when the state file records the installer introduced it
  and the entry is still byte-identical to what was written.
- Otherwise preserve the entry and report it, including preserving a whole file
  the installer cannot parse well enough to locate its managed entries in.
- Treat a missing or unreadable state file as "nothing is managed": add what is
  absent, change nothing that exists, remove nothing.

### Why

Verified on this machine on 2026-07-31, against the two files as the agents left
them:

- `~/.codex/rules/default.rules` holds 48 approvals Codex recorded interactively,
  none of them curated, and no comments. The installer links that directory into
  this repository, so after installation every approval Codex records is written
  into this working tree and the machine keeps only the curated file.
- `~/.claude/settings.json` holds 832 allow entries and no duplicates. Thirty-four
  of them are the same `Tool(command *)` shape the installer derives, including
  `Bash(git add *)`, and Codex's own first recorded rule is the single-token
  prefix `["Get-Content"]`, the shape the curated rules use. Neither format has a
  provenance field, and in both of them an agent-written entry can be spelled
  exactly like a managed one, so shape proves nothing.

That leaves an out-of-band record as the only mechanism that fits all three
files, which is why there is one mechanism rather than one per format. JSON
cannot carry a marker comment at all, and whether Codex preserves comments and
block position when it appends an approval could not be verified here, because
the Codex CLI is installed in neither shell on this machine.

Recording provenance when the entry is written separates the two cases that leave
evidence: a grant that pre-existed the first merge is machine-owned, and a grant
the installer introduced and that is still unchanged is installer-owned. One case
leaves no evidence in any format. A user who approves a permission the installer
already granted changes nothing, because the agent sees the grant and never
prompts. That case is treated as installer-owned, so withdrawal costs one
re-approval prompt, reported by name and recoverable from the backup. The
alternative costs revocation itself: a rule deliberately removed from the curated
source would stay granted on every machine that ever installed it.

### Rejected alternatives

- Keeping the rules directory linked: it makes every interactive approval an
  uncommitted change in this repository, and pushing it would install one
  machine's approvals everywhere.
- A marker-delimited managed block inside each file: expressible in TOML and in
  the rules syntax but not in JSON, so Claude Code would need a second mechanism
  anyway, and it assumes an append the agent performs leaves the block intact.
- A file the installer owns outright, so provenance is file-level and no manifest
  is needed: Claude Code's only such location is the enterprise managed-settings
  path, which requires administrator rights that `SPEC.md` forbids depending on.
  Whether Codex loads every `*.rules` file in its rules directory is unverified;
  if it does, the curated rules move into an installer-owned file and their
  provenance becomes file-level. That is a better substrate under this model, not
  a different model.
- Continuing to replace shared files and relying on the timestamped backup:
  backups make replacement recoverable, not state-preserving, and nothing tells
  the user that 48 approvals or an `mcp_servers` block are now only in a backup.
- Replacing `permissions.allow` with the derived set: discards 832 approvals to
  save recording what was written.
- Preserving every stale grant and only ever reporting it: keeps the defect this
  phase exists to fix, because the curated source could grant but never revoke.

### Consequences

`~/.codex/rules` stops being a link and becomes a real directory the installer
merges into. On a machine where the link already exists, the approvals Codex
recorded through it are in this repository's working tree, not in the machine's
own file, so the migration has to report them for review rather than silently
adopt or discard them.

`config.toml` is merged key by key instead of rendered, and generated trust tables
are managed entries keyed by project path, so a trust entry the user added by hand
is never touched.

The state file is a fourth thing installation creates in a managed home. It is
per-machine, must never be tracked here, and its absence is safe by construction.

`SPEC.md` already requires that no grant is deleted unless installer ownership is
provable and that an ambiguous identical grant is reported instead. Under this
entry an ambiguous identical grant is precisely one that pre-existed the first
merge. Both installers, both installer tests, `README.md`, and
`docs/AGENT_LAYOUT.md` change with the implementation; `TASKS.md` carries that
work.

## 2026-07-31 No branches and no pull requests in this repository

Status: Superseded in part by "Bots may open pull requests, humans may not"
above. The rule for human work stands.

### Decision

Work is committed straight to `main`. This repository creates no branches and
opens no pull requests, and an agent must not propose either, including as a way
to obtain review evidence. Evidence that only CI can produce comes from
dispatching the validation workflow and reading the run.

### Why

There is one maintainer. Every gate a pull request exists to enforce -- review by
someone else, conversation resolution, approval before merge -- has no second
party to satisfy it, so requiring one produced ceremony that the same person
performed on both sides.

The rule it replaces asked for a branch and a pull request whenever a change
needed evidence this environment cannot produce. That reason does not survive:
`workflow_dispatch` runs the same three-platform validation on any ref, so the
evidence never depended on a pull request. It was obtained that way once, for the
Windows pruning fix, before this entry was written.

### Rejected alternatives

- Keeping pull requests for installer changes only: installer changes are the most
  common kind of change here, so the exception would be the rule.
- Keeping a branch without a pull request: a branch that is never reviewed and
  always fast-forwarded is a rename of `main` with an extra push and delete.
- Requiring a self-approval to preserve the shape of a review gate: records an
  approval that carries no independent judgment, which is worse than no gate
  because it reads like one.

### Consequences

`AGENTS.md`, `docs/WORKFLOW.md`, `ROADMAP.md`, `SPEC.md`, and `TASKS.md` no longer
describe a merge gate. Two things are left stranded and are recorded as tasks
rather than removed here: the `dependency-review` job, which is gated on
`pull_request` and therefore unreachable, and `.github/pull_request_template.md`,
which is now only a template for a flow nobody uses. The `pr-readiness` skill
stays installed, because it is installed into every repository and has a
documented path for when no pull request exists.

Because a dispatch is manual, a push that silently fails to trigger validation is
now the only way a change reaches `main` unverified. That makes the open question
of why no push has ever triggered a run a correctness issue, not a curiosity.

## 2026-07-31 A language skill is installed when the language is a tool

Status: Accepted. Supersedes "Installed skills cover tooling, not stacks or
domains" below, whose stated principle contradicted the set it produced. The four
placements that entry made stand; its reason for keeping `web-development` does
not, and `web-development` moves to the pool.

### Decision

A language skill is installed when an agent reaches for that language as a tool in
any repository. It goes to the pool when the language is the project's stack.

Installed: `bash-scripting`, `powershell-scripting`, `python-scripting`. Pooled:
`rust-cli`, `web-development`.

### Why

The superseded entry was titled "not stacks or domains" while leaving four stack
skills installed, so it could not be applied to a fifth case without inventing a
reason. It kept `web-development` on reach, two of eight local repositories, which
is a frequency test with no threshold and no stopping rule.

The distinction that actually separates the set is what the language is being used
for. An agent writes shell or Python to get something done in a repository of any
kind, including one that contains neither. It writes TypeScript or Rust only when
the project is written in TypeScript or Rust, which is the definition of the pool.
This also explains why `python-scripting` is installed while `web-development` is
not, which the superseded entry made look arbitrary.

`web-development` held one rule worth having without the skill loaded: detect the
package manager from the lockfile, because running the wrong one rewrites it. That
is a destructive-mistake rule, one sentence long, and it now sits in
`ai-home/AGENTS.md` beside the existing destructive-operations rule. It applies
without a `.js` or `.ts` trigger, which also covers a repository carrying a
lockfile for tooling without being a JS/TS project.

### Rejected alternatives

- Keeping the reach test and recording a threshold: any threshold is arbitrary,
  and reach changes as repositories come and go, so the set would need revisiting
  on no principled trigger.
- Moving `bash-scripting` and `powershell-scripting` out for consistency with a
  literal no-stacks rule: it is the rule that was wrong, not those placements.
  This baseline's own installers are Bash and PowerShell, and both are reached for
  in repositories that contain neither.
- Leaving the whole skill installed for the sake of the lockfile rule: a skill
  loaded on a stack trigger to deliver one always-relevant sentence, which is what
  the global instruction file is for.

### Consequences

The installed set is eight: three workflow skills, three tool-language skills,
`web-verification`, and `show-codex-reset-expiries`. A new language skill is
placed by asking whether an agent reaches for the language or works in it, so the
question has an answer before the skill is written.

## 2026-07-31 The optional skill pool is its own repository

Status: Accepted. Resolves the open question left by "Which skills are installed
on every machine" below.

### Decision

The optional skill pool is a separate private repository, `rwgs/ai-skills`. A
repository that wants one of its skills copies it in and records the pool commit
it took.

### Why

An installed skill needs no update mechanism: the installer symlinks
`.agents/skills/<name>` into `~/.agents/skills/` and `~/.claude/skills/`, so a
pull in this repository updates every machine and every project at once. A pool
skill is different only because it is drawn into a repository, which means a
copy, and a copy drifts.

Detecting that drift requires a version identity to record. The repository
boundary is not what makes updating easier; the commit is. A pool with no commit
to pin gives the planned `adopt-baseline` update mode nothing to compare an
adopted copy against, so drift could never be reported for skills even once it is
reported for documents.

### Rejected alternatives

- The unversioned directory the skills were actually in,
  `~/OneDrive/Development/ai/skills-optional/`: it has no version identity to
  record, so drift is uncomputable by construction, and OneDrive syncing a `.git`
  directory is a known source of repository corruption.
- A branch of this repository: already rejected below, and unchanged by this
  entry.
- Reintroducing `skills-optional/` here: also already rejected below. A second
  tree, a second documented list, and a duplicate check still cost more than they
  give.

### Consequences

`forgejo-maintainer`, `hugo`, `infrastructure`, `linux-sysadmin`, `mdbook`,
`podman-operator`, and `windows-sysadmin` move out of OneDrive into the pool
repository, joined by `python-ai` and `rust-cli`. The `adopt-baseline` update mode
must read a recorded pool commit as well as a recorded baseline commit.

## 2026-07-31 Installed skills cover tooling, not stacks or domains

Status: Accepted. Applies the bar set by "Which skills are installed on every
machine" below to the four skills that were left undecided.

### Decision

- `python-ai` and `rust-cli` move to the pool. Both are scoped to one stack, and
  `python-ai` further to one domain.
- `python-scripting` joins the installed set, alongside `bash-scripting` and
  `powershell-scripting`.
- `web-development` splits. Its stack-agnostic browser and local-server rules
  become `web-verification`, installed; the JS/TS tooling keeps the
  `web-development` name and stays installed.

### Why

`python-ai` reads as a Python skill and is not one. Every section of it is
AI-specific, and its only generally useful content is four diagnostic commands.
General Python was therefore uncovered while appearing covered, which is worse
than an absence: an agent reaching for Python as a tool in a repository that is
not a Python project matched nothing.

The split follows the same reasoning in the other direction. Serving over HTTP
rather than `file://`, not orphaning a server that holds the port, and a service
worker returning stale assets after a change are true of any web application
whatever its backend, but they were reachable only behind a `.js`/`.ts` trigger.
Two of eight local repositories have a `package.json` while more than two are
browser-facing. The extracted skill also gives the visual-verification rule in
`AGENTS.md` a skill to stand on, which it did not have.

### Rejected alternatives

- Keeping `python-ai` installed to cover general Python work: it does not cover
  it, so this trades a real gap for the appearance of coverage.
- Leaving `web-development` whole: one description line instead of two, but the
  browser rules stay locked behind a stack trigger that most browser-facing
  repositories here do not fire.
- Moving `web-development` to the pool as well: its tooling half is still wanted
  wherever JS/TS exists, and with the browser rules extracted the two halves have
  different reach. Revisit once the split has been used.

### Consequences

The installed set stays at nine skills. Removing a skill requires rerunning the
installer so its links are pruned, and `docs/SKILLS.md` must match the
directories or validation fails.

## 2026-07-31 The line-ending check exempts by extension

Status: Accepted. Promoted from `PLAN.md` when that file was replaced.

### Decision

`scripts/validate.sh` fails when `git grep` finds a carriage return in any
tracked file except `*.ps1`, named as a literal path exclusion rather than read
from each file's `eol` attribute.

### Why

The check exists to catch any carriage return, and `git ls-files --eol` reports a
file holding a lone CR as `-text` rather than `crlf`, so it answers which line
ending a file uses and not whether it holds a carriage return.

One extension is exempt today. Reading the `eol` attribute instead would make the
check agree with `.gitattributes` automatically, which sounds like an improvement
and is the failure mode: a future `eol=crlf` entry would then be exempted
silently, with no diff showing that the check stopped covering something.

### Rejected alternatives

- `git ls-files --eol`: purpose-built for line endings, but classifies a lone CR
  as binary.
- Deriving the exemption from `.gitattributes`: removes the coupling at the cost
  of removing the review step that coupling forces.

### Consequences

Adding an `eol=crlf` entry to `.gitattributes` requires adding the same path to
the exclusion in `scripts/validate.sh`. Neither file references the other, so the
pairing lives here.

## 2026-07-31 Let the plugin manifests carry comments

Status: Accepted. Supersedes in part "One plugin manifest per agent" below, which
recorded that the manifests reject comment lines. The rest of that entry stands.

### Decision

`codex-plugins.txt` and `claude-plugins.txt` ignore blank lines and lines whose
first non-blank character is `#`. Every reader applies that one rule: both
installers, `scripts/validate.sh`, and both installer tests. Comments are
whole-line only.

### Why

The two formats differ by one field, and the reason for the difference lived in
`README.md` and in duplicated installer comments, so neither file could state its
own format. Rejecting every non-entry line was justified earlier by a stray field
caught during testing, but that argues for validating entries, not for refusing
the only place a format can be explained where it is used.

### Rejected alternatives

- Trailing comments after an entry: every reader would have to strip a comment
  before parsing, and a Claude Code entry already carries two fields, to save one
  line in a file with one entry.
- Explaining both formats only in `README.md`: the previous state, which put the
  explanation three files away from what it explains and let the manifests drift
  from it silently.

### Consequences

A reader added later must skip these lines or it will treat a comment as a plugin
selector. A format change now updates the manifest it changes as well as
`README.md`.

## 2026-07-31 Keep the shared permission source outside `ai-home/codex/`

Status: Accepted.

### Decision

`default.rules` lives at `ai-home/rules/default.rules`. `ai-home/` holds what
both agents depend on; `ai-home/codex/` holds only Codex-specific files. There
is no `ai-home/claude/`.

### Why

The rule file is the single hand-authored source for both permission systems,
but it sat under `ai-home/codex/` because the installer links that whole
directory into `~/.codex/rules`. Location implied ownership, so a shared
artifact read as Codex-only. Moving it costs one path in each installer and
leaves the link behavior identical.

The missing `ai-home/claude/` is not an omission to fill. Claude Code's
`settings.json` accumulates interactively approved permissions, so the installer
renders and merges it rather than linking a repository file. There is nothing
portable to put in such a directory, and `AGENTS.md` previously implied
otherwise.

### Rejected alternatives

- Leaving the file under `ai-home/codex/` and explaining the placement in
  `SPEC.md`: documentation compensating for a layout that contradicts itself.
- Creating an empty `ai-home/claude/` for symmetry: symmetry the installer does
  not implement, which would invite files that cannot work.

### Consequences

`ai-home/` is now read as the shared root rather than a container of per-agent
directories. Anything added there is a claim that both agents depend on it.

## 2026-07-31 Add CHANGELOG.md for consumer-visible changes

Status: Accepted. Supersedes in part the entry below that rejected
`CHANGELOG.md`.

### Decision

`CHANGELOG.md` is added to this repository and to the `ai-project-manager`
templates, created when a project has consumers who install or upgrade it
independently of its source. It is not part of the planning set: it records what
changed for consumers, where `DECISIONS.md` records why for maintainers.

### Why

The earlier entry rejected `CHANGELOG.md` as user-facing release notes belonging
to projects that ship versioned releases. That reasoning did not survive contact
with this repository, which ships no releases and still needs one: installing
mutates the user's home directory by linking instructions and skills, merging
`settings.json`, and adding trust entries. Someone who installed weeks ago and
pulls has a real question that the commit history answers badly, namely whether
to rerun the installer and what it will change.

### Rejected alternatives

- Generated release notes from merged pull requests: reads from a pull-request
  flow this repository does not use, since changes are committed to `main`.
- One entry per commit: reproduces the commit history in a second place and goes
  stale, which misreports what shipped. Entries are limited to changes a
  consumer would act on.

### Consequences

The templates now carry seven files rather than six, and `CHANGELOG.md` is the
only one whose audience is not the coding agent. It is created conditionally, so
a project with no separate consumers is not forced to carry an empty file.

## 2026-07-31 Close the planning document set at six files

Status: Superseded in part by the `CHANGELOG.md` entry above. The rest stands.

### Decision

The planning set is `AGENTS.md`, `SPEC.md`, `ROADMAP.md`, `TASKS.md`, `PLAN.md`,
and this file, in this repository and in the `ai-project-manager` templates. No
further top-level planning document is added without retiring one.

### Why

Every added document costs a routing entry in `AGENTS.md`, a row in the
`docs/WORKFLOW.md` role table, and an entry in the `scripts/validate.sh`
required-file list. `docs/WORKFLOW.md` also states that a coding agent must not
be relied on to discover a document by filename, so an unrouted document is
inert. Two documents that answer the same question drift, and the agent then has
to reconcile them on every task.

### Rejected alternatives

- `CONSTITUTION.md`, `CONVENTIONS.md`: both name what `AGENTS.md` already holds
  in Operating principles and Working boundaries. `AGENTS.md` loads
  automatically in both agents; neither of these would.
- `MEMORY.md`: the context it would preserve is already split between the
  `PLAN.md` "Constraints discovered" section for the change in flight and
  promotion into `SPEC.md`, `AGENTS.md`, or this file for anything durable. A
  repository copy also competes with Claude Code's own memory store and is
  invisible to Codex.
- `DESIGN.md`: overlaps the `SPEC.md` architecture section and the `PLAN.md`
  approach section, leaving three places that could own an architecture change.
- `DEPLOYMENT.md`: installation is specified in `SPEC.md` and detailed in
  `docs/AGENT_LAYOUT.md`. A project with a genuine runbook puts it in `docs/` and
  routes it from `AGENTS.md`.
- `TODO.md`: `TASKS.md` owns actionable work, and a second task list guarantees
  the drift the `ai-project-manager` safety rules already forbid ignoring.
- `CHANGELOG.md`: a record of what changed for users, generated from merged pull
  requests, rather than agent context. Not excluded from projects that ship
  versioned releases, but not part of this planning set.

### Consequences

A new planning need is met by extending an existing document. Proposals to add
these files should be answered from this entry rather than re-argued.

## 2026-07-31 Record closed decisions outside PLAN.md

Status: Accepted.

### Decision

Decisions that constrain future work are promoted out of `PLAN.md` into this
file when a phase completes, and verified facts that change how the project is
understood are promoted into `AGENTS.md` or `SPEC.md`.

### Why

`PLAN.md` asks for rejected alternatives and abandoned approaches "so they are
not retried", then declares itself replaced when the next non-trivial change
begins. Without promotion, every plan destroys the one thing it promises to
preserve. Recording the shared instruction link in the `SPEC.md` "Unresolved
questions" section was the same gap showing up in a different place: a closed
decision parked wherever there was room.

### Rejected alternatives

- Numbered ADR files under `docs/decisions/`: the conventional form, but
  file-per-decision ceremony does not match a flat six-file planning set, and
  the `ai-project-manager` discovery step looks for planning documents at the
  repository root first.
- Keeping rationale in `SPEC.md` only: `SPEC.md` states the architecture that
  was chosen, not the options that were eliminated, so a rejected approach stays
  available to be re-proposed.

### Consequences

`ai-project-manager` gained a promotion step, a safety rule against re-proposing
a rejected approach, and a validation item. `PLAN.md` is safe to overwrite once
promotion has run, and unsafe to overwrite before.

## 2026-07-30 Install only the skills that earn a place on every machine

Status: Accepted.

### Decision

A skill is installed on every machine when it is reusable across repositories,
used often enough to justify an always-loaded description, and specific enough
that its trigger will not misfire. A skill tied to one product, one environment,
or one kind of project stays with the repositories that use it.

### Why

Every installed skill costs a description line that is always in context and a
trigger that can misfire into the wrong project. The body loads only when the
skill fires, so the cost of an unused skill is small but not zero, and it scales
with the size of the set.

The test is not whether a skill applies to every project in the abstract, which
no stack-specific skill ever will. It is whether the skill is wanted in the
repositories actually worked in, without per-repository setup.

### Rejected alternatives

- A branch holding the optional skills: it would diverge from the default set,
  and it would have to be checked out just to see what is available.
- A `skills-optional/` tree inside this repository: used briefly, then dropped
  once its contents moved out, because a second tree, a second documented list,
  and a duplicate check across both cost more than they gave for an empty
  directory. Reintroducing it is a small change if the need returns.

### Consequences

`forgejo-maintainer`, `hugo`, and `mdbook` live outside this repository. The
installed set is the set that meets the bar, and anything else is drawn in per
repository. Where the optional pool lives and how a repository draws from it are
still open; see `TASKS.md`.

## 2026-07-30 One plugin manifest per agent

Status: Superseded in part by the comment-support entry above. The rest stands.

### Decision

`codex-plugins.txt` and `claude-plugins.txt` are separate files.
`codex-plugins.txt` holds `<plugin>@<marketplace>`; `claude-plugins.txt` holds
`<plugin>@<marketplace> <marketplace git URL>` because Claude Code registers no
marketplace until first interactive use and the installer must add it first.

### Why

The two agents publish the same upstream plugin under different marketplaces,
so there is no shared selector to factor out. The formats differ by one required
field, and per-agent files keep both installers free of a parsing layer that
Bash and PowerShell would each have to implement.

### Rejected alternatives

- A single manifest with an agent column: adds a parsing layer to both
  installers to express a difference that is one field wide.
- Failing the run when an agent's command is missing: replaced by skipping that
  agent's plugins with a warning, so a machine without Codex can still install
  the Claude Code side.

### Consequences

Both installers, the validator, and both installer tests read these files, so a
format change touches four readers. The manifests currently reject comment
lines, which strict validation justified by catching a stray field during
testing; `TASKS.md` plans to revisit that specific point, which requires a
superseding entry rather than an edit here.

## 2026-07-30 Share one instruction file between both agents

Status: Accepted.

### Decision

`ai-home/AGENTS.md` is the single global instruction file. The installer links
it to `~/.codex/AGENTS.md` and to `~/.claude/CLAUDE.md`, and the
repository-local `CLAUDE.md` is a one-line `@AGENTS.md` import.

### Why

Claude Code does not read `AGENTS.md`, so the alternative to linking is a second
copy of the same instructions. Two copies drift, and the drift is silent because
each agent only ever loads one of them.

### Rejected alternatives

- Separate per-agent instruction files: doubles the edit surface for every
  instruction change and produces agents that behave differently for no stated
  reason.
- Generating `CLAUDE.md` from `AGENTS.md` at install time: a generated copy is
  still a copy, and it goes stale in the repository between installs.

### Consequences

Instructions that apply to every repository go in `ai-home/AGENTS.md` and reach
both agents. `scripts/validate.sh` enforces that the repository-local
`CLAUDE.md` stays a bare `@AGENTS.md` import, so instructions cannot accumulate
there where Codex would never see them.

## 2026-06-21 Link managed files instead of copying them

Status: Superseded in part by "Shared files are merged against a recorded
provenance manifest" above, which stops linking the Codex rules directory because
Codex writes interactive approvals into it. The rest stands.

### Decision

Files this repository fully owns are installed as symbolic links: the shared
instruction file, the rules directory, the model profiles, and every skill.
Files the machine partly owns are not linked. `config.toml` is rendered because
it carries machine-specific trust entries, and Claude Code's `settings.json` is
merged because it accumulates interactively approved permissions.

### Why

An edit to a linked file takes effect in both agents immediately. A copy has to
be reinstalled after every edit, and until that happens both agents run stale
instructions with no signal that they are stale.

A copy can also be edited in place and diverge silently, which would end this
repository's claim to be the source of truth. The same argument already forces
the repository-local `CLAUDE.md` to be a bare import rather than a second copy
of the instructions.

Pruning depends on links as well: the installer removes a stale skill by
recognising an entry as a link into this repository's `.agents/skills/`. With
copies there is no way to distinguish an obsolete managed copy from a file the
user wrote, so removing a skill from the default set could not be made safe.

### Rejected alternatives

- Copying everything: loses immediate propagation, silent-drift detection, and
  safe pruning, in exchange for avoiding one platform requirement.
- Copying only where symbolic links are unavailable: trades a loud one-time
  setup failure for a quiet recurring correctness problem, because an edit would
  stop propagating with no error. A fallback would have to report which files
  are links and which are copies for drift to stay visible.

### Consequences

Installation requires an environment that can create symbolic links. On Windows
that means Developer Mode or an elevated shell, which is why the installer
integration tests cannot pass under Git Bash without it. Moving or deleting this
repository breaks every managed link, which is intended: the links are what make
the repository authoritative.
