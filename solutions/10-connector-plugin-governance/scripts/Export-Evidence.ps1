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
            [pscustomobject]@{ controlId = '1.13'; status = 'implemented'; notes = 'Scaffold evidence entry.' }
    [pscustomobject]@{ controlId = '2.13'; status = 'implemented'; notes = 'Scaffold evidence entry.' }
    [pscustomobject]@{ controlId = '2.14'; status = 'implemented'; notes = 'Scaffold evidence entry.' }
    [pscustomobject]@{ controlId = '4.13'; status = 'implemented'; notes = 'Scaffold evidence entry.' }
)

Export-SolutionEvidencePackage `
    -Solution '10-connector-plugin-governance' `
    -SolutionCode 'CPG' `
    -Tier $ConfigurationTier `
    -OutputPath $OutputPath `
    -Summary @{ overallStatus = 'implemented'; recordCount = $controls.Count; findingCount = 0; exceptionCount = 0 } `
    -Controls $controls `
    -Artifacts @()
