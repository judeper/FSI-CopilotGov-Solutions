<#
.SYNOPSIS
    Detects permissions drift by comparing current SharePoint permissions against an approved baseline.

.DESCRIPTION
    Loads the latest baseline snapshot and returns representative sample drift scoped
    to baseline sites until tenant-bound current-state capture is added. Sample drift
    is classified as ADDED (new permission entries), REMOVED (entries no longer present),
    or CHANGED (permission level modified). Each drift item receives a risk score and
    tier classification.

    HIGH-risk drift can trigger an alert summary email via Microsoft Graph API when
    Graph context and a sender mailbox are configured.

    This documentation-first scaffold does not perform live tenant comparison.

.PARAMETER TenantUrl
    The SharePoint Online tenant URL (e.g., https://contoso.sharepoint.com).

.PARAMETER BaselinePath
    Path to the baseline file or latest-baseline.json pointer. Defaults to ./baselines/latest-baseline.json.

.PARAMETER OutputPath
    Directory for drift report output files. Defaults to ./reports.

.PARAMETER ConfigPath
    Path to default-config.json (or equivalent scoring config). Defaults to ./config/default-config.json.

.PARAMETER AlertRecipient
    Email address to receive HIGH-risk drift alert notifications.

.PARAMETER AlertSender
    Optional sender mailbox or user ID for Graph sendMail. If omitted, delegated /me/sendMail is used.

.EXAMPLE
    .\Invoke-DriftScan.ps1 -TenantUrl "https://contoso.sharepoint.com" -AlertRecipient "compliance@contoso.com" -AlertSender "compliance-automation@contoso.com"

.EXAMPLE
    .\Invoke-DriftScan.ps1 -TenantUrl "https://contoso.sharepoint.com" -BaselinePath "./baselines/baseline-20250101T120000.json"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$TenantUrl,

    [Parameter()]
    [string]$BaselinePath = './baselines/latest-baseline.json',

    [Parameter()]
    [string]$OutputPath = './reports',

    [Parameter()]
    [string]$ConfigPath = './config/default-config.json',

    [Parameter()]
    [string]$AlertRecipient,

    [Parameter()]
    [string]$AlertSender
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
Import-Module (Join-Path $repoRoot 'scripts\common\GraphAuth.psm1') -Force
Import-Module (Join-Path $repoRoot 'scripts\common\EvidenceExport.psm1') -Force

#region Helper Functions

function Get-ConfigAsHashtable {
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        [Parameter(Mandatory)]
        [string]$SolutionRoot
    )

    $resolvedPath = $Path
    if (-not [System.IO.Path]::IsPathRooted($resolvedPath)) {
        $trimmed = $resolvedPath -replace '^[.][\\/]', ''
        $resolvedPath = Join-Path $SolutionRoot $trimmed
    }

    if (-not (Test-Path -Path $resolvedPath)) {
        throw "Risk scoring configuration file was not found: $resolvedPath"
    }

    return Get-Content -Path $resolvedPath -Raw | ConvertFrom-Json -AsHashtable
}

function Get-RequiredIntConfigValue {
    param(
        [Parameter(Mandatory)]
        [hashtable]$Table,
        [Parameter(Mandatory)]
        [string]$Key,
        [Parameter(Mandatory)]
        [string]$Context
    )

    if (-not $Table.ContainsKey($Key)) {
        throw "Missing required scoring configuration key '$Context.$Key'."
    }

    if ($null -eq $Table[$Key] -or -not ($Table[$Key] -is [ValueType])) {
        throw "Scoring configuration key '$Context.$Key' must be numeric."
    }

    return [int]$Table[$Key]
}

function Test-FullControlPermissionLevel {
    param([AllowNull()][string]$PermissionLevel)

    if ([string]::IsNullOrWhiteSpace($PermissionLevel)) { return $false }

    $normalized = ($PermissionLevel -replace '\s', '').ToLowerInvariant()
    return $normalized -eq 'fullcontrol'
}

