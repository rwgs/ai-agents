[CmdletBinding()]
param(
    [Alias('dry-run')]
    [switch] $DryRun,

    [switch] $Plugins
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$userHome = if ($env:USERPROFILE) {
    $env:USERPROFILE
}
elseif ($env:HOME) {
    $env:HOME
}
else {
    [Environment]::GetFolderPath([Environment+SpecialFolder]::UserProfile)
}
$codexHome = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $userHome '.codex' }
$agentsHome = if ($env:AGENTS_HOME) { $env:AGENTS_HOME } else { Join-Path $userHome '.agents' }
$claudeHome = if ($env:CLAUDE_CONFIG_DIR) { $env:CLAUDE_CONFIG_DIR } else { Join-Path $userHome '.claude' }
$codexHome = [System.IO.Path]::GetFullPath($codexHome)
$agentsHome = [System.IO.Path]::GetFullPath($agentsHome)
$claudeHome = [System.IO.Path]::GetFullPath($claudeHome)
$userHome = [System.IO.Path]::GetFullPath($userHome)
$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$backupRoot = Join-Path $codexHome "backups/ai-$timestamp-$PID"
$codexPluginManifest = Join-Path $repoRoot 'codex-plugins.txt'
$claudePluginManifest = Join-Path $repoRoot 'claude-plugins.txt'
$configSource = Join-Path $repoRoot 'ai-home/codex/config.toml'
$rulesSource = Join-Path $repoRoot 'ai-home/rules/default.rules'
$claudeSettings = Join-Path $claudeHome 'settings.json'
$stateFile = Join-Path $agentsHome 'ai-install-state.json'
$stateVersion = 1
# Repositories do not all live under ~/github, and a trust entry is generated per
# exact worktree, so the roots to search are configurable. AI_TRUST_ROOTS holds a
# semicolon-separated list.
$trustRoots = if ($env:AI_TRUST_ROOTS) {
    @($env:AI_TRUST_ROOTS -split ';' | Where-Object { $_ })
}
else {
    @((Join-Path $userHome 'github'))
}
$script:mergeReport = [System.Collections.Generic.List[string]]::new()

if ($Plugins) {
    foreach ($manifest in @($codexPluginManifest, $claudePluginManifest)) {
        if (-not (Test-Path -LiteralPath $manifest -PathType Leaf)) {
            throw "Plugin manifest does not exist: $manifest"
        }
    }
}

function Write-DryRunCommand {
    param(
        [Parameter(Mandatory)]
        [string] $Command
    )

    if ($DryRun) {
        Write-Output "+ $Command"
    }
}

function New-ManagedDirectory {
    param(
        [Parameter(Mandatory)]
        [string] $Path
    )

    if (Test-Path -LiteralPath $Path -PathType Container) {
        return
    }

    if ($DryRun) {
        Write-DryRunCommand "New-Item -ItemType Directory -Path '$Path'"
        return
    }

    New-Item -ItemType Directory -Path $Path -Force | Out-Null
}

function Get-NormalizedPath {
    param(
        [Parameter(Mandatory)]
        [string] $Path
    )

    return [System.IO.Path]::GetFullPath($Path).TrimEnd(
        [System.IO.Path]::DirectorySeparatorChar,
        [System.IO.Path]::AltDirectorySeparatorChar
    )
}

function Test-LinkTargetsSource {
    param(
        [Parameter(Mandatory)]
        [System.IO.FileSystemInfo] $Item,

        [Parameter(Mandatory)]
        [string] $Source
    )

    if ($Item.LinkType -ne 'SymbolicLink' -or -not $Item.Target) {
        return $false
    }

    $linkTarget = [string] $Item.Target
    if (-not [System.IO.Path]::IsPathRooted($linkTarget)) {
        $linkTarget = Join-Path (Split-Path -Parent $Item.FullName) $linkTarget
    }

    return (Get-NormalizedPath $linkTarget) -eq (Get-NormalizedPath $Source)
}

function Get-BackupPath {
    param(
        [Parameter(Mandatory)]
        [string] $Target
    )

    $normalizedTarget = Get-NormalizedPath $Target
    $normalizedCodexHome = Get-NormalizedPath $codexHome
    $codexPrefix = $normalizedCodexHome + [System.IO.Path]::DirectorySeparatorChar

    if ($normalizedTarget.StartsWith($codexPrefix, [StringComparison]::OrdinalIgnoreCase)) {
        $relative = $normalizedTarget.Substring($codexPrefix.Length)
        return Join-Path $backupRoot $relative
    }

    $normalizedAgentsHome = Get-NormalizedPath $agentsHome
    $agentsPrefix = $normalizedAgentsHome + [System.IO.Path]::DirectorySeparatorChar
    if ($normalizedTarget.StartsWith($agentsPrefix, [StringComparison]::OrdinalIgnoreCase)) {
        $relative = $normalizedTarget.Substring($agentsPrefix.Length)
        return Join-Path (Join-Path $backupRoot 'agents') $relative
    }

    $normalizedClaudeHome = Get-NormalizedPath $claudeHome
    $claudePrefix = $normalizedClaudeHome + [System.IO.Path]::DirectorySeparatorChar
    if ($normalizedTarget.StartsWith($claudePrefix, [StringComparison]::OrdinalIgnoreCase)) {
        $relative = $normalizedTarget.Substring($claudePrefix.Length)
        return Join-Path (Join-Path $backupRoot 'claude') $relative
    }

    throw "Managed target is outside CODEX_HOME, AGENTS_HOME, and CLAUDE_CONFIG_DIR: $Target"
}

