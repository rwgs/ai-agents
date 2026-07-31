# A versioned skill pool and an installed set of tooling skills

Approach for the change currently in flight. Replaced when the next non-trivial
change begins, so anything that must outlive this change is promoted first:
decisions that constrain future work to `DECISIONS.md`, and verified facts that
change how the project is understood to `AGENTS.md` or `SPEC.md`.

## Problem

Two questions left open in `SPEC.md` and one gap found while answering them:

- The optional skill pool had no recorded location. It was in
  `~/OneDrive/Development/ai/skills-optional/`, a plain directory holding
  `forgejo-maintainer`, `hugo`, `infrastructure`, `linux-sysadmin`, `mdbook`,
  `podman-operator`, and `windows-sysadmin`. Nothing in either repository said so.
- `python-ai`, `rust-cli`, and `web-development` were installed on every machine
  without a decision either way.
- `python-ai` reads as a Python skill and covers only Python AI applications, so
  general Python work matched nothing while appearing covered.

## Constraints discovered

- Installed skills are symlinked, not copied: `scripts/install.sh` links
  `.agents/skills/<name>` into both `~/.agents/skills/` and `~/.claude/skills/`.
  A pull updates every machine, so the installed set needs no update mechanism and
  only the pool does.
- The pool directory is not a Git repository, so an adopting repository has no
  commit to record and drift cannot be computed at all.
- Reach against the eight repositories under `~/Development`: Rust one, JS/TS two,
  Python one. `fabled-lands` and `web-fabled-lands-dev` have no `package.json` at
  any depth, so `web-development` does not fire in two of the browser-facing
  projects.
- `web-development` already separates cleanly. Its "Browser and local server
  debugging" section names no JavaScript; every other section is lockfiles,
  `tsconfig.json`, ESLint, Prettier, Biome, or Vitest and Jest.
- `AGENTS.md` requires visual verification for UI changes and no skill supported
  it.
- `gh` is not installed on this machine, in Git Bash or in PowerShell, so a remote
  repository cannot be created from here.
- `docs/SKILLS.md` lists the installed set and `scripts/validate.sh` fails when
  that list and the directories drift, so both move together or neither does.

## Approach

- Build the pool as a local Git repository at `~/Development/ai-skills`, outside
  OneDrive so nothing syncs a `.git` directory. Move the seven pool skills in,
  add `rust-cli` and `python-ai`, and commit. Leave creating the private
  `rwgs/ai-skills` remote and the first push to be done where `gh` or the web UI
  is available.
- Add `python-scripting` to the installed set, shaped like `bash-scripting` and
  `powershell-scripting`: uv, virtual environments, ruff, pytest, type checking.
- Extract the browser and local-server rules from `web-development` into
  `web-verification`, installed and stack-agnostic. Cross-reference both ways, as
  `docs/SKILLS.md` requires for adjacent skills.
- Move the remaining `web-development` tooling to the pool as well, and promote its
  one destructive-mistake rule, detecting the package manager from the lockfile, to
  `ai-home/AGENTS.md`. Record the criterion that decides this, so the next language
  skill does not need a fresh argument.
- Update `docs/SKILLS.md`, `SPEC.md` (both unresolved questions close),
  `README.md`, `CHANGELOG.md`, and `TASKS.md` in the same change.

## Trade-offs

- The pool is a copy-and-record repository rather than a submodule. A submodule
  pins a commit without extra machinery but forces a fixed path in every adopting
  repository, and the recorded-commit approach reuses the drift reporting already
  planned for the baseline documents.
- `web-development` was kept installed at first, on the grounds that the split
  needed something to be judged by. That was a reach argument, and reach has no
  threshold; the criterion recorded instead is whether an agent reaches for the
  language as a tool or works in it because it is the stack. The first attempt is
  left visible in `DECISIONS.md` as a superseded entry rather than rewritten.
- Promoting the lockfile rule to global instructions rather than leaving it in the
  pooled skill trades one always-loaded line for coverage that no longer depends on
  a `.js` or `.ts` trigger. The rest of the skill is genuinely stack-bound.
- The installed set falls from nine to eight, and every language skill in it is now
  one an agent reaches for in any repository.
- `show-codex-reset-expiries` stays installed although it is tied to one product,
  because it was considered and kept.

## Verification

- `./scripts/validate.sh` under WSL, which checks the skill inventory against
  `docs/SKILLS.md`, every skill's front matter, and the installer integration test
  that needs symbolic links.
- `scripts/install.sh --dry-run` to confirm the two new skills link and the two
  removed ones are pruned rather than left behind.
- `git log` in the pool repository, to confirm the nine skills are committed
  before anything is deleted from OneDrive.
