#Requires -Version 7.0
<#
.SYNOPSIS
    Exports FINRA Supervision Workflow evidence package.
.DESCRIPTION
    Assembles supervision-queue-snapshot, review-disposition-log, and sampling-summary
    evidence artifacts aligned to the evidence-schema.json contract.
    In documentation-first mode (default), generates configuration-based evidence.
    In -LiveExport mode, queries Dataverse for actual queue and log records.
.PARAMETER ConfigurationTier
    Governance tier: baseline, recommended, or regulated.
.PARAMETER OutputPath
    Directory for evidence output.
.PARAMETER PeriodStart
    Inclusive period start in YYYY-MM-DD format.
.PARAMETER PeriodEnd
    Inclusive period end in YYYY-MM-DD format.
.PARAMETER LiveExport
    When specified, queries Dataverse with DATAVERSE_ACCESS_TOKEN for live evidence.
.EXAMPLE
    .\Export-Evidence.ps1 -ConfigurationTier regulated -PeriodStart 2026-01-01 -PeriodEnd 2026-01-31
#>
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet('baseline', 'recommended', 'regulated')]
    [string]$ConfigurationTier = 'baseline',

    [Parameter()]
    [string]$OutputPath = (Join-Path $PSScriptRoot '..\artifacts\evidence'),

    [Parameter()]
    [ValidatePattern('^\d{4}-\d{2}-\d{2}$')]
    [string]$PeriodStart = (Get-Date).AddDays(-30).ToString('yyyy-MM-dd'),

    [Parameter()]
    [ValidatePattern('^\d{4}-\d{2}-\d{2}$')]
    [string]$PeriodEnd = (Get-Date).ToString('yyyy-MM-dd'),

    [Parameter()]
    [switch]$LiveExport
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
Import-Module (Join-Path $repoRoot 'scripts\common\EvidenceExport.psm1') -Force

$script:DocumentationFirstWarning = 'Documentation-first export emits configuration-based sample evidence. Use -LiveExport with Dataverse connectivity before treating supervisory controls as implemented.'

function Read-JsonFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not (Test-Path -Path $Path -PathType Leaf)) {
        throw "JSON file not found: $Path"
    }

    return Get-Content -Path $Path -Raw | ConvertFrom-Json -AsHashtable
}

function Get-ConfiguredEnvironmentUrl {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$DefaultConfig
    )

    $defaults = $DefaultConfig['defaults']
    if ($defaults.Contains('dataverseEnvironmentUrl') -and -not [string]::IsNullOrWhiteSpace([string]$defaults['dataverseEnvironmentUrl'])) {
        return [string]$defaults['dataverseEnvironmentUrl']
    }

    if ($defaults.Contains('datverseEnvironmentUrl') -and -not [string]::IsNullOrWhiteSpace([string]$defaults['datverseEnvironmentUrl'])) {
        return [string]$defaults['datverseEnvironmentUrl']
    }

    return $null
}

function Get-EffectiveConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$SolutionRoot,

        [Parameter(Mandatory)]
        [ValidateSet('baseline', 'recommended', 'regulated')]
        $Tier
    )

    $defaultConfig = Read-JsonFile -Path (Join-Path $SolutionRoot 'config\default-config.json')
    $tierConfig = Read-JsonFile -Path (Join-Path $SolutionRoot ("config\{0}.json" -f $Tier))

    $supportedZones = @($tierConfig['supportedZones'])
    $effectiveSamplingRates = [ordered]@{}
    $effectiveSlaHours = [ordered]@{}
    $defaultSampling = $defaultConfig['defaults']['samplingRates']
    $defaultSla = $defaultConfig['defaults']['slaHoursByZone']

    foreach ($zone in $supportedZones) {
        if ($tierConfig['samplingRates'].Contains($zone)) {
            $effectiveSamplingRates[$zone] = [int]$tierConfig['samplingRates'][$zone]
        }
        elseif ($defaultSampling.Contains($zone) -and $defaultSampling[$zone].Contains($Tier)) {
            $effectiveSamplingRates[$zone] = [int]$defaultSampling[$zone][$Tier]
        }

        if ($tierConfig['slaHoursByZone'].Contains($zone)) {
            $effectiveSlaHours[$zone] = [int]$tierConfig['slaHoursByZone'][$zone]
        }
        elseif ($defaultSla.Contains($zone)) {
            $effectiveSlaHours[$zone] = [int]$defaultSla[$zone]
        }
    }

    return [ordered]@{
        solution = $defaultConfig['solution']
        tier = $Tier
        controls = @($defaultConfig['controls'])
        regulations = @($defaultConfig['regulations'])
        evidenceOutputs = @($defaultConfig['evidenceOutputs'])
        supportedZones = $supportedZones
        samplingRates = $effectiveSamplingRates
        slaHoursByZone = $effectiveSlaHours
        escalationEnabled = [bool]$tierConfig['escalationEnabled']
        notifications = $tierConfig['notifications']
        reviewDispositionValues = @($tierConfig['reviewDispositionValues'])
        exceptionTracking = $tierConfig['exceptionTracking']
        immutableLogRequired = [bool]$tierConfig['immutableLogRequired']
        evidenceRetentionDays = [int]$tierConfig['evidenceRetentionDays']
        purviewPolicyId = [string]$defaultConfig['defaults']['purviewPolicyId']
        dataverseEnvironmentUrl = Get-ConfiguredEnvironmentUrl -DefaultConfig $defaultConfig
    }
}

