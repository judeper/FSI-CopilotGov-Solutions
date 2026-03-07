<#
.SYNOPSIS
Produces oversharing findings for SharePoint, OneDrive, and Teams.

.DESCRIPTION
Loads the selected solution configuration, gathers workload candidates from
implementation stubs, applies FSI-weighted risk classification, optionally
exports the findings and summary, and returns an array of normalized findings.

.PARAMETER ConfigurationTier
Selects the governance tier to apply. Supported values are baseline,
recommended, and regulated.

.PARAMETER TenantId
Tenant GUID used to label the monitoring run.

.PARAMETER MaxSites
Optional cap for the number of findings returned. Use -1 for no cap.

.PARAMETER WorkloadsToScan
Optional list of workloads to scan. When omitted, the value is taken from the
selected configuration tier.

.PARAMETER ExportPath
Optional directory used to write `monitor-findings.json` and
`monitor-summary.json`.

.EXAMPLE
.\Monitor-Compliance.ps1 -ConfigurationTier recommended -TenantId 00000000-0000-0000-0000-000000000000 -WorkloadsToScan sharePoint -MaxSites 100

.EXAMPLE
.\Monitor-Compliance.ps1 -ConfigurationTier regulated -TenantId 00000000-0000-0000-0000-000000000000 -ExportPath .\artifacts\monitor
#>
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet('baseline', 'recommended', 'regulated')]
    [string]$ConfigurationTier = 'baseline',

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$TenantId,

    [Parameter()]
    [int]$MaxSites = -1,

    [Parameter()]
    [ValidateSet('sharePoint', 'oneDrive', 'teams')]
    [string[]]$WorkloadsToScan,

    [Parameter()]
    [string]$ExportPath
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
    $defaultConfig = ConvertTo-Hashtable -InputObject ((Get-Content -Path (Join-Path $configRoot 'default-config.json') -Raw) | ConvertFrom-Json)
    $tierConfig = ConvertTo-Hashtable -InputObject ((Get-Content -Path (Join-Path $configRoot ("{0}.json" -f $ConfigurationTier)) -Raw) | ConvertFrom-Json)

    return (Merge-Hashtable -Base $defaultConfig -Override $tierConfig)
}

function Get-SharePointOversharingSites {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$TenantId
    )

    return @(
        [pscustomobject]@{
            SiteUrl = 'https://contoso.sharepoint.com/sites/CommercialLending'
            WorkloadType = 'sharePoint'
            SharingScope = 'Anonymous'
            DetectedSignals = @('customerPII', 'regulatedRecords')
            PermissionAnomalyCount = 18
            ExposureType = 'Anyone link exposes regulated lending records'
            Owner = 'commerciallendingowners@contoso.com'
            TenantId = $TenantId
        }
        [pscustomobject]@{
            SiteUrl = 'https://contoso.sharepoint.com/sites/TradingResearch'
            WorkloadType = 'sharePoint'
            SharingScope = 'AllEmployees'
            DetectedSignals = @('tradingData', 'legalDocs')
            PermissionAnomalyCount = 11
            ExposureType = 'All employee access to trading research workspace'
            Owner = 'tradingresearchowners@contoso.com'
            TenantId = $TenantId
        }
        [pscustomobject]@{
            SiteUrl = 'https://contoso.sharepoint.com/sites/PolicyOperations'
            WorkloadType = 'sharePoint'
            SharingScope = 'BroadInternal'
            DetectedSignals = @('legalDocs')
            PermissionAnomalyCount = 4
            ExposureType = 'Broad internal access to policy and exam response drafts'
            Owner = 'policyoperations@contoso.com'
            TenantId = $TenantId
        }
    )
}

function Get-OneDriveOversharingItems {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$TenantId
    )

    return @(
        [pscustomobject]@{
            SiteUrl = 'https://contoso-my.sharepoint.com/personal/rmiller'
            WorkloadType = 'oneDrive'
            SharingScope = 'Guest'
            DetectedSignals = @('customerPII')
            PermissionAnomalyCount = 9
            ExposureType = 'Externally shared client review package in OneDrive'
            Owner = 'rmiller@contoso.com'
            TenantId = $TenantId
        }
        [pscustomobject]@{
            SiteUrl = 'https://contoso-my.sharepoint.com/personal/litigationops'
            WorkloadType = 'oneDrive'
            SharingScope = 'BroadInternal'
            DetectedSignals = @('legalDocs')
            PermissionAnomalyCount = 3
            ExposureType = 'Broad internal share from legal operations OneDrive'
            Owner = 'litigationops@contoso.com'
            TenantId = $TenantId
        }
    )
}

function Get-TeamsOversharingChannels {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$TenantId
    )

    return @(
        [pscustomobject]@{
            SiteUrl = 'https://contoso.sharepoint.com/sites/WealthAdvisoryTeam'
            WorkloadType = 'teams'
            SharingScope = 'Guest'
            DetectedSignals = @('customerPII', 'legalDocs')
            PermissionAnomalyCount = 7
            ExposureType = 'Guest-enabled advisory team channel contains client and legal material'
            Owner = 'wealthadvisoryowners@contoso.com'
            TenantId = $TenantId
        }
        [pscustomobject]@{
            SiteUrl = 'https://contoso.sharepoint.com/sites/InternalControlsTeam'
            WorkloadType = 'teams'
            SharingScope = 'Targeted'
            DetectedSignals = @('regulatedRecords')
            PermissionAnomalyCount = 2
            ExposureType = 'Targeted channel with limited but regulated records exposure'
            Owner = 'internalcontrolsteam@contoso.com'
            TenantId = $TenantId
        }
    )
}

