# AI decisions

Closed decisions that constrain future changes, newest first. Entries are
appended and never rewritten; a reversal is recorded by adding a new entry and
marking the old one superseded.

Record a decision only when it constrains future work and its rationale cannot
be recovered by reading the code. Routine implementation choices belong in the
diff.

## 2026-08-10 An ambiguity stops the work and is named for review

Status: Accepted. Replaces the `AGENTS.md` operating principle that an ambiguous
request is settled by the agent and asked about only where the readings lead to
materially different work, which had stood since that file was written.

### Decision

An ambiguity in what is being asked for stops the work before anything is edited.
What is unclear and the readings it admits are named, and the answer is waited
for. No reading is picked silently, and the likeliest reading is not a licence to
proceed.

An unread fact is not an ambiguity. A question about how the code behaves, what a
command outputs, or which path exists is answered by reading or running it, and
that route is unchanged.

The rule lands in all three instruction files: this repository's `AGENTS.md`,
`ai-home/AGENTS.md` for every repository on the machine, and the
`ai-project-manager` `AGENTS.md` template for every repository adopted from here.

### Why

The maintainer's call, taken when the three candidate rules were put side by side
with the wording each would produce. It prices a round trip as cheaper than work
built on a reading nobody confirmed, which is the trade the superseded rule made
in the other direction.

The distinction that keeps the rule from stalling everything is between an
ambiguous request and an unknown fact. Only the first stops the work; the second
was never a question for the user, and this repository already requires it to be
read or run rather than recalled.

### Rejected alternatives

- Keep the superseded rule and add only the requirement to name the readings
  found: fewest interruptions, and it leaves the agent deciding which ambiguities
  are material, which is the judgment being taken away from it.
- Proceed on the likeliest reading every time and list every ambiguity in the
  summary for review after the fact: no round trips at all, and review then
  happens over work that may already have to be discarded.

### Consequences

Expect more questions on small work. That is the cost being accepted, not a
defect to tune away later.

Each agent's own default guidance points the other way: Claude Code's harness
reserves blocking questions for cases where proceeding would be unsafe or make
the work useless. The repository and global instruction files override it, and an
agent that has been told to settle ambiguity itself by its own defaults is
following this rule instead.

## 2026-08-10 The Codex reset-expiry skill is removed, not pooled

Status: Accepted. Supersedes in part "A skill about the agent's own operation is
installed, not pooled" below, which rejected dropping this skill. The placement
clause that entry added stands.

### Decision

`show-codex-reset-expiries` is deleted, along with its `openai.yaml` and its
`show-reset-expiries.mjs`. It is not moved to `rwgs/ai-skills`. The installed set
is nine, so the installer has to be rerun to prune its two links per machine.

The machine-reach clause stays in `docs/SKILLS.md` with the example removed: a
skill about an agent's own operation is still installed rather than pooled.

### Why

The check is no longer wanted. The earlier entry rejected dropping the skill
because it was the only thing here that reads the reset-credit expiries, which is
an argument against pooling or duplicating a wanted check, not against retiring
one.

### Rejected alternatives

- Move it to the pool: the pool exists for skills a repository draws in, and this
  one has no repository dependency, so a pooled copy would sit unused in whichever
  repository copied it. Its content is in this repository's history if it is ever
  wanted again.
- Keep it installed because its trigger is harmless: an always-loaded description
  is a cost even when it never fires, and the reason for keeping it was that the
  answer was wanted.

### Consequences

Nothing installed is placed by the machine-reach clause now, so the next candidate
is placed by reading the rule rather than by comparing itself to a sibling.
Neither agent can report reset-credit expiries any more; nothing else here reads
`rateLimitResetCredits`.

## 2026-08-06 Windows installs without a privilege, by method per target

Status: Accepted. Removes the blocker Phase 4's last item has carried since
2026-08-02. Supersedes in part "Files this repository fully owns are installed as
symbolic links" below, which required a link on every platform; it stands
unchanged for Linux and macOS.

### Decision

The Windows installer creates nothing that needs Developer Mode or elevation. The
method is chosen by what the target is, not by what the machine allows, so one
install produces one result on every Windows machine:

- A managed directory becomes a junction. The 20 skill links are all of them.
- `~/.claude/CLAUDE.md` becomes a real file holding one `@` import of
  `ai-home/AGENTS.md`, by absolute path with forward slashes.
- `~/.codex/AGENTS.md` and the two `*.config.toml` model profiles are copied.

A copied or generated file is machine-writable where a link was not, so each is
recorded in the install state file and governed by the provenance model already
in force for `config.toml`, the Codex rules, and `settings.json`: rewritten only
when absent or byte-identical to what the installer recorded writing, otherwise
preserved and reported.

`scripts/install.sh` is unchanged. Symbolic links need no privilege on Linux or
macOS, and the platforms that work are not made worse to match the one that did
not.

### Why

The blocker was recorded as a property of this machine for four days. It is a
property of the installer, and a baseline meant to be portable cannot require a
privilege that a locked-down Windows machine will never grant.

How much of the install actually needed it had never been measured. Of 24 links,
20 are skill directories, and junctions cover every one of them without a
privilege. Both PowerShell editions report a junction as `LinkType` `Junction`
with a resolved `Target`, which is what the installer's idempotency and pruning
checks already read, so those widen rather than change shape.

Claude Code's documentation prescribes the import for exactly this case: "On
Windows, creating a symlink requires Administrator privileges or Developer Mode,
so use the `@AGENTS.md` import instead." It is also better than a link, because
the import resolves at session start and cannot go stale.

Codex has no equivalent. It offers no include mechanism for `AGENTS.md`, and
`model_instructions_file`, the key that looks like the answer, is documented as a
"Replacement for built-in instructions instead of `AGENTS.md`", so using it would
discard Codex's built-in instructions rather than point at a shared file.

### Rejected alternatives

Hard links. They create unprivileged and would have needed no state records, but
they are orphaned by an ordinary `git` update: tested on 2026-08-06, after `git
checkout` of the source the source read `version one` while the link still read
`version two`. Codex would silently read stale instructions after every `git
pull`, which is worse than not installing.

A symbolic link first, falling back when it is refused. It makes the installed
result depend on machine state, doubles what the tests must cover, and leaves two
shapes in the field for every later run to recognise.

Junctions only, leaving the four files to need the privilege. It fixes 20 of 24
links and still refuses to complete on a machine without Developer Mode, which is
the entire failure being removed.

Requiring one elevated run. It is the cheapest fix for this machine and no fix at
all for the baseline, which is the thing being installed.

The superseded entry rejected "copying only where symbolic links are unavailable"
because a fallback "would have to report which files are links and which are
copies for drift to stay visible". That objection is answered rather than
overruled: there is no fallback, so the shape is fixed per platform and known
before the run; the state file records every written file; and each run reports
what it wrote, refreshed, or preserved. Its other two arguments for links are
untouched, because both concern the skills, which stay links: pruning still
recognises a managed entry by its link target, and the instruction file that most
needs immediate propagation is the one that now uses an import, which propagates
immediately for the same reason a link does.

### Consequences

Editing `ai-home/AGENTS.md` no longer reaches Codex until the installer is re-run.
That is stated in `README.md` rather than left to be discovered, and it is the
only behavior this decision makes worse.

`scripts/test-install.ps1` no longer needs symbolic-link permission, so the
complete Windows installer test becomes runnable outside CI, including here.

## 2026-08-03 Scanning is unavailable here, and an accepted write is not a change

Status: Accepted. Closes the secret-scanning and code-scanning items Phase 7 held
open, and answers the plan question "The default branch is worth protecting and
cannot be protected here" named as the first thing to check for both.

