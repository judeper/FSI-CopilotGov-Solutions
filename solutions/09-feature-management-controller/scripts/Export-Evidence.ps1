[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet('baseline', 'recommended', 'regulated')]
    [string]$ConfigurationTier = 'baseline',
    [Parameter()]
    [string]$OutputPath = (Join-Path $PSScriptRoot '..\artifacts')
)

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..\..')
Import-Module (Join-Path $repoRoot 'scripts\common\EvidenceExport.psm1') -Force

$controls = @(
            [pscustomobject]@{ controlId = '2.6'; status = 'implemented'; notes = 'Scaffold evidence entry.' }
    [pscustomobject]@{ controlId = '4.1'; status = 'implemented'; notes = 'Scaffold evidence entry.' }
    [pscustomobject]@{ controlId = '4.2'; status = 'implemented'; notes = 'Scaffold evidence entry.' }
    [pscustomobject]@{ controlId = '4.3'; status = 'implemented'; notes = 'Scaffold evidence entry.' }
    [pscustomobject]@{ controlId = '4.4'; status = 'implemented'; notes = 'Scaffold evidence entry.' }
    [pscustomobject]@{ controlId = '4.12'; status = 'implemented'; notes = 'Scaffold evidence entry.' }
    [pscustomobject]@{ controlId = '4.13'; status = 'implemented'; notes = 'Scaffold evidence entry.' }
)

Export-SolutionEvidencePackage `
    -Solution '09-feature-management-controller' `
    -SolutionCode 'FMC' `
    -Tier $ConfigurationTier `
    -OutputPath $OutputPath `
    -Summary @{ overallStatus = 'implemented'; recordCount = $controls.Count; findingCount = 0; exceptionCount = 0 } `
    -Controls $controls `
    -Artifacts @()
