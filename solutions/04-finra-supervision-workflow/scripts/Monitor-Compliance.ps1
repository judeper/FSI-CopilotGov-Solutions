#Requires -Version 7.0
<#
.SYNOPSIS
    Monitors FINRA Supervision Workflow compliance posture.
.DESCRIPTION
    Checks configuration drift, validates sampling rates against tier policy,
    verifies SLA configuration alignment, and reports control status.
    Reads config from the solution config folder; does not make live API calls
    unless -LiveCheck is specified.
.PARAMETER ConfigurationTier
    Governance tier: baseline, recommended, or regulated.
.PARAMETER LiveCheck
    When specified, attempts to connect to Dataverse and verify queue health.
.PARAMETER OutputPath
    Directory for compliance status output.
.EXAMPLE
    .\Monitor-Compliance.ps1 -ConfigurationTier recommended -OutputPath .\artifacts\monitoring
#>
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet('baseline', 'recommended', 'regulated')]
    [string]$ConfigurationTier = 'baseline',

    [Parameter()]
    [switch]$LiveCheck,

    [Parameter()]
    [string]$OutputPath = (Join-Path $PSScriptRoot '..\artifacts\monitoring')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Shared-Functions.ps1')

$script:RuntimeMode = 'documentation-first'
$script:StatusWarning = 'Monitor-Compliance.ps1 validates configuration posture and an optional endpoint probe only; it does not confirm live queue processing or reviewer activity.'

function Resolve-DocumentationFirstStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [bool]$HasFindings
    )

    if ($HasFindings) {
        return 'monitor-only'
    }

    return 'partial'
}

function Test-LiveDataverseEndpoint {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$EnvironmentUrl
    )

    $result = [ordered]@{
        attempted = $true
        connected = $false
        queueHealth = 'not-verified'
        notes = @()
    }

    if ([string]::IsNullOrWhiteSpace($EnvironmentUrl) -or $EnvironmentUrl -in @('https://contoso.crm.dynamics.com', 'https://REPLACE-ME.crm.dynamics.com')) {
        $result['notes'] = @('Live Dataverse verification was requested, but the configured environment URL is still a placeholder.')
        return [pscustomobject]$result
    }

    try {
        $response = Invoke-WebRequest -Uri $EnvironmentUrl -Method Head -MaximumRedirection 0 -SkipHttpErrorCheck -TimeoutSec 15
        if ($response.StatusCode -in @(200, 302, 401, 403)) {
            $result['connected'] = $true
            $result['queueHealth'] = 'endpoint-responsive'
            $result['notes'] = @('Dataverse environment endpoint responded to an HTTP probe. Queue row validation remains a manual step in this script.')
        }
        else {
            $result['notes'] = @("Unexpected HTTP status code returned by Dataverse endpoint: $($response.StatusCode)")
        }
    }
    catch {
        $result['notes'] = @("Dataverse endpoint probe failed: $($_.Exception.Message)")
    }

    return [pscustomobject]$result
}

$solutionRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$configuration = Get-EffectiveConfiguration -SolutionRoot $solutionRoot -Tier $ConfigurationTier

$expectedZonesByTier = @{
    baseline = @('Zone1')
    recommended = @('Zone1', 'Zone2')
    regulated = @('Zone1', 'Zone2', 'Zone3')
}

$samplingBounds = @{
    Zone1 = @{ Min = 5; Max = 25 }
    Zone2 = @{ Min = 25; Max = 50 }
    Zone3 = @{ Min = 100; Max = 100 }
}

$expectedZones = @($expectedZonesByTier[$ConfigurationTier])
$actualZones = @($configuration['supportedZones'])
$missingZones = @($expectedZones | Where-Object { $_ -notin $actualZones })
$unexpectedZones = @($actualZones | Where-Object { $_ -notin $expectedZones })

$samplingFindings = New-Object System.Collections.Generic.List[string]
$slaFindings = New-Object System.Collections.Generic.List[string]
$control35Findings = New-Object System.Collections.Generic.List[string]
$control36Findings = New-Object System.Collections.Generic.List[string]

if ($missingZones.Count -gt 0) {
    $samplingFindings.Add("Missing configured zones for tier ${ConfigurationTier}: $($missingZones -join ', ')")
}

if ($unexpectedZones.Count -gt 0) {
    $samplingFindings.Add("Unexpected configured zones for tier ${ConfigurationTier}: $($unexpectedZones -join ', ')")
}

foreach ($zone in $expectedZones) {
    if (-not $configuration['samplingRates'].Contains($zone)) {
        $samplingFindings.Add("Sampling rate is not configured for $zone.")
        continue
    }

    $samplingRate = [int]$configuration['samplingRates'][$zone]
    $bounds = $samplingBounds[$zone]
    if ($samplingRate -lt $bounds['Min'] -or $samplingRate -gt $bounds['Max']) {
        $samplingFindings.Add("Sampling rate for $zone is $samplingRate percent, outside the supported range of $($bounds['Min']) to $($bounds['Max']) percent.")
    }
}

foreach ($zone in $expectedZones) {
    if (-not $configuration['slaHoursByZone'].Contains($zone)) {
        $slaFindings.Add("SLA hours are not configured for $zone.")
        continue
    }

    $slaHours = [int]$configuration['slaHoursByZone'][$zone]
    if ($slaHours -le 0) {
        $slaFindings.Add("SLA hours for $zone must be greater than zero.")
    }
}

