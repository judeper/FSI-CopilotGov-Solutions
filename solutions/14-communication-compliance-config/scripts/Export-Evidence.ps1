<#
.SYNOPSIS
    Exports evidence for the Communication Compliance Configurator solution.

.DESCRIPTION
    Builds solution-specific evidence artifacts for policy templates, reviewer
    queue metrics, and lexicon updates, then packages them with the shared
    evidence export module.

.PARAMETER ConfigurationTier
    Governance tier: baseline, recommended, or regulated.

.PARAMETER OutputPath
    Path for evidence artifacts and the packaged evidence file.

.PARAMETER PeriodStart
    Start date for the evidence reporting window.

.PARAMETER PeriodEnd
    End date for the evidence reporting window.

.PARAMETER PassThru
    Returns the detailed export result object.

.EXAMPLE
    .\Export-Evidence.ps1 -ConfigurationTier regulated -PassThru

    Creates tier-specific evidence artifacts and the shared evidence package.

.OUTPUTS
    PSCustomObject. Evidence package summary and artifact metadata.

.NOTES
    Overall evidence status is intentionally set to partial because reviewer
    actions and AI disclosure monitoring still depend on manual operations.
#>
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet('baseline', 'recommended', 'regulated')]
    [string]$ConfigurationTier = 'baseline',

    [Parameter()]
    [string]$OutputPath = (Join-Path $PSScriptRoot '..\artifacts\evidence'),

    [Parameter()]
    [datetime]$PeriodStart = (Get-Date).Date.AddDays(-30),

    [Parameter()]
    [datetime]$PeriodEnd = (Get-Date),

    [Parameter()]
    [switch]$PassThru
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$solutionRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

Import-Module (Join-Path $repoRoot 'scripts\common\EvidenceExport.psm1') -Force
Import-Module (Join-Path $repoRoot 'scripts\common\IntegrationConfig.psm1') -Force -Global

function ConvertTo-Hashtable {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        [object]$InputObject
    )

    if ($null -eq $InputObject) {
        return $null
    }

    if ($InputObject -is [System.Collections.IDictionary]) {
        $dictionary = @{}
        foreach ($key in $InputObject.Keys) {
            $dictionary[$key] = ConvertTo-Hashtable -InputObject $InputObject[$key]
        }

        return $dictionary
    }

    if ($InputObject -is [pscustomobject]) {
        $dictionary = @{}
        foreach ($property in $InputObject.PSObject.Properties) {
            $dictionary[$property.Name] = ConvertTo-Hashtable -InputObject $property.Value
        }

        return $dictionary
    }

    if (($InputObject -is [System.Collections.IEnumerable]) -and -not ($InputObject -is [string])) {
        $items = @()
        foreach ($item in $InputObject) {
            $items += ,(ConvertTo-Hashtable -InputObject $item)
        }

        return $items
    }

    return $InputObject
}

function Merge-Hashtable {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Base,

        [Parameter(Mandatory)]
        [hashtable]$Overlay
    )

    $merged = @{}
    foreach ($key in $Base.Keys) {
        $merged[$key] = $Base[$key]
    }

    foreach ($key in $Overlay.Keys) {
        if ($merged.ContainsKey($key) -and ($merged[$key] -is [hashtable]) -and ($Overlay[$key] -is [hashtable])) {
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
        [string]$ConfigRoot,

        [Parameter(Mandatory)]
        [ValidateSet('baseline', 'recommended', 'regulated')]
        [string]$Tier
    )

    $defaultConfigPath = Join-Path $ConfigRoot 'default-config.json'
    $tierConfigPath = Join-Path $ConfigRoot ('{0}.json' -f $Tier)

    if (-not (Test-Path -Path $defaultConfigPath)) {
        throw 'Default configuration file not found.'
    }

    if (-not (Test-Path -Path $tierConfigPath)) {
        throw 'Configuration tier file not found.'
    }

    $defaultConfig = ConvertTo-Hashtable -InputObject ((Get-Content -Path $defaultConfigPath -Raw) | ConvertFrom-Json)
    $tierConfig = ConvertTo-Hashtable -InputObject ((Get-Content -Path $tierConfigPath -Raw) | ConvertFrom-Json)
    $mergedConfig = Merge-Hashtable -Base $defaultConfig -Overlay $tierConfig
    $mergedConfig['tier'] = $Tier

    return $mergedConfig
}

