<#
.SYNOPSIS
Produces oversharing findings for SharePoint, OneDrive, and Teams.

.DESCRIPTION
Loads the selected solution configuration, gathers workload candidates via
Microsoft Graph API when authentication parameters are supplied, or falls back
to representative sample data for documentation-first and test scenarios.
Applies FSI-weighted risk classification, optionally exports the findings and
summary, and returns an array of normalized findings.

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

.PARAMETER ClientId
Application (client) ID for app-only Graph authentication.

.PARAMETER ClientSecret
Client secret for app-only Graph authentication.

.PARAMETER CertificateThumbprint
Certificate thumbprint for app-only Graph authentication.

.PARAMETER UseMgGraph
Use the Microsoft.Graph SDK (Connect-MgGraph) for delegated authentication.

.EXAMPLE
.\Monitor-Compliance.ps1 -ConfigurationTier recommended -TenantId 00000000-0000-0000-0000-000000000000 -WorkloadsToScan sharePoint -MaxSites 100

.EXAMPLE
.\Monitor-Compliance.ps1 -ConfigurationTier regulated -TenantId 00000000-0000-0000-0000-000000000000 -ClientId $appId -ClientSecret $secret

.EXAMPLE
.\Monitor-Compliance.ps1 -ConfigurationTier regulated -TenantId 00000000-0000-0000-0000-000000000000 -UseMgGraph -ExportPath .\artifacts\monitor
#>
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet('baseline', 'recommended', 'regulated')]
    [string]$ConfigurationTier = 'baseline',

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [ValidatePattern('^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')]
    [string]$TenantId,

    [Parameter()]
    [int]$MaxSites = -1,

    [Parameter()]
    [ValidateSet('sharePoint', 'oneDrive', 'teams')]
    [string[]]$WorkloadsToScan,

    [Parameter()]
    [string]$ExportPath,

    [Parameter()]
    [string]$ClientId,

    [Parameter()]
    [string]$ClientSecret,

    [Parameter()]
    [string]$CertificateThumbprint,

    [Parameter()]
    [switch]$UseMgGraph
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path $PSScriptRoot 'SharedUtilities.psm1') -Force

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$graphAuthModulePath = Join-Path $repoRoot 'scripts\common\GraphAuth.psm1'
if (Test-Path $graphAuthModulePath) {
    Import-Module $graphAuthModulePath -Force
}
else {
    Write-Warning "Shared module GraphAuth.psm1 not found at '$graphAuthModulePath'. Graph authentication unavailable; sample data will be used."
}

function Invoke-GraphWithRetry {
    <#
    .SYNOPSIS
    Wraps Invoke-CopilotGovGraphRequest with retry and exponential backoff for throttled (429) responses.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][psobject]$Context,
        [Parameter(Mandatory)][string]$Uri,
        [switch]$AllPages,
        [int]$MaxRetries = 3,
        [int[]]$BackoffSeconds = @(60, 120, 240)
    )
    $attempt = 0
    while ($true) {
        try {
            $params = @{ Context = $Context; Uri = $Uri }
            if ($AllPages) { $params['AllPages'] = $true }
            return Invoke-CopilotGovGraphRequest @params
        }
        catch {
            $attempt++
            $is429 = $_.Exception.Message -match '429' -or
                     $_.Exception.Message -match 'throttl' -or
                     ($null -ne $_.Exception.Response -and
                      [int]$_.Exception.Response.StatusCode -eq 429)
            if (-not $is429 -or $attempt -gt $MaxRetries) { throw }
            $delay = if ($attempt -le $BackoffSeconds.Count) { $BackoffSeconds[$attempt - 1] } else { $BackoffSeconds[-1] }
            Write-Warning "Graph API throttled (attempt $attempt/$MaxRetries). Retrying in ${delay}s..."
            Start-Sleep -Seconds $delay
        }
    }
}

