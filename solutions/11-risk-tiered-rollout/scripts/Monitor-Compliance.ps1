[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet('baseline', 'recommended', 'regulated')]
    [string]$ConfigurationTier = 'baseline'
)

Import-Module (Join-Path $PSScriptRoot '..\..\..\scripts\common\IntegrationConfig.psm1') -Force
$status = if ($ConfigurationTier -eq 'regulated') { 'partial' } else { 'implemented' }
[pscustomobject]@{
    Solution = 'Risk-Tiered Rollout Automation'
    Tier = $ConfigurationTier
    Status = $status
    Controls = @('1.9', '1.11', '1.12', '4.12')
}
