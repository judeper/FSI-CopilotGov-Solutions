<#
.SYNOPSIS
Exports evidence for the Item-Level Oversharing Scanner solution.

.DESCRIPTION
Runs the monitoring workflow, builds the item-oversharing-findings,
risk-scored-report, and remediation-actions artifacts, packages them into
the shared evidence schema format, and writes SHA-256 checksum files for
each JSON output.

.PARAMETER ConfigurationTier
Selects the governance tier to apply. Supported values are baseline,
recommended, and regulated.

.PARAMETER OutputPath
Directory where evidence artifacts and the package manifest will be written.

.PARAMETER TenantId
Tenant GUID used to label the export.

.PARAMETER PeriodStart
Start date of the reporting period.

.PARAMETER PeriodEnd
End date of the reporting period.

.EXAMPLE
.\Export-Evidence.ps1 -ConfigurationTier recommended -TenantId 00000000-0000-0000-0000-000000000000 -OutputPath .\artifacts\evidence

.EXAMPLE
.\Export-Evidence.ps1 -ConfigurationTier regulated -TenantId 00000000-0000-0000-0000-000000000000 -OutputPath .\artifacts\evidence -PeriodStart (Get-Date).AddDays(-30) -PeriodEnd (Get-Date)
#>
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet('baseline', 'recommended', 'regulated')]
    [string]$ConfigurationTier = 'baseline',

    [Parameter()]
    [string]$OutputPath = (Join-Path $PSScriptRoot '..\artifacts\evidence'),

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$TenantId,

    [Parameter()]
    [datetime]$PeriodStart = ((Get-Date).Date.AddDays(-7)),

    [Parameter()]
    [datetime]$PeriodEnd = (Get-Date).Date
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
Import-Module (Join-Path $repoRoot 'scripts\common\EvidenceExport.psm1') -Force
Import-Module (Join-Path $repoRoot 'scripts\common\IntegrationConfig.psm1') -Force

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

function Write-JsonWithHash {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [object]$Content,

        [Parameter(Mandatory)]
        [string]$ArtifactName,

        [Parameter(Mandatory)]
        [string]$ArtifactType
    )

    $directory = Split-Path -Path $Path -Parent
    if (-not (Test-Path -Path $directory)) {
        $null = New-Item -Path $directory -ItemType Directory -Force
    }

    $Content | ConvertTo-Json -Depth 10 | Set-Content -Path $Path -Encoding utf8

    $hashInfo = Write-CopilotGovSha256File -Path $Path

    return [pscustomobject]@{
        name = $ArtifactName
        type = $ArtifactType
        path = ([System.IO.Path]::GetFullPath($Path))
        hash = $hashInfo.Hash
    }
}

if ($PeriodStart -gt $PeriodEnd) {
    throw 'PeriodStart cannot be later than PeriodEnd.'
}

$configuration = Get-Configuration -ConfigurationTier $ConfigurationTier
$monitorScriptPath = Join-Path $PSScriptRoot 'Monitor-Compliance.ps1'

$monitorParameters = @{
    ConfigurationTier = $ConfigurationTier
    TenantId = $TenantId
}

$scoredItems = @(& $monitorScriptPath @monitorParameters)
$outputRoot = [System.IO.Path]::GetFullPath($OutputPath)
$null = New-Item -Path $outputRoot -ItemType Directory -Force

$itemFindings = foreach ($item in $scoredItems) {
    [pscustomobject]@{
        siteUrl = $item.SiteUrl
        libraryName = $item.LibraryName
        itemPath = $item.ItemPath
        itemType = $item.ItemType
        sharedWith = $item.SharedWith
        shareType = $item.ShareType
        sensitivityLabel = $item.SensitivityLabel
        lastModified = $item.LastModified
        reportingPeriodStart = $PeriodStart.ToString('yyyy-MM-dd')
        reportingPeriodEnd = $PeriodEnd.ToString('yyyy-MM-dd')
    }
}

$riskReport = foreach ($item in $scoredItems) {
    [pscustomobject]@{
        siteUrl = $item.SiteUrl
        libraryName = $item.LibraryName
        itemPath = $item.ItemPath
        shareType = $item.ShareType
        sensitivityLabel = $item.SensitivityLabel
        riskTier = $item.RiskTier
        baseScore = [int]$item.BaseScore
        weightedScore = [double]$item.WeightedScore
        contentCategory = $item.ContentCategory
    }
}

