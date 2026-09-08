#!/usr/bin/env bash
# Clone or update this repository, then run its installer from the clone.
#
# The installer links into the clone, so the clone is not temporary: it is where
# the managed instructions, rules, and skills live afterwards. Moving or deleting
# it breaks every link, which is why this script clones to a fixed location and
# updates that same location on a rerun.
set -euo pipefail

repo_url="${AI_REPO_URL:-https://github.com/rwgs/ai.git}"
install_dir="${AI_INSTALL_DIR:-$HOME/.local/share/ai}"
branch="${AI_BRANCH:-main}"

if ! command -v git >/dev/null 2>&1; then
  printf 'error: git is required\n' >&2
  exit 1
fi

# A token is only needed while the repository is private, and it is passed per
# command rather than written into the remote URL, so it never lands in
# .git/config where every later fetch would leak it.
git_arguments=()
if [[ -n "${AI_GIT_TOKEN:-}" ]]; then
  authorization="$(printf 'x-access-token:%s' "$AI_GIT_TOKEN" | base64 | tr -d '\n')"
  git_arguments=(-c "http.extraheader=Authorization: Basic $authorization")
fi

# macOS ships Bash 3.2, where expanding an empty array under `set -u` is an
# unbound-variable error, so the empty case never expands the array at all.
authenticated_git() {
  if ((${#git_arguments[@]} > 0)); then
    git "${git_arguments[@]}" "$@"
  else
    git "$@"
  fi
}

# The installed links point into this clone, so the clone is part of the target
# system a dry run must not change. Fetching only writes remote-tracking refs,
# which no agent reads, and it is what lets the preview name the revision an
# install would move to.
dry_run=""
for argument in "$@"; do
  [[ "$argument" == "--dry-run" ]] && dry_run="yes"
done

if [[ -d "$install_dir/.git" ]]; then
  authenticated_git -C "$install_dir" fetch --quiet origin "$branch"

  if [[ -n "$dry_run" ]]; then
    printf 'would update %s to %s\n' \
      "$install_dir" "$(git -C "$install_dir" rev-parse --short "origin/$branch")"
  else
    printf 'updating %s\n' "$install_dir"
    git -C "$install_dir" checkout --quiet "$branch"
    # Fast-forward only: a local edit or a rewritten history stops the run instead
    # of being merged or discarded.
    git -C "$install_dir" merge --ff-only --quiet "origin/$branch"
  fi
else
  printf 'cloning %s into %s\n' "$repo_url" "$install_dir"
  mkdir -p "$(dirname "$install_dir")"
  authenticated_git clone --quiet --branch "$branch" "$repo_url" "$install_dir"
fi

printf 'installing from %s at %s\n' \
  "$install_dir" "$(git -C "$install_dir" rev-parse --short HEAD)"

# Every remaining argument belongs to the installer, so --dry-run and --plugins
# work exactly as they do when it is run directly.
exec "$install_dir/scripts/install.sh" "$@"
