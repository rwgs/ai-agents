#!/usr/bin/env bash
set -euo pipefail

dry_run=false
install_plugins=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      dry_run=true
      ;;
    --plugins)
      install_plugins=true
      ;;
    *)
      printf 'usage: %s [--dry-run] [--plugins]\n' "$0" >&2
      exit 2
      ;;
  esac
  shift
done

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
codex_home="${CODEX_HOME:-$HOME/.codex}"
agents_home="${AGENTS_HOME:-$HOME/.agents}"
claude_home="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
timestamp="$(date +%Y%m%d-%H%M%S)"
backup_root="$codex_home/backups/ai-$timestamp-$$"
codex_plugin_manifest="$repo_root/codex-plugins.txt"
claude_plugin_manifest="$repo_root/claude-plugins.txt"
config_source="$repo_root/ai-home/codex/config.toml"
rules_source="$repo_root/ai-home/rules/default.rules"
claude_settings="$claude_home/settings.json"
merge_program="$repo_root/scripts/merge-agent-state.py"
state_file="$agents_home/ai-install-state.json"
# Repositories do not all live under ~/github, and a trust entry is generated per
# exact worktree, so the roots to search are configurable. AI_TRUST_ROOTS holds a
# colon-separated list.
trust_roots="${AI_TRUST_ROOTS:-$HOME/github}"
python_tool=""

if "$install_plugins"; then
  for manifest in "$codex_plugin_manifest" "$claude_plugin_manifest"; do
    if [[ ! -f "$manifest" ]]; then
      printf 'error: plugin manifest does not exist: %s\n' "$manifest" >&2
      exit 1
    fi
  done
fi

run() {
  if "$dry_run"; then
    printf '+'
    printf ' %q' "$@"
    printf '\n'
  else
    "$@"
  fi
}

ensure_parent() {
  run mkdir -p "$(dirname "$1")"
}