function Get-PeriodBoundary {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Date,

        [Parameter()]
        [switch]$ExclusiveEnd
    )

    $parsed = [datetime]::ParseExact($Date, 'yyyy-MM-dd', [System.Globalization.CultureInfo]::InvariantCulture)
    if ($ExclusiveEnd) {
        return $parsed.AddDays(1)
    }

    return $parsed
}

function Write-JsonArtifact {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$FileName,

        [Parameter(Mandatory)]
        [string]$ArtifactType,

        [Parameter(Mandatory)]
        [object]$Payload,

        [Parameter(Mandatory)]
        [string]$DestinationPath
    )

    $null = New-Item -ItemType Directory -Path $DestinationPath -Force
    $path = Join-Path $DestinationPath ("{0}.json" -f $FileName)
    $Payload | ConvertTo-Json -Depth 12 | Set-Content -Path $path -Encoding utf8
    $hash = Get-CopilotGovSha256 -Path $path
    Set-Content -Path ($path + '.sha256') -Value ("{0}  {1}" -f $hash, [System.IO.Path]::GetFileName($path)) -Encoding utf8

    return [ordered]@{
        name = $FileName
        type = $ArtifactType
        path = $path
        hash = $hash
    }
}

function Get-DocumentationEvidenceData {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Configuration,

        [Parameter(Mandatory)]
        $Tier,

        [Parameter(Mandatory)]
        $StartDate,

        [Parameter(Mandatory)]
        $EndDate
    )

    $queueRecords = @()
    $logRecords = @()
    $samplingRecords = @()
    $stateSummary = @()
    $actionSummary = @()
    $exceptionCount = 0
    $index = 1

    foreach ($zone in @($Configuration['supportedZones'])) {
        $queueNumber = 'FSW-{0}-{1:000}' -f ($zone.Replace('Zone', 'Z')), $index
        $samplingRate = [int]$Configuration['samplingRates'][$zone]
        $slaHours = [int]$Configuration['slaHoursByZone'][$zone]
        $zoneState = switch ($zone) {
            'Zone3' { 'Escalated' }
            'Zone2' { 'InReview' }
            default { 'PendingReview' }
        }
        $reviewOutcome = switch ($zone) {
            'Zone3' { 'Escalated' }
            'Zone2' { 'Pending' }
            default { 'Pending' }
        }
        $principal = ('principal.{0}@contoso.com' -f $zone.ToLowerInvariant())
        $slaDue = $StartDate.AddHours($slaHours + (($index - 1) * 2)).ToString('o')
        $queueRecords += [ordered]@{
            fsi_queuenumber = $queueNumber
            fsi_sourcetype = 'PurviewCommunicationCompliance'
            fsi_sourceid = ('doc-sample-{0:000}' -f $index)
            fsi_agentid = 'Microsoft365Copilot'
            fsi_zone = $zone
            fsi_tier = $Tier
            fsi_state = $zoneState
            fsi_assignedprincipal = $principal
            fsi_sladue = $slaDue
            fsi_reviewoutcome = $reviewOutcome
            fsi_reviewnotes = if ($zone -eq 'Zone3') { 'High-risk item requires immediate principal review.' } else { 'Documentation-first sample item generated from tier configuration.' }
        }

        $logRecords += [ordered]@{
            fsi_lognumber = ('LOG-{0:000}-01' -f $index)
            fsi_queueitem = $queueNumber
            fsi_action = 'ingested'
            fsi_actor = 'Ingest Flagged Items'
            fsi_timestamp = $StartDate.AddHours($index).ToString('o')
        }
        $logRecords += [ordered]@{
            fsi_lognumber = ('LOG-{0:000}-02' -f $index)
            fsi_queueitem = $queueNumber
            fsi_action = 'assigned'
            fsi_actor = 'Assignment Flow'
            fsi_timestamp = $StartDate.AddHours($index + 1).ToString('o')
        }

        if ($zone -eq 'Zone3') {
            $logRecords += [ordered]@{
                fsi_lognumber = ('LOG-{0:000}-03' -f $index)
                fsi_queueitem = $queueNumber
                fsi_action = 'sla-warning'
                fsi_actor = 'Escalation Flow'
                fsi_timestamp = $StartDate.AddHours($index + 2).ToString('o')
            }
            $exceptionCount++
        }

        $samplingRecords += [ordered]@{
            zone = $zone
            tier = $Tier
            reviewPercent = $samplingRate
            slaHours = $slaHours
            escalationEnabled = [bool]$Configuration['escalationEnabled']
        }

        $stateSummary += [ordered]@{
            state = $zoneState
            count = 1
        }
        $actionSummary += [ordered]@{
            zone = $zone
            actions = if ($zone -eq 'Zone3') { 3 } else { 2 }
        }

        $index++
    }

    return [ordered]@{
        queueSnapshot = [ordered]@{
            solution = '04-finra-supervision-workflow'
            tier = $Tier
            mode = 'documentation-first'
            warning = $script:DocumentationFirstWarning
            periodStart = $StartDate.ToString('yyyy-MM-dd')
            periodEnd = $EndDate.ToString('yyyy-MM-dd')
            summary = [ordered]@{
                recordCount = $queueRecords.Count
                stateSummary = $stateSummary
            }
            records = @($queueRecords)
        }
        reviewDispositionLog = [ordered]@{
            solution = '04-finra-supervision-workflow'
            tier = $Tier
            mode = 'documentation-first'
            warning = $script:DocumentationFirstWarning
            periodStart = $StartDate.ToString('yyyy-MM-dd')
            periodEnd = $EndDate.ToString('yyyy-MM-dd')
            summary = [ordered]@{
                recordCount = $logRecords.Count
                actionSummary = $actionSummary
            }
            records = @($logRecords)
        }
        samplingSummary = [ordered]@{
            solution = '04-finra-supervision-workflow'
            tier = $Tier
            mode = 'documentation-first'
            warning = $script:DocumentationFirstWarning
            periodStart = $StartDate.ToString('yyyy-MM-dd')
            periodEnd = $EndDate.ToString('yyyy-MM-dd')
            summary = [ordered]@{
                configuredZones = @($Configuration['supportedZones'])
                escalationEnabled = [bool]$Configuration['escalationEnabled']
            }
            records = @($samplingRecords)
        }
        recordCount = $queueRecords.Count + $logRecords.Count + $samplingRecords.Count
        exceptionCount = $exceptionCount
    }
}

