<#
.SYNOPSIS
    Validates configuration and prerequisites for SharePoint Permissions Drift Detection.

.DESCRIPTION
    Loads the solution configuration for the selected tier, validates prerequisite
    modules and upstream dependency output, and generates a deployment manifest.
    This script does not make changes to the tenant — it prepares and validates
    the deployment configuration.

.PARAMETER ConfigurationTier
    The configuration tier to deploy. Valid values: baseline, recommended, regulated.

.PARAMETER TenantId
    The Microsoft Entra tenant identifier.

.PARAMETER OutputPath
    Directory for deployment artifacts. Defaults to .\artifacts\SPD.

.EXAMPLE
    .\Deploy-Solution.ps1 -ConfigurationTier recommended -TenantId "00000000-0000-0000-0000-000000000000"

.EXAMPLE
    .\Deploy-Solution.ps1 -ConfigurationTier regulated -TenantId "00000000-0000-0000-0000-000000000000" -WhatIf
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter()]
    [ValidateSet('baseline', 'recommended', 'regulated')]
    [string]$ConfigurationTier = 'baseline',

    [Parameter()]
    [string]$OutputPath = '.\artifacts\SPD',

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$TenantId
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
Import-Module (Join-Path $repoRoot 'scripts\common\GraphAuth.psm1') -Force
Import-Module (Join-Path $repoRoot 'scripts\common\EvidenceExport.psm1') -Force

#region Helper Functions

function ConvertTo-Hashtable {
    param([Parameter(ValueFromPipeline)] $InputObject)
    process {
        if ($null -eq $InputObject) { return @{} }
        if ($InputObject -is [System.Collections.IDictionary]) { return $InputObject }
        $ht = @{}
        foreach ($prop in $InputObject.PSObject.Properties) {
            $ht[$prop.Name] = if ($prop.Value -is [PSCustomObject]) {
                ConvertTo-Hashtable $prop.Value
            } else { $prop.Value }
        }
        return $ht
    }
}

function Merge-Hashtable {
    param([hashtable]$Base, [hashtable]$Override)
    $merged = $Base.Clone()
    foreach ($key in $Override.Keys) {
        if ($merged.ContainsKey($key) -and $merged[$key] -is [hashtable] -and $Override[$key] -is [hashtable]) {
            $merged[$key] = Merge-Hashtable -Base $merged[$key] -Override $Override[$key]
        }
        else {
            $merged[$key] = $Override[$key]
        }
    }
    return $merged
}

function Get-Configuration {
    param([string]$Tier)
    $solutionRoot = Join-Path $PSScriptRoot '..'
    $defaultPath = Join-Path $solutionRoot 'config\default-config.json'
    $tierPath = Join-Path $solutionRoot "config\$Tier.json"

    $default = Get-Content -Path $defaultPath -Raw | ConvertFrom-Json | ConvertTo-Hashtable

    if (Test-Path $tierPath) {
        $tierOverride = Get-Content -Path $tierPath -Raw | ConvertFrom-Json | ConvertTo-Hashtable
        return Merge-Hashtable -Base $default -Override $tierOverride
    }
    return $default
}

function Test-RequiredModuleAvailable {
    param(
        [string]$ModuleName,
        [string]$MinimumVersion
    )

    $modules = Get-Module -ListAvailable -Name $ModuleName -ErrorAction SilentlyContinue
    $highestModule = $modules | Sort-Object -Property Version -Descending | Select-Object -First 1
    $installedVersion = if ($highestModule) { $highestModule.Version } else { $null }
    $minimumVersionObject = [version]$MinimumVersion
    $isAvailable = $false

    if ($null -ne $installedVersion) {
        $isAvailable = ([version]$installedVersion -ge $minimumVersionObject)
    }

    return [pscustomobject]@{
        Available        = $isAvailable
        ModuleName       = $ModuleName
        InstalledVersion = if ($installedVersion) { $installedVersion.ToString() } else { 'Not installed' }
        MinimumVersion   = $MinimumVersion
    }
}

