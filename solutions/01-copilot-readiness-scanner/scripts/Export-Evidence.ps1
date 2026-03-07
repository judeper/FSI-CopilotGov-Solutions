<#
.SYNOPSIS
Exports schema-aligned evidence artifacts for the Copilot Readiness Assessment Scanner.

.DESCRIPTION
Loads default and tier-specific configuration, assembles control assessments for solution 01,
writes evidence artifacts and a schema-aligned package file, computes SHA-256 hashes for each
JSON artifact, and returns a summary suitable for operational logging or Power BI ingestion.
The export logic is intentionally explicit so teams can extend the placeholder datasets with
live tenant findings while preserving the repository evidence contract.

.PARAMETER ConfigurationTier
Specifies the governance tier used for the export. Valid values are baseline, recommended, and regulated.

.PARAMETER OutputPath
Specifies the folder where evidence artifacts are written.

.PARAMETER TenantId
Specifies the Microsoft Entra tenant identifier associated with the evidence package.

.PARAMETER PeriodStart
Specifies the beginning of the reporting period.

.PARAMETER PeriodEnd
Specifies the end of the reporting period.

.EXAMPLE
PS> .\Export-Evidence.ps1 -ConfigurationTier recommended -TenantId 'contoso.onmicrosoft.com' -OutputPath '.\artifacts'

Exports the default 30-day evidence package for the recommended tier.

.EXAMPLE
PS> .\Export-Evidence.ps1 -ConfigurationTier regulated -TenantId '11111111-1111-1111-1111-111111111111' -PeriodStart (Get-Date).AddDays(-90) -PeriodEnd (Get-Date)

Exports a regulated-tier evidence package for a custom reporting window.
#>
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet('baseline', 'recommended', 'regulated')]
    [string]$ConfigurationTier = 'baseline',

    [Parameter()]
    [string]$OutputPath = (Join-Path $PSScriptRoot '..\artifacts'),

    [Parameter(Mandatory)]
    [string]$TenantId,

    [Parameter()]
    [datetime]$PeriodStart = (Get-Date).Date.AddDays(-30),

    [Parameter()]
    [datetime]$PeriodEnd = (Get-Date).Date
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:RuntimeMode = 'documentation-first-sample-data'
$script:DataSourceMode = 'simulated-control-evidence'
$script:RuntimeWarning = 'Artifacts were generated from representative sample findings in the repository and do not confirm live tenant scans.'

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
        [string]$ModuleName,

        [Parameter()]
        [switch]$Optional
    )

    $modulePath = Join-Path (Join-Path (Get-RepositoryRoot) 'scripts\common') $ModuleName
    if (-not (Test-Path -Path $modulePath)) {
        if ($Optional) {
            return $false
        }

        throw "Shared module not found: $modulePath"
    }

    Import-Module $modulePath -Force
    return $true
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

function Get-EvidenceSchemaVersion {
    [CmdletBinding()]
    param()

    if (Get-Command -Name Get-CopilotGovEvidenceSchemaVersion -ErrorAction SilentlyContinue) {
        return (Get-CopilotGovEvidenceSchemaVersion)
    }

    return '1.1.0'
}

function Get-StatusNumericScore {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('implemented', 'partial', 'monitor-only', 'playbook-only')]
        [string]$Status
    )

    if (Get-Command -Name Get-CopilotGovStatusScore -ErrorAction SilentlyContinue) {
        return (Get-CopilotGovStatusScore -Status $Status)
    }

    switch ($Status) {
        'implemented' { return 100 }
        'partial' { return 50 }
        'monitor-only' { return 25 }
        'playbook-only' { return 10 }
    }
}

function Write-JsonArtifact {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [object]$Payload
    )

    $Payload | ConvertTo-Json -Depth 10 | Set-Content -Path $Path -Encoding utf8
    $hash = (Get-FileHash -Path $Path -Algorithm SHA256).Hash.ToLowerInvariant()
    $hashFilePath = $Path + '.sha256'
    Set-Content -Path $hashFilePath -Value ("{0}  {1}" -f $hash, [System.IO.Path]::GetFileName($Path)) -Encoding utf8

    return [pscustomobject]@{
        Path         = $Path
        Hash         = $hash
        HashFilePath = $hashFilePath
    }
}

