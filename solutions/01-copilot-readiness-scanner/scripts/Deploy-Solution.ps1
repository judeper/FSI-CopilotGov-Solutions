<#
.SYNOPSIS
Deploys the Copilot Readiness Assessment Scanner configuration and manifest artifacts.

.DESCRIPTION
Loads default and tier-specific configuration for solution 01, validates local prerequisites,
performs a placeholder Microsoft Graph connectivity check for the target tenant, creates a
deployment manifest, and appends an entry to a deployment log. The script is designed as an
implementation-ready stub that can be extended with tenant-specific scheduling, secure secret
retrieval, and Power BI publishing steps.

.PARAMETER ConfigurationTier
Specifies the governance tier to deploy. Valid values are baseline, recommended, and regulated.

.PARAMETER OutputPath
Specifies the folder where deployment artifacts are written.

.PARAMETER TenantId
Specifies the Microsoft Entra tenant identifier used for connectivity validation.

.EXAMPLE
PS> .\Deploy-Solution.ps1 -ConfigurationTier recommended -TenantId 'contoso.onmicrosoft.com' -OutputPath '.\artifacts'

Creates a recommended-tier deployment manifest and registers the deployment event.

.EXAMPLE
PS> .\Deploy-Solution.ps1 -ConfigurationTier regulated -TenantId '11111111-1111-1111-1111-111111111111' -WhatIf

Shows what the regulated deployment would write without changing files.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [Parameter()]
    [ValidateSet('baseline', 'recommended', 'regulated')]
    [string]$ConfigurationTier = 'baseline',

    [Parameter()]
    [string]$OutputPath = (Join-Path $PSScriptRoot '..\artifacts'),

    [Parameter(Mandatory)]
    [string]$TenantId
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path $PSScriptRoot 'CRS-Common.psm1') -Force

function Test-ModuleAvailability {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    return [bool](Get-Module -ListAvailable -Name $Name)
}

function Test-SolutionPrerequisites {
    [CmdletBinding()]
    param()

    $requiredModules = @(
        'Microsoft.Graph',
        'ExchangeOnlineManagement',
        'PnP.PowerShell',
        'MicrosoftTeams'
    )

    $moduleResults = foreach ($moduleName in $requiredModules) {
        [pscustomobject]@{
            Name      = $moduleName
            Installed = (Test-ModuleAvailability -Name $moduleName)
        }
    }

    $sharedModuleFiles = @(
        'IntegrationConfig.psm1',
        'GraphAuth.psm1'
    )

    $sharedResults = foreach ($moduleFile in $sharedModuleFiles) {
        $modulePath = Join-Path (Join-Path (Get-RepositoryRoot) 'scripts\common') $moduleFile
        [pscustomobject]@{
            Name    = $moduleFile
            Path    = $modulePath
            Present = (Test-Path -Path $modulePath)
        }
    }

    $missingModules = @($moduleResults | Where-Object { -not $_.Installed } | Select-Object -ExpandProperty Name)
    $missingSharedModules = @($sharedResults | Where-Object { -not $_.Present } | Select-Object -ExpandProperty Name)

    return [pscustomobject]@{
        PowerShellVersion    = $PSVersionTable.PSVersion.ToString()
        RequiredModules      = $moduleResults
        MissingModules       = $missingModules
        SharedModules        = $sharedResults
        MissingSharedModules = $missingSharedModules
        IsReady              = ($PSVersionTable.PSVersion.Major -ge 7 -and $missingModules.Count -eq 0 -and $missingSharedModules.Count -eq 0)
    }
}

function Test-GraphConnectivityPlaceholder {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$TenantId
    )

    Import-SharedModule -ModuleName 'GraphAuth.psm1'
    $context = New-CopilotGovGraphContext -TenantId $TenantId -Scopes @(
        'LicenseAssignment.Read.All',
        'Organization.Read.All',
        'Directory.Read.All',
        'AuditLog.Read.All'
    )

    return [pscustomobject]@{
        IsConnected = $false
        Mode        = 'placeholder'
        TenantId    = $TenantId
        Scopes      = $context.Scopes
        ConnectedAt = $context.ConnectedAt
    }
}

