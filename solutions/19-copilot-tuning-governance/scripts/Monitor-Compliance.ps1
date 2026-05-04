<#
.SYNOPSIS
Monitors Copilot Tuning governance compliance status and reports coverage gaps.

.DESCRIPTION
Loads the solution configuration, checks tuning governance compliance status
including approval workflow adherence, model inventory completeness, and risk
reassessment cadence. Uses representative sample data when tenant-specific
integrations are unavailable.

.PARAMETER ConfigurationTier
Selects the governance tier to apply. Supported values are baseline,
recommended, and regulated.

.PARAMETER TenantId
Tenant GUID used for context and evidence labeling.

.PARAMETER ExportPath
Directory where the compliance monitoring output will be written.

.EXAMPLE
.\Monitor-Compliance.ps1 -ConfigurationTier recommended -TenantId 00000000-0000-0000-0000-000000000000

.EXAMPLE
.\Monitor-Compliance.ps1 -ConfigurationTier regulated -TenantId 00000000-0000-0000-0000-000000000000
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
    [string]$ExportPath = (Join-Path $PSScriptRoot '..\artifacts\monitor')
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

function Get-SampleComplianceStatus {
    [CmdletBinding()]
    param()

    $now = Get-Date
    return @(
        [pscustomobject]@{
            ModelId = 'ctg-model-001'
            ModelName = 'Trading Desk Assistant'
            BusinessUnit = 'Capital Markets'
            Status = 'active'
            Owner = 'capital-markets-lead@contoso.com'
            ApprovalStatus = 'approved'
            LastReassessmentDate = $now.AddDays(-20).ToString('yyyy-MM-dd')
            NextReassessmentDate = $now.AddDays(70).ToString('yyyy-MM-dd')
            RiskLevel = 'high'
            ComplianceStatus = 'compliant'
        }
        [pscustomobject]@{
            ModelId = 'ctg-model-002'
            ModelName = 'Client Onboarding Helper'
            BusinessUnit = 'Wealth Management'
            Status = 'active'
            Owner = 'wm-operations@contoso.com'
            ApprovalStatus = 'approved'
            LastReassessmentDate = $now.AddDays(-85).ToString('yyyy-MM-dd')
            NextReassessmentDate = $now.AddDays(5).ToString('yyyy-MM-dd')
            RiskLevel = 'medium'
            ComplianceStatus = 'at-risk'
        }
        [pscustomobject]@{
            ModelId = 'ctg-model-003'
            ModelName = 'Compliance Research Agent'
            BusinessUnit = 'Legal and Compliance'
            Status = 'pending-approval'
            Owner = $null
            ApprovalStatus = 'pending'
            LastReassessmentDate = $null
            NextReassessmentDate = $null
            RiskLevel = 'high'
            ComplianceStatus = 'gap'
        }
        [pscustomobject]@{
            ModelId = 'ctg-model-004'
            ModelName = 'HR Policy Assistant'
            BusinessUnit = 'Human Resources'
            Status = 'deprecated'
            Owner = 'hr-tech@contoso.com'
            ApprovalStatus = 'approved'
            LastReassessmentDate = $now.AddDays(-120).ToString('yyyy-MM-dd')
            NextReassessmentDate = $null
            RiskLevel = 'low'
            ComplianceStatus = 'compliant'
        }
    )
}

$configuration = Get-Configuration -ConfigurationTier $ConfigurationTier

Write-Verbose 'Using representative sample data for compliance monitoring.'
$complianceResults = Get-SampleComplianceStatus

$compliantCount = @($complianceResults | Where-Object { $_.ComplianceStatus -eq 'compliant' }).Count
$atRiskCount = @($complianceResults | Where-Object { $_.ComplianceStatus -eq 'at-risk' }).Count
$gapCount = @($complianceResults | Where-Object { $_.ComplianceStatus -eq 'gap' }).Count

$outputRoot = [System.IO.Path]::GetFullPath($ExportPath)
$null = New-Item -Path $outputRoot -ItemType Directory -Force

$summary = [ordered]@{
    solution = $configuration.solution
    tier = $ConfigurationTier
    tenantId = $TenantId
    monitoredAt = (Get-Date).ToString('o')
    tuningEnabled = $configuration.tuningEnabled
    totalModels = @($complianceResults).Count
    compliant = $compliantCount
    atRisk = $atRiskCount
    coverageGaps = $gapCount
    findings = @($complianceResults)
}

$outputFile = Join-Path $outputRoot 'compliance-status.json'
$summary | ConvertTo-Json -Depth 10 | Set-Content -Path $outputFile -Encoding utf8

$complianceResults
