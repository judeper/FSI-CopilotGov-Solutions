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
    Slug = '09-feature-management-controller'
    DisplayName = 'Copilot Feature Management Controller'
    Controls = @('2.6', '4.1', '4.2', '4.3', '4.4', '4.12', '4.13')
    Tier = $ConfigurationTier
}

if ($PSCmdlet.ShouldProcess($solution.DisplayName, 'Create scaffold deployment manifest')) {
    $null = New-Item -ItemType Directory -Path $OutputPath -Force
    $outputFile = Join-Path $OutputPath ('09-feature-management-controller-deployment.json')
    $solution | ConvertTo-Json -Depth 6 | Set-Content -Path $outputFile -Encoding utf8
    Write-Output $solution
}
