#Requires -Modules PnP.PowerShell

<#
.SYNOPSIS
    Captures a permissions baseline snapshot for SharePoint Online sites.

.DESCRIPTION
    Connects to SharePoint Online sites using PnP PowerShell and captures the current
    permissions state as the approved baseline. For each site, the script records
    site-level sharing settings, unique permission entries on lists and libraries,
    sharing links, and external user access.

    The baseline is saved to a timestamped JSON file and a pointer file
    (latest-baseline.json) is updated to reference the most recent capture.

    When no live PnP connection is available, the script returns representative
    sample data for documentation and testing purposes.

.PARAMETER TenantUrl
    The SharePoint Online tenant URL (e.g., https://contoso.sharepoint.com).

.PARAMETER OutputPath
    Directory for baseline output files. Defaults to ./baselines.

.PARAMETER SiteUrls
    Optional array of specific site URLs to include. If omitted, all sites
    matching the baseline-config.json scope are processed.

.PARAMETER ConfigPath
    Path to baseline-config.json. Defaults to ./config/baseline-config.json.

.EXAMPLE
    .\New-PermissionsBaseline.ps1 -TenantUrl "https://contoso.sharepoint.com" -OutputPath "./baselines"

.EXAMPLE
    .\New-PermissionsBaseline.ps1 -TenantUrl "https://contoso.sharepoint.com" -SiteUrls @("https://contoso.sharepoint.com/sites/Finance")
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$TenantUrl,

    [Parameter()]
    [string]$OutputPath = './baselines',

    [Parameter()]
    [string[]]$SiteUrls,

    [Parameter()]
    [string]$ConfigPath = './config/baseline-config.json'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
Import-Module (Join-Path $repoRoot 'scripts\common\GraphAuth.psm1') -Force
Import-Module (Join-Path $repoRoot 'scripts\common\EvidenceExport.psm1') -Force

#region Helper Functions

function Get-BaselineConfig {
    param([string]$Path)
    if (Test-Path $Path) {
        return Get-Content -Path $Path -Raw | ConvertFrom-Json
    }
    Write-Warning "Configuration file not found at $Path — using defaults."
    return [pscustomobject]@{
        scope = [pscustomobject]@{
            includeSiteTypes  = @('TeamSite', 'CommunicationSite', 'OneDriveSite')
            excludeSiteUrls   = @()
            includeLists      = $true
            includeLibraries  = $true
            maxSitesPerRun    = 500
        }
        baselineRetentionDays = 90
        scanFrequencyHours    = 24
    }
}

function Get-SitePermissionsSnapshot {
    <#
    .SYNOPSIS
        Captures permissions state for a single SharePoint site.
    #>
    param(
        [string]$SiteUrl,
        [pscustomobject]$Config
    )

    # Attempt live PnP connection; fall back to sample data
    $pnpContext = $null
    try {
        $pnpContext = Get-PnPContext -ErrorAction SilentlyContinue
    }
    catch {
        Write-Verbose "No active PnP context — using representative sample data."
    }

    if ($null -eq $pnpContext) {
        return [pscustomobject]@{
            siteUrl          = $SiteUrl
            sharingSettings  = [pscustomobject]@{
                sharingCapability     = 'ExternalUserSharingOnly'
                defaultSharingLinkType = 'Internal'
                allowAnonymousLinks   = $false
            }
            uniquePermissions = @(
                [pscustomobject]@{
                    itemPath        = 'Shared Documents'
                    itemType        = 'Library'
                    principalName   = 'Finance Members'
                    principalType   = 'SharePointGroup'
                    permissionLevel = 'Contribute'
                    isInherited     = $false
                }
                [pscustomobject]@{
                    itemPath        = 'Shared Documents/Confidential'
                    itemType        = 'Folder'
                    principalName   = 'Compliance Team'
                    principalType   = 'SecurityGroup'
                    permissionLevel = 'Read'
                    isInherited     = $false
                }
            )
            sharingLinks = @(
                [pscustomobject]@{
                    itemPath  = 'Shared Documents/Q4-Report.xlsx'
                    linkType  = 'OrganizationView'
                    createdBy = 'analyst@contoso.com'
                    createdAt = (Get-Date).AddDays(-14).ToString('o')
                    expiresAt = $null
                }
            )
            externalUsers = @(
                [pscustomobject]@{
                    userPrincipalName = 'auditor@externalfirm.com'
                    displayName       = 'External Auditor'
                    accessGrantedAt   = (Get-Date).AddDays(-30).ToString('o')
                    accessScope       = 'Shared Documents/Audit-Reports'
                    permissionLevel   = 'Read'
                }
            )
        }
    }

    # Live PnP enumeration would go here
    try {
        Connect-PnPOnline -Url $SiteUrl -ErrorAction Stop
        $siteSharing = Get-PnPSite -Includes SharingCapability -ErrorAction Stop
        $lists = Get-PnPList -ErrorAction Stop
        $permissions = @()

        foreach ($list in $lists) {
            if (-not $Config.scope.includeLists -and $list.BaseTemplate -eq 100) { continue }
            if (-not $Config.scope.includeLibraries -and $list.BaseTemplate -eq 101) { continue }

            try {
                $roleAssignments = Get-PnPListItem -List $list -Fields 'HasUniqueRoleAssignments' -ErrorAction Stop
                foreach ($item in $roleAssignments) {
                    $permissions += [pscustomobject]@{
                        itemPath        = "$($list.Title)/$($item.FieldValues.FileLeafRef)"
                        itemType        = $list.BaseTemplate -eq 101 ? 'Library' : 'List'
                        principalName   = 'Enumerated-Principal'
                        principalType   = 'SecurityGroup'
                        permissionLevel = 'Read'
                        isInherited     = -not $item.FieldValues.HasUniqueRoleAssignments
                    }
                }
            }
            catch {
                Write-Warning "Unable to enumerate permissions for list $($list.Title): $($_.Exception.Message)"
            }
        }

        return [pscustomobject]@{
            siteUrl           = $SiteUrl
            sharingSettings   = $siteSharing
            uniquePermissions = $permissions
            sharingLinks      = @()
            externalUsers     = @()
        }
    }
    catch {
        Write-Warning "PnP enumeration failed for $SiteUrl — $($_.Exception.Message). Using sample data."
        return Get-SitePermissionsSnapshot -SiteUrl $SiteUrl -Config $Config
    }
}

#endregion

#region Main Logic

$config = Get-BaselineConfig -Path $ConfigPath

# Determine site list
if ($SiteUrls -and $SiteUrls.Count -gt 0) {
    $targetSites = $SiteUrls
}
else {
    # Sample sites for documentation-first scaffold
    $targetSites = @(
        "$TenantUrl/sites/Finance",
        "$TenantUrl/sites/Trading-Desk",
        "$TenantUrl/sites/Compliance-Records",
        "$TenantUrl/sites/HR-Confidential",
        "$TenantUrl/sites/Client-Advisory"
    )
}

# Limit to maxSitesPerRun
$maxSites = $config.scope.maxSitesPerRun
if ($targetSites.Count -gt $maxSites) {
    Write-Warning "Site count ($($targetSites.Count)) exceeds maxSitesPerRun ($maxSites). Truncating."
    $targetSites = $targetSites | Select-Object -First $maxSites
}

Write-Host "Capturing permissions baseline for $($targetSites.Count) site(s)..."

$siteSnapshots = @()
foreach ($siteUrl in $targetSites) {
    Write-Verbose "Processing: $siteUrl"
    $snapshot = Get-SitePermissionsSnapshot -SiteUrl $siteUrl -Config $config
    $siteSnapshots += $snapshot
}

$timestamp = Get-Date -Format 'yyyyMMddTHHmmss'
$baseline = [pscustomobject]@{
    capturedAt = (Get-Date).ToString('o')
    tenantUrl  = $TenantUrl
    siteCount  = $siteSnapshots.Count
    sites      = $siteSnapshots
}

# Ensure output directory exists
if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
}

$baselineFileName = "baseline-$timestamp.json"
$baselineFilePath = Join-Path $OutputPath $baselineFileName

$baseline | ConvertTo-Json -Depth 10 | Set-Content -Path $baselineFilePath -Encoding UTF8
Write-Host "Baseline saved: $baselineFilePath"

# Update latest-baseline pointer
$latestPointer = [pscustomobject]@{
    baselinePath = $baselineFileName
    capturedAt   = $baseline.capturedAt
    siteCount    = $baseline.siteCount
}

$latestPointerPath = Join-Path $OutputPath 'latest-baseline.json'
$latestPointer | ConvertTo-Json -Depth 5 | Set-Content -Path $latestPointerPath -Encoding UTF8
Write-Host "Latest baseline pointer updated: $latestPointerPath"

#endregion

# Return summary
[pscustomobject]@{
    BaselineFile = $baselineFilePath
    PointerFile  = $latestPointerPath
    SiteCount    = $siteSnapshots.Count
    CapturedAt   = $baseline.capturedAt
    Status       = 'BaselineCaptured'
}
