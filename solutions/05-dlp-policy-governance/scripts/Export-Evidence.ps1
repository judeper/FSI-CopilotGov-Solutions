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
. (Join-Path $PSScriptRoot 'Common-Functions.ps1')

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
        regulations = @('GLBA 501(b)', 'SEC Reg S-P', 'DORA Article 9', 'GDPR', 'FINRA 4511', 'SOX 302/404')
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
            seniorComplianceSignOffRequired = if ($TierConfig.PSObject.Properties.Name -contains 'seniorComplianceSignOffRequired') { [bool]$TierConfig.seniorComplianceSignOffRequired } else { $false }
            mandatoryAttestation = if ($TierConfig.PSObject.Properties.Name -contains 'mandatoryAttestation') { [bool]$TierConfig.mandatoryAttestation } else { $false }
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

    $result = Write-CopilotGovSha256File -Path $Path
    return $result.Hash
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
$allExceptionData = ConvertTo-Array -InputObject (Read-JsonData -Path $exceptionArtifactPath)

# Filter exception records to the specified reporting period
$exceptionData = @($allExceptionData | Where-Object {
    if ($_.PSObject.Properties.Name -contains 'approvedOn' -and -not [string]::IsNullOrWhiteSpace([string]$_.approvedOn)) {
        try {
            $approvedDate = [datetime]::Parse([string]$_.approvedOn)
            $approvedDate.Date -ge $PeriodStart.Date -and $approvedDate.Date -le $PeriodEnd.Date
        } catch {
            $true  # Include records with unparseable dates so they surface in evidence
        }
    } else {
        $true  # Include records without dates so they surface for review
    }
})
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
    -Artifacts $artifacts `
    -AdditionalMetadata @{
        periodStart = $PeriodStart.ToString('yyyy-MM-dd')
        periodEnd = $PeriodEnd.ToString('yyyy-MM-dd')
    }

[pscustomobject]@{
    evidencePackagePath = $packageResult.Path
    evidencePackageHash = $packageResult.Hash
    baselineArtifact = $baselineArtifactPath
    driftArtifact = $driftArtifactPath
    exceptionArtifact = $exceptionArtifactPath
    summary = $summary
    monitoringStatus = $monitorResult.overallStatus
}

