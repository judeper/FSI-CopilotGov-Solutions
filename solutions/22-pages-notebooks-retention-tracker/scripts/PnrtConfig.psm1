<#
.SYNOPSIS
    Shared PNRT configuration module used by Deploy-Solution.ps1, Monitor-Compliance.ps1,
    and Export-Evidence.ps1.
#>

function Get-PnrtConfiguration {
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
        solution                  = $defaultConfig.solution
        displayName               = $defaultConfig.displayName
        solutionCode              = $defaultConfig.solutionCode
        version                   = $defaultConfig.version
        track                     = $defaultConfig.track
        priority                  = $defaultConfig.priority
        regulations               = $defaultConfig.regulations
        framework_ids             = $defaultConfig.framework_ids
        primaryControls           = $defaultConfig.primaryControls
        supportingControls        = $defaultConfig.supportingControls
        defaults                  = $defaultConfig.defaults
        evidenceOutputs           = $defaultConfig.evidenceOutputs
        tier                      = $tierConfig.tier
        controls                  = $tierConfig.controls
        evidenceRetentionDays     = $tierConfig.evidenceRetentionDays
        pagesRetentionDays        = $tierConfig.pagesRetentionDays
        notebookRetentionDays     = $tierConfig.notebookRetentionDays
        branchingAuditMode        = $tierConfig.branchingAuditMode
        branchingAuditRequired    = $tierConfig.branchingAuditRequired
        loopProvenanceRequired    = $tierConfig.loopProvenanceRequired
        preservationLockRequired  = $tierConfig.preservationLockRequired
        signedLineageRequired     = $tierConfig.signedLineageRequired
        retentionLabelCoverage    = $tierConfig.retentionLabelCoverage
        powerAutomateFlow         = $tierConfig.powerAutomateFlow
        wormStorage               = if ($tierConfig.Contains('wormStorage')) { $tierConfig.wormStorage } else { $null }
        supervisoryReview         = if ($tierConfig.Contains('supervisoryReview')) { $tierConfig.supervisoryReview } else { $null }
    }
}

function Test-PnrtPositiveIntegerField {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Configuration,

        [Parameter(Mandatory)]
        [string]$FieldName
    )

    $parsedValue = 0
    if (-not [int]::TryParse([string]$Configuration[$FieldName], [ref]$parsedValue) -or $parsedValue -le 0) {
        throw "PNRT configuration field [$FieldName] must be a positive integer greater than zero."
    }
}

function Test-PnrtPercentageField {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Configuration,

        [Parameter(Mandatory)]
        [string]$SectionName,

        [Parameter(Mandatory)]
        [string]$FieldName
    )

    if (-not $Configuration.Contains($SectionName) -or $Configuration[$SectionName] -isnot [System.Collections.IDictionary]) {
        throw "PNRT configuration section [$SectionName] must be present for percentage validation."
    }

    $section = $Configuration[$SectionName]
    if (-not $section.Contains($FieldName) -or $null -eq $section[$FieldName]) {
        throw "PNRT configuration field [$SectionName.$FieldName] must be present for percentage validation."
    }

    $parsedValue = 0
    if (-not [int]::TryParse([string]$section[$FieldName], [ref]$parsedValue) -or $parsedValue -le 0 -or $parsedValue -gt 100) {
        throw "PNRT configuration field [$SectionName.$FieldName] must be an integer percentage from 1 through 100."
    }
}

function Test-PnrtConfiguration {
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
        'pagesRetentionDays',
        'notebookRetentionDays',
        'branchingAuditMode',
        'branchingAuditRequired',
        'retentionLabelCoverage',
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
        throw "PNRT configuration is missing required fields: $($missingFields -join ', ')"
    }

    if (-not $Configuration.defaults.Contains('monitoredArtifactTypes') -or @($Configuration.defaults.monitoredArtifactTypes).Count -lt 3) {
        throw 'PNRT configuration must define at least three monitored artifact types.'
    }

    foreach ($numericField in @('evidenceRetentionDays', 'pagesRetentionDays', 'notebookRetentionDays')) {
        Test-PnrtPositiveIntegerField -Configuration $Configuration -FieldName $numericField
    }

    Test-PnrtPercentageField -Configuration $Configuration -SectionName 'retentionLabelCoverage' -FieldName 'minimumCoveragePct'

    if ($Configuration['branchingAuditRequired'] -isnot [bool]) {
        throw 'PNRT configuration field [branchingAuditRequired] must be a Boolean value.'
    }
}

Export-ModuleMember -Function Get-PnrtConfiguration, Test-PnrtConfiguration
