#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
task_test_root="$(mktemp -d "${TMPDIR:-/tmp}/ai-install-test.XXXXXX")"
test_codex_home="$task_test_root/codex home"
test_agents_home="$task_test_root/agents home"
test_claude_home="$task_test_root/claude home"
test_user_home="$task_test_root/user home"
test_github_repo="$test_user_home/github/nested/project"

cleanup() {
  if [[ -d "$task_test_root" && "$(basename "$task_test_root")" == ai-install-test.* ]]; then
    rm -rf -- "$task_test_root"
  fi
}
trap cleanup EXIT

fail() {
  printf 'error: %s\n' "$1" >&2
  exit 1
}

assert_link() {
  local target="$1"
  local source="$2"

  [[ -L "$target" ]] || fail "expected symbolic link: $target"
  [[ "$(readlink "$target")" == "$source" ]] ||
    fail "unexpected link target: $target"
}

# The Claude settings assertions need a working interpreter. A non-functional
# python3 shim can sit on PATH, so confirm the candidate actually runs.
test_python=""
for python_candidate in python3 python; do
  if command -v "$python_candidate" >/dev/null 2>&1 &&
    "$python_candidate" --version >/dev/null 2>&1; then
    test_python="$python_candidate"
    break
  fi
done

mkdir -p "$test_codex_home"
mkdir -p "$test_claude_home"
mkdir -p "$test_github_repo/.git"
printf 'original global instructions\n' >"$test_codex_home/AGENTS.md"

# Seed real-looking Claude state so the merge is proven non-destructive.
cat >"$test_claude_home/settings.json" <<'EOF'
{
  "model": "opus[1m]",
  "permissions": {
    "allow": [
      "Bash(git add *)"
    ],
    "additionalDirectories": [
      "/tmp"
    ]
  }
}
EOF

HOME="$test_user_home" CODEX_HOME="$test_codex_home" AGENTS_HOME="$test_agents_home" CLAUDE_CONFIG_DIR="$test_claude_home" \
  "$repo_root/scripts/install.sh" >/dev/null

assert_link "$test_codex_home/AGENTS.md" "$repo_root/ai-home/AGENTS.md"
[[ -f "$test_codex_home/config.toml" && ! -L "$test_codex_home/config.toml" ]] ||
  fail "expected generated config file: $test_codex_home/config.toml"
grep -Fqx "[projects.\"$test_user_home/github\"]" "$test_codex_home/config.toml" ||
  fail "generated config does not trust the user GitHub root"
grep -Fqx "[projects.\"$test_github_repo\"]" "$test_codex_home/config.toml" ||
  fail "generated config does not trust a nested Git repository"
assert_link "$test_codex_home/rules" "$repo_root/ai-home/rules"
assert_link "$test_codex_home/ollama.config.toml" "$repo_root/ai-home/codex/ollama.config.toml"
assert_link "$test_codex_home/llamacpp.config.toml" "$repo_root/ai-home/codex/llamacpp.config.toml"

