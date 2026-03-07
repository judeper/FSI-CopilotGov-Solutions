[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet('baseline', 'recommended', 'regulated')]
    [string]$ConfigurationTier = 'baseline'
)

Import-Module (Join-Path $PSScriptRoot '..\..\..\scripts\common\IntegrationConfig.psm1') -Force
$status = if ($ConfigurationTier -eq 'regulated') { 'partial' } else { 'implemented' }
[pscustomobject]@{
    Solution = 'Regulatory Compliance Dashboard'
    Tier = $ConfigurationTier
    Status = $status
    Controls = @('3.7', '3.8', '3.12', '3.13', '4.5', '4.7')
}