resolve_path() {
  local path="$1"
  local directory
  local hops=0
  local link_target

  while [[ -L "$path" ]]; do
    hops=$((hops + 1))
    if ((hops > 64)); then
      printf 'error: too many symbolic-link hops: %s\n' "$1" >&2
      return 2
    fi

    if ! directory="$(cd -P "$(dirname "$path")" && pwd)"; then
      return 1
    fi
    if ! link_target="$(readlink "$path")"; then
      return 1
    fi
    if [[ "$link_target" == /* ]]; then
      path="$link_target"
    else
      path="$directory/$link_target"
    fi
  done

  if [[ -d "$path" ]]; then
    if ! directory="$(cd -P "$path" && pwd)"; then
      return 1
    fi
    printf '%s\n' "$directory"
    return
  fi

  if ! directory="$(cd -P "$(dirname "$path")" && pwd)"; then
    return 1
  fi
  printf '%s/%s\n' "$directory" "$(basename "$path")"
}

backup_path_for() {
  local target="$1"

  case "$target" in
    "$codex_home"/*) printf '%s/%s\n' "$backup_root" "${target#"$codex_home"/}" ;;
    "$agents_home"/*) printf '%s/agents/%s\n' "$backup_root" "${target#"$agents_home"/}" ;;
    "$claude_home"/*) printf '%s/claude/%s\n' "$backup_root" "${target#"$claude_home"/}" ;;
    *)
      printf 'error: managed target is outside the managed homes: %s\n' "$target" >&2
      exit 1
      ;;
  esac
}

link_managed_path() {
  local source="$1"
  local target="$2"

  if [[ ! -e "$source" ]]; then
    printf 'error: managed source does not exist: %s\n' "$source" >&2
    exit 1
  fi

  ensure_parent "$target"

  if [[ -L "$target" ]]; then
    local resolved_source
    local resolved_target=""
    local resolve_status=0

    if ! resolved_source="$(resolve_path "$source")"; then
      return 1
    fi

    if resolved_target="$(resolve_path "$target")"; then
      resolve_status=0
    else
      resolve_status=$?
    fi

    if ((resolve_status != 0 && resolve_status != 2)); then
      return "$resolve_status"
    fi

    if ((resolve_status == 0)) && [[ "$resolved_target" == "$resolved_source" ]]; then
      printf 'already linked: %s\n' "$target"
      return
    fi
  fi

  if [[ -e "$target" || -L "$target" ]]; then
    ensure_parent "$(backup_path_for "$target")"
    run mv "$target" "$(backup_path_for "$target")"
    printf 'backed up: %s -> %s\n' "$target" "$(backup_path_for "$target")"
  fi

  run ln -s "$source" "$target"
  printf 'linked: %s -> %s\n' "$target" "$source"
}

select_python() {
  local candidate

  for candidate in python3 python; do
    command -v "$candidate" >/dev/null 2>&1 || continue
    # A non-functional python3 shim can sit on PATH, so confirm it actually runs.
    "$candidate" --version >/dev/null 2>&1 || continue
    python_tool="$candidate"
    return
  done
}

# Codex writes interactive approvals into its rules directory, so that directory
# cannot be a link into this repository. An installation that made one is undone
# here, and the approvals it captured are left where they landed rather than
# adopted or discarded.
prepare_rules_directory() {
  local rules_dir="$codex_home/rules"
  local link_target

  if [[ -L "$rules_dir" ]]; then
    link_target="$(readlink "$rules_dir")"
    ensure_parent "$(backup_path_for "$rules_dir")"
    run mv "$rules_dir" "$(backup_path_for "$rules_dir")"
    printf 'unlinked: %s -> %s\n' "$rules_dir" "$(backup_path_for "$rules_dir")"

    if [[ "$link_target" == "$repo_root"/* ]]; then
      printf 'note: approvals recorded through that link are in %s; review them there\n' \
        "$link_target"
    fi

    return 0
  fi

  return 1
}

merge_agent_state() {
  local rules_dir="$codex_home/rules"
  local fresh_rules=false
  local -a arguments=()
  local root

  select_python

  if [[ -z "$python_tool" ]]; then
    printf 'warning: python3 is required to merge %s, %s, and %s; skipping\n' \
      "$codex_home/config.toml" "$rules_dir/default.rules" "$claude_settings" >&2
    return
  fi

  if prepare_rules_directory; then
    # A dry run leaves the link in place, so the merge must not read the
    # repository's own rules back through it.
    "$dry_run" && fresh_rules=true
  fi

  run mkdir -p "$rules_dir"

  arguments=(
    --state "$state_file"
    --backup-dir "$backup_root"
    --config-source "$config_source"
    --config-target "$codex_home/config.toml"
    --rules-source "$rules_source"
    --rules-target "$rules_dir/default.rules"
    --claude-target "$claude_settings"
  )

  while IFS= read -r root; do
    [[ -n "$root" ]] || continue
    arguments+=(--trust-root "$root")
  done <<<"${trust_roots//:/$'\n'}"

  "$fresh_rules" && arguments+=(--rules-fresh)
  "$dry_run" && arguments+=(--dry-run)

  "$python_tool" "$merge_program" "${arguments[@]}"
}

prune_managed_skills() {
  local skills_dir="$1"
  local entry link_target

  [[ -d "$skills_dir" ]] || return 0

  for entry in "$skills_dir"/*; do
    # Only ever consider links this installer could have created. A real
    # directory, or a link pointing anywhere else, belongs to the user.
    [[ -L "$entry" ]] || continue

    link_target="$(readlink "$entry")" || continue
    [[ "$link_target" == "$repo_root/.agents/skills/"* ]] || continue

    # The source is gone, so the skill was removed or made optional.
    [[ -e "$link_target" ]] && continue

    run rm -f -- "$entry"
    printf 'pruned stale skill link: %s\n' "$entry"
  done
}

agent_is_available() {
  local agent="$1"

  # A dry run only prints what it would do, so a missing agent is not a problem.
  if "$dry_run" || command -v "$agent" >/dev/null 2>&1; then
    return 0
  fi

  printf 'warning: %s is not installed; skipping its plugins\n' "$agent" >&2
  return 1
}

# Both manifests ignore blank lines and lines whose first non-blank character is
# a hash, so each file can record why its own format differs from the other's.
is_manifest_entry() {
  [[ ! "$1" =~ ^[[:space:]]*(#|$) ]]
}

install_codex_plugins() {
  local plugin

  agent_is_available codex || return 0

  while IFS= read -r plugin || [[ -n "$plugin" ]]; do
    is_manifest_entry "$plugin" || continue
    # Codex ships openai-curated as a built-in marketplace, so a plugin from it
    # needs no registration step.
    run codex plugin add "$plugin"
  done <"$codex_plugin_manifest"
}

install_claude_plugins() {
  local line selector source

  agent_is_available claude || return 0

  while IFS= read -r line || [[ -n "$line" ]]; do
    is_manifest_entry "$line" || continue
    read -r selector source <<<"$line"

    if [[ -z "$source" ]]; then
      printf 'error: Claude Code plugin entry has no marketplace source: %s\n' \
        "$selector" >&2
      exit 1
    fi

    # Claude Code registers no marketplace until its first interactive start, so
    # an installer that runs before that must add the source itself. The URL is
    # spelled out because owner/repo shorthand resolves over SSH. Both commands
    # are idempotent, so a rerun re-clones and reinstalls nothing.
    run claude plugin marketplace add "$source"
    run claude plugin install "$selector"
  done <"$claude_plugin_manifest"
}

link_managed_path "$repo_root/ai-home/AGENTS.md" "$codex_home/AGENTS.md"

for profile in "$repo_root"/ai-home/codex/*.config.toml; do
  [[ -f "$profile" ]] || continue
  link_managed_path "$profile" "$codex_home/$(basename "$profile")"
done

link_managed_path "$repo_root/ai-home/AGENTS.md" "$claude_home/CLAUDE.md"
merge_agent_state

for skill_dir in "$repo_root"/.agents/skills/*; do
  [[ -d "$skill_dir" ]] || continue
  link_managed_path "$skill_dir" "$agents_home/skills/$(basename "$skill_dir")"
  link_managed_path "$skill_dir" "$claude_home/skills/$(basename "$skill_dir")"
done

prune_managed_skills "$agents_home/skills"
prune_managed_skills "$claude_home/skills"

if "$install_plugins"; then
  install_codex_plugins
  install_claude_plugins
fi

if "$dry_run"; then
  printf 'dry run complete\n'
else
  printf 'installation complete. Restart Codex and Claude Code to reload configuration.\n'
fi
