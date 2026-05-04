<#
.SYNOPSIS
Deploys the Entra Access Reviews Automation solution.

.DESCRIPTION
Loads the solution default configuration plus the selected governance tier,
checks for upstream output from solution 02-oversharing-risk-assessment,
records a placeholder Microsoft Entra ID Governance licensing validation, and writes a
deployment manifest for auditability.

.PARAMETER ConfigurationTier
Selects the governance tier to apply. Supported values are baseline,
recommended, and regulated.

.PARAMETER OutputPath
Directory where the deployment manifest will be written.

.PARAMETER TenantId
Tenant GUID used to label the deployment manifest and dependency checks.

.PARAMETER WhatIf
Shows the deployment actions that would be taken without writing the manifest.

.EXAMPLE
.\Deploy-Solution.ps1 -ConfigurationTier recommended -TenantId 00000000-0000-0000-0000-000000000000

.EXAMPLE
.\Deploy-Solution.ps1 -ConfigurationTier regulated -TenantId 00000000-0000-0000-0000-000000000000 -WhatIf
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
    [string]$TenantId
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

function Test-EntraGovernanceLicense {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Configuration,

        [Parameter(Mandatory)]
        [string]$TenantId
    )

    $status = if ($env:EAR_ASSUME_GOVERNANCE_LICENSE -eq '1') { 'verified' } else { 'manual-check-required' }
    $notes = if ($status -eq 'verified') {
        'EAR_ASSUME_GOVERNANCE_LICENSE=1 was supplied for stub validation.'
    }
    else {
        'Validate Microsoft Entra ID Governance or Microsoft Entra Suite licensing in the tenant before production deployment; Microsoft Entra ID P2 applies only where Microsoft Learn documents support for the planned access review scenario.'
    }

    return [pscustomobject]@{
        Requirement = 'Microsoft Entra ID Governance or Microsoft Entra Suite'
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

    $dependencyRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\02-oversharing-risk-assessment\artifacts'))

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

$configuration = Get-Configuration -ConfigurationTier $ConfigurationTier
$upstreamCheck = Test-UpstreamReadinessOutput -DependencyName $configuration.upstreamDependency
$licenseCheck = Test-EntraGovernanceLicense -Configuration $configuration -TenantId $TenantId

$outputRoot = [System.IO.Path]::GetFullPath($OutputPath)
$manifestPath = Join-Path $outputRoot '18-entra-access-reviews-deployment.json'

$manifest = [ordered]@{
    solution = $configuration.solution
    solutionCode = $configuration.solutionCode
    displayName = $configuration.displayName
    version = $configuration.version
    tenantId = $TenantId
    tier = $ConfigurationTier
    exportedAt = (Get-Date).ToString('o')
    dependency = $upstreamCheck
    entraGovernanceLicense = $licenseCheck
    configurationSnapshot = [ordered]@{
        reviewScope = $configuration.reviewScope
        autoApplyDecisions = $configuration.autoApplyDecisions
        enableEscalation = $configuration.enableEscalation
        maxSitesPerRun = $configuration.maxSitesPerRun
        evidenceRetentionDays = $configuration.evidenceRetentionDays
    }
}

if ($PSCmdlet.ShouldProcess($outputRoot, 'Create access reviews deployment manifest')) {
    $null = New-Item -Path $outputRoot -ItemType Directory -Force
    $manifest | ConvertTo-Json -Depth 10 | Set-Content -Path $manifestPath -Encoding utf8
}

[pscustomobject]@{
    Solution = $configuration.displayName
    Tier = $ConfigurationTier
    TenantId = $TenantId
    DependencyStatus = $upstreamCheck.Status
    EntraGovernanceLicenseStatus = $licenseCheck.Status
    DeploymentManifestPath = $manifestPath
}