function Get-ControlAssessments {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$Configuration
    )

    $permissionStatus = if ([bool]$Configuration.includeGuestAccounts) { 'partial' } else { 'monitor-only' }
    $permissionNotes = if ([bool]$Configuration.includeGuestAccounts) {
        'Permission model auditing includes guest exposure review, but remediation and exception approval remain customer-owned.'
    }
    else {
        'Guest account review is excluded in this tier, so permission model coverage is limited to internal sharing posture.'
    }

    $sharePointStatus = if (($Configuration.maxSitesScanned -eq -1) -or ([int]$Configuration.maxSitesScanned -ge 2000)) { 'partial' } else { 'monitor-only' }
    $sharePointNotes = if ($sharePointStatus -eq 'partial') {
        'SharePoint Advanced Management readiness is assessed across a broad site inventory, but operational enforcement still requires tenant action.'
    }
    else {
        'SharePoint Advanced Management readiness is sampled in this tier and should be expanded before production attestation.'
    }

    $licenseStatus = if ($Configuration.scanSchedule -in @('daily', 'continuous')) { 'partial' } else { 'monitor-only' }
    $licenseNotes = if ($licenseStatus -eq 'partial') {
        'License assignment and cohort review are monitored on an operational cadence, but procurement and exception approvals remain outside the scanner.'
    }
    else {
        'License planning is assessed at a summary level in this tier and should be supplemented with periodic business justification review.'
    }

    return @(
        [ordered]@{
            controlId = '1.1'
            status    = 'partial'
            notes     = 'Automated readiness and data hygiene checks cover the six defined scan domains, but business-owned content remediation remains outside automation.'
        },
        [ordered]@{
            controlId = '1.5'
            status    = 'monitor-only'
            notes     = 'Sensitivity label usage and coverage are inventoried, but taxonomy approval and legal interpretation remain compliance-led activities.'
        },
        [ordered]@{
            controlId = '1.6'
            status    = $permissionStatus
            notes     = $permissionNotes
        },
        [ordered]@{
            controlId = '1.7'
            status    = $sharePointStatus
            notes     = $sharePointNotes
        },
        [ordered]@{
            controlId = '1.9'
            status    = $licenseStatus
            notes     = $licenseNotes
        }
    )
}

function Get-OverallReadinessScore {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object[]]$Controls,

        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$Weights
    )

    $weightedScore = 0.0
    foreach ($control in $Controls) {
        $weight = if ($Weights.Contains($control.controlId)) { [double]$Weights[$control.controlId] } else { 0.0 }
        $weightedScore += ((Get-StatusNumericScore -Status $control.status) * $weight)
    }

    return [Math]::Round($weightedScore, 2)
}

