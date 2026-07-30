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
  "CLAUDE.md"
  "PLAN.md"
  "README.md"
  "ROADMAP.md"
  "SPEC.md"
  "TASKS.md"
  "codex-plugins.txt"
  "ai-home/AGENTS.md"
  "ai-home/codex/config.toml"
  "ai-home/codex/ollama.config.toml"
  "ai-home/codex/llamacpp.config.toml"
  "ai-home/codex/rules/default.rules"
  "docs/AGENT_LAYOUT.md"
  "docs/RTK.md"
  "docs/SKILLS.md"
  "docs/WORKFLOW.md"
  ".github/dependabot.yml"
  ".github/pull_request_template.md"
  ".github/workflows/validate.yml"
  "scripts/install.ps1"
  "scripts/install.sh"
  "scripts/test-install.ps1"
  "scripts/test-install.sh"
)

for relative in "${required_files[@]}"; do
  [[ -f "$repo_root/$relative" ]] || fail "missing $relative"
done

if grep -Evq '^[a-z0-9][a-z0-9-]*@[a-z0-9][a-z0-9-]*$' "$repo_root/codex-plugins.txt"; then
  fail "codex-plugins.txt contains an invalid plugin selector"
fi

plugin_count="$(grep -Ec '^[a-z0-9][a-z0-9-]*@[a-z0-9][a-z0-9-]*$' "$repo_root/codex-plugins.txt" || true)"
[[ "$plugin_count" -gt 0 ]] || fail "codex-plugins.txt contains no plugins"

duplicate_plugins="$(sort "$repo_root/codex-plugins.txt" | uniq -d)"
[[ -z "$duplicate_plugins" ]] || fail "codex-plugins.txt contains duplicate plugins"

if [[ -n "$python_tool" ]]; then
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

derived_rules="$(
  sed -n 's/^prefix_rule(pattern=\["\([^"]*\)"\], decision="allow")$/\1/p' \
    "$repo_root/ai-home/codex/rules/default.rules"
)"
derived_count="$(printf '%s\n' "$derived_rules" | grep -c . || true)"

[[ "$derived_count" -gt 0 ]] ||
  fail "no Claude allow rules derive from ai-home/codex/rules/default.rules"

printf '%s\n' "$derived_rules" | grep -Fqx rtk ||
  fail "derived Claude rules must include rtk"

if [[ -d "$repo_root/.codex/skills" ]]; then
  fail "legacy .codex/skills directory still exists"
fi

# Optional skills are validated like installed ones so they do not rot while
# unused, but they are listed under a different heading and never installed.
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
    printf '%s\n' "$skill_basename"
  done
}

documented_under() {
  # The sed expression is intentionally literal.
  # shellcheck disable=SC2016
  sed -n "/^## $1\$/,/^## /p" "$repo_root/docs/SKILLS.md" |
    sed -n 's/^- `\([^`]*\)`$/\1/p' |
    sort
}

installed_skills="$(validate_skill_tree .agents/skills | sort)"
optional_skills="$(validate_skill_tree skills-optional | sort)"

# Counted here rather than inside the function, because command substitution
# runs it in a subshell where an incremented counter would be discarded.
skill_count="$((
  $(printf '%s\n' "$installed_skills" | grep -c .) +
  $(printf '%s\n' "$optional_skills" | grep -c .)
))"

[[ -n "$installed_skills" ]] || fail "no skills found under .agents/skills"

[[ "$(documented_under 'Repository skills')" == "$installed_skills" ]] ||
  fail "docs/SKILLS.md does not match .agents/skills"
[[ "$(documented_under 'Optional skills')" == "$optional_skills" ]] ||
  fail "docs/SKILLS.md does not match skills-optional"

# An optional skill must not also be installed, or the installer would link a
# skill the documentation says is unavailable.
duplicate_skills="$(comm -12 <(printf '%s\n' "$installed_skills") <(printf '%s\n' "$optional_skills"))"
[[ -z "$duplicate_skills" ]] ||
  fail "skills present in both .agents/skills and skills-optional: $duplicate_skills"

for forbidden in auth.json history.jsonl installation_id state_5.sqlite goals_1.sqlite memories_1.sqlite; do
  [[ ! -e "$repo_root/$forbidden" ]] || fail "runtime file must not be tracked: $forbidden"
done

if command -v git >/dev/null 2>&1 &&
  git -C "$repo_root" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  if git -C "$repo_root" ls-files | grep -Eq '(^|/)(auth\.json|history\.jsonl|installation_id|.*\.sqlite(-shm|-wal)?)$'; then
    fail "tracked Codex runtime or credential files detected"
  fi
fi

if ! bash -n \
  "$repo_root/scripts/install.sh" \
  "$repo_root/scripts/test-install.sh" \
  "$repo_root/scripts/validate.sh"; then
  fail "Bash syntax validation failed"
fi

if command -v shellcheck >/dev/null 2>&1; then
  shellcheck \
    "$repo_root/scripts/install.sh" \
    "$repo_root/scripts/test-install.sh" \
    "$repo_root/scripts/validate.sh" ||
    fail "ShellCheck failed"
fi

if command -v codex >/dev/null 2>&1; then
  policy_result="$(
    codex execpolicy check \
      --rules "$repo_root/ai-home/codex/rules/default.rules" \
      rtk gain
  )" || fail "invalid ai-home/codex/rules/default.rules"

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
