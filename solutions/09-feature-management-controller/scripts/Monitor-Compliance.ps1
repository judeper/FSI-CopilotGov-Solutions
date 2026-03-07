[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet('baseline', 'recommended', 'regulated')]
    [string]$ConfigurationTier = 'baseline'
)

Import-Module (Join-Path $PSScriptRoot '..\..\..\scripts\common\IntegrationConfig.psm1') -Force
$status = if ($ConfigurationTier -eq 'regulated') { 'partial' } else { 'implemented' }
[pscustomobject]@{
    Solution = 'Copilot Feature Management Controller'
    Tier = $ConfigurationTier
    Status = $status
    Controls = @('2.6', '4.1', '4.2', '4.3', '4.4', '4.12', '4.13')
}
