<#
.SYNOPSIS
Exports evidence for the Oversharing Risk Assessment and Remediation solution.

.DESCRIPTION
Runs the monitoring script, builds the oversharing-findings, remediation-queue,
and site-owner-attestations artifacts, packages them into the shared evidence
schema format, and writes SHA-256 checksum files for each JSON output.

.PARAMETER ConfigurationTier
Selects the governance tier to apply. Supported values are baseline,
recommended, and regulated.

.PARAMETER OutputPath
Directory where evidence artifacts and the package manifest will be written.

.PARAMETER TenantId
Tenant GUID used to label the export.

.PARAMETER PeriodStart
Start date of the reporting period.

.PARAMETER PeriodEnd
End date of the reporting period.

.PARAMETER IncludeAttestations
When supplied, creates owner-attestation records for queued remediation items.

.EXAMPLE
.\Export-Evidence.ps1 -ConfigurationTier recommended -TenantId 00000000-0000-0000-0000-000000000000 -OutputPath .\artifacts\evidence

.EXAMPLE
.\Export-Evidence.ps1 -ConfigurationTier regulated -TenantId 00000000-0000-0000-0000-000000000000 -OutputPath .\artifacts\evidence -IncludeAttestations
#>
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet('baseline', 'recommended', 'regulated')]
    [string]$ConfigurationTier = 'baseline',

    [Parameter()]
    [string]$OutputPath = (Join-Path $PSScriptRoot '..\artifacts\evidence'),

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$TenantId,

    [Parameter()]
    [datetime]$PeriodStart = ((Get-Date).Date.AddDays(-7)),

    [Parameter()]
    [datetime]$PeriodEnd = (Get-Date).Date,

    [Parameter()]
    [switch]$IncludeAttestations
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
Import-Module (Join-Path $repoRoot 'scripts\common\EvidenceExport.psm1') -Force
Import-Module (Join-Path $repoRoot 'scripts\common\IntegrationConfig.psm1') -Force

function ConvertTo-Hashtable {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$InputObject
    )

    if ($null -eq $InputObject) {
        return $null
    }

    if ($InputObject -is [System.Collections.IDictionary]) {
        $table = @{}
        foreach ($key in $InputObject.Keys) {
            $table[$key] = ConvertTo-Hashtable -InputObject $InputObject[$key]
        }

        return $table
    }

    if ($InputObject -is [pscustomobject]) {
        $table = @{}
        foreach ($property in $InputObject.PSObject.Properties) {
            $table[$property.Name] = ConvertTo-Hashtable -InputObject $property.Value
        }

        return $table
    }

    if (($InputObject -is [System.Collections.IEnumerable]) -and -not ($InputObject -is [string])) {
        $list = @()
        foreach ($item in $InputObject) {
            $list += ,(ConvertTo-Hashtable -InputObject $item)
        }

        return $list
    }

    return $InputObject
}

function Merge-Hashtable {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Base,

        [Parameter(Mandatory)]
        [hashtable]$Override
    )

    $merged = @{}

    foreach ($key in $Base.Keys) {
        $merged[$key] = $Base[$key]
    }

    foreach ($key in $Override.Keys) {
        if (($merged.ContainsKey($key)) -and ($merged[$key] -is [hashtable]) -and ($Override[$key] -is [hashtable])) {
            $merged[$key] = Merge-Hashtable -Base $merged[$key] -Override $Override[$key]
        }
        else {
            $merged[$key] = $Override[$key]
        }
    }

    return $merged
}

function Get-Configuration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('baseline', 'recommended', 'regulated')]
        [string]$ConfigurationTier
    )

    $configRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\config'))
    $defaultConfig = ConvertTo-Hashtable -InputObject ((Get-Content -Path (Join-Path $configRoot 'default-config.json') -Raw) | ConvertFrom-Json)
    $tierConfig = ConvertTo-Hashtable -InputObject ((Get-Content -Path (Join-Path $configRoot ("{0}.json" -f $ConfigurationTier)) -Raw) | ConvertFrom-Json)

    return (Merge-Hashtable -Base $defaultConfig -Override $tierConfig)
}

