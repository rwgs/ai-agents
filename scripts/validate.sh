#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
errors=0

# A non-functional python3 shim can sit on PATH, so confirm the candidate runs.
python_tool=""
for python_candidate in python3 python; do
  if command -v "$python_candidate" >/dev/null 2>&1 &&
    "$python_candidate" --version >/dev/null 2>&1; then
    python_tool="$python_candidate"
    break
  fi
done

fail() {
  printf 'error: %s\n' "$1" >&2
  errors=$((errors + 1))
}

required_files=(
  "AGENTS.md"
  "CHANGELOG.md"
  "CLAUDE.md"
  "DECISIONS.md"
  "PLAN.md"
  "README.md"
  "ROADMAP.md"
  "SPEC.md"
  "TASKS.md"
  "codex-plugins.txt"
  "claude-plugins.txt"
  "ai-home/AGENTS.md"
  "ai-home/codex/config.toml"
  "ai-home/codex/ollama.config.toml"
  "ai-home/codex/llamacpp.config.toml"
  "ai-home/rules/default.rules"
  "docs/AGENT_LAYOUT.md"
  "docs/RTK.md"
  "docs/SKILLS.md"
  "docs/WORKFLOW.md"
  "scripts/bootstrap.ps1"
  "scripts/bootstrap.sh"
  "scripts/install.ps1"
  "scripts/install.sh"
  "scripts/merge-agent-state.py"
  "scripts/test-install.ps1"
  "scripts/test-install.sh"
)

for relative in "${required_files[@]}"; do
  [[ -f "$repo_root/$relative" ]] || fail "missing $relative"
done

# CI is the one part of this repository that has to be written per Git host, so
# these are listed apart from the host-neutral files above rather than standing
# in for the definition of a valid repository. Supporting another host means
# adding its definition here, not renaming one of these.
required_host_files=(
  ".github/dependabot.yml"
  ".github/workflows/codeql.yml"
  ".github/workflows/validate.yml"
  "azure-pipelines.yml"
)

for relative in "${required_host_files[@]}"; do
  [[ -f "$repo_root/$relative" ]] || fail "missing host CI definition $relative"
done

selector='[a-z0-9][a-z0-9-]*@[a-z0-9][a-z0-9-]*'

# Both manifests ignore blank lines and lines whose first non-blank character is
# a hash, so each file can record its own format. The installers and both
# installer tests apply the same rule.
manifest_entries() {
  grep -Ev '^[[:space:]]*(#|$)' "$repo_root/$1" || true
}

# Codex resolves a selector against its built-in marketplaces, so a Codex entry
# is the selector alone. Claude Code registers no marketplace until its first
# interactive start, so a Claude entry also carries the marketplace source the
# installer must add before installing from it.
validate_plugin_manifest() {
  local manifest="$1"
  local pattern="$2"
  local entries count duplicates

  entries="$(manifest_entries "$manifest")"
  count="$(printf '%s\n' "$entries" | grep -c . || true)"

  if [[ "$count" -eq 0 ]]; then
    fail "$manifest contains no plugins"
    return
  fi

  if printf '%s\n' "$entries" | grep -Evq "$pattern"; then
    fail "$manifest contains an invalid plugin entry"
  fi

  duplicates="$(printf '%s\n' "$entries" | sort | uniq -d)"
  [[ -z "$duplicates" ]] || fail "$manifest contains duplicate plugins"
}

validate_plugin_manifest codex-plugins.txt "^$selector\$"
validate_plugin_manifest claude-plugins.txt "^$selector https://[^ ]+\.git\$"

# Superpowers is the one workflow plugin this repository installs, and it has to
# reach both agents or the two configurations diverge.
for plugin_manifest in codex-plugins.txt claude-plugins.txt; do
  grep -Eq "^superpowers@" "$repo_root/$plugin_manifest" ||
    fail "$plugin_manifest does not select the superpowers plugin"
done

