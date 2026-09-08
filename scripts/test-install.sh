#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# Codex used to write approvals into this file through a link. Nothing the
# installer does may touch it now, so its contents are checked at the end.
repo_rules_checksum="$(cksum <"$repo_root/ai-home/rules/default.rules")"
# macOS sets TMPDIR with a trailing slash, so mktemp returns a path holding a
# doubled separator and the merge writes the collapsed form. Canonicalising here
# keeps the paths this test asserts on identical to the ones it installs with.
task_test_root="$(cd "$(mktemp -d "${TMPDIR:-/tmp}/ai-install-test.XXXXXX")" && pwd -P)"
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
mkdir -p "$test_codex_home/rules"
mkdir -p "$test_claude_home"
mkdir -p "$test_github_repo/.git"
printf 'original global instructions\n' >"$test_codex_home/AGENTS.md"

# Seed the Codex state a real machine has: marketplaces, plugin enablement, MCP
# servers, a desktop block, a trust entry outside the searched roots, and a
# setting whose value disagrees with the baseline. None of it may be lost.
cat >"$test_codex_home/config.toml" <<'EOF'
model = "gpt-5.6-sol"
model_verbosity = "medium"

[features]
js_repl = false

[marketplaces.openai-bundled]
enabled = true

[mcp_servers.node_repl]
command = 'node_repl.exe'

[projects.'/elsewhere/machine project']
trust_level = "trusted"

[desktop]
conversationDetailMode = "STEPS_PROSE"
EOF

# Codex records interactive approvals here, so the file is the machine's own.
cat >"$test_codex_home/rules/default.rules" <<'EOF'
prefix_rule(pattern=["git", "status"], decision="allow")
prefix_rule(pattern=["sed"], decision="allow")
EOF

# Seed real-looking Claude state so the merge is proven non-destructive.
cat >"$test_claude_home/settings.json" <<'EOF'
{
  "model": "opus[1m]",
  "permissions": {
    "allow": [
      "Bash(git add *)",
      "Bash(grep -n 'a&b' <c> *)"
    ],
    "additionalDirectories": [
      "/tmp"
    ]
  }
}
EOF

install_log="$task_test_root/install.log"
HOME="$test_user_home" CODEX_HOME="$test_codex_home" AGENTS_HOME="$test_agents_home" CLAUDE_CONFIG_DIR="$test_claude_home" \
  "$repo_root/scripts/install.sh" >"$install_log"

assert_link "$test_codex_home/AGENTS.md" "$repo_root/ai-home/AGENTS.md"
[[ -f "$test_codex_home/config.toml" && ! -L "$test_codex_home/config.toml" ]] ||
  fail "expected merged config file: $test_codex_home/config.toml"
grep -Fqx "[projects.\"$test_user_home/github\"]" "$test_codex_home/config.toml" ||
  fail "merged config does not trust the user GitHub root"
grep -Fqx "[projects.\"$test_github_repo\"]" "$test_codex_home/config.toml" ||
  fail "merged config does not trust a nested Git repository"
# The baseline asks before acting. Installing must never escalate a machine to
# Codex's unrestricted preset.
grep -Fqx 'sandbox_mode = "workspace-write"' "$test_codex_home/config.toml" ||
  fail "merged config does not sandbox writes to the workspace"
grep -Fqx 'approval_policy = "on-request"' "$test_codex_home/config.toml" ||
  fail "merged config does not ask for approval"
! grep -Fq 'danger-full-access' "$test_codex_home/config.toml" ||
  fail "merged config grants unrestricted access"

# Machine-owned Codex state survives the merge.
for machine_entry in \
  '[marketplaces.openai-bundled]' \
  '[mcp_servers.node_repl]' \
  '[desktop]' \
  "[projects.'/elsewhere/machine project']" \
  'js_repl = false'; do
  grep -Fqx "$machine_entry" "$test_codex_home/config.toml" ||
    fail "merge lost machine-owned config state: $machine_entry"
done
# A managed key the machine already sets differently is left alone and reported,
# because nothing proves this installer wrote it.
grep -Fqx 'model_verbosity = "medium"' "$test_codex_home/config.toml" ||
  fail "merge overwrote a machine-owned value"
grep -q '^preserved: .*model_verbosity = "medium"' "$install_log" ||
  fail "merge did not report the preserved machine-owned value"
# A managed key inside a table the machine already has joins that table.
grep -Fqx 'memories = true' "$test_codex_home/config.toml" ||
  fail "merge did not add a managed key to an existing table"