### Decision

This repository runs no secret scanning, no push protection, and no code
scanning, recorded as one accepted exception rather than as a decision against
the controls. The reason is that GitHub does not sell them to this account for
this private repository without a purchase, the owner is the maintainer, and it
comes up for review again if the repository is made public or either product is
bought. `.github/workflows/codeql.yml` stays dispatch-only with its `push` and
`schedule` triggers commented out, since a run that builds a database it cannot
upload is a ten-minute failure on a schedule.

A repository settings change is confirmed by reading the state back, never by the
status code of the write that made it.

### Why

Three reads had reported the products off and none of them said why, so the items
were written as a settings visit whose sufficiency nobody had established. A read
cannot tell an unflipped switch from an unavailable product. A write can, because
its refusal carries a reason, and the same token had already written the
Dependabot security-updates switch on 2026-08-02.

Attempted on 2026-08-03 with that token, which carries `gist`, `read:org`, `repo`,
and `workflow` scopes and reports `permissions.admin` on the repository, one
product per request:

- `PATCH /repos/rwgs/ai` setting `security_and_analysis.secret_scanning.status` to
  `enabled` returns HTTP 422 `Secret scanning is not available for this
  repository.`
- The same call for `advanced_security` returns HTTP 422 `Advanced security has
  not been purchased.`
- `GET` and `PATCH /repos/rwgs/ai/code-scanning/default-setup` both return HTTP
  403 `Code scanning is not enabled for this repository. Please enable code
  scanning in the repository settings.`

So this is the same boundary the ruleset entry below hit, reached through a
different endpoint and stated in the product's own words. It is not a checkbox
waiting in the settings page. The account's plan name was not read, because `GET
/user` returns `plan: null` for a token without `user` scope; the boundary comes
from the refusals rather than from the plan, which is the stronger of the two
anyway.

The write rule comes from the third attempt, which is the one that would have
produced a false confirmation. `PATCH /repos/rwgs/ai` setting
`security_and_analysis.secret_scanning_push_protection.status` to `enabled`
returns HTTP 200 with the full repository object, and that object reports
`secret_scanning_push_protection` still `disabled`. Push protection depends on
secret scanning, which is unavailable, so GitHub accepts the request and changes
nothing. Reading only the status code would have closed half this item on a write
that did nothing.

`GET /repos/rwgs/ai` reports `security_and_analysis: null` before and after all
four attempts, so that field's absence is not evidence about any individual
switch. The per-product statuses appeared only inside the accepted PATCH's
response, where `dependabot_security_updates` reads `enabled` and
`secret_scanning`, `secret_scanning_push_protection`,
`secret_scanning_non_provider_patterns`, and `secret_scanning_validity_checks`
all read `disabled`. That is also the only confirmation to date, from any
endpoint, that the security-updates switch enabled on 2026-08-02 is still on.

### Rejected alternatives

- Leave both items open until the settings page is visited: the API has now
  answered what the settings page would show, and an item that cannot be closed
  by any action available here keeps a phase blocked on nothing.
- Make the repository public to obtain both products free: it decides
  publication, a much larger question, on the strength of two scanners. This is
  the second time that trade has been offered by a settings limitation and
  rejected for the same reason.
- Buy GitHub Secret Protection or GitHub Code Security: defensible, and the
  maintainer's call rather than an implementation decision, so it is a reopening
  condition instead of a choice taken here.
- Delete `.github/workflows/codeql.yml` since it cannot upload: it analyses both
  languages correctly on dispatch and fails only at the upload, so it is the
  configured control waiting for one setting rather than dead weight, and
  `scripts/validate.sh` requires it.
- Restore the `push` and `schedule` triggers anyway, to have the failure on
  record: the failure is already on record as run `30676585363`, and a scheduled
  red run trains a single maintainer to ignore the one signal they have.
- Substitute a local pre-commit secret scan: it runs on the machine that would
  have committed the secret, this repository installs no hooks, and a hook does
  not see what is already pushed. Worth revisiting as a convenience, never as the
  control.

### Consequences

Phase 7 closes with the reason recorded, which its CodeQL exit criterion already
permitted and its secret-scanning criterion did not; that criterion is restated to
allow it. Nothing in Phase 7 now waits on an external setting.

The exception is the whole of this repository's answer to two baseline rules. What
remains against a committed secret is the `AGENTS.md` rule that no credential,
token, session, history, cache, log, or runtime database belongs here, and the
`scripts/validate.sh` check that fails on a tracked `auth.json`, `history.jsonl`,
`installation_id`, or `*.sqlite`. That check names the four Codex artifacts this
setup could plausibly leak and knows nothing about any other secret, so it is a
compensating control for one filename list rather than for the rule.

The security baseline gains the read-it-back rule, because an accepted write that
changes nothing is indistinguishable from a successful one at the point where
somebody records that a control is on.

## 2026-08-02 Dependency updates are monthly, grouped, and pinned to a version tag

Status: Accepted. Extends "Bots may open pull requests, humans may not" below,
which chose to keep Dependabot and did not say at what cadence or against which
kind of ref. That entry stands unchanged.

### Decision

Dependabot version updates run monthly with every `github-actions` bump grouped
into one pull request. Dependabot security updates are enabled as well, which is a
second repository setting rather than part of `.github/dependabot.yml`. A pinned
action names a version tag in its trailing comment, not any other tag the upstream
project happens to publish.

### Why

The cadence was measured rather than assumed. In the thirteen weeks to 2026-07-30,
`github/codeql-action` published twelve version tags and `actions/checkout`
published two on the line it tracks. Weekly ungrouped updates over a two-action
surface annualise to roughly fifty pull requests, each firing a ten-minute
three-platform run, for one maintainer. Monthly and grouped gives twelve reviews a
year and still reports every stale pin, because the pins are a control against an
action moving under a mutable ref rather than a patch cadence.

That trade only holds with security updates on, since they are what does not wait
up to a month when an advisory lands. They were off while Dependabot alerts were
on, so the mechanism this repository documented as "Dependabot" was one of the two
switches GitHub actually has.

The version-tag rule comes from a defect, not a preference. Both
`github/codeql-action` steps were pinned to the commit behind
`codeql-bundle-v2.26.2`, which is a real immutable commit and satisfies every
supply-chain reason for pinning, but is not a point on the semver stream Dependabot
compares against. Dependabot reads that trailing comment to decide what version an
action sits at. The pin was five commits behind the `v4.37.4` release commit, in
`src/defaults.json`, `lib/defaults.json`, and `lib/entry-points.js`, so work was
available and no pull request had ever been opened. An immutable pin the update
mechanism cannot place on a version stream is silently never updated and is
indistinguishable from a pin that is current.

### Rejected alternatives

- Dropping Dependabot because CodeQL generates almost all the churn: the surface
  without CodeQL is `actions/checkout` at about three bumps a year, which is nearly
  free, and the entry below already rejected dropping it for the reason that
  nothing else reports a stale pin.
- Keeping the weekly ungrouped schedule: maximum freshness, but a queue that gets
  ignored reports currency it does not deliver, and the pins protect against a
  moved ref rather than against being a fortnight behind.
- Excluding `github/codeql-action` to cut the volume while keeping the rest: it is
  the pin with a real expiry, because GitHub retires action majors and a retired
  one eventually fails the run.
- Proving the mechanism by committing a deliberately stale pin and waiting for the
  bump: the repository already had a stale pin, so the experiment would have
  measured the same silence more slowly. Correcting the pin is the same test.

### Consequences

`.github/dependabot.yml` carries a `groups` entry and a monthly interval, and
`.github/workflows/codeql.yml` pins both steps to `f205ea1c` with a `# v4.37.4`
comment. The security baseline in `docs/WORKFLOW.md` splits routine currency from
advisory-driven updates, because they are separate capabilities and on GitHub
separate switches, and states that an absent pull request is not evidence the
mechanism works.

