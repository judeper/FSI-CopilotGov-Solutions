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
    Slug = '13-dora-resilience-monitor'
    DisplayName = 'DORA Operational Resilience Monitor'
    Controls = @('2.7', '4.9', '4.10', '4.11')
    Tier = $ConfigurationTier
}

if ($PSCmdlet.ShouldProcess($solution.DisplayName, 'Create scaffold deployment manifest')) {
    $null = New-Item -ItemType Directory -Path $OutputPath -Force
    $outputFile = Join-Path $OutputPath ('13-dora-resilience-monitor-deployment.json')
    $solution | ConvertTo-Json -Depth 6 | Set-Content -Path $outputFile -Encoding utf8
    Write-Output $solution
}
