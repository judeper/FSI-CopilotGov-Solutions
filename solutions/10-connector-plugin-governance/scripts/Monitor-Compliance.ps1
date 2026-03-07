<#
.SYNOPSIS
Evaluates the current compliance state of Copilot Connector and Plugin Governance.

.DESCRIPTION
Compares the current connector inventory to the approved baseline, identifies new or
unapproved connectors, checks approval workflow SLA adherence, and prepares an operational
status report. When requested, the script creates an alert preview for newly detected
connectors that require review.

.PARAMETER ConfigurationTier
Governance tier to evaluate.

.PARAMETER AlertOnNewConnectors
When supplied, generates a Teams notification preview when new connectors are detected.

.PARAMETER OutputPath
Directory that contains prior deployment artifacts and where the compliance status file
should be written.

.EXAMPLE
.\Monitor-Compliance.ps1 -ConfigurationTier regulated -AlertOnNewConnectors -OutputPath ..\artifacts

.NOTES
This script supports compliance with FINRA 3110, OCC 2011-12, and DORA by highlighting
inventory drift and overdue approval actions.
#>
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet('baseline', 'recommended', 'regulated')]
    [string]$ConfigurationTier = 'baseline',

    [Parameter()]
    [switch]$AlertOnNewConnectors,

    [Parameter()]
    [string]$OutputPath = (Join-Path $PSScriptRoot '..\artifacts')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$solutionRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

Import-Module (Join-Path $repoRoot 'scripts\common\IntegrationConfig.psm1') -Force
Import-Module (Join-Path $repoRoot 'scripts\common\TeamsNotification.psm1') -Force

function Get-ConnectorGovernanceConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$SolutionRoot,

        [Parameter(Mandatory)]
        [ValidateSet('baseline', 'recommended', 'regulated')]
        [string]$Tier
    )

    return [pscustomobject]@{
        Default = Get-Content -Path (Join-Path $SolutionRoot 'config\default-config.json') -Raw | ConvertFrom-Json -Depth 20
        Baseline = Get-Content -Path (Join-Path $SolutionRoot 'config\baseline.json') -Raw | ConvertFrom-Json -Depth 20
        Tier = Get-Content -Path (Join-Path $SolutionRoot ("config\{0}.json" -f $Tier)) -Raw | ConvertFrom-Json -Depth 20
    }
}

function Get-ArtifactContent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [scriptblock]$FallbackFactory
    )

    if (Test-Path -Path $Path) {
        return @(Get-Content -Path $Path -Raw | ConvertFrom-Json -Depth 20)
    }

    return @(& $FallbackFactory)
}

function Measure-ConnectorRisk {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Connector,

        [Parameter(Mandatory)]
        [pscustomobject]$DefaultConfig
    )

    if ($Connector.PSObject.Properties.Name -contains 'riskLevel' -and $Connector.riskLevel) {
        return $Connector.riskLevel
    }

    if ($DefaultConfig.blockedConnectorIds -contains $Connector.connectorId) {
        return 'blocked'
    }

    if (($Connector.publisherType -eq 'microsoft') -and -not $Connector.allowsExternalEgress) {
        return 'low'
    }

    if (($Connector.publisherType -eq 'third-party') -and ($Connector.certification -eq 'Certified') -and -not $Connector.supportsFinancialData) {
        return 'medium'
    }

    return 'high'
}

function Get-UnapprovedConnectors {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object[]]$CurrentInventory,

        [Parameter(Mandatory)]
        [string[]]$ApprovedBaselineConnectorIds,

        [Parameter(Mandatory)]
        [ValidateSet('baseline', 'recommended', 'regulated')]
        [string]$ConfigurationTier,

        [Parameter(Mandatory)]
        [pscustomobject]$DefaultConfig
    )

    $unapproved = foreach ($connector in $CurrentInventory) {
        $riskLevel = Measure-ConnectorRisk -Connector $connector -DefaultConfig $DefaultConfig
        $approvalStatus = if ($connector.PSObject.Properties.Name -contains 'approvalStatus' -and $connector.approvalStatus) {
            $connector.approvalStatus
        }
        elseif ($ConfigurationTier -eq 'regulated') {
            'pending-regulated-review'
        }
        elseif ($ApprovedBaselineConnectorIds -contains $connector.connectorId -and $riskLevel -eq 'low') {
            'approved'
        }
        else {
            'pending-review'
        }

        $isNewConnector = $ApprovedBaselineConnectorIds -notcontains $connector.connectorId
        if ($approvalStatus -ne 'approved' -or $isNewConnector) {
            [pscustomobject]@{
                connectorId = $connector.connectorId
                displayName = $connector.displayName
                riskLevel = $riskLevel
                approvalStatus = $approvalStatus
                isNewConnector = $isNewConnector
                dataFlowBoundaries = @($connector.dataFlowBoundaries)
            }
        }
    }

    return @($unapproved)
}

function Test-ApprovalSLA {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object[]]$ApprovalRequests
    )

    $now = Get-Date

    $violations = foreach ($request in $ApprovalRequests) {
        if ($request.status -in @('approved', 'denied', 'blocked')) {
            continue
        }

        $dueBy = if ($request.PSObject.Properties.Name -contains 'dueBy' -and $request.dueBy) {
            [datetime]$request.dueBy
        }
        else {
            ([datetime]$request.requestedAt).AddHours(24)
        }

        if ($dueBy -lt $now) {
            [pscustomobject]@{
                requestId = $request.requestId
                connectorId = $request.connectorId
                displayName = $request.displayName
                approver = $request.approver
                overdueHours = [math]::Round(($now - $dueBy).TotalHours, 2)
                currentStage = if ($request.PSObject.Properties.Name -contains 'status') { $request.status } else { 'submitted' }
            }
        }
    }

    return @($violations)
}