Whether the pin comment was the cause stays unproven. No REST endpoint exposes a
Dependabot version-update job, so the fix is also the test: if it was, the next
monthly run behaves normally, and if nothing appears the remaining explanation is
that version updates are not running on this repository at all.

Proven the same day, and the paragraph above is wrong about how. A version-update
job is an Actions workflow run named `Dependabot Updates`, so `gh run view --log`
reads its conclusion for every dependency without the repository's Dependabot tab.
The job that ran before the repin logged the action with no version at all and
resolved the latest version to the pinned commit itself; the job that ran after it
logged `4.37.4` and compared against the release stream. The pin comment was the
cause, version updates do run here, and the decision above stands unchanged. The
evidence is recorded against the task in `TASKS.md`, and the verification route is
now a rule in the `docs/WORKFLOW.md` security baseline.

## 2026-08-02 The default branch is worth protecting and cannot be protected here

Status: Accepted. Answers the ruleset question Phase 7 left open, and rejects the
premise it was asked on.

### Decision

A default-branch ruleset is worth configuring, including in a flow with one
maintainer and no pull requests. The half worth having is the push-enforced half,
and the two rules that carry it are blocking a force push and blocking deletion.

This repository configures none of it, because it cannot. That is recorded as an
accepted exception rather than as a decision against the control: the reason is
that the feature is not available on this account's plan for a private
repository, the owner is the maintainer, and it comes up for review again if the
repository is made public or the account moves to a plan that includes it.

`docs/WORKFLOW.md` gains the capability rule its `Default-branch enforcement` row
was missing, so the baseline asks for the protection rather than only naming the
mechanism, and the row states the plan boundary.

### Why

The question was asked on the premise that every gate a ruleset offers needs a
pull request or a second reviewer. Read from GitHub's rule reference on
2026-08-02, that is wrong for nine of the sixteen branch rules. Restricting
creations, updates, and deletions, requiring signed commits, blocking force
pushes, and the four file restrictions on path, path length, extension, and size
are all enforced when a commit is pushed. The seven that need a pull request are
the merge gates: linear history, deployments, a pull request itself, status
checks, code scanning, code quality, and coverage.

The distinction matters most in exactly the flow the premise assumed it away in.
A repository where every change is pushed straight to `main` has nothing between
a mistyped `git push --force` and the history it overwrites, and no reviewer who
would have seen it. The merge gates are genuinely unreachable here, and they are
not the useful part.

Availability is a separate answer and it is empirical. `GET
/repos/rwgs/ai/rulesets`, `GET /repos/rwgs/ai/rules/branches/main`, and `GET
/repos/rwgs/ai/branches/main/protection` each return HTTP 403 with `Upgrade to
GitHub Pro or make this repository public to enable this feature.`, read with a
token carrying `repo` scope on the repository. So there is nothing to configure,
partially configure, or configure later without changing the plan or the
visibility.

An exception is the honest record of that, and the baseline already has the
mechanism: it asks for a reason, an owner, and a review date wherever a host
provides nothing, and a host that provides it only on a paid plan is the same
gap. Recording it here rather than in `AGENTS.md` follows this repository having
a decision log; the guidance for an adopting repository is unchanged.

### Rejected alternatives

- Answer the question as asked and drop the ruleset from the roadmap: it is the
  answer the premise leads to, and it would have closed a control this
  repository wants on reasoning that a five-minute read disproves.
- Make the repository public to obtain the feature: it is free and it decides a
  much larger question, publication, on the strength of two branch rules. The
  restatement phase exists so that publishing is possible, not so that it is
  forced by a settings limitation.
- Buy GitHub Pro for it: defensible, and it is the maintainer's call rather than
  an implementation decision, so it is named as a reopening condition instead of
  taken here.
- Substitute a local `pre-push` hook that refuses a force push to `main`: it runs
  on the machine that would have made the mistake, it is not installed by this
  repository's installer, and a hook is bypassed by the same flag it is guarding
  against. Worth revisiting only as a convenience, never as the control.
- Record nothing until the plan changes: the gap then reads as an unexamined
  omission, and the next session re-derives the same three 403s.

### Consequences

`docs/WORKFLOW.md` states protecting the default branch's history as a
capability, with the condition that makes it apply, and its table row says the
GitHub mechanism is free on a public repository and needs a paid plan on a
private one. An adopting repository on any host reads the rule and either meets
it or records its own exception.

Phase 7 keeps no ruleset task. What is left in it is repository settings that
have to be changed outside this environment, and the same plan boundary is the
first thing to check for the secret-scanning and code-scanning items, since both
products are sold for a private repository too.

Nothing about the rule split has been tested here, because the API refuses the
read that would show it. It is GitHub's documentation, not an observation, and
the first person to configure a ruleset should expect to check it.

## 2026-08-02 Local readiness names the review it did not get

Status: Accepted. Settles the contradiction between `pr-readiness` and "No
branches and no pull requests in this repository" below, which that entry left
standing and the skill's restatement deliberately did not fix.

### Decision

The independent-review gate stays, and gains a condition. It applies where the
repository asks for one in its instructions or its recorded decisions, or where
its host enforces one over the changed paths. Where nothing settles the question,
the requirement is reported as undetermined and the readiness claim stays
conditional on it.

Where the author is the only party, the gate is not skipped and not faked. Four
substitutes take its place, none of them called a review: the complete required
gate run and reported by command, every automated review the repository does have
confirmed against the commit under review, a separate pass over the finished diff
read against the requirements rather than the intent, and the leftover risk named.

The result is reported as local readiness, with the missing review stated as a
limitation of that claim. No approval, review state, or reviewer that does not
exist is ever recorded, and a maintainer never approves their own change.

### Why

The skill is installed into every repository, and it stated a gate this
repository cannot satisfy. That leaves an agent three options and two of them are
bad: fake the review, ignore a hard gate, or block a change that is finished.
Ignoring it is the one that spreads, because a gate an agent learns to step over
teaches that the rest of the list is advisory too.

The condition has to be read rather than assumed, because both defaults are wrong
somewhere. Requiring a reviewer everywhere is the state being fixed. Assuming
nobody reviews would quietly weaken every repository that does have reviewers and
happens to load this skill, which is all of them.

The substitutes are chosen for being producible by one person and for failing
visibly. Three of the four are commands and their output. The fourth, a separate
pass over the finished diff, is the only judgment in the set, and it is worded so
it cannot be reported as a review: it is placed after the change is finished and
read against the requirements, because the defect it catches is the one the
author's intent papered over while writing.

Naming the absence is the part that carries the earlier entry's argument. That
entry rejected self-approval on the grounds that a gate whose shape survives
without its substance is worse than a missing gate, because it reads like one
that held. A readiness report that lists a review path and its evidence lets a
reader tell a change nobody else read from one that was reviewed, which is the
only honest output available when there is no second party.

### Rejected alternatives

- Drop the gate from the skill: it fits this repository exactly and makes the
  skill wrong for every repository with reviewers, which is the population the
  gate exists for.
- Keep it unconditional and let a single maintainer ignore it in practice: it was
  the state, it had been recorded as a contradiction twice, and an ignored hard
  gate costs more than the review it stands in for.
- Let a review by an agent count as the independent one: attractive, because a
  session with no authoring context does read the diff differently. Rejected
  because in this repository the agent is usually the author, and a rule whose
  answer depends on which session wrote the code cannot be checked from the diff.