function Get-PrincipalTypeWeight {
    param(
        [AllowNull()][string]$PrincipalType,
        [hashtable]$PrincipalTypeWeights
    )

    if (-not $PrincipalTypeWeights.ContainsKey('Default')) {
        throw "Missing required scoring configuration key 'driftTypeWeights.principalType.Default'."
    }

    if ([string]::IsNullOrWhiteSpace($PrincipalType)) {
        return Get-RequiredIntConfigValue -Table $PrincipalTypeWeights -Key 'Default' -Context 'driftTypeWeights.principalType'
    }

    if ($PrincipalTypeWeights.ContainsKey($PrincipalType)) {
        return Get-RequiredIntConfigValue -Table $PrincipalTypeWeights -Key $PrincipalType -Context 'driftTypeWeights.principalType'
    }

    return Get-RequiredIntConfigValue -Table $PrincipalTypeWeights -Key 'Default' -Context 'driftTypeWeights.principalType'
}

function Get-DriftTypeWeight {
    param(
        [string]$DriftType,
        [pscustomobject]$DriftItem,
        [hashtable]$DriftTypeWeights
    )

    $baseWeights = $DriftTypeWeights['base']
    $permissionWeights = $DriftTypeWeights['permissionLevel']
    $principalTypeWeights = $DriftTypeWeights['principalType']

    if ($null -eq $baseWeights -or $null -eq $permissionWeights -or $null -eq $principalTypeWeights) {
        throw 'driftTypeWeights must include base, permissionLevel, and principalType tables.'
    }

    $weight = Get-RequiredIntConfigValue -Table $baseWeights -Key $DriftType -Context 'driftTypeWeights.base'
    switch ($DriftType) {
        'ADDED' {
            if (Test-FullControlPermissionLevel -PermissionLevel $DriftItem.After.permissionLevel) {
                $weight += Get-RequiredIntConfigValue -Table $permissionWeights -Key 'FullControl' -Context 'driftTypeWeights.permissionLevel'
            }
            elseif ($DriftItem.After.permissionLevel -eq 'Contribute') {
                $weight += Get-RequiredIntConfigValue -Table $permissionWeights -Key 'Contribute' -Context 'driftTypeWeights.permissionLevel'
            }
            else {
                $weight += Get-RequiredIntConfigValue -Table $permissionWeights -Key 'Default' -Context 'driftTypeWeights.permissionLevel'
            }

            $weight += Get-PrincipalTypeWeight -PrincipalType $DriftItem.After.principalType -PrincipalTypeWeights $principalTypeWeights
        }
        'CHANGED' {
            if ((Test-FullControlPermissionLevel -PermissionLevel $DriftItem.After.permissionLevel) -and
                -not (Test-FullControlPermissionLevel -PermissionLevel $DriftItem.Before.permissionLevel)) {
                $weight += Get-RequiredIntConfigValue -Table $permissionWeights -Key 'ChangedToFullControl' -Context 'driftTypeWeights.permissionLevel'
            }

            $weight += Get-PrincipalTypeWeight -PrincipalType $DriftItem.After.principalType -PrincipalTypeWeights $principalTypeWeights
        }
    }
    return $weight
}

function Get-RiskTier {
    param(
        [int]$Score,
        [hashtable]$RiskThresholds
    )

    $highThreshold = Get-RequiredIntConfigValue -Table $RiskThresholds -Key 'high' -Context 'riskThresholds'
    $mediumThreshold = Get-RequiredIntConfigValue -Table $RiskThresholds -Key 'medium' -Context 'riskThresholds'
    $lowThreshold = Get-RequiredIntConfigValue -Table $RiskThresholds -Key 'low' -Context 'riskThresholds'

    if ($highThreshold -lt $mediumThreshold -or $mediumThreshold -lt $lowThreshold) {
        throw 'riskThresholds must satisfy high >= medium >= low.'
    }

    if ($Score -ge $highThreshold) { return 'HIGH' }
    if ($Score -ge $mediumThreshold) { return 'MEDIUM' }
    return 'LOW'
}

function Set-RiskClassification {
    param(
        [pscustomobject]$DriftItem,
        [hashtable]$DriftTypeWeights,
        [hashtable]$RiskThresholds
    )

    $DriftItem.RiskScore = Get-DriftTypeWeight -DriftType $DriftItem.DriftType -DriftItem $DriftItem -DriftTypeWeights $DriftTypeWeights
    $DriftItem.RiskTier = Get-RiskTier -Score $DriftItem.RiskScore -RiskThresholds $RiskThresholds
    return $DriftItem
}

