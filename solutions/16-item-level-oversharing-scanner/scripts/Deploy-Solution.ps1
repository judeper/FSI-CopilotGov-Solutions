<#
.SYNOPSIS
Deploys the Item-Level Oversharing Scanner solution.

.DESCRIPTION
Loads the solution default configuration plus the selected governance tier,
checks for upstream output from solution 02-oversharing-risk-assessment,
validates deployment prerequisites, and writes a deployment manifest for
auditability.

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

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
Import-Module (Join-Path $repoRoot 'scripts\common\GraphAuth.psm1') -Force
Import-Module (Join-Path $repoRoot 'scripts\common\EvidenceExport.psm1') -Force

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

function Test-UpstreamDependencyOutput {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$DependencyName
    )

    $dependencyRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\02-oversharing-risk-assessment\artifacts'))

    if (-not (Test-Path -Path $dependencyRoot)) {
        return [pscustomobject]@{
            Dependency = $DependencyName
            Status = 'not-found'
            OutputPath = $dependencyRoot
            ArtifactCount = 0
            Notes = "Upstream dependency output path not found. Run $DependencyName first."
        }
    }

    $artifactFiles = Get-ChildItem -Path $dependencyRoot -Filter *.json -Recurse -File -ErrorAction SilentlyContinue
    if (-not $artifactFiles) {
        return [pscustomobject]@{
            Dependency = $DependencyName
            Status = 'empty'
            OutputPath = $dependencyRoot
            ArtifactCount = 0
            Notes = "Upstream dependency output path exists but contains no JSON artifacts."
        }
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
$upstreamCheck = Test-UpstreamDependencyOutput -DependencyName $configuration.upstreamDependency

$outputRoot = [System.IO.Path]::GetFullPath($OutputPath)
$manifestPath = Join-Path $outputRoot '16-item-level-oversharing-scanner-deployment.json'

$manifest = [ordered]@{
    solution = $configuration.solution
    solutionCode = $configuration.solutionCode
    displayName = $configuration.displayName
    version = $configuration.version
    tenantId = $TenantId
    tier = $ConfigurationTier
    exportedAt = (Get-Date).ToString('o')
    dependency = $upstreamCheck
    configurationSnapshot = [ordered]@{
        scanWorkloads = $configuration.scanWorkloads
        remediationMode = $configuration.remediationMode
        maxSitesPerRun = $configuration.maxSitesPerRun
        maxItemsPerLibrary = $configuration.maxItemsPerLibrary
        autoRemediationEnabled = $configuration.autoRemediationEnabled
        requireApprovalForHigh = $configuration.requireApprovalForHigh
    }
}

if ($PSCmdlet.ShouldProcess($outputRoot, 'Create item-level oversharing deployment manifest')) {
    $null = New-Item -Path $outputRoot -ItemType Directory -Force
    $manifest | ConvertTo-Json -Depth 10 | Set-Content -Path $manifestPath -Encoding utf8
}

[pscustomobject]@{
    Solution = $configuration.displayName
    Tier = $ConfigurationTier
    TenantId = $TenantId
    DependencyStatus = $upstreamCheck.Status
    DeploymentManifestPath = $manifestPath
}