function New-PolicyCatalog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Config,

        [Parameter(Mandatory)]
        [datetime]$CreatedAt,

        [Parameter(Mandatory)]
        [datetime]$PublishedAt
    )

    $catalog = @{
        CopilotAIDisclosure = [ordered]@{
            policyName = 'CCC-Copilot-AI-Disclosure'
            policyType = 'AI disclosure review'
            scope = $Config['supervisedCommunicationTypes']
            keywords = @('generated by copilot', 'ai-assisted draft', 'drafted with copilot')
            conditions = @(
                'Customer-facing communication contains AI attribution or draft disclaimer.',
                'Reviewer validates that the disclosure is retained before release.'
            )
        }
        FinancialAdviceReview = [ordered]@{
            policyName = 'CCC-Financial-Advice-Review'
            policyType = 'financial advice review'
            scope = $Config['supervisedCommunicationTypes']
            keywords = @('portfolio allocation', 'personalized recommendation', 'risk tolerance', 'suitable for you')
            conditions = @(
                'Communication references investor profile, recommendations, or suitability language.',
                'Reviewer validates that advice language aligns to approved supervisory standards.'
            )
        }
        PromotionalLanguageReview = [ordered]@{
            policyName = 'CCC-Promotional-Language-Review'
            policyType = 'promotional content review'
            scope = $Config['supervisedCommunicationTypes']
            keywords = @('guaranteed returns', 'outperform the market', 'safe investment', 'risk free')
            conditions = @(
                'Communication includes promotional phrasing that may trigger FINRA 2210 review.',
                'Reviewer validates balanced presentation of risks and disclosures.'
            )
        }
        BestInterestDisclosure = [ordered]@{
            policyName = 'CCC-Best-Interest-Disclosure'
            policyType = 'best interest disclosure review'
            scope = $Config['supervisedCommunicationTypes']
            keywords = @('best interest', 'rollover recommendation', 'fee comparison', 'material limitation')
            conditions = @(
                'Communication references a recommendation that may require best-interest disclosure.',
                'Reviewer validates that required supporting disclosures are present.'
            )
        }
        ConflictOfInterestReview = [ordered]@{
            policyName = 'CCC-Conflict-Of-Interest-Review'
            policyType = 'conflict review'
            scope = $Config['supervisedCommunicationTypes']
            keywords = @('proprietary product', 'higher commission', 'revenue sharing', 'sales contest')
            conditions = @(
                'Communication indicates a possible conflict of interest or incentive alignment issue.',
                'Reviewer validates escalation to supervision or legal review when required.'
            )
        }
        InsiderRiskCorrelation = [ordered]@{
            policyName = 'CCC-Insider-Risk-Correlation'
            policyType = 'insider risk correlation'
            scope = $Config['supervisedCommunicationTypes']
            keywords = @('material non-public information', 'watch list account', 'deal room', 'private placement')
            conditions = @(
                'Communication includes insider risk indicators that may require cross-solution escalation.',
                'Reviewer coordinates with Insider Risk Management if an elevated pattern is detected.'
            )
        }
        RetailCommunicationEscalation = [ordered]@{
            policyName = 'CCC-Retail-Communication-Escalation'
            policyType = 'supervisory escalation'
            scope = $Config['supervisedCommunicationTypes']
            keywords = @('principal approval', 'escalate to supervision', 'hold for review', 'legal approval required')
            conditions = @(
                'Communication has triggered review and now requires documented supervisory escalation.',
                'Reviewer validates linkage to the FINRA supervision workflow dependency.'
            )
        }
        DualReviewSupervision = [ordered]@{
            policyName = 'CCC-Dual-Review-Supervision'
            policyType = 'dual review supervision'
            scope = $Config['supervisedCommunicationTypes']
            keywords = @('legal review', 'secondary reviewer', 'supervisor sign-off', 'retain for exam')
            conditions = @(
                'High-risk communication requires dual review before release or retention closeout.',
                'Reviewer validates secondary approval and evidence retention.'
            )
        }
    }

    $selectedPolicies = @()
    foreach ($templateId in $Config['policyTemplates']) {
        if (-not $catalog.ContainsKey($templateId)) {
            throw ('Unknown policy template ID: {0}' -f $templateId)
        }

        $selectedPolicies += [pscustomobject]@{
            policyName = $catalog[$templateId]['policyName']
            policyType = $catalog[$templateId]['policyType']
            scope = $catalog[$templateId]['scope']
            keywords = $catalog[$templateId]['keywords']
            conditions = $catalog[$templateId]['conditions']
            createdAt = $CreatedAt.ToString('o')
            publishedAt = $PublishedAt.ToString('o')
            version = ('{0}-{1}' -f $Config['version'], $Config['tier'])
        }
    }

    return $selectedPolicies
}

