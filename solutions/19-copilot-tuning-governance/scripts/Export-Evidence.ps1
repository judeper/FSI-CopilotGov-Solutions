<#
.SYNOPSIS
Exports evidence for the Copilot Tuning Governance solution.

.DESCRIPTION
Collects tuning requests, model inventory, and risk assessments, packages them
into the shared evidence schema format, and writes SHA-256 checksum files for
each JSON output. Uses representative sample data and does not connect to live
Microsoft 365 services.

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

Import-Module (Join-Path $PSScriptRoot '..\..\..\scripts\common\EvidenceExport.psm1') -Force
Import-Module (Join-Path $PSScriptRoot '..\..\..\scripts\common\IntegrationConfig.psm1') -Force

function Get-SchemaVersion {
    if (Get-Command -Name Get-CopilotGovEvidenceSchemaVersion -ErrorAction SilentlyContinue) {
        return (Get-CopilotGovEvidenceSchemaVersion)
    }
    return '1.1.0'
}

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

$tuningRequests = @(
    [pscustomobject]@{
        requestId = 'ctg-req-001'
        requestedBy = 'capital-markets-lead@contoso.com'
        businessUnit = 'Capital Markets'
        sourceDataDescription = 'Trading desk communications and market analysis reports'
        dataClassification = 'Confidential'
        intendedUse = 'Automated trading desk assistant for internal market research summarization'
        approvalStatus = 'approved'
        approvedBy = 'model-risk-officer@contoso.com'
        submittedAt = $now.AddDays(-45).ToString('o')
        reportingPeriodStart = $PeriodStart.ToString('yyyy-MM-dd')
        reportingPeriodEnd = $PeriodEnd.ToString('yyyy-MM-dd')
    }
    [pscustomobject]@{
        requestId = 'ctg-req-002'
        requestedBy = 'wm-operations@contoso.com'
        businessUnit = 'Wealth Management'
        sourceDataDescription = 'Client onboarding procedures and KYC documentation templates'
        dataClassification = 'Highly Confidential'
        intendedUse = 'Client onboarding workflow assistant for relationship managers'
        approvalStatus = 'approved'
        approvedBy = 'model-risk-officer@contoso.com'
        submittedAt = $now.AddDays(-30).ToString('o')
        reportingPeriodStart = $PeriodStart.ToString('yyyy-MM-dd')
        reportingPeriodEnd = $PeriodEnd.ToString('yyyy-MM-dd')
    }
    [pscustomobject]@{
        requestId = 'ctg-req-003'
        requestedBy = 'compliance-lead@contoso.com'
        businessUnit = 'Legal and Compliance'
        sourceDataDescription = 'Regulatory guidance documents and compliance research'
        dataClassification = 'Confidential'
        intendedUse = 'Compliance research agent for regulatory analysis'
        approvalStatus = 'pending'
        approvedBy = $null
        submittedAt = $now.AddDays(-5).ToString('o')
        reportingPeriodStart = $PeriodStart.ToString('yyyy-MM-dd')
        reportingPeriodEnd = $PeriodEnd.ToString('yyyy-MM-dd')
    }
)

$modelInventory = @(
    [pscustomobject]@{
        modelId = 'ctg-model-001'
        modelName = 'Trading Desk Assistant'
        status = 'active'
        owner = 'capital-markets-lead@contoso.com'
        businessUnit = 'Capital Markets'
        createdAt = $now.AddDays(-40).ToString('o')
        lastReassessmentDate = $now.AddDays(-20).ToString('yyyy-MM-dd')
        nextReassessmentDate = $now.AddDays(70).ToString('yyyy-MM-dd')
    }
    [pscustomobject]@{
        modelId = 'ctg-model-002'
        modelName = 'Client Onboarding Helper'
        status = 'active'
        owner = 'wm-operations@contoso.com'
        businessUnit = 'Wealth Management'
        createdAt = $now.AddDays(-25).ToString('o')
        lastReassessmentDate = $now.AddDays(-85).ToString('yyyy-MM-dd')
        nextReassessmentDate = $now.AddDays(5).ToString('yyyy-MM-dd')
    }
    [pscustomobject]@{
        modelId = 'ctg-model-004'
        modelName = 'HR Policy Assistant'
        status = 'deprecated'
        owner = 'hr-tech@contoso.com'
        businessUnit = 'Human Resources'
        createdAt = $now.AddDays(-180).ToString('o')
        lastReassessmentDate = $now.AddDays(-120).ToString('yyyy-MM-dd')
        nextReassessmentDate = $null
    }
)