$actionIndex = 1
$remediationActions = foreach ($item in ($scoredItems | Sort-Object -Property @{ Expression = 'WeightedScore'; Descending = $true })) {
    $action = switch ($item.ShareType) {
        'AnyoneLink' { 'Remove anonymous sharing link' }
        'ExternalUser' { 'Remove external user permission' }
        'OrgLink' { 'Downgrade organization link from Edit to View' }
        'BroadGroup' { 'Remove broad group permission' }
        default { 'Review manually' }
    }

    [pscustomobject]@{
        actionId = ('IOS-{0:D4}' -f $actionIndex)
        siteUrl = $item.SiteUrl
        itemPath = $item.ItemPath
        shareType = $item.ShareType
        riskTier = $item.RiskTier
        action = $action
        status = 'pending-approval'
        approvalRequired = $true
        approvedBy = $null
        executedAt = $null
        notes = 'Evidence export record. Remediation requires approval.'
    }

    $actionIndex++
}

$artifacts = @()
$artifacts += Write-JsonWithHash -Path (Join-Path $outputRoot 'item-oversharing-findings.json') -Content @($itemFindings) -ArtifactName 'item-oversharing-findings' -ArtifactType 'item-oversharing-findings'
$artifacts += Write-JsonWithHash -Path (Join-Path $outputRoot 'risk-scored-report.json') -Content @($riskReport) -ArtifactName 'risk-scored-report' -ArtifactType 'risk-scored-report'
$artifacts += Write-JsonWithHash -Path (Join-Path $outputRoot 'remediation-actions.json') -Content @($remediationActions) -ArtifactName 'remediation-actions' -ArtifactType 'remediation-actions'

$controls = @(
    [pscustomobject]@{
        controlId = '1.2'
        status = 'partial'
        notes = 'Item-level oversharing detection extends site-level coverage from solution 02 but requires tenant PnP connectivity for full enumeration.'
    }
    [pscustomobject]@{
        controlId = '1.3'
        status = 'monitor-only'
        notes = 'Supports Restricted SharePoint Search planning by identifying overshared items that should be limited.'
    }
    [pscustomobject]@{
        controlId = '1.4'
        status = 'partial'
        notes = 'Semantic index governance is supported through item-level findings and risk prioritization.'
    }
    [pscustomobject]@{
        controlId = '1.6'
        status = 'monitor-only'
        notes = 'Item-level permission anomalies are surfaced and scored for follow-up.'
    }
    [pscustomobject]@{
        controlId = '2.5'
        status = 'partial'
        notes = 'Data minimization is supported through detection and approval-gated remediation of overshared items.'
    }
)

$package = [ordered]@{
    metadata = [ordered]@{
        solution = $configuration.solution
        solutionCode = $configuration.solutionCode
        exportVersion = (Get-CopilotGovEvidenceSchemaVersion)
        exportedAt = (Get-Date).ToString('o')
        tier = $ConfigurationTier
        periodStart = $PeriodStart.ToString('yyyy-MM-dd')
        periodEnd = $PeriodEnd.ToString('yyyy-MM-dd')
    }
    summary = [ordered]@{
        overallStatus = 'partial'
        recordCount = (@($itemFindings).Count + @($riskReport).Count + @($remediationActions).Count)
        findingCount = @($itemFindings).Count
        highRiskCount = @($riskReport | Where-Object { $_.riskTier -eq 'HIGH' }).Count
        mediumRiskCount = @($riskReport | Where-Object { $_.riskTier -eq 'MEDIUM' }).Count
        lowRiskCount = @($riskReport | Where-Object { $_.riskTier -eq 'LOW' }).Count
    }
    controls = $controls
    artifacts = $artifacts
}

$packageArtifact = Write-JsonWithHash -Path (Join-Path $outputRoot '16-item-level-oversharing-scanner-evidence-package.json') -Content $package -ArtifactName 'ios-evidence-package' -ArtifactType 'evidence-package'
$validation = Test-CopilotGovEvidencePackage -Path $packageArtifact.path -ExpectedArtifacts @($configuration.evidenceOutputs)
if (-not $validation.IsValid) {
    $details = ($validation.Errors | ForEach-Object { ' - {0}' -f $_ }) -join [Environment]::NewLine
    throw ("Evidence validation failed for {0}:{1}{2}" -f $packageArtifact.path, [Environment]::NewLine, $details)
}

[pscustomobject]@{
    PackagePath = $packageArtifact.path
    PackageHash = $packageArtifact.hash
    ArtifactCount = @($artifacts).Count
    Findings = @($itemFindings).Count
    RiskScoredItems = @($riskReport).Count
    RemediationActions = @($remediationActions).Count
}