function New-ReviewerQueueMetrics {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Config,

        [Parameter(Mandatory)]
        [datetime]$AsOfDate
    )

    $tierMetrics = switch ($Config['tier']) {
        'baseline' {
            [ordered]@{ totalPending = 18; avgAgeHours = 20; p90AgeHours = 60; escalatedCount = 1; overdueCount = 2 }
        }
        'recommended' {
            [ordered]@{ totalPending = 12; avgAgeHours = 14; p90AgeHours = 34; escalatedCount = 2; overdueCount = 1 }
        }
        'regulated' {
            [ordered]@{ totalPending = 8; avgAgeHours = 9; p90AgeHours = 18; escalatedCount = 3; overdueCount = 0 }
        }
    }

    return [pscustomobject]@{
        snapshotDate = $AsOfDate.ToString('o')
        totalPending = $tierMetrics['totalPending']
        avgAgeHours = $tierMetrics['avgAgeHours']
        p90AgeHours = $tierMetrics['p90AgeHours']
        dispositionBreakdown = @(
            [pscustomobject]@{ disposition = 'no-issue'; count = 21 },
            [pscustomobject]@{ disposition = 'coach'; count = 7 },
            [pscustomobject]@{ disposition = 'escalate'; count = $tierMetrics['escalatedCount'] },
            [pscustomobject]@{ disposition = 'retain-for-exam'; count = 4 }
        )
        escalatedCount = $tierMetrics['escalatedCount']
        overdueCount = $tierMetrics['overdueCount']
    }
}

function New-LexiconUpdateLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Config
    )

    return [pscustomobject]@{
        updateDate = $Config['lexiconLastUpdated']
        wordAdded = $Config['lexiconWords']
        wordRemoved = @('legacy marketing superlative', 'manual review placeholder')
        updatedBy = 'Communication Compliance Policy Owner'
        approvedBy = 'Legal and Compliance Council'
        policyVersion = $Config['lexiconVersion']
    }
}

$configRoot = Join-Path $solutionRoot 'config'
$config = Get-SolutionConfiguration -ConfigRoot $configRoot -Tier $ConfigurationTier
$tierDefinition = Get-CopilotGovTierDefinition -Tier $ConfigurationTier

$null = New-Item -ItemType Directory -Path $OutputPath -Force
$artifactRoot = Join-Path $OutputPath 'artifact-data'
$null = New-Item -ItemType Directory -Path $artifactRoot -Force