function Write-JsonWithHash {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [object]$Content,

        [Parameter(Mandatory)]
        [string]$ArtifactName,

        [Parameter(Mandatory)]
        [string]$ArtifactType
    )

    $directory = Split-Path -Path $Path -Parent
    if (-not (Test-Path -Path $directory)) {
        $null = New-Item -Path $directory -ItemType Directory -Force
    }

    $Content | ConvertTo-Json -Depth 10 | Set-Content -Path $Path -Encoding utf8

    $hashInfo = Write-CopilotGovSha256File -Path $Path

    return [pscustomobject]@{
        name = $ArtifactName
        type = $ArtifactType
        path = ([System.IO.Path]::GetFullPath($Path))
        hash = $hashInfo.Hash
    }
}

if ($PeriodStart -gt $PeriodEnd) {
    throw 'PeriodStart cannot be later than PeriodEnd.'
}

$configuration = Get-Configuration -ConfigurationTier $ConfigurationTier
$monitorScriptPath = Join-Path $PSScriptRoot 'Monitor-Compliance.ps1'

$monitorParameters = @{
    ConfigurationTier = $ConfigurationTier
    TenantId = $TenantId
    MaxSites = [int]$configuration.maxSitesPerRun
    WorkloadsToScan = [string[]]$configuration.scanWorkloads
}

$findings = @(& $monitorScriptPath @monitorParameters)
$outputRoot = [System.IO.Path]::GetFullPath($OutputPath)
$null = New-Item -Path $outputRoot -ItemType Directory -Force

$oversharingFindings = foreach ($finding in $findings) {
    [pscustomobject]@{
        siteUrl = $finding.SiteUrl
        workloadType = $finding.WorkloadType
        riskTier = $finding.RiskLevel
        exposureType = $finding.ExposureType
        permissionAnomalyCount = [int]$finding.PermissionAnomalyCount
        recommendedAction = $finding.RecommendedAction
        owner = $finding.Owner
        reportingPeriodStart = $PeriodStart.ToString('yyyy-MM-dd')
        reportingPeriodEnd = $PeriodEnd.ToString('yyyy-MM-dd')
    }
}

$queueIndex = 1
$remediationQueue = foreach ($finding in ($findings | Sort-Object -Property @{ Expression = 'RiskScore'; Descending = $true }, @{ Expression = 'PermissionAnomalyCount'; Descending = $true })) {
    $priority = switch ($finding.RiskLevel) {
        'HIGH' { 'P1' }
        'MEDIUM' { 'P2' }
        default { 'P3' }
    }

    $assignedTo = if ($finding.RiskLevel -eq 'HIGH') { 'SecurityOps' } else { 'SiteOwner' }
    $targetDate = switch ($finding.RiskLevel) {
        'HIGH' { (Get-Date).AddDays(3) }
        'MEDIUM' { (Get-Date).AddDays(7) }
        default { (Get-Date).AddDays(14) }
    }

    [pscustomobject]@{
        queueId = ('ORA-{0:D4}' -f $queueIndex)
        siteUrl = $finding.SiteUrl
        workloadType = $finding.WorkloadType
        priority = $priority
        riskTier = $finding.RiskLevel
        assignedTo = $assignedTo
        targetDate = $targetDate.ToString('yyyy-MM-dd')
        status = if ($configuration.remediationMode -eq 'detectOnly') { 'identified' } else { 'queued' }
        recommendedAction = $finding.RecommendedAction
    }

    $queueIndex++
}

$siteOwnerAttestations = if ($IncludeAttestations.IsPresent) {
    foreach ($queueItem in $remediationQueue | Where-Object { $_.priority -in @('P1', 'P2') }) {
        $owner = ($oversharingFindings | Where-Object { $_.siteUrl -eq $queueItem.siteUrl } | Select-Object -First 1).owner

        [pscustomobject]@{
            siteUrl = $queueItem.siteUrl
            owner = $owner
            attestationStatus = 'requested'
            requestedOn = (Get-Date).ToString('yyyy-MM-dd')
            dueBy = (Get-Date).AddDays(14).ToString('yyyy-MM-dd')
            remediationTicket = $queueItem.queueId
            notes = 'Owner attestation requested after remediation queue creation.'
        }
    }
}
else {
    @(
        [pscustomobject]@{
            siteUrl = $null
            owner = $null
            attestationStatus = 'not-requested'
            requestedOn = $null
            dueBy = $null
            remediationTicket = $null
            notes = 'IncludeAttestations switch was not supplied for this export.'
        }
    )
}

