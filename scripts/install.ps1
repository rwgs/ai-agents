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
$githubRoot = Join-Path $userHome 'github'

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

function Get-TrustedGitProject {
    param(
        [Parameter(Mandatory)]
        [string] $Root
    )

    $projects = [System.Collections.Generic.HashSet[string]]::new(
        [System.StringComparer]::OrdinalIgnoreCase
    )
    [void] $projects.Add([System.IO.Path]::GetFullPath($Root))

    if (-not (Test-Path -LiteralPath $Root -PathType Container)) {
        return @($projects)
    }

    $excludedDirectories = @('.git', 'node_modules', '.venv', 'venv', 'target', 'build', 'dist')
    $pending = [System.Collections.Generic.Stack[string]]::new()
    $pending.Push([System.IO.Path]::GetFullPath($Root))

    while ($pending.Count -gt 0) {
        $directory = $pending.Pop()
        if (Test-Path -LiteralPath (Join-Path $directory '.git')) {
            [void] $projects.Add($directory)
        }

        Get-ChildItem -LiteralPath $directory -Directory -Force -ErrorAction SilentlyContinue |
            Where-Object {
                $_.Name -notin $excludedDirectories -and
                -not ($_.Attributes -band [System.IO.FileAttributes]::ReparsePoint)
            } |
            ForEach-Object { $pending.Push($_.FullName) }
    }

    return @($projects | Sort-Object)
}

function Get-ManagedConfigContent {
    $content = [System.IO.File]::ReadAllText($configSource)
    $content += "`n# Generated by the AI installer. Rerun it after adding repositories.`n"

    foreach ($project in (Get-TrustedGitProject -Root $githubRoot)) {
        $escapedProject = ConvertTo-TomlBasicString -Value $project
        $tableHeader = "[projects.`"$escapedProject`"]"
        $tablePattern = "(?m)^$([regex]::Escape($tableHeader))`r?$"

        if ($content -notmatch $tablePattern) {
            $content += "`n$tableHeader`ntrust_level = `"trusted`"`n"
        }
    }

    return $content
}

function Install-ManagedConfig {
    param(
        [Parameter(Mandatory)]
        [string] $Content,

        [Parameter(Mandatory)]
        [string] $Target
    )

    New-ManagedDirectory (Split-Path -Parent $Target)
    $existing = Get-Item -LiteralPath $Target -Force -ErrorAction SilentlyContinue

    if (
        $existing -and
        $existing.LinkType -ne 'SymbolicLink' -and
        [System.IO.File]::ReadAllText($Target) -ceq $Content
    ) {
        Write-Output "already installed: $Target"
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
        Write-DryRunCommand "Write generated Codex configuration to '$Target'"
    }
    else {
        $utf8WithoutBom = [System.Text.UTF8Encoding]::new($false)
        [System.IO.File]::WriteAllText($Target, $Content, $utf8WithoutBom)
    }
    Write-Output "installed: $Target"
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

function Get-MergedClaudeSettingsContent {
    $rules = Get-DerivedClaudeRule
    if ($rules.Count -eq 0) {
        throw "No allow rules derived from $rulesSource"
    }

    # Plain ConvertFrom-Json is the only form both supported editions accept, and
    # the PSCustomObject it returns keeps the key order the file already has.
    $settings = if (
        (Test-Path -LiteralPath $claudeSettings -PathType Leaf) -and
        [System.IO.File]::ReadAllText($claudeSettings).Trim()
    ) {
        [System.IO.File]::ReadAllText($claudeSettings) | ConvertFrom-Json
    }
    else {
        [pscustomobject] @{}
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
        [string[]] $allow,
        [System.StringComparer]::Ordinal
    )
    foreach ($rule in $rules) {
        if ($present.Add($rule)) {
            $allow.Add($rule)
        }
    }

    Set-JsonProperty -Object $permissions -Name 'allow' -Value ([string[]] $allow)
    return (ConvertTo-PortableJson -Value $settings)
}

function Install-ClaudeSettingsFile {
    $content = Get-MergedClaudeSettingsContent

    New-ManagedDirectory (Split-Path -Parent $claudeSettings)
    $existing = Get-Item -LiteralPath $claudeSettings -Force -ErrorAction SilentlyContinue

    if (
        $existing -and
        $existing.LinkType -ne 'SymbolicLink' -and
        [System.IO.File]::ReadAllText($claudeSettings) -ceq $content
    ) {
        Write-Output "already current: $claudeSettings"
        return
    }

    if ($existing) {
        $backup = Get-BackupPath $claudeSettings
        New-ManagedDirectory (Split-Path -Parent $backup)

        if ($DryRun) {
            Write-DryRunCommand "Copy-Item -LiteralPath '$claudeSettings' -Destination '$backup'"
        }
        else {
            Copy-Item -LiteralPath $claudeSettings -Destination $backup
        }
        Write-Output "backed up: $claudeSettings -> $backup"
    }

    if ($DryRun) {
        Write-DryRunCommand "Write merged Claude permissions to '$claudeSettings'"
    }
    else {
        $utf8WithoutBom = [System.Text.UTF8Encoding]::new($false)
        [System.IO.File]::WriteAllText($claudeSettings, $content, $utf8WithoutBom)
    }
    Write-Output "merged managed permissions: $claudeSettings"
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
Install-ManagedConfig -Content (Get-ManagedConfigContent) -Target (Join-Path $codexHome 'config.toml')
Set-ManagedLink (Join-Path $repoRoot 'ai-home/rules') (Join-Path $codexHome 'rules')

Get-ChildItem -LiteralPath (Join-Path $repoRoot 'ai-home/codex') -Filter '*.config.toml' -File |
    ForEach-Object {
        Set-ManagedLink $_.FullName (Join-Path $codexHome $_.Name)
    }

Set-ManagedLink (Join-Path $repoRoot 'ai-home/AGENTS.md') (Join-Path $claudeHome 'CLAUDE.md')
Install-ClaudeSettingsFile

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