for skill_dir in "$repo_root"/.agents/skills/*; do
  [[ -d "$skill_dir" ]] || continue
  assert_link "$test_agents_home/skills/$(basename "$skill_dir")" "$skill_dir"
  assert_link "$test_claude_home/skills/$(basename "$skill_dir")" "$skill_dir"
done

assert_link "$test_claude_home/CLAUDE.md" "$repo_root/ai-home/AGENTS.md"

if [[ -n "$test_python" ]]; then
  [[ -f "$test_claude_home/settings.json" ]] ||
    fail "expected merged Claude settings: $test_claude_home/settings.json"

  "$test_python" - "$test_claude_home/settings.json" <<'PYTHON' || fail "Claude settings merge is not conservative"
import json
import pathlib
import sys

settings = json.loads(pathlib.Path(sys.argv[1]).read_text())
permissions = settings["permissions"]
allow = permissions["allow"]

assert settings["model"] == "opus[1m]", "unrelated setting was lost"
assert permissions["additionalDirectories"] == ["/tmp"], "additionalDirectories changed"
assert "deny" not in permissions and "ask" not in permissions, "absent keys were invented"
assert allow[0] == "Bash(git add *)", "existing allow entry was lost or reordered"
assert "Bash(rtk *)" in allow, "derived Bash rule missing"
assert "PowerShell(rtk *)" in allow, "derived PowerShell rule missing"
assert len(allow) == len(set(allow)), "merge introduced duplicates"
PYTHON

  claude_settings_before="$task_test_root/claude-settings-before.json"
  cp "$test_claude_home/settings.json" "$claude_settings_before"
fi

shopt -s nullglob
instruction_backups=("$test_codex_home"/backups/ai-*/AGENTS.md)
shopt -u nullglob
[[ ${#instruction_backups[@]} -eq 1 ]] ||
  fail "expected one AGENTS.md backup, found ${#instruction_backups[@]}"
[[ "$(sed -n '1p' "${instruction_backups[0]}")" == "original global instructions" ]] ||
  fail "AGENTS.md backup content changed"

link_fixture_dir="$task_test_root/link fixtures"
mkdir -p "$link_fixture_dir"
ln -s "$repo_root/ai-home/AGENTS.md" "$link_fixture_dir/managed instructions"
rm -- "$test_codex_home/AGENTS.md"
ln -s "../link fixtures/managed instructions" "$test_codex_home/AGENTS.md"
raw_instruction_target="$(readlink "$test_codex_home/AGENTS.md")"

HOME="$test_user_home" CODEX_HOME="$test_codex_home" AGENTS_HOME="$test_agents_home" CLAUDE_CONFIG_DIR="$test_claude_home" \
  "$repo_root/scripts/install.sh" >/dev/null
[[ "$(readlink "$test_codex_home/AGENTS.md")" == "$raw_instruction_target" ]] ||
  fail "idempotent install replaced an equivalent relative link"

shopt -s nullglob
instruction_backups=("$test_codex_home"/backups/ai-*/AGENTS.md)
shopt -u nullglob
[[ ${#instruction_backups[@]} -eq 1 ]] ||
  fail "idempotent install created another AGENTS.md backup"

if [[ -n "$test_python" ]]; then
  cmp -s "$claude_settings_before" "$test_claude_home/settings.json" ||
    fail "idempotent install changed the merged Claude settings"
fi

rm -- "$test_codex_home/rules"
ln -s "$repo_root/ai-home/rules/." "$test_codex_home/rules"
raw_rules_target="$(readlink "$test_codex_home/rules")"
HOME="$test_user_home" CODEX_HOME="$test_codex_home" AGENTS_HOME="$test_agents_home" CLAUDE_CONFIG_DIR="$test_claude_home" \
  "$repo_root/scripts/install.sh" >/dev/null
[[ "$(readlink "$test_codex_home/rules")" == "$raw_rules_target" ]] ||
  fail "idempotent install replaced an equivalent normalized link"

cycle_fixture_dir="$task_test_root/cycle fixtures"
mkdir -p "$cycle_fixture_dir"
ln -s "cycle-b" "$cycle_fixture_dir/cycle-a"
ln -s "cycle-a" "$cycle_fixture_dir/cycle-b"
rm -- "$test_codex_home/ollama.config.toml"
ln -s "../cycle fixtures/cycle-a" "$test_codex_home/ollama.config.toml"
cycle_error_log="$task_test_root/cycle-error.log"

HOME="$test_user_home" CODEX_HOME="$test_codex_home" AGENTS_HOME="$test_agents_home" CLAUDE_CONFIG_DIR="$test_claude_home" \
  "$repo_root/scripts/install.sh" >/dev/null 2>"$cycle_error_log"
grep -q '^error: too many symbolic-link hops:' "$cycle_error_log" ||
  fail "cyclic link did not report a bounded-resolution error"
assert_link "$test_codex_home/ollama.config.toml" "$repo_root/ai-home/codex/ollama.config.toml"

# Pruning: a link into this repository whose source is gone must be removed,
# while anything the installer did not create must survive. The stale link is
# fabricated rather than made by deleting a real skill, so the test never
# mutates the repository it is running from.
ln -s "$repo_root/.agents/skills/removed-skill" "$test_claude_home/skills/removed-skill"
mkdir -p "$test_claude_home/skills/handmade-skill"
foreign_dir="$task_test_root/foreign skills/foreign-skill"
mkdir -p "$foreign_dir"
ln -s "$foreign_dir" "$test_claude_home/skills/foreign-skill"
ln -s "$task_test_root/missing/foreign-orphan" "$test_claude_home/skills/foreign-orphan"

HOME="$test_user_home" CODEX_HOME="$test_codex_home" AGENTS_HOME="$test_agents_home" CLAUDE_CONFIG_DIR="$test_claude_home" \
  "$repo_root/scripts/install.sh" --dry-run >"$task_test_root/prune-dry-run.log" 2>&1
[[ -L "$test_claude_home/skills/removed-skill" ]] ||
  fail "dry-run pruned a stale skill link"
grep -q '^pruned stale skill link: ' "$task_test_root/prune-dry-run.log" ||
  fail "dry-run did not report the prune it would perform"

HOME="$test_user_home" CODEX_HOME="$test_codex_home" AGENTS_HOME="$test_agents_home" CLAUDE_CONFIG_DIR="$test_claude_home" \
  "$repo_root/scripts/install.sh" >/dev/null

[[ ! -L "$test_claude_home/skills/removed-skill" ]] ||
  fail "stale managed skill link was not pruned"
[[ -d "$test_claude_home/skills/handmade-skill" ]] ||
  fail "pruning removed a hand-made skill directory"
[[ -L "$test_claude_home/skills/foreign-skill" ]] ||
  fail "pruning removed a link pointing outside the repository"
[[ -L "$test_claude_home/skills/foreign-orphan" ]] ||
  fail "pruning removed a broken link the installer did not create"
[[ -d "$foreign_dir" ]] ||
  fail "pruning followed a link and deleted its target"

fake_bin="$task_test_root/fake bin"
plugin_log="$task_test_root/plugin-calls.log"
claude_plugin_log="$task_test_root/claude-plugin-calls.log"
mkdir -p "$fake_bin"
cat >"$fake_bin/codex" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$CODEX_PLUGIN_TEST_LOG"
EOF
cat >"$fake_bin/claude" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$CLAUDE_PLUGIN_TEST_LOG"
EOF
chmod +x "$fake_bin/codex" "$fake_bin/claude"

plugin_codex_home="$task_test_root/plugin codex"
plugin_agents_home="$task_test_root/plugin agents"
plugin_claude_home="$task_test_root/plugin claude"
HOME="$test_user_home" PATH="$fake_bin:$PATH" CODEX_PLUGIN_TEST_LOG="$plugin_log" \
  CLAUDE_PLUGIN_TEST_LOG="$claude_plugin_log" \
  CODEX_HOME="$plugin_codex_home" AGENTS_HOME="$plugin_agents_home" CLAUDE_CONFIG_DIR="$plugin_claude_home" \
  "$repo_root/scripts/install.sh" --plugins >/dev/null

expected_plugin_calls="$(sed 's/^/plugin add /' "$repo_root/codex-plugins.txt")"
actual_plugin_calls="$(sed -n '1,$p' "$plugin_log")"
[[ "$actual_plugin_calls" == "$expected_plugin_calls" ]] ||
  fail "installer did not install the expected Codex plugins"

# A Claude Code plugin needs its marketplace registered first, so each manifest
# entry must produce the marketplace add before the install.
expected_claude_calls="$(
  awk 'NF { printf "plugin marketplace add %s\nplugin install %s\n", $2, $1 }' \
    "$repo_root/claude-plugins.txt"
)"
actual_claude_calls="$(sed -n '1,$p' "$claude_plugin_log")"
[[ "$actual_claude_calls" == "$expected_claude_calls" ]] ||
  fail "installer did not install the expected Claude Code plugins"

# A machine with only one agent must still install that agent's plugins. The
# scenario needs Codex genuinely absent, so it is skipped where one is on PATH
# rather than asserted against an environment that cannot produce it.
if command -v codex >/dev/null 2>&1; then
  printf 'note: codex is installed; skipping the missing-agent scenario\n'
else
  one_agent_bin="$task_test_root/one agent bin"
  one_agent_log="$task_test_root/one-agent-plugin-calls.log"
  unused_codex_log="$task_test_root/unused-codex-calls.log"
  missing_codex_log="$task_test_root/missing-codex.log"
  mkdir -p "$one_agent_bin"
  cp "$fake_bin/claude" "$one_agent_bin/claude"

  HOME="$test_user_home" PATH="$one_agent_bin:$PATH" \
    CODEX_PLUGIN_TEST_LOG="$unused_codex_log" CLAUDE_PLUGIN_TEST_LOG="$one_agent_log" \
    CODEX_HOME="$task_test_root/one agent codex" AGENTS_HOME="$task_test_root/one agent agents" \
    CLAUDE_CONFIG_DIR="$task_test_root/one agent claude" \
    "$repo_root/scripts/install.sh" --plugins >/dev/null 2>"$missing_codex_log"

  grep -q '^warning: codex is not installed; skipping its plugins$' "$missing_codex_log" ||
    fail "a missing agent did not report a skip warning"
  [[ ! -e "$unused_codex_log" ]] || fail "installer invoked a missing agent"
  [[ "$(sed -n '1,$p' "$one_agent_log")" == "$expected_claude_calls" ]] ||
    fail "a missing Codex install blocked Claude Code plugin installation"
fi

dry_run_codex_home="$task_test_root/dry run codex"
dry_run_agents_home="$task_test_root/dry run agents"
dry_run_claude_home="$task_test_root/dry run claude"
dry_run_plugin_log="$task_test_root/dry-run-plugin-calls.log"
dry_run_claude_plugin_log="$task_test_root/dry-run-claude-plugin-calls.log"
HOME="$test_user_home" PATH="$fake_bin:$PATH" CODEX_PLUGIN_TEST_LOG="$dry_run_plugin_log" \
  CLAUDE_PLUGIN_TEST_LOG="$dry_run_claude_plugin_log" \
  CODEX_HOME="$dry_run_codex_home" AGENTS_HOME="$dry_run_agents_home" CLAUDE_CONFIG_DIR="$dry_run_claude_home" \
  "$repo_root/scripts/install.sh" --dry-run --plugins >/dev/null
[[ ! -e "$dry_run_codex_home" && ! -L "$dry_run_codex_home" ]] ||
  fail "dry-run created CODEX_HOME"
[[ ! -e "$dry_run_agents_home" && ! -L "$dry_run_agents_home" ]] ||
  fail "dry-run created AGENTS_HOME"
[[ ! -e "$dry_run_claude_home" && ! -L "$dry_run_claude_home" ]] ||
  fail "dry-run created CLAUDE_CONFIG_DIR"
[[ ! -e "$dry_run_plugin_log" ]] || fail "dry-run invoked Codex plugin installation"
[[ ! -e "$dry_run_claude_plugin_log" ]] ||
  fail "dry-run invoked Claude Code plugin installation"

control_user_home="$task_test_root/control user home"
control_repo="$control_user_home/github/bad"$'\n'"project"
control_codex_home="$task_test_root/control codex"
control_agents_home="$task_test_root/control agents"
control_claude_home="$task_test_root/control claude"
control_error_log="$task_test_root/control-error.log"
mkdir -p "$control_repo/.git"

if HOME="$control_user_home" CODEX_HOME="$control_codex_home" AGENTS_HOME="$control_agents_home" CLAUDE_CONFIG_DIR="$control_claude_home" \
  "$repo_root/scripts/install.sh" --dry-run >/dev/null 2>"$control_error_log"; then
  fail "installer accepted a project path containing a control character"
fi
grep -q '^error: project path contains unsupported control characters:' "$control_error_log" ||
  fail "installer did not report the invalid project path"
[[ ! -e "$control_codex_home" && ! -L "$control_codex_home" ]] ||
  fail "invalid project path changed CODEX_HOME"

printf 'installer integration test passed\n'
