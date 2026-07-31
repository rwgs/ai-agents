[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
# Codex used to write approvals into this file through a link. Nothing the
# installer does may touch it now, so its contents are checked at the end.
$repoRulesHash = (Get-FileHash -LiteralPath (Join-Path $repoRoot 'ai-home/rules/default.rules') -Algorithm SHA256).Hash
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
    New-Item -ItemType Directory -Path (Join-Path $testCodexHome 'rules') -Force | Out-Null
    New-Item -ItemType Directory -Path $testClaudeHome -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $testGitHubRepo '.git') -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $testCodexHome 'AGENTS.md') -Value 'original global instructions'

    # Seed the Codex state a real machine has: marketplaces, MCP servers, a
    # desktop block, a trust entry outside the searched roots, and a setting
    # whose value disagrees with the baseline. None of it may be lost.
    Set-Content -LiteralPath (Join-Path $testCodexHome 'config.toml') -Value @'
model = "gpt-5.6-sol"
model_verbosity = "medium"

[features]
js_repl = false

[marketplaces.openai-bundled]
enabled = true

[mcp_servers.node_repl]
command = 'node_repl.exe'

[projects.'C:\elsewhere\machine project']
trust_level = "trusted"

[desktop]
conversationDetailMode = "STEPS_PROSE"
'@

    # Codex records interactive approvals here, so the file is the machine's own.
    Set-Content -LiteralPath (Join-Path $testCodexHome 'rules/default.rules') -Value @'
