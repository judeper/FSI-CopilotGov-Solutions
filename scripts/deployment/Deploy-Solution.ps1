[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [string]$SolutionSlug,
    [Parameter()]
    [ValidateSet('baseline', 'recommended', 'regulated')]
    [string]$Tier = 'baseline'
)

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$scriptPath = Join-Path $repoRoot (Join-Path 'solutions' (Join-Path $SolutionSlug 'scripts\Deploy-Solution.ps1'))
if (-not (Test-Path -Path $scriptPath)) {
    throw "Solution deployment script not found: $scriptPath"
}
if ($PSCmdlet.ShouldProcess($SolutionSlug, 'Invoke solution deployment script')) {
    & $scriptPath -ConfigurationTier $Tier
}
