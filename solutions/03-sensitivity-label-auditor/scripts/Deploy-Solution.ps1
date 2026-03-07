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
    Slug = '03-sensitivity-label-auditor'
    DisplayName = 'Sensitivity Label Coverage Auditor'
    Controls = @('1.5', '2.2', '3.11', '3.12')
    Tier = $ConfigurationTier
}

if ($PSCmdlet.ShouldProcess($solution.DisplayName, 'Create scaffold deployment manifest')) {
    $null = New-Item -ItemType Directory -Path $OutputPath -Force
    $outputFile = Join-Path $OutputPath ('03-sensitivity-label-auditor-deployment.json')
    $solution | ConvertTo-Json -Depth 6 | Set-Content -Path $outputFile -Encoding utf8
    Write-Output $solution
}