function Get-SharingScopeWeight {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$SharingScope,

        [Parameter(Mandatory)]
        [hashtable]$Configuration
    )

    switch ($SharingScope) {
        'Anonymous' { return [int]$Configuration.sharingScopeWeights.anonymous }
        'Guest' { return [int]$Configuration.sharingScopeWeights.guest }
        'AllEmployees' { return [int]$Configuration.sharingScopeWeights.allEmployees }
        'BroadInternal' { return [int]$Configuration.sharingScopeWeights.broadInternal }
        default { return [int]$Configuration.sharingScopeWeights.targeted }
    }
}

function Invoke-RiskClassification {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object[]]$Candidates,

        [Parameter(Mandatory)]
        [hashtable]$Configuration,

        [Parameter(Mandatory)]
        [ValidateSet('DetectOnly', 'Notify', 'AutoRemediate')]
        [string]$RemediationMode
    )

    $thresholds = $Configuration.riskThresholds
    $classifiers = $Configuration.fsiFsiDataClassifiers

    foreach ($candidate in $Candidates) {
        $score = Get-SharingScopeWeight -SharingScope $candidate.SharingScope -Configuration $Configuration

        foreach ($signal in $candidate.DetectedSignals) {
            if ($classifiers.ContainsKey($signal)) {
                $score += [int]$classifiers[$signal].weight
            }
        }

        if ($candidate.PermissionAnomalyCount -ge 10) {
            $score += 20
        }
        elseif ($candidate.PermissionAnomalyCount -ge 5) {
            $score += 10
        }
        elseif ($candidate.PermissionAnomalyCount -gt 0) {
            $score += 5
        }

        if (($candidate.WorkloadType -eq 'teams') -and ($candidate.SharingScope -eq 'Guest')) {
            $score += 5
        }

        $riskLevel = if ($score -ge [int]$thresholds.high) {
            'HIGH'
        }
        elseif ($score -ge [int]$thresholds.medium) {
            'MEDIUM'
        }
        else {
            'LOW'
        }

        $recommendedAction = switch ($riskLevel) {
            'HIGH' {
                if ($RemediationMode -eq 'AutoRemediate') {
                    'Queue immediate permission reduction, freeze guest sharing, and request owner attestation.'
                }
                else {
                    'Escalate to remediation approval and notify the business owner within one business day.'
                }
            }
            'MEDIUM' {
                'Notify the owner, review membership scope, and remove broad internal access if not justified.'
            }
            default {
                'Track for routine permission hygiene and validate the next review cycle.'
            }
        }

        [pscustomobject]@{
            SiteUrl = $candidate.SiteUrl
            WorkloadType = $candidate.WorkloadType
            RiskLevel = $riskLevel
            ExposureType = $candidate.ExposureType
            PermissionAnomalyCount = [int]$candidate.PermissionAnomalyCount
            RecommendedAction = $recommendedAction
            RiskScore = $score
            Owner = $candidate.Owner
            SharingScope = $candidate.SharingScope
            DetectedSignals = ($candidate.DetectedSignals -join ',')
        }
    }
}

$configuration = Get-Configuration -ConfigurationTier $ConfigurationTier

$effectiveWorkloads = if ($PSBoundParameters.ContainsKey('WorkloadsToScan')) {
    $WorkloadsToScan
}
else {
    [string[]]$configuration.scanWorkloads
}

$effectiveMaxSites = if ($MaxSites -lt 0) {
    [int]$configuration.maxSitesPerRun
}
else {
    $MaxSites
}

$rawCandidates = @()

foreach ($workload in $effectiveWorkloads) {
    switch ($workload) {
        'sharePoint' {
            $rawCandidates += Get-SharePointOversharingSites -TenantId $TenantId
        }
        'oneDrive' {
            $rawCandidates += Get-OneDriveOversharingItems -TenantId $TenantId
        }
        'teams' {
            $rawCandidates += Get-TeamsOversharingChannels -TenantId $TenantId
        }
    }
}

$findings = @(Invoke-RiskClassification -Candidates $rawCandidates -Configuration $configuration -RemediationMode (([string]$configuration.remediationMode).Substring(0, 1).ToUpper() + ([string]$configuration.remediationMode).Substring(1)))

if ($effectiveMaxSites -ge 0) {
    $findings = @($findings | Select-Object -First $effectiveMaxSites)
}

$summary = [pscustomobject]@{
    TenantId = $TenantId
    Tier = $ConfigurationTier
    Workloads = ($effectiveWorkloads -join ', ')
    TotalFindings = @($findings).Count
    HighRiskCount = @($findings | Where-Object { $_.RiskLevel -eq 'HIGH' }).Count
    MediumRiskCount = @($findings | Where-Object { $_.RiskLevel -eq 'MEDIUM' }).Count
    LowRiskCount = @($findings | Where-Object { $_.RiskLevel -eq 'LOW' }).Count
}

Write-Host ("Summary: Total={0}; HIGH={1}; MEDIUM={2}; LOW={3}" -f $summary.TotalFindings, $summary.HighRiskCount, $summary.MediumRiskCount, $summary.LowRiskCount)

if ($PSBoundParameters.ContainsKey('ExportPath')) {
    $exportRoot = [System.IO.Path]::GetFullPath($ExportPath)
    $null = New-Item -Path $exportRoot -ItemType Directory -Force
    $findings | ConvertTo-Json -Depth 8 | Set-Content -Path (Join-Path $exportRoot 'monitor-findings.json') -Encoding utf8
    $summary | ConvertTo-Json -Depth 5 | Set-Content -Path (Join-Path $exportRoot 'monitor-summary.json') -Encoding utf8
}

return $findings
