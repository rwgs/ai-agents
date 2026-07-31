# AI decisions

Closed decisions that constrain future changes, newest first. Entries are
appended and never rewritten; a reversal is recorded by adding a new entry and
marking the old one superseded.

Record a decision only when it constrains future work and its rationale cannot
be recovered by reading the code. Routine implementation choices belong in the
diff.

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

Status: Accepted.

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
