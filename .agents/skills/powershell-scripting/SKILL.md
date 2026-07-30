---
name: powershell-scripting
description: Design, implement, review, test, and debug PowerShell scripts and modules with strict mode, approved verbs, PSScriptAnalyzer, safe JSON and path handling, and predictable cross-platform behavior. Use when asked to create or modify .ps1 or .psm1 files, automate Windows workflows, fix PowerShell bugs, improve script safety, or validate Windows and CI PowerShell scripts.
---

# powershell-scripting

## Workflow

1. Inspect repository instructions, the target PowerShell edition, callers, and
   supported platforms.
2. Decide whether the script must run on Windows PowerShell 5.1 or may require
   PowerShell 7+.
3. Identify inputs, side effects, privilege needs, failure behavior, and cleanup.
4. Implement the smallest maintainable change using existing project helpers.
5. Validate syntax, static analysis, and representative success and failure
   paths.

## Edition selection

- PowerShell 7+ provides `&&` and `||`, ternary, null-coalescing,
  `ConvertFrom-Json -AsHashtable`, and UTF-8 without BOM by default.
- Windows PowerShell 5.1 has none of those. Do not use them in a script that
  must run there.
- Preserve the repository's existing edition target unless the task requires
  changing it.

## Implementation rules

- Start scripts with `Set-StrictMode -Version Latest` and
  `$ErrorActionPreference = 'Stop'` so typos and failures surface immediately.
- Use approved verbs. `Get-Verb` lists them. `Ensure`, `Link`, and `Check` are
  not approved; `New`, `Set`, and `Test` are.
- Use singular nouns in function names, even when the function returns a
  collection.
- Use `-LiteralPath` when a path may contain `[`, `]`, or other wildcard
  characters.
- Use `Join-Path` rather than string concatenation, and
  `[System.IO.Path]::GetFullPath` to normalize before comparing paths.
- Compare paths case-insensitively on Windows with
  `[StringComparison]::OrdinalIgnoreCase`.
- Pass `-Depth 100` to `ConvertTo-Json`. The default depth of 2 silently
  truncates nested structures.
- Use `ConvertFrom-Json -AsHashtable` when round-tripping data that must keep
  keys the script does not know about.
- Never edit JSON or XML by regular expression. Parse, modify, and re-emit.
- Write files with `[System.Text.UTF8Encoding]::new($false)` when a BOM would
  break another consumer.
- Return nonzero for failures. Check `$LASTEXITCODE` after calling a native
  executable, because `$ErrorActionPreference` does not apply to it.
- Use `-Confirm:$false` on destructive cmdlets that would otherwise prompt, and
  never use `Read-Host`, `Get-Credential`, or `Out-GridView` in automation.
- Prefer a `-DryRun` or `-WhatIf` preview for scripts that change system state,
  and make sure the preview path creates nothing.

## Cross-platform pitfalls

- Creating a symbolic link on Windows requires Developer Mode or an elevated
  session. Catch the failure and explain the requirement rather than letting a
  raw exception surface.
- Scripts stored with CRLF endings fail on Linux and macOS. Keep `.sh` files LF
  and pin line endings in `.gitattributes`.
- `ConvertTo-Json` output formatting differs from other JSON writers. Do not
  assume byte-identical output when comparing against a file written elsewhere.
- A non-functional `python3` shim can sit on `PATH` on Windows. Confirm an
  interpreter runs before depending on it.

## Diagnostics

```powershell
$errors = $null
[System.Management.Automation.Language.Parser]::ParseFile($path, [ref]$null, [ref]$errors)

Install-Module PSScriptAnalyzer -Scope CurrentUser
Invoke-ScriptAnalyzer -Path scripts -Severity Warning, Error
Invoke-ScriptAnalyzer -Path scripts -ExcludeRule PSUseShouldProcessForStateChangingFunctions
Get-Verb
```

Parse checking catches syntax errors without executing the script, which matters
for a script whose top-level code changes the system.

## Validation

- The script parses without errors under the target edition.
- PSScriptAnalyzer has no unresolved actionable findings. Document any excluded
  rule and the reason.
- Paths containing spaces, brackets, and non-ASCII characters are handled.
- Preview mode creates and modifies nothing.
- Native command failures are detected through `$LASTEXITCODE`.
- Destructive, privileged, and network operations are tested safely or clearly
  identified as untested.
