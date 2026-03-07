#Requires -Version 7.0
<#
.SYNOPSIS
Deploys DLP Policy Governance configuration for Microsoft 365 Copilot.
.DESCRIPTION
Takes a baseline snapshot of current DLP policies scoped to Copilot workloads, writes the baseline JSON file, generates a deployment manifest, and creates connection stubs for Graph API and Exchange Online. The script does not modify DLP policies and is limited to read-only deployment artifacts that support later tenant data collection.
.PARAMETER ConfigurationTier
Governance tier to apply. Valid values are baseline, recommended, and regulated.
.PARAMETER OutputPath
Directory that receives the deployment manifest and connection stubs.
.PARAMETER BaselinePath
Path to the baseline snapshot JSON file that represents the expected Copilot DLP policy state for the selected tier.
.EXAMPLE
.\Deploy-Solution.ps1 -ConfigurationTier recommended -OutputPath ..\artifacts -BaselinePath ..\artifacts\dlp-policy-baseline.json
.NOTES
Use -WhatIf to preview file creation without writing artifacts.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter()]
    [ValidateSet('baseline', 'recommended', 'regulated')]
    [string]$ConfigurationTier = 'baseline',

    [Parameter()]
    [string]$OutputPath = (Join-Path (Split-Path $PSScriptRoot -Parent) 'artifacts'),

    [Parameter()]
    [string]$BaselinePath = (Join-Path (Join-Path (Split-Path $PSScriptRoot -Parent) 'artifacts') 'dlp-policy-baseline.json')
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

$defaultConfig = Read-JsonFile -Path (Join-Path $solutionRoot 'config\default-config.json')
$tierConfig = Read-JsonFile -Path (Join-Path $solutionRoot ("config\{0}.json" -f $ConfigurationTier))
$baselineDirectory = Split-Path -Path $BaselinePath -Parent
$connectionStubPath = Join-Path $OutputPath 'connection-stubs'
$graphStubPath = Join-Path $connectionStubPath 'graph-connection.stub.ps1'
$exchangeStubPath = Join-Path $connectionStubPath 'exchange-online-connection.stub.ps1'
$manifestPath = Join-Path $OutputPath 'deployment-manifest.json'
$policies = New-DlpPolicyTemplate -DefaultConfig $defaultConfig -TierConfig $tierConfig
$defaultMode = Get-PolicyModeValue -PolicyModes $tierConfig.policyModes -Name 'default' -Fallback 'Audit'
$highSensitivityMode = Get-PolicyModeValue -PolicyModes $tierConfig.policyModes -Name 'highSensitivity' -Fallback $defaultMode
$npiMode = Get-PolicyModeValue -PolicyModes $tierConfig.policyModes -Name 'npi' -Fallback $highSensitivityMode
$piiMode = Get-PolicyModeValue -PolicyModes $tierConfig.policyModes -Name 'pii' -Fallback $highSensitivityMode

$baselineSnapshot = [ordered]@{
    solution = '05-dlp-policy-governance'
    solutionCode = 'DPG'
    displayName = 'DLP Policy Governance for Copilot'
    tier = $ConfigurationTier
    capturedAt = (Get-Date).ToString('o')
    snapshotType = 'template'
    baselineSource = 'tier-configuration'
    controls = @('2.1', '3.10', '3.12')
    regulations = @('GLBA 501(b)', 'SEC Reg S-P', 'DORA Article 9', 'GDPR')
    copilotWorkloads = @($tierConfig.copilotWorkloads)
    monitoredSignals = @($defaultConfig.defaults.copilotSignals)
    policyModes = [ordered]@{
        default = $defaultMode
        highSensitivity = $highSensitivityMode
        npi = $npiMode
        pii = $piiMode
    }
    exceptionHandling = [ordered]@{
        approvalRequired = [bool]$tierConfig.exceptionApprovalRequired
        attestationRequired = [bool]$tierConfig.exceptionAttestationRequired
        approverRole = [string]$tierConfig.exceptionApproverRole
        policyChangeApproval = [string]$tierConfig.policyChangeApproval
    }
    evidenceRetentionDays = [int]$tierConfig.evidenceRetentionDays
    driftCheckFrequency = [string]$tierConfig.driftCheckFrequency
    notifications = [ordered]@{
        profile = [string]$tierConfig.notificationProfile
        summary = [bool]$tierConfig.summaryNotifications
    }
    policyScope = [ordered]@{
        includedGroups = @($defaultConfig.defaults.policyScope.includedGroups)
        excludedGroups = @($defaultConfig.defaults.policyScope.excludedGroups)
    }
    policies = $policies
    notes = @(
        'This baseline is a structured template for Copilot-scoped DLP policy review.',
        'Replace template values with a live Purview export when tenant connectivity is available.'
    )
}