function Set-ManagedLink {
    param(
        [Parameter(Mandatory)]
        [string] $Source,

        [Parameter(Mandatory)]
        [string] $Target
    )

    if (-not (Test-Path -LiteralPath $Source)) {
        throw "Managed source does not exist: $Source"
    }

    New-ManagedDirectory (Split-Path -Parent $Target)

    $existing = Get-Item -LiteralPath $Target -Force -ErrorAction SilentlyContinue
    if ($existing -and (Test-LinkTargetsSource -Item $existing -Source $Source)) {
        Write-Output "already linked: $Target"
        return
    }

    if ($existing) {
        $backup = Get-BackupPath $Target
        New-ManagedDirectory (Split-Path -Parent $backup)

        if ($DryRun) {
            Write-DryRunCommand "Move-Item -LiteralPath '$Target' -Destination '$backup'"
        }
        else {
            Move-Item -LiteralPath $Target -Destination $backup
        }
        Write-Output "backed up: $Target -> $backup"
    }

    if ($DryRun) {
        Write-DryRunCommand "New-Item -ItemType SymbolicLink -Path '$Target' -Target '$Source'"
    }
    else {
        try {
            New-Item -ItemType SymbolicLink -Path $Target -Target $Source | Out-Null
        }
        catch {
            throw "Failed to create symbolic link '$Target'. Enable Windows Developer Mode or run PowerShell as Administrator. $($_.Exception.Message)"
        }
    }
    Write-Output "linked: $Target -> $Source"
}

function ConvertTo-TomlBasicString {
    param(
        [Parameter(Mandatory)]
        [string] $Value
    )

    if ($Value -match '[\x00-\x1F\x7F]') {
        throw "Project path contains unsupported control characters: $Value"
    }

    return $Value.Replace('\', '\\').Replace('"', '\"')
}

function ConvertFrom-TomlKey {
    param(
        [Parameter(Mandatory)]
        [string] $Token
    )

    if ($Token.StartsWith("'")) {
        return $Token.Substring(1, $Token.Length - 2)
    }

    if (-not $Token.StartsWith('"')) {
        return $Token
    }

    return [regex]::Replace(
        $Token.Substring(1, $Token.Length - 2),
        '\\(u[0-9a-fA-F]{4}|.)',
        {
            param($match)

            $escape = $match.Groups[1].Value
            if ($escape.StartsWith('u')) {
                return [string][char][System.Convert]::ToInt32($escape.Substring(1), 16)
            }

            switch ($escape) {
                'n' { "`n" }
                't' { "`t" }
                'r' { "`r" }
                default { $escape }
            }
        }
    )
}

function Get-PathKey {
    param(
        [Parameter(Mandatory)]
        [string] $Path
    )

    return (Get-NormalizedPath $Path).ToLowerInvariant()
}

function Get-EntryIdentity {
    param(
        [AllowEmptyString()]
        [string] $Table,

        [Parameter(Mandatory)]
        [string] $Key
    )

    return $Table + [char] 0 + $Key
}

function Get-TrustedGitProject {
    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [string[]] $Root
    )

    $projects = [System.Collections.Generic.List[string]]::new()
    $seen = [System.Collections.Generic.HashSet[string]]::new(
        [System.StringComparer]::OrdinalIgnoreCase
    )
    $excludedDirectories = @('.git', 'node_modules', '.venv', 'venv', 'target', 'build', 'dist')

    foreach ($root in $Root) {
        $found = [System.Collections.Generic.List[string]]::new()
        $found.Add([System.IO.Path]::GetFullPath($root))

        if (Test-Path -LiteralPath $root -PathType Container) {
            $pending = [System.Collections.Generic.Stack[string]]::new()
            $pending.Push([System.IO.Path]::GetFullPath($root))

            while ($pending.Count -gt 0) {
                $directory = $pending.Pop()
                if (Test-Path -LiteralPath (Join-Path $directory '.git')) {
                    $found.Add($directory)
                }

                Get-ChildItem -LiteralPath $directory -Directory -Force -ErrorAction SilentlyContinue |
                    Where-Object {
                        $_.Name -notin $excludedDirectories -and
                        -not ($_.Attributes -band [System.IO.FileAttributes]::ReparsePoint)
                    } |
                    ForEach-Object { $pending.Push($_.FullName) }
            }
        }

        foreach ($project in ($found | Sort-Object)) {
            if ($seen.Add($project)) {
                $projects.Add($project)
            }
        }
    }

    return $projects.ToArray()
}

