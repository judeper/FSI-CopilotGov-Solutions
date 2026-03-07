#Requires -Version 7.0
<#
.SYNOPSIS
    Deploys the FINRA Supervision Workflow configuration for Microsoft 365 Copilot.
.DESCRIPTION
    Validates prerequisites, applies tier-specific configuration, generates a deployment
    manifest, and prepares Dataverse connection reference stubs. Power Automate flows
    and Dataverse tables must be created manually per docs\deployment-guide.md because
    the Power Platform CLI is not required as a dependency for this solution.
.PARAMETER ConfigurationTier
    Governance tier: baseline, recommended, or regulated.
.PARAMETER OutputPath
    Directory for deployment manifest and evidence stubs.
.PARAMETER EnvironmentUrl
    Power Platform environment URL (for example, https://org.crm.dynamics.com).
.PARAMETER WhatIf
    Preview actions without writing files.
.EXAMPLE
    .\Deploy-Solution.ps1 -ConfigurationTier regulated -EnvironmentUrl https://contoso.crm.dynamics.com
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter()]
    [ValidateSet('baseline', 'recommended', 'regulated')]
    [string]$ConfigurationTier = 'baseline',

    [Parameter()]
    [string]$OutputPath = (Join-Path $PSScriptRoot '..\artifacts\deployment'),

    [Parameter()]
    [string]$EnvironmentUrl
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Read-JsonFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not (Test-Path -Path $Path -PathType Leaf)) {
        throw "JSON file not found: $Path"
    }

    return Get-Content -Path $Path -Raw | ConvertFrom-Json -AsHashtable
}

function Get-ConfiguredEnvironmentUrl {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$DefaultConfig
    )

    $defaults = $DefaultConfig['defaults']
    if ($defaults.Contains('dataverseEnvironmentUrl') -and -not [string]::IsNullOrWhiteSpace([string]$defaults['dataverseEnvironmentUrl'])) {
        return [string]$defaults['dataverseEnvironmentUrl']
    }

    if ($defaults.Contains('datverseEnvironmentUrl') -and -not [string]::IsNullOrWhiteSpace([string]$defaults['datverseEnvironmentUrl'])) {
        return [string]$defaults['datverseEnvironmentUrl']
    }

    return $null
}

function Get-EffectiveConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$SolutionRoot,

        [Parameter(Mandatory)]
        [ValidateSet('baseline', 'recommended', 'regulated')]
        [string]$Tier,

        [Parameter()]
        [string]$OverrideEnvironmentUrl
    )

    $defaultConfig = Read-JsonFile -Path (Join-Path $SolutionRoot 'config\default-config.json')
    $tierConfig = Read-JsonFile -Path (Join-Path $SolutionRoot ("config\{0}.json" -f $Tier))

    $supportedZones = @($tierConfig['supportedZones'])
    $effectiveSamplingRates = [ordered]@{}
    $effectiveSlaHours = [ordered]@{}
    $defaultSampling = $defaultConfig['defaults']['samplingRates']
    $defaultSla = $defaultConfig['defaults']['slaHoursByZone']

    foreach ($zone in $supportedZones) {
        if ($tierConfig['samplingRates'].Contains($zone)) {
            $effectiveSamplingRates[$zone] = [int]$tierConfig['samplingRates'][$zone]
        }
        elseif ($defaultSampling.Contains($zone) -and $defaultSampling[$zone].Contains($Tier)) {
            $effectiveSamplingRates[$zone] = [int]$defaultSampling[$zone][$Tier]
        }

        if ($tierConfig['slaHoursByZone'].Contains($zone)) {
            $effectiveSlaHours[$zone] = [int]$tierConfig['slaHoursByZone'][$zone]
        }
        elseif ($defaultSla.Contains($zone)) {
            $effectiveSlaHours[$zone] = [int]$defaultSla[$zone]
        }
    }

    $resolvedEnvironmentUrl = if (-not [string]::IsNullOrWhiteSpace($OverrideEnvironmentUrl)) {
        $OverrideEnvironmentUrl
    }
    else {
        Get-ConfiguredEnvironmentUrl -DefaultConfig $defaultConfig
    }

    return [ordered]@{
        solution = $defaultConfig['solution']
        tier = $Tier
        controls = @($defaultConfig['controls'])
        regulations = @($defaultConfig['regulations'])
        evidenceOutputs = @($defaultConfig['evidenceOutputs'])
        connectionReferences = @($defaultConfig['connectionReferences'])
        environmentVariables = @($defaultConfig['environmentVariables'])
        dataverseTables = @($defaultConfig['dataverseTables'])
        powerAutomateFlows = @($defaultConfig['powerAutomateFlows'])
        supportedZones = $supportedZones
        samplingRates = $effectiveSamplingRates
        slaHoursByZone = $effectiveSlaHours
        escalationEnabled = [bool]$tierConfig['escalationEnabled']
        notifications = $tierConfig['notifications']
        reviewDispositionValues = @($tierConfig['reviewDispositionValues'])
        exceptionTracking = $tierConfig['exceptionTracking']
        immutableLogRequired = [bool]$tierConfig['immutableLogRequired']
        evidenceRetentionDays = [int]$tierConfig['evidenceRetentionDays']
        purviewPolicyId = [string]$defaultConfig['defaults']['purviewPolicyId']
        dataverseEnvironmentUrl = $resolvedEnvironmentUrl
    }
}

