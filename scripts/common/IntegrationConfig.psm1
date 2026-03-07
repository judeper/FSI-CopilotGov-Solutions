Set-StrictMode -Version Latest

$script:GovernanceTierMap = [ordered]@{
    baseline = @{ Value = 1; Label = 'baseline' }
    recommended = @{ Value = 2; Label = 'recommended' }
    regulated = @{ Value = 3; Label = 'regulated' }
}

$script:DashboardStatusScores = [ordered]@{
    implemented = 100
    partial = 50
    'monitor-only' = 25
    'playbook-only' = 10
    'not-applicable' = 0
}

function Get-CopilotGovTierDefinition {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('baseline', 'recommended', 'regulated')]
        [string]$Tier
    )

    return [pscustomobject]$script:GovernanceTierMap[$Tier]
}

function Get-CopilotGovStatusScore {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('implemented', 'partial', 'monitor-only', 'playbook-only', 'not-applicable')]
        [string]$Status
    )

    return $script:DashboardStatusScores[$Status]
}

function New-CopilotGovTableName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$SolutionSlug,

        [Parameter(Mandatory)]
        [ValidateSet('baseline', 'assessmenthistory', 'finding', 'evidence')]
        [string]$Purpose
    )

    $normalized = ($SolutionSlug.ToLowerInvariant() -replace '[^a-z0-9]+', '_').Trim('_')
    return "fsi_cg_{0}_{1}" -f $normalized, $Purpose
}

function Get-CopilotGovEvidenceSchemaVersion {
    [CmdletBinding()]
    param()

    return '1.0.0'
}

Export-ModuleMember -Function Get-CopilotGovTierDefinition, Get-CopilotGovStatusScore, New-CopilotGovTableName, Get-CopilotGovEvidenceSchemaVersion