function Get-ConfigIndex {
    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [string[]] $Line
    )

    # The last content line of each table is where a new key for that table
    # goes, so it lands with the table it belongs to rather than at the end of
    # the file. A key defined twice is never written, because nothing says which
    # occurrence Codex reads.
    $tableEnd = @{ '' = -1 }
    $keys = @{}
    $ambiguous = @{}
    $current = ''

    for ($number = 0; $number -lt $Line.Count; $number++) {
        $text = $Line[$number]

        if ($text -match '^\s*\[([^\[\]]*)\]\s*$') {
            $current = $Matches[1].Trim()
            $tableEnd[$current] = $number
            continue
        }

        if ($text.Trim()) {
            $tableEnd[$current] = $number
        }

        if ($text -match '^\s*([A-Za-z0-9_-]+|"(?:[^"\\]|\\.)*"|''[^'']*'')\s*=') {
            $identity = Get-EntryIdentity -Table $current -Key (ConvertFrom-TomlKey $Matches[1])
            if ($keys.ContainsKey($identity)) {
                $ambiguous[$identity] = $true
            }
            else {
                $keys[$identity] = $number
            }
        }
    }

    return [pscustomobject] @{
        TableEnd  = $tableEnd
        Keys      = $keys
        Ambiguous = $ambiguous
    }
}

function Get-ManagedSourceEntry {
    $entries = [System.Collections.Generic.List[psobject]]::new()
    $current = ''

    foreach ($line in [System.IO.File]::ReadAllLines($configSource)) {
        $trimmed = $line.Trim()
        if (-not $trimmed -or $trimmed.StartsWith('#')) {
            continue
        }

        if ($line -match '^\s*\[([^\[\]]*)\]\s*$') {
            $current = $Matches[1].Trim()
            continue
        }

        if ($line -match '^\s*([A-Za-z0-9_-]+|"(?:[^"\\]|\\.)*"|''[^'']*'')\s*=') {
            $entries.Add([pscustomobject] @{
                    Table = $current
                    Key   = ConvertFrom-TomlKey $Matches[1]
                    Line  = $line.TrimEnd()
                })
        }
    }

    return $entries
}

function Add-ConfigKey {
    param(
        # A mandatory collection parameter rejects an empty element unless it is
        # allowed explicitly, and a configuration file has blank lines.
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [System.Collections.Generic.List[string]] $Line,

        [AllowEmptyString()]
        [string] $Table,

        [Parameter(Mandatory)]
        [string] $Text
    )

    $index = Get-ConfigIndex -Line $Line.ToArray()

    if (-not $index.TableEnd.ContainsKey($Table)) {
        if ($Line.Count -and $Line[$Line.Count - 1].Trim()) {
            $Line.Add('')
        }
        $Line.Add("[$Table]")
        $Line.Add($Text)
        return
    }

    $Line.Insert($index.TableEnd[$Table] + 1, $Text)
}

function Get-ProjectTable {
    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [string[]] $Line
    )

    $found = @{}

    for ($number = 0; $number -lt $Line.Count; $number++) {
        if ($Line[$number] -notmatch '^\s*\[([^\[\]]*)\]\s*$') {
            continue
        }

        $name = $Matches[1].Trim()
        if (-not $name.StartsWith('projects.')) {
            continue
        }

        $found[(Get-PathKey (ConvertFrom-TomlKey $name.Substring('projects.'.Length)))] = $number
    }

    return $found
}

