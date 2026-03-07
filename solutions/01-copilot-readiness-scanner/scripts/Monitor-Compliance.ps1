<#
.SYNOPSIS
Runs domain-level readiness monitoring for the Copilot Readiness Assessment Scanner.

.DESCRIPTION
Loads default and tier-specific configuration, simulates domain checks for the configured
Microsoft 365 workloads, computes tier-aware readiness scores, and optionally writes the
baseline results to disk for downstream Power BI ingestion. The script is designed as a
credible implementation stub that can be extended with live Microsoft Graph, Purview,
SharePoint, and Power Platform queries.

.PARAMETER ConfigurationTier
Specifies the governance tier to evaluate. Valid values are baseline, recommended, and regulated.

.PARAMETER TenantId
Specifies the Microsoft Entra tenant identifier used for the monitoring session.

.PARAMETER ExportPath
Specifies where monitoring baseline artifacts are written.

.PARAMETER Domains
Limits the scan to one or more of the supported domains: licensing, identity, defender,
purview, powerPlatform, and copilotConfig.

.EXAMPLE
PS> .\Monitor-Compliance.ps1 -ConfigurationTier recommended -TenantId 'contoso.onmicrosoft.com'

Runs the full recommended-tier readiness baseline and writes an export snapshot to the default artifacts folder.

.EXAMPLE
PS> .\Monitor-Compliance.ps1 -ConfigurationTier baseline -TenantId 'contoso.onmicrosoft.com' -Domains licensing,identity,purview

Runs a targeted baseline scan for the selected domains.
#>
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet('baseline', 'recommended', 'regulated')]
    [string]$ConfigurationTier = 'baseline',

    [Parameter(Mandatory)]
    [string]$TenantId,

    [Parameter()]
    [string]$ExportPath = (Join-Path $PSScriptRoot '..\artifacts'),

    [Parameter()]
    [ValidateSet('licensing', 'identity', 'defender', 'purview', 'powerPlatform', 'copilotConfig')]
    [string[]]$Domains
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:RuntimeMode = 'documentation-first'
$script:DataSourceMode = 'simulated-baseline'
$script:SimulationWarning = 'Representative sample readiness scores were emitted; no live Microsoft Graph, Purview, SharePoint, or Power Platform calls were performed.'

function Get-RepositoryRoot {
    [CmdletBinding()]
    param()

    return (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
}

function Get-SolutionRoot {
    [CmdletBinding()]
    param()

    return (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
}

function Import-SharedModule {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ModuleName
    )

    $modulePath = Join-Path (Join-Path (Get-RepositoryRoot) 'scripts\common') $ModuleName
    if (-not (Test-Path -Path $modulePath)) {
        throw "Shared module not found: $modulePath"
    }

    Import-Module $modulePath -Force
}

function Merge-Hashtable {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$Base,

        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$Overlay
    )

    $merged = [ordered]@{}

    foreach ($key in $Base.Keys) {
        $merged[$key] = $Base[$key]
    }

    foreach ($key in $Overlay.Keys) {
        if (
            $merged.Contains($key) -and
            ($merged[$key] -is [System.Collections.IDictionary]) -and
            ($Overlay[$key] -is [System.Collections.IDictionary])
        ) {
            $merged[$key] = Merge-Hashtable -Base $merged[$key] -Overlay $Overlay[$key]
        }
        else {
            $merged[$key] = $Overlay[$key]
        }
    }

    return $merged
}

function Get-SolutionConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('baseline', 'recommended', 'regulated')]
        [string]$Tier
    )

    $solutionRoot = Get-SolutionRoot
    $defaultConfigPath = Join-Path $solutionRoot 'config\default-config.json'
    $tierConfigPath = Join-Path $solutionRoot ("config\{0}.json" -f $Tier)

    if (-not (Test-Path -Path $defaultConfigPath)) {
        throw "Default configuration file not found: $defaultConfigPath"
    }

    if (-not (Test-Path -Path $tierConfigPath)) {
        throw "Tier configuration file not found: $tierConfigPath"
    }

    $defaultConfig = Get-Content -Path $defaultConfigPath -Raw | ConvertFrom-Json -AsHashtable
    $tierConfig = Get-Content -Path $tierConfigPath -Raw | ConvertFrom-Json -AsHashtable

    return (Merge-Hashtable -Base $defaultConfig -Overlay $tierConfig)
}

