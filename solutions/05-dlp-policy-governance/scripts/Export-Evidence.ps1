#Requires -Version 7.0
<#
.SYNOPSIS
Exports DLP Policy Governance evidence package.
.DESCRIPTION
Assembles `dlp-policy-baseline`, `policy-drift-findings`, and `exception-attestations` artifacts, writes SHA-256 companions, and produces a solution evidence package aligned to `data\evidence-schema.json`.
.PARAMETER ConfigurationTier
Governance tier to export. Valid values are baseline, recommended, and regulated.
.PARAMETER OutputPath
Directory that receives the evidence artifacts and package.
.PARAMETER PeriodStart
Start date for the evidence reporting period.
.PARAMETER PeriodEnd
End date for the evidence reporting period.
.EXAMPLE
.\Export-Evidence.ps1 -ConfigurationTier recommended -OutputPath ..\artifacts -PeriodStart 2026-01-01 -PeriodEnd 2026-01-31
#>
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet('baseline', 'recommended', 'regulated')]
    [string]$ConfigurationTier = 'baseline',

    [Parameter()]
    [string]$OutputPath = (Join-Path (Split-Path $PSScriptRoot -Parent) 'artifacts'),

    [Parameter()]
    [datetime]$PeriodStart = (Get-Date).Date.AddDays(-30),

    [Parameter()]
    [datetime]$PeriodEnd = (Get-Date).Date
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($PeriodStart.Date -gt $PeriodEnd.Date) {
    throw 'PeriodStart must be less than or equal to PeriodEnd.'
}

$solutionRoot = (Resolve-Path (Split-Path $PSScriptRoot -Parent)).Path
$repoRoot = (Resolve-Path (Join-Path $solutionRoot '..\..')).Path
Import-Module (Join-Path $repoRoot 'scripts\common\EvidenceExport.psm1') -Force
Import-Module (Join-Path $repoRoot 'scripts\common\IntegrationConfig.psm1') -Force

function Read-JsonFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not (Test-Path -Path $Path)) {
        throw "JSON file not found: $Path"
    }

    $rawContent = Get-Content -Path $Path -Raw
    if ([string]::IsNullOrWhiteSpace($rawContent)) {
        throw "JSON file is empty: $Path"
    }

    return $rawContent | ConvertFrom-Json -Depth 32
}

function Read-JsonData {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not (Test-Path -Path $Path)) {
        return $null
    }

    $rawContent = Get-Content -Path $Path -Raw
    if ([string]::IsNullOrWhiteSpace($rawContent)) {
        return $null
    }

    return $rawContent | ConvertFrom-Json -Depth 32
}

function ConvertTo-Array {
    [CmdletBinding()]
    param(
        [Parameter()]
        $InputObject
    )

    if ($null -eq $InputObject) {
        Write-Output -NoEnumerate @()
        return
    }

    if ($InputObject -is [System.Array]) {
        Write-Output -NoEnumerate @($InputObject)
        return
    }

    if ($InputObject -is [System.Collections.IEnumerable] -and -not ($InputObject -is [string])) {
        Write-Output -NoEnumerate @($InputObject)
        return
    }

    Write-Output -NoEnumerate @($InputObject)
}

function Get-PolicyModeValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$PolicyModes,

        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter()]
        [string]$Fallback = 'Audit'
    )

    if ($null -ne $PolicyModes -and $PolicyModes.PSObject.Properties.Name -contains $Name) {
        return [string]$PolicyModes.$Name
    }

    return $Fallback
}

function New-DlpPolicyTemplate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$DefaultConfig,

        [Parameter(Mandatory)]
        [object]$TierConfig
    )

    $defaultMode = Get-PolicyModeValue -PolicyModes $TierConfig.policyModes -Name 'default' -Fallback 'Audit'
    $highSensitivityMode = Get-PolicyModeValue -PolicyModes $TierConfig.policyModes -Name 'highSensitivity' -Fallback $defaultMode
    $npiMode = Get-PolicyModeValue -PolicyModes $TierConfig.policyModes -Name 'npi' -Fallback $highSensitivityMode
    $piiMode = Get-PolicyModeValue -PolicyModes $TierConfig.policyModes -Name 'pii' -Fallback $highSensitivityMode

    $templates = foreach ($workload in @($TierConfig.copilotWorkloads)) {
        [ordered]@{
            policyName = "Copilot DLP - $workload - $($TierConfig.tier)"
            workload = [string]$workload
            mode = $defaultMode
            highSensitivityMode = $highSensitivityMode
            labelSpecificModes = [ordered]@{
                NPI = $npiMode
                PII = $piiMode
            }
            sensitivityConditions = [ordered]@{
                standard = @($TierConfig.sensitivityConditions.standard)
                highSensitivity = @($TierConfig.sensitivityConditions.highSensitivity)
            }
            scope = [ordered]@{
                includedGroups = @($DefaultConfig.defaults.policyScope.includedGroups)
                excludedGroups = @($DefaultConfig.defaults.policyScope.excludedGroups)
            }
            monitoredSignals = @($DefaultConfig.defaults.copilotSignals)
            exceptionHandling = [ordered]@{
                approvalRequired = [bool]$TierConfig.exceptionApprovalRequired
                attestationRequired = [bool]$TierConfig.exceptionAttestationRequired
                approverRole = [string]$TierConfig.exceptionApproverRole
                policyChangeApproval = [string]$TierConfig.policyChangeApproval
            }
            evidenceRetentionDays = [int]$TierConfig.evidenceRetentionDays
            driftCheckFrequency = [string]$TierConfig.driftCheckFrequency
        }
    }

    return $templates
}

