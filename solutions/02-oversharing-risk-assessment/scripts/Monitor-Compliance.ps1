[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet('baseline', 'recommended', 'regulated')]
    [string]$ConfigurationTier = 'baseline'
)

Import-Module (Join-Path $PSScriptRoot '..\..\..\scripts\common\IntegrationConfig.psm1') -Force
$status = if ($ConfigurationTier -eq 'regulated') { 'partial' } else { 'implemented' }
[pscustomobject]@{
    Solution = 'Oversharing Risk Assessment and Remediation'
    Tier = $ConfigurationTier
    Status = $status
    Controls = @('1.2', '1.3', '1.4', '1.6', '2.5', '2.12')
}
