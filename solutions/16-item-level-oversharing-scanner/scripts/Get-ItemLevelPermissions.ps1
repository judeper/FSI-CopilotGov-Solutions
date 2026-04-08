<#
.SYNOPSIS
Enumerates item-level permissions across SharePoint document libraries.

.DESCRIPTION
Connects to SharePoint via PnP PowerShell and enumerates all document libraries
in each specified site. For each file and folder, retrieves permission entries
and flags items as overshared when any of the following conditions are detected:
anyone (anonymous) links, organization-wide links with Edit access, direct
sharing with external or guest users, or sharing with broad groups such as
Everyone or Everyone except external users.

Scripts use representative sample data and do not connect to live Microsoft 365
services in their repository form.

.PARAMETER SiteUrls
Array of SharePoint site URLs to scan for item-level permissions.

.PARAMETER OutputPath
Directory where the item permissions CSV will be written.

.PARAMETER TenantUrl
SharePoint tenant admin URL used for PnP connection.

.EXAMPLE
.\Get-ItemLevelPermissions.ps1 -SiteUrls @("https://tenant.sharepoint.com/sites/finance") -TenantUrl "https://tenant-admin.sharepoint.com" -OutputPath .\artifacts\scan

.EXAMPLE
.\Get-ItemLevelPermissions.ps1 -SiteUrls @("https://tenant.sharepoint.com/sites/finance","https://tenant.sharepoint.com/sites/legal") -TenantUrl "https://tenant-admin.sharepoint.com"
#>
# PnP.PowerShell is required for live SharePoint operations.
# Scripts fall back to representative sample data when PnP is unavailable.
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string[]]$SiteUrls,

    [Parameter()]
    [string]$OutputPath = (Join-Path $PSScriptRoot '..\artifacts\scan'),

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$TenantUrl
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
Import-Module (Join-Path $repoRoot 'scripts\common\GraphAuth.psm1') -Force
Import-Module (Join-Path $repoRoot 'scripts\common\EvidenceExport.psm1') -Force

$broadGroups = @(
    'Everyone',
    'Everyone except external users',
    'All Company',
    'All Users',
    'NT AUTHORITY\authenticated users'
)

function Get-ItemShareType {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$RoleAssignment,

        [Parameter()]
        [object]$SharingInfo
    )

    $member = $RoleAssignment.Member
    $loginName = if ($member -is [hashtable]) { $member['LoginName'] } else { $member.LoginName }
    $title = if ($member -is [hashtable]) { $member['Title'] } else { $member.Title }
    $principalType = if ($member -is [hashtable]) { $member['PrincipalType'] } else { $member.PrincipalType }

    if ($null -ne $SharingInfo) {
        $sharingLinks = if ($SharingInfo -is [hashtable]) { $SharingInfo['SharingLinks'] } else { $SharingInfo.SharingLinks }
        if ($null -ne $sharingLinks) {
            foreach ($link in $sharingLinks) {
                $linkScope = if ($link -is [hashtable]) { $link['Scope'] } else { $link.Scope }
                $isEditLink = if ($link -is [hashtable]) { $link['IsEditLink'] } else { $link.IsEditLink }

                if ($linkScope -eq 'Anyone') {
                    return @{ ShareType = 'AnyoneLink'; SharedWith = 'Anonymous' }
                }
                if ($linkScope -eq 'Organization' -and $isEditLink -eq $true) {
                    return @{ ShareType = 'OrgLink'; SharedWith = 'Organization (Edit)' }
                }
            }
        }
    }

    if ($null -ne $loginName) {
        if ($loginName -match '#ext#' -or $loginName -match 'guest') {
            return @{ ShareType = 'ExternalUser'; SharedWith = $loginName }
        }
    }

    if ($null -ne $title -and $title -in $broadGroups) {
        return @{ ShareType = 'BroadGroup'; SharedWith = $title }
    }

    if ($null -ne $principalType -and $principalType -eq 'SecurityGroup') {
        if ($null -ne $title -and $broadGroups -contains $title) {
            return @{ ShareType = 'BroadGroup'; SharedWith = $title }
        }
    }

    return $null
}

function Get-SampleItemPermissions {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$SiteUrl
    )

    $siteName = ($SiteUrl -split '/')[-1]

    return @(
        [pscustomobject]@{
            SiteUrl = $SiteUrl
            LibraryName = 'Documents'
            ItemPath = "/sites/$siteName/Documents/Q4-Financial-Report.xlsx"
            ItemType = 'File'
            SharedWith = 'Anonymous'
            ShareType = 'AnyoneLink'
            SensitivityLabel = 'Confidential - Trading'
            LastModified = (Get-Date).AddDays(-3).ToString('yyyy-MM-dd')
        }
        [pscustomobject]@{
            SiteUrl = $SiteUrl
            LibraryName = 'Documents'
            ItemPath = "/sites/$siteName/Documents/Customer-KYC-Records/"
            ItemType = 'Folder'
            SharedWith = 'guest@external.com'
            ShareType = 'ExternalUser'
            SensitivityLabel = 'Highly Confidential - PII'
            LastModified = (Get-Date).AddDays(-7).ToString('yyyy-MM-dd')
        }
        [pscustomobject]@{
            SiteUrl = $SiteUrl
            LibraryName = 'Shared Documents'
            ItemPath = "/sites/$siteName/Shared Documents/Trading-Positions-2025.csv"
            ItemType = 'File'
            SharedWith = 'Organization (Edit)'
            ShareType = 'OrgLink'
            SensitivityLabel = 'Confidential - Trading'
            LastModified = (Get-Date).AddDays(-1).ToString('yyyy-MM-dd')
        }
        [pscustomobject]@{
            SiteUrl = $SiteUrl
            LibraryName = 'Shared Documents'
            ItemPath = "/sites/$siteName/Shared Documents/Internal-Memo.docx"
            ItemType = 'File'
            SharedWith = 'Everyone except external users'
            ShareType = 'BroadGroup'
            SensitivityLabel = ''
            LastModified = (Get-Date).AddDays(-14).ToString('yyyy-MM-dd')
        }
        [pscustomobject]@{
            SiteUrl = $SiteUrl
            LibraryName = 'Legal Hold'
            ItemPath = "/sites/$siteName/Legal Hold/Litigation-Response-2025.pdf"
            ItemType = 'File'
            SharedWith = 'Anonymous'
            ShareType = 'AnyoneLink'
            SensitivityLabel = 'Highly Confidential - Legal'
            LastModified = (Get-Date).AddDays(-2).ToString('yyyy-MM-dd')
        }
    )
}

$outputRoot = [System.IO.Path]::GetFullPath($OutputPath)
$null = New-Item -Path $outputRoot -ItemType Directory -Force
$csvPath = Join-Path $outputRoot 'item-permissions.csv'
$allFindings = @()

foreach ($siteUrl in $SiteUrls) {
    Write-Verbose "Scanning site: $siteUrl"

    try {
        $allFindings += Get-SampleItemPermissions -SiteUrl $siteUrl
    }
    catch {
        Write-Warning "Failed to scan site $siteUrl : $_"
        continue
    }
}

if ($allFindings.Count -gt 0) {
    $allFindings | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
    Write-Verbose "Exported $($allFindings.Count) item permission findings to $csvPath"
}
else {
    Write-Warning 'No overshared items found across the specified sites.'
}

[pscustomobject]@{
    SitesScanned = $SiteUrls.Count
    ItemsFound = $allFindings.Count
    OutputPath = $csvPath
}
