<#
.SYNOPSIS
Deploys the Copilot Tuning Governance solution.

.DESCRIPTION
Loads the solution default configuration plus the selected governance tier,
validates tuning governance prerequisites, and writes a deployment manifest
for auditability. Uses representative sample data and does not connect to
live Microsoft 365 services.

.PARAMETER ConfigurationTier
Selects the governance tier to apply. Supported values are baseline,
recommended, and regulated.

.PARAMETER OutputPath
Directory where the deployment manifest will be written.

.PARAMETER TenantId
Tenant GUID used to label the deployment manifest and prerequisite checks.

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

function Test-CopilotLicenseThreshold {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Configuration,

        [Parameter(Mandatory)]
        [string]$TenantId
    )

    $status = if ($env:CTG_ASSUME_LICENSE_THRESHOLD -eq '1') { 'verified' } else { 'manual-check-required' }
    $notes = if ($status -eq 'verified') {
        'CTG_ASSUME_LICENSE_THRESHOLD=1 was supplied for stub validation.'
    }
    else {
        'Validate early access preview availability, Microsoft 365 admin center visibility, and at least 5,000 Microsoft 365 Copilot licenses during public preview before expanding Copilot Tuning access.'
    }

    return [pscustomobject]@{
        Requirement = 'Copilot Tuning Preview Eligibility'
        TenantId = $TenantId
        Status = $status
        Notes = $notes
    }
}

$configuration = Get-Configuration -ConfigurationTier $ConfigurationTier
$licenseCheck = Test-CopilotLicenseThreshold -Configuration $configuration -TenantId $TenantId

$outputRoot = [System.IO.Path]::GetFullPath($OutputPath)
$manifestPath = Join-Path $outputRoot '19-copilot-tuning-governance-deployment.json'

$manifest = [ordered]@{
    solution = $configuration.solution
    solutionCode = $configuration.solutionCode
    displayName = $configuration.displayName
    version = $configuration.version
    tenantId = $TenantId
    tier = $ConfigurationTier
    exportedAt = (Get-Date).ToString('o')
    copilotLicenseCheck = $licenseCheck
    configurationSnapshot = [ordered]@{
        tuningEnabled = $configuration.tuningEnabled
        requireApprovalWorkflow = $configuration.requireApprovalWorkflow
        requireModelInventory = $configuration.requireModelInventory
        requireRiskAssessment = $configuration.requireRiskAssessment
        requireOwnerAttestation = $configuration.requireOwnerAttestation
        riskReassessmentDays = $configuration.riskReassessmentDays
        evidenceRetentionDays = $configuration.evidenceRetentionDays
        maxTuningRequestsPerCycle = $configuration.maxTuningRequestsPerCycle
    }
}

if ($PSCmdlet.ShouldProcess($outputRoot, 'Create tuning governance deployment manifest')) {
    $null = New-Item -Path $outputRoot -ItemType Directory -Force
    $manifest | ConvertTo-Json -Depth 10 | Set-Content -Path $manifestPath -Encoding utf8
}

[pscustomobject]@{
    Solution = $configuration.displayName
    Tier = $ConfigurationTier
    TenantId = $TenantId
    TuningEnabled = $configuration.tuningEnabled
    CopilotLicenseStatus = $licenseCheck.Status
    DeploymentManifestPath = $manifestPath
}
