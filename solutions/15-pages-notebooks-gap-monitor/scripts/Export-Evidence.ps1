<#
.SYNOPSIS
    Exports evidence for the Copilot Pages and Notebooks Compliance Gap Monitor.

.DESCRIPTION
    Generates the monitor-only evidence package for the Pages and Notebooks gap
    monitor. The script writes three documentation-led artifacts:
    - gap-findings
    - compensating-control-log
    - preservation-exception-register

    The resulting package supports compliance with SEC 17a-4, FINRA 4511, and
    SOX 404 by documenting current coverage gaps, manual controls, and exception
    handling. The script does not claim native platform remediation.

.PARAMETER ConfigurationTier
    Governance tier to use when exporting evidence.

.PARAMETER OutputPath
    Directory where standalone artifact files and the packaged evidence output
    are written.

.PARAMETER PeriodStart
    Start of the reporting period for the evidence export.

.PARAMETER PeriodEnd
    End of the reporting period for the evidence export.

.PARAMETER PassThru
    Returns the full export summary when specified.

.OUTPUTS
    PSCustomObject. Evidence export summary or full payload depending on PassThru.

.EXAMPLE
    pwsh -File .\scripts\Export-Evidence.ps1 -ConfigurationTier recommended -PassThru

.EXAMPLE
    pwsh -File .\scripts\Export-Evidence.ps1 -ConfigurationTier regulated -OutputPath .\artifacts\evidence -PeriodStart (Get-Date).AddDays(-90) -PeriodEnd (Get-Date)

.NOTES
    Solution: Copilot Pages and Notebooks Compliance Gap Monitor (PNGM)
    Controls: 2.11, 3.2, 3.3, 3.11
    Overall status: monitor-only
#>
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet('baseline', 'recommended', 'regulated')]
    [string]$ConfigurationTier = 'baseline',

    [Parameter()]
    [string]$OutputPath = (Join-Path $PSScriptRoot '..\artifacts'),

    [Parameter()]
    [datetime]$PeriodStart = ((Get-Date).Date.AddDays(-30)),

    [Parameter()]
    [datetime]$PeriodEnd = (Get-Date),

    [Parameter()]
    [switch]$PassThru
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
Import-Module (Join-Path $repoRoot 'scripts\common\EvidenceExport.psm1') -Force
Import-Module (Join-Path $repoRoot 'scripts\common\IntegrationConfig.psm1') -Force

function Get-PngmConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('baseline', 'recommended', 'regulated')]
        [string]$Tier
    )

    $configRoot = Join-Path (Split-Path -Parent $PSScriptRoot) 'config'
    $defaultConfigPath = Join-Path $configRoot 'default-config.json'
    $tierConfigPath = Join-Path $configRoot ('{0}.json' -f $Tier)

    return [pscustomobject]@{
        Default = (Get-Content -Path $defaultConfigPath -Raw | ConvertFrom-Json)
        Tier = (Get-Content -Path $tierConfigPath -Raw | ConvertFrom-Json)
    }
}

function Write-ArtifactFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        $Content
    )

    $directory = Split-Path -Parent $Path
    $null = New-Item -ItemType Directory -Path $directory -Force
    $Content | ConvertTo-Json -Depth 8 | Set-Content -Path $Path -Encoding utf8
    return $Path
}

if ($PeriodEnd -lt $PeriodStart) {
    throw 'PeriodEnd must be greater than or equal to PeriodStart.'
}

$configuration = Get-PngmConfiguration -Tier $ConfigurationTier
$defaultConfig = $configuration.Default
$tierConfig = $configuration.Tier
$tierDefinition = Get-CopilotGovTierDefinition -Tier $ConfigurationTier
$generatedAt = Get-Date

