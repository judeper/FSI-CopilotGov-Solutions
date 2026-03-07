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
    Slug = '10-connector-plugin-governance'
    DisplayName = 'Copilot Connector and Plugin Governance'
    Controls = @('1.13', '2.13', '2.14', '4.13')
    Tier = $ConfigurationTier
}

if ($PSCmdlet.ShouldProcess($solution.DisplayName, 'Create scaffold deployment manifest')) {
    $null = New-Item -ItemType Directory -Path $OutputPath -Force
    $outputFile = Join-Path $OutputPath ('10-connector-plugin-governance-deployment.json')
    $solution | ConvertTo-Json -Depth 6 | Set-Content -Path $outputFile -Encoding utf8
    Write-Output $solution
}