- Have the maintainer self-approve to keep the gate's shape: already rejected in
  the entry this one settles, and the reasoning is quoted rather than repeated.
- Record the requirement in a field of `.agents/baseline.json`: configured rather
  than read, and it writes a claim about a repository's review culture into a
  marker whose every other entry is a checkable path.
- Leave the condition to each repository's own instructions and say nothing in
  the skill: the repositories that never wrote the rule down are exactly the ones
  reaching for guidance, and they would get the unconditional gate again.

### Consequences

`pr-readiness` gains a `Readiness without an independent reviewer` section and a
condition on its seventh workflow step, and its final report says which review
path applied and on what evidence. Every other rule in the skill is unchanged.

`docs/WORKFLOW.md` step 12 names both reduced paths rather than one. This
repository is on both, and they are independent: a repository can have pull
requests and one maintainer, or reviewers and no pull requests.

Phase 7's exit criterion that no documented gate depends on a human pull request
or a second reviewer is met for the reusable guidance. What is left in that phase
is repository settings that have to be changed outside this environment.

## 2026-08-02 Heading text is the contract between a template and an adopted document

Status: Accepted. Settles what the update workflow compares, which the scratch
proof found unstated and therefore broken.

### Decision

An adopted document keeps the heading text of every template section it retains,
and drops the sections that do not apply. Renaming a retained heading is
prohibited, and renaming one in a template here is a breaking change for every
repository that adopted it.

The comparison applies to the four templates whose headings are stable section
names: `AGENTS.md`, `SPEC.md`, `TASKS.md`, and `PLAN.md`. It does not apply to
`DECISIONS.md` or `CHANGELOG.md`, whose template holds a single placeholder entry
heading, or to `ROADMAP.md`, whose headings are example phase names. Those three
are checked by their own rules.

A section a repository deliberately does not have is closed by an entry in that
repository's own `DECISIONS.md`, and is then reported as kept on purpose rather
than counted outstanding.

### Why

Found by running the loop on a scratch repository on 2026-08-02 rather than by
reading it. Adoption said to adapt each template and delete what does not apply,
and said nothing about heading text, so an adapted `AGENTS.md` came out carrying
`## Scope`, `## Working style`, and `## Verification` where the template had six
different headings. The update run then reported the whole template as missing,
which is the maximally wrong answer: it is noise on every run, and the one thing it
hides is a genuinely new section.

Heading text is the only join available. The prose beneath a heading is meant to
have been rewritten, which rules out comparing content; the marker records paths
rather than sections, which rules out recording the section set; and any identifier
added to a heading would be visible in a document a human reads constantly.

The exclusions are the same argument in reverse. A template that never had stable
sections cannot supply the join, and comparing anyway produces a diff on every real
entry of an append-only log and on every phase name a repository chose for itself.

The closed-section rule is what makes the loop terminate at all. Adoption
instructs a repository to delete inapplicable sections, so every adopting
repository is missing some, and the update workflow only read `DECISIONS.md` in its
convention-drift section. Without extending that read to sections, a missing
section stayed outstanding forever, the recorded commit could never advance, and
"re-apply until it reports nothing to do" was unreachable by construction.

### Rejected alternatives

- Compare content rather than headings, and report a section whose prose still
  matches the template: it inverts the rule the baseline is built on, that an
  adopted document is adapted as it lands, and it would report nothing for a
  document that was properly adapted.
- Record the adopted section set in `.agents/baseline.json`: a second list to
  maintain, and it goes stale exactly when someone edits the document without
  updating the marker, which is the failure the marker exists to detect rather than
  to acquire.
- Let each repository rename headings and match them by order or by similarity:
  a matcher with no ground truth, guessing which of two rewritten headings is the
  same section.
- Add a stable machine identifier to each heading, such as an anchor comment:
  robust, and it puts markup into the documents a human reads most, for a join that
  heading text already provides for free.
- Keep the `DECISIONS.md` read in the convention-drift section only and accept
  that a dropped section is reported forever: it is what the skill said, and it
  makes the phase's own exit criterion unreachable.

### Consequences

`adopt-baseline` requires the heading text and carries a safety rule against
renaming one. `start-repository` says the same for the documents it creates.
`update-baseline` names the four comparable templates, says how to check the other
three, and reads the repository's `DECISIONS.md` before reporting a missing section
or counting it outstanding.

Renaming a section heading in one of the four templates here now costs every
adopting repository a reported drift. That is the intended price of having a join
at all, and it is worth stating in a commit that renames one.

## 2026-08-02 A new repository is started, and its refusals carry a reopening condition

Status: Accepted. Implements the third workflow the entry below on sibling skills
left named and unwritten, and settles what an empty repository can take.

### Decision

`start-repository` is a tenth installed skill. Three workflows, three
preconditions: the marker separates a first pass from every later one, and whether
the repository holds work separates the two first passes. A repository holding
nothing but what its host's create command left is started; one holding a source
file, an instruction file, or a planning document is adopted.

It keeps no list of what a repository may take. `adopt-baseline` holds that, and
this skill points at it for the selection table, the skill wiring, the host
reading, the CI derivation, and the marker's fields. What it decides differently
is what an empty repository can take yet, in three rules.

- The line-ending and ignore rules are the first commit, ahead of the instruction
  files.
- A document that states intent is written now, and a document that records
  history waits. `SPEC.md`, `ROADMAP.md`, and `TASKS.md` are writable at creation;
  `PLAN.md` and `CHANGELOG.md` are not. `DECISIONS.md` is the exception among the
  history documents and is written now.
- Every artifact left out records the condition that reopens it, in the marker's
  existing `declined` field. `update-baseline` reads the reason and says whether
  the repository now meets it.

### Why

The two existing skills both mismatch a new repository, and not cosmetically.
`adopt-baseline` opens by inventorying files that do not exist, reconciling a
`CLAUDE.md` nobody wrote, and deciding keep-or-promote for skills nobody authored,
so four of its steps are no-ops before it reaches anything useful; `update-baseline`
refuses to run without a marker. The result was a project set up by hand and never
recorded, which leaves it outside the update loop this phase exists to close.

Putting `.gitattributes` in the first commit is the one thing a new repository gets
cheaply that an adopting one cannot. Verified in a scratch repository on
2026-08-02: with the file committed first, a file subsequently written with CRLF is
staged as LF and `git add --renormalize .` stages nothing, so the renormalising
commit and the working-tree refresh that adoption needs never happen at all.

The intent-against-history split is what stops the planning set becoming stubs. It
is tempting to read "no code yet" as "no documents yet", and the opposite is true
for three of them: the requirements, the phase order, and the first phase's tasks
are the reason the repository is being created. `PLAN.md` and `CHANGELOG.md` have
nothing to hold, because one describes a change in flight and the other what
changed for consumers who do not exist. `DECISIONS.md` inverts again, and is the
strongest case of all: the language, the framework, the host, and the shape are
chosen while the repository is created, and those are exactly the choices whose
rationale cannot be recovered from the code a year later.

The reopening condition is the load-bearing part, and it follows from what the
update skill already does with a decline. It reports one once per run with its
recorded reason and never adds it, which is right when the reason is "this
repository does not want it" and wrong when the reason is "there is nothing to put
in it yet". At creation almost every refusal is the second kind, most sharply for
the CI definition: no workflow is added to a repository with no check to run, so
the usual new repository declines it on day one and would never be offered it
again. A reason naming the condition turns that into a report that becomes
actionable the moment the first test lands.

### Rejected alternatives