function Invoke-DataverseTableQuery {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$EnvironmentUrl,

        [Parameter(Mandatory)]
        [string]$TableName,

        [Parameter(Mandatory)]
        [string[]]$Select,

        [Parameter()]
        [string]$Filter
    )

    if ([string]::IsNullOrWhiteSpace($env:DATAVERSE_ACCESS_TOKEN)) {
        throw 'DATAVERSE_ACCESS_TOKEN environment variable is required when -LiveExport is specified.'
    }

    if ([string]::IsNullOrWhiteSpace($EnvironmentUrl) -or $EnvironmentUrl -like 'https://contoso.crm.dynamics.com') {
        throw 'A non-placeholder Dataverse environment URL is required when -LiveExport is specified.'
    }

    $uri = '{0}/api/data/v9.2/{1}?$select={2}' -f $EnvironmentUrl.TrimEnd('/'), $TableName, ($Select -join ',')
    if (-not [string]::IsNullOrWhiteSpace($Filter)) {
        $uri = '{0}&$filter={1}' -f $uri, [System.Uri]::EscapeDataString($Filter)
    }

    $headers = @{
        Authorization = "Bearer $($env:DATAVERSE_ACCESS_TOKEN)"
        Accept = 'application/json'
    }

    $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get
    return @($response.value)
}