function New-DeploymentManifest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$Configuration,

        [Parameter(Mandatory)]
        [string]$TierLabel,

        [Parameter(Mandatory)]
        [pscustomobject]$Prerequisites,

        [Parameter(Mandatory)]
        [pscustomobject]$GraphValidation,

        [Parameter(Mandatory)]
        [string]$TenantId
    )

    return [ordered]@{
        solution        = $Configuration.solution
        solutionCode    = $Configuration.solutionCode
        displayName     = $Configuration.displayName
        version         = $Configuration.version
        tier            = $Configuration.tier
        tierLabel       = $TierLabel
        tenantId        = $TenantId
        deployedAt      = (Get-Date).ToString('o')
        reportFormat    = $Configuration.reportFormat
        graphApiVersion = $Configuration.graphApiVersion
        scanDomains     = $Configuration.scanDomains
        controls        = $Configuration.controls
        defaults        = $Configuration.defaults
        prerequisites   = $Prerequisites
        connectivity    = $GraphValidation
    }
}

try {
    Write-Verbose "Loading configuration for tier [$ConfigurationTier]."
    $configuration = Get-SolutionConfiguration -Tier $ConfigurationTier

    Write-Verbose 'Importing shared tier helper module.'
    Import-SharedModule -ModuleName 'IntegrationConfig.psm1'
    $tierDefinition = Get-CopilotGovTierDefinition -Tier $ConfigurationTier

    Write-Verbose 'Validating local prerequisites.'
    $prerequisites = Test-SolutionPrerequisites
    if (-not $prerequisites.IsReady) {
        $missingItems = @($prerequisites.MissingModules + $prerequisites.MissingSharedModules)
        throw "Prerequisite validation failed. Missing components: $([string]::Join(', ', $missingItems))"
    }

    Write-Verbose "Performing placeholder Graph connectivity validation for tenant [$TenantId]."
    $graphValidation = Test-GraphConnectivityPlaceholder -TenantId $TenantId

    $resolvedOutputPath = [System.IO.Path]::GetFullPath($OutputPath)
    $timestamp = Get-Date -Format 'yyyyMMddHHmmss'
    $manifestName = "CRS-deployment-manifest-{0}-{1}.json" -f $ConfigurationTier, $timestamp
    $manifestPath = Join-Path $resolvedOutputPath $manifestName
    $deploymentLogPath = Join-Path $resolvedOutputPath 'deployment-log.jsonl'

    $manifest = New-DeploymentManifest `
        -Configuration $configuration `
        -TierLabel $tierDefinition.Label `
        -Prerequisites $prerequisites `
        -GraphValidation $graphValidation `
        -TenantId $TenantId

    $status = 'whatif'
    if ($PSCmdlet.ShouldProcess($resolvedOutputPath, 'Create deployment manifest and register deployment log entry')) {
        $null = New-Item -ItemType Directory -Path $resolvedOutputPath -Force
        $manifest | ConvertTo-Json -Depth 8 | Set-Content -Path $manifestPath -Encoding utf8

        $logEntry = [ordered]@{
            timestamp    = (Get-Date).ToString('o')
            solution     = $configuration.solution
            solutionCode = $configuration.solutionCode
            tier         = $ConfigurationTier
            tenantId     = $TenantId
            manifestPath = $manifestPath
            status       = 'registered'
            operator     = [System.Environment]::UserName
        }

        $logEntry | ConvertTo-Json -Compress | Add-Content -Path $deploymentLogPath -Encoding utf8
        $status = 'registered'
        Write-Information "Deployment manifest created at $manifestPath"
    }

    [pscustomobject]@{
        Solution          = $configuration.displayName
        Tier              = $ConfigurationTier
        TenantId          = $TenantId
        Status            = $status
        ManifestPath      = $manifestPath
        DeploymentLogPath = $deploymentLogPath
        GraphConnectivity = $graphValidation.Mode
        ScanDomains       = $configuration.scanDomains
    }
}
catch {
    Write-Error -Message ("Deployment failed: {0}" -f $_.Exception.Message)
    throw
}
