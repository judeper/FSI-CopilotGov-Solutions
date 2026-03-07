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
            [pscustomobject]@{ controlId = '1.9'; status = 'implemented'; notes = 'Scaffold evidence entry.' }
    [pscustomobject]@{ controlId = '4.5'; status = 'implemented'; notes = 'Scaffold evidence entry.' }
    [pscustomobject]@{ controlId = '4.6'; status = 'implemented'; notes = 'Scaffold evidence entry.' }
    [pscustomobject]@{ controlId = '4.8'; status = 'implemented'; notes = 'Scaffold evidence entry.' }
)

Export-SolutionEvidencePackage `
    -Solution '08-license-governance-roi' `
    -SolutionCode 'LGR' `
    -Tier $ConfigurationTier `
    -OutputPath $OutputPath `
    -Summary @{ overallStatus = 'implemented'; recordCount = $controls.Count; findingCount = 0; exceptionCount = 0 } `
    -Controls $controls `
    -Artifacts @()
