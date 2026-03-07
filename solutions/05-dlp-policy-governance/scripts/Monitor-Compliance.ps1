#Requires -Version 7.0
<#
.SYNOPSIS
Monitors DLP Policy Governance compliance posture.
.DESCRIPTION
Compares current configuration against the stored baseline, checks policy mode alignment with the selected tier, validates Copilot workload coverage, and returns drift findings for controls 2.1, 3.10, and 3.12.
.PARAMETER ConfigurationTier
Governance tier to evaluate. Valid values are baseline, recommended, and regulated.
.PARAMETER BaselinePath
Path to the stored DLP baseline JSON file.
.PARAMETER OutputPath
Directory that receives monitoring output, including `policy-drift-findings.json`.
.PARAMETER AlertOnDrift
When set, raises a warning if the drift percentage meets or exceeds the configured threshold.
.EXAMPLE
.\Monitor-Compliance.ps1 -ConfigurationTier recommended -BaselinePath ..\artifacts\dlp-policy-baseline.json -OutputPath ..\artifacts -AlertOnDrift
#>
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet('baseline', 'recommended', 'regulated')]
    [string]$ConfigurationTier = 'baseline',

    [Parameter()]
    [string]$BaselinePath = (Join-Path (Join-Path (Split-Path $PSScriptRoot -Parent) 'artifacts') 'dlp-policy-baseline.json'),

    [Parameter()]
    [string]$OutputPath = (Join-Path (Split-Path $PSScriptRoot -Parent) 'artifacts'),

    [Parameter()]
    [switch]$AlertOnDrift
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$solutionRoot = (Resolve-Path (Split-Path $PSScriptRoot -Parent)).Path
$repoRoot = (Resolve-Path (Join-Path $solutionRoot '..\..')).Path
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

function Get-NestedValue {
    [CmdletBinding()]
    param(
        [Parameter()]
        [object]$InputObject,

        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter()]
        [string]$Fallback = ''
    )

    if ($null -ne $InputObject -and $InputObject.PSObject.Properties.Name -contains $Name) {
        return [string]$InputObject.$Name
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
            exceptionHandling = [ordered]@{
                approvalRequired = [bool]$TierConfig.exceptionApprovalRequired
                attestationRequired = [bool]$TierConfig.exceptionAttestationRequired
                approverRole = [string]$TierConfig.exceptionApproverRole
                policyChangeApproval = [string]$TierConfig.policyChangeApproval
            }
        }
    }

    return $templates
}

$script:findings = [System.Collections.Generic.List[object]]::new()

function Add-Finding {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ControlId,

        [Parameter(Mandatory)]
        [string]$Category,

        [Parameter(Mandatory)]
        [ValidateSet('added', 'removed', 'modified')]
        [string]$ChangeType,

        [Parameter(Mandatory)]
        [ValidateSet('low', 'medium', 'high')]
        [string]$Severity,

        [Parameter(Mandatory)]
        [string]$Message,

        [Parameter()]
        $BaselineValue,

        [Parameter()]
        $CurrentValue
    )

    $findingIndex = $script:findings.Count + 1
    $script:findings.Add([pscustomobject]@{
        findingId = ('DPG-{0:D3}' -f $findingIndex)
        solution = '05-dlp-policy-governance'
        tier = $ConfigurationTier
        controlId = $ControlId
        category = $Category
        changeType = $ChangeType
        severity = $Severity
        detectedAt = (Get-Date).ToString('o')
        message = $Message
        baselineValue = $BaselineValue
        currentValue = $CurrentValue
    })
}

$defaultConfig = Read-JsonFile -Path (Join-Path $solutionRoot 'config\default-config.json')
$tierConfig = Read-JsonFile -Path (Join-Path $solutionRoot ("config\{0}.json" -f $ConfigurationTier))
$expectedPolicies = New-DlpPolicyTemplate -DefaultConfig $defaultConfig -TierConfig $tierConfig
$expectedWorkloads = @($tierConfig.copilotWorkloads)
$threshold = if ($tierConfig.PSObject.Properties.Name -contains 'driftThreshold') { [double]$tierConfig.driftThreshold } else { [double]$defaultConfig.defaults.driftThreshold }
$baseline = $null

if (Test-Path -Path $BaselinePath) {
    $baseline = Read-JsonFile -Path $BaselinePath
} else {
    Add-Finding -ControlId '3.10' -Category 'baseline' -ChangeType 'removed' -Severity 'high' -Message 'No approved baseline exists for drift comparison.' -BaselineValue $BaselinePath -CurrentValue $null
}

$baselinePolicies = if ($null -ne $baseline) { ConvertTo-Array -InputObject $baseline.policies } else { @() }
$actualWorkloads = @($baselinePolicies | ForEach-Object { [string]$_.workload } | Sort-Object -Unique)

