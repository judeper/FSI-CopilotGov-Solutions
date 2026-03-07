[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter()]
    [ValidateSet('baseline', 'recommended', 'regulated')]
    [string]$ConfigurationTier = 'baseline',
    [Parameter()]
    [string]$OutputPath = (Join-Path $PSScriptRoot '..\artifacts')
)

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..\..')
Import-Module (Join-Path $repoRoot 'scripts\common\IntegrationConfig.psm1') -Force

$solution = [pscustomobject]@{
    Slug = '05-dlp-policy-governance'
    DisplayName = 'DLP Policy Governance for Copilot'
    Controls = @('2.1', '3.10', '3.12')
    Tier = $ConfigurationTier
}

if ($PSCmdlet.ShouldProcess($solution.DisplayName, 'Create scaffold deployment manifest')) {
    $null = New-Item -ItemType Directory -Path $OutputPath -Force
    $outputFile = Join-Path $OutputPath ('05-dlp-policy-governance-deployment.json')
    $solution | ConvertTo-Json -Depth 6 | Set-Content -Path $outputFile -Encoding utf8
    Write-Output $solution
}