$artifacts = @()
$artifacts += Write-JsonWithHash -Path (Join-Path $outputRoot 'oversharing-findings.json') -Content @($oversharingFindings) -ArtifactName 'oversharing-findings' -ArtifactType 'oversharing-findings'
$artifacts += Write-JsonWithHash -Path (Join-Path $outputRoot 'remediation-queue.json') -Content @($remediationQueue) -ArtifactName 'remediation-queue' -ArtifactType 'remediation-queue'
$artifacts += Write-JsonWithHash -Path (Join-Path $outputRoot 'site-owner-attestations.json') -Content @($siteOwnerAttestations) -ArtifactName 'site-owner-attestations' -ArtifactType 'site-owner-attestations'

$controls = @(
    [pscustomobject]@{
        controlId = '1.2'
        status = 'partial'
        notes = 'DSPM for AI covers the top 100 sites only; tenant-wide coverage still requires local monitoring and remediation workflow tuning.'
    }
    [pscustomobject]@{
        controlId = '1.3'
        status = 'monitor-only'
        notes = 'Restricted SharePoint Search readiness is documented and tracked but not enforced directly by this script.'
    }
    [pscustomobject]@{
        controlId = '1.4'
        status = 'partial'
        notes = 'Semantic index governance is supported by scoped findings and remediation prioritization.'
    }
    [pscustomobject]@{
        controlId = '2.5'
        status = 'monitor-only'
        notes = 'Data minimization is supported through detection and recommended actions, but reduction remains a downstream remediation activity.'
    }
    [pscustomobject]@{
        controlId = '2.12'
        status = 'partial'
        notes = 'External sharing and guest access exposures are surfaced for cleanup and owner review.'
    }
    [pscustomobject]@{
        controlId = '1.6'
        status = 'monitor-only'
        notes = 'Permission model anomalies are counted and reported for follow-up.'
    }
)

$package = [ordered]@{
    metadata = [ordered]@{
        solution = $configuration.solution
        solutionCode = $configuration.solutionCode
        exportVersion = (Get-CopilotGovEvidenceSchemaVersion)
        exportedAt = (Get-Date).ToString('o')
        tier = $ConfigurationTier
        periodStart = $PeriodStart.ToString('yyyy-MM-dd')
        periodEnd = $PeriodEnd.ToString('yyyy-MM-dd')
    }
    summary = [ordered]@{
        overallStatus = 'partial'
        recordCount = (@($oversharingFindings).Count + @($remediationQueue).Count + @($siteOwnerAttestations).Count)
        findingCount = @($oversharingFindings).Count
        exceptionCount = @($siteOwnerAttestations | Where-Object { $_.attestationStatus -eq 'exception' }).Count
    }
    controls = $controls
    artifacts = $artifacts
}

$packageArtifact = Write-JsonWithHash -Path (Join-Path $outputRoot '02-oversharing-risk-assessment-evidence-package.json') -Content $package -ArtifactName 'ora-evidence-package' -ArtifactType 'evidence-package'
$validation = Test-CopilotGovEvidencePackage -Path $packageArtifact.path -ExpectedArtifacts @($configuration.evidenceOutputs)
if (-not $validation.IsValid) {
    $details = ($validation.Errors | ForEach-Object { ' - {0}' -f $_ }) -join [Environment]::NewLine
    throw ("Evidence validation failed for {0}:{1}{2}" -f $packageArtifact.path, [Environment]::NewLine, $details)
}

[pscustomobject]@{
    PackagePath = $packageArtifact.path
    PackageHash = $packageArtifact.hash
    ArtifactCount = @($artifacts).Count
    Findings = @($oversharingFindings).Count
    QueueItems = @($remediationQueue).Count
    Attestations = @($siteOwnerAttestations).Count
}