function New-BaselineSnapshot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Tier,

        [Parameter(Mandatory)]
        [object]$DefaultConfig,

        [Parameter(Mandatory)]
        [object]$TierConfig
    )

    $defaultMode = Get-PolicyModeValue -PolicyModes $TierConfig.policyModes -Name 'default' -Fallback 'Audit'
    $highSensitivityMode = Get-PolicyModeValue -PolicyModes $TierConfig.policyModes -Name 'highSensitivity' -Fallback $defaultMode
    $npiMode = Get-PolicyModeValue -PolicyModes $TierConfig.policyModes -Name 'npi' -Fallback $highSensitivityMode
    $piiMode = Get-PolicyModeValue -PolicyModes $TierConfig.policyModes -Name 'pii' -Fallback $highSensitivityMode

    return [ordered]@{
        solution = '05-dlp-policy-governance'
        solutionCode = 'DPG'
        displayName = 'DLP Policy Governance for Copilot'
        tier = $Tier
        capturedAt = (Get-Date).ToString('o')
        snapshotType = 'template'
        baselineSource = 'evidence-export'
        controls = @('2.1', '3.10', '3.12')
        regulations = @('GLBA 501(b)', 'SEC Reg S-P', 'DORA Article 9', 'GDPR')
        copilotWorkloads = @($TierConfig.copilotWorkloads)
        monitoredSignals = @($DefaultConfig.defaults.copilotSignals)
        policyModes = [ordered]@{
            default = $defaultMode
            highSensitivity = $highSensitivityMode
            npi = $npiMode
            pii = $piiMode
        }
        exceptionHandling = [ordered]@{
            approvalRequired = [bool]$TierConfig.exceptionApprovalRequired
            attestationRequired = [bool]$TierConfig.exceptionAttestationRequired
            approverRole = [string]$TierConfig.exceptionApproverRole
            policyChangeApproval = [string]$TierConfig.policyChangeApproval
        }
        evidenceRetentionDays = [int]$TierConfig.evidenceRetentionDays
        driftCheckFrequency = [string]$TierConfig.driftCheckFrequency
        notifications = [ordered]@{
            profile = [string]$TierConfig.notificationProfile
            summary = [bool]$TierConfig.summaryNotifications
        }
        policyScope = [ordered]@{
            includedGroups = @($DefaultConfig.defaults.policyScope.includedGroups)
            excludedGroups = @($DefaultConfig.defaults.policyScope.excludedGroups)
        }
        policies = (New-DlpPolicyTemplate -DefaultConfig $DefaultConfig -TierConfig $TierConfig)
        notes = @(
            'Evidence export created a baseline template because no prior baseline artifact was found.',
            'Replace template values with a live Purview export when tenant connectivity is available.'
        )
    }
}

function Write-HashCompanion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    $hash = Get-CopilotGovSha256 -Path $Path
    Set-Content -Path ($Path + '.sha256') -Value ('{0}  {1}' -f $hash, [IO.Path]::GetFileName($Path)) -Encoding utf8
    return $hash
}

$defaultConfig = Read-JsonFile -Path (Join-Path $solutionRoot 'config\default-config.json')
$tierConfig = Read-JsonFile -Path (Join-Path $solutionRoot ("config\{0}.json" -f $ConfigurationTier))
$null = New-Item -ItemType Directory -Path $OutputPath -Force
$baselineArtifactPath = Join-Path $OutputPath 'dlp-policy-baseline.json'
$driftArtifactPath = Join-Path $OutputPath 'policy-drift-findings.json'
$exceptionArtifactPath = Join-Path $OutputPath 'exception-attestations.json'