function Get-SitePermissionAnalysis {
    [CmdletBinding()]
    param(
        [Parameter()]
        [object[]]$Permissions = @(),

        [Parameter()]
        [string]$SiteName = ''
    )

    $sharingScope = 'Targeted'
    $anomalyCount = 0
    $exposureReasons = @()

    foreach ($perm in $Permissions) {
        $link = if ($perm -is [hashtable]) { $perm['link'] } else { $perm.link }
        $grantedToV2 = if ($perm -is [hashtable]) { $perm['grantedToV2'] } else { $perm.grantedToV2 }
        $grantedTo = if ($perm -is [hashtable]) { $perm['grantedTo'] } else { $perm.grantedTo }

        if ($null -ne $link) {
            $linkScope = if ($link -is [hashtable]) { $link['scope'] } else { $link.scope }
            $linkType = if ($link -is [hashtable]) { $link['type'] } else { $link.type }

            switch ($linkScope) {
                'anonymous' {
                    $sharingScope = 'Anonymous'
                    $anomalyCount++
                    $exposureReasons += 'Anonymous sharing link detected'
                }
                'organization' {
                    if ($sharingScope -notin @('Anonymous', 'Guest')) {
                        $sharingScope = 'AllEmployees'
                    }
                    if ($linkType -eq 'edit') { $anomalyCount++ }
                    $exposureReasons += 'Organization-wide sharing link'
                }
                'users' {
                    # User-scoped links are targeted (most restrictive) — do not inflate anomaly count
                }
            }
        }
        elseif ($null -ne $grantedToV2 -or $null -ne $grantedTo) {
            $target = if ($null -ne $grantedToV2) { $grantedToV2 } else { $grantedTo }
            $user = if ($target -is [hashtable]) { $target['user'] } else { $target.user }
            $group = if ($target -is [hashtable]) { $target['group'] } else { $target.group }

            if ($null -ne $user) {
                $email = if ($user -is [hashtable]) { $user['email'] } else { $user.email }
                $displayName = if ($user -is [hashtable]) { $user['displayName'] } else { $user.displayName }
                if ($email -match '#ext#' -or $displayName -match '#ext#') {
                    if ($sharingScope -ne 'Anonymous') { $sharingScope = 'Guest' }
                    $anomalyCount++
                    $exposureReasons += 'External user access'
                }
            }

            if ($null -ne $group) {
                $groupName = if ($group -is [hashtable]) { $group['displayName'] } else { $group.displayName }
                if ($groupName -match 'Everyone|All Company|All Users|Everyone except external') {
                    if ($sharingScope -notin @('Anonymous', 'Guest', 'AllEmployees')) {
                        $sharingScope = 'BroadInternal'
                    }
                    $anomalyCount++
                    $exposureReasons += "Broad group access: $groupName"
                }
            }
        }
    }

    $exposureType = if ($exposureReasons.Count -gt 0) {
        $primary = $exposureReasons[0]
        if ($exposureReasons.Count -gt 1) { "$primary (+$($exposureReasons.Count - 1) more)" } else { $primary }
    }
    else {
        'No oversharing indicators detected'
    }

    return [pscustomobject]@{
        SharingScope = $sharingScope
        AnomalyCount = $anomalyCount
        ExposureType = $exposureType
    }
}

function Get-SiteDataSignals {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$SiteName = '',

        [Parameter()]
        [hashtable]$Configuration
    )

    $signals = @()
    if ($null -eq $Configuration -or -not $Configuration.ContainsKey('fsiDataClassifiers')) {
        return $signals
    }

    $classifiers = $Configuration.fsiDataClassifiers
    $siteNameLower = $SiteName.ToLower()

    foreach ($classifierKey in $classifiers.Keys) {
        $keywords = @($classifiers[$classifierKey].keywords)
        foreach ($keyword in $keywords) {
            if ($siteNameLower -match [regex]::Escape($keyword.ToLower())) {
                if ($classifierKey -notin $signals) {
                    $signals += $classifierKey
                }
                break
            }
        }
    }

    return $signals
}

