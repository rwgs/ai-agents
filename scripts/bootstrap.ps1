# Clone or update this repository, then run its installer from the clone.
#
# The installer links into the clone, so the clone is not temporary: it is where
# the managed instructions, rules, and skills live afterwards. Moving or deleting
# it breaks every link, which is why this script clones to a fixed location and
# updates that same location on a rerun.
[CmdletBinding()]
param(
    [Alias('dry-run')]
    [switch] $DryRun,

    [switch] $Plugins
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$userHome = if ($env:USERPROFILE) { $env:USERPROFILE } else { $env:HOME }
$repoUrl = if ($env:AI_REPO_URL) { $env:AI_REPO_URL } else { 'https://github.com/rwgs/ai.git' }
$branch = if ($env:AI_BRANCH) { $env:AI_BRANCH } else { 'main' }
$installDir = if ($env:AI_INSTALL_DIR) {
    $env:AI_INSTALL_DIR
}
else {
    Join-Path $userHome 'Development/ai'
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw 'git is required'
}

# A token is only needed while the repository is private, and it is passed per
# command rather than written into the remote URL, so it never lands in
# .git/config where every later fetch would leak it.
$gitArgument = @()
if ($env:AI_GIT_TOKEN) {
    $authorization = [System.Convert]::ToBase64String(
        [System.Text.Encoding]::ASCII.GetBytes("x-access-token:$($env:AI_GIT_TOKEN)")
    )
    $gitArgument = @('-c', "http.extraheader=Authorization: Basic $authorization")
}

function Invoke-Git {
    param(
        [Parameter(Mandatory)]
        [string[]] $Argument,

        [switch] $Authenticated
    )

    $global:LASTEXITCODE = 0
    $prefix = if ($Authenticated) { $gitArgument } else { @() }
    & git @prefix @Argument
    if ($LASTEXITCODE -ne 0) {
        throw "git $($Argument -join ' ') failed with exit code $LASTEXITCODE."
    }
}

if (Test-Path -LiteralPath (Join-Path $installDir '.git')) {
    Write-Output "updating $installDir"
    Invoke-Git -Authenticated -Argument @('-C', $installDir, 'fetch', '--quiet', 'origin', $branch)
    Invoke-Git -Argument @('-C', $installDir, 'checkout', '--quiet', $branch)
    # Fast-forward only: a local edit or a rewritten history stops the run
    # instead of being merged or discarded.
    Invoke-Git -Argument @('-C', $installDir, 'merge', '--ff-only', '--quiet', "origin/$branch")
}
else {
    Write-Output "cloning $repoUrl into $installDir"
    $parent = Split-Path -Parent $installDir
    if ($parent -and -not (Test-Path -LiteralPath $parent -PathType Container)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    Invoke-Git -Authenticated -Argument @('clone', '--quiet', '--branch', $branch, $repoUrl, $installDir)
}

$revision = & git -C $installDir rev-parse --short HEAD
Write-Output "installed from $installDir at $revision"

# A hashtable, because splatting an array would pass -DryRun as a positional
# argument and the installer takes named switches.
$installerArgument = @{}
if ($DryRun) { $installerArgument['DryRun'] = $true }
if ($Plugins) { $installerArgument['Plugins'] = $true }

& (Join-Path $installDir 'scripts/install.ps1') @installerArgument