if ($ConfigurationTier -eq 'regulated' -and $configuration['slaHoursByZone'].Contains('Zone3')) {
    if ([int]$configuration['slaHoursByZone']['Zone3'] -ne 4) {
        $slaFindings.Add('Zone3 must remain at a 4 hour SLA for the regulated tier.')
    }
}

if ($ConfigurationTier -eq 'baseline' -and $configuration['slaHoursByZone'].Contains('Zone1')) {
    if ([int]$configuration['slaHoursByZone']['Zone1'] -gt 48) {
        $slaFindings.Add('Zone1 should not exceed a 48 hour SLA for the baseline tier.')
    }
}

$requiredDispositions = @('approved', 'rejected', 'escalated')
foreach ($disposition in $requiredDispositions) {
    if ($configuration['reviewDispositionValues'] -notcontains $disposition) {
        $control35Findings.Add("Required review disposition missing: $disposition")
    }
}

if ($ConfigurationTier -eq 'regulated' -and -not $configuration['immutableLogRequired']) {
    $control35Findings.Add('Regulated tier must require an immutable log.')
}

if (-not $configuration['exceptionTracking']['enabled']) {
    $control36Findings.Add('Exception tracking must be enabled.')
}

if (-not $configuration['exceptionTracking']['slaBreachLogEnabled']) {
    $control36Findings.Add('SLA breach logging must be enabled for exception tracking.')
}

if ($configuration['escalationEnabled']) {
    if (@($configuration['notifications']['breachRecipients']).Count -eq 0) {
        $control36Findings.Add('Escalation is enabled, but no breach recipients are configured.')
    }
}
elseif ($ConfigurationTier -ne 'baseline') {
    $control36Findings.Add('Escalation should be enabled for recommended and regulated tiers.')
}

$controls = @(
    [pscustomobject]@{
        controlId = '3.4'
        status = Resolve-DocumentationFirstStatus -HasFindings (($samplingFindings.Count -gt 0) -or ($slaFindings.Count -gt 0))
        notes = if ($samplingFindings.Count -eq 0 -and $slaFindings.Count -eq 0) {
            'Sampling rates and SLA targets are configured for the expected zones, but live supervisory queue processing is not validated by this script.'
        }
        else {
            ($samplingFindings + $slaFindings) -join ' '
        }
    }
    [pscustomobject]@{
        controlId = '3.5'
        status = Resolve-DocumentationFirstStatus -HasFindings ($control35Findings.Count -gt 0)
        notes = if ($control35Findings.Count -eq 0) {
            'Review dispositions and immutable logging requirements are configured for the active tier, but live reviewer actions are not inspected here.'
        }
        else {
            $control35Findings -join ' '
        }
    }
    [pscustomobject]@{
        controlId = '3.6'
        status = Resolve-DocumentationFirstStatus -HasFindings ($control36Findings.Count -gt 0)
        notes = if ($control36Findings.Count -eq 0) {
            'Exception tracking, escalation handling, and notification settings are configured for the active tier, but the repository monitor does not verify live exception rows.'
        }
        else {
            $control36Findings -join ' '
        }
    }
)

$liveCheckResult = if ($LiveCheck) {
    Test-LiveDataverseEndpoint -EnvironmentUrl ([string]$configuration['dataverseEnvironmentUrl'])
}
else {
    [pscustomobject]@{
        attempted = $false
        connected = $null
        queueHealth = 'skipped'
        notes = @('Live Dataverse verification was not requested; output reflects documentation-first configuration checks only.')
    }
}

$dataSourceMode = if ($LiveCheck -and $liveCheckResult.connected) {
    'configuration-plus-endpoint-probe'
}
elseif ($LiveCheck) {
    'configuration-plus-failed-endpoint-probe'
}
else {
    'configuration-only'
}

$overallStatus = if (@($controls | Where-Object { $_.status -eq 'monitor-only' }).Count -gt 0 -or ($LiveCheck -and -not $liveCheckResult.connected)) {
    'monitor-only'
}
else {
    'partial'
}

if (-not $LiveCheck -or -not $liveCheckResult.connected) {
    Write-Warning $script:StatusWarning
}

$result = [ordered]@{
    solution = '04-finra-supervision-workflow'
    solutionCode = 'FSW'
    tier = $ConfigurationTier
    checkedAt = (Get-Date).ToString('o')
    overallStatus = $overallStatus
    runtimeMode = $script:RuntimeMode
    dataSourceMode = $dataSourceMode
    statusWarning = $script:StatusWarning
    supportedZones = $configuration['supportedZones']
    samplingRates = $configuration['samplingRates']
    slaHoursByZone = $configuration['slaHoursByZone']
    samplingValidation = [ordered]@{
        passed = ($samplingFindings.Count -eq 0)
        findings = @($samplingFindings)
    }
    slaValidation = [ordered]@{
        passed = ($slaFindings.Count -eq 0)
        findings = @($slaFindings)
    }
    controls = $controls
    liveCheck = $liveCheckResult
}

$null = New-Item -ItemType Directory -Path $OutputPath -Force
$statusPath = Join-Path $OutputPath 'fsw-compliance-status.json'
$result | ConvertTo-Json -Depth 10 | Set-Content -Path $statusPath -Encoding utf8

[pscustomobject]$result
