#Requires -Version 7.0
<#
.SYNOPSIS
Monitors Copilot Interaction Audit Trail Manager compliance posture.

.DESCRIPTION
Checks Unified Audit Log configuration expectations, validates retention periods against
regulatory minimums, verifies eDiscovery readiness indicators, and returns structured
compliance findings for controls 3.1, 3.2, 3.3, 3.11, and 3.12.

.PARAMETER ConfigurationTier
Specifies the governance tier to evaluate. Valid values are baseline, recommended, and regulated.

.PARAMETER OutputPath
Specifies the folder where the compliance status file is written.

.PARAMETER TenantId
Specifies the Microsoft 365 tenant identifier to annotate in the compliance output.

.PARAMETER CheckRetention
Specifies whether retention minimum validation is performed.

.PARAMETER CheckAuditLevel
Specifies whether audit level validation is performed.

.EXAMPLE
PS> .\Monitor-Compliance.ps1 -ConfigurationTier recommended -OutputPath .\artifacts\monitor -TenantId 00000000-0000-0000-0000-000000000000 -CheckRetention $true -CheckAuditLevel $true

.NOTES
This script supports compliance with regulatory books-and-records monitoring by validating the
solution configuration against documented retention and audit requirements.
#>
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet('baseline', 'recommended', 'regulated')]
    [string]$ConfigurationTier = 'baseline',

    [Parameter()]
    [string]$OutputPath = (Join-Path $PSScriptRoot '..\artifacts\monitor'),

    [Parameter()]
    [string]$TenantId = 'not-specified',

    [Parameter()]
    [bool]$CheckRetention = $true,

    [Parameter()]
    [bool]$CheckAuditLevel = $true
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Resolve-AtmOutputPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if ([IO.Path]::IsPathRooted($Path)) {
        return $Path
    }

    return [IO.Path]::GetFullPath((Join-Path (Get-Location).Path $Path))
}

function Read-AtmJsonFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    return Get-Content -Path $Path -Raw | ConvertFrom-Json -Depth 20
}

function Write-AtmJsonFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [object]$InputObject
    )

    $directory = Split-Path -Path $Path -Parent
    if (-not (Test-Path -Path $directory)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }

    $InputObject | ConvertTo-Json -Depth 20 | Set-Content -Path $Path -Encoding utf8
    return $Path
}

function Get-AtmOverallStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]]$Statuses
    )

    if ($Statuses -contains 'partial') {
        return 'partial'
    }

    if ($Statuses -contains 'monitor-only') {
        return 'monitor-only'
    }

    if ($Statuses -contains 'playbook-only') {
        return 'playbook-only'
    }

    return 'implemented'
}

$solutionRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
Import-Module (Join-Path $repoRoot 'scripts\common\IntegrationConfig.psm1') -Force

$defaultConfig = Read-AtmJsonFile -Path (Join-Path $solutionRoot 'config\default-config.json')
$tierConfig = Read-AtmJsonFile -Path (Join-Path $solutionRoot ("config\{0}.json" -f $ConfigurationTier))
$outputFolder = Resolve-AtmOutputPath -Path $OutputPath
$timestamp = (Get-Date).ToString('o')

$ualStatusFlag = if ($defaultConfig.defaults.PSObject.Properties.Name -contains 'unifiedAuditLogEnabled') {
    $defaultConfig.defaults.unifiedAuditLogEnabled
} else {
    $defaultConfig.defaults.unifiedAuditLogEnabled
}

$requiredEventTypes = @($defaultConfig.defaults.auditEventTypes)
$configuredEventTypes = @($tierConfig.auditEventTypes)
$missingEventTypes = @($requiredEventTypes | Where-Object { $_ -notin $configuredEventTypes })
$allowedAuditLevels = @($defaultConfig.defaults.auditLevelRequired)
$auditLevelValid = ($tierConfig.auditLevel -in $allowedAuditLevels)

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
        gapDays = [Math]::Max(0, ($minimumDays - $configuredDays))
    }
}

$retentionGaps = @($retentionValidation | Where-Object { -not $_.meetsMinimum })

$findings = [System.Collections.Generic.List[object]]::new()
if ($missingEventTypes.Count -gt 0) {
    $findings.Add([pscustomobject]@{
        id = 'audit-event-gap'
        severity = 'high'
        category = 'audit'
        description = 'Required Copilot audit event types are missing from the configured monitoring scope.'
        recommendation = 'Update the audit validation scope to include CopilotInteraction, AIInteraction, and supporting workload events.'
    })
}

if ($CheckAuditLevel -and -not $auditLevelValid) {
    $findings.Add([pscustomobject]@{
        id = 'audit-level-gap'
        severity = 'medium'
        category = 'audit'
        description = 'The configured audit level does not match the allowed values in default-config.json.'
        recommendation = 'Update the tier configuration to Standard or Advanced as documented.'
    })
}