if (-not (Test-Path -Path $baselineArtifactPath)) {
    $baselineSnapshot = New-BaselineSnapshot -Tier $ConfigurationTier -DefaultConfig $defaultConfig -TierConfig $tierConfig
    $baselineSnapshot | ConvertTo-Json -Depth 10 | Set-Content -Path $baselineArtifactPath -Encoding utf8
}

$monitorScriptPath = Join-Path $PSScriptRoot 'Monitor-Compliance.ps1'
$monitorResult = & $monitorScriptPath -ConfigurationTier $ConfigurationTier -BaselinePath $baselineArtifactPath -OutputPath $OutputPath

if (-not (Test-Path -Path $driftArtifactPath)) {
    ConvertTo-Json -InputObject @() -Depth 10 | Set-Content -Path $driftArtifactPath -Encoding utf8
}

if (-not (Test-Path -Path $exceptionArtifactPath)) {
    ConvertTo-Json -InputObject @() -Depth 10 | Set-Content -Path $exceptionArtifactPath -Encoding utf8
}

$baselineData = Read-JsonFile -Path $baselineArtifactPath
$driftData = ConvertTo-Array -InputObject (Read-JsonData -Path $driftArtifactPath)
$exceptionData = ConvertTo-Array -InputObject (Read-JsonData -Path $exceptionArtifactPath)
$baselinePolicyCount = @($baselineData.policies).Count
$workloadCount = @($baselineData.copilotWorkloads).Count

$baselineHash = Write-HashCompanion -Path $baselineArtifactPath
$driftHash = Write-HashCompanion -Path $driftArtifactPath
$exceptionHash = Write-HashCompanion -Path $exceptionArtifactPath

$control310Status = if ($driftData.Count -gt 0) { 'partial' } else { 'implemented' }
$control312Notes = if ($exceptionData.Count -eq 0) { 'No approved exceptions were recorded during the reporting period.' } else { ('Recorded {0} approved exception attestation record(s).' -f $exceptionData.Count) }

$controls = @(
    [pscustomobject]@{
        controlId = '2.1'
        status = 'monitor-only'
        notes = ('Captured {0} Copilot-scoped DLP policy record(s) across {1} workload(s).' -f $baselinePolicyCount, $workloadCount)
    },
    [pscustomobject]@{
        controlId = '3.10'
        status = $control310Status
        notes = ('Exported {0} policy drift finding(s) for the reporting period.' -f $driftData.Count)
    },
    [pscustomobject]@{
        controlId = '3.12'
        status = 'implemented'
        notes = $control312Notes
    }
)

$summary = [ordered]@{
    overallStatus = if ($driftData.Count -gt 0) { 'partial' } else { 'implemented' }
    recordCount = [int]($baselinePolicyCount + $driftData.Count + $exceptionData.Count)
    findingCount = [int]$driftData.Count
    exceptionCount = [int]$exceptionData.Count
}

$artifacts = @(
    [pscustomobject]@{
        name = 'dlp-policy-baseline'
        type = 'application/json'
        path = $baselineArtifactPath
        hash = $baselineHash
    },
    [pscustomobject]@{
        name = 'policy-drift-findings'
        type = 'application/json'
        path = $driftArtifactPath
        hash = $driftHash
    },
    [pscustomobject]@{
        name = 'exception-attestations'
        type = 'application/json'
        path = $exceptionArtifactPath
        hash = $exceptionHash
    }
)

$packageResult = Export-SolutionEvidencePackage `
    -Solution '05-dlp-policy-governance' `
    -SolutionCode 'DPG' `
    -Tier $ConfigurationTier `
    -OutputPath $OutputPath `
    -Summary $summary `
    -Controls $controls `
    -Artifacts $artifacts

$packagePath = $packageResult.Path
$package = [ordered]@{
    metadata = [ordered]@{
        solution = '05-dlp-policy-governance'
        solutionCode = 'DPG'
        exportVersion = (Get-CopilotGovEvidenceSchemaVersion)
        exportedAt = (Get-Date).ToString('o')
        tier = $ConfigurationTier
        periodStart = $PeriodStart.ToString('yyyy-MM-dd')
        periodEnd = $PeriodEnd.ToString('yyyy-MM-dd')
    }
    summary = $summary
    controls = $controls
    artifacts = $artifacts
}

$package | ConvertTo-Json -Depth 10 | Set-Content -Path $packagePath -Encoding utf8
$packageHash = Write-HashCompanion -Path $packagePath

[pscustomobject]@{
    evidencePackagePath = $packagePath
    evidencePackageHash = $packageHash
    baselineArtifact = $baselineArtifactPath
    driftArtifact = $driftArtifactPath
    exceptionArtifact = $exceptionArtifactPath
    summary = $summary
    monitoringStatus = $monitorResult.overallStatus
}