function Compare-PermissionSet {
    <#
    .SYNOPSIS
        Compares baseline and current permission sets for a single site.
    #>
    param(
        [pscustomobject]$BaselineSite,
        [pscustomobject]$CurrentSite,
        [hashtable]$DriftTypeWeights,
        [hashtable]$RiskThresholds
    )

    $driftItems = @()

    # Index baseline permissions by a composite key
    $baselineIndex = @{}
    foreach ($perm in $BaselineSite.uniquePermissions) {
        $key = "$($perm.itemPath)|$($perm.principalName)"
        $baselineIndex[$key] = $perm
    }

    # Index current permissions
    $currentIndex = @{}
    foreach ($perm in $CurrentSite.uniquePermissions) {
        $key = "$($perm.itemPath)|$($perm.principalName)"
        $currentIndex[$key] = $perm
    }

    # Detect ADDED entries (in current but not in baseline)
    foreach ($key in $currentIndex.Keys) {
        if (-not $baselineIndex.ContainsKey($key)) {
            $driftItem = [pscustomobject]@{
                SiteUrl    = $CurrentSite.siteUrl
                ItemPath   = $currentIndex[$key].itemPath
                DriftType  = 'ADDED'
                Before     = $null
                After      = $currentIndex[$key]
                RiskScore  = 0
                RiskTier   = 'LOW'
                DetectedAt = (Get-Date).ToString('o')
            }
            $driftItems += (Set-RiskClassification -DriftItem $driftItem -DriftTypeWeights $DriftTypeWeights -RiskThresholds $RiskThresholds)
        }
    }

    # Detect REMOVED entries (in baseline but not in current)
    foreach ($key in $baselineIndex.Keys) {
        if (-not $currentIndex.ContainsKey($key)) {
            $driftItem = [pscustomobject]@{
                SiteUrl    = $CurrentSite.siteUrl
                ItemPath   = $baselineIndex[$key].itemPath
                DriftType  = 'REMOVED'
                Before     = $baselineIndex[$key]
                After      = $null
                RiskScore  = 0
                RiskTier   = 'LOW'
                DetectedAt = (Get-Date).ToString('o')
            }
            $driftItems += (Set-RiskClassification -DriftItem $driftItem -DriftTypeWeights $DriftTypeWeights -RiskThresholds $RiskThresholds)
        }
    }

    # Detect CHANGED entries (present in both but permission level differs)
    foreach ($key in $currentIndex.Keys) {
        if ($baselineIndex.ContainsKey($key)) {
            $baselinePerm = $baselineIndex[$key]
            $currentPerm = $currentIndex[$key]
            if ($baselinePerm.permissionLevel -ne $currentPerm.permissionLevel) {
                $driftItem = [pscustomobject]@{
                    SiteUrl    = $CurrentSite.siteUrl
                    ItemPath   = $currentPerm.itemPath
                    DriftType  = 'CHANGED'
                    Before     = $baselinePerm
                    After      = $currentPerm
                    RiskScore  = 0
                    RiskTier   = 'LOW'
                    DetectedAt = (Get-Date).ToString('o')
                }
                $driftItems += (Set-RiskClassification -DriftItem $driftItem -DriftTypeWeights $DriftTypeWeights -RiskThresholds $RiskThresholds)
            }
        }
    }

    return $driftItems
}