function Test-PnPModuleAvailable {
    return Test-RequiredModuleAvailable -ModuleName 'PnP.PowerShell' -MinimumVersion '2.3.0'
}

function Test-GraphModuleAvailable {
    return Test-RequiredModuleAvailable -ModuleName 'Microsoft.Graph' -MinimumVersion '2.0.0'
}

function Test-UpstreamReadinessOutput {
    $upstreamPath = Join-Path $PSScriptRoot '..\..\02-oversharing-risk-assessment'
    return [pscustomobject]@{
        UpstreamSolution = '02-oversharing-risk-assessment'
        PathExists       = (Test-Path $upstreamPath)
        Status           = if (Test-Path $upstreamPath) { 'Available' } else { 'NotFound' }
    }
}

#endregion

#region Main Logic

Write-Host "=== SharePoint Permissions Drift Detection — Deployment ===" -ForegroundColor Cyan
Write-Host "Configuration tier: $ConfigurationTier"
Write-Host "Tenant ID: $TenantId"

$config = Get-Configuration -Tier $ConfigurationTier

# Prerequisite checks
$pnpCheck = Test-PnPModuleAvailable
$graphCheck = Test-GraphModuleAvailable
$upstreamCheck = Test-UpstreamReadinessOutput

Write-Host "`nPrerequisite Checks:" -ForegroundColor Yellow
Write-Host "  PnP.PowerShell: $($pnpCheck.InstalledVersion) (required: $($pnpCheck.MinimumVersion))"
Write-Host "  Microsoft.Graph: $($graphCheck.InstalledVersion) (required: $($graphCheck.MinimumVersion))"
Write-Host "  Upstream (Solution 02): $($upstreamCheck.Status)"

$failedModuleChecks = @($pnpCheck, $graphCheck) | Where-Object { -not $_.Available }
if ($failedModuleChecks.Count -gt 0) {
    foreach ($check in $failedModuleChecks) {
        Write-Warning "$($check.ModuleName) version check failed. Installed: $($check.InstalledVersion); required: $($check.MinimumVersion)."
    }
    throw 'Prerequisite module version check failed.'
}

if ($PSCmdlet.ShouldProcess("$OutputPath", "Generate deployment manifest")) {
    # Ensure output directory
    if (-not (Test-Path $OutputPath)) {
        New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
    }

    $deploymentManifest = [pscustomobject]@{
        solution          = '17-sharepoint-permissions-drift'
        solutionCode      = 'SPD'
        displayName       = 'SharePoint Permissions Drift Detection'
        version           = if ($config.ContainsKey('version')) { [string]$config['version'] } else { 'v0.1.4' }
        deployedAt        = (Get-Date).ToString('o')
        configurationTier = $ConfigurationTier
        tenantId          = $TenantId
        prerequisites     = [pscustomobject]@{
            pnpPowerShell  = $pnpCheck
            microsoftGraph = $graphCheck
        }
        upstreamDependency = $upstreamCheck
        configurationSnapshot = $config
    }

    $manifestPath = Join-Path $OutputPath 'SPD-deployment.json'
    $deploymentManifest | ConvertTo-Json -Depth 10 | Set-Content -Path $manifestPath -Encoding UTF8
    Write-Host "`nDeployment manifest saved: $manifestPath" -ForegroundColor Green
}

#endregion

# Return summary
[pscustomobject]@{
    Solution          = '17-sharepoint-permissions-drift'
    ConfigurationTier = $ConfigurationTier
    TenantId          = $TenantId
    PnPAvailable      = $pnpCheck.Available
    GraphAvailable    = $graphCheck.Available
    UpstreamStatus    = $upstreamCheck.Status
    ManifestPath      = (Join-Path $OutputPath 'SPD-deployment.json')
    Status            = 'DeploymentValidated'
}