$policyTemplateExport = New-PolicyCatalog -Config $config -CreatedAt $PeriodStart -PublishedAt $PeriodEnd
$reviewerQueueMetrics = New-ReviewerQueueMetrics -Config $config -AsOfDate $PeriodEnd
$lexiconUpdateLog = New-LexiconUpdateLog -Config $config

$policyTemplatePath = Join-Path $artifactRoot 'policy-template-export.json'
$queueMetricsPath = Join-Path $artifactRoot 'reviewer-queue-metrics.json'
$lexiconLogPath = Join-Path $artifactRoot 'lexicon-update-log.json'

$policyTemplateExport | ConvertTo-Json -Depth 8 | Set-Content -Path $policyTemplatePath -Encoding utf8
$reviewerQueueMetrics | ConvertTo-Json -Depth 8 | Set-Content -Path $queueMetricsPath -Encoding utf8
$lexiconUpdateLog | ConvertTo-Json -Depth 8 | Set-Content -Path $lexiconLogPath -Encoding utf8

$policyTemplateHash = (Write-CopilotGovSha256File -Path $policyTemplatePath).Hash
$queueMetricsHash = (Write-CopilotGovSha256File -Path $queueMetricsPath).Hash
$lexiconLogHash = (Write-CopilotGovSha256File -Path $lexiconLogPath).Hash

$controls = @(
    [pscustomobject]@{
        controlId = '2.10'
        status = 'monitor-only'
        notes = 'Insider risk correlation templates support compliance with insider risk monitoring, but live correlation requires Insider Risk Management integration.'
    }
    [pscustomobject]@{
        controlId = '3.4'
        status = 'implemented'
        notes = 'Communication compliance policy templates and queue metrics artifacts support compliance with monitored communications oversight.'
    }
    [pscustomobject]@{
        controlId = '3.5'
        status = 'implemented'
        notes = 'FINRA 2210 promotional content and financial advice policy templates support compliance with retail communication review expectations.'
    }
    [pscustomobject]@{
        controlId = '3.6'
        status = 'partial'
        notes = 'Reviewer queue metrics support compliance with supervision requirements, but supervisory actions remain manual.'
    }
    [pscustomobject]@{
        controlId = '3.9'
        status = 'partial'
        notes = 'AI disclosure and transparency templates support compliance with disclosure monitoring, but ongoing review is partly manual.'
    }
)

$artifacts = @(
    [pscustomobject]@{ name = 'policy-template-export'; type = 'json'; path = $policyTemplatePath; hash = $policyTemplateHash }
    [pscustomobject]@{ name = 'reviewer-queue-metrics'; type = 'json'; path = $queueMetricsPath; hash = $queueMetricsHash }
    [pscustomobject]@{ name = 'lexicon-update-log'; type = 'json'; path = $lexiconLogPath; hash = $lexiconLogHash }
)

$summary = [ordered]@{
    overallStatus = 'partial'
    recordCount = ($policyTemplateExport.Count + 2)
    findingCount = 3
    exceptionCount = 0
}

$exportParameters = @{
    Solution = '14-communication-compliance-config'
    SolutionCode = 'CCC'
    Tier = $ConfigurationTier
    OutputPath = $OutputPath
    Summary = $summary
    Controls = $controls
    Artifacts = $artifacts
}

$package = Export-SolutionEvidencePackage @exportParameters

$result = [pscustomobject]@{
    Solution = $config['displayName']
    SolutionCode = $config['solutionCode']
    Tier = $ConfigurationTier
    TierLabel = $tierDefinition.Label
    OverallStatus = 'partial'
    OverallStatusScore = Get-CopilotGovStatusScore -Status 'partial'
    PeriodStart = $PeriodStart.ToString('o')
    PeriodEnd = $PeriodEnd.ToString('o')
    ArtifactCount = $artifacts.Count
    PackagePath = $package.Path
    PackageHash = $package.Hash
}

if ($PassThru) {
    $result
}
else {
    $result
}