$riskAssessments = @(
    [pscustomobject]@{
        assessmentId = 'ctg-ra-001'
        modelId = 'ctg-model-001'
        assessedBy = 'model-risk-officer@contoso.com'
        assessmentDate = $now.AddDays(-20).ToString('yyyy-MM-dd')
        riskLevel = 'high'
        dataRiskFactors = 'Source data contains trading communications subject to FINRA supervision requirements.'
        modelRiskFactors = 'Tuned model may surface non-public information if access controls are not properly scoped.'
        outcome = 'approved-with-conditions'
        notes = 'Approved with requirement for quarterly reassessment and restricted audience scope.'
    }
    [pscustomobject]@{
        assessmentId = 'ctg-ra-002'
        modelId = 'ctg-model-002'
        assessedBy = 'model-risk-officer@contoso.com'
        assessmentDate = $now.AddDays(-85).ToString('yyyy-MM-dd')
        riskLevel = 'medium'
        dataRiskFactors = 'Source data includes KYC templates with PII field patterns.'
        modelRiskFactors = 'Tuned model should not reproduce client-specific PII in responses.'
        outcome = 'approved'
        notes = 'Approved for wealth management relationship managers only.'
    }
)

$artifacts = @()
$artifacts += Write-JsonWithHash -Path (Join-Path $outputRoot 'tuning-requests.json') -Content @($tuningRequests) -ArtifactName 'tuning-requests' -ArtifactType 'tuning-requests'
$artifacts += Write-JsonWithHash -Path (Join-Path $outputRoot 'model-inventory.json') -Content @($modelInventory) -ArtifactName 'model-inventory' -ArtifactType 'model-inventory'
$artifacts += Write-JsonWithHash -Path (Join-Path $outputRoot 'risk-assessments.json') -Content @($riskAssessments) -ArtifactName 'risk-assessments' -ArtifactType 'risk-assessments'

$controls = @(
    [pscustomobject]@{
        controlId = '1.16'
        status = 'partial'
        notes = 'Tuning governance patterns are documented but tenant-specific integration with supported Microsoft 365 admin center or Agent 365 experiences requires further implementation.'
    }
    [pscustomobject]@{
        controlId = '3.8'
        status = 'monitor-only'
        notes = 'Model risk management is supported through risk assessment patterns but not enforced directly by this script.'
    }
)

$package = [ordered]@{
    metadata = [ordered]@{
        solution = $configuration.solution
        solutionCode = $configuration.solutionCode
        exportVersion = (Get-SchemaVersion)
        exportedAt = (Get-Date).ToString('o')
        tier = $ConfigurationTier
        periodStart = $PeriodStart.ToString('yyyy-MM-dd')
        periodEnd = $PeriodEnd.ToString('yyyy-MM-dd')
    }
    summary = [ordered]@{
        overallStatus = 'partial'
        recordCount = (@($tuningRequests).Count + @($modelInventory).Count + @($riskAssessments).Count)
        tuningRequestCount = @($tuningRequests).Count
        modelInventoryCount = @($modelInventory).Count
        riskAssessmentCount = @($riskAssessments).Count
    }
    controls = $controls
    artifacts = $artifacts
}

$packageArtifact = Write-JsonWithHash -Path (Join-Path $outputRoot '19-copilot-tuning-governance-evidence-package.json') -Content $package -ArtifactName 'ctg-evidence-package' -ArtifactType 'evidence-package'
$validation = Test-CopilotGovEvidencePackage -Path $packageArtifact.path -ExpectedArtifacts @($configuration.evidenceOutputs)
if (-not $validation.IsValid) {
    $details = ($validation.Errors | ForEach-Object { ' - {0}' -f $_ }) -join [Environment]::NewLine
    throw ("Evidence validation failed for {0}:{1}{2}" -f $packageArtifact.path, [Environment]::NewLine, $details)
}

[pscustomobject]@{
    PackagePath = $packageArtifact.path
    PackageHash = $packageArtifact.hash
    ArtifactCount = @($artifacts).Count
    TuningRequests = @($tuningRequests).Count
    ModelInventory = @($modelInventory).Count
    RiskAssessments = @($riskAssessments).Count
}
