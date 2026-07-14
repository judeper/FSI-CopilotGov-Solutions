<#
.SYNOPSIS
    Exports CTAF evidence artifacts as JSON files with SHA-256 companion sidecars.

.DESCRIPTION
    Documentation-first evidence export. Invokes Monitor-Compliance.ps1 to gather a
    sample snapshot, then writes four evidence artifacts: agent-federation-inventory,
    cross-tenant-trust-assessment, mcp-trust-relationship-log, and
    agent-id-attestation-evidence. Each artifact is paired with a .sha256 sidecar.

.PARAMETER ConfigurationTier
    Governance tier: baseline, recommended, or regulated.

.PARAMETER OutputPath
    Path for exported evidence artifacts.

.PARAMETER PeriodStart
    Beginning of the evidence window (defaults to 30 days ago).

.PARAMETER PeriodEnd
    End of the evidence window (defaults to now).

.PARAMETER PassThru
    Returns the evidence summary object after writing artifacts.

.PARAMETER WhatIf
    Builds the evidence plan in memory and returns it without writing any JSON artifacts, SHA-256
    companions, or the evidence package. Useful for read-only lab validation that must leave no
    local artifacts. Planned artifact paths are returned with null hashes and a null package path.

.EXAMPLE
    .\Export-Evidence.ps1 -ConfigurationTier recommended -Verbose

.EXAMPLE
    .\Export-Evidence.ps1 -ConfigurationTier regulated -PassThru -WhatIf

.NOTES
    Solution: Cross-Tenant Agent Federation Auditor (CTAF)
    Version:  v0.1.3
    Status:   Documentation-first scaffold (sample data only)
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter()]
    [ValidateSet('baseline', 'recommended', 'regulated')]
    [string]$ConfigurationTier = 'baseline',

    [Parameter()]
    [string]$OutputPath = (Join-Path $PSScriptRoot '..\artifacts'),

    [Parameter()]
    [datetime]$PeriodStart = (Get-Date).Date.AddDays(-30),

    [Parameter()]
    [datetime]$PeriodEnd = (Get-Date),

    [Parameter()]
    [switch]$PassThru
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path $PSScriptRoot 'CtafConfig.psm1') -Force
Import-Module (Join-Path $PSScriptRoot '..\..\..\scripts\common\EvidenceExport.psm1') -Force

if ($PeriodEnd -lt $PeriodStart) {
    throw 'PeriodEnd must be greater than or equal to PeriodStart.'
}

function New-CtafArtifactFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string]$Path,
        [Parameter(Mandatory)] [object]$Content
    )

    $directory = Split-Path -Path $Path -Parent
    $null = New-Item -ItemType Directory -Path $directory -Force
    $Content | ConvertTo-Json -Depth 10 | Set-Content -Path $Path -Encoding utf8
    $hashInfo = Write-CtafSha256File -Path $Path

    return [pscustomobject]@{
        Path = $Path
        Hash = $hashInfo.Hash
    }
}

Write-Verbose ("Loading CTAF configuration for tier [{0}]." -f $ConfigurationTier)
$configuration = Get-CtafConfiguration -Tier $ConfigurationTier
Test-CtafConfiguration -Configuration $configuration

$resolvedOutputPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputPath)
$monitorScript = Join-Path $PSScriptRoot 'Monitor-Compliance.ps1'

Write-Verbose 'Collecting monitoring snapshot for evidence export.'
$snapshot = & $monitorScript -ConfigurationTier $ConfigurationTier -OutputPath $resolvedOutputPath -PassThru -Verbose:$($VerbosePreference -eq 'Continue')

$envelope = {
    param($recordsArr)
    [ordered]@{
        solution = $configuration.solution
        tier = $ConfigurationTier
        periodStart = $PeriodStart.ToString('o')
        periodEnd = $PeriodEnd.ToString('o')
        generatedAt = (Get-Date).ToString('o')
        runtimeMode = 'sample'
        warning = $snapshot.Warning
        retentionDays = $configuration.evidenceRetentionDays
        records = $recordsArr
    }
}

$artifactPlans = @(
    [pscustomobject]@{ name = 'agent-federation-inventory'; fileName = ("agent-federation-inventory-{0}.json" -f $ConfigurationTier); content = (& $envelope @($snapshot.FederationInventory)) }
    [pscustomobject]@{ name = 'cross-tenant-trust-assessment'; fileName = ("cross-tenant-trust-assessment-{0}.json" -f $ConfigurationTier); content = (& $envelope @($snapshot.CrossTenantTrust)) }
    [pscustomobject]@{ name = 'mcp-trust-relationship-log'; fileName = ("mcp-trust-relationship-log-{0}.json" -f $ConfigurationTier); content = (& $envelope @($snapshot.McpAttestations)) }
    [pscustomobject]@{ name = 'agent-id-attestation-evidence'; fileName = ("agent-id-attestation-evidence-{0}.json" -f $ConfigurationTier); content = (& $envelope @($snapshot.AgentIdAttestations)) }
)