function Get-TierModifier {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('baseline', 'recommended', 'regulated')]
        [string]$Tier
    )

    switch ($Tier) {
        'baseline' { return 0 }
        'recommended' { return 5 }
        'regulated' { return 10 }
    }
}

function Get-DomainStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [int]$Score,

        [Parameter(Mandatory)]
        [int]$AlertThreshold
    )

    if ($Score -ge [Math]::Min(100, $AlertThreshold + 15)) {
        return 'implemented'
    }

    if ($Score -ge $AlertThreshold) {
        return 'partial'
    }

    if ($Score -ge [Math]::Max(40, $AlertThreshold - 20)) {
        return 'monitor-only'
    }

    return 'playbook-only'
}

function Resolve-ReportedStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('implemented', 'partial', 'monitor-only', 'playbook-only')]
        [string]$CandidateStatus
    )

    if ($script:DataSourceMode -eq 'simulated-baseline' -and $CandidateStatus -eq 'implemented') {
        return 'partial'
    }

    return $CandidateStatus
}

function New-DomainResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Domain,

        [Parameter(Mandatory)]
        [int]$BaseScore,

        [Parameter(Mandatory)]
        [string[]]$Issues,

        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$Configuration
    )

    $tierModifier = Get-TierModifier -Tier $Configuration.tier
    $score = [Math]::Max(0, [Math]::Min(100, $BaseScore + $tierModifier))
    $rawStatus = Get-DomainStatus -Score $score -AlertThreshold ([int]$Configuration.alertThreshold)
    $status = Resolve-ReportedStatus -CandidateStatus $rawStatus

    return [pscustomobject]@{
        Domain    = $Domain
        Score     = $score
        Status    = $status
        Issues    = $Issues
        Timestamp = (Get-Date).ToString('o')
        RuntimeMode = $script:RuntimeMode
        DataSourceMode = $script:DataSourceMode
        StatusBasis = if ($rawStatus -ne $status) { 'Implemented score downgraded to partial because the repository emitted a simulated baseline.' } else { 'Sample score mapped to the repository status vocabulary.' }
        SimulationWarning = $script:SimulationWarning
    }
}

function Invoke-LicensingScan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$Configuration,

        [Parameter(Mandatory)]
        [string]$TenantId
    )

    $issues = @(
        "Copilot assignment cohort for tenant [$TenantId] includes users without current business justification records.",
        'License plan reconciliation is modeled as a placeholder until live Graph queries are enabled.',
        'Unused Copilot-capable licenses should be reviewed against the approved rollout wave.'
    )

    return (New-DomainResult -Domain 'licensing' -BaseScore 82 -Issues $issues -Configuration $Configuration)
}

function Invoke-IdentityScan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$Configuration,

        [Parameter(Mandatory)]
        [string]$TenantId
    )

    $issues = @(
        "Privileged role review for tenant [$TenantId] is expected to include break-glass and shared administrator accounts.",
        'Inactive user cleanup and conditional access dependency checks require customer validation before production attestation.'
    )

    if (-not [bool]$Configuration.includeGuestAccounts) {
        $issues += 'Guest account review is excluded by the selected tier and should be handled separately before broader Copilot rollout.'
    }
    else {
        $issues += 'Guest access posture is in scope and should be correlated with external sharing policies.'
    }

    return (New-DomainResult -Domain 'identity' -BaseScore 74 -Issues $issues -Configuration $Configuration)
}

function Invoke-DefenderScan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$Configuration,

        [Parameter(Mandatory)]
        [string]$TenantId
    )

    $issues = @(
        "Defender security signal collection for tenant [$TenantId] assumes current endpoint and alert telemetry are available.",
        'High-risk exposure items should be reviewed before Copilot access is broadened to sensitive user groups.',
        'Security posture checks currently represent a baseline implementation pattern and may require tenant-specific API tuning.'
    )

    return (New-DomainResult -Domain 'defender' -BaseScore 76 -Issues $issues -Configuration $Configuration)
}

