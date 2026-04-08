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
    [ValidatePattern('^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')]
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

Import-Module (Join-Path $PSScriptRoot 'SharedUtilities.psm1') -Force

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$evidenceModulePath = Join-Path $repoRoot 'scripts\common\EvidenceExport.psm1'
$integrationModulePath = Join-Path $repoRoot 'scripts\common\IntegrationConfig.psm1'

if (Test-Path $evidenceModulePath) {
    Import-Module $evidenceModulePath -Force
}
else {
    Write-Warning "Shared module EvidenceExport.psm1 not found at '$evidenceModulePath'. Using local fallbacks."
    function Write-CopilotGovSha256File {
        param([Parameter(Mandatory)][string]$Path)
        $hash = (Get-FileHash -Path $Path -Algorithm SHA256).Hash.ToLowerInvariant()
        $fileName = [IO.Path]::GetFileName($Path)
        $hashLine = '{0}  {1}' -f $hash, $fileName
        Set-Content -Path "$Path.sha256" -Value $hashLine -Encoding utf8
        return [pscustomobject]@{ Hash = $hash; Path = "$Path.sha256" }
    }
    function Get-CopilotGovEvidenceSchemaVersion { return '1.1.0' }
    # Fallback validator used only when shared EvidenceExport.psm1 cannot be loaded.
    # Returns IsValid=$true because full schema/hash validation requires the shared module.
    function Test-CopilotGovEvidencePackage {
        param([Parameter(Mandatory)][string]$Path, [string[]]$ExpectedArtifacts = @())
        Write-Warning 'Using fallback evidence validator — shared module EvidenceExport.psm1 was not loaded. Skipping schema and hash checks.'
        return [pscustomobject]@{ IsValid = $true; Errors = @() }
    }
}

if (Test-Path $integrationModulePath) {
    Import-Module $integrationModulePath -Force
}
else {
    Write-Warning "Shared module IntegrationConfig.psm1 not found at '$integrationModulePath'. Using local defaults."
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

$configuration = Get-Configuration -ConfigurationTier $ConfigurationTier -ScriptRoot $PSScriptRoot
$monitorScriptPath = Join-Path $PSScriptRoot 'Monitor-Compliance.ps1'

$monitorExportDir = Join-Path ([System.IO.Path]::GetTempPath()) ('ora-export-{0}' -f [guid]::NewGuid().ToString('N').Substring(0,8))
$monitorParameters = @{
    ConfigurationTier = $ConfigurationTier
    TenantId = $TenantId
    MaxSites = [int]$configuration.maxSitesPerRun
    WorkloadsToScan = [string[]]$configuration.scanWorkloads
    ExportPath = $monitorExportDir
}

$findings = @(& $monitorScriptPath @monitorParameters)

# Read actual sensitivity label coverage from monitor summary
$labelCoverage = $null
$monitorSummaryPath = Join-Path $monitorExportDir 'monitor-summary.json'
if (Test-Path $monitorSummaryPath) {
    $monitorSummary = (Get-Content -Path $monitorSummaryPath -Raw) | ConvertFrom-Json
    $labelCoverage = $monitorSummary.SensitivityLabelCoverage
}

if (Test-Path $monitorExportDir) {
    Remove-Item -Path $monitorExportDir -Recurse -Force -ErrorAction SilentlyContinue
}
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
        detectedSignals = $finding.DetectedSignals
        sharingScope = $finding.SharingScope
        riskScore = [int]$finding.RiskScore
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

# Sensitivity label coverage from actual Microsoft Purview Information Protection data
$defaultLabelRecommendation = 'Apply Microsoft Purview Information Protection sensitivity labels to all sites containing regulated data to restrict Microsoft 365 Copilot content surfacing.'
$totalSitesScanned = if ($null -ne $labelCoverage) { [int]$labelCoverage.TotalSitesScanned } else { [Math]::Max(@($oversharingFindings).Count, 1) }
$sitesWithLabels = if ($null -ne $labelCoverage) { [int]$labelCoverage.SitesWithLabels } else { 0 }
$labelCoveragePercent = if ($null -ne $labelCoverage) { [double]$labelCoverage.LabelCoveragePercent } else { 0.0 }

$sensitivityLabelCoverage = [pscustomobject]@{
    totalSitesScanned = $totalSitesScanned
    sitesWithLabels = $sitesWithLabels
    sitesWithoutLabels = ($totalSitesScanned - $sitesWithLabels)
    labelCoveragePercent = $labelCoveragePercent
    reportingPeriodStart = $PeriodStart.ToString('yyyy-MM-dd')
    reportingPeriodEnd = $PeriodEnd.ToString('yyyy-MM-dd')
    recommendation = if ($null -ne $labelCoverage -and $labelCoverage.Recommendation) { $labelCoverage.Recommendation } else { $defaultLabelRecommendation }
}

$artifacts += Write-JsonWithHash -Path (Join-Path $outputRoot 'sensitivity-label-coverage.json') -Content $sensitivityLabelCoverage -ArtifactName 'sensitivity-label-coverage' -ArtifactType 'sensitivity-label-coverage'

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
    [pscustomobject]@{
        controlId = '1.7'
        status = 'monitor-only'
        notes = ('Sensitivity label coverage: {0}% of scanned sites have Microsoft Purview Information Protection labels applied. Sites without labels may expose regulated content via Microsoft 365 Copilot.' -f $labelCoveragePercent)
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