function Test-RequiredConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$Configuration
    )

    $missing = New-Object System.Collections.Generic.List[string]

    foreach ($field in @('supportedZones', 'samplingRates', 'slaHoursByZone', 'notifications', 'reviewDispositionValues', 'exceptionTracking')) {
        if (-not $Configuration.Contains($field)) {
            $missing.Add($field)
        }
    }

    foreach ($zone in @($Configuration['supportedZones'])) {
        if (-not $Configuration['samplingRates'].Contains($zone)) {
            $missing.Add("samplingRates.$zone")
        }

        if (-not $Configuration['slaHoursByZone'].Contains($zone)) {
            $missing.Add("slaHoursByZone.$zone")
        }
    }

    if ($missing.Count -gt 0) {
        throw "Configuration validation failed. Missing required settings: $($missing -join ', ')"
    }

    if ($Configuration['reviewDispositionValues'].Count -lt 3) {
        throw 'Configuration validation failed. At least three review disposition values are required.'
    }

    if ([string]::IsNullOrWhiteSpace([string]$Configuration['dataverseEnvironmentUrl'])) {
        throw 'Configuration validation failed. Dataverse environment URL is required.'
    }

    $uri = $null
    if (-not [System.Uri]::TryCreate([string]$Configuration['dataverseEnvironmentUrl'], [System.UriKind]::Absolute, [ref]$uri)) {
        throw "Configuration validation failed. Invalid Dataverse environment URL: $($Configuration['dataverseEnvironmentUrl'])"
    }
}

function Test-PowerShellSyntax {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]]$Paths
    )

    $results = foreach ($path in $Paths) {
        $tokens = $null
        $errors = $null
        $null = [System.Management.Automation.Language.Parser]::ParseFile($path, [ref]$tokens, [ref]$errors)

        [pscustomobject]@{
            path = $path
            isValid = ($errors.Count -eq 0)
            errors = @($errors | ForEach-Object { $_.Message })
        }
    }

    return $results
}

$solutionRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$configuration = Get-EffectiveConfiguration -SolutionRoot $solutionRoot -Tier $ConfigurationTier -OverrideEnvironmentUrl $EnvironmentUrl
Test-RequiredConfiguration -Configuration $configuration

$scriptPaths = @(
    (Join-Path $PSScriptRoot 'Deploy-Solution.ps1'),
    (Join-Path $PSScriptRoot 'Monitor-Compliance.ps1'),
    (Join-Path $PSScriptRoot 'Export-Evidence.ps1')
)

$syntaxValidation = Test-PowerShellSyntax -Paths $scriptPaths
$syntaxErrors = @($syntaxValidation | Where-Object { -not $_.isValid })
if ($syntaxErrors.Count -gt 0) {
    $invalidPaths = $syntaxErrors | ForEach-Object { $_.path }
    throw "PowerShell syntax validation failed for: $($invalidPaths -join ', ')"
}

if ($configuration['purviewPolicyId'] -eq '00000000-0000-0000-0000-000000000000') {
    Write-Warning 'The Purview policy ID is still the placeholder value. Update fsi_ev_fsw_purviewpolicyid before production use.'
}

