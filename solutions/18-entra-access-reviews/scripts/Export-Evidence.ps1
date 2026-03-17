<#
.SYNOPSIS
Exports evidence for the Entra Access Reviews Automation solution.

.DESCRIPTION
Collects access review definitions, review decisions, and applied actions,
packages them into the shared evidence schema format, and writes SHA-256
checksum files for each JSON output.

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
.\Export-Evidence.ps1 -ConfigurationTier regulated -TenantId 00000000-0000-0000-0000-000000000000 -OutputPath .\artifacts\evidence
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
    [datetime]$PeriodStart = ((Get-Date).Date.AddDays(-30)),

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
$outputRoot = [System.IO.Path]::GetFullPath($OutputPath)
$null = New-Item -Path $outputRoot -ItemType Directory -Force

$now = Get-Date

$reviewDefinitions = @(
    [pscustomobject]@{
        reviewDefinitionId = 'ear-site-001-review'
        siteUrl = 'https://contoso.sharepoint.com/sites/TradingDesk'
        riskTier = 'HIGH'
        reviewFrequencyDays = 30
        reviewDurationDays = 7
        reviewer = 'trading-desk-owner@contoso.com'
        scope = 'site-members-and-guests'
        createdAt = $now.AddDays(-30).ToString('o')
        reportingPeriodStart = $PeriodStart.ToString('yyyy-MM-dd')
        reportingPeriodEnd = $PeriodEnd.ToString('yyyy-MM-dd')
    }
    [pscustomobject]@{
        reviewDefinitionId = 'ear-site-002-review'
        siteUrl = 'https://contoso.sharepoint.com/sites/CustomerPII'
        riskTier = 'HIGH'
        reviewFrequencyDays = 30
        reviewDurationDays = 7
        reviewer = 'pii-owner@contoso.com'
        scope = 'site-members-and-guests'
        createdAt = $now.AddDays(-30).ToString('o')
        reportingPeriodStart = $PeriodStart.ToString('yyyy-MM-dd')
        reportingPeriodEnd = $PeriodEnd.ToString('yyyy-MM-dd')
    }
    [pscustomobject]@{
        reviewDefinitionId = 'ear-site-003-review'
        siteUrl = 'https://contoso.sharepoint.com/sites/ComplianceDocs'
        riskTier = 'MEDIUM'
        reviewFrequencyDays = 90
        reviewDurationDays = 14
        reviewer = 'compliance-lead@contoso.com'
        scope = 'site-members-and-guests'
        createdAt = $now.AddDays(-60).ToString('o')
        reportingPeriodStart = $PeriodStart.ToString('yyyy-MM-dd')
        reportingPeriodEnd = $PeriodEnd.ToString('yyyy-MM-dd')
    }
)

$reviewDecisions = @(
    [pscustomobject]@{
        reviewDefinitionId = 'ear-site-001-review'
        instanceId = 'instance-001'
        decisionId = 'decision-001'
        userId = 'user-001'
        userDisplayName = 'Jane Doe'
        decision = 'Approve'
        reviewedBy = 'trading-desk-owner@contoso.com'
        reviewedAt = $now.AddDays(-5).ToString('o')
        justification = 'User requires continued access for trading operations.'
    }
    [pscustomobject]@{
        reviewDefinitionId = 'ear-site-001-review'
        instanceId = 'instance-001'
        decisionId = 'decision-002'
        userId = 'user-002'
        userDisplayName = 'External Contractor'
        decision = 'Deny'
        reviewedBy = 'trading-desk-owner@contoso.com'
        reviewedAt = $now.AddDays(-4).ToString('o')
        justification = 'Contractor engagement ended. Access no longer required.'
    }
)

$appliedActions = @(
    [pscustomobject]@{
        reviewDefinitionId = 'ear-site-001-review'
        instanceId = 'instance-001'
        userId = 'user-002'
        action = 'remove-access'
        appliedAt = $now.AddDays(-3).ToString('o')
        appliedBy = 'system-automation'
        siteUrl = 'https://contoso.sharepoint.com/sites/TradingDesk'
        notes = 'Deny decision applied. User removed from site members.'
    }
)

$artifacts = @()
$artifacts += Write-JsonWithHash -Path (Join-Path $outputRoot 'access-review-definitions.json') -Content @($reviewDefinitions) -ArtifactName 'access-review-definitions' -ArtifactType 'access-review-definitions'
$artifacts += Write-JsonWithHash -Path (Join-Path $outputRoot 'review-decisions.json') -Content @($reviewDecisions) -ArtifactName 'review-decisions' -ArtifactType 'review-decisions'
$artifacts += Write-JsonWithHash -Path (Join-Path $outputRoot 'applied-actions.json') -Content @($appliedActions) -ArtifactName 'applied-actions' -ArtifactType 'applied-actions'

$controls = @(
    [pscustomobject]@{
        controlId = '1.2'
        status = 'partial'
        notes = 'Access review definitions are created but tenant-specific API integration requires further implementation.'
    }
    [pscustomobject]@{
        controlId = '1.6'
        status = 'monitor-only'
        notes = 'Permission model audits are supported through scheduled access reviews but not enforced directly by this script.'
    }
    [pscustomobject]@{
        controlId = '2.5'
        status = 'monitor-only'
        notes = 'Data minimization is supported by removing unnecessary access through deny decisions.'
    }
    [pscustomobject]@{
        controlId = '2.12'
        status = 'partial'
        notes = 'Guest and external user access is included in review scope for periodic recertification.'
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
        recordCount = (@($reviewDefinitions).Count + @($reviewDecisions).Count + @($appliedActions).Count)
        definitionCount = @($reviewDefinitions).Count
        decisionCount = @($reviewDecisions).Count
        actionCount = @($appliedActions).Count
    }
    controls = $controls
    artifacts = $artifacts
}

$packageArtifact = Write-JsonWithHash -Path (Join-Path $outputRoot '18-entra-access-reviews-evidence-package.json') -Content $package -ArtifactName 'ear-evidence-package' -ArtifactType 'evidence-package'
$validation = Test-CopilotGovEvidencePackage -Path $packageArtifact.path -ExpectedArtifacts @($configuration.evidenceOutputs)
if (-not $validation.IsValid) {
    $details = ($validation.Errors | ForEach-Object { ' - {0}' -f $_ }) -join [Environment]::NewLine
    throw ("Evidence validation failed for {0}:{1}{2}" -f $packageArtifact.path, [Environment]::NewLine, $details)
}

[pscustomobject]@{
    PackagePath = $packageArtifact.path
    PackageHash = $packageArtifact.hash
    ArtifactCount = @($artifacts).Count
    Definitions = @($reviewDefinitions).Count
    Decisions = @($reviewDecisions).Count
    Actions = @($appliedActions).Count
}