$gapFindings = @(
    [pscustomobject]@{
        gapId = 'PNGM-GAP-001'
        description = 'Copilot Pages content stored in Loop-backed workspaces is not yet validated for consistent tenant retention inheritance.'
        affectedCapability = 'Copilot Pages retention coverage'
        affectedRegulation = @('SEC 17a-4', 'FINRA 4511', 'SOX 404')
        severity = 'high'
        discoveredAt = $PeriodStart.AddDays(2).ToString('o')
        status = 'open'
        platformUpdateRequired = $true
    }
    [pscustomobject]@{
        gapId = 'PNGM-GAP-002'
        description = 'Loop workspace content referenced by Copilot Pages still requires tenant-specific eDiscovery verification.'
        affectedCapability = 'Loop workspace eDiscovery scope'
        affectedRegulation = @('SEC 17a-4', 'FINRA 4511')
        severity = 'high'
        discoveredAt = $PeriodStart.AddDays(4).ToString('o')
        status = 'open'
        platformUpdateRequired = $true
    }
    [pscustomobject]@{
        gapId = 'PNGM-GAP-003'
        description = 'SharePoint-backed notebooks can usually be preserved, but Copilot-generated notebook context still depends on manual validation for formal evidence use.'
        affectedCapability = 'Notebooks preservation verification'
        affectedRegulation = @('FINRA 4511', 'SOX 404')
        severity = 'medium'
        discoveredAt = $PeriodStart.AddDays(7).ToString('o')
        status = 'mitigated'
        platformUpdateRequired = $false
    }
    [pscustomobject]@{
        gapId = 'PNGM-GAP-004'
        description = 'Copilot Pages sharing restrictions still require manual review of workspace permissions and external access settings.'
        affectedCapability = 'Copilot Pages security and sharing'
        affectedRegulation = @('FINRA 4511', 'SOX 404')
        severity = 'medium'
        discoveredAt = $PeriodStart.AddDays(9).ToString('o')
        status = 'open'
        platformUpdateRequired = $false
    }
)

$compensatingControlLog = @(
    [pscustomobject]@{
        controlId = 'PNGM-CC-001'
        gapId = 'PNGM-GAP-001'
        controlDescription = 'Operations exports in-scope Copilot Pages to a governed SharePoint records library and records the export job identifier.'
        controlType = 'manual-export'
        implementedAt = $PeriodStart.AddDays(5).ToString('o')
        implementedBy = 'Records Operations'
        approvedBy = 'Compliance Officer'
        reviewDueDate = $PeriodEnd.AddDays(30).ToString('o')
        status = 'active'
    }
    [pscustomobject]@{
        controlId = 'PNGM-CC-002'
        gapId = 'PNGM-GAP-002'
        controlDescription = 'Investigation teams capture Loop workspace URLs, page owners, and exported evidence in the case file while native eDiscovery coverage is monitored.'
        controlType = 'ediscovery-workaround'
        implementedAt = $PeriodStart.AddDays(6).ToString('o')
        implementedBy = 'eDiscovery Operations'
        approvedBy = 'Deputy General Counsel'
        reviewDueDate = $PeriodEnd.AddDays(21).ToString('o')
        status = 'active'
    }
    [pscustomobject]@{
        controlId = 'PNGM-CC-003'
        gapId = 'PNGM-GAP-004'
        controlDescription = 'Collaboration governance performs a monthly sharing review for Pages workspaces and logs any access exceptions.'
        controlType = 'access-review'
        implementedAt = $PeriodStart.AddDays(8).ToString('o')
        implementedBy = 'Collaboration Governance'
        approvedBy = 'Information Security Manager'
        reviewDueDate = $PeriodEnd.AddDays(14).ToString('o')
        status = 'active'
    }
)

$preservationExceptionRegister = @(
    [pscustomobject]@{
        exceptionId = 'PNGM-EX-001'
        gapId = 'PNGM-GAP-001'
        regulation = 'SEC 17a-4'
        exceptionRationale = 'Native retention coverage for Loop-backed Pages remains under review, so the firm preserves final artifacts through manual export and supervisory approval.'
        approvedBy = $(if ($tierConfig.preservationExceptionTracking) { 'Chief Compliance Officer' } else { 'Pending legal sign-off' })
        approvalDate = $(if ($tierConfig.preservationExceptionTracking) { $PeriodEnd.AddDays(-3).ToString('o') } else { $null })
        expiryDate = $PeriodEnd.AddDays(90).ToString('o')
        reviewHistory = @(
            [pscustomobject]@{
                reviewedAt = $PeriodEnd.AddDays(-10).ToString('o')
                reviewer = 'Records Management'
                notes = 'Gap remains open. Continue manual export and supervisory review.'
            }
        )
    }
)

$gapFindingsPath = Join-Path $OutputPath '15-pages-notebooks-gap-monitor-gap-findings.json'
$compensatingControlPath = Join-Path $OutputPath '15-pages-notebooks-gap-monitor-compensating-control-log.json'
$exceptionRegisterPath = Join-Path $OutputPath '15-pages-notebooks-gap-monitor-preservation-exception-register.json'

