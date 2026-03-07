<#
.SYNOPSIS
Deploys the Oversharing Risk Assessment and Remediation solution.

.DESCRIPTION
Loads the solution default configuration plus the selected governance tier,
checks for upstream output from solution 01-copilot-readiness-scanner,
records a placeholder SharePoint Advanced Management license validation,
marks Restricted SharePoint Search readiness when configured, and writes a
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
    [string]$TenantId,

    [Parameter()]
    [ValidateSet('DetectOnly', 'Notify', 'AutoRemediate')]
    [string]$ScanMode = 'DetectOnly'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

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
    $defaultConfigPath = Join-Path $configRoot 'default-config.json'
    $tierConfigPath = Join-Path $configRoot ("{0}.json" -f $ConfigurationTier)

    $defaultConfig = ConvertTo-Hashtable -InputObject ((Get-Content -Path $defaultConfigPath -Raw) | ConvertFrom-Json)
    $tierConfig = ConvertTo-Hashtable -InputObject ((Get-Content -Path $tierConfigPath -Raw) | ConvertFrom-Json)

    return (Merge-Hashtable -Base $defaultConfig -Override $tierConfig)
}

function Test-SharePointAdvancedManagementLicense {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Configuration,

        [Parameter(Mandatory)]
        [string]$TenantId
    )

    $status = if ($env:ORA_ASSUME_SAM_LICENSE -eq '1') { 'verified' } else { 'manual-check-required' }
    $notes = if ($status -eq 'verified') {
        'ORA_ASSUME_SAM_LICENSE=1 was supplied for stub validation.'
    }
    else {
        'Validate SharePoint Advanced Management licensing in the tenant before production deployment.'
    }

    return [pscustomobject]@{
        Requirement = 'SharePoint Advanced Management'
        TenantId = $TenantId
        Status = $status
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

    $enabled = [bool]($Configuration.enableRestrictedSharePointSearch -or $Configuration.restrictedSharePointSearchEnabled)
    if (-not $enabled) {
        return [pscustomobject]@{
            Enabled = $false
            Status = 'not-requested'
            Notes = 'Selected tier does not request Restricted SharePoint Search.'
        }
    }

    $status = if ($ScanMode -eq 'AutoRemediate') { 'planned-enable' } else { 'planned-enable' }

    return [pscustomobject]@{
        Enabled = $true
        Status = $status
        Notes = 'Placeholder action only. Validate search scoping with SharePoint administrators before enforcement.'
    }
}

$configuration = Get-Configuration -ConfigurationTier $ConfigurationTier
$upstreamCheck = Test-UpstreamReadinessOutput -DependencyName $configuration.upstreamDependency
$licenseCheck = Test-SharePointAdvancedManagementLicense -Configuration $configuration -TenantId $TenantId
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
