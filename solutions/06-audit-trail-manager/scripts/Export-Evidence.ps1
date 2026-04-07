#Requires -Version 7.0
<#
.SYNOPSIS
Exports Copilot Interaction Audit Trail Manager evidence package.

.DESCRIPTION
Assembles audit-log-completeness, retention-policy-state, and ediscovery-readiness-package
artifacts, writes SHA-256 companion files, and creates the shared evidence package for the
selected configuration tier.

.PARAMETER ConfigurationTier
Specifies the governance tier to export. Valid values are baseline, recommended, and regulated.

.PARAMETER OutputPath
Specifies the folder where evidence artifacts are written.

.PARAMETER PeriodStart
Specifies the start date of the evidence window.

.PARAMETER PeriodEnd
Specifies the end date of the evidence window.

.PARAMETER TenantId
Specifies the Microsoft 365 tenant identifier to annotate in the evidence package.

.EXAMPLE
PS> .\Export-Evidence.ps1 -ConfigurationTier regulated -OutputPath .\artifacts\evidence -PeriodStart 2026-01-01 -PeriodEnd 2026-01-31 -TenantId 00000000-0000-0000-0000-000000000000

.NOTES
This script supports compliance with books-and-records examinations by exporting a structured
JSON package and SHA-256 companion files for the selected tier.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter()]
    [ValidateSet('baseline', 'recommended', 'regulated')]
    [string]$ConfigurationTier = 'baseline',

    [Parameter()]
    [string]$OutputPath = (Join-Path $PSScriptRoot '..\artifacts\evidence'),

    [Parameter()]
    [datetime]$PeriodStart = (Get-Date).Date.AddDays(-30),

    [Parameter()]
    [datetime]$PeriodEnd = (Get-Date).Date,

    [Parameter()]
    [string]$TenantId = 'not-specified'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path $PSScriptRoot 'AtmShared.psm1') -Force

function Write-AtmHashFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    $hash = Get-CopilotGovSha256 -Path $Path
    Set-Content -Path ($Path + '.sha256') -Value ('{0}  {1}' -f $hash, [IO.Path]::GetFileName($Path)) -Encoding utf8
    return $hash
}

if ($PeriodEnd -lt $PeriodStart) {
    throw 'PeriodEnd must be greater than or equal to PeriodStart.'
}

$solutionRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
Import-Module (Join-Path $repoRoot 'scripts\common\EvidenceExport.psm1') -Force

$defaultConfig = Read-AtmJsonFile -Path (Join-Path $solutionRoot 'config\default-config.json')
$tierConfig = Read-AtmJsonFile -Path (Join-Path $solutionRoot ("config\{0}.json" -f $ConfigurationTier))
$outputFolder = Resolve-AtmOutputPath -Path $OutputPath
$timestamp = (Get-Date).ToString('o')
$periodStartString = $PeriodStart.ToString('yyyy-MM-dd')
$periodEndString = $PeriodEnd.ToString('yyyy-MM-dd')

$ualStatusFlag = if ($defaultConfig.defaults.PSObject.Properties.Name -contains 'unifiedAuditLogEnabled') {
    $defaultConfig.defaults.unifiedAuditLogEnabled
}
else {
    'check'
}

$regulationNames = [ordered]@{
    SEC_17a4 = 'SEC 17a-4'
    FINRA_4511 = 'FINRA 4511'
    CFTC_1_31 = 'CFTC 1.31'
    SOX_404 = 'SOX 404'
}

$retentionValidation = foreach ($property in $defaultConfig.defaults.retentionPeriods.byRegulation.PSObject.Properties) {
    $regKey = $property.Name
    $minimumDays = [int]$property.Value
    $configuredDays = [int]$tierConfig.retentionPeriods.byRegulation.$regKey

    [pscustomobject]@{
        regulationKey = $regKey
        regulation = $regulationNames[$regKey]
        minimumDays = $minimumDays
        configuredDays = $configuredDays
        meetsMinimum = ($configuredDays -ge $minimumDays)
    }
}

$sampleCounts = foreach ($eventType in @($defaultConfig.defaults.auditEventTypes)) {
    [ordered]@{
        eventType = $eventType
        sampleCount = 0
        status = 'pending-tenant-query'
    }
}