if [[ -n "$python_tool" ]]; then
  # The Bash installer's merge is a Python program, so a syntax error in it
  # would only surface when someone installs.
  "$python_tool" -m py_compile "$repo_root/scripts/merge-agent-state.py" ||
    fail "scripts/merge-agent-state.py does not compile"
  rm -rf -- "$repo_root/scripts/__pycache__"

  for config_file in "$repo_root"/ai-home/codex/*.toml; do
    "$python_tool" -c 'import pathlib, sys, tomllib; tomllib.loads(pathlib.Path(sys.argv[1]).read_text())' "$config_file" ||
      fail "invalid TOML in ${config_file#"$repo_root"/}"
  done

  "$python_tool" -c 'import pathlib, sys, tomllib; config = tomllib.loads(pathlib.Path(sys.argv[1]).read_text()); raise SystemExit(config.get("features", {}).get("memories") is not True)' \
    "$repo_root/ai-home/codex/config.toml" ||
    fail "ai-home/codex/config.toml must enable features.memories"
fi

# The repository-local CLAUDE.md must bridge to AGENTS.md, because Claude Code
# does not read AGENTS.md and a divergent copy would drift. Surrounding prose is
# fine; the import must be on a line of its own for Claude Code to resolve it.
grep -qE '^[[:space:]]*@AGENTS\.md[[:space:]]*$' "$repo_root/CLAUDE.md" ||
  fail "CLAUDE.md must import AGENTS.md with a line containing only @AGENTS.md"

# Instructions belong in AGENTS.md so both agents get them. A CLAUDE.md that has
# grown past a short explanation is drifting back into a second source of truth.
claude_md_lines="$(grep -cv '^[[:space:]]*$' "$repo_root/CLAUDE.md")"
[[ "$claude_md_lines" -le 15 ]] ||
  fail "CLAUDE.md has $claude_md_lines lines; put instructions in AGENTS.md instead"

# Codex rejects the whole file when one line is malformed, and `codex execpolicy`
# is only available where Codex is installed, so the structure is checked here
# too. Every entry is one prefix_rule with a non-empty quoted pattern list and a
# known decision. The decisions are the three the rules documentation names and
# Codex CLI 0.153.0 accepts; `deny` and `ask` read like the right words and are
# both rejected by the parser.
while IFS= read -r rule_line; do
  [[ -n "$rule_line" ]] || continue
  fail "malformed rule in ai-home/rules/default.rules: $rule_line"
done <<<"$(
  grep -Ev '^[[:space:]]*(#|$)' "$repo_root/ai-home/rules/default.rules" |
    grep -Ev '^prefix_rule\(pattern=\["[^"]+"(, "[^"]+")*\], decision="(allow|prompt|forbidden)"\)$' ||
    true
)"

derived_rules="$(
  sed -n 's/^prefix_rule(pattern=\["\([^"]*\)"\], decision="allow")$/\1/p' \
    "$repo_root/ai-home/rules/default.rules"
)"
derived_count="$(printf '%s\n' "$derived_rules" | grep -c . || true)"

[[ "$derived_count" -gt 0 ]] ||
  fail "no Claude allow rules derive from ai-home/rules/default.rules"

printf '%s\n' "$derived_rules" | grep -Fqx rtk ||
  fail "derived Claude rules must include rtk"

if [[ -d "$repo_root/.codex/skills" ]]; then
  fail "legacy .codex/skills directory still exists"
fi

# The inventory is collected in a variable rather than printed, because a
# command substitution would run this in a subshell where every `fail` it makes
# increments a counter that is then discarded and the run exits 0.
skill_inventory=""

validate_skill_tree() {
  local tree="$1"
  local skill_dir skill_file skill_basename first_line skill_name

  for skill_dir in "$repo_root/$tree"/*; do
    [[ -d "$skill_dir" ]] || continue
    skill_file="$skill_dir/SKILL.md"
    skill_basename="$(basename "$skill_dir")"

    if [[ ! -f "$skill_file" ]]; then
      fail "missing ${skill_file#"$repo_root"/}"
      continue
    fi

    first_line="$(sed -n '1p' "$skill_file")"
    [[ "$first_line" == "---" ]] || fail "${skill_file#"$repo_root"/} has no YAML front matter"
    grep -q '^name: .\+' "$skill_file" || fail "${skill_file#"$repo_root"/} has no name"
    grep -q '^description: .\+' "$skill_file" || fail "${skill_file#"$repo_root"/} has no description"
    skill_name="$(sed -n 's/^name: //p' "$skill_file" | sed -n '1p')"
    [[ "$skill_name" == "$skill_basename" ]] ||
      fail "${skill_file#"$repo_root"/} name does not match its directory"
    ! grep -q '\[TODO:' "$skill_file" || fail "${skill_file#"$repo_root"/} contains TODO placeholders"
    skill_inventory+="$skill_basename"$'\n'
  done
}

documented_under() {
  # The sed expression is intentionally literal.
  # shellcheck disable=SC2016
  sed -n "/^## $1\$/,/^## /p" "$repo_root/docs/SKILLS.md" |
    sed -n 's/^- `\([^`]*\)`$/\1/p' |
    sort
}

validate_skill_tree .agents/skills
installed_skills="$(printf '%s' "$skill_inventory" | sort)"
skill_count="$(printf '%s\n' "$installed_skills" | grep -c . || true)"

[[ -n "$installed_skills" ]] || fail "no skills found under .agents/skills"

[[ "$(documented_under 'Repository skills')" == "$installed_skills" ]] ||
  fail "docs/SKILLS.md does not match .agents/skills"

for forbidden in auth.json history.jsonl installation_id state_5.sqlite goals_1.sqlite memories_1.sqlite; do
  [[ ! -e "$repo_root/$forbidden" ]] || fail "runtime file must not be tracked: $forbidden"
done

if command -v git >/dev/null 2>&1 &&
  git -C "$repo_root" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  if git -C "$repo_root" ls-files | grep -Eq '(^|/)(auth\.json|history\.jsonl|installation_id|.*\.sqlite(-shm|-wal)?)$'; then
    fail "tracked Codex runtime or credential files detected"
  fi

  # A shell script committed without the executable bit runs fine on a Windows
  # checkout and on a WSL DrvFs mount, which grant execute to everything, and
  # fails with "Permission denied" on Linux and macOS. The index mode is checked
  # rather than the file mode, because core.filemode is false on Windows.
  while IFS= read -r indexed_script; do
    [[ -n "$indexed_script" ]] || continue
    fail "tracked shell script is not executable: $indexed_script"
  done <<<"$(
    git -C "$repo_root" ls-files --stage -- '*.sh' |
      awk '$1 != "100755" { print $4 }'
  )"

  # .gitattributes checks every tracked file out with LF except *.ps1, and a
  # CRLF shell script fails on Linux and macOS with a syntax error. git grep
  # reads working-tree bytes; Git Bash's grep strips CR before matching. The
  # pattern is built with printf because Git Bash's Bash drops a $'\r' word,
  # which would leave an empty pattern that matches every line of every file.
  carriage_return="$(printf '\r')"

  while IFS= read -r carriage_return_file; do
    [[ -n "$carriage_return_file" ]] || continue
    fail "carriage return in tracked file: $carriage_return_file"
  done <<<"$(
    git -C "$repo_root" grep -I -l -e "$carriage_return" -- . ':(exclude)*.ps1' ||
      true
  )"
fi

if ! bash -n \
  "$repo_root/scripts/bootstrap.sh" \
  "$repo_root/scripts/install.sh" \
  "$repo_root/scripts/test-install.sh" \
  "$repo_root/scripts/validate.sh"; then
  fail "Bash syntax validation failed"
fi

# A skill can ship an executable, and a broken one only fails when a user runs
# the skill. Node is not required to install this repository, so the check runs
# where it is available; CI always has it.
if command -v node >/dev/null 2>&1; then
  while IFS= read -r script_file; do
    node --check "$script_file" ||
      fail "JavaScript syntax validation failed for ${script_file#"$repo_root"/}"
  done < <(find "$repo_root/.agents/skills" -name '*.mjs' -o -name '*.js' -type f)
fi

if command -v shellcheck >/dev/null 2>&1; then
  shellcheck \
    "$repo_root/scripts/bootstrap.sh" \
    "$repo_root/scripts/install.sh" \
    "$repo_root/scripts/test-install.sh" \
    "$repo_root/scripts/validate.sh" ||
    fail "ShellCheck failed"
fi

if command -v codex >/dev/null 2>&1; then
  policy_result="$(
    codex execpolicy check \
      --rules "$repo_root/ai-home/rules/default.rules" \
      rtk gain
  )" || fail "invalid ai-home/rules/default.rules"

  if [[ -n "${policy_result:-}" && -n "$python_tool" ]]; then
    "$python_tool" -c 'import json, sys; raise SystemExit(json.loads(sys.argv[1]).get("decision") != "allow")' \
      "$policy_result" || fail "default rules must allow rtk commands"
  fi
fi

if command -v pwsh >/dev/null 2>&1; then
  for powershell_file in \
    "$repo_root/scripts/install.ps1" \
    "$repo_root/scripts/test-install.ps1"; do
    # The PowerShell variables must not expand in Bash.
    # shellcheck disable=SC2016
    AI_POWERSHELL_FILE="$powershell_file" pwsh -NoProfile -Command \
      '$errors = $null; [void][System.Management.Automation.Language.Parser]::ParseFile($env:AI_POWERSHELL_FILE, [ref]$null, [ref]$errors); if ($errors.Count) { $errors | ForEach-Object { Write-Error $_ }; exit 1 }' ||
      fail "PowerShell syntax validation failed for ${powershell_file#"$repo_root"/}"
  done

  # Mirrors ShellCheck for the PowerShell installers. Skipped when the module is
  # absent; CI installs it. ShouldProcess is excluded because the installers
  # expose the documented -DryRun switch instead of -WhatIf.
  # The PowerShell variables must not expand in Bash.
  # shellcheck disable=SC2016
  if pwsh -NoProfile -Command \
    'exit ([bool](Get-Module -ListAvailable PSScriptAnalyzer) ? 0 : 1)' 2>/dev/null; then
    AI_SCRIPTS_DIR="$repo_root/scripts" pwsh -NoProfile -Command \
      '$f = @(Invoke-ScriptAnalyzer -Path $env:AI_SCRIPTS_DIR -Severity Warning, Error -ExcludeRule PSUseShouldProcessForStateChangingFunctions); if ($f.Count) { $f | Format-Table RuleName, ScriptName, Line, Message -AutoSize | Out-String -Width 200 | Write-Output; exit 1 }' ||
      fail "PSScriptAnalyzer reported findings"
  fi
fi

if ! bash "$repo_root/scripts/test-install.sh"; then
  fail "installer integration test failed"
fi

if [[ $errors -gt 0 ]]; then
  printf 'validation failed with %d error(s)\n' "$errors" >&2
  exit 1
fi

printf 'validation passed: %d skills checked\n' "$skill_count"
