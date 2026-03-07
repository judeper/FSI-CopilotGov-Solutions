[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet('baseline', 'recommended', 'regulated')]
    [string]$ConfigurationTier = 'baseline'
)

Import-Module (Join-Path $PSScriptRoot '..\..\..\scripts\common\IntegrationConfig.psm1') -Force
$status = if ($ConfigurationTier -eq 'regulated') { 'partial' } else { 'implemented' }
[pscustomobject]@{
    Solution = 'Copilot Connector and Plugin Governance'
    Tier = $ConfigurationTier
    Status = $status
    Controls = @('1.13', '2.13', '2.14', '4.13')
}