$auditArtifact = [ordered]@{
    solution = $defaultConfig.solution
    solutionCode = $defaultConfig.solutionCode
    tier = $ConfigurationTier
    tenantId = $TenantId
    generatedAt = $timestamp
    periodStart = $periodStartString
    periodEnd = $periodEndString
    ualStatus = [ordered]@{
        enabledCheck = $ualStatusFlag
        auditLevel = $tierConfig.auditLevel
        validationCommand = 'Check-AuditLogCompleteness'
        latencyNote = 'UAL results may lag by up to 24 hours.'
    }
    requiredEventTypes = @($defaultConfig.defaults.auditEventTypes)
    capturedEventTypes = @($tierConfig.auditEventTypes)
    sampleCounts = $sampleCounts
    notes = @(
        'Copilot event detail depends on Microsoft 365 audit level.',
        'Sample counts should be refreshed from tenant audit data before examination use.'
    )
}

$retentionArtifact = [ordered]@{
    solution = $defaultConfig.solution
    solutionCode = $defaultConfig.solutionCode
    tier = $ConfigurationTier
    tenantId = $TenantId
    generatedAt = $timestamp
    activePolicies = @(
        foreach ($item in $retentionValidation) {
            [ordered]@{
                policyName = "ATM-$ConfigurationTier-$($item.regulationKey)"
                regulation = $item.regulation
                configuredDays = $item.configuredDays
                minimumDays = $item.minimumDays
                meetsMinimum = $item.meetsMinimum
                workloadScope = @('Exchange', 'SharePoint', 'Teams', 'Microsoft365Copilot')
            }
        }
    )
    labels = @(
        [ordered]@{
            labelName = "ATM-$ConfigurationTier-Copilot-Record"
            appliesTo = 'Copilot interaction artifacts and supporting files'
            required = [bool]$tierConfig.retentionLabelRequired
            publishingMode = $tierConfig.retentionPolicyMode
        }
    )
    retentionPeriodsByRegulation = $retentionValidation
    wormDocumentationRequired = [bool](($tierConfig.PSObject.Properties.Name -contains 'wormDocumentationRequired') -and $tierConfig.wormDocumentationRequired)
    immutableStorageAttestationRequired = [bool](($tierConfig.PSObject.Properties.Name -contains 'immutableStorageAttestationRequired') -and $tierConfig.immutableStorageAttestationRequired)
    notes = @(
        'Retention schedules should be confirmed in Microsoft Purview before relying on the evidence package.',
        'SEC 17a-4 immutable storage requirements are documented separately from this JSON output.'
    )
}

switch ($tierConfig.ediscovery.mode) {
    'basic' {
        $caseCount = 1
        $holdCount = 0
        $custodianCount = 2
    }
    'enhanced' {
        $caseCount = 1
        $holdCount = 2
        $custodianCount = 5
    }
    'full' {
        $caseCount = 2
        $holdCount = 4
        $custodianCount = 8
    }
    default {
        $caseCount = 0
        $holdCount = 0
        $custodianCount = 0
    }
}

$ediscoveryArtifact = [ordered]@{
    solution = $defaultConfig.solution
    solutionCode = $defaultConfig.solutionCode
    tier = $ConfigurationTier
    tenantId = $TenantId
    generatedAt = $timestamp
    caseCount = $caseCount
    holdCount = $holdCount
    custodianCount = $custodianCount
    preservationStatus = $tierConfig.ediscovery.preservationStatus
    caseTemplate = $tierConfig.ediscovery.caseTemplate
    holdConfiguration = [ordered]@{
        required = [bool]$tierConfig.ediscovery.holdRequired
        mode = $tierConfig.ediscovery.mode
        custodianScope = $tierConfig.ediscovery.custodianScope
    }
    notes = @(
        'Counts reflect the tier readiness baseline and should be replaced with tenant values before regulator production.',
        'Legal hold ownership and export operators should be documented outside the package.'
    )
}

