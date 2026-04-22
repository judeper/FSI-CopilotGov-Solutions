<#
.SYNOPSIS
    Shared GMG configuration module used by Deploy-Solution.ps1, Monitor-Compliance.ps1,
    and Export-Evidence.ps1.

.DESCRIPTION
    Documentation-first module. Loads default-config.json plus the selected tier file
    and validates required fields. Does not connect to live services.
#>

function Get-GmgConfiguration {
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
        solution                            = $defaultConfig.solution
        displayName                         = $defaultConfig.displayName
        solutionCode                        = $defaultConfig.solutionCode
        version                             = $defaultConfig.version
        track                               = $defaultConfig.track
        priority                            = $defaultConfig.priority
        phase                               = $defaultConfig.phase
        primaryControls                     = $defaultConfig.primaryControls
        supportingControls                  = $defaultConfig.supportingControls
        regulations                         = $defaultConfig.regulations
        framework_ids                       = $defaultConfig.framework_ids
        evidenceOutputs                     = $defaultConfig.evidenceOutputs
        defaults                            = $defaultConfig.defaults
        tier                                = $tierConfig.tier
        controls                            = $tierConfig.controls
        model_inventory_review_cadence_days = $tierConfig.model_inventory_review_cadence_days
        monitoring_log_retention_days       = $tierConfig.monitoring_log_retention_days
        validation_assessment_required      = $tierConfig.validation_assessment_required
        third_party_review_cadence_days     = $tierConfig.third_party_review_cadence_days
        ongoingMonitoring                   = $tierConfig.ongoingMonitoring
        independentChallenge                = $tierConfig.independentChallenge
        evidenceRetentionDays               = $tierConfig.evidenceRetentionDays
        notificationMode                    = $tierConfig.notificationMode
        modelRiskCommittee                  = if ($tierConfig.Contains('modelRiskCommittee')) { $tierConfig.modelRiskCommittee } else { $null }
        evidenceImmutability                = if ($tierConfig.Contains('evidenceImmutability')) { $tierConfig.evidenceImmutability } else { $null }
    }
}

function Test-GmgConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Configuration
    )

    $requiredFields = @(
        'solution',
        'displayName',
        'solutionCode',
        'version',
        'tier',
        'controls',
        'model_inventory_review_cadence_days',
        'monitoring_log_retention_days',
        'validation_assessment_required',
        'third_party_review_cadence_days',
        'ongoingMonitoring',
        'evidenceRetentionDays',
        'notificationMode'
    )

    $missingFields = @()
    foreach ($field in $requiredFields) {
        if (-not $Configuration.Contains($field) -or $null -eq $Configuration[$field]) {
            $missingFields += $field
        }
    }

    if ($missingFields.Count -gt 0) {
        throw "GMG configuration is missing required fields: $($missingFields -join ', ')"
    }
}

function Write-GmgSha256File {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    $hash = (Get-FileHash -Path $Path -Algorithm SHA256).Hash.ToLowerInvariant()
    $sidecarPath = "$Path.sha256"
    "$hash  $(Split-Path -Leaf $Path)" | Set-Content -Path $sidecarPath -Encoding utf8
    return [pscustomobject]@{ Path = $Path; Hash = $hash; SidecarPath = $sidecarPath }
}

Export-ModuleMember -Function Get-GmgConfiguration, Test-GmgConfiguration, Write-GmgSha256File