# Codex writes approvals into its rules directory, so the directory is the
# machine's and the curated rules are merged into its file.
[[ -d "$test_codex_home/rules" && ! -L "$test_codex_home/rules" ]] ||
  fail "expected a real rules directory: $test_codex_home/rules"
grep -Fqx 'prefix_rule(pattern=["git", "status"], decision="allow")' \
  "$test_codex_home/rules/default.rules" ||
  fail "merge lost an interactively approved rule"
grep -Fqx 'prefix_rule(pattern=["rtk"], decision="allow")' \
  "$test_codex_home/rules/default.rules" ||
  fail "merge did not add the curated rules"
[[ -f "$test_agents_home/ai-install-state.json" ]] ||
  fail "installer recorded no provenance state"

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
# The PowerShell installer has to normalise these characters, because Windows
# PowerShell 5.1 escapes them when it serializes JSON. Both platforms assert the
# same thing so the two installers cannot drift on it.
assert "Bash(grep -n 'a&b' <c> *)" in allow, "entry with escapable characters was rewritten"
assert "'a&b' <c>" in pathlib.Path(sys.argv[1]).read_text(), "merged file escaped literal characters"
assert "Bash(rtk *)" in allow, "derived Bash rule missing"
assert "PowerShell(rtk *)" in allow, "derived PowerShell rule missing"
assert len(allow) == len(set(allow)), "merge introduced duplicates"
PYTHON

  claude_settings_before="$task_test_root/claude-settings-before.json"
  cp "$test_claude_home/settings.json" "$claude_settings_before"
fi

config_before="$task_test_root/config-before.toml"
rules_before="$task_test_root/rules-before.rules"
cp "$test_codex_home/config.toml" "$config_before"
cp "$test_codex_home/rules/default.rules" "$rules_before"

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

cmp -s "$config_before" "$test_codex_home/config.toml" ||
  fail "idempotent install changed the merged Codex configuration"
cmp -s "$rules_before" "$test_codex_home/rules/default.rules" ||
  fail "idempotent install changed the merged Codex rules"

first_skill="$(basename "$(find "$repo_root/.agents/skills" -mindepth 1 -maxdepth 1 -type d | sort | head -n 1)")"
rm -- "$test_agents_home/skills/$first_skill"
ln -s "$repo_root/.agents/skills/$first_skill/." "$test_agents_home/skills/$first_skill"
raw_skill_target="$(readlink "$test_agents_home/skills/$first_skill")"
HOME="$test_user_home" CODEX_HOME="$test_codex_home" AGENTS_HOME="$test_agents_home" CLAUDE_CONFIG_DIR="$test_claude_home" \
  "$repo_root/scripts/install.sh" >/dev/null
[[ "$(readlink "$test_agents_home/skills/$first_skill")" == "$raw_skill_target" ]] ||
  fail "idempotent install replaced an equivalent normalized link"

# A previous installation linked the rules directory into this repository, and
# Codex then wrote its approvals there. Installing must undo that link and say
# where those approvals went, rather than adopting or discarding them.
rm -rf -- "$test_codex_home/rules"
ln -s "$repo_root/ai-home/rules" "$test_codex_home/rules"
migration_log="$task_test_root/migration.log"
HOME="$test_user_home" CODEX_HOME="$test_codex_home" AGENTS_HOME="$test_agents_home" CLAUDE_CONFIG_DIR="$test_claude_home" \
  "$repo_root/scripts/install.sh" >"$migration_log"
[[ -d "$test_codex_home/rules" && ! -L "$test_codex_home/rules" ]] ||
  fail "installer left the rules directory linked into this repository"
grep -q "^unlinked: $test_codex_home/rules -> " "$migration_log" ||
  fail "installer did not report unlinking the rules directory"
grep -q '^note: approvals recorded through that link are in ' "$migration_log" ||
  fail "installer did not report where approvals recorded through the link are"
grep -Fqx 'prefix_rule(pattern=["rtk"], decision="allow")' \
  "$test_codex_home/rules/default.rules" ||
  fail "the replacement rules file does not carry the curated rules"

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

# Both manifests ignore blank lines and lines whose first non-blank character is
# a hash, so the expected calls come from the entries alone.
expected_plugin_calls="$(
  awk '!/^[[:space:]]*(#|$)/ { print "plugin add " $0 }' "$repo_root/codex-plugins.txt"
)"
actual_plugin_calls="$(sed -n '1,$p' "$plugin_log")"
[[ "$actual_plugin_calls" == "$expected_plugin_calls" ]] ||
  fail "installer did not install the expected Codex plugins"

# A Claude Code plugin needs its marketplace registered first, so each manifest
# entry must produce the marketplace add before the install.
expected_claude_calls="$(
  awk '!/^[[:space:]]*(#|$)/ { printf "plugin marketplace add %s\nplugin install %s\n", $2, $1 }' \
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

