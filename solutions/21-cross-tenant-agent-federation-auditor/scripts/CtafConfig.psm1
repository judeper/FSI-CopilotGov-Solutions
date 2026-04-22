<#
.SYNOPSIS
    Shared CTAF configuration module used by Deploy-Solution.ps1, Monitor-Compliance.ps1,
    and Export-Evidence.ps1.

.DESCRIPTION
    Loads default-config.json plus the requested tier file and validates required fields.
    Documentation-first: this module performs no live tenant calls.
#>

function Get-CtafConfiguration {
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
        solution                          = $defaultConfig.solution
        displayName                       = $defaultConfig.displayName
        solutionCode                      = $defaultConfig.solutionCode
        version                           = $defaultConfig.version
        track                             = $defaultConfig.track
        priority                          = $defaultConfig.priority
        regulations                       = $defaultConfig.regulations
        framework_ids                     = $defaultConfig.framework_ids
        defaults                          = $defaultConfig.defaults
        evidenceOutputs                   = $defaultConfig.evidenceOutputs
        tier                              = $tierConfig.tier
        primaryControls                   = $tierConfig.primaryControls
        supportingControls                = $tierConfig.supportingControls
        federationReviewCadenceDays       = $tierConfig.federationReviewCadenceDays
        mcpTrustAttestationRequired       = $tierConfig.mcpTrustAttestationRequired
        agentIdSigningRequired            = $tierConfig.agentIdSigningRequired
        agentIdKeyRotationTrackingEnabled = $tierConfig.agentIdKeyRotationTrackingEnabled
        crossTenantAuditLogRetentionDays  = $tierConfig.crossTenantAuditLogRetentionDays
        evidenceRetentionDays             = $tierConfig.evidenceRetentionDays
        notificationMode                  = $tierConfig.notificationMode
        copilotStudioPublishing           = $tierConfig.copilotStudioPublishing
        mcpAttestation                    = $tierConfig.mcpAttestation
        agentIdRotation                   = if ($tierConfig.Contains('agentIdRotation')) { $tierConfig.agentIdRotation } else { $null }
        auditAggregation                  = if ($tierConfig.Contains('auditAggregation')) { $tierConfig.auditAggregation } else { $null }
    }
}

function Test-CtafConfiguration {
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
        'primaryControls',
        'federationReviewCadenceDays',
        'evidenceRetentionDays',
        'notificationMode',
        'copilotStudioPublishing',
        'mcpAttestation'
    )

    $missingFields = @()
    foreach ($field in $requiredFields) {
        if (-not $Configuration.Contains($field) -or $null -eq $Configuration[$field]) {
            $missingFields += $field
        }
    }

    if ($missingFields.Count -gt 0) {
        throw "CTAF configuration is missing required fields: $($missingFields -join ', ')"
    }

    if (@($Configuration.primaryControls).Count -lt 1) {
        throw 'CTAF configuration must include at least one primary control.'
    }
}

function Write-CtafSha256File {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    $hash = (Get-FileHash -Path $Path -Algorithm SHA256).Hash.ToLowerInvariant()
    $sidecar = "$Path.sha256"
    "$hash  $(Split-Path -Leaf $Path)" | Set-Content -Path $sidecar -Encoding utf8
    return [pscustomobject]@{
        Path = $Path
        Sidecar = $sidecar
        Hash = $hash
    }
}

Export-ModuleMember -Function Get-CtafConfiguration, Test-CtafConfiguration, Write-CtafSha256File
