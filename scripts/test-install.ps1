[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$taskTestRoot = Join-Path ([System.IO.Path]::GetTempPath()) "ai-install-test-$([guid]::NewGuid())"
$testCodexHome = Join-Path $taskTestRoot 'codex home'
$testAgentsHome = Join-Path $taskTestRoot 'agents home'
$testClaudeHome = Join-Path $taskTestRoot 'claude home'
$testUserHome = Join-Path $taskTestRoot 'user home'
$testGitHubRepo = Join-Path (Join-Path (Join-Path $testUserHome 'github') 'nested') 'project'
$previousCodexHome = [Environment]::GetEnvironmentVariable('CODEX_HOME', 'Process')
$previousAgentsHome = [Environment]::GetEnvironmentVariable('AGENTS_HOME', 'Process')
$previousClaudeHome = [Environment]::GetEnvironmentVariable('CLAUDE_CONFIG_DIR', 'Process')
$previousPluginTestLog = [Environment]::GetEnvironmentVariable('CODEX_PLUGIN_TEST_LOG', 'Process')
$previousClaudePluginTestLog = [Environment]::GetEnvironmentVariable('CLAUDE_PLUGIN_TEST_LOG', 'Process')
$previousUserProfile = [Environment]::GetEnvironmentVariable('USERPROFILE', 'Process')

function Assert-Condition {
    param(
        [Parameter(Mandatory)]
        [bool] $Condition,

        [Parameter(Mandatory)]
        [string] $Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

function Assert-Link {
    param(
        [Parameter(Mandatory)]
        [string] $Target,

        [Parameter(Mandatory)]
        [string] $Source
    )

    $item = Get-Item -LiteralPath $Target -Force
    Assert-Condition ($item.LinkType -eq 'SymbolicLink') "Expected symbolic link: $Target"

    $linkTarget = [string] $item.Target
    if (-not [System.IO.Path]::IsPathRooted($linkTarget)) {
        $linkTarget = Join-Path (Split-Path -Parent $item.FullName) $linkTarget
    }

    $actual = [System.IO.Path]::GetFullPath($linkTarget)
    $expected = [System.IO.Path]::GetFullPath($Source)
    Assert-Condition ($actual -eq $expected) "Unexpected link target: $Target"
}

try {
    New-Item -ItemType Directory -Path $testCodexHome -Force | Out-Null
    New-Item -ItemType Directory -Path $testClaudeHome -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $testGitHubRepo '.git') -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $testCodexHome 'AGENTS.md') -Value 'original global instructions'

    # Seed real-looking Claude state so the merge is proven non-destructive.
    Set-Content -LiteralPath (Join-Path $testClaudeHome 'settings.json') -Value @'
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
'@

    $env:USERPROFILE = $testUserHome
    $env:CODEX_HOME = $testCodexHome
    $env:AGENTS_HOME = $testAgentsHome
    $env:CLAUDE_CONFIG_DIR = $testClaudeHome
    & (Join-Path $repoRoot 'scripts/install.ps1') | Out-Null

    Assert-Link (Join-Path $testCodexHome 'AGENTS.md') (Join-Path $repoRoot 'ai-home/AGENTS.md')
    $installedConfigPath = Join-Path $testCodexHome 'config.toml'
    $installedConfig = Get-Item -LiteralPath $installedConfigPath -Force
    Assert-Condition ($installedConfig.LinkType -ne 'SymbolicLink') "Expected generated config file: $installedConfigPath"
    $installedConfigContent = [System.IO.File]::ReadAllText($installedConfigPath)
    $escapedGitHubRoot = (Join-Path $testUserHome 'github').Replace('\', '\\')
    $escapedGitHubRepo = $testGitHubRepo.Replace('\', '\\')
    Assert-Condition (
        $installedConfigContent.Contains("[projects.`"$escapedGitHubRoot`"]")
    ) 'Generated config does not trust the user GitHub root'
    Assert-Condition (
        $installedConfigContent.Contains("[projects.`"$escapedGitHubRepo`"]")
    ) 'Generated config does not trust a nested Git repository'
    Assert-Link (Join-Path $testCodexHome 'rules') (Join-Path $repoRoot 'ai-home/rules')
    Assert-Link (Join-Path $testCodexHome 'ollama.config.toml') (Join-Path $repoRoot 'ai-home/codex/ollama.config.toml')
    Assert-Link (Join-Path $testCodexHome 'llamacpp.config.toml') (Join-Path $repoRoot 'ai-home/codex/llamacpp.config.toml')

    Get-ChildItem -LiteralPath (Join-Path $repoRoot '.agents/skills') -Directory |
        ForEach-Object {
            Assert-Link (Join-Path (Join-Path $testAgentsHome 'skills') $_.Name) $_.FullName
            Assert-Link (Join-Path (Join-Path $testClaudeHome 'skills') $_.Name) $_.FullName
        }

    Assert-Link (Join-Path $testClaudeHome 'CLAUDE.md') (Join-Path $repoRoot 'ai-home/AGENTS.md')

    $claudeSettingsPath = Join-Path $testClaudeHome 'settings.json'
    $mergedSettings = Get-Content -LiteralPath $claudeSettingsPath -Raw |
        ConvertFrom-Json -AsHashtable -Depth 100
    $mergedAllow = @($mergedSettings.permissions.allow)
    Assert-Condition ($mergedSettings.model -eq 'opus[1m]') 'Unrelated Claude setting was lost'
    Assert-Condition (
        $mergedSettings.permissions.additionalDirectories[0] -eq '/tmp'
    ) 'Claude additionalDirectories changed'
    Assert-Condition (
        -not $mergedSettings.permissions.ContainsKey('deny') -and
        -not $mergedSettings.permissions.ContainsKey('ask')
    ) 'Absent Claude permission keys were invented'
    Assert-Condition (
        $mergedAllow[0] -eq 'Bash(git add *)'
    ) 'Existing Claude allow entry was lost or reordered'
    Assert-Condition (
        $mergedAllow -contains 'Bash(rtk *)' -and $mergedAllow -contains 'PowerShell(rtk *)'
    ) 'Derived Claude allow entries missing'
    Assert-Condition (
        $mergedAllow.Count -eq ($mergedAllow | Select-Object -Unique).Count
    ) 'Claude merge introduced duplicates'
    $claudeSettingsBefore = Get-Content -LiteralPath $claudeSettingsPath -Raw

    $instructionBackups = @(
        Get-ChildItem -LiteralPath (Join-Path $testCodexHome 'backups') -Filter 'AGENTS.md' -File -Recurse
    )
    Assert-Condition ($instructionBackups.Count -eq 1) "Expected one AGENTS.md backup, found $($instructionBackups.Count)"
    $backupContent = Get-Content -LiteralPath $instructionBackups[0].FullName -Raw
    Assert-Condition ($backupContent.Trim() -eq 'original global instructions') 'AGENTS.md backup content changed'

    & (Join-Path $repoRoot 'scripts/install.ps1') | Out-Null
    Assert-Link (Join-Path $testCodexHome 'AGENTS.md') (Join-Path $repoRoot 'ai-home/AGENTS.md')
    $instructionBackups = @(
        Get-ChildItem -LiteralPath (Join-Path $testCodexHome 'backups') -Filter 'AGENTS.md' -File -Recurse
    )
    Assert-Condition ($instructionBackups.Count -eq 1) 'Idempotent install created another AGENTS.md backup'
    Assert-Condition (
        (Get-Content -LiteralPath $claudeSettingsPath -Raw) -ceq $claudeSettingsBefore
    ) 'Idempotent install changed the merged Claude settings'

    # Pruning: a link into this repository whose source is gone must be removed,
    # while anything the installer did not create must survive. The stale link is
    # fabricated rather than made by deleting a real skill, so the test never
    # mutates the repository it is running from.
    $claudeSkills = Join-Path $testClaudeHome 'skills'
    New-Item -ItemType SymbolicLink -Force `
        -Path (Join-Path $claudeSkills 'removed-skill') `
        -Target (Join-Path $repoRoot '.agents/skills/removed-skill') | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $claudeSkills 'handmade-skill') -Force | Out-Null
    $foreignDir = Join-Path $taskTestRoot 'foreign skills/foreign-skill'
    New-Item -ItemType Directory -Path $foreignDir -Force | Out-Null
    New-Item -ItemType SymbolicLink -Force `
        -Path (Join-Path $claudeSkills 'foreign-skill') -Target $foreignDir | Out-Null

    & (Join-Path $repoRoot 'scripts/install.ps1') -DryRun | Out-Null
    Assert-Condition (
        $null -ne (Get-Item -LiteralPath (Join-Path $claudeSkills 'removed-skill') -Force -ErrorAction SilentlyContinue)
    ) 'Dry-run pruned a stale skill link'

    & (Join-Path $repoRoot 'scripts/install.ps1') | Out-Null
    Assert-Condition (
        -not (Get-Item -LiteralPath (Join-Path $claudeSkills 'removed-skill') -Force -ErrorAction SilentlyContinue)
    ) 'Stale managed skill link was not pruned'
    Assert-Condition (
        Test-Path -LiteralPath (Join-Path $claudeSkills 'handmade-skill') -PathType Container
    ) 'Pruning removed a hand-made skill directory'
    Assert-Condition (
        $null -ne (Get-Item -LiteralPath (Join-Path $claudeSkills 'foreign-skill') -Force -ErrorAction SilentlyContinue)
    ) 'Pruning removed a link pointing outside the repository'
    Assert-Condition (
        Test-Path -LiteralPath $foreignDir -PathType Container
    ) 'Pruning followed a link and deleted its target'

    $pluginLog = Join-Path $taskTestRoot 'plugin-calls.log'
    $claudePluginLog = Join-Path $taskTestRoot 'claude-plugin-calls.log'
    $env:CODEX_PLUGIN_TEST_LOG = $pluginLog
    $env:CLAUDE_PLUGIN_TEST_LOG = $claudePluginLog
    function global:codex {
        Add-Content -LiteralPath $env:CODEX_PLUGIN_TEST_LOG -Value ($args -join ' ')
        $global:LASTEXITCODE = 0
    }
    function global:claude {
        Add-Content -LiteralPath $env:CLAUDE_PLUGIN_TEST_LOG -Value ($args -join ' ')
        $global:LASTEXITCODE = 0
    }

    $env:CODEX_HOME = Join-Path $taskTestRoot 'plugin codex'
    $env:AGENTS_HOME = Join-Path $taskTestRoot 'plugin agents'
    $env:CLAUDE_CONFIG_DIR = Join-Path $taskTestRoot 'plugin claude'
    & (Join-Path $repoRoot 'scripts/install.ps1') -Plugins | Out-Null

    # Both manifests ignore blank lines and lines whose first non-blank character
    # is a hash, so the expected calls come from the entries alone.
    $expectedPluginCalls = @(
        Get-Content -LiteralPath (Join-Path $repoRoot 'codex-plugins.txt') |
            Where-Object { $_ -notmatch '^\s*(#|$)' } |
            ForEach-Object { "plugin add $($_.Trim())" }
    )
    $actualPluginCalls = @(Get-Content -LiteralPath $pluginLog)
    Assert-Condition (
        ($actualPluginCalls.Count -eq $expectedPluginCalls.Count) -and
        (($actualPluginCalls -join "`n") -eq ($expectedPluginCalls -join "`n"))
    ) 'Installer did not install the expected Codex plugins'

    # A Claude Code plugin needs its marketplace registered first, so each
    # manifest entry must produce the marketplace add before the install.
    $expectedClaudeCalls = @(
        Get-Content -LiteralPath (Join-Path $repoRoot 'claude-plugins.txt') |
            Where-Object { $_ -notmatch '^\s*(#|$)' } |
            ForEach-Object {
                $fields = $_.Trim() -split '\s+', 2
                "plugin marketplace add $($fields[1].Trim())"
                "plugin install $($fields[0])"
            }
    )
    $actualClaudeCalls = @(Get-Content -LiteralPath $claudePluginLog)
    Assert-Condition (
        ($actualClaudeCalls.Count -eq $expectedClaudeCalls.Count) -and
        (($actualClaudeCalls -join "`n") -eq ($expectedClaudeCalls -join "`n"))
    ) 'Installer did not install the expected Claude Code plugins'

    # A machine with only one agent must still install that agent's plugins. The
    # scenario needs Claude Code genuinely absent, so it is skipped where one is
    # installed rather than asserted against an environment that cannot produce
    # it.
    Remove-Item Function:\claude -ErrorAction SilentlyContinue
    if (Get-Command claude -ErrorAction SilentlyContinue) {
        Write-Output 'note: claude is installed; skipping the missing-agent scenario'
    }
    else {
        $missingAgentLog = Join-Path $taskTestRoot 'missing-agent-plugin-calls.log'
        $unusedClaudeLog = Join-Path $taskTestRoot 'unused-claude-calls.log'
        $env:CODEX_PLUGIN_TEST_LOG = $missingAgentLog
        $env:CLAUDE_PLUGIN_TEST_LOG = $unusedClaudeLog
        $env:CODEX_HOME = Join-Path $taskTestRoot 'one agent codex'
        $env:AGENTS_HOME = Join-Path $taskTestRoot 'one agent agents'
        $env:CLAUDE_CONFIG_DIR = Join-Path $taskTestRoot 'one agent claude'
        $missingAgentWarnings = @()
        & (Join-Path $repoRoot 'scripts/install.ps1') -Plugins -WarningVariable missingAgentWarnings |
            Out-Null

        Assert-Condition (
            ($missingAgentWarnings -join "`n") -match 'claude is not installed'
        ) 'A missing agent did not report a skip warning'
        Assert-Condition (
            -not (Test-Path -LiteralPath $unusedClaudeLog)
        ) 'Installer invoked a missing agent'
        Assert-Condition (
            (@(Get-Content -LiteralPath $missingAgentLog) -join "`n") -eq ($expectedPluginCalls -join "`n")
        ) 'A missing Claude Code install blocked Codex plugin installation'
    }

    function global:claude {
        Add-Content -LiteralPath $env:CLAUDE_PLUGIN_TEST_LOG -Value ($args -join ' ')
        $global:LASTEXITCODE = 0
    }

    $dryRunCodexHome = Join-Path $taskTestRoot 'dry run codex'
    $dryRunAgentsHome = Join-Path $taskTestRoot 'dry run agents'
    $dryRunClaudeHome = Join-Path $taskTestRoot 'dry run claude'
    $dryRunPluginLog = Join-Path $taskTestRoot 'dry-run-plugin-calls.log'
    $dryRunClaudePluginLog = Join-Path $taskTestRoot 'dry-run-claude-plugin-calls.log'
    $env:CODEX_PLUGIN_TEST_LOG = $dryRunPluginLog
    $env:CLAUDE_PLUGIN_TEST_LOG = $dryRunClaudePluginLog
    $env:CODEX_HOME = $dryRunCodexHome
    $env:AGENTS_HOME = $dryRunAgentsHome
    $env:CLAUDE_CONFIG_DIR = $dryRunClaudeHome
    & (Join-Path $repoRoot 'scripts/install.ps1') -DryRun -Plugins | Out-Null
    Assert-Condition (-not (Test-Path -LiteralPath $dryRunCodexHome)) 'Dry-run created CODEX_HOME'
    Assert-Condition (-not (Test-Path -LiteralPath $dryRunAgentsHome)) 'Dry-run created AGENTS_HOME'
    Assert-Condition (-not (Test-Path -LiteralPath $dryRunClaudeHome)) 'Dry-run created CLAUDE_CONFIG_DIR'
    Assert-Condition (-not (Test-Path -LiteralPath $dryRunPluginLog)) 'Dry-run invoked Codex plugin installation'
    Assert-Condition (
        -not (Test-Path -LiteralPath $dryRunClaudePluginLog)
    ) 'Dry-run invoked Claude Code plugin installation'

    Write-Output 'installer integration test passed'
}
finally {
    if ($null -eq $previousCodexHome) {
        Remove-Item Env:CODEX_HOME -ErrorAction SilentlyContinue
    }
    else {
        $env:CODEX_HOME = $previousCodexHome
    }

    if ($null -eq $previousAgentsHome) {
        Remove-Item Env:AGENTS_HOME -ErrorAction SilentlyContinue
    }
    else {
        $env:AGENTS_HOME = $previousAgentsHome
    }

    if ($null -eq $previousClaudeHome) {
        Remove-Item Env:CLAUDE_CONFIG_DIR -ErrorAction SilentlyContinue
    }
    else {
        $env:CLAUDE_CONFIG_DIR = $previousClaudeHome
    }

    if ($null -eq $previousPluginTestLog) {
        Remove-Item Env:CODEX_PLUGIN_TEST_LOG -ErrorAction SilentlyContinue
    }
    else {
        $env:CODEX_PLUGIN_TEST_LOG = $previousPluginTestLog
    }

    if ($null -eq $previousClaudePluginTestLog) {
        Remove-Item Env:CLAUDE_PLUGIN_TEST_LOG -ErrorAction SilentlyContinue
    }
    else {
        $env:CLAUDE_PLUGIN_TEST_LOG = $previousClaudePluginTestLog
    }

    if ($null -eq $previousUserProfile) {
        Remove-Item Env:USERPROFILE -ErrorAction SilentlyContinue
    }
    else {
        $env:USERPROFILE = $previousUserProfile
    }

    Remove-Item Function:\codex -ErrorAction SilentlyContinue
    Remove-Item Function:\claude -ErrorAction SilentlyContinue

    $tempRoot = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath())
    $normalizedTestRoot = [System.IO.Path]::GetFullPath($taskTestRoot)
    if (
        $normalizedTestRoot.StartsWith($tempRoot, [StringComparison]::OrdinalIgnoreCase) -and
        (Split-Path -Leaf $normalizedTestRoot).StartsWith('ai-install-test-')
    ) {
        Remove-Item -LiteralPath $normalizedTestRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}