if [[ -n "$test_python" ]]; then
  # Withdrawal and preservation are the ownership model's hard cases. They are
  # driven against the merge program directly, because reaching them through the
  # installer would mean editing this repository's own curated files while it
  # runs.
  provenance_root="$task_test_root/provenance"
  provenance_state="$provenance_root/state.json"
  provenance_config="$provenance_root/config.toml"
  provenance_rules="$provenance_root/default.rules"
  provenance_claude="$provenance_root/settings.json"
  curated_all="$provenance_root/curated-all.rules"
  curated_reduced="$provenance_root/curated-reduced.rules"
  mkdir -p "$provenance_root"

  cp "$repo_root/ai-home/rules/default.rules" "$curated_all"
  grep -v '^prefix_rule(pattern=\["\(jq\|sed\)"\], decision="allow")$' \
    "$curated_all" >"$curated_reduced"

  # sed is approved before the first merge, so the grant is the machine's even
  # though the curated set spells it identically. git status is never curated.
  cat >"$provenance_rules" <<'EOF'
prefix_rule(pattern=["git", "status"], decision="allow")
prefix_rule(pattern=["sed"], decision="allow")
EOF
  cat >"$provenance_claude" <<'EOF'
{
  "permissions": {
    "allow": [
      "Bash(sed *)"
    ]
  }
}
EOF

  merge_state() {
    "$test_python" "$repo_root/scripts/merge-agent-state.py" \
      --state "$provenance_state" \
      --config-source "$repo_root/ai-home/codex/config.toml" \
      --config-target "$provenance_config" \
      --rules-source "$1" \
      --rules-target "$provenance_rules" \
      --claude-target "$provenance_claude" \
      --trust-root "$provenance_root/github"
  }

  merge_state "$curated_all" >"$provenance_root/first.log"
  grep -Fqx 'prefix_rule(pattern=["jq"], decision="allow")' "$provenance_rules" ||
    fail "first merge did not add a curated rule"
  grep -Fq '"Bash(jq *)"' "$provenance_claude" ||
    fail "first merge did not add a derived permission"

  merge_state "$curated_reduced" >"$provenance_root/second.log"
  ! grep -Fqx 'prefix_rule(pattern=["jq"], decision="allow")' "$provenance_rules" ||
    fail "an uncurated rule this program added was not withdrawn"
  ! grep -Fq '"Bash(jq *)"' "$provenance_claude" ||
    fail "an uncurated permission this program added was not withdrawn"
  ! grep -Fq '"PowerShell(jq *)"' "$provenance_claude" ||
    fail "an uncurated permission this program added was not withdrawn"
  grep -Fqx 'prefix_rule(pattern=["sed"], decision="allow")' "$provenance_rules" ||
    fail "a rule approved before installation was withdrawn"
  grep -Fq '"Bash(sed *)"' "$provenance_claude" ||
    fail "a permission approved before installation was withdrawn"
  grep -q '^preserved: Bash(sed \*) is no longer curated' "$provenance_root/second.log" ||
    fail "the preserved identical permission was not reported"
  grep -Fqx 'prefix_rule(pattern=["git", "status"], decision="allow")' "$provenance_rules" ||
    fail "withdrawal removed a rule the machine wrote"

  # A managed key the machine has since changed is left as the machine set it.
  sed -i.bak 's/^approval_policy = "on-request"$/approval_policy = "never"/' "$provenance_config"
  rm -f -- "$provenance_config.bak"
  merge_state "$curated_all" >"$provenance_root/third.log"
  grep -Fqx 'approval_policy = "never"' "$provenance_config" ||
    fail "merge overwrote a managed key the machine changed"
  grep -q '^preserved: .*approval_policy changed since installation' \
    "$provenance_root/third.log" ||
    fail "merge did not report the managed key the machine changed"

  # Reverting to the recorded value hands the key back, so management resumes.
  sed -i.bak 's/^approval_policy = "never"$/approval_policy = "on-request"/' "$provenance_config"
  rm -f -- "$provenance_config.bak"
  merge_state "$curated_reduced" >"$provenance_root/fourth.log"
  grep -Fqx 'approval_policy = "on-request"' "$provenance_config" ||
    fail "merge lost a managed key after the machine reverted it"

  # Valid TOML this line-based merge cannot classify is preserved whole and
  # reported. Appending to it would declare a table twice and stop Codex from
  # starting, which is the opposite of preserving machine-owned settings. The
  # same two fixtures are in scripts/test-install.ps1.
  assert_unsupported_config() {
    local description="$1"
    local fixture="$2"
    local before

    printf '%s' "$fixture" >"$provenance_config"
    before="$(cksum <"$provenance_config")"
    merge_state "$curated_all" >"$provenance_root/unsupported.log"

    [[ "$(cksum <"$provenance_config")" == "$before" ]] ||
      fail "merge rewrote a config.toml holding $description"
    grep -Fq 'memories = false' "$provenance_config" ||
      fail "merge lost the machine's setting in a config.toml holding $description"
    grep -q '^preserved: .*cannot parse' "$provenance_root/unsupported.log" ||
      fail "merge did not report the unparsed line in a config.toml holding $description"
    "$test_python" -c 'import pathlib, sys, tomllib; tomllib.loads(pathlib.Path(sys.argv[1]).read_text())' \
      "$provenance_config" ||
      fail "merge left an unparseable config.toml holding $description"
  }

  assert_unsupported_config 'a table header with a trailing comment' \
    '[features] # local choices