function Merge-CodexConfig {
    param(
        [Parameter(Mandatory)]
        [string] $Target,

        [AllowNull()]
        $State
    )

    $entries = Get-ManagedSourceEntry
    if ($entries.Count -eq 0) {
        throw "No managed entries in $configSource"
    }

    $lines = [System.Collections.Generic.List[string]]::new()
    if (Test-Path -LiteralPath $Target -PathType Leaf) {
        foreach ($line in (Split-FileText ([System.IO.File]::ReadAllText($Target)))) {
            $lines.Add($line)
        }
    }

    $recordedKeys = @{}
    foreach ($record in (Get-StateList -Record $State -Name 'keys')) {
        $recordedKeys[(Get-EntryIdentity -Table $record.table -Key $record.key)] = $record.line
    }

    $recordedPreexisting = @{}
    foreach ($record in (Get-StateList -Record $State -Name 'preexisting')) {
        $recordedPreexisting[(Get-EntryIdentity -Table $record.table -Key $record.key)] = $true
    }

    $recordedTrust = [ordered] @{}
    foreach ($record in (Get-StateList -Record $State -Name 'trust')) {
        $recordedTrust[(Get-PathKey $record.path)] = $record
    }

    $managed = [System.Collections.Generic.List[psobject]]::new()
    $preexisting = [System.Collections.Generic.List[psobject]]::new()
    $trust = [System.Collections.Generic.List[psobject]]::new()
    $changed = $false
    $sourceIdentities = @{}

    foreach ($entry in $entries) {
        $identity = Get-EntryIdentity -Table $entry.Table -Key $entry.Key
        $sourceIdentities[$identity] = $true
        $label = if ($entry.Table) { "$($entry.Table).$($entry.Key)" } else { $entry.Key }
        $index = Get-ConfigIndex -Line $lines.ToArray()

        if ($index.Ambiguous.ContainsKey($identity)) {
            $script:mergeReport.Add("preserved: $Target defines $label more than once")
            continue
        }

        if (-not $index.Keys.ContainsKey($identity)) {
            Add-ConfigKey -Line $lines -Table $entry.Table -Text $entry.Line
            $managed.Add([ordered] @{ table = $entry.Table; key = $entry.Key; line = $entry.Line })
            $script:mergeReport.Add("set: $Target $label")
            $changed = $true
            continue
        }

        $number = $index.Keys[$identity]
        $current = $lines[$number].TrimEnd()

        if ($recordedPreexisting.ContainsKey($identity) -or -not $recordedKeys.ContainsKey($identity)) {
            $preexisting.Add([ordered] @{ table = $entry.Table; key = $entry.Key })
            if ($current -cne $entry.Line) {
                $script:mergeReport.Add(
                    "preserved: $Target has $($current.Trim()); the baseline sets $($entry.Line)"
                )
            }
            continue
        }

        if ($current -cne $recordedKeys[$identity]) {
            $managed.Add([ordered] @{
                    table = $entry.Table
                    key   = $entry.Key
                    line  = $recordedKeys[$identity]
                })
            $script:mergeReport.Add("preserved: $Target $label changed since installation")
            continue
        }

        if ($current -cne $entry.Line) {
            $lines[$number] = $entry.Line
            $script:mergeReport.Add("updated: $Target $label")
            $changed = $true
        }

        $managed.Add([ordered] @{ table = $entry.Table; key = $entry.Key; line = $entry.Line })
    }

    foreach ($identity in @($recordedKeys.Keys)) {
        if ($sourceIdentities.ContainsKey($identity)) {
            continue
        }

        $index = Get-ConfigIndex -Line $lines.ToArray()
        if (-not $index.Keys.ContainsKey($identity)) {
            continue
        }

        $number = $index.Keys[$identity]
        $label = $identity.Replace([string][char] 0, '.').TrimStart('.')

        if ($lines[$number].TrimEnd() -ceq $recordedKeys[$identity]) {
            $lines.RemoveAt($number)
            $script:mergeReport.Add("withdrew: $Target $label")
            $changed = $true
        }
        else {
            $script:mergeReport.Add("preserved: $Target $label is no longer managed and has changed")
        }
    }

    $wanted = @{}
    foreach ($project in (Get-TrustedGitProject -Root $trustRoots)) {
        $key = Get-PathKey $project
        $wanted[$key] = $true
        $existing = Get-ProjectTable -Line $lines.ToArray()

        if ($existing.ContainsKey($key)) {
            if ($recordedTrust.Contains($key)) {
                $trust.Add($recordedTrust[$key])
            }
            continue
        }

        $block = @(
            "[projects.`"$(ConvertTo-TomlBasicString -Value $project)`"]",
            'trust_level = "trusted"'
        )
        if ($lines.Count -and $lines[$lines.Count - 1].Trim()) {
            $lines.Add('')
        }
        foreach ($text in $block) {
            $lines.Add($text)
        }
        $trust.Add([ordered] @{ path = $project; lines = $block })
        $script:mergeReport.Add("trusted: $project")
        $changed = $true
    }

    foreach ($key in @($recordedTrust.Keys)) {
        if ($wanted.ContainsKey($key)) {
            continue
        }

        $record = $recordedTrust[$key]
        $existing = Get-ProjectTable -Line $lines.ToArray()
        if (-not $existing.ContainsKey($key)) {
            continue
        }

        $start = $existing[$key]
        $recordedBlock = @($record.lines)
        $actual = @()
        for ($offset = 0; $offset -lt $recordedBlock.Count -and ($start + $offset) -lt $lines.Count; $offset++) {
            $actual += $lines[$start + $offset].TrimEnd()
        }

        if (($actual -join "`n") -ceq ($recordedBlock -join "`n")) {
            $lines.RemoveRange($start, $recordedBlock.Count)
            $script:mergeReport.Add("withdrew trust: $($record.path)")
            $changed = $true
        }
        else {
            $script:mergeReport.Add("preserved: changed trust entry for $($record.path)")
            $trust.Add($record)
        }
    }

    $content = $null
    if ($changed) {
        $content = Join-FileText $lines
    }

    return [pscustomobject] @{
        Content = $content
        State   = [ordered] @{
            keys        = $managed.ToArray()
            preexisting = $preexisting.ToArray()
            trust       = $trust.ToArray()
        }
    }
}

function Get-DerivedClaudeRule {
    $rules = [System.Collections.Generic.List[string]]::new()
    $seen = [System.Collections.Generic.HashSet[string]]::new(
        [System.StringComparer]::Ordinal
    )

    foreach ($line in [System.IO.File]::ReadAllLines($rulesSource)) {
        $match = [regex]::Match(
            $line,
            '^prefix_rule\(pattern=\["(?<command>[^"]*)"\], decision="allow"\)$'
        )
        if (-not $match.Success) {
            continue
        }

        $command = $match.Groups['command'].Value
        if (-not $seen.Add($command)) {
            continue
        }

        $rules.Add("Bash($command *)")
        $rules.Add("PowerShell($command *)")
    }

    return $rules
}

function Test-JsonProperty {
    param(
        [Parameter(Mandatory)]
        [psobject] $Object,

        [Parameter(Mandatory)]
        [string] $Name
    )

    return [bool] ($Object.PSObject.Properties.Name -contains $Name)
}

function Set-JsonProperty {
    param(
        [Parameter(Mandatory)]
        [psobject] $Object,

        [Parameter(Mandatory)]
        [string] $Name,

        [AllowNull()]
        $Value
    )

    if (Test-JsonProperty -Object $Object -Name $Name) {
        $Object.$Name = $Value
    }
    else {
        Add-Member -InputObject $Object -NotePropertyName $Name -NotePropertyValue $Value
    }
}

function ConvertTo-PortableJson {
    param(
        [Parameter(Mandatory)]
        [psobject] $Value
    )

    $json = ConvertTo-Json -InputObject $Value -Depth 100

    # Windows PowerShell 5.1 writes <, >, & and ' as Unicode escapes where
    # PowerShell 7 writes the characters, and hundreds of approved commands
    # contain them, so an edition change would otherwise rewrite permissions the
    # user approved. Each key below is a regular expression; the leading group
    # consumes complete backslash pairs so an already escaped backslash followed
    # by the letter u is left alone.
    $portableEscape = [ordered] @{
        '\\u003c' = '<'
        '\\u003e' = '>'
        '\\u0026' = '&'
        '\\u0027' = "'"
    }

    foreach ($escape in $portableEscape.Keys) {
        $json = [regex]::Replace(
            $json,
            '(?<!\\)((?:\\\\)*)' + $escape,
            '${1}' + $portableEscape[$escape]
        )
    }

    return $json
}

function Merge-CodexRule {
    param(
        [Parameter(Mandatory)]
        [string] $Target,

        [AllowNull()]
        $State,

        [switch] $Fresh
    )

    $curated = [System.Collections.Generic.List[string]]::new()
    foreach ($line in [System.IO.File]::ReadAllLines($rulesSource)) {
        $trimmed = $line.Trim()
        if ($trimmed -and -not $trimmed.StartsWith('#')) {
            $curated.Add($line.TrimEnd())
        }
    }

    if ($curated.Count -eq 0) {
        throw "No rules in $rulesSource"
    }

    $lines = [System.Collections.Generic.List[string]]::new()
    if (-not $Fresh -and (Test-Path -LiteralPath $Target -PathType Leaf)) {
        foreach ($line in (Split-FileText ([System.IO.File]::ReadAllText($Target)))) {
            $lines.Add($line)
        }
    }

    $present = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
    foreach ($line in $lines) {
        [void] $present.Add($line.TrimEnd())
    }

    $recorded = [System.Collections.Generic.HashSet[string]]::new(
        [string[]] @(Get-StateList -Record $State -Name 'rules'),
        [System.StringComparer]::Ordinal
    )
    $recordedPreexisting = [System.Collections.Generic.HashSet[string]]::new(
        [string[]] @(Get-StateList -Record $State -Name 'preexisting'),
        [System.StringComparer]::Ordinal
    )

    $managed = [System.Collections.Generic.List[string]]::new()
    $preexisting = [System.Collections.Generic.List[string]]::new()
    $added = 0
    $changed = $false

    foreach ($rule in $curated) {
        if ($present.Contains($rule)) {
            if ($recorded.Contains($rule) -and -not $recordedPreexisting.Contains($rule)) {
                $managed.Add($rule)
            }
            else {
                $preexisting.Add($rule)
            }
            continue
        }

        $lines.Add($rule)
        [void] $present.Add($rule)
        $managed.Add($rule)
        $added++
        $changed = $true
    }

    if ($added) {
        $script:mergeReport.Add("added $added curated rule(s): $Target")
    }

    $curatedSet = [System.Collections.Generic.HashSet[string]]::new(
        [string[]] $curated.ToArray(),
        [System.StringComparer]::Ordinal
    )

    foreach ($rule in @($recorded | Sort-Object)) {
        if ($curatedSet.Contains($rule) -or $recordedPreexisting.Contains($rule)) {
            continue
        }
        if (-not $present.Contains($rule)) {
            continue
        }

        for ($number = $lines.Count - 1; $number -ge 0; $number--) {
            if ($lines[$number].TrimEnd() -ceq $rule) {
                $lines.RemoveAt($number)
            }
        }
        [void] $present.Remove($rule)
        $script:mergeReport.Add("withdrew rule: $rule")
        $changed = $true
    }

    # A rule already in the machine's file when this installer first ran is the
    # machine's, so dropping it from the curated set withdraws nothing. The two
    # are identical text, so reporting it once is the only honest outcome.
    foreach ($rule in @($recordedPreexisting | Sort-Object)) {
        if (-not $curatedSet.Contains($rule) -and $present.Contains($rule)) {
            $script:mergeReport.Add("preserved: $rule is no longer curated but predates this install")
        }
    }

    $content = $null
    if ($changed) {
        $content = Join-FileText $lines
    }

    return [pscustomobject] @{
        Content = $content
        State   = [ordered] @{
            rules       = $managed.ToArray()
            preexisting = $preexisting.ToArray()
        }
    }
}

function Merge-ClaudeSetting {
    param(
        [Parameter(Mandatory)]
        [string] $Target,

        [AllowNull()]
        $State
    )

    $derived = Get-DerivedClaudeRule
    if ($derived.Count -eq 0) {
        throw "No allow rules derived from $rulesSource"
    }

    $text = if (Test-Path -LiteralPath $Target -PathType Leaf) {
        [System.IO.File]::ReadAllText($Target)
    }
    else {
        ''
    }

    $recordedState = [ordered] @{
        allow       = @(Get-StateList -Record $State -Name 'allow')
        preexisting = @(Get-StateList -Record $State -Name 'preexisting')
    }

    if ($text.Trim()) {
        # Plain ConvertFrom-Json is the only form both supported editions accept,
        # and the PSCustomObject it returns keeps the key order the file has.
        try {
            $settings = $text | ConvertFrom-Json
        }
        catch {
            $script:mergeReport.Add("preserved: $Target is not valid JSON ($($_.Exception.Message))")
            return [pscustomobject] @{ Content = $null; State = $recordedState }
        }
    }
    else {
        $settings = [pscustomobject] @{}
    }

    if ($settings -isnot [System.Management.Automation.PSCustomObject]) {
        $script:mergeReport.Add("preserved: $Target does not hold a JSON object")
        return [pscustomobject] @{ Content = $null; State = $recordedState }
    }

    if (-not (Test-JsonProperty -Object $settings -Name 'permissions')) {
        Set-JsonProperty -Object $settings -Name 'permissions' -Value ([pscustomobject] @{})
    }

    $permissions = $settings.permissions
    if (-not (Test-JsonProperty -Object $permissions -Name 'allow')) {
        Set-JsonProperty -Object $permissions -Name 'allow' -Value @()
    }

    $allow = [System.Collections.Generic.List[string]]::new()
    foreach ($entry in @($permissions.allow)) {
        $allow.Add([string] $entry)
    }

    $present = [System.Collections.Generic.HashSet[string]]::new(
        [string[]] $allow.ToArray(),
        [System.StringComparer]::Ordinal
    )
    $recorded = [System.Collections.Generic.HashSet[string]]::new(
        [string[]] $recordedState['allow'],
        [System.StringComparer]::Ordinal
    )
    $recordedPreexisting = [System.Collections.Generic.HashSet[string]]::new(
        [string[]] $recordedState['preexisting'],
        [System.StringComparer]::Ordinal
    )

    $managed = [System.Collections.Generic.List[string]]::new()
    $preexisting = [System.Collections.Generic.List[string]]::new()
    $added = 0
    $changed = $false

    foreach ($entry in $derived) {
        if ($present.Contains($entry)) {
            if ($recorded.Contains($entry) -and -not $recordedPreexisting.Contains($entry)) {
                $managed.Add($entry)
            }
            else {
                $preexisting.Add($entry)
            }
            continue
        }

        $allow.Add($entry)
        [void] $present.Add($entry)
        $managed.Add($entry)
        $added++
        $changed = $true
    }

    if ($added) {
        $script:mergeReport.Add("added $added derived permission(s): $Target")
    }

    # Get-DerivedClaudeRule returns a list, and PowerShell unrolls it into an
    # array on the way out, so the cast is what makes the type explicit here.
    $wanted = [System.Collections.Generic.HashSet[string]]::new(
        [string[]] $derived,
        [System.StringComparer]::Ordinal
    )

    foreach ($entry in @($recorded | Sort-Object)) {
        if ($wanted.Contains($entry) -or $recordedPreexisting.Contains($entry)) {
            continue
        }
        if (-not $present.Contains($entry)) {
            continue
        }

        [void] $allow.Remove($entry)
        [void] $present.Remove($entry)
        $script:mergeReport.Add("withdrew permission: $entry")
        $changed = $true
    }

    # An entry already approved when this installer first ran belongs to the
    # user, and nothing in the file distinguishes it from a managed one, so it
    # survives with a report rather than being withdrawn.
    foreach ($entry in @($recordedPreexisting | Sort-Object)) {
        if (-not $wanted.Contains($entry) -and $present.Contains($entry)) {
            $script:mergeReport.Add(
                "preserved: $entry is no longer curated but was approved before this install"
            )
        }
    }

    Set-JsonProperty -Object $permissions -Name 'allow' -Value ([string[]] $allow.ToArray())
    $rendered = ConvertTo-PortableJson -Value $settings
    $content = $null
    if ($changed -or $rendered -cne $text) {
        $content = $rendered
    }

    return [pscustomobject] @{
        Content = $content
        State   = [ordered] @{
            allow       = $managed.ToArray()
            preexisting = $preexisting.ToArray()
        }
    }
}

function Split-FileText {
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string] $Text
    )

    if (-not $Text) {
        return @()
    }

    $lines = $Text -split "`n"
    if ($lines[$lines.Count - 1] -eq '') {
        $lines = $lines[0..($lines.Count - 2)]
    }

    return $lines
}

function Join-FileText {
    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [System.Collections.Generic.List[string]] $Line
    )

    $builder = [System.Text.StringBuilder]::new()
    foreach ($text in $Line) {
        [void] $builder.Append($text)
        [void] $builder.Append("`n")
    }

    return $builder.ToString()
}

function Get-StateList {
    param(
        [AllowNull()]
        $Record,

        [Parameter(Mandatory)]
        [string] $Name
    )

    if ($null -eq $Record -or -not (Test-JsonProperty -Object $Record -Name $Name)) {
        return @()
    }

    return @($Record.$Name)
}

function Get-InstallState {
    if (-not (Test-Path -LiteralPath $stateFile -PathType Leaf)) {
        return $null
    }

    $text = [System.IO.File]::ReadAllText($stateFile)
    if (-not $text.Trim()) {
        return $null
    }

    try {
        $state = $text | ConvertFrom-Json
    }
    catch {
        return $null
    }

    if (-not (Test-JsonProperty -Object $state -Name 'version') -or $state.version -ne $stateVersion) {
        return $null
    }

    return $state
}

function Get-ArtifactState {
    param(
        [AllowNull()]
        $State,

        [Parameter(Mandatory)]
        [string] $Name,

        [Parameter(Mandatory)]
        [string] $Target
    )

    # A record written for a different target says nothing about this one, so it
    # is treated as absent and the run manages nothing in the new file.
    if ($null -eq $State -or -not (Test-JsonProperty -Object $State -Name $Name)) {
        return $null
    }

    $record = $State.$Name
    if (-not (Test-JsonProperty -Object $record -Name 'path') -or $record.path -ne $Target) {
        return $null
    }

    return $record
}

function Write-MergedFile {
    param(
        [Parameter(Mandatory)]
        [string] $Path,

        [AllowNull()]
        $Content,

        [Parameter(Mandatory)]
        [string] $BackupName
    )

    if ($null -eq $Content) {
        $script:mergeReport.Add("already current: $Path")
        return
    }

    if ($DryRun) {
        $script:mergeReport.Add("would write: $Path")
        return
    }

    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        $backup = Join-Path $backupRoot $BackupName
        New-ManagedDirectory (Split-Path -Parent $backup)
        Copy-Item -LiteralPath $Path -Destination $backup
        $script:mergeReport.Add("backed up: $Path -> $backup")
    }

    New-ManagedDirectory (Split-Path -Parent $Path)
    [System.IO.File]::WriteAllText($Path, $Content, [System.Text.UTF8Encoding]::new($false))
    $script:mergeReport.Add("merged: $Path")
}