$gapFindingsArtifact = [ordered]@{
    solution = $defaultConfig.solution
    artifact = 'gap-findings'
    periodStart = $PeriodStart.ToString('o')
    periodEnd = $PeriodEnd.ToString('o')
    generatedAt = $generatedAt.ToString('o')
    recordCount = $gapFindings.Count
    records = $gapFindings
}

$compensatingControlArtifact = [ordered]@{
    solution = $defaultConfig.solution
    artifact = 'compensating-control-log'
    periodStart = $PeriodStart.ToString('o')
    periodEnd = $PeriodEnd.ToString('o')
    generatedAt = $generatedAt.ToString('o')
    recordCount = $compensatingControlLog.Count
    records = $compensatingControlLog
}

$exceptionRegisterArtifact = [ordered]@{
    solution = $defaultConfig.solution
    artifact = 'preservation-exception-register'
    periodStart = $PeriodStart.ToString('o')
    periodEnd = $PeriodEnd.ToString('o')
    generatedAt = $generatedAt.ToString('o')
    recordCount = $preservationExceptionRegister.Count
    records = $preservationExceptionRegister
}

$null = New-Item -ItemType Directory -Path $OutputPath -Force
Write-ArtifactFile -Path $gapFindingsPath -Content $gapFindingsArtifact | Out-Null
Write-ArtifactFile -Path $compensatingControlPath -Content $compensatingControlArtifact | Out-Null
Write-ArtifactFile -Path $exceptionRegisterPath -Content $exceptionRegisterArtifact | Out-Null

$controls = @(
    [pscustomobject]@{
        controlId = '2.11'
        status = 'monitor-only'
        notes = 'Pages security controls remain limited; compensating access restrictions and review procedures are registered.'
    }
    [pscustomobject]@{
        controlId = '3.2'
        status = 'monitor-only'
        notes = 'Retention policy gaps are documented; compensating manual export procedures are registered.'
    }
    [pscustomobject]@{
        controlId = '3.3'
        status = 'partial'
        notes = 'eDiscovery covers SharePoint-backed notebooks; Loop workspace coverage is still being monitored.'
    }
    [pscustomobject]@{
        controlId = '3.11'
        status = 'playbook-only'
        notes = 'Books-and-records requirements are documented as gaps until platform updates close the open preservation exceptions.'
    }
)

$artifacts = @(
    [pscustomobject]@{
        name = 'gap-findings'
        type = 'gap-findings'
        path = $gapFindingsPath
    }
    [pscustomobject]@{
        name = 'compensating-control-log'
        type = 'compensating-control-log'
        path = $compensatingControlPath
    }
    [pscustomobject]@{
        name = 'preservation-exception-register'
        type = 'preservation-exception-register'
        path = $exceptionRegisterPath
    }
)

$summary = @{
    overallStatus = 'monitor-only'
    recordCount = ($gapFindings.Count + $compensatingControlLog.Count + $preservationExceptionRegister.Count)
    findingCount = $gapFindings.Count
    exceptionCount = $preservationExceptionRegister.Count
}

$packageResult = Export-SolutionEvidencePackage `
    -Solution $defaultConfig.solution `
    -SolutionCode $defaultConfig.solutionCode `
    -Tier $ConfigurationTier `
    -OutputPath $OutputPath `
    -Summary $summary `
    -Controls $controls `
    -Artifacts $artifacts

$exportResult = [ordered]@{
    solution = $defaultConfig.solution
    solutionCode = $defaultConfig.solutionCode
    tier = $ConfigurationTier
    tierDefinition = $tierDefinition
    overallStatus = $summary.overallStatus
    dashboardStatusScore = (Get-CopilotGovStatusScore -Status $summary.overallStatus)
    packagePath = $packageResult.Path
    packageHash = $packageResult.Hash
    artifacts = $artifacts
    summary = $summary
}

if ($PassThru) {
    $exportResult
}
else {
    [pscustomobject]@{
        solution = $defaultConfig.solution
        tier = $ConfigurationTier
        overallStatus = $summary.overallStatus
        recordCount = $summary.recordCount
        packagePath = $packageResult.Path
        artifactCount = $artifacts.Count
    }
}