memories = false
'
  assert_unsupported_config 'a dotted key' 'features.memories = false
'
fi

# The bootstrap clones and then installs from the clone. It is exercised against
# a local copy of this repository, so the test needs no network and never
# contacts the real remote.
bootstrap_origin="$task_test_root/origin.git"
bootstrap_install_dir="$task_test_root/bootstrap clone"
bootstrap_log="$task_test_root/bootstrap.log"
git clone --quiet --bare "$repo_root" "$bootstrap_origin"

# The bootstrap's own output goes to a log, so a failure has to reprint it or
# the run dies with nothing to read.
run_bootstrap() {
  AI_REPO_URL="$bootstrap_origin" AI_INSTALL_DIR="$bootstrap_install_dir" \
    AI_BRANCH="$(git -C "$repo_root" rev-parse --abbrev-ref HEAD)" \
    HOME="$test_user_home" CODEX_HOME="$task_test_root/bootstrap codex" \
    AGENTS_HOME="$task_test_root/bootstrap agents" \
    CLAUDE_CONFIG_DIR="$task_test_root/bootstrap claude" \
    "$repo_root/scripts/bootstrap.sh" --dry-run >"$bootstrap_log" 2>&1 || {
    cat "$bootstrap_log" >&2
    fail "bootstrap exited non-zero"
  }
}

run_bootstrap

[[ -f "$bootstrap_install_dir/scripts/install.sh" ]] ||
  fail "bootstrap did not clone the repository"
grep -q '^cloning ' "$bootstrap_log" || fail "bootstrap did not report the clone"
grep -q '^dry run complete$' "$bootstrap_log" ||
  fail "bootstrap did not run the installer from the clone"
[[ ! -e "$task_test_root/bootstrap codex" ]] ||
  fail "bootstrap dry run created CODEX_HOME"

# A rerun previews the update rather than performing it, because the installed
# links point into this clone. Upstream is moved first, so the assertion is about
# a real pending change and not about a rerun with nothing to fetch.
bootstrap_revision="$(git -C "$bootstrap_install_dir" rev-parse HEAD)"
bootstrap_upstream="$task_test_root/upstream"
git clone --quiet "$bootstrap_origin" "$bootstrap_upstream"
printf 'version two\n' >>"$bootstrap_upstream/ai-home/AGENTS.md"
git -C "$bootstrap_upstream" -c user.name=test -c user.email=test@example.com \
  commit --quiet --all --message 'move upstream'
git -C "$bootstrap_upstream" push --quiet origin HEAD

# Asserted rather than assumed: a dry run that changes nothing proves nothing
# unless there was something upstream for it to have pulled in.
[[ "$(git -C "$bootstrap_origin" rev-parse HEAD)" != "$bootstrap_revision" ]] ||
  fail "the upstream fixture did not move"

run_bootstrap

grep -q "^would update $bootstrap_install_dir to " "$bootstrap_log" ||
  fail "bootstrap rerun did not report the update it would make"
grep -q '^dry run complete$' "$bootstrap_log" ||
  fail "bootstrap rerun did not run the installer"
[[ "$(git -C "$bootstrap_install_dir" rev-parse HEAD)" == "$bootstrap_revision" ]] ||
  fail "bootstrap dry run moved the installed clone"
! grep -q '^version two$' "$bootstrap_install_dir/ai-home/AGENTS.md" ||
  fail "bootstrap dry run changed what the agents read"

[[ "$(cksum <"$repo_root/ai-home/rules/default.rules")" == "$repo_rules_checksum" ]] ||
  fail "the installer wrote into this repository's curated rule file"

printf 'installer integration test passed\n'
