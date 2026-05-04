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
    Overall status: monitor-only
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
    $hashInfo = Write-CopilotGovSha256File -Path $Path

    return [pscustomobject]@{
        Path = $Path
        Hash = $hashInfo.Hash
    }
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
        description = 'Purview eDiscovery supports search, collection, review, and export for Pages, Notebooks, and Loop, but full-text search within .page and .loop files in review sets is not available.'
        affectedCapability = 'Purview eDiscovery review-set full-text search'
        affectedRegulation = @('SEC 17a-4', 'FINRA 4511')
        severity = 'high'
        discoveredAt = $PeriodStart.AddDays(4).ToString('o')
        status = 'open'
        platformUpdateRequired = $true
    }
    [pscustomobject]@{
        gapId = 'PNGM-GAP-003'
        description = 'Copilot Notebooks create .pod files in SharePoint Embedded containers; notebook storage, retention policy scope, and export evidence require tenant validation.'
        affectedCapability = 'Notebooks preservation verification'
        affectedRegulation = @('FINRA 4511', 'SOX 404')
        severity = 'medium'
        discoveredAt = $PeriodStart.AddDays(7).ToString('o')
        status = 'validation-required'
        platformUpdateRequired = $false
    }
    [pscustomobject]@{
        gapId = 'PNGM-GAP-004'
        description = 'Copilot Pages sharing restrictions require manual review, and Information Barriers are not supported for content stored in SharePoint Embedded containers.'
        affectedCapability = 'Copilot Pages security, sharing, and Information Barriers'
        affectedRegulation = @('FINRA 4511', 'SOX 404')
        severity = 'high'
        discoveredAt = $PeriodStart.AddDays(9).ToString('o')
        status = 'open'
        platformUpdateRequired = $true
    }
    [pscustomobject]@{
        gapId = 'PNGM-GAP-005'
        description = 'Legal hold requires manual SharePoint Embedded container addition per user, and retention labels have limited manual support for Pages, Notebooks, and Loop content.'
        affectedCapability = 'Legal hold and retention label limitations'
        affectedRegulation = @('SEC 17a-4', 'FINRA 4511')
        severity = 'high'
        discoveredAt = $PeriodStart.AddDays(3).ToString('o')
        status = 'open'
        platformUpdateRequired = $true
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
        controlDescription = 'Investigation teams record SharePoint Embedded container URLs, page owners, collection/export steps, and the review-set full-text search limitation in the case file.'
        controlType = 'ediscovery-review-set-limitation'
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
        controlDescription = 'Compliance operations validates notebook storage location, retention policy scope, retention label behavior, and export steps during quarterly control reviews.'
        controlType = 'manual-export'
        implementedAt = $PeriodStart.AddDays(10).ToString('o')
        implementedBy = 'Compliance Operations'
        approvedBy = 'Compliance Officer'
        reviewDueDate = $PeriodEnd.AddDays(30).ToString('o')
        status = 'active'
    }
    [pscustomobject]@{
        controlId = 'PNGM-CC-005'
        gapId = 'PNGM-GAP-005'
        controlDescription = 'Records Management documents legal-hold container inclusion, retention-label limitations, and any preservation exception required for books-and-records review.'
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

$controls = @(
    [pscustomobject]@{
        controlId = '2.11'
        status = 'monitor-only'
        notes = 'Pages security controls and the SharePoint Embedded Information Barriers limitation are registered for manual governance review.'
    }
    [pscustomobject]@{
        controlId = '3.2'
        status = 'monitor-only'
        notes = 'Retention policies are supported via All SharePoint Sites; validation evidence and compensating manual procedures are registered.'
    }
    [pscustomobject]@{
        controlId = '3.3'
        status = 'partial'
        notes = 'Microsoft Purview eDiscovery supports search, collection, review, and export; review-set full-text search and container-scoping limitations are still monitored.'
    }
    [pscustomobject]@{
        controlId = '3.11'
        status = 'monitor-only'
        notes = 'Books-and-records requirements are monitored through legal-hold, retention label, and preservation exception reviews.'
    }
)

$hasActiveControls = ($compensatingControlLog | Where-Object { $_.status -eq 'active' }).Count -gt 0
$summary = @{
    overallStatus = $(if ($hasActiveControls) { 'partial' } else { 'monitor-only' })
    recordCount = ($gapFindings.Count + $compensatingControlLog.Count + $preservationExceptionRegister.Count)
    findingCount = $gapFindings.Count
    exceptionCount = $preservationExceptionRegister.Count
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
        -Artifacts $artifacts
}

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