try {
    if ($PeriodEnd -lt $PeriodStart) {
        throw 'PeriodEnd must be on or after PeriodStart.'
    }

    Import-SharedModule -ModuleName 'IntegrationConfig.psm1' -Optional | Out-Null
    Import-SharedModule -ModuleName 'EvidenceExport.psm1' | Out-Null
    $configuration = Get-SolutionConfiguration -Tier $ConfigurationTier
    $resolvedOutputPath = [System.IO.Path]::GetFullPath($OutputPath)
    $null = New-Item -ItemType Directory -Path $resolvedOutputPath -Force

    $periodStartText = $PeriodStart.ToString('yyyyMMdd')
    $periodEndText = $PeriodEnd.ToString('yyyyMMdd')

    $controls = Get-ControlAssessments -Configuration $configuration
    $overallReadinessScore = Get-OverallReadinessScore -Controls $controls -Weights $configuration.scoringWeights

    $findings = @(
        [ordered]@{
            findingId    = 'DH-001'
            domain       = 'purview'
            severity     = 'high'
            title        = 'Unlabeled collaboration content detected'
            description  = 'The scanner expects unlabeled or legacy-labeled content to be remediated before broad Copilot exposure.'
            controlId    = '1.1'
            recommendation = 'Review label inheritance and prioritize repositories with broad internal visibility.'
        },
        [ordered]@{
            findingId    = 'DH-002'
            domain       = 'identity'
            severity     = 'medium'
            title        = 'Privileged access review requires current attestation'
            description  = 'Privileged role assignments should be reconciled with business ownership before production rollout.'
            controlId    = '1.6'
            recommendation = 'Run a role attestation cycle and remove stale administrative assignments.'
        },
        [ordered]@{
            findingId    = 'DH-003'
            domain       = 'licensing'
            severity     = 'medium'
            title        = 'Copilot assignment cohort is not fully justified'
            description  = 'License allocation should align with approved cohorts, use cases, and supervisory oversight.'
            controlId    = '1.9'
            recommendation = 'Update assignment records and confirm procurement approvals for inactive or excess allocations.'
        }
    )

    if ([bool]$configuration.includeGuestAccounts) {
        $findings += [ordered]@{
            findingId      = 'DH-004'
            domain         = 'identity'
            severity       = 'medium'
            title          = 'Guest access review is in scope'
            description    = 'Guest account posture should be correlated with external sharing and sensitivity label boundaries.'
            controlId      = '1.6'
            recommendation = 'Review guest accounts with access to regulated collaboration spaces before expanding Copilot usage.'
        }
    }

    $remediationActions = @(
        [ordered]@{
            actionId      = 'RP-001'
            priority      = 'high'
            owner         = 'ComplianceEngineering'
            targetDate    = $PeriodEnd.AddDays(14).ToString('yyyy-MM-dd')
            relatedFinding = 'DH-001'
            action        = 'Expand sensitivity label remediation for high-exposure repositories.'
        },
        [ordered]@{
            actionId      = 'RP-002'
            priority      = 'high'
            owner         = 'IdentityOperations'
            targetDate    = $PeriodEnd.AddDays(21).ToString('yyyy-MM-dd')
            relatedFinding = 'DH-002'
            action        = 'Complete privileged access attestation and remove stale elevated assignments.'
        },
        [ordered]@{
            actionId      = 'RP-003'
            priority      = 'medium'
            owner         = 'CollaborationProgramOffice'
            targetDate    = $PeriodEnd.AddDays(30).ToString('yyyy-MM-dd')
            relatedFinding = 'DH-003'
            action        = 'Reconcile Copilot license assignments with the approved rollout wave.'
        }
    )

    if ([bool]$configuration.includeGuestAccounts) {
        $remediationActions += [ordered]@{
            actionId      = 'RP-004'
            priority      = 'medium'
            owner         = 'IdentityOperations'
            targetDate    = $PeriodEnd.AddDays(30).ToString('yyyy-MM-dd')
            relatedFinding = 'DH-004'
            action        = 'Validate guest access against external sharing policy and remove unsupported guest memberships.'
        }
    }

    $readinessArtifactName = "CRS-readiness-scorecard-{0}-{1}-{2}.json" -f $ConfigurationTier, $periodStartText, $periodEndText
    $findingsArtifactName = "CRS-data-hygiene-findings-{0}-{1}-{2}.json" -f $ConfigurationTier, $periodStartText, $periodEndText
    $remediationArtifactName = "CRS-remediation-plan-{0}-{1}-{2}.json" -f $ConfigurationTier, $periodStartText, $periodEndText
    $packageArtifactName = "CRS-evidence-package-{0}-{1}-{2}.json" -f $ConfigurationTier, $periodStartText, $periodEndText

    $readinessPayload = [ordered]@{
        metadata = [ordered]@{
            solution   = $configuration.solution
            solutionCode = $configuration.solutionCode
            tenantId   = $TenantId
            tier       = $ConfigurationTier
            periodStart = $PeriodStart.ToString('yyyy-MM-dd')
            periodEnd  = $PeriodEnd.ToString('yyyy-MM-dd')
            generatedAt = (Get-Date).ToString('o')
            runtimeMode = $script:RuntimeMode
            dataSourceMode = $script:DataSourceMode
            warning = $script:RuntimeWarning
        }
        summary = [ordered]@{
            overallReadinessScore = $overallReadinessScore
            alertThreshold        = $configuration.alertThreshold
            scanDomains           = $configuration.scanDomains
            reportFormat          = $configuration.reportFormat
            warning               = $script:RuntimeWarning
        }
        controls = $controls
    }

    $findingsPayload = [ordered]@{
        metadata = [ordered]@{
            solution   = $configuration.solution
            tenantId   = $TenantId
            tier       = $ConfigurationTier
            generatedAt = (Get-Date).ToString('o')
            runtimeMode = $script:RuntimeMode
            dataSourceMode = $script:DataSourceMode
            warning = $script:RuntimeWarning
        }
        findings = $findings
    }

    $remediationPayload = [ordered]@{
        metadata = [ordered]@{
            solution   = $configuration.solution
            tenantId   = $TenantId
            tier       = $ConfigurationTier
            generatedAt = (Get-Date).ToString('o')
            runtimeMode = $script:RuntimeMode
            dataSourceMode = $script:DataSourceMode
            warning = $script:RuntimeWarning
        }
        actions = $remediationActions
    }

    $readinessArtifact = Write-JsonArtifact -Path (Join-Path $resolvedOutputPath $readinessArtifactName) -Payload $readinessPayload
    $findingsArtifact = Write-JsonArtifact -Path (Join-Path $resolvedOutputPath $findingsArtifactName) -Payload $findingsPayload
    $remediationArtifact = Write-JsonArtifact -Path (Join-Path $resolvedOutputPath $remediationArtifactName) -Payload $remediationPayload

    $artifactEntries = @(
        [ordered]@{
            name = 'readiness-scorecard'
            type = 'readiness-scorecard'
            path = $readinessArtifact.Path
            hash = $readinessArtifact.Hash
        },
        [ordered]@{
            name = 'data-hygiene-findings'
            type = 'data-hygiene-findings'
            path = $findingsArtifact.Path
            hash = $findingsArtifact.Hash
        },
        [ordered]@{
            name = 'remediation-plan'
            type = 'remediation-plan'
            path = $remediationArtifact.Path
            hash = $remediationArtifact.Hash
        }
    )

    $monitorOnlyCount = @($controls | Where-Object { $_.status -eq 'monitor-only' }).Count
    $summary = [ordered]@{
        overallStatus  = 'partial'
        recordCount    = (1 + $findings.Count + $remediationActions.Count)
        findingCount   = $findings.Count
        exceptionCount = $monitorOnlyCount
    }

    $packagePayload = [ordered]@{
        metadata = [ordered]@{
            solution      = $configuration.solution
            solutionCode  = $configuration.solutionCode
            exportVersion = (Get-EvidenceSchemaVersion)
            exportedAt    = (Get-Date).ToString('o')
            tier          = $ConfigurationTier
            periodStart   = $PeriodStart.ToString('yyyy-MM-dd')
            periodEnd     = $PeriodEnd.ToString('yyyy-MM-dd')
            runtimeMode   = $script:RuntimeMode
            dataSourceMode = $script:DataSourceMode
            warning       = $script:RuntimeWarning
        }
        summary   = [ordered]@{
            overallStatus = $summary.overallStatus
            recordCount = $summary.recordCount
            findingCount = $summary.findingCount
            exceptionCount = $summary.exceptionCount
            statusSemantics = 'Control states describe documentation-first sample evidence and must not be treated as proof of live scanning depth.'
        }
        controls  = $controls
        artifacts = $artifactEntries
    }

    $packageArtifact = Write-JsonArtifact -Path (Join-Path $resolvedOutputPath $packageArtifactName) -Payload $packagePayload
    $validation = Test-CopilotGovEvidencePackage -Path $packageArtifact.Path -ExpectedArtifacts @($configuration.evidenceOutputs)
    if (-not $validation.IsValid) {
        $details = ($validation.Errors | ForEach-Object { ' - {0}' -f $_ }) -join [Environment]::NewLine
        throw ("Evidence validation failed for {0}:{1}{2}" -f $packageArtifact.Path, [Environment]::NewLine, $details)
    }

    [pscustomobject]@{
        PackagePath    = $packageArtifact.Path
        PackageHash    = $packageArtifact.Hash
        OverallStatus  = $summary.overallStatus
        RecordCount    = $summary.recordCount
        FindingCount   = $summary.findingCount
        ExceptionCount = $summary.exceptionCount
        ArtifactCount  = $artifactEntries.Count
        RuntimeMode    = $script:RuntimeMode
    }
}
catch {
    Write-Error -Message ("Evidence export failed: {0}" -f $_.Exception.Message)
    throw
}