if ($CheckRetention) {
    foreach ($gap in $retentionGaps) {
        $findings.Add([pscustomobject]@{
            id = ('retention-gap-{0}' -f $gap.regulationKey.ToLowerInvariant())
            severity = 'high'
            category = 'retention'
            description = ('Configured retention for {0} is below the documented minimum.' -f $gap.regulation)
            recommendation = ('Increase configured retention from {0} to at least {1} days.' -f $gap.configuredDays, $gap.minimumDays)
        })
    }
}

if ([bool]$tierConfig.ediscovery.holdRequired -and $tierConfig.ediscovery.preservationStatus -ne 'required') {
    $findings.Add([pscustomobject]@{
        id = 'ediscovery-preservation-gap'
        severity = 'medium'
        category = 'ediscovery'
        description = 'A hold is required by the selected tier but preservation status is not marked required.'
        recommendation = 'Confirm legal hold configuration and update preservation status before export.'
    })
}

if (-not $tierConfig.powerAutomate.exceptionAlertsEnabled) {
    $findings.Add([pscustomobject]@{
        id = 'exception-alert-gap'
        severity = 'medium'
        category = 'notification'
        description = 'Power Automate exception alerts are not enabled in the selected tier configuration.'
        recommendation = 'Enable exception alerts so retention and evidence gaps are routed to operations.'
    })
}

$control31Status = if (-not $CheckAuditLevel) {
    'monitor-only'
} elseif ($missingEventTypes.Count -eq 0 -and $auditLevelValid) {
    'implemented'
} else {
    'partial'
}

$control32Status = if (-not $CheckRetention) {
    'monitor-only'
} elseif ($retentionGaps.Count -eq 0) {
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
        dashboardScore = (Get-CopilotGovStatusScore -Status $control31Status)
        notes = 'Audit completeness checks validate required Copilot event types and audit level expectations.'
    }
    [pscustomobject]@{
        controlId = '3.2'
        status = $control32Status
        dashboardScore = (Get-CopilotGovStatusScore -Status $control32Status)
        notes = 'Retention configuration is compared against SEC, FINRA, CFTC, and SOX references.'
    }
    [pscustomobject]@{
        controlId = '3.3'
        status = $control33Status
        dashboardScore = (Get-CopilotGovStatusScore -Status $control33Status)
        notes = 'eDiscovery readiness tracks case templates, preservation expectations, and custodian scope.'
    }
    [pscustomobject]@{
        controlId = '3.11'
        status = $control311Status
        dashboardScore = (Get-CopilotGovStatusScore -Status $control311Status)
        notes = 'Retention label coverage is documented for Copilot interaction artifacts.'
    }
    [pscustomobject]@{
        controlId = '3.12'
        status = $control312Status
        dashboardScore = (Get-CopilotGovStatusScore -Status $control312Status)
        notes = 'Exception handling depends on Power Automate alert routing and notification mode.'
    }
)

$overallStatus = Get-AtmOverallStatus -Statuses @($controls.status)
$result = [ordered]@{
    solution = $defaultConfig.solution
    solutionCode = $defaultConfig.solutionCode
    tier = $ConfigurationTier
    tenantId = $TenantId
    generatedAt = $timestamp
    overallStatus = $overallStatus
    auditValidation = [ordered]@{
        unifiedAuditLog = $ualStatusFlag
        requiredEventTypes = $requiredEventTypes
        configuredEventTypes = $configuredEventTypes
        missingEventTypes = $missingEventTypes
        auditLevel = $tierConfig.auditLevel
        allowedAuditLevels = $allowedAuditLevels
        checkAuditLevel = $CheckAuditLevel
    }
    retentionValidation = $retentionValidation
    ediscoveryReadiness = [ordered]@{
        mode = $tierConfig.ediscovery.mode
        holdRequired = [bool]$tierConfig.ediscovery.holdRequired
        caseTemplate = $tierConfig.ediscovery.caseTemplate
        custodianScope = $tierConfig.ediscovery.custodianScope
        preservationStatus = $tierConfig.ediscovery.preservationStatus
    }
    controls = $controls
    findings = @($findings)
    dataverseTargets = [ordered]@{
        baseline = (New-CopilotGovTableName -SolutionSlug 'atm' -Purpose 'baseline')
        assessmentHistory = (New-CopilotGovTableName -SolutionSlug 'atm' -Purpose 'assessmenthistory')
        evidence = (New-CopilotGovTableName -SolutionSlug 'atm' -Purpose 'evidence')
    }
}

$statusPath = Join-Path $outputFolder 'compliance-status.json'
Write-AtmJsonFile -Path $statusPath -InputObject $result | Out-Null

[pscustomobject]$result