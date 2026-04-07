<#
.SYNOPSIS
Exports evidence for Copilot Connector and Plugin Governance.

.DESCRIPTION
Creates documentation-led connector inventory, approval register, and data-flow attestation
artifacts for the selected governance tier, writes SHA-256 companion files for every emitted
artifact, and packages the export by using the shared repository evidence contract.

.PARAMETER ConfigurationTier
Governance tier to report in the evidence package.

.PARAMETER OutputPath
Directory where the evidence package and companion artifacts are written.

.EXAMPLE
.\Export-Evidence.ps1 -ConfigurationTier regulated -OutputPath ..\artifacts
#>
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet('baseline', 'recommended', 'regulated')]
    [string]$ConfigurationTier = 'baseline',

    [Parameter()]
    [string]$OutputPath = (Join-Path $PSScriptRoot '..\artifacts')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$solutionRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

Import-Module (Join-Path $repoRoot 'scripts\common\EvidenceExport.psm1') -Force

function Read-JsonAsHashtable {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    return Get-Content -Path $Path -Raw -Encoding utf8 | ConvertFrom-Json -AsHashtable
}

function Merge-Hashtable {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$Base,

        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$Overlay
    )

    $result = [ordered]@{}
    foreach ($key in $Base.Keys) {
        $result[$key] = $Base[$key]
    }

    foreach ($key in $Overlay.Keys) {
        if ($result.Contains($key) -and ($result[$key] -is [System.Collections.IDictionary]) -and ($Overlay[$key] -is [System.Collections.IDictionary])) {
            $result[$key] = Merge-Hashtable -Base $result[$key] -Overlay $Overlay[$key]
            continue
        }

        $result[$key] = $Overlay[$key]
    }

    return $result
}

function Get-CpgConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('baseline', 'recommended', 'regulated')]
        [string]$Tier
    )

    $defaultConfig = Read-JsonAsHashtable -Path (Join-Path $solutionRoot 'config\default-config.json')
    $tierConfig = Read-JsonAsHashtable -Path (Join-Path $solutionRoot ("config\{0}.json" -f $Tier))
    return (Merge-Hashtable -Base $defaultConfig -Overlay $tierConfig)
}

function Write-ArtifactDocument {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [object]$Content
    )

    $Content | ConvertTo-Json -Depth 20 | Set-Content -Path $Path -Encoding utf8
    $hashInfo = Write-CopilotGovSha256File -Path $Path

    return [pscustomobject]@{
        name = $Name
        type = 'json'
        path = $Path
        hash = $hashInfo.Hash
    }
}

$config = Get-CpgConfiguration -Tier $ConfigurationTier
$resolvedOutputPath = [IO.Path]::GetFullPath($OutputPath)
$null = New-Item -ItemType Directory -Path $resolvedOutputPath -Force
$exportedAt = (Get-Date).ToString('o')

$connectorInventory = @(
    [pscustomobject]@{
        connectorId = 'shared_sharepointonline'
        displayName = 'SharePoint Online'
        publisher = 'Microsoft'
        riskLevel = 'low'
        approvalStatus = if (@($config.approvalModel.autoApprovedConnectorIds) -contains 'shared_sharepointonline') { 'approved' } else { 'pending-security-review' }
        dataFlowBoundaries = @('internal-m365')
        assetType = 'connector'
        publisherType = 'microsoft'
        certification = 'built-in'
        lastSeen = $exportedAt
        classificationReason = 'Microsoft-built connector with no external data egress.'
        requiresDataFlowAttestation = $false
    }
    [pscustomobject]@{
        connectorId = 'shared_salesforce'
        displayName = 'Salesforce'
        publisher = 'Salesforce'
        riskLevel = 'medium'
        approvalStatus = 'pending-security-review'
        dataFlowBoundaries = @('certified-third-party')
        assetType = 'connector'
        publisherType = 'certified-third-party'
        certification = 'certified'
        lastSeen = $exportedAt
        classificationReason = 'Certified third-party connector with controlled external egress.'
        requiresDataFlowAttestation = [bool]$config.dataFlowPolicy.requireAttestationForExternalEgress
    }
    [pscustomobject]@{
        connectorId = 'custom_corebanking'
        displayName = 'Custom Core Banking Connector'
        publisher = 'Contoso Bank Engineering'
        riskLevel = 'high'
        approvalStatus = 'submitted'
        dataFlowBoundaries = @('regulated-financial-systems')
        assetType = 'custom-connector'
        publisherType = 'custom'
        certification = 'not-applicable'
        lastSeen = $exportedAt
        classificationReason = 'Custom connector targets regulated financial systems and requires elevated review.'
        requiresDataFlowAttestation = $true
    }
    [pscustomobject]@{
        connectorId = 'shared_dropbox'
        displayName = 'Dropbox'
        publisher = 'Dropbox'
        riskLevel = 'blocked'
        approvalStatus = 'blocked'
        dataFlowBoundaries = @('personal-or-public-services')
        assetType = 'connector'
        publisherType = 'third-party'
        certification = 'Certified'
        lastSeen = $exportedAt
        classificationReason = 'Public storage connector is blocked in regulated Copilot contexts.'
        requiresDataFlowAttestation = $false
    }
)