function Get-LiveEvidenceData {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Configuration,

        [Parameter(Mandatory)]
        $Tier,

        [Parameter(Mandatory)]
        $StartDate,

        [Parameter(Mandatory)]
        $EndDate
    )

    $environmentUrl = [string]$Configuration['dataverseEnvironmentUrl']
    $queueFilter = "createdon ge $($StartDate.ToString('yyyy-MM-ddTHH:mm:ssZ')) and createdon lt $($EndDate.AddDays(1).ToString('yyyy-MM-ddTHH:mm:ssZ'))"
    $logFilter = "fsi_timestamp ge $($StartDate.ToString('yyyy-MM-ddTHH:mm:ssZ')) and fsi_timestamp lt $($EndDate.AddDays(1).ToString('yyyy-MM-ddTHH:mm:ssZ'))"

    $queueRecords = Invoke-DataverseTableQuery -EnvironmentUrl $environmentUrl -TableName 'fsi_cg_fsw_queue' -Select @('fsi_queuenumber', 'fsi_sourcetype', 'fsi_sourceid', 'fsi_agentid', 'fsi_zone', 'fsi_tier', 'fsi_state', 'fsi_assignedprincipal', 'fsi_sladue', 'fsi_reviewoutcome', 'fsi_reviewnotes') -Filter $queueFilter
    $logRecords = Invoke-DataverseTableQuery -EnvironmentUrl $environmentUrl -TableName 'fsi_cg_fsw_log' -Select @('fsi_lognumber', 'fsi_queueitem', 'fsi_action', 'fsi_actor', 'fsi_timestamp') -Filter $logFilter
    $configRows = Invoke-DataverseTableQuery -EnvironmentUrl $environmentUrl -TableName 'fsi_cg_fsw_config' -Select @('fsi_zone', 'fsi_tier', 'fsi_slahours', 'fsi_reviewpercent')

    $stateSummary = @($queueRecords | Group-Object -Property fsi_state | ForEach-Object {
        [ordered]@{
            state = $_.Name
            count = $_.Count
        }
    })

    $actionSummary = @($logRecords | Group-Object -Property fsi_action | ForEach-Object {
        [ordered]@{
            action = $_.Name
            count = $_.Count
        }
    })

    $samplingRecords = if ($configRows.Count -gt 0) {
        @($configRows | Where-Object { $_.fsi_tier -eq $Tier } | ForEach-Object {
            [ordered]@{
                zone = $_.fsi_zone
                tier = $_.fsi_tier
                reviewPercent = [int]$_.fsi_reviewpercent
                slaHours = [int]$_.fsi_slahours
                escalationEnabled = [bool]$Configuration['escalationEnabled']
            }
        })
    }
    else {
        @($Configuration['supportedZones'] | ForEach-Object {
            [ordered]@{
                zone = $_
                tier = $Tier
                reviewPercent = [int]$Configuration['samplingRates'][$_]
                slaHours = [int]$Configuration['slaHoursByZone'][$_]
                escalationEnabled = [bool]$Configuration['escalationEnabled']
            }
        })
    }

    $exceptionCount = @($queueRecords | Where-Object { $_.fsi_state -eq 'Escalated' -or $_.fsi_reviewoutcome -eq 'ExceptionGranted' }).Count

    return [ordered]@{
        queueSnapshot = [ordered]@{
            solution = '04-finra-supervision-workflow'
            tier = $Tier
            mode = 'live-export'
            warning = 'Live-export mode reads Dataverse rows, but Power Automate and Dataverse implementations remain customer-managed outside this repository.'
            periodStart = $StartDate.ToString('yyyy-MM-dd')
            periodEnd = $EndDate.ToString('yyyy-MM-dd')
            summary = [ordered]@{
                recordCount = $queueRecords.Count
                stateSummary = $stateSummary
            }
            records = @($queueRecords)
        }
        reviewDispositionLog = [ordered]@{
            solution = '04-finra-supervision-workflow'
            tier = $Tier
            mode = 'live-export'
            warning = 'Live-export mode reads Dataverse rows, but Power Automate and Dataverse implementations remain customer-managed outside this repository.'
            periodStart = $StartDate.ToString('yyyy-MM-dd')
            periodEnd = $EndDate.ToString('yyyy-MM-dd')
            summary = [ordered]@{
                recordCount = $logRecords.Count
                actionSummary = $actionSummary
            }
            records = @($logRecords)
        }
        samplingSummary = [ordered]@{
            solution = '04-finra-supervision-workflow'
            tier = $Tier
            mode = 'live-export'
            warning = 'Live-export mode reads Dataverse rows, but Power Automate and Dataverse implementations remain customer-managed outside this repository.'
            periodStart = $StartDate.ToString('yyyy-MM-dd')
            periodEnd = $EndDate.ToString('yyyy-MM-dd')
            summary = [ordered]@{
                configuredZones = @($Configuration['supportedZones'])
                escalationEnabled = [bool]$Configuration['escalationEnabled']
            }
            records = @($samplingRecords)
        }
        recordCount = $queueRecords.Count + $logRecords.Count + $samplingRecords.Count
        exceptionCount = $exceptionCount
    }
}