- Extend `adopt-baseline` to handle an empty repository, branching per step: no
  growth in the installed set and no installer rerun. Rejected on the rule
  recorded below, that this is a third precondition rather than a mode, and
  because the branches would land in the four steps that exist to reconcile
  content, which is precisely what an empty repository has none of.
- Leave new repositories to `adopt-baseline` unchanged and accept the no-op steps:
  cheapest, and it is the state that produced the problem. An agent asked to start
  a project reaches for the skill named for adopting an existing one, or sets the
  project up by hand and writes no marker.
- Repeat the offerable set in the new skill so it stands alone: rejected for the
  third time, and the argument gets stronger with each skill. Three lists disagree
  sooner than two, and the last change to extend the set would have had to edit all
  three.
- Ship a template repository to clone instead of a skill: one command, and it
  freezes the baseline at the moment the template was written, has no marker, and
  needs its own update mechanism, which is the whole of Phase 6 rebuilt for a
  second artifact.
- Add a `deferred` field to the marker beside `declined`: honest about the
  difference, and it teaches `update-baseline` a second vocabulary in a record
  whose entries are otherwise all checkable paths. The same argument already sent
  intentional convention deviations to the repository's own `DECISIONS.md`. The
  reason text carries the distinction at no schema cost, and a marker written by
  either skill reads the same way.
- Create every planning document at creation and let them fill in later: uniform,
  and it produces exactly the stub this baseline reports as drift. A document of
  headings reads as an answered question.
- Write a CI definition with no steps, so the file exists from day one: it reports
  a green run it did not earn, on every push, which is the case already rejected
  when the CI definition was made derived rather than copied.

### Consequences

The installed set is ten, so the installer has to be rerun to add the link.
`docs/SKILLS.md` lists the skill, the `docs/WORKFLOW.md` lifecycle names which of
the three to run, and `CHANGELOG.md` says why a rerun is needed.

`update-baseline` gains one clause: it reads a decline reason before reporting it
and says whether a reopening condition is now met. `adopt-baseline` gains the
handover at its inventory step and the boundary in its scope and description.
Nothing else about either changes, and the offerable set is still in one place.

Phase 6 has one task left, the scratch-repository proof, and it now has three
workflows to exercise rather than two. Nothing here is verified against a real
repository either; that task is what changes it.

## 2026-08-02 Adoption installs line endings and derives the host's CI definition

Status: Accepted. Settles how the development infrastructure is propagated, which
Phase 6 named and left to whichever host branch Phase 8 produced.

### Decision

`.gitattributes` is installed in every adopting repository, with the
renormalisation as a commit of its own and the working-tree refresh after it. The
CI definition and the dependency-update configuration are offered rather than
installed, and each is the one belonging to the repository's host: the Actions
workflow and Dependabot on GitHub, `azure-pipelines.yml` and no Dependabot on
Azure DevOps, neither on a host with no counterpart, with the reason recorded
either way.

The CI definition is derived from this repository's own, never copied. Its shape
is convention and travels: the triggers, the least-privilege permission block, the
concurrency group, actions pinned by commit SHA, the timeout. Its steps do not,
because they run checks only this repository has, so they are written from what the
adopting repository actually has, and no workflow is added to a repository with no
check to run.

The host is read from the remote and asked for wherever the hostname names no
product. One question, whether the repository accepts a pull request from a bot,
decides both Dependabot and the `pull_request` trigger; where the answer is no, the
action pins are refreshed by hand and that is recorded as an accepted exception.

### Why

The three artifacts look like one propagation task and behave like three. Line
endings have a failure rather than a gap behind them: a Bash script checked out
with CRLF fails with `syntax error near unexpected token`, which this repository
hit in its own checkout, so the file is not a preference to offer. A CI definition
is the opposite: its value is entirely in the checks it runs, and this
repository's are `shellcheck scripts/*.sh`, `./scripts/validate.sh`, and the
PowerShell installer test under both editions. Copied anywhere else that is a
workflow that fails on its first run, so what propagates is the shape.

Deriving also settles what a green run means. A workflow whose steps were copied
and then emptied reports success it did not earn, and it does that on every push,
which is worse than an absent workflow because the repository looks validated.

Asking for the host rather than deducing it follows from what the URLs can carry.
`github.com`, `dev.azure.com`, and `*.visualstudio.com` name a product; an
on-premise Azure DevOps Server answers at whatever hostname its organisation gave
it, and a repository may have no remote yet. Guessing wrong writes the wrong CI
definition into the repository, which is a file the maintainer then has to notice.

Tying Dependabot and the `pull_request` trigger to one answer is the same reason
this repository keeps both under "Bots may open pull requests, humans may not".
The condition behind that entry is not a preference about bots; it is whether
anyone merges what a bot opens. A repository where nobody does wants neither the
configuration that opens them nor the trigger that validates them, and it still
has to keep its pins current, which is why the refusal carries an accepted
exception rather than silence.

The renormalisation is separated from the file because the two are separate
operations, verified in a scratch repository on 2026-08-02. Committing
`.gitattributes` changes nothing already committed; `git add --renormalize .`
stages the conversion and touches every affected file; the working tree keeps its
old endings until `git rm --cached -r .` and `git reset --hard` check them out
again; and a rerun that stages nothing is what proves the tree converged.

### Rejected alternatives

- Ship a workflow template as a skill asset, so the shape has one authored
  source: it is a second copy of what `.github/workflows/validate.yml` already
  carries, with nothing comparing the two, which is the drift argument this
  baseline has already accepted for instructions and for skills.
- Copy the workflow verbatim and let the adopting repository delete the steps it
  cannot run: every adoption starts with a red build, and the steps most likely to
  be left behind are the ones naming scripts that do not exist.
- Generate the adopting repository's workflow from a detected project type: it
  needs a matrix of ecosystems and check commands, guesses the build for every
  project it has not seen, and the skill already reads the repository for
  everything else it writes.
- Offer `.gitattributes` alongside the other two, for symmetry: symmetry bought by
  making the one artifact with a reproducible failure behind it optional.
- Detect the host from the remote alone, with no question: shorter, and an
  on-premise Azure DevOps Server is indistinguishable from any other private
  hostname, so the quiet answer would be to offer neither artifact to exactly the
  host that needs its pipeline most.
- Offer Dependabot independently of the `pull_request` trigger: two questions with
  one answer between them, and the failure mode is a repository configured to
  receive pull requests nothing validates.

### Consequences

`adopt-baseline` gains a step between project-scoped configuration and the
marker, so what it propagates is recorded like everything else, and the marker
records a host-specific artifact under the path it takes on that host.
`update-baseline` needs no list of its own: it reads the offerable set from
`adopt-baseline`, and gains one rule, that a host-specific artifact is added only
for the host the repository is on now, so a repository that moved host is reported
rather than given a second CI definition.

Two adopting repositories will not end up with identical workflow files. That is
the intended outcome of deriving rather than copying, and it means a future change
to this repository's workflow shape propagates as convention rather than as a
diff.

The phase's remaining work is unchanged: an entry point for a new repository, and
the scratch-repository proof, which is now the only thing standing between this
loop and evidence that it works.

## 2026-08-01 Updating is a sibling skill, and only a verbatim copy is refreshed

Status: Accepted. Settles the choice the task left open between an update mode
inside `adopt-baseline` and a skill of its own, and how far additive semantics go.

### Decision

`update-baseline` is a ninth installed skill. Presence of
`.agents/baseline.json` separates the two: no marker means the repository never
adopted and `adopt-baseline` owns the pass, a marker means the repository is
updated against it and never adopted again. Each skill names the other at its
boundary, and the offerable set of artifacts stays in `adopt-baseline` alone.

Additive semantics are drawn in three places rather than one.