function Invoke-PurviewScan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$Configuration,

        [Parameter(Mandatory)]
        [string]$TenantId
    )

    $issues = @(
        "Sensitivity label coverage for tenant [$TenantId] should be reconciled with known regulated content repositories.",
        'Retention and records readiness indicators require formal records management approval before they can be treated as complete.',
        'Unlabeled or legacy-labeled content remains a common source of Copilot data hygiene exceptions.'
    )

    return (New-DomainResult -Domain 'purview' -BaseScore 84 -Issues $issues -Configuration $Configuration)
}

function Invoke-PowerPlatformScan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$Configuration,

        [Parameter(Mandatory)]
        [string]$TenantId
    )

    $issues = @(
        "Power Platform environment inventory for tenant [$TenantId] should be reviewed for unmanaged maker activity.",
        'Custom connector review is modeled as a governance checkpoint and still requires customer confirmation.',
        'DLP policy coverage should be compared against the Copilot pilot business processes before sign-off.'
    )

    return (New-DomainResult -Domain 'powerPlatform' -BaseScore 67 -Issues $issues -Configuration $Configuration)
}

function Invoke-CopilotConfigScan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$Configuration,

        [Parameter(Mandatory)]
        [string]$TenantId
    )

    $issues = @(
        "Copilot configuration inventory for tenant [$TenantId] should be aligned to the approved rollout wave and support model.",
        'Prompt grounding and access scope validation remain dependent on workload-level controls outside the current stub implementation.',
        'Configuration drift between pilot and production cohorts should be reviewed before broader enablement.'
    )

    return (New-DomainResult -Domain 'copilotConfig' -BaseScore 80 -Issues $issues -Configuration $Configuration)
}

try {
    Write-Verbose "Loading configuration for tier [$ConfigurationTier]."
    $configuration = Get-SolutionConfiguration -Tier $ConfigurationTier

    Import-SharedModule -ModuleName 'GraphAuth.psm1'
    $null = New-CopilotGovGraphContext -TenantId $TenantId -Scopes @(
        'Organization.Read.All',
        'Directory.Read.All',
        'Reports.Read.All'
    )

    $selectedDomains = if ($PSBoundParameters.ContainsKey('Domains') -and $Domains.Count -gt 0) {
        $Domains
    }
    else {
        [string[]]$configuration.scanDomains
    }

    $unsupportedDomains = @($selectedDomains | Where-Object { $_ -notin $configuration.scanDomains })
    if ($unsupportedDomains.Count -gt 0) {
        throw "Unsupported domain selection: $([string]::Join(', ', $unsupportedDomains))"
    }

    Write-Warning $script:SimulationWarning
    $scanResults = foreach ($domain in $selectedDomains) {
        switch ($domain) {
            'licensing' { Invoke-LicensingScan -Configuration $configuration -TenantId $TenantId }
            'identity' { Invoke-IdentityScan -Configuration $configuration -TenantId $TenantId }
            'defender' { Invoke-DefenderScan -Configuration $configuration -TenantId $TenantId }
            'purview' { Invoke-PurviewScan -Configuration $configuration -TenantId $TenantId }
            'powerPlatform' { Invoke-PowerPlatformScan -Configuration $configuration -TenantId $TenantId }
            'copilotConfig' { Invoke-CopilotConfigScan -Configuration $configuration -TenantId $TenantId }
        }
    }

    $resolvedExportPath = [System.IO.Path]::GetFullPath($ExportPath)
    $null = New-Item -ItemType Directory -Path $resolvedExportPath -Force
    $exportFileName = "CRS-monitoring-baseline-{0}-{1}.json" -f $ConfigurationTier, (Get-Date -Format 'yyyyMMddHHmmss')
    $exportFilePath = Join-Path $resolvedExportPath $exportFileName
    $scanResults | ConvertTo-Json -Depth 6 | Set-Content -Path $exportFilePath -Encoding utf8

    Write-Information "Simulated monitoring baseline exported to $exportFilePath"
    $scanResults
}
catch {
    Write-Error -Message ("Monitoring failed: {0}" -f $_.Exception.Message)
    throw
}