$startDate = Get-PeriodBoundary -Date $PeriodStart
$endDate = Get-PeriodBoundary -Date $PeriodEnd
if ($endDate -lt $startDate) {
    throw 'PeriodEnd must be greater than or equal to PeriodStart.'
}

$solutionRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$configuration = Get-EffectiveConfiguration -SolutionRoot $solutionRoot -Tier $ConfigurationTier
$data = if ($LiveExport) {
    Get-LiveEvidenceData -Configuration $configuration -Tier $ConfigurationTier -StartDate $startDate -EndDate $endDate
}
else {
    Get-DocumentationEvidenceData -Configuration $configuration -Tier $ConfigurationTier -StartDate $startDate -EndDate $endDate
}

$queueArtifact = Write-JsonArtifact -FileName 'supervision-queue-snapshot' -ArtifactType 'supervision-queue-snapshot' -Payload $data['queueSnapshot'] -DestinationPath $OutputPath
$logArtifact = Write-JsonArtifact -FileName 'review-disposition-log' -ArtifactType 'review-disposition-log' -Payload $data['reviewDispositionLog'] -DestinationPath $OutputPath
$samplingArtifact = Write-JsonArtifact -FileName 'sampling-summary' -ArtifactType 'sampling-summary' -Payload $data['samplingSummary'] -DestinationPath $OutputPath

$controls = @(
    [pscustomobject]@{
        controlId = '3.4'
        status = if ($LiveExport) { if (@($data['queueSnapshot']['records']).Count -eq 0) { 'partial' } else { 'implemented' } } else { 'partial' }
        notes = if ($LiveExport) {
            'Supports compliance with supervisory coverage by capturing queue intake, zone assignment, sampling configuration, and SLA targets.'
        }
        else {
            'Documentation-first sample evidence captures the intended queue, sampling, and SLA pattern; live Dataverse rows are required before treating supervisory coverage as implemented.'
        }
    }
    [pscustomobject]@{
        controlId = '3.5'
        status = if ($LiveExport) { if (@($data['reviewDispositionLog']['records']).Count -eq 0) { 'partial' } else { 'implemented' } } else { 'partial' }
        notes = if ($LiveExport) {
            'Supports compliance with review disposition accountability through reviewer actions, timestamps, and recorded outcomes.'
        }
        else {
            'Documentation-first sample evidence preserves the intended review-disposition contract, but live reviewer actions are not exported by default.'
        }
    }
    [pscustomobject]@{
        controlId = '3.6'
        status = if ($LiveExport -and $configuration['exceptionTracking']['enabled']) { 'implemented' } else { 'partial' }
        notes = if ($LiveExport -and $configuration['exceptionTracking']['enabled']) {
            'Supports compliance with exception tracking through escalation settings, breach logging, and review notes retained for audit.'
        }
        else {
            'Exception tracking configuration is documented and exportable, but default repository output remains documentation-first until live Dataverse evidence is supplied.'
        }
    }
)

$overallStatus = if ($LiveExport -and @($controls | Where-Object { $_.status -ne 'implemented' }).Count -eq 0) { 'implemented' } else { 'partial' }
$summary = [ordered]@{
    overallStatus = $overallStatus
    recordCount = [int]$data['recordCount']
    findingCount = [int](@($controls | Where-Object { $_.status -ne 'implemented' }).Count)
    exceptionCount = [int]$data['exceptionCount']
}

$package = Export-SolutionEvidencePackage `
    -Solution '04-finra-supervision-workflow' `
    -SolutionCode 'FSW' `
    -Tier $ConfigurationTier `
    -OutputPath $OutputPath `
    -Summary $summary `
    -Controls $controls `
    -Artifacts @($queueArtifact, $logArtifact, $samplingArtifact) `
    -ExpectedArtifacts @($configuration['evidenceOutputs']) `
    -AdditionalMetadata @{
        periodStart = $PeriodStart
        periodEnd = $PeriodEnd
        evidenceMode = if ($LiveExport) { 'live-export' } else { 'documentation-first' }
        warning = if ($LiveExport) { 'Live-export reads Dataverse records but still depends on customer-managed Power Platform assets.' } else { $script:DocumentationFirstWarning }
        policyId = $configuration['purviewPolicyId']
        environmentUrl = $configuration['dataverseEnvironmentUrl']
    }

[pscustomobject]@{
    Solution = 'FINRA Supervision Workflow for Copilot'
    Tier = $ConfigurationTier
    Mode = if ($LiveExport) { 'live-export' } else { 'documentation-first' }
    PackagePath = $package.Path
    PackageHash = $package.Hash
    Artifacts = @($queueArtifact, $logArtifact, $samplingArtifact)
}