$controls = @(
    [pscustomobject]@{
        controlId = '2.17'
        status = 'partial'
        notes = 'Entra Agent ID identity-governance review evidence is exported using sample records; live Microsoft Graph integration is required for production evidence.'
    },
    [pscustomobject]@{
        controlId = '2.16'
        status = 'partial'
        notes = 'Cross-tenant access posture is exported using sample records; live cross-tenant access policy enumeration is required for production evidence.'
    },
    [pscustomobject]@{
        controlId = '1.10'
        status = 'monitor-only'
        notes = 'Third-party connector inventory is referenced via the MCP connection review log; full third-party register lives outside this solution.'
    },
    [pscustomobject]@{
        controlId = '2.13'
        status = 'monitor-only'
        notes = 'Copilot Studio publishing settings are sampled; live admin API enumeration is roadmapped.'
    },
    [pscustomobject]@{
        controlId = '2.14'
        status = 'partial'
        notes = 'MCP server connection/authentication posture is recorded in mcp-trust-relationship-log; live tool approval and allow-list integration is roadmapped.'
    },
    [pscustomobject]@{
        controlId = '4.13'
        status = 'monitor-only'
        notes = 'Cross-tenant audit log retention is documented per tier; live aggregation requires Sentinel or equivalent provisioning.'
    }
)

# Artifact files and their package/result entries are produced in the ShouldProcess block below so
# that -WhatIf can return a read-only evidence plan without writing any files.

$recordCount = @($snapshot.FederationInventory).Count + @($snapshot.CrossTenantTrust).Count + @($snapshot.McpAttestations).Count + @($snapshot.AgentIdAttestations).Count
$findingCount = (@($snapshot.CrossTenantTrust) | Where-Object { $_.reviewStatus -ne 'current' }).Count +
                (@($snapshot.McpAttestations) | Where-Object { $_.connectionReviewStatus -ne 'current' }).Count +
                (@($snapshot.AgentIdAttestations) | Where-Object { $_.reviewStatus -ne 'current' }).Count
$exceptionCount = ($controls | Where-Object { $_.status -ne 'implemented' }).Count

$packageSummary = @{
    overallStatus = 'partial'
    recordCount = $recordCount
    findingCount = $findingCount
    exceptionCount = $exceptionCount
}

$packageMetadata = [ordered]@{
    generatedAt = (Get-Date).ToString('o')
    runtimeMode = 'sample'
    documentationFirstNotice = 'Evidence package generated from documentation-first sample data; not suitable for examiner submission.'
}

$expectedArtifacts = @(
    'agent-federation-inventory',
    'cross-tenant-trust-assessment',
    'mcp-trust-relationship-log',
    'agent-id-attestation-evidence'
)

$resultArtifacts = @()
$package = [pscustomobject]@{ Path = $null; Hash = $null; HashPath = $null }

if ($PSCmdlet.ShouldProcess($resolvedOutputPath, ("Export CTAF evidence package for tier {0}" -f $ConfigurationTier))) {
    $null = New-Item -ItemType Directory -Path $resolvedOutputPath -Force

    # Package artifact entries use package-relative file names so the exported package stays valid
    # when the evidence directory is relocated (the shared validator resolves relative paths against
    # the package directory). Returned artifact entries use absolute paths so callers can locate them.
    $packageArtifacts = @()
    foreach ($plan in $artifactPlans) {
        $file = New-CtafArtifactFile -Path (Join-Path $resolvedOutputPath $plan.fileName) -Content $plan.content
        $packageArtifacts += [pscustomobject]@{ name = $plan.name; type = 'json'; path = $plan.fileName; hash = $file.Hash }
        $resultArtifacts += [pscustomobject]@{ name = $plan.name; type = 'json'; path = $file.Path; hash = $file.Hash }
    }

    $package = Export-SolutionEvidencePackage `
        -Solution $configuration.solution `
        -SolutionCode $configuration.solutionCode `
        -Tier $ConfigurationTier `
        -OutputPath $resolvedOutputPath `
        -PackageFileName ("ctaf-evidence-package-{0}.json" -f $ConfigurationTier) `
        -Summary $packageSummary `
        -Controls $controls `
        -Artifacts $packageArtifacts `
        -ExpectedArtifacts $expectedArtifacts `
        -AdditionalMetadata $packageMetadata
}
else {
    Write-Verbose 'WhatIf enabled. Returning evidence plan without writing artifacts or package.'
    foreach ($plan in $artifactPlans) {
        $resultArtifacts += [pscustomobject]@{
            name = $plan.name
            type = 'json'
            path = (Join-Path $resolvedOutputPath $plan.fileName)
            hash = $null
        }
    }
}

$result = [pscustomobject]@{
    Summary = $packageSummary
    Controls = $controls
    Artifacts = $resultArtifacts
    Package = $package
    PackagePath = $package.Path
    PackageHash = $package.Hash
    RuntimeMode = 'sample'
}

if ($PassThru) {
    return $result
}

$result
