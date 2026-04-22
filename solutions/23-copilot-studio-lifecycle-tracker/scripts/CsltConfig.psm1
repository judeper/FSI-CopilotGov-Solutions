<#
.SYNOPSIS
    Shared CSLT configuration module used by Deploy-Solution.ps1, Monitor-Compliance.ps1,
    and Export-Evidence.ps1.
#>

function Get-CsltConfiguration {
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
        solution                       = $defaultConfig.solution
        displayName                    = $defaultConfig.displayName
        solutionCode                   = $defaultConfig.solutionCode
        version                        = $defaultConfig.version
        track                          = $defaultConfig.track
        priority                       = $defaultConfig.priority
        primaryControls                = $defaultConfig.primaryControls
        supportingControls             = $defaultConfig.supportingControls
        regulations                    = $defaultConfig.regulations
        framework_ids                  = $defaultConfig.framework_ids
        evidenceOutputs                = $defaultConfig.evidenceOutputs
        defaults                       = $defaultConfig.defaults
        tier                           = $tierConfig.tier
        controls                       = $tierConfig.controls
        publishingApprovalRequired     = $tierConfig.publishingApprovalRequired
        dualApproverRequired           = $tierConfig.dualApproverRequired
        versioningRetentionDays        = $tierConfig.versioningRetentionDays
        deprecationNoticeDays          = $tierConfig.deprecationNoticeDays
        lifecycleReviewCadenceDays     = $tierConfig.lifecycleReviewCadenceDays
        inventoryPollingIntervalHours  = $tierConfig.inventoryPollingIntervalHours
        evidenceRetentionDays          = $tierConfig.evidenceRetentionDays
        notificationMode               = $tierConfig.notificationMode
        publishingApprovalLog          = $tierConfig.publishingApprovalLog
        deprecationEvidence            = $tierConfig.deprecationEvidence
        lifecycleReview                = if ($tierConfig.Contains('lifecycleReview')) { $tierConfig.lifecycleReview } else { $null }
        evidenceImmutability           = if ($tierConfig.Contains('evidenceImmutability')) { $tierConfig.evidenceImmutability } else { $null }
    }
}

function Test-CsltConfiguration {
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
        'publishingApprovalRequired',
        'versioningRetentionDays',
        'deprecationNoticeDays',
        'lifecycleReviewCadenceDays',
        'inventoryPollingIntervalHours',
        'evidenceRetentionDays',
        'notificationMode',
        'publishingApprovalLog',
        'deprecationEvidence'
    )

    $missingFields = @()
    foreach ($field in $requiredFields) {
        if (-not $Configuration.Contains($field) -or $null -eq $Configuration[$field]) {
            $missingFields += $field
        }
    }

    if ($missingFields.Count -gt 0) {
        throw "CSLT configuration is missing required fields: $($missingFields -join ', ')"
    }

    if ($Configuration.tier -eq 'regulated' -and -not $Configuration.dualApproverRequired) {
        throw 'CSLT regulated tier requires dualApproverRequired to be true.'
    }
}

Export-ModuleMember -Function Get-CsltConfiguration, Test-CsltConfiguration