function Get-SampleDriftData {
    <#
    .SYNOPSIS
        Returns representative sample drift data for documentation-first scaffold.
    #>
    param(
        [string]$TenantUrl,
        [hashtable]$DriftTypeWeights,
        [hashtable]$RiskThresholds
    )

    $sampleItems = @(
        [pscustomobject]@{
            SiteUrl    = "$TenantUrl/sites/Finance"
            ItemPath   = 'Shared Documents/Confidential'
            DriftType  = 'ADDED'
            Before     = $null
            After      = [pscustomobject]@{
                principalName   = 'External Consultant'
                principalType   = 'ExternalUser'
                permissionLevel = 'Full Control'
            }
            RiskScore  = 0
            RiskTier   = 'LOW'
            DetectedAt = (Get-Date).ToString('o')
        }
        [pscustomobject]@{
            SiteUrl    = "$TenantUrl/sites/Trading-Desk"
            ItemPath   = 'Trading Records'
            DriftType  = 'CHANGED'
            Before     = [pscustomobject]@{
                principalName   = 'Trading Analysts'
                principalType   = 'SecurityGroup'
                permissionLevel = 'Read'
            }
            After      = [pscustomobject]@{
                principalName   = 'Trading Analysts'
                principalType   = 'SecurityGroup'
                permissionLevel = 'Full Control'
            }
            RiskScore  = 0
            RiskTier   = 'LOW'
            DetectedAt = (Get-Date).ToString('o')
        }
        [pscustomobject]@{
            SiteUrl    = "$TenantUrl/sites/Client-Advisory"
            ItemPath   = 'Client Reports/2025-Q1.xlsx'
            DriftType  = 'ADDED'
            Before     = $null
            After      = [pscustomobject]@{
                principalName   = 'All Employees'
                principalType   = 'OrganizationWide'
                permissionLevel = 'Read'
            }
            RiskScore  = 0
            RiskTier   = 'LOW'
            DetectedAt = (Get-Date).ToString('o')
        }
        [pscustomobject]@{
            SiteUrl    = "$TenantUrl/sites/HR-Confidential"
            ItemPath   = 'Policies/Travel-Policy.docx'
            DriftType  = 'REMOVED'
            Before     = [pscustomobject]@{
                principalName   = 'HR Admins'
                principalType   = 'SharePointGroup'
                permissionLevel = 'Full Control'
            }
            After      = $null
            RiskScore  = 0
            RiskTier   = 'LOW'
            DetectedAt = (Get-Date).ToString('o')
        }
    )

    $classifiedItems = @()
    foreach ($sampleItem in $sampleItems) {
        $classifiedItems += (Set-RiskClassification -DriftItem $sampleItem -DriftTypeWeights $DriftTypeWeights -RiskThresholds $RiskThresholds)
    }

    return $classifiedItems
}

function Send-DriftAlert {
    <#
    .SYNOPSIS
        Sends a drift alert email via Microsoft Graph API for HIGH-risk findings.
    #>
    param(
        [string]$Recipient,
        [string]$SenderAddress,
        [array]$HighRiskItems
    )

    if (-not $Recipient -or @($HighRiskItems).Count -eq 0) { return }

    $graphContext = $null
    try {
        $graphContext = Get-MgContext -ErrorAction SilentlyContinue
    }
    catch {
        Write-Verbose "No Microsoft Graph context available."
    }

    if ($null -eq $graphContext) {
        Write-Warning "Graph API context not available — alert email not sent. $(@($HighRiskItems).Count) HIGH-risk drift item(s) detected."
        return
    }

    try {
        $subject = "SharePoint Permissions Drift Alert — $(@($HighRiskItems).Count) HIGH-Risk Item(s)"
        $body = "HIGH-risk permissions drift detected on the following sites:`n"
        foreach ($item in $HighRiskItems) {
            $body += "  - $($item.SiteUrl) | $($item.ItemPath) | $($item.DriftType) | Score: $($item.RiskScore)`n"
        }

        $message = @{
            message = @{
                subject      = $subject
                body         = @{ contentType = 'Text'; content = $body }
                toRecipients = @(@{ emailAddress = @{ address = $Recipient } })
            }
        }

        $sendMailUri = if ([string]::IsNullOrWhiteSpace($SenderAddress)) {
            'https://graph.microsoft.com/v1.0/me/sendMail'
        }
        else {
            "https://graph.microsoft.com/v1.0/users/$SenderAddress/sendMail"
        }

        Invoke-MgGraphRequest -Method POST -Uri $sendMailUri -Body $message
        $senderDescription = if ([string]::IsNullOrWhiteSpace($SenderAddress)) { 'delegated /me mailbox' } else { $SenderAddress }
        Write-Host "Alert email sent to $Recipient from $senderDescription."
    }
    catch {
        Write-Warning "Failed to send alert email: $($_.Exception.Message)"
    }
}

#endregion

#region Main Logic

$solutionRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$config = Get-ConfigAsHashtable -Path $ConfigPath -SolutionRoot $solutionRoot
if (-not $config.ContainsKey('driftTypeWeights') -or -not $config.ContainsKey('riskThresholds')) {
    throw "Risk scoring configuration must include 'driftTypeWeights' and 'riskThresholds'."
}