$manifest = [ordered]@{
    solution = '05-dlp-policy-governance'
    solutionCode = 'DPG'
    displayName = 'DLP Policy Governance for Copilot'
    tier = $ConfigurationTier
    deploymentType = 'read-only'
    generatedAt = (Get-Date).ToString('o')
    outputPath = $OutputPath
    baselinePath = $BaselinePath
    dependencies = @('03-sensitivity-label-auditor')
    tierSettings = [ordered]@{
        workloads = @($tierConfig.copilotWorkloads)
        driftThreshold = [int]$tierConfig.driftThreshold
        exceptionApprovalRequired = [bool]$tierConfig.exceptionApprovalRequired
        policyModes = $tierConfig.policyModes
    }
    dataverse = [ordered]@{
        baseline = (New-CopilotGovTableName -SolutionSlug 'dpg' -Purpose 'baseline')
        finding = (New-CopilotGovTableName -SolutionSlug 'dpg' -Purpose 'finding')
        evidence = (New-CopilotGovTableName -SolutionSlug 'dpg' -Purpose 'evidence')
    }
    generatedFiles = [ordered]@{
        baseline = $BaselinePath
        manifest = $manifestPath
        graphConnectionStub = $graphStubPath
        exchangeOnlineConnectionStub = $exchangeStubPath
    }
    notes = @(
        'Deploy-Solution.ps1 does not create or change DLP policies.',
        'Use the generated connection stubs to collect live Purview data before approving the baseline.'
    )
}

$graphConnectionStub = @"
#Requires -Version 7.0
<#
.SYNOPSIS
Connects to Microsoft Graph for DLP Policy Governance data collection.
.DESCRIPTION
Template connection stub for collecting policy metadata that supports Copilot DLP baseline and drift reviews.
#>
[CmdletBinding()]
param()

Connect-MgGraph -Scopes @(
    'InformationProtectionPolicy.Read',
    'Policy.Read.All'
)
"@

$exchangeOnlineStub = @"
#Requires -Version 7.0
<#
.SYNOPSIS
Connects to Exchange Online and Security and Compliance PowerShell.
.DESCRIPTION
Template connection stub for collecting Purview DLP policy metadata in a read-only session.
#>
[CmdletBinding()]
param()

Connect-ExchangeOnline -ShowBanner:`$false
Connect-IPPSSession
"@

$result = [pscustomobject]@{
    solution = '05-dlp-policy-governance'
    tier = $ConfigurationTier
    baselinePath = $BaselinePath
    manifestPath = $manifestPath
    graphConnectionStub = $graphStubPath
    exchangeOnlineConnectionStub = $exchangeStubPath
    policyCount = $policies.Count
    outputPath = $OutputPath
}

if ($PSCmdlet.ShouldProcess('05-dlp-policy-governance', 'Write deployment artifacts')) {
    $null = New-Item -ItemType Directory -Path $OutputPath -Force
    $null = New-Item -ItemType Directory -Path $baselineDirectory -Force
    $null = New-Item -ItemType Directory -Path $connectionStubPath -Force

    $baselineSnapshot | ConvertTo-Json -Depth 10 | Set-Content -Path $BaselinePath -Encoding utf8
    $manifest | ConvertTo-Json -Depth 10 | Set-Content -Path $manifestPath -Encoding utf8
    Set-Content -Path $graphStubPath -Value $graphConnectionStub -Encoding utf8
    Set-Content -Path $exchangeStubPath -Value $exchangeOnlineStub -Encoding utf8
}

$result
