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
    SOX 404 by documenting current validation items, documented limitations,
    manual controls, and exception handling. The script does not claim native platform remediation.

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
    Overall status: derived from mapped control states and dependency checks
#>
[CmdletBinding(SupportsShouldProcess)]
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

Import-Module (Join-Path $PSScriptRoot 'PngmShared.psm1') -Force

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
    $resolvedPath = (Resolve-Path -Path $Path).Path
    $hashInfo = Write-CopilotGovSha256File -Path $Path

    return [pscustomobject]@{
        Path = [System.IO.Path]::GetFileName($resolvedPath)
        AbsolutePath = $resolvedPath
        Hash = $hashInfo.Hash
    }
}

if ($PeriodEnd -lt $PeriodStart) {
    throw 'PeriodEnd must be greater than or equal to PeriodStart.'
}

$OutputPath = [System.IO.Path]::GetFullPath($OutputPath)
$configuration = Get-PngmConfiguration -Tier $ConfigurationTier
$defaultConfig = $configuration.Default
$tierConfig = $configuration.Tier
$tierDefinition = Get-CopilotGovTierDefinition -Tier $ConfigurationTier
$dependencyStatus = Get-PngmDependencyStatus -RepoRoot $repoRoot -Dependencies @($defaultConfig.dependencies)
$generatedAt = Get-Date

$gapFindings = @(
    [pscustomobject]@{
        gapId = 'PNGM-GAP-001'
        description = 'Purview retention policies configured for All SharePoint Sites are supported for Copilot Pages and Copilot Notebooks; tenant policy scope and evidence should be validated for regulated records.'
        affectedCapability = 'Copilot Pages and Notebooks retention policy validation'
        affectedRegulation = @('SEC 17a-4', 'FINRA 4511', 'SOX 404')
        severity = 'medium'
        discoveredAt = $PeriodStart.AddDays(2).ToString('o')
        status = 'validation-required'
        platformUpdateRequired = $false
    }
    [pscustomobject]@{
        gapId = 'PNGM-GAP-002'
        description = 'M365 Roadmap 561492 (GA June 2026, rolling out) introduces full review-set indexing for Loop and Copilot Pages with HTML export from search. Tenant rollout verification remains required before retiring legacy workaround documentation.'
        affectedCapability = 'Purview eDiscovery review-set indexing rollout validation'
        affectedRegulation = @('SEC 17a-4', 'FINRA 4511')
        severity = 'medium'
        discoveredAt = $PeriodStart.AddDays(4).ToString('o')
        status = 'validation-required'
        platformUpdateRequired = $false
    }
    [pscustomobject]@{
        gapId = 'PNGM-GAP-003'
        description = 'Copilot Notebooks .pod files share the user-owned SharePoint Embedded container with Copilot Pages and Loop My workspace. Deleted notebooks cannot be recovered from an end-user recycle bin, so lifecycle controls remain open.'
        affectedCapability = 'Notebook lifecycle, audit visibility, and recovery limitation'
        affectedRegulation = @('SEC 17a-4', 'FINRA 4511', 'SOX 404')
        severity = 'high'
        discoveredAt = $PeriodStart.AddDays(7).ToString('o')
        status = 'open'
        platformUpdateRequired = $true
    }
    [pscustomobject]@{
        gapId = 'PNGM-GAP-004'
        description = 'Conditional Access applies at app-level scope for Microsoft 365 Copilot, and Information Barriers are not supported for SharePoint Embedded containers used by Copilot Pages and Copilot Notebooks.'
        affectedCapability = 'Access boundaries (Conditional Access app-level and Information Barriers limitation)'
        affectedRegulation = @('FINRA 4511', 'SOX 404')
        severity = 'high'
        discoveredAt = $PeriodStart.AddDays(9).ToString('o')
        status = 'open'
        platformUpdateRequired = $true
    }
    [pscustomobject]@{
        gapId = 'PNGM-GAP-005'
        description = 'Purview legal-hold container picker support for user-owned SharePoint Embedded containers is rolling out (expected early August 2026). Until verified per tenant, manual container inclusion and retention-label manual handling controls remain required.'
        affectedCapability = 'Legal hold container picker rollout and retention-label manual limits'
        affectedRegulation = @('SEC 17a-4', 'FINRA 4511')
        severity = 'medium'
        discoveredAt = $PeriodStart.AddDays(3).ToString('o')
        status = 'validation-required'
        platformUpdateRequired = $false
    }
)