try {
    $config = Get-ConnectorGovernanceConfiguration -SolutionRoot $solutionRoot -Tier $ConfigurationTier
    $baselineApprovedConnectorIds = @($config.Baseline.approvalModel.autoApprovedConnectorIds)

    $inventoryPath = Join-Path $OutputPath 'cpg-connector-inventory.json'
    $approvalRegisterPath = Join-Path $OutputPath 'cpg-approval-register.json'
    $statusPath = Join-Path $OutputPath 'cpg-compliance-status.json'

    $currentInventory = Get-ArtifactContent -Path $inventoryPath -FallbackFactory {
        @(
            [pscustomobject]@{
                connectorId = 'shared_sharepointonline'
                displayName = 'SharePoint'
                publisherType = 'microsoft'
                certification = 'Microsoft'
                allowsExternalEgress = $false
                supportsFinancialData = $false
                dataFlowBoundaries = @('internal-m365')
                approvalStatus = if ($ConfigurationTier -eq 'regulated') { 'pending-regulated-review' } else { 'approved' }
            }
            [pscustomobject]@{
                connectorId = 'shared_salesforce'
                displayName = 'Salesforce'
                publisherType = 'third-party'
                certification = 'Certified'
                allowsExternalEgress = $true
                supportsFinancialData = $false
                dataFlowBoundaries = @('certified-third-party')
                approvalStatus = 'pending-security-review'
            }
            [pscustomobject]@{
                connectorId = 'custom_corebanking'
                displayName = 'Core Banking Custom Connector'
                publisherType = 'custom'
                certification = 'Uncertified'
                allowsExternalEgress = $true
                supportsFinancialData = $true
                dataFlowBoundaries = @('regulated-financial-systems')
                approvalStatus = 'pending-ciso-dlp-review'
            }
            [pscustomobject]@{
                connectorId = 'shared_dropbox'
                displayName = 'Dropbox Business'
                publisherType = 'third-party'
                certification = 'Certified'
                allowsExternalEgress = $true
                supportsFinancialData = $false
                dataFlowBoundaries = @('personal-or-public-services')
                approvalStatus = 'blocked'
            }
        )
    }

    $approvalRequests = Get-ArtifactContent -Path $approvalRegisterPath -FallbackFactory {
        @(
            [pscustomobject]@{
                requestId = 'CPG-DEMO-001'
                connectorId = 'shared_salesforce'
                displayName = 'Salesforce'
                requestedAt = (Get-Date).AddHours(-18).ToString('o')
                dueBy = (Get-Date).AddHours(30).ToString('o')
                approver = 'cpg-reviewers@contoso.com'
                status = 'submitted'
            }
            [pscustomobject]@{
                requestId = 'CPG-DEMO-002'
                connectorId = 'custom_corebanking'
                displayName = 'Core Banking Custom Connector'
                requestedAt = (Get-Date).AddHours(-36).ToString('o')
                dueBy = (Get-Date).AddHours(-6).ToString('o')
                approver = 'cpg-reviewers@contoso.com'
                status = 'submitted'
            }
        )
    }

    $unapprovedConnectors = Get-UnapprovedConnectors `
        -CurrentInventory $currentInventory `
        -ApprovedBaselineConnectorIds $baselineApprovedConnectorIds `
        -ConfigurationTier $ConfigurationTier `
        -DefaultConfig $config.Default

    $slaViolations = Test-ApprovalSLA -ApprovalRequests $approvalRequests
    $newConnectorCount = @($unapprovedConnectors | Where-Object { $_.isNewConnector }).Count
    $pendingApprovalCount = @($approvalRequests | Where-Object { $_.status -notin @('approved', 'denied', 'blocked') }).Count
    $status = if (@($unapprovedConnectors).Count -eq 0 -and @($slaViolations).Count -eq 0) { 'implemented' } else { 'partial' }

    $alerts = @()
    if ($AlertOnNewConnectors.IsPresent -and $newConnectorCount -gt 0) {
        $alerts += New-TeamsMessageCard `
            -Title 'CPG new connector alert' `
            -Summary ("{0} connector or plugin records are outside the approved baseline and require review." -f $newConnectorCount)
    }

    $report = [pscustomobject]@{
        solution = 'Copilot Connector and Plugin Governance'
        solutionCode = 'CPG'
        reviewedAt = (Get-Date).ToString('o')
        tier = $ConfigurationTier
        status = $status
        statusScore = Get-CopilotGovStatusScore -Status $status
        currentConnectorCount = @($currentInventory).Count
        unapprovedConnectorCount = @($unapprovedConnectors).Count
        newConnectorCount = $newConnectorCount
        pendingApprovalCount = $pendingApprovalCount
        pendingApprovalSlaViolations = @($slaViolations).Count
        dataverseEvidenceTable = $config.Default.dataverseTables.evidence
        unapprovedConnectors = $unapprovedConnectors
        slaViolations = $slaViolations
        alerts = $alerts
    }

    $null = New-Item -ItemType Directory -Path $OutputPath -Force
    $report | ConvertTo-Json -Depth 20 | Set-Content -Path $statusPath -Encoding utf8

    Write-Output $report
}
catch {
    Write-Error -Message ("Connector governance monitoring failed: {0}" -f $_.Exception.Message)
    throw
}