- A missing document or a missing template section is added. A section that cannot
  be written for the repository is reported instead, because an empty heading reads
  as an answered question.
- No line an adopted document already carries is ever rewritten, and convention
  drift is reported rather than corrected.
- A skill copied from the pool is refreshed when its copy is byte-identical to the
  pool at the recorded commit, and reported untouched otherwise.

`baseline.commit` advances only when nothing the run surfaced is still outstanding.
A pooled skill carries its own commit, so one customised copy does not hold the
baseline commit back. A deviation the repository intends to keep is recorded in its
own `DECISIONS.md`, which this skill reads before calling anything drift.

### Why

Two workflows with different preconditions, different semantics, and different
outputs are two skills under this repository's own authoring rule, and the split
already has a precedent here in project planning against pull-request readiness.
The triggers separate cleanly: adopt, standardise, and roll out against update,
refresh, and drift. A single description covering both would have to be chosen from
by an agent that then branches inside the skill, and `adopt-baseline`'s scope line
has said one repository, once, since it was written.

The refresh test is the provenance rule this repository already accepted for shared
files, applied where it fits. Write only what is absent or still byte-identical to
what was recorded; preserve and report anything else. A pooled skill is copied
verbatim, so byte-identical is its normal state and the test does real work. An
adopted document is adapted to the repository as it lands, so it is never
byte-identical and the same test would be dead code, which is why documents keep
the stricter never-overwrite rule that `ROADMAP.md` states as a correctness
requirement.

Holding the recorded commit back is what stops the report losing a finding. The
commit is the point a later run diffs from, so advancing it past drift that was
reported and never applied would hide that drift permanently, in the one file whose
whole purpose is to make an update honest.

Reading the repository's `DECISIONS.md` before reporting drift is what makes the
loop converge without inventing a marker field for it. A deviation held on purpose
is a closed decision, which is exactly what that file records, and the alternative
was a second vocabulary of convention keys inside a marker whose entries are
otherwise all checkable paths.

### Rejected alternatives

- A second mode inside `adopt-baseline`, branching on the marker: no growth in the
  installed set and no installer rerun. Rejected on the authoring rule and the
  trigger collision; the user chose the sibling when both shapes were put side by
  side.
- Repeating the offerable set of artifacts in the update skill so it stands alone:
  self-contained, and it guarantees the two lists disagree, starting with this
  phase's own propagation task, which would then have to update both.
- Applying convention drift automatically, since each rule is one the baseline
  asserts: it edits files nobody asked it to touch, and every rule in the list has
  a reason a repository might legitimately hold it.
- Overwriting an adopted document when it is byte-identical to the template, for
  symmetry with the skill rule: consistent, and unreachable, because adoption
  adapts the template as it lands.
- Advancing the recorded commit on every run and recording outstanding drift in the
  marker instead: keeps the commit meaning "last compared", at the cost of a second
  list to maintain in the record and a second way for it to go stale.
- Overwriting a customised pool copy and leaving the user to recover it from Git:
  simplest refresh, and it destroys the customisation this phase exists to protect.

### Consequences

The installed set is nine, so the installer has to be rerun to add the link.
`docs/SKILLS.md` lists the skill and `CHANGELOG.md` says why a rerun is needed,
which no other change in this phase has required.

The `SPEC.md` question about how an adopting repository is told a pooled skill has
changed is answered and moves out of the unresolved list. Nothing here is verified
against a real repository: the phase's scratch-repository proof is the task that
does that, and it now has something to prove.

The remaining phase task that gives a new repository its own entry point inherits a
settled rule for where it belongs. It is a third workflow with a third
precondition, an empty repository, not a mode of either of these two.

## 2026-08-01 An adopting repository records what it took in `.agents/baseline.json`

Status: Accepted. Gives the update mode planned in Phase 6 something to compare
against, which the entry below left named but unplaced.

### Decision

A repository that adopts the baseline commits one file, `.agents/baseline.json`,
beside the `.agents/skills/` directory adoption already writes into. It carries a
`version`, the baseline clone URL, the full commit taken and the date it was
taken, the baseline artifacts adopted, the artifacts declined with a reason for
each, and every skill copied from `rwgs/ai-skills` with its source URL and full
commit.

It records what came from the baseline or the pool and nothing else. A skill
authored in the repository has no entry, because it has no upstream to compare
against, and the keep-or-promote-or-retire decisions adoption makes stay in that
repository's `DECISIONS.md`.

Every entry names something checkable in the working tree, so a later run reports
the marker disagreeing with the repository rather than trusting it. Both commits
are read from a clone with no uncommitted changes, because content copied out of
a dirty tree is not the commit that would be recorded.

### Why

Update mode is additive: it adds what is missing, reports drift, and overwrites
nothing. Two absences look identical in a repository and mean opposite things. A
`SPEC.md` missing because the repository declined it must never be offered again;
a `SPEC.md` missing because the baseline added it after adoption is exactly what
an update exists to add. Only a record of the decline separates them, and only a
reason on that record stops the declined document being offered on every
subsequent run.

The same argument already decided where the skill pool lives. That entry made the
pool a repository so a copy would have a commit to be compared against; this one
is where the commit is written down. Without it the pool decision buys nothing.

A separate file rather than a section of an adopted document, for two reasons.
The marker is state that every re-apply rewrites, and the planning documents are
either hand-maintained prose or, in `DECISIONS.md`, append-only by their own
header. It also has to exist in a repository that declined every planning
document, which the selection table permits for a documentation repository, and
that is precisely where the declined list is most of the content.

JSON because it is the one format `python3` and Windows PowerShell 5.1 both parse
with nothing installed, which is already recorded here as why the `config.toml`
merge is textual: `tomllib` reads TOML and does not write it, and PowerShell has
no TOML support at all. The installer's provenance manifest is the precedent for
the shape, including the `version` field. The marker differs from it in the one
way that matters: it is per-repository and committed, because a fresh clone must
be able to say what the repository adopted.

Full 40-character commits, because a short hash goes ambiguous as either
repository grows and this file is read long after it is written. The clone URL
rather than `rwgs/ai`, because nothing host-neutral asserts a host and the same
content can be cloned from Azure DevOps.

### Rejected alternatives

- A `## Baseline` section in the adopting repository's `AGENTS.md`: no new file,
  and it is the one document every adopting repository has. Rejected because a
  re-apply would rewrite a block inside hand-maintained instructions that both
  agents load in full, spending context in every session on a fact only an update
  run reads.
- An entry in the adopting repository's `DECISIONS.md`: adoption already writes
  decisions there, so it looks like the natural home. Rejected because that file
  is append-only, the recorded commit changes on every re-apply, and a
  documentation repository declines the file entirely.
- A dotfile at the repository root: one more top-level entry in every adopting
  repository, competing for attention with a planning set deliberately closed at
  six files, when `.agents/` already holds the other per-repository artifact
  adoption writes.
- Recording only the commit and letting update mode diff the baseline tree against
  the repository: fewest fields and no reasons to maintain. Rejected because a
  diff cannot tell a declined document from a missing one, so every update would
  offer back everything the repository deliberately refused.
- A submodule or subtree pinning the baseline: an exact commit with nothing
  hand-written to drift. Rejected because it drags the whole baseline into every
  adopting repository, and adopted documents are customised after they land, which
  is the case a subtree merge handles worst.
- A Markdown table, which a human reads most easily: it has no parser in any
  language used here, so every reader would hand-roll one.
- Recording every skill in the repository rather than only the pool copies: a
  hand-maintained inventory whose extra rows have no upstream, so they can never
  be compared and can only go stale.

### Consequences