if ($configuration['dataverseEnvironmentUrl'] -like 'https://contoso.crm.dynamics.com') {
    Write-Warning 'The Dataverse environment URL is still the placeholder value. Update fsi_ev_fsw_environmenturl before production use.'
}

$connectionReferenceStubs = [ordered]@{
    solution = $configuration['solution']['slug']
    solutionCode = $configuration['solution']['code']
    tier = $ConfigurationTier
    connectionReferences = @(
        [ordered]@{
            name = 'fsi_cr_fsw_purview'
            service = 'purview-communication-compliance'
            required = $true
            status = 'manual-create'
            purpose = 'Used by the Ingest Flagged Items flow to retrieve flagged Copilot communications.'
        },
        [ordered]@{
            name = 'fsi_cr_fsw_dataverse'
            service = 'dataverse'
            required = $true
            status = 'manual-create'
            purpose = 'Used by all supervision flows to create, update, and query queue and log rows.'
        }
    )
}

$environmentVariableStubs = [ordered]@{
    solution = $configuration['solution']['slug']
    solutionCode = $configuration['solution']['code']
    tier = $ConfigurationTier
    environmentVariables = @(
        [ordered]@{
            name = 'fsi_ev_fsw_purviewpolicyid'
            value = $configuration['purviewPolicyId']
            required = $true
            purpose = 'Stores the Purview Communication Compliance policy identifier.'
        },
        [ordered]@{
            name = 'fsi_ev_fsw_environmenturl'
            value = $configuration['dataverseEnvironmentUrl']
            required = $true
            purpose = 'Stores the Power Platform Dataverse environment URL.'
        },
        [ordered]@{
            name = 'fsi_ev_fsw_escalationenabled'
            value = [string]$configuration['escalationEnabled']
            required = $true
            purpose = 'Enables or disables the Escalation Flow.'
        },
        [ordered]@{
            name = 'fsi_ev_fsw_defaulttier'
            value = $ConfigurationTier
            required = $true
            purpose = 'Identifies the active governance tier for deployment validation.'
        }
    )
}

$manifest = [ordered]@{
    solution = $configuration['solution']
    generatedAt = (Get-Date).ToString('o')
    deploymentTier = $ConfigurationTier
    deploymentStatus = 'implemented'
    manualDeployment = $true
    documentation = 'docs\deployment-guide.md'
    controls = $configuration['controls']
    regulations = $configuration['regulations']
    evidenceOutputs = $configuration['evidenceOutputs']
    supportedZones = $configuration['supportedZones']
    samplingRates = $configuration['samplingRates']
    slaHoursByZone = $configuration['slaHoursByZone']
    escalationEnabled = $configuration['escalationEnabled']
    notifications = $configuration['notifications']
    immutableLogRequired = $configuration['immutableLogRequired']
    evidenceRetentionDays = $configuration['evidenceRetentionDays']
    dataverseTables = $configuration['dataverseTables']
    powerAutomateFlows = $configuration['powerAutomateFlows']
    connectionReferencesFile = 'connection-reference-stubs.json'
    environmentVariablesFile = 'environment-variable-stubs.json'
    syntaxValidation = $syntaxValidation
}

if ($PSCmdlet.ShouldProcess($OutputPath, 'Write deployment manifest and stub files')) {
    $null = New-Item -ItemType Directory -Path $OutputPath -Force

    $manifestPath = Join-Path $OutputPath 'deployment-manifest.json'
    $connectionPath = Join-Path $OutputPath 'connection-reference-stubs.json'
    $environmentPath = Join-Path $OutputPath 'environment-variable-stubs.json'

    $manifest | ConvertTo-Json -Depth 10 | Set-Content -Path $manifestPath -Encoding utf8
    $connectionReferenceStubs | ConvertTo-Json -Depth 10 | Set-Content -Path $connectionPath -Encoding utf8
    $environmentVariableStubs | ConvertTo-Json -Depth 10 | Set-Content -Path $environmentPath -Encoding utf8

    [pscustomobject]@{
        Solution = $configuration['solution']['name']
        Tier = $ConfigurationTier
        ManifestPath = $manifestPath
        ConnectionReferencePath = $connectionPath
        EnvironmentVariablePath = $environmentPath
        SyntaxValidated = $true
    }
}