if ($PSCmdlet.ShouldProcess($outputFolder, 'Write ATM evidence artifacts')) {
    $null = New-Item -ItemType Directory -Path $outputFolder -Force
    $auditPath = Write-AtmJsonFile -Path (Join-Path $outputFolder 'audit-log-completeness.json') -InputObject $auditArtifact
    $retentionPath = Write-AtmJsonFile -Path (Join-Path $outputFolder 'retention-policy-state.json') -InputObject $retentionArtifact
    $ediscoveryPath = Write-AtmJsonFile -Path (Join-Path $outputFolder 'ediscovery-readiness-package.json') -InputObject $ediscoveryArtifact

    $auditHash = Write-AtmHashFile -Path $auditPath
    $retentionHash = Write-AtmHashFile -Path $retentionPath
    $ediscoveryHash = Write-AtmHashFile -Path $ediscoveryPath
} else {
    return
}

$retentionGapCount = @($retentionValidation | Where-Object { -not $_.meetsMinimum }).Count
$control32Status = if ($retentionGapCount -eq 0) { 'implemented' } else { 'partial' }
$summaryStatus = if ($retentionGapCount -eq 0) { 'implemented' } else { 'partial' }

$requiredEventTypes = @($defaultConfig.defaults.auditEventTypes)
$configuredEventTypes = @($tierConfig.auditEventTypes)
$missingEventTypes = @($requiredEventTypes | Where-Object { $_ -notin $configuredEventTypes })
$allowedAuditLevels = @($defaultConfig.defaults.auditLevelRequired)
$auditLevelValid = ($tierConfig.auditLevel -in $allowedAuditLevels)

$control31Status = if ($missingEventTypes.Count -eq 0 -and $auditLevelValid) {
    'implemented'
} else {
    'partial'
}

$control33Status = if ($tierConfig.ediscovery.mode -in @('basic', 'enhanced', 'full')) {
    'implemented'
} else {
    'partial'
}

$control311Status = if ([bool]$tierConfig.retentionLabelRequired -and -not [string]::IsNullOrWhiteSpace([string]$tierConfig.retentionPolicyMode)) {
    'implemented'
} else {
    'partial'
}

$control312Status = if ($tierConfig.powerAutomate.exceptionAlertsEnabled) {
    'implemented'
} else {
    'monitor-only'
}

$controls = @(
    [pscustomobject]@{
        controlId = '3.1'
        status = $control31Status
        notes = 'audit-log-completeness captures required Copilot event types and audit level notes for the selected tier.'
    }
    [pscustomobject]@{
        controlId = '3.2'
        status = $control32Status
        notes = 'retention-policy-state compares configured retention days against SEC, FINRA, CFTC, and SOX references.'
    }
    [pscustomobject]@{
        controlId = '3.3'
        status = $control33Status
        notes = 'ediscovery-readiness-package records case, hold, custodian, and preservation expectations.'
    }
    [pscustomobject]@{
        controlId = '3.11'
        status = $control311Status
        notes = 'Retention labels and publishing mode are documented for Copilot interaction artifacts.'
    }
    [pscustomobject]@{
        controlId = '3.12'
        status = $control312Status
        notes = 'Notification mode and exception-handling responsibilities are described by tier.'
    }
)

$artifacts = @(
    [pscustomobject]@{
        name = 'audit-log-completeness'
        type = 'json'
        path = $auditPath
        hash = $auditHash
    }
    [pscustomobject]@{
        name = 'retention-policy-state'
        type = 'json'
        path = $retentionPath
        hash = $retentionHash
    }
    [pscustomobject]@{
        name = 'ediscovery-readiness-package'
        type = 'json'
        path = $ediscoveryPath
        hash = $ediscoveryHash
    }
)

$summary = @{
    overallStatus = $summaryStatus
    recordCount = $artifacts.Count
    findingCount = $retentionGapCount
    exceptionCount = 0
}

$package = Export-SolutionEvidencePackage `
    -Solution '06-audit-trail-manager' `
    -SolutionCode 'ATM' `
    -Tier $ConfigurationTier `
    -OutputPath $outputFolder `
    -Summary $summary `
    -Controls $controls `
    -Artifacts $artifacts `
    -AdditionalMetadata @{
        periodStart = $periodStartString
        periodEnd = $periodEndString
        tenantId = $TenantId
    }

[pscustomobject]@{
    Solution = $defaultConfig.solution
    Tier = $ConfigurationTier
    PackagePath = $package.Path
    PackageHash = $package.Hash
    ArtifactPaths = @($artifacts.path)
}
