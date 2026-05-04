<#
.SYNOPSIS
Deploys the Oversharing Risk Assessment and Remediation solution.

.DESCRIPTION
Loads the solution default configuration plus the selected governance tier,
checks for upstream output from solution 01-copilot-readiness-scanner,
records a placeholder SharePoint Advanced Management feature-entitlement validation,
marks temporary Restricted SharePoint Search readiness when configured, and writes a
deployment manifest for auditability.

.PARAMETER ConfigurationTier
Selects the governance tier to apply. Supported values are baseline,
recommended, and regulated.

.PARAMETER OutputPath
Directory where the deployment manifest will be written.

.PARAMETER TenantId
Tenant GUID used to label the deployment manifest and dependency checks.

.PARAMETER ScanMode
Requested operating mode for the solution. Supported values are DetectOnly,
Notify, and AutoRemediate.

.PARAMETER WhatIf
Shows the deployment actions that would be taken without writing the manifest.

.EXAMPLE
.\Deploy-Solution.ps1 -ConfigurationTier recommended -TenantId 00000000-0000-0000-0000-000000000000 -ScanMode DetectOnly

.EXAMPLE
.\Deploy-Solution.ps1 -ConfigurationTier regulated -TenantId 00000000-0000-0000-0000-000000000000 -ScanMode Notify -WhatIf
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter()]
    [ValidateSet('baseline', 'recommended', 'regulated')]
    [string]$ConfigurationTier = 'baseline',

    [Parameter()]
    [string]$OutputPath = (Join-Path $PSScriptRoot '..\artifacts\deployment'),

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [ValidatePattern('^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')]
    [string]$TenantId,

    [Parameter()]
    [ValidateSet('DetectOnly', 'Notify', 'AutoRemediate')]
    [string]$ScanMode = 'DetectOnly'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path $PSScriptRoot 'SharedUtilities.psm1') -Force

function Test-SharePointAdvancedManagementEntitlement {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Configuration,

        [Parameter(Mandatory)]
        [string]$TenantId
    )

    $assumeEntitlement = $env:ORA_ASSUME_SAM_ENTITLEMENT -eq '1' -or $env:ORA_ASSUME_SAM_LICENSE -eq '1'
    $status = if ($assumeEntitlement) { 'verified' } else { 'manual-check-required' }
    $notes = if ($status -eq 'verified') {
        'ORA_ASSUME_SAM_ENTITLEMENT=1 or ORA_ASSUME_SAM_LICENSE=1 was supplied for stub validation.'
    }
    else {
        'Validate the required base license plus either a Microsoft 365 Copilot license assignment or a standalone Microsoft SharePoint Advanced Management license before production deployment.'
    }

    return [pscustomobject]@{
        Requirement = 'SharePoint Advanced Management feature entitlement'
        TenantId = $TenantId
        Status = $status
        BaseLicenseRequirement = 'Office 365 E3/E5/A5 or Microsoft 365 E1/E3/E5/A5'
        EntitlementPaths = @(
            'Microsoft 365 Copilot license assigned to at least one user'
            'Standalone Microsoft SharePoint Advanced Management license'
        )
        Notes = $notes
    }
}

function Test-UpstreamReadinessOutput {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$DependencyName
    )

    $dependencyRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\01-copilot-readiness-scanner\artifacts'))

    if (-not (Test-Path -Path $dependencyRoot)) {
        throw ("Upstream dependency output path not found: {0}. Run {1} first." -f $dependencyRoot, $DependencyName)
    }

    $artifactFiles = Get-ChildItem -Path $dependencyRoot -Filter *.json -Recurse -File -ErrorAction Stop
    if (-not $artifactFiles) {
        throw ("Upstream dependency output path '{0}' does not contain JSON artifacts." -f $dependencyRoot)
    }

    return [pscustomobject]@{
        Dependency = $DependencyName
        Status = 'validated'
        OutputPath = $dependencyRoot
        ArtifactCount = $artifactFiles.Count
        SampleArtifact = $artifactFiles[0].FullName
    }
}

function Resolve-RestrictedSharePointSearchState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Configuration,

        [Parameter(Mandatory)]
        [ValidateSet('DetectOnly', 'Notify', 'AutoRemediate')]
        [string]$ScanMode
    )

    $enabled = [bool]$Configuration.enableRestrictedSharePointSearch
    if (-not $enabled) {
        return [pscustomobject]@{
            Enabled = $false
            Status = 'not-requested'
            Notes = 'Selected tier does not request Restricted SharePoint Search.'
        }
    }

    $status = if ($ScanMode -eq 'AutoRemediate') { 'planned-temporary-enable-with-approval' } else { 'planned-temporary-enable' }

    return [pscustomobject]@{
        Enabled = $true
        Status = $status
        Notes = 'Temporary planning placeholder only. Restricted SharePoint Search is limited to 100 allowed sites, is not a security boundary, does not change permissions, and documents that allowed-list membership is not the only way content can appear in search or Copilot responses.'
    }
}

$configuration = Get-Configuration -ConfigurationTier $ConfigurationTier -ScriptRoot $PSScriptRoot
$upstreamCheck = Test-UpstreamReadinessOutput -DependencyName $configuration.upstreamDependency
$licenseCheck = Test-SharePointAdvancedManagementEntitlement -Configuration $configuration -TenantId $TenantId
$restrictedSearchState = Resolve-RestrictedSharePointSearchState -Configuration $configuration -ScanMode $ScanMode

$outputRoot = [System.IO.Path]::GetFullPath($OutputPath)
$manifestPath = Join-Path $outputRoot '02-oversharing-risk-assessment-deployment.json'

$manifest = [ordered]@{
    solution = $configuration.solution
    solutionCode = $configuration.solutionCode
    displayName = $configuration.displayName
    version = $configuration.version
    tenantId = $TenantId
    tier = $ConfigurationTier
    scanMode = $ScanMode
    exportedAt = (Get-Date).ToString('o')
    dependency = $upstreamCheck
    sharePointAdvancedManagement = $licenseCheck
    restrictedSharePointSearch = $restrictedSearchState
    configurationSnapshot = [ordered]@{
        scanWorkloads = $configuration.scanWorkloads
        remediationMode = $configuration.remediationMode
        maxSitesPerRun = $configuration.maxSitesPerRun
        notificationMode = $configuration.notificationMode
        enableSiteOwnerNotifications = $configuration.enableSiteOwnerNotifications
        evidenceRetentionDays = $configuration.evidenceRetentionDays
        riskThresholds = $configuration.riskThresholds
        requireOwnerAttestation = $configuration.requireOwnerAttestation
        requireExaminerReadyEvidence = $configuration.requireExaminerReadyEvidence
    }
}

if ($PSCmdlet.ShouldProcess($outputRoot, 'Create oversharing deployment manifest')) {
    $null = New-Item -Path $outputRoot -ItemType Directory -Force
    $manifest | ConvertTo-Json -Depth 10 | Set-Content -Path $manifestPath -Encoding utf8
}

[pscustomobject]@{
    Solution = $configuration.displayName
    Tier = $ConfigurationTier
    TenantId = $TenantId
    ScanMode = $ScanMode
    DependencyStatus = $upstreamCheck.Status
    SharePointAdvancedManagementStatus = $licenseCheck.Status
    RestrictedSharePointSearchStatus = $restrictedSearchState.Status
    DeploymentManifestPath = $manifestPath
}