$compensatingControlLog = @(
    [pscustomobject]@{
        controlId = 'PNGM-CC-001'
        gapId = 'PNGM-GAP-001'
        controlDescription = 'Operations verifies All SharePoint Sites retention policy scope for in-scope Copilot Pages and records SharePoint Embedded container evidence; manual export is used only when policy scope cannot be demonstrated.'
        controlType = 'tenant-validation'
        implementedAt = $PeriodStart.AddDays(5).ToString('o')
        implementedBy = 'Records Operations'
        approvedBy = 'Compliance Officer'
        reviewDueDate = $PeriodEnd.AddDays(30).ToString('o')
        status = 'active'
    }
    [pscustomobject]@{
        controlId = 'PNGM-CC-002'
        gapId = 'PNGM-GAP-002'
        controlDescription = 'Investigation teams validate rollout status for review-set indexing and HTML export, then capture evidence for any remaining manual search-limit procedures.'
        controlType = 'ediscovery-rollout-validation'
        implementedAt = $PeriodStart.AddDays(6).ToString('o')
        implementedBy = 'Microsoft Purview eDiscovery Operations'
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
    [pscustomobject]@{
        controlId = 'PNGM-CC-004'
        gapId = 'PNGM-GAP-003'
        controlDescription = 'Compliance operations validates notebook storage location, .pod audit visibility, retention policy scope, and preservation export steps during quarterly control reviews.'
        controlType = 'lifecycle-audit-validation'
        implementedAt = $PeriodStart.AddDays(10).ToString('o')
        implementedBy = 'Compliance Operations'
        approvedBy = 'Compliance Officer'
        reviewDueDate = $PeriodEnd.AddDays(30).ToString('o')
        status = 'active'
    }
    [pscustomobject]@{
        controlId = 'PNGM-CC-005'
        gapId = 'PNGM-GAP-005'
        controlDescription = 'Records Management documents legal-hold container inclusion until picker rollout is validated, tracks retention-label manual limits, and logs preservation exceptions when needed.'
        controlType = 'preservation-exception'
        implementedAt = $PeriodStart.AddDays(4).ToString('o')
        implementedBy = 'Records Management'
        approvedBy = 'Deputy General Counsel'
        reviewDueDate = $PeriodEnd.AddDays(90).ToString('o')
        status = 'active'
    }
)

$preservationExceptionRegister = @(
    [pscustomobject]@{
        exceptionId = 'PNGM-EX-001'
        gapId = 'PNGM-GAP-001'
        regulation = 'SEC 17a-4'
        exceptionRationale = 'If All SharePoint Sites retention policy scope or container-specific configuration cannot be evidenced for required Pages or Notebooks records, the firm preserves final artifacts through manual export and supervisory approval.'
        approvedBy = $(if ($tierConfig.preservationExceptionTracking) { 'Chief Compliance Officer' } else { 'Pending legal sign-off' })
        approvalDate = $(if ($tierConfig.preservationExceptionTracking) { $PeriodEnd.AddDays(-3).ToString('o') } else { $null })
        expiryDate = $PeriodEnd.AddDays(90).ToString('o')
        reviewHistory = @(
            [pscustomobject]@{
                reviewedAt = $PeriodEnd.AddDays(-10).ToString('o')
                reviewer = 'Records Management'
                notes = 'Validation item remains open. Continue policy-scope evidence review and manual export where required.'
            }
        )
    }
    [pscustomobject]@{
        exceptionId = 'PNGM-EX-002'
        gapId = 'PNGM-GAP-005'
        regulation = 'SEC 17a-4'
        exceptionRationale = 'Books-and-records preservation for Copilot Pages, Copilot Notebooks, and Loop content requires documented legal-hold container inclusion, retention-label governance, and formal exceptions where manual limits affect regulated records.'
        approvedBy = $(if ($tierConfig.preservationExceptionTracking) { 'Chief Compliance Officer' } else { 'Pending legal sign-off' })
        approvalDate = $(if ($tierConfig.preservationExceptionTracking) { $PeriodEnd.AddDays(-3).ToString('o') } else { $null })
        expiryDate = $PeriodEnd.AddDays(90).ToString('o')
        reviewHistory = @(
            [pscustomobject]@{
                reviewedAt = $PeriodEnd.AddDays(-10).ToString('o')
                reviewer = 'Records Management'
                notes = 'Books-and-records preservation exception remains active. Continue legal-hold container review, retention-label governance, and quarterly reassessment.'
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
    frameworkIds = @($defaultConfig.framework_ids)
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

$trackedGaps = @($gapFindings | Where-Object { $_.status -in @('open', 'validation-required') })
$controlStateInput = @(
    $compensatingControlLog |
    ForEach-Object {
        [pscustomobject]@{
            gapId = $_.gapId
            status = if ($_.status -eq 'active') { 'in-place' } else { 'planned' }
        }
    }
)
$controls = Get-PngmControlState -TierConfiguration $tierConfig -TrackedGaps $trackedGaps -CompensatingControls $controlStateInput
$summary = @{
    overallStatus = $(if (@($controls | Where-Object { $_.status -eq 'partial' }).Count -gt 0) { 'partial' } else { 'monitor-only' })
    recordCount = ($gapFindings.Count + $compensatingControlLog.Count + $preservationExceptionRegister.Count)
    findingCount = $gapFindings.Count
    exceptionCount = $preservationExceptionRegister.Count
}
if ($dependencyStatus.hasMissingDependencies) {
    $summary.overallStatus = 'monitor-only'
}

$artifacts = @(
    [pscustomobject]@{
        name = 'gap-findings'
        type = 'gap-findings'
        path = $gapFindingsPath
        hash = $null
    }
    [pscustomobject]@{
        name = 'compensating-control-log'
        type = 'compensating-control-log'
        path = $compensatingControlPath
        hash = $null
    }
    [pscustomobject]@{
        name = 'preservation-exception-register'
        type = 'preservation-exception-register'
        path = $exceptionRegisterPath
        hash = $null
    }
)

$packageResult = @{ Path = $null; Hash = $null }

if ($PSCmdlet.ShouldProcess($defaultConfig.displayName, "Export evidence package for tier $ConfigurationTier")) {
    $null = New-Item -ItemType Directory -Path $OutputPath -Force
    $gapFindingsFile = Write-ArtifactFile -Path $gapFindingsPath -Content $gapFindingsArtifact
    $compensatingControlFile = Write-ArtifactFile -Path $compensatingControlPath -Content $compensatingControlArtifact
    $exceptionRegisterFile = Write-ArtifactFile -Path $exceptionRegisterPath -Content $exceptionRegisterArtifact

    $artifacts = @(
        [pscustomobject]@{
            name = 'gap-findings'
            type = 'gap-findings'
            path = $gapFindingsFile.Path
            hash = $gapFindingsFile.Hash
        }
        [pscustomobject]@{
            name = 'compensating-control-log'
            type = 'compensating-control-log'
            path = $compensatingControlFile.Path
            hash = $compensatingControlFile.Hash
        }
        [pscustomobject]@{
            name = 'preservation-exception-register'
            type = 'preservation-exception-register'
            path = $exceptionRegisterFile.Path
            hash = $exceptionRegisterFile.Hash
        }
    )

    $packageResult = Export-SolutionEvidencePackage `
        -Solution $defaultConfig.solution `
        -SolutionCode $defaultConfig.solutionCode `
        -Tier $ConfigurationTier `
        -OutputPath $OutputPath `
        -Summary $summary `
        -Controls $controls `
        -Artifacts $artifacts `
        -AdditionalMetadata ([ordered]@{
            frameworkIds = @($defaultConfig.framework_ids)
            dependencyStatus = $dependencyStatus
        })
}

$exportResult = [ordered]@{
    solution = $defaultConfig.solution
    solutionCode = $defaultConfig.solutionCode
    frameworkIds = @($defaultConfig.framework_ids)
    tier = $ConfigurationTier
    tierDefinition = $tierDefinition
    overallStatus = $summary.overallStatus
    dashboardStatusScore = (Get-CopilotGovStatusScore -Status $summary.overallStatus)
    packagePath = $packageResult.Path
    packageHash = $packageResult.Hash
    artifacts = $artifacts
    summary = $summary
    dependencyStatus = $dependencyStatus
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