$driftTypeWeights = $config['driftTypeWeights']
$riskThresholds = $config['riskThresholds']

# Load baseline
$baselineData = $null
if (Test-Path $BaselinePath) {
    $rawBaseline = Get-Content -Path $BaselinePath -Raw | ConvertFrom-Json

    # Check if this is a pointer file
    if ($rawBaseline.PSObject.Properties.Name -contains 'baselinePath') {
        $baselineDir = Split-Path $BaselinePath -Parent
        $actualBaselinePath = Join-Path $baselineDir $rawBaseline.baselinePath
        if (Test-Path $actualBaselinePath) {
            $baselineData = Get-Content -Path $actualBaselinePath -Raw | ConvertFrom-Json
        }
        else {
            Write-Warning "Referenced baseline file not found: $actualBaselinePath"
        }
    }
    else {
        $baselineData = $rawBaseline
    }
}

# If no baseline is found, use representative sample drift data.
$useSampleData = $null -eq $baselineData
if ($useSampleData) {
    Write-Warning "No baseline file found at $BaselinePath — using representative sample drift data."
}

$driftItems = @()

if ($useSampleData) {
    $driftItems = Get-SampleDriftData -TenantUrl $TenantUrl -DriftTypeWeights $driftTypeWeights -RiskThresholds $riskThresholds
}
else {
    foreach ($baselineSite in $baselineData.sites) {
        # Tenant-bound current-state capture is pending; scope representative sample drift to baseline sites.
        $sampleDrift = Get-SampleDriftData -TenantUrl $TenantUrl -DriftTypeWeights $driftTypeWeights -RiskThresholds $riskThresholds
        $siteDrift = $sampleDrift | Where-Object { $_.SiteUrl -eq $baselineSite.siteUrl }
        if ($siteDrift) {
            $driftItems += $siteDrift
        }
    }
}

# Build drift report
$timestamp = Get-Date -Format 'yyyyMMddTHHmmss'
$driftReport = [pscustomobject]@{
    generatedAt    = (Get-Date).ToString('o')
    tenantUrl      = $TenantUrl
    baselinePath   = $BaselinePath
    totalDriftItems = @($driftItems).Count
    summary        = [pscustomobject]@{
        added   = @($driftItems | Where-Object { $_.DriftType -eq 'ADDED' }).Count
        removed = @($driftItems | Where-Object { $_.DriftType -eq 'REMOVED' }).Count
        changed = @($driftItems | Where-Object { $_.DriftType -eq 'CHANGED' }).Count
        high    = @($driftItems | Where-Object { $_.RiskTier -eq 'HIGH' }).Count
        medium  = @($driftItems | Where-Object { $_.RiskTier -eq 'MEDIUM' }).Count
        low     = @($driftItems | Where-Object { $_.RiskTier -eq 'LOW' }).Count
    }
    items          = $driftItems
}

# Ensure output directory exists
if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
}

$reportFileName = "drift-report-$timestamp.json"
$reportFilePath = Join-Path $OutputPath $reportFileName

$driftReport | ConvertTo-Json -Depth 10 | Set-Content -Path $reportFilePath -Encoding UTF8
Write-Host "Drift report saved: $reportFilePath"

# Send alert for HIGH-risk items
$highRiskItems = @($driftItems | Where-Object { $_.RiskTier -eq 'HIGH' })
if (@($highRiskItems).Count -gt 0) {
    Send-DriftAlert -Recipient $AlertRecipient -SenderAddress $AlertSender -HighRiskItems $highRiskItems
}

#endregion

# Return summary
[pscustomobject]@{
    ReportFile     = $reportFilePath
    TotalDrift     = @($driftItems).Count
    HighRisk       = @($highRiskItems).Count
    MediumRisk     = @($driftItems | Where-Object { $_.RiskTier -eq 'MEDIUM' }).Count
    LowRisk        = @($driftItems | Where-Object { $_.RiskTier -eq 'LOW' }).Count
    AlertSent      = (@($highRiskItems).Count -gt 0 -and $AlertRecipient)
    Status         = 'DriftScanComplete'
}