prefix_rule(pattern=["git", "status"], decision="allow")
prefix_rule(pattern=["sed"], decision="allow")
'@

    # Seed real-looking Claude state so the merge is proven non-destructive.
    Set-Content -LiteralPath (Join-Path $testClaudeHome 'settings.json') -Value @'
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
'@

    $env:USERPROFILE = $testUserHome
    $env:CODEX_HOME = $testCodexHome
    $env:AGENTS_HOME = $testAgentsHome
    $env:CLAUDE_CONFIG_DIR = $testClaudeHome
    $installLog = @(& (Join-Path $repoRoot 'scripts/install.ps1'))

    Assert-Link (Join-Path $testCodexHome 'AGENTS.md') (Join-Path $repoRoot 'ai-home/AGENTS.md')
    $installedConfigPath = Join-Path $testCodexHome 'config.toml'
    $installedConfig = Get-Item -LiteralPath $installedConfigPath -Force
    Assert-Condition ($installedConfig.LinkType -ne 'SymbolicLink') "Expected merged config file: $installedConfigPath"
    $installedConfigContent = [System.IO.File]::ReadAllText($installedConfigPath)
    $escapedGitHubRoot = (Join-Path $testUserHome 'github').Replace('\', '\\')
    $escapedGitHubRepo = $testGitHubRepo.Replace('\', '\\')
    Assert-Condition (
        $installedConfigContent.Contains("[projects.`"$escapedGitHubRoot`"]")
    ) 'Generated config does not trust the user GitHub root'
    Assert-Condition (
        $installedConfigContent.Contains("[projects.`"$escapedGitHubRepo`"]")
    ) 'Generated config does not trust a nested Git repository'
    # The baseline asks before acting. Installing must never escalate a machine
    # to Codex's unrestricted preset.
    Assert-Condition (
        $installedConfigContent.Contains('sandbox_mode = "workspace-write"')
    ) 'Installed config does not sandbox writes to the workspace'
    Assert-Condition (
        $installedConfigContent.Contains('approval_policy = "on-request"')
    ) 'Installed config does not ask for approval'
    Assert-Condition (
        -not $installedConfigContent.Contains('danger-full-access')
    ) 'Installed config grants unrestricted access'

    # Machine-owned Codex state survives the merge.
    foreach ($machineEntry in @(
            '[marketplaces.openai-bundled]',
            '[mcp_servers.node_repl]',
            '[desktop]',
            "[projects.'C:\elsewhere\machine project']",
            'js_repl = false'
        )) {
        Assert-Condition (
            $installedConfigContent.Contains($machineEntry)
        ) "Merge lost machine-owned config state: $machineEntry"
    }

    # A managed key the machine already sets differently is left alone and
    # reported, because nothing proves this installer wrote it.
    Assert-Condition (
        $installedConfigContent.Contains('model_verbosity = "medium"')
    ) 'Merge overwrote a machine-owned value'
    Assert-Condition (
        ($installLog -join "`n") -match '(?m)^preserved: .*model_verbosity = "medium"'
    ) 'Merge did not report the preserved machine-owned value'
    # A managed key inside a table the machine already has joins that table.
    Assert-Condition (
        $installedConfigContent.Contains('memories = true')
    ) 'Merge did not add a managed key to an existing table'

    # Codex writes approvals into its rules directory, so the directory is the
    # machine's and the curated rules are merged into its file.
    $rulesDirectory = Get-Item -LiteralPath (Join-Path $testCodexHome 'rules') -Force
    Assert-Condition (
        $rulesDirectory.PSIsContainer -and $rulesDirectory.LinkType -ne 'SymbolicLink'
    ) 'Expected a real rules directory'
    $installedRulesPath = Join-Path $testCodexHome 'rules/default.rules'
    $installedRules = [System.IO.File]::ReadAllText($installedRulesPath)
    Assert-Condition (
        $installedRules.Contains('prefix_rule(pattern=["git", "status"], decision="allow")')
    ) 'Merge lost an interactively approved rule'
    Assert-Condition (
        $installedRules.Contains('prefix_rule(pattern=["rtk"], decision="allow")')
    ) 'Merge did not add the curated rules'
    Assert-Condition (
        Test-Path -LiteralPath (Join-Path $testAgentsHome 'ai-install-state.json') -PathType Leaf
    ) 'Installer recorded no provenance state'
    Assert-Link (Join-Path $testCodexHome 'ollama.config.toml') (Join-Path $repoRoot 'ai-home/codex/ollama.config.toml')
    Assert-Link (Join-Path $testCodexHome 'llamacpp.config.toml') (Join-Path $repoRoot 'ai-home/codex/llamacpp.config.toml')

    Get-ChildItem -LiteralPath (Join-Path $repoRoot '.agents/skills') -Directory |
        ForEach-Object {
            Assert-Link (Join-Path (Join-Path $testAgentsHome 'skills') $_.Name) $_.FullName
            Assert-Link (Join-Path (Join-Path $testClaudeHome 'skills') $_.Name) $_.FullName
        }

    Assert-Link (Join-Path $testClaudeHome 'CLAUDE.md') (Join-Path $repoRoot 'ai-home/AGENTS.md')

    $claudeSettingsPath = Join-Path $testClaudeHome 'settings.json'
    # Plain ConvertFrom-Json, because Windows PowerShell 5.1 has no -AsHashtable
    # and the installer has to run there too.
    $mergedSettings = Get-Content -LiteralPath $claudeSettingsPath -Raw | ConvertFrom-Json
    $mergedPermissions = $mergedSettings.permissions
    $mergedAllow = @($mergedPermissions.allow)
    Assert-Condition ($mergedSettings.model -eq 'opus[1m]') 'Unrelated Claude setting was lost'
    Assert-Condition (
        $mergedPermissions.additionalDirectories[0] -eq '/tmp'
    ) 'Claude additionalDirectories changed'
    Assert-Condition (
        ($mergedPermissions.PSObject.Properties.Name -notcontains 'deny') -and
        ($mergedPermissions.PSObject.Properties.Name -notcontains 'ask')
    ) 'Absent Claude permission keys were invented'
    Assert-Condition (
        $mergedAllow[0] -eq 'Bash(git add *)'
    ) 'Existing Claude allow entry was lost or reordered'
    # Windows PowerShell 5.1 escapes these characters when it serializes JSON and
    # PowerShell 7 does not, so an unnormalized merge rewrites approved commands.
    Assert-Condition (
        $mergedAllow -contains "Bash(grep -n 'a&b' <c> *)"
    ) 'Claude allow entry with escapable characters was rewritten'
    Assert-Condition (
        (Get-Content -LiteralPath $claudeSettingsPath -Raw).Contains("'a&b' <c>")
    ) 'Merged Claude settings escaped characters the source file wrote literally'
    Assert-Condition (
        $mergedAllow -contains 'Bash(rtk *)' -and $mergedAllow -contains 'PowerShell(rtk *)'
    ) 'Derived Claude allow entries missing'
    Assert-Condition (
        $mergedAllow.Count -eq ($mergedAllow | Select-Object -Unique).Count
    ) 'Claude merge introduced duplicates'
    $claudeSettingsBefore = Get-Content -LiteralPath $claudeSettingsPath -Raw
    $configBefore = [System.IO.File]::ReadAllText($installedConfigPath)
    $rulesBefore = [System.IO.File]::ReadAllText($installedRulesPath)

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
    Assert-Condition (
        [System.IO.File]::ReadAllText($installedConfigPath) -ceq $configBefore
    ) 'Idempotent install changed the merged Codex configuration'
    Assert-Condition (
        [System.IO.File]::ReadAllText($installedRulesPath) -ceq $rulesBefore
    ) 'Idempotent install changed the merged Codex rules'

    # A previous installation linked the rules directory into this repository,
    # and Codex then wrote its approvals there. Installing must undo that link
    # and say where those approvals went.
    Remove-Item -LiteralPath (Join-Path $testCodexHome 'rules') -Recurse -Force
    New-Item -ItemType SymbolicLink -Force `
        -Path (Join-Path $testCodexHome 'rules') `
        -Target (Join-Path $repoRoot 'ai-home/rules') | Out-Null
    $migrationLog = @(& (Join-Path $repoRoot 'scripts/install.ps1'))
    $migratedRules = Get-Item -LiteralPath (Join-Path $testCodexHome 'rules') -Force
    Assert-Condition (
        $migratedRules.PSIsContainer -and $migratedRules.LinkType -ne 'SymbolicLink'
    ) 'Installer left the rules directory linked into this repository'
    Assert-Condition (
        ($migrationLog -join "`n") -match '(?m)^unlinked: '
    ) 'Installer did not report unlinking the rules directory'
    Assert-Condition (
        ($migrationLog -join "`n") -match '(?m)^note: approvals recorded through that link are in '
    ) 'Installer did not report where approvals recorded through the link are'
    Assert-Condition (
        [System.IO.File]::ReadAllText($installedRulesPath).Contains(
            'prefix_rule(pattern=["rtk"], decision="allow")')
    ) 'The replacement rules file does not carry the curated rules'

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

    # Withdrawal and preservation are the ownership model's hard cases. They are
    # driven against the installer's own merge functions with temporary curated
    # sources, because reaching them through the installer itself would mean
    # editing this repository's curated files while it runs.
    $provenanceRoot = Join-Path $taskTestRoot 'provenance'
    New-Item -ItemType Directory -Path (Join-Path $provenanceRoot 'rules') -Force | Out-Null
    $curatedAll = Join-Path $provenanceRoot 'curated-all.rules'
    $curatedReduced = Join-Path $provenanceRoot 'curated-reduced.rules'
    Copy-Item -LiteralPath (Join-Path $repoRoot 'ai-home/rules/default.rules') -Destination $curatedAll
    Set-Content -LiteralPath $curatedReduced -Value (
        Get-Content -LiteralPath $curatedAll |
            Where-Object { $_ -notmatch '^prefix_rule\(pattern=\["(jq|sed)"\], decision="allow"\)$' }
    )

    # sed is approved before the first merge, so the grant is the machine's even
    # though the curated set spells it identically. git status is never curated.
    $provenanceRules = Join-Path $provenanceRoot 'rules/default.rules'
    Set-Content -LiteralPath $provenanceRules -Value @'
prefix_rule(pattern=["git", "status"], decision="allow")
prefix_rule(pattern=["sed"], decision="allow")
'@
    $provenanceClaude = Join-Path $provenanceRoot 'settings.json'
    Set-Content -LiteralPath $provenanceClaude -Value @'
{
  "permissions": {
    "allow": [
      "Bash(sed *)"
    ]
  }
}
'@

    $parseErrors = $null
    $installerAst = [System.Management.Automation.Language.Parser]::ParseFile(
        (Join-Path $repoRoot 'scripts/install.ps1'), [ref] $null, [ref] $parseErrors)
    Assert-Condition ($parseErrors.Count -eq 0) 'install.ps1 does not parse'
    foreach ($node in $installerAst.FindAll(
            { param($item) $item -is [System.Management.Automation.Language.FunctionDefinitionAst] },
            $true)) {
        . ([scriptblock]::Create($node.Extent.Text))
    }

    # The dot-sourced functions read the installer's own script variables by
    # name, so they are set rather than passed.
    $provenanceConfig = Join-Path $provenanceRoot 'config.toml'
    $mergeContext = @{
        DryRun         = $false
        codexHome      = $provenanceRoot
        claudeSettings = $provenanceClaude
        configSource   = Join-Path $repoRoot 'ai-home/codex/config.toml'
        stateFile      = Join-Path $provenanceRoot 'state.json'
        stateVersion   = 1
        backupRoot     = Join-Path $provenanceRoot 'backups'
        trustRoots     = @((Join-Path $provenanceRoot 'github'))
    }
    foreach ($name in $mergeContext.Keys) {
        Set-Variable -Name $name -Value $mergeContext[$name] -Scope Script
    }

    function Invoke-ProvenanceMerge {
        param(
            [Parameter(Mandatory)]
            [string] $Source
        )

        $script:rulesSource = $Source
        $script:mergeReport = [System.Collections.Generic.List[string]]::new()
        return @(Invoke-AgentStateMerge)
    }

    [void] (Invoke-ProvenanceMerge -Source $curatedAll)
    Assert-Condition (
        [System.IO.File]::ReadAllText($provenanceRules).Contains(
            'prefix_rule(pattern=["jq"], decision="allow")')
    ) 'First merge did not add a curated rule'
    Assert-Condition (
        [System.IO.File]::ReadAllText($provenanceClaude).Contains('"Bash(jq *)"')
    ) 'First merge did not add a derived permission'

    $secondLog = Invoke-ProvenanceMerge -Source $curatedReduced
    $mergedRules = [System.IO.File]::ReadAllText($provenanceRules)
    $mergedClaude = [System.IO.File]::ReadAllText($provenanceClaude)
    Assert-Condition (
        -not $mergedRules.Contains('prefix_rule(pattern=["jq"], decision="allow")')
    ) 'An uncurated rule this installer added was not withdrawn'
    Assert-Condition (
        -not $mergedClaude.Contains('"Bash(jq *)"') -and
        -not $mergedClaude.Contains('"PowerShell(jq *)"')
    ) 'An uncurated permission this installer added was not withdrawn'
    Assert-Condition (
        $mergedRules.Contains('prefix_rule(pattern=["sed"], decision="allow")')
    ) 'A rule approved before installation was withdrawn'
    Assert-Condition (
        $mergedClaude.Contains('"Bash(sed *)"')
    ) 'A permission approved before installation was withdrawn'
    Assert-Condition (
        ($secondLog -join "`n") -match '(?m)^preserved: Bash\(sed \*\) is no longer curated'
    ) 'The preserved identical permission was not reported'
    Assert-Condition (
        $mergedRules.Contains('prefix_rule(pattern=["git", "status"], decision="allow")')
    ) 'Withdrawal removed a rule the machine wrote'

    # A managed key the machine has since changed is left as the machine set it.
    [System.IO.File]::WriteAllText(
        $provenanceConfig,
        [System.IO.File]::ReadAllText($provenanceConfig).Replace(
            'approval_policy = "on-request"', 'approval_policy = "never"'),
        [System.Text.UTF8Encoding]::new($false))
    $thirdLog = Invoke-ProvenanceMerge -Source $curatedAll
    Assert-Condition (
        [System.IO.File]::ReadAllText($provenanceConfig).Contains('approval_policy = "never"')
    ) 'Merge overwrote a managed key the machine changed'
    Assert-Condition (
        ($thirdLog -join "`n") -match '(?m)^preserved: .*approval_policy changed since installation'
    ) 'Merge did not report the managed key the machine changed'

    # Reverting to the recorded value hands the key back, so management resumes.
    [System.IO.File]::WriteAllText(
        $provenanceConfig,
        [System.IO.File]::ReadAllText($provenanceConfig).Replace(
            'approval_policy = "never"', 'approval_policy = "on-request"'),
        [System.Text.UTF8Encoding]::new($false))
    [void] (Invoke-ProvenanceMerge -Source $curatedReduced)
    Assert-Condition (
        [System.IO.File]::ReadAllText($provenanceConfig).Contains('approval_policy = "on-request"')
    ) 'Merge lost a managed key after the machine reverted it'

    Assert-Condition (
        (Get-FileHash -LiteralPath (Join-Path $repoRoot 'ai-home/rules/default.rules') -Algorithm SHA256).Hash -eq
        $repoRulesHash
    ) "The installer wrote into this repository's curated rule file"

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