if ($null -ne $baseline) {
    if ([string]$baseline.solution -ne '05-dlp-policy-governance') {
        Add-Finding -ControlId '3.10' -Category 'baselineMetadata' -ChangeType 'modified' -Severity 'medium' -Message 'The baseline file does not belong to Solution 05.' -BaselineValue $baseline.solution -CurrentValue '05-dlp-policy-governance'
    }

    if ([string]$baseline.tier -ne $ConfigurationTier) {
        Add-Finding -ControlId '3.10' -Category 'baselineTier' -ChangeType 'modified' -Severity 'medium' -Message 'The baseline tier does not match the selected monitoring tier.' -BaselineValue $baseline.tier -CurrentValue $ConfigurationTier
    }
}

foreach ($workload in $expectedWorkloads) {
    if ($workload -notin $actualWorkloads) {
        Add-Finding -ControlId '2.1' -Category 'workloadCoverage' -ChangeType 'removed' -Severity 'high' -Message "Expected workload $workload is missing from the baseline snapshot." -BaselineValue $workload -CurrentValue $null
    }
}

foreach ($workload in $actualWorkloads) {
    if ($workload -notin $expectedWorkloads) {
        Add-Finding -ControlId '2.1' -Category 'workloadCoverage' -ChangeType 'added' -Severity 'medium' -Message "Baseline snapshot contains workload $workload that is outside the selected tier definition." -BaselineValue $null -CurrentValue $workload
    }
}

$expectedPolicyMap = @{}
foreach ($policy in $expectedPolicies) {
    $expectedPolicyMap[[string]$policy.workload] = $policy
}

$baselinePolicyMap = @{}
foreach ($policy in $baselinePolicies) {
    $baselinePolicyMap[[string]$policy.workload] = $policy
}

foreach ($workload in $expectedWorkloads) {
    if (-not $baselinePolicyMap.ContainsKey($workload)) {
        continue
    }

    $expectedPolicy = $expectedPolicyMap[$workload]
    $actualPolicy = $baselinePolicyMap[$workload]

    if ([string]$actualPolicy.mode -ne [string]$expectedPolicy.mode) {
        Add-Finding -ControlId '2.1' -Category 'policyMode' -ChangeType 'modified' -Severity 'medium' -Message "Workload $workload uses mode $($actualPolicy.mode) instead of expected mode $($expectedPolicy.mode)." -BaselineValue $actualPolicy.mode -CurrentValue $expectedPolicy.mode
    }

    if ([string]$actualPolicy.highSensitivityMode -ne [string]$expectedPolicy.highSensitivityMode) {
        Add-Finding -ControlId '2.1' -Category 'highSensitivityMode' -ChangeType 'modified' -Severity 'medium' -Message "Workload $workload does not align to the expected high-sensitivity policy mode." -BaselineValue $actualPolicy.highSensitivityMode -CurrentValue $expectedPolicy.highSensitivityMode
    }

    $actualNpiMode = Get-NestedValue -InputObject $actualPolicy.labelSpecificModes -Name 'NPI' -Fallback $actualPolicy.highSensitivityMode
    $expectedNpiMode = Get-NestedValue -InputObject $expectedPolicy.labelSpecificModes -Name 'NPI' -Fallback $expectedPolicy.highSensitivityMode
    if ($actualNpiMode -ne $expectedNpiMode) {
        Add-Finding -ControlId '2.1' -Category 'npiMode' -ChangeType 'modified' -Severity 'medium' -Message "Workload $workload does not align to the expected NPI handling mode." -BaselineValue $actualNpiMode -CurrentValue $expectedNpiMode
    }

    $actualPiiMode = Get-NestedValue -InputObject $actualPolicy.labelSpecificModes -Name 'PII' -Fallback $actualPolicy.highSensitivityMode
    $expectedPiiMode = Get-NestedValue -InputObject $expectedPolicy.labelSpecificModes -Name 'PII' -Fallback $expectedPolicy.highSensitivityMode
    if ($actualPiiMode -ne $expectedPiiMode) {
        Add-Finding -ControlId '2.1' -Category 'piiMode' -ChangeType 'modified' -Severity 'medium' -Message "Workload $workload does not align to the expected PII handling mode." -BaselineValue $actualPiiMode -CurrentValue $expectedPiiMode
    }
}

if ($null -ne $baseline) {
    $baselineApprovalRequired = [bool]$baseline.exceptionHandling.approvalRequired
    if ($baselineApprovalRequired -ne [bool]$tierConfig.exceptionApprovalRequired) {
        Add-Finding -ControlId '3.12' -Category 'exceptionHandling' -ChangeType 'modified' -Severity 'medium' -Message 'Baseline exception approval settings do not match the selected tier.' -BaselineValue $baselineApprovalRequired -CurrentValue ([bool]$tierConfig.exceptionApprovalRequired)
    }

    $baselineApproverRole = [string]$baseline.exceptionHandling.approverRole
    if ($baselineApproverRole -ne [string]$tierConfig.exceptionApproverRole) {
        Add-Finding -ControlId '3.12' -Category 'approverRole' -ChangeType 'modified' -Severity 'medium' -Message 'Baseline approver role does not match the selected tier.' -BaselineValue $baselineApproverRole -CurrentValue ([string]$tierConfig.exceptionApproverRole)
    }
}