`adopt-baseline` gains a step that writes the marker and an inventory check that
stops adoption when one already exists, since the skill applies to a repository
once. `docs/SKILLS.md` and `SPEC.md` name the file as where a pool commit is
recorded, and the `SPEC.md` unresolved question narrows: both inputs to the
comparison now exist and only the reporting is unbuilt.

Update mode reads one file for both recorded commits and receives the declined set
as data rather than inferring it. Its remaining freedom is what to do when the
marker and the repository disagree, which is a report either way.

This repository gets no marker. It is the baseline rather than an adopter, and
nothing here reads or writes one.

## 2026-08-01 One skill source per repository, exposed by an ignored link

Status: Accepted. Settles the disagreement between `docs/SKILLS.md` and
`adopt-baseline`, which described two different dual-agent wirings.

### Decision

A repository holds one copy of each skill, under `.agents/skills/<name>`,
whether it was written for that repository or copied in from the `rwgs/ai-skills`
pool. Claude Code reaches it through a single directory link, `.claude/skills`
pointing at `.agents/skills`, created during adoption, listed in `.gitignore`,
and never committed. There is no second copy under `.claude/skills/<name>`.

Where a repository already has a real `.claude/skills` directory, its skills move
to `.agents/skills/` before that directory is replaced by the link.

### Why

Two copies of one skill in one repository drift, and the drift is silent because
each agent reads only one of them. That is the same argument this baseline
already accepted twice: one `AGENTS.md` with `CLAUDE.md` as a bare import, and
managed files installed as links rather than copies.

It also decides a question Phase 6's update mode would otherwise have to answer.
That mode compares an adopted copy against the pool commit recorded for it. With
one copy the comparison has one input. With two it has two, plus a rule for what
a disagreement between them means, and that rule would have to be invented
because neither copy is more authoritative than the other.

`.agents/skills/` is the source rather than `.claude/skills/` because it is the
agent-neutral path, it is what this repository already authors into, and Codex
reads it directly.

### Rejected alternatives

- Two committed copies, the wording `docs/SKILLS.md` carried: it needs no
  per-clone setup and works on a Windows clone that cannot create links, which is
  a real advantage. Rejected because it trades a one-time setup step for silent
  drift between two files that are supposed to be the same file.
- Committing the link instead of ignoring it: a committed symbolic link is
  checked out as a plain text file on a Windows clone without symbolic-link
  support, and skill discovery then fails with no error at all.
- Authoring under `.claude/skills/` and linking `.agents/skills`: the same shape
  reversed, with the source in the agent-specific directory.
- Leaving both wordings and letting each repository pick: the two have different
  drift behavior, so update mode would need to detect which was used before it
  could report anything.

### Consequences

`.claude/skills` is per-clone setup under this decision, so a fresh clone of an
adopting repository has no Claude Code skills until the link is recreated. That
cost is accepted and stated in `adopt-baseline`, whose validation step already
checks that project-local skills resolve under both paths.

This repository is unaffected: it has no `.claude/skills` and needs none, because
every skill here is installed user-wide by the installer and none is
project-local. The rule governs adopting repositories.

Phase 6's update mode reads one skill copy per name and one recorded pool commit.

## 2026-08-01 A skill about the agent's own operation is installed, not pooled

Status: Superseded in part by "The Codex reset-expiry skill is removed, not
pooled" above, which drops the skill this entry declined to drop. The clause
itself stands. Adds the clause that "Install only the skills that earn a place on
every machine" below needed and did not have, and that `docs/SKILLS.md` has been
contradicting since `show-codex-reset-expiries` was installed.

### Decision

The bar that sends a skill tied to one product, one environment, or one kind of
project to the pool is about the repository a skill is drawn into. A skill about
an agent's own operation is placed by machine reach instead, so
`show-codex-reset-expiries` stays installed even though it names Codex.

### Why

The pool exists because a skill about a stack is wanted in the repositories
written in that stack and nowhere else, so a copy per repository is the right
shape. `show-codex-reset-expiries` has no repository dependency of any kind: it
reports the expiry times of the signed-in account's Codex rate-limit reset
credits, which is the same answer in every directory on the machine. Pooling it
would make an account-level check present only in the repositories that happened
to copy it, absent in the one the user asks from, and duplicated as a `.mjs` file
per repository.

It also passes the part of the bar that the pool test exists to protect. The
description is explicitly gated on the user asking for it, so the trigger cannot
misfire into unrelated work, and `docs/SKILLS.md` already names this skill as the
one legitimate case for putting an agent's name in a description.

### Rejected alternatives

- Move it to the pool, as the literal wording of the bar requires: consistent,
  and it makes a user-wide question answerable only where someone copied the
  answer in.
- Leave the contradiction and note it on the skill: it was already noted twice,
  in `TASKS.md` and in the authoring rules, and each placement decision had to
  re-derive the exception.
- Drop the skill: it is the only thing here that reads the reset-credit
  expiries, and nothing else in either agent reports them.

### Consequences

`docs/SKILLS.md` states the clause, so the next candidate is placed by reading
the bar rather than by comparing itself to this skill. A future skill about
Claude Code's own operation is installed for the same reason without needing a
new entry.

The installed set stays at eight.

## 2026-08-01 Both hosts are supported, only GitHub is verified

Status: Accepted.

### Decision

The baseline supports GitHub and Azure DevOps, covering both the hosted service
and Azure DevOps Server on-premise. Support means three things and not a fourth.

- Nothing host-neutral asserts a host. A rule states the capability it needs,
  and a table underneath it names the mechanism on each host, including where
  one host has none.
- Host-specific artifacts are named per host and sit beside each other. This
  repository keeps its GitHub Actions workflows and gains an
  `azure-pipelines.yml` running the same gate. Neither is generated from the
  other.
- Azure DevOps artifacts ship labelled unverified until an organisation or a
  server exists to run them against.

It does not mean a host abstraction layer, a detected-host branch in installer
code, or a command wrapper that dispatches on the remote URL.

### Why

The requirement is to design for Azure DevOps, cloud and on-premise, with
neither in use. That makes verification impossible today and makes the
verifiable part the separation itself: whether a GitHub name appears where the
host is irrelevant. Read this session, the leak is in seven places and only two
of them are genuinely host-specific work, the CI definition and the
pull-request commands. The rest is a GitHub product name standing in for a
capability.

Labelling rather than withholding follows from who reads these files. An agent
loads `pr-readiness` in every repository and `docs/WORKFLOW.md` on any
governance question, so an unwritten Azure DevOps path is not a neutral absence:
the agent falls back to the GitHub commands, which fail, or invents an `az`
line. An artifact marked unverified is a claim the reader can price. Nothing
here weakens the rule that a command is read before it is written; the two
tasks that need a command surface are sequenced behind reading it.

Keeping GitHub as the verified host is a statement of fact rather than a
preference. The repository is hosted there, its three-platform runs are the only
CI evidence the maintainer can obtain, and the `Validate` workflow's push
trigger was fixed at some cost in Phase 4.

### Rejected alternatives

- Stay GitHub-only and revisit if an Azure DevOps repository appears: cheapest,
  and it was the position until this was asked for. It also means the coupling
  keeps spreading, because Phase 6 is about to teach `adopt-baseline` to
  propagate CI and dependency-update configuration, and a GitHub-shaped
  propagation is far more expensive to unpick afterwards than to avoid now.
- Abstract the host behind one interface, so no file names a host: the shape a
  reader expects, and it fits badly. Two hosts differ in what exists, not only
  in how it is spelled. Azure DevOps Server has no Microsoft-hosted agents, no
  Dependabot, and no code-scanning product this session could confirm, so the
  abstraction would need holes named per host anyway, and the holes are the
  useful part.
