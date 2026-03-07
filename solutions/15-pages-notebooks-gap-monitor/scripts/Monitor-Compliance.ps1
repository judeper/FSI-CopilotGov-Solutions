[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet('baseline', 'recommended', 'regulated')]
    [string]$ConfigurationTier = 'baseline'
)

Import-Module (Join-Path $PSScriptRoot '..\..\..\scripts\common\IntegrationConfig.psm1') -Force
$status = if ($ConfigurationTier -eq 'regulated') { 'partial' } else { 'implemented' }
[pscustomobject]@{
    Solution = 'Copilot Pages and Notebooks Compliance Gap Monitor'
    Tier = $ConfigurationTier
    Status = $status
    Controls = @('2.11', '3.2', '3.3', '3.11')
}
