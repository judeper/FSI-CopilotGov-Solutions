#Requires -Version 7.0
<#
.SYNOPSIS
    Shared utility functions for the FINRA Supervision Workflow solution scripts.
.DESCRIPTION
    Contains Read-JsonFile, Get-ConfiguredEnvironmentUrl, and Get-EffectiveConfiguration
    used by Export-Evidence.ps1, Deploy-Solution.ps1, and Monitor-Compliance.ps1.
#>

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