$exceptionLogPath = Join-Path $OutputPath 'exception-attestations.json'
$exceptionRecords = ConvertTo-Array -InputObject (Read-JsonData -Path $exceptionLogPath)
if ([bool]$tierConfig.exceptionApprovalRequired -and -not (Test-Path -Path $exceptionLogPath)) {
    Add-Finding -ControlId '3.12' -Category 'exceptionLog' -ChangeType 'removed' -Severity 'medium' -Message 'Exception approval is required for this tier but exception-attestations.json is missing.' -BaselineValue $exceptionLogPath -CurrentValue $null
}

foreach ($record in $exceptionRecords) {
    $missingFields = @()
    if (($record.PSObject.Properties.Name -notcontains 'attestor') -or [string]::IsNullOrWhiteSpace([string]$record.attestor)) {
        $missingFields += 'attestor'
    }
    if (($record.PSObject.Properties.Name -notcontains 'approvedOn') -or [string]::IsNullOrWhiteSpace([string]$record.approvedOn)) {
        $missingFields += 'approvedOn'
    }
    if (($record.PSObject.Properties.Name -notcontains 'justification') -or [string]::IsNullOrWhiteSpace([string]$record.justification)) {
        $missingFields += 'justification'
    }
    if (($record.PSObject.Properties.Name -notcontains 'expiresOn') -or [string]::IsNullOrWhiteSpace([string]$record.expiresOn)) {
        $missingFields += 'expiresOn'
    }

    if ($missingFields.Count -gt 0) {
        Add-Finding -ControlId '3.12' -Category 'attestationRecord' -ChangeType 'modified' -Severity 'low' -Message ('An exception attestation record is missing the following fields: {0}.' -f ($missingFields -join ', ')) -BaselineValue $null -CurrentValue $missingFields
    }
}

$findingsArray = @($script:findings)
$expectedPolicyCount = [math]::Max($expectedPolicies.Count, 1)
$driftPercentage = [math]::Round(($findingsArray.Count / $expectedPolicyCount) * 100, 2)
$alertRaised = $AlertOnDrift.IsPresent -and ($findingsArray.Count -gt 0) -and ($driftPercentage -ge $threshold)
$null = New-Item -ItemType Directory -Path $OutputPath -Force
$findingsPath = Join-Path $OutputPath 'policy-drift-findings.json'
$summaryPath = Join-Path $OutputPath 'monitor-compliance.json'
ConvertTo-Json -InputObject $findingsArray -Depth 10 | Set-Content -Path $findingsPath -Encoding utf8

$control21Findings = @($findingsArray | Where-Object { $_.controlId -eq '2.1' })
$control310Findings = @($findingsArray | Where-Object { $_.controlId -eq '3.10' })
$control312Findings = @($findingsArray | Where-Object { $_.controlId -eq '3.12' })

$control21Status = if (($control21Findings.Count -eq 0) -and ($null -ne $baseline)) { 'monitor-only' } else { 'partial' }
$control310Status = if (($control310Findings.Count -eq 0) -and ($null -ne $baseline)) { 'implemented' } else { 'partial' }
$control312Status = if ($control312Findings.Count -eq 0) { 'implemented' } else { 'partial' }
$overallStatus = if (($findingsArray.Count -eq 0) -and ($null -ne $baseline)) { 'implemented' } else { 'partial' }

$controls = @(
    [pscustomobject]@{
        controlId = '2.1'
        status = $control21Status
        score = Get-CopilotGovStatusScore -Status $control21Status
        notes = 'Validated Copilot workload coverage and tier-specific DLP policy mode alignment.'
    },
    [pscustomobject]@{
        controlId = '3.10'
        status = $control310Status
        score = Get-CopilotGovStatusScore -Status $control310Status
        notes = 'Generated drift findings from the selected baseline and tier comparison.'
    },
    [pscustomobject]@{
        controlId = '3.12'
        status = $control312Status
        score = Get-CopilotGovStatusScore -Status $control312Status
        notes = 'Validated exception approval and attestation prerequisites for the selected tier.'
    }
)

$result = [ordered]@{
    solution = '05-dlp-policy-governance'
    solutionCode = 'DPG'
    tier = $ConfigurationTier
    evaluatedAt = (Get-Date).ToString('o')
    baselinePath = $BaselinePath
    findingsPath = $findingsPath
    monitorSummaryPath = $summaryPath
    baselinePresent = [bool]($null -ne $baseline)
    expectedWorkloads = $expectedWorkloads
    actualWorkloads = $actualWorkloads
    findingCount = $findingsArray.Count
    driftThreshold = $threshold
    driftPercentage = $driftPercentage
    alertRaised = $alertRaised
    overallStatus = $overallStatus
    controls = $controls
}

$result | ConvertTo-Json -Depth 10 | Set-Content -Path $summaryPath -Encoding utf8

if ($alertRaised) {
    Write-Warning ('Drift threshold exceeded. Finding count: {0}. Drift percentage: {1}.' -f $findingsArray.Count, $driftPercentage)
}

[pscustomobject]$result