# Codex writes interactive approvals into its rules directory, so that directory
# cannot be a link into this repository. An installation that made one is undone
# here, and the approvals it captured are left where they landed rather than
# adopted or discarded.
function Initialize-RulesDirectory {
    param(
        [Parameter(Mandatory)]
        [string] $Path
    )

    $existing = Get-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
    $unlinked = $false

    if ($existing -and $existing.LinkType -eq 'SymbolicLink') {
        $linkTarget = [string] $existing.Target

        if ($DryRun) {
            Write-DryRunCommand "Remove the link '$Path'"
        }
        else {
            # Delete on the entry itself removes the link and never its target,
            # which Move-Item and -Recurse could both follow. There is nothing to
            # back up: the link holds no content of its own.
            $existing.Delete()
        }

        $script:mergeReport.Add("unlinked: $Path")
        $unlinked = $true

        if ((Get-PathKey $linkTarget).StartsWith((Get-PathKey $repoRoot))) {
            $script:mergeReport.Add(
                "note: approvals recorded through that link are in $linkTarget; review them there"
            )
        }
    }

    New-ManagedDirectory $Path
    return $unlinked
}

function Invoke-AgentStateMerge {
    $configTarget = Join-Path $codexHome 'config.toml'
    $rulesTarget = Join-Path (Join-Path $codexHome 'rules') 'default.rules'
    # A dry run leaves the link in place, so the merge must not read the
    # repository's own rules back through it.
    $freshRules = (Initialize-RulesDirectory (Join-Path $codexHome 'rules')) -and $DryRun
    $state = Get-InstallState

    $config = Merge-CodexConfig -Target $configTarget `
        -State (Get-ArtifactState -State $state -Name 'codexConfig' -Target $configTarget)
    $rules = Merge-CodexRule -Target $rulesTarget -Fresh:$freshRules `
        -State (Get-ArtifactState -State $state -Name 'codexRules' -Target $rulesTarget)
    $claude = Merge-ClaudeSetting -Target $claudeSettings `
        -State (Get-ArtifactState -State $state -Name 'claudeSettings' -Target $claudeSettings)

    # Backups keep the layout the installer's other backups use, so a restore is
    # a copy back to the matching home.
    Write-MergedFile -Path $configTarget -Content $config.Content -BackupName 'config.toml'
    Write-MergedFile -Path $rulesTarget -Content $rules.Content `
        -BackupName (Join-Path 'rules' 'default.rules')
    Write-MergedFile -Path $claudeSettings -Content $claude.Content `
        -BackupName (Join-Path 'claude' 'settings.json')

    if (-not $DryRun) {
        $config.State['path'] = $configTarget
        $rules.State['path'] = $rulesTarget
        $claude.State['path'] = $claudeSettings

        New-ManagedDirectory (Split-Path -Parent $stateFile)
        [System.IO.File]::WriteAllText(
            $stateFile,
            (ConvertTo-PortableJson -Value ([pscustomobject] [ordered] @{
                        version        = $stateVersion
                        codexConfig    = $config.State
                        codexRules     = $rules.State
                        claudeSettings = $claude.State
                    })),
            [System.Text.UTF8Encoding]::new($false)
        )
    }

    foreach ($line in $script:mergeReport) {
        Write-Output $line
    }
}

function Remove-StaleManagedSkill {
    param(
        [Parameter(Mandatory)]
        [string] $SkillsDirectory
    )

    if (-not (Test-Path -LiteralPath $SkillsDirectory -PathType Container)) {
        return
    }

    $managedRoot = Get-NormalizedPath (Join-Path $repoRoot '.agents/skills')
    $managedPrefix = $managedRoot + [System.IO.Path]::DirectorySeparatorChar

    Get-ChildItem -LiteralPath $SkillsDirectory -Force | ForEach-Object {
        # Only ever consider links this installer could have created. A real
        # directory, or a link pointing anywhere else, belongs to the user.
        if ($_.LinkType -ne 'SymbolicLink' -or -not $_.Target) {
            return
        }

        $linkTarget = [string] $_.Target
        if (-not [System.IO.Path]::IsPathRooted($linkTarget)) {
            $linkTarget = Join-Path (Split-Path -Parent $_.FullName) $linkTarget
        }
        $linkTarget = Get-NormalizedPath $linkTarget

        if (-not $linkTarget.StartsWith($managedPrefix, [StringComparison]::OrdinalIgnoreCase)) {
            return
        }

        # The source is gone, so the skill was removed or made optional.
        if (Test-Path -LiteralPath $linkTarget) {
            return
        }

        if ($DryRun) {
            Write-DryRunCommand "Remove-Item -LiteralPath '$($_.FullName)' -Force"
        }
        else {
            # Delete on the entry itself removes the link and never the source,
            # which -Recurse would follow. It also copes with either reparse
            # type, unlike [System.IO.Directory]::Delete: Windows records a link
            # made while its target is missing as a file, so a stale link can be
            # a file reparse point pointing at a directory that used to exist.
            $_.Delete()
        }
        Write-Output "pruned stale skill link: $($_.FullName)"
    }
}

function Test-AgentAvailable {
    param(
        [Parameter(Mandatory)]
        [string] $Agent
    )

    # A dry run only prints what it would do, so a missing agent is not a problem.
    if ($DryRun -or (Get-Command $Agent -ErrorAction SilentlyContinue)) {
        return $true
    }

    Write-Warning "$Agent is not installed; skipping its plugins."
    return $false
}

function Invoke-AgentPluginCommand {
    param(
        [Parameter(Mandatory)]
        [string] $Agent,

        [Parameter(Mandatory)]
        [string[]] $CommandArgument,

        [Parameter(Mandatory)]
        [string] $FailureMessage
    )

    if ($DryRun) {
        Write-DryRunCommand "$Agent $($CommandArgument -join ' ')"
        return
    }

    $global:LASTEXITCODE = 0
    & $Agent @CommandArgument
    if ($LASTEXITCODE -ne 0) {
        throw $FailureMessage
    }
}

function Install-CodexPlugin {
    if (-not (Test-AgentAvailable 'codex')) {
        return
    }

    Get-Content -LiteralPath $codexPluginManifest |
        ForEach-Object {
            # Both manifests ignore blank lines and lines whose first non-blank
            # character is a hash, so each file can record why its own format
            # differs from the other's.
            if ($_ -match '^\s*(#|$)') {
                return
            }

            $plugin = $_.Trim()

            # Codex ships openai-curated as a built-in marketplace, so a plugin
            # from it needs no registration step.
            Invoke-AgentPluginCommand -Agent 'codex' `
                -CommandArgument @('plugin', 'add', $plugin) `
                -FailureMessage "Failed to install Codex plugin: $plugin"
        }
}

function Install-ClaudePlugin {
    if (-not (Test-AgentAvailable 'claude')) {
        return
    }

    Get-Content -LiteralPath $claudePluginManifest |
        ForEach-Object {
            if ($_ -match '^\s*(#|$)') {
                return
            }

            $fields = $_.Trim() -split '\s+', 2
            if ($fields.Count -lt 2 -or -not $fields[1].Trim()) {
                throw "Claude Code plugin entry has no marketplace source: $($fields[0])"
            }

            $selector = $fields[0]
            $source = $fields[1].Trim()

            # Claude Code registers no marketplace until its first interactive
            # start, so an installer that runs before that must add the source
            # itself. The URL is spelled out because owner/repo shorthand
            # resolves over SSH. Both commands are idempotent, so a rerun
            # re-clones and reinstalls nothing.
            Invoke-AgentPluginCommand -Agent 'claude' `
                -CommandArgument @('plugin', 'marketplace', 'add', $source) `
                -FailureMessage "Failed to add Claude Code marketplace: $source"
            Invoke-AgentPluginCommand -Agent 'claude' `
                -CommandArgument @('plugin', 'install', $selector) `
                -FailureMessage "Failed to install Claude Code plugin: $selector"
        }
}

Set-ManagedLink (Join-Path $repoRoot 'ai-home/AGENTS.md') (Join-Path $codexHome 'AGENTS.md')

Get-ChildItem -LiteralPath (Join-Path $repoRoot 'ai-home/codex') -Filter '*.config.toml' -File |
    ForEach-Object {
        Set-ManagedLink $_.FullName (Join-Path $codexHome $_.Name)
    }

Set-ManagedLink (Join-Path $repoRoot 'ai-home/AGENTS.md') (Join-Path $claudeHome 'CLAUDE.md')
Invoke-AgentStateMerge

Get-ChildItem -LiteralPath (Join-Path $repoRoot '.agents/skills') -Directory |
    ForEach-Object {
        Set-ManagedLink $_.FullName (Join-Path (Join-Path $agentsHome 'skills') $_.Name)
        Set-ManagedLink $_.FullName (Join-Path (Join-Path $claudeHome 'skills') $_.Name)
    }

Remove-StaleManagedSkill (Join-Path $agentsHome 'skills')
Remove-StaleManagedSkill (Join-Path $claudeHome 'skills')

if ($Plugins) {
    Install-CodexPlugin
    Install-ClaudePlugin
}

if ($DryRun) {
    Write-Output 'dry run complete'
}
else {
    Write-Output 'installation complete. Restart Codex and Claude Code to reload configuration.'
}