$approvalRegister = @(
    foreach ($connector in @($connectorInventory | Where-Object { $_.approvalStatus -ne 'approved' })) {
        $slaHours = [int]$config.approvalSLAHours[$connector.riskLevel]
        [pscustomobject]@{
            requestId = ('CPG-{0}' -f $connector.connectorId.ToUpperInvariant())
            connectorId = $connector.connectorId
            displayName = $connector.displayName
            riskLevel = $connector.riskLevel
            requestedAt = $exportedAt
            dueBy = (Get-Date).AddHours($slaHours).ToString('o')
            approver = if ($connector.riskLevel -eq 'high') { 'CISO-DLP-Review' } else { 'Security-Review-Queue' }
            stages = if (($connector.riskLevel -eq 'high') -and $config.approvalModel.ContainsKey('highRiskReviewStages')) {
                @($config.approvalModel.highRiskReviewStages)
            }
            else {
                @($config.approvalModel.mandatoryReviewStages)
            }
            status = if ($connector.approvalStatus -eq 'blocked') { 'denied' } else { 'submitted' }
            notes = if ($connector.approvalStatus -eq 'blocked') {
                'Connector remains blocked because it targets a prohibited public-service boundary.'
            }
            else {
                'Approval workflow retains review timing and decision notes for supervisory review.'
            }
        }
    }
)

$dataFlowAttestations = @(
    foreach ($connector in @($connectorInventory | Where-Object { $_.requiresDataFlowAttestation })) {
        [pscustomobject]@{
            attestationId = ('CPG-ATT-{0}' -f $connector.connectorId.ToUpperInvariant())
            connectorId = $connector.connectorId
            displayName = $connector.displayName
            sourceBoundary = 'internal-m365'
            destinationBoundary = ($connector.dataFlowBoundaries -join ',')
            businessJustification = 'Approved business workflow requires controlled data movement for Copilot extensibility.'
            reviewedBy = if ($connector.riskLevel -eq 'high') { 'ThirdPartyRiskManagement' } else { 'Security Architecture' }
            attestedOn = $exportedAt
            expirationDate = if ($config.dataFlowPolicy.ContainsKey('requireAnnualReattestation') -and $config.dataFlowPolicy.requireAnnualReattestation) {
                (Get-Date).AddDays(365).ToString('yyyy-MM-dd')
            }
            else {
                $null
            }
            status = if ($connector.riskLevel -eq 'high') { 'pending' } else { 'approved' }
        }
    }
)

$inventoryArtifact = Write-ArtifactDocument -Path (Join-Path $resolvedOutputPath 'connector-inventory.json') -Name 'connector-inventory' -Content $connectorInventory
$approvalArtifact = Write-ArtifactDocument -Path (Join-Path $resolvedOutputPath 'approval-register.json') -Name 'approval-register' -Content $approvalRegister
$attestationArtifact = Write-ArtifactDocument -Path (Join-Path $resolvedOutputPath 'data-flow-attestations.json') -Name 'data-flow-attestations' -Content $dataFlowAttestations

$controls = @(
    [pscustomobject]@{
        controlId = '1.13'
        status = 'partial'
        notes = 'Connector inventory and risk classification are exported, but third-party due diligence still requires manual review.'
    }
    [pscustomobject]@{
        controlId = '2.13'
        status = 'implemented'
        notes = 'Data-flow boundaries and attestation records document approved cross-boundary connector usage.'
    }
    [pscustomobject]@{
        controlId = '2.14'
        status = 'implemented'
        notes = 'Approval-register export captures reviewer routing, SLA timing, and escalation stages for connector enablement.'
    }
    [pscustomobject]@{
        controlId = '4.13'
        status = 'partial'
        notes = 'Operational monitoring records blocked and pending connectors, while DORA register reconciliation remains a manual control.'
    }
)

$artifacts = @($inventoryArtifact, $approvalArtifact, $attestationArtifact)
$package = Export-SolutionEvidencePackage `
    -Solution '10-connector-plugin-governance' `
    -SolutionCode 'CPG' `
    -Tier $ConfigurationTier `
    -OutputPath $resolvedOutputPath `
    -Summary @{
        overallStatus = if (@($controls | Where-Object { $_.status -ne 'implemented' }).Count -eq 0) { 'implemented' } else { 'partial' }
        recordCount = ($connectorInventory.Count + $approvalRegister.Count + $dataFlowAttestations.Count)
        findingCount = @($approvalRegister | Where-Object { $_.status -ne 'approved' }).Count
        exceptionCount = @($dataFlowAttestations | Where-Object { $_.status -ne 'approved' }).Count
        manualActionsRequired = @(
            'Reconcile approved third-party connectors to the DORA ICT third-party register.',
            'Complete manual due diligence review for high-risk and custom connectors before production rollout.'
        )
    } `
    -Controls $controls `
    -Artifacts $artifacts

[pscustomobject]@{
    Package = $package
    Controls = $controls
    Artifacts = $artifacts
}