function Get-SharePointOversharingSites {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$TenantId,

        [Parameter()]
        [psobject]$GraphContext,

        [Parameter()]
        [hashtable]$Configuration
    )

    if ($null -eq $GraphContext) {
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

    $sites = @(Invoke-GraphWithRetry -Context $GraphContext `
        -Uri "/sites?search=*&`$select=id,displayName,webUrl,isPersonalSite&`$top=999" -AllPages)

    $spSites = @($sites | Where-Object {
        $personal = if ($_ -is [hashtable]) { $_['isPersonalSite'] } else { $_.isPersonalSite }
        -not $personal
    })

    $candidates = @()
    foreach ($site in $spSites) {
        $siteId = if ($site -is [hashtable]) { $site['id'] } else { $site.id }
        $siteUrl = if ($site -is [hashtable]) { $site['webUrl'] } else { $site.webUrl }
        $siteName = if ($site -is [hashtable]) { $site['displayName'] } else { $site.displayName }

        $permissions = @()
        try {
            $permissions = @(Invoke-GraphWithRetry -Context $GraphContext `
                -Uri "/sites/$siteId/drive/root/permissions")
        }
        catch {
            Write-Warning "Could not retrieve permissions for $siteUrl : $($_.Exception.Message)"
        }

        $analysis = Get-SitePermissionAnalysis -Permissions $permissions -SiteName $siteName
        $signals = Get-SiteDataSignals -SiteName $siteName -Configuration $Configuration

        $owner = ''
        try {
            $siteDetail = Invoke-GraphWithRetry -Context $GraphContext `
                -Uri "/sites/$siteId`?`$select=createdBy"
            $createdBy = if ($siteDetail -is [hashtable]) { $siteDetail['createdBy'] } else { $siteDetail.createdBy }
            if ($null -ne $createdBy) {
                $user = if ($createdBy -is [hashtable]) { $createdBy['user'] } else { $createdBy.user }
                if ($null -ne $user) {
                    $owner = if ($user -is [hashtable]) { $user['email'] } else { $user.email }
                }
            }
        }
        catch { Write-Warning "Could not resolve owner for site $siteUrl : $($_.Exception.Message)" }
        if ([string]::IsNullOrWhiteSpace($owner)) { $owner = "siteadmin@tenant" }

        $candidates += [pscustomobject]@{
            SiteUrl = $siteUrl
            WorkloadType = 'sharePoint'
            SharingScope = $analysis.SharingScope
            DetectedSignals = $signals
            PermissionAnomalyCount = $analysis.AnomalyCount
            ExposureType = $analysis.ExposureType
            Owner = $owner
            TenantId = $TenantId
        }
    }

    return $candidates
}

function Get-OneDriveOversharingItems {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$TenantId,

        [Parameter()]
        [psobject]$GraphContext,

        [Parameter()]
        [hashtable]$Configuration
    )

    if ($null -eq $GraphContext) {
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

    $sites = @(Invoke-GraphWithRetry -Context $GraphContext `
        -Uri "/sites?search=*&`$select=id,displayName,webUrl,isPersonalSite&`$top=999" -AllPages)

    $personalSites = @($sites | Where-Object {
        $personal = if ($_ -is [hashtable]) { $_['isPersonalSite'] } else { $_.isPersonalSite }
        $personal -eq $true
    })

    $candidates = @()
    foreach ($site in $personalSites) {
        $siteId = if ($site -is [hashtable]) { $site['id'] } else { $site.id }
        $siteUrl = if ($site -is [hashtable]) { $site['webUrl'] } else { $site.webUrl }
        $siteName = if ($site -is [hashtable]) { $site['displayName'] } else { $site.displayName }

        $permissions = @()
        try {
            $permissions = @(Invoke-GraphWithRetry -Context $GraphContext `
                -Uri "/sites/$siteId/drive/root/permissions")
        }
        catch {
            Write-Warning "Could not retrieve OneDrive permissions for $siteUrl : $($_.Exception.Message)"
        }

        $analysis = Get-SitePermissionAnalysis -Permissions $permissions -SiteName $siteName
        if ($analysis.AnomalyCount -eq 0) { continue }

        $signals = Get-SiteDataSignals -SiteName $siteName -Configuration $Configuration
        $ownerEmail = $siteUrl -replace '^.*personal[/\\]', ''
        if ([string]::IsNullOrWhiteSpace($ownerEmail) -or $ownerEmail -notmatch '@') {
            $ownerEmail = "$ownerEmail@tenant"
        }

        $candidates += [pscustomobject]@{
            SiteUrl = $siteUrl
            WorkloadType = 'oneDrive'
            SharingScope = $analysis.SharingScope
            DetectedSignals = $signals
            PermissionAnomalyCount = $analysis.AnomalyCount
            ExposureType = $analysis.ExposureType
            Owner = $ownerEmail
            TenantId = $TenantId
        }
    }

    return $candidates
}

function Get-TeamsOversharingChannels {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$TenantId,

        [Parameter()]
        [psobject]$GraphContext,

        [Parameter()]
        [hashtable]$Configuration
    )

    if ($null -eq $GraphContext) {
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

    $groups = @()
    try {
        $groups = @(Invoke-GraphWithRetry -Context $GraphContext `
            -Uri "/groups?`$filter=resourceProvisioningOptions/Any(x:x eq 'Team')&`$select=id,displayName,mail" -AllPages)
    }
    catch {
        Write-Warning "Could not enumerate Teams-connected groups: $($_.Exception.Message)"
        return @()
    }

    $candidates = @()
    foreach ($group in $groups) {
        $groupId = if ($group -is [hashtable]) { $group['id'] } else { $group.id }
        $groupName = if ($group -is [hashtable]) { $group['displayName'] } else { $group.displayName }
        $groupMail = if ($group -is [hashtable]) { $group['mail'] } else { $group.mail }

        $spSite = $null
        try {
            $spSite = Invoke-GraphWithRetry -Context $GraphContext `
                -Uri "/groups/$groupId/sites/root?`$select=id,webUrl"
        }
        catch {
            Write-Warning "Could not retrieve SharePoint site for team $groupName : $($_.Exception.Message)"
            continue
        }

        $siteId = if ($spSite -is [hashtable]) { $spSite['id'] } else { $spSite.id }
        $siteUrl = if ($spSite -is [hashtable]) { $spSite['webUrl'] } else { $spSite.webUrl }

        $permissions = @()
        try {
            $permissions = @(Invoke-GraphWithRetry -Context $GraphContext `
                -Uri "/sites/$siteId/drive/root/permissions")
        }
        catch {
            Write-Warning "Could not retrieve permissions for team $groupName : $($_.Exception.Message)"
        }

        $analysis = Get-SitePermissionAnalysis -Permissions $permissions -SiteName $groupName
        $signals = Get-SiteDataSignals -SiteName $groupName -Configuration $Configuration

        $owner = if (-not [string]::IsNullOrWhiteSpace($groupMail)) { $groupMail } else { "teamowner@tenant" }

        $candidates += [pscustomobject]@{
            SiteUrl = $siteUrl
            WorkloadType = 'teams'
            SharingScope = $analysis.SharingScope
            DetectedSignals = $signals
            PermissionAnomalyCount = $analysis.AnomalyCount
            ExposureType = $analysis.ExposureType
            Owner = $owner
            TenantId = $TenantId
        }
    }

    return $candidates
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
    $classifiers = $Configuration.fsiDataClassifiers

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

function Get-SensitivityLabelCoverage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$TenantId,

        [Parameter()]
        [psobject]$GraphContext,

        [Parameter()]
        [object[]]$ScannedSites = @()
    )

    if ($null -eq $GraphContext) {
        # Sample data: representative label coverage for documentation-first scenarios
        $totalSites = [Math]::Max(@($ScannedSites).Count, 7)
        $labeledCount = [Math]::Floor($totalSites * 0.43)
        return [pscustomobject]@{
            TenantId = $TenantId
            TotalSitesScanned = $totalSites
            SitesWithLabels = $labeledCount
            SitesWithoutLabels = ($totalSites - $labeledCount)
            LabelCoveragePercent = [Math]::Round(($labeledCount / $totalSites) * 100, 1)
            LabelBreakdown = @(
                [pscustomobject]@{ Label = 'Highly Confidential'; Count = [Math]::Floor($labeledCount * 0.33) }
                [pscustomobject]@{ Label = 'Confidential'; Count = [Math]::Floor($labeledCount * 0.50) }
                [pscustomobject]@{ Label = 'General'; Count = ($labeledCount - [Math]::Floor($labeledCount * 0.33) - [Math]::Floor($labeledCount * 0.50)) }
            )
            Recommendation = 'Apply Microsoft Purview Information Protection sensitivity labels to all sites containing regulated data to restrict Microsoft 365 Copilot content surfacing.'
        }
    }

    $labeledSiteCount = 0
    $unlabeledSiteCount = 0
    $labelCounts = @{}

    foreach ($site in $ScannedSites) {
        $siteUrl = if ($site -is [hashtable]) { $site['SiteUrl'] } else { $site.SiteUrl }
        $siteId = $null
        try {
            $siteInfo = Invoke-GraphWithRetry -Context $GraphContext `
                -Uri "/sites?search=$([Uri]::EscapeDataString($siteUrl))&`$select=id&`$top=1"
            $siteId = if ($siteInfo -is [array] -and $siteInfo.Count -gt 0) {
                if ($siteInfo[0] -is [hashtable]) { $siteInfo[0]['id'] } else { $siteInfo[0].id }
            }
        }
        catch {
            Write-Warning "Could not look up site ID for $siteUrl : $($_.Exception.Message)"
        }

        if ($null -eq $siteId) { $unlabeledSiteCount++; continue }

        try {
            $driveItems = @(Invoke-GraphWithRetry -Context $GraphContext `
                -Uri "/sites/$siteId/drive/root/children?`$select=id,sensitivityLabel&`$top=50")
            $labeledItems = @($driveItems | Where-Object {
                $label = if ($_ -is [hashtable]) { $_['sensitivityLabel'] } else { $_.sensitivityLabel }
                $null -ne $label
            })

            if ($labeledItems.Count -gt 0) {
                $labeledSiteCount++
                foreach ($item in $labeledItems) {
                    $label = if ($item -is [hashtable]) { $item['sensitivityLabel'] } else { $item.sensitivityLabel }
                    $labelName = if ($label -is [hashtable]) { $label['displayName'] } else { $label.displayName }
                    if (-not [string]::IsNullOrWhiteSpace($labelName)) {
                        if (-not $labelCounts.ContainsKey($labelName)) { $labelCounts[$labelName] = 0 }
                        $labelCounts[$labelName]++
                    }
                }
            }
            else {
                $unlabeledSiteCount++
            }
        }
        catch {
            Write-Warning "Could not retrieve sensitivity labels for site $siteUrl : $($_.Exception.Message)"
            $unlabeledSiteCount++
        }
    }

    $totalScanned = $labeledSiteCount + $unlabeledSiteCount
    $coveragePercent = if ($totalScanned -gt 0) { [Math]::Round(($labeledSiteCount / $totalScanned) * 100, 1) } else { 0 }

    $breakdown = foreach ($key in $labelCounts.Keys | Sort-Object) {
        [pscustomobject]@{ Label = $key; Count = $labelCounts[$key] }
    }

    return [pscustomobject]@{
        TenantId = $TenantId
        TotalSitesScanned = $totalScanned
        SitesWithLabels = $labeledSiteCount
        SitesWithoutLabels = $unlabeledSiteCount
        LabelCoveragePercent = $coveragePercent
        LabelBreakdown = @($breakdown)
        Recommendation = 'Apply Microsoft Purview Information Protection sensitivity labels to all sites containing regulated data to restrict Microsoft 365 Copilot content surfacing.'
    }
}

$configuration = Get-Configuration -ConfigurationTier $ConfigurationTier -ScriptRoot $PSScriptRoot

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

$graphContext = $null
if ($PSBoundParameters.ContainsKey('ClientId') -or $UseMgGraph) {
    $connectParams = @{ TenantId = $TenantId }
    if ($UseMgGraph) { $connectParams['UseMgGraph'] = $true }
    if ($PSBoundParameters.ContainsKey('ClientId')) { $connectParams['ClientId'] = $ClientId }
    if ($PSBoundParameters.ContainsKey('ClientSecret')) { $connectParams['ClientSecret'] = $ClientSecret }
    if ($PSBoundParameters.ContainsKey('CertificateThumbprint')) { $connectParams['CertificateThumbprint'] = $CertificateThumbprint }
    try {
        $graphContext = Connect-CopilotGovGraph @connectParams
    }
    catch {
        Write-Warning "Graph authentication failed, falling back to sample data: $($_.Exception.Message)"
    }
}

foreach ($workload in $effectiveWorkloads) {
    switch ($workload) {
        'sharePoint' {
            $rawCandidates += Get-SharePointOversharingSites -TenantId $TenantId -GraphContext $graphContext -Configuration $configuration
        }
        'oneDrive' {
            $rawCandidates += Get-OneDriveOversharingItems -TenantId $TenantId -GraphContext $graphContext -Configuration $configuration
        }
        'teams' {
            $rawCandidates += Get-TeamsOversharingChannels -TenantId $TenantId -GraphContext $graphContext -Configuration $configuration
        }
    }
}

$findings = @(Invoke-RiskClassification -Candidates $rawCandidates -Configuration $configuration -RemediationMode (([string]$configuration.remediationMode).Substring(0, 1).ToUpper() + ([string]$configuration.remediationMode).Substring(1)))

if ($effectiveMaxSites -eq 0) {
    Write-Warning "MaxSites is 0. No findings will be returned. Set MaxSites to -1 (no cap) or a positive integer if this is unintentional."
}

if ($effectiveMaxSites -ge 0) {
    $findings = @($findings | Select-Object -First $effectiveMaxSites)
}

$sensitivityLabelCoverage = Get-SensitivityLabelCoverage -TenantId $TenantId -GraphContext $graphContext -ScannedSites $rawCandidates

$summary = [pscustomobject]@{
    TenantId = $TenantId
    Tier = $ConfigurationTier
    Workloads = ($effectiveWorkloads -join ', ')
    TotalFindings = @($findings).Count
    HighRiskCount = @($findings | Where-Object { $_.RiskLevel -eq 'HIGH' }).Count
    MediumRiskCount = @($findings | Where-Object { $_.RiskLevel -eq 'MEDIUM' }).Count
    LowRiskCount = @($findings | Where-Object { $_.RiskLevel -eq 'LOW' }).Count
    SensitivityLabelCoverage = $sensitivityLabelCoverage
}

Write-Verbose ("Summary: Total={0}; HIGH={1}; MEDIUM={2}; LOW={3}; LabelCoverage={4}%" -f $summary.TotalFindings, $summary.HighRiskCount, $summary.MediumRiskCount, $summary.LowRiskCount, $sensitivityLabelCoverage.LabelCoveragePercent)

if ($PSBoundParameters.ContainsKey('ExportPath')) {
    $exportRoot = [System.IO.Path]::GetFullPath($ExportPath)
    $null = New-Item -Path $exportRoot -ItemType Directory -Force
    $findings | ConvertTo-Json -Depth 8 | Set-Content -Path (Join-Path $exportRoot 'monitor-findings.json') -Encoding utf8
    $summary | ConvertTo-Json -Depth 5 | Set-Content -Path (Join-Path $exportRoot 'monitor-summary.json') -Encoding utf8
}

return $findings
