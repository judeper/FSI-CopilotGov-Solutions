<#
.SYNOPSIS
    Shared DRM configuration module used by Deploy-Solution.ps1, Monitor-Compliance.ps1,
    and Export-Evidence.ps1 to eliminate duplicated Get-DrmConfiguration and
    Test-DrmConfiguration logic.
#>

function Get-DrmConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('baseline', 'recommended', 'regulated')]
        [string]$Tier
    )

    $configRoot = Join-Path $PSScriptRoot '..\config'
    $defaultConfigPath = Join-Path $configRoot 'default-config.json'
    $tierConfigPath = Join-Path $configRoot ("{0}.json" -f $Tier)

    foreach ($pathToCheck in @($defaultConfigPath, $tierConfigPath)) {
        if (-not (Test-Path -Path $pathToCheck)) {
            throw "Configuration file not found: $pathToCheck"
        }
    }

    $defaultConfig = Get-Content -Path $defaultConfigPath -Raw | ConvertFrom-Json -AsHashtable
    $tierConfig = Get-Content -Path $tierConfigPath -Raw | ConvertFrom-Json -AsHashtable

    return [ordered]@{
        solution                             = $defaultConfig.solution
        displayName                          = $defaultConfig.displayName
        solutionCode                         = $defaultConfig.solutionCode
        version                              = $defaultConfig.version
        track                                = $defaultConfig.track
        priority                             = $defaultConfig.priority
        regulations                          = $defaultConfig.regulations
        defaults                             = $defaultConfig.defaults
        evidenceOutputs                      = $defaultConfig.evidenceOutputs
        tier                                 = $tierConfig.tier
        controls                             = $tierConfig.controls
        evidenceRetentionDays                = $tierConfig.evidenceRetentionDays
        notificationMode                     = $tierConfig.notificationMode
        serviceHealthPollingIntervalMinutes  = $tierConfig.serviceHealthPollingIntervalMinutes
        incidentClassification               = $tierConfig.incidentClassification
        resilienceTestTracking               = $tierConfig.resilienceTestTracking
        sentinelIntegration                  = $tierConfig.sentinelIntegration
        powerAutomateFlow                    = $tierConfig.powerAutomateFlow
        dataResidency                        = if ($tierConfig.Contains('dataResidency')) { $tierConfig.dataResidency } else { $null }
        evidenceImmutability                 = if ($tierConfig.Contains('evidenceImmutability')) { $tierConfig.evidenceImmutability } else { $null }
    }
}

function Test-DrmConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Configuration,

        [Parameter()]
        [string[]]$AdditionalRequiredFields
    )

    $requiredFields = @(
        'solution',
        'displayName',
        'solutionCode',
        'version',
        'defaults',
        'tier',
        'controls',
        'evidenceRetentionDays',
        'notificationMode',
        'serviceHealthPollingIntervalMinutes',
        'incidentClassification',
        'resilienceTestTracking',
        'sentinelIntegration',
        'powerAutomateFlow'
    )

    if ($AdditionalRequiredFields) {
        $requiredFields += $AdditionalRequiredFields
    }

    $missingFields = @()
    foreach ($field in $requiredFields) {
        if (-not $Configuration.Contains($field) -or $null -eq $Configuration[$field]) {
            $missingFields += $field
            continue
        }

        if ($Configuration[$field] -is [string] -and [string]::IsNullOrWhiteSpace([string]$Configuration[$field])) {
            $missingFields += $field
        }
    }

    if ($missingFields.Count -gt 0) {
        throw "DRM configuration is missing required fields: $($missingFields -join ', ')"
    }

    if (-not $Configuration.defaults.Contains('monitoredServices') -or @($Configuration.defaults.monitoredServices).Count -lt 5) {
        throw 'DRM configuration must define at least five monitored services.'
    }

    if (-not $Configuration.incidentClassification.Contains('severityThresholds')) {
        throw 'DRM configuration must include incident severity thresholds.'
    }
}

Export-ModuleMember -Function Get-DrmConfiguration, Test-DrmConfiguration