- Generate `azure-pipelines.yml` from the Actions workflow: one source, and it
  requires a translator for two schemas with different job, matrix, and shell
  models, validated against neither host. A second file of ninety lines is
  cheaper than a generator nobody can test.
- Withhold the Azure DevOps artifacts until an instance exists to verify them
  against: honest and it leaves the requirement unmet indefinitely, with the
  design work discarded. Rejected in favour of shipping them labelled.
- Migrate this repository to Azure DevOps to make the second host the verified
  one: it would verify the new path by abandoning the one that works, and the
  maintainer uses neither Azure DevOps variant.

### Consequences

`SPEC.md` gains host neutrality as required behavior and the unverified pipeline
as a stated non-goal for this phase. `docs/WORKFLOW.md`'s security baseline is
restated as capabilities with a per-host table, which is what an adopting
repository on either host reads. `scripts/validate.sh` stops treating the
`.github/` layout as the definition of a valid repository.

Phase 6 inherits a requirement rather than a fix: whatever `adopt-baseline`
learns to propagate, it propagates the artifact matching the adopting
repository's host. Phase 7's governance gates are GitHub features, so that phase
now has to say which of its gates exist on Azure DevOps and which do not.

The first person to run the pipeline against a real organisation should expect
to correct it. That is the cost accepted here, and it is recorded in the file
itself so the expectation is not lost with this entry.

## 2026-08-01 Restate the installer's linking core, leave the rest of the script code

Status: Accepted. Settles the case the entry below left open, which rejected
rewriting commands and configuration keys as churn but said nothing about
authored logic.

### Decision

Four functions are restated, because each is wholly or almost wholly inherited
and each has a structure that could have been written another way:
`resolve_path` and `link_managed_path` in `scripts/install.sh`, and
`Test-LinkTargetsSource` and `Get-BackupPath` in `scripts/install.ps1`. Their
bodies change; their names, parameters, and every string they print do not.

The other 626 attributed lines across the five scripts stay as they are.

### Why

The 750 lines are not 750 lines of authored logic. Measured on 2026-08-01: 299
of them are a blank line, a lone `}`, `fi`, `done`, or `else`, a shebang, or a
comment. Much of the rest is declaration boilerplate that has one spelling --
`set -euo pipefail`, `Set-StrictMode -Version Latest`, PowerShell `param(`
blocks with their `[Parameter(Mandatory)]` and `[string] $Path` lines, and the
`$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)` idiom every shell script
here opens with.

What is left is concentrated rather than spread, which is why a per-function
answer is possible at all. Six functions hold it: `resolve_path` 39 of 39 lines,
`link_managed_path` 42 of 45, `Get-NormalizedPath` 11 of 11,
`Test-LinkTargetsSource` 20 of 20, `Get-BackupPath` 23 of 31, and
`Write-DryRunCommand` 10 of 10. Two of those six are a parameter block wrapped
around a single expression, so they are excluded; the other four branch, loop,
or compare, and that is the choice a restatement can actually make differently.

The message strings are excluded because they are a contract between four files,
not prose. Both installer tests match the installer's exact output:
`scripts/test-install.sh` greps `^error: too many symbolic-link hops:` and
`^pruned stale skill link: `, and `scripts/test-install.ps1` matches
`(?m)^preserved: ` and `(?m)^dry run complete$`. Rewording one message means
editing four files in step, and the only evidence the edit is correct is the
same three-platform run that already passes. Holding the strings fixed also
means the restatement cannot break a test by rewording.

Regression risk is asymmetric with the prose passes, which is the reason to
restate four functions rather than five files. A restated document that drops a
rule is caught by reading it. A restated installer that drops a guard is caught
only where a test already covers that guard, and these scripts are the paths
that write into a populated `~/.codex` and `~/.claude`. The four selected
functions are the covered ones: `resolve_path` by the cyclic-link fixture and
the relative and normalized equivalent-link assertions, `link_managed_path` by
the full link inventory and the backup count, and the two PowerShell functions
by `Assert-Link` on every managed link plus the idempotent re-install asserting
that no second backup appears.

### Rejected alternatives

- Restate all 750 lines: churn across 299 structural lines and the declaration
  boilerplate, and it drags the message strings into scope, which is exactly
  where the four-file coupling lives.
- Leave all 750 as they are: cheapest, and the reading the entry below invites.
  Rejected because `resolve_path` and `link_managed_path` are 81 lines of wholly
  inherited authored logic in the installer's linking core, the largest such
  concentration left in the tree, and the phase's claim would then depend on
  nobody looking there.
- Rewrite the five scripts from scratch against `SPEC.md`: produces a genuinely
  independent installer, and discards behavior proven on three platforms under
  both PowerShell editions to solve an attribution problem 124 lines wide.
- Restate `Get-NormalizedPath` and `Write-DryRunCommand` too, for consistency:
  the first returns one `GetFullPath` call with a `TrimEnd`, the second is one
  `if`. Renaming their parameters would shed attribution without changing
  anything a reader would call authored.

### Consequences

The phase closes with 626 attributed lines rather than zero, and that is the
intended end state. Its claim is about prose and authored logic, not about the
number `git blame` reports.

`TASKS.md` carries the restatement, sequenced after the pending first install on
this machine so that install runs the code the CI runs already proved. Nothing
here asks for attribution to be preserved: a later change to these scripts is
free to rewrite whatever it touches.

## 2026-08-01 Replace the inherited content instead of rewriting the history

Status: Accepted.

### Decision

The commit history stays as it is, including the 34 commits by the upstream
author. The inherited *content* is replaced file by file until the tree stands on
its own, prioritised by how much surviving upstream prose each file carries.
Functional lines are left alone: commands, configuration keys, rule entries that
are just command names, `.gitignore` patterns, and workflow boilerplate.

### Why

Measured on 2026-08-01 with `git blame` across every tracked file: 1,926 of the
tree's 8,704 lines are still authored by the upstream commits, spread over 31
files. This repository began as a copy of the public `ChrisTitusTech/titus-ai`,
which carries no licence, and it is not a GitHub fork.

Rewriting the history was the obvious alternative and does not do what it looks
like it does. Squashing to a fresh root would delete the record of who wrote what
while keeping what they wrote, which is worse than leaving it: the same content
would be published with its attribution removed. It would also discard the
evidence trail this repository deliberately accumulates in its commit messages,
including the CI run identifiers that close tasks.

Replacing the content is the only route that ends with a tree that is this
repository's own regardless of what upstream does, and it improves the files on
the way: the inherited instruction prose was written for a different repository
and says less about this one than a restatement can.

### Rejected alternatives

- Squash to a single fresh commit and force-push: covered above. It solves the
  narrower problem of the upstream author's personal paths appearing in history,
  which matters only if this repository is published.
- Start a new repository: the same rewrite with the settings, URL, and evidence
  thrown away.
- Ask upstream to add a licence and change nothing: cheapest and still worth
  doing, but it leaves the outcome dependent on someone else answering.
- Rewrite every attributed line, including commands and configuration keys:
  churn. `./scripts/install.sh --dry-run` has one spelling, and changing a rule
  entry's command name would break it.

### Consequences

`TASKS.md` carries the remaining files in priority order. Each pass has to
preserve behavior exactly: these are working instructions, and
`scripts/validate.sh` checks several of them, so a restatement that drops a rule
is a regression rather than a rewrite.

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
Codex writes interactive approvals into it, and in part by "Windows installs
without a privilege, by method per target" above, which stops using symbolic
links on Windows. The principle stands and the mechanism is per platform: on
Linux and macOS every file named here is still a symbolic link.

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
