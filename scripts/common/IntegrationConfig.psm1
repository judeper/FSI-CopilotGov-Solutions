<#
.SYNOPSIS
Shared configuration contract module.

.DESCRIPTION
Provides tier-name mapping, status-score conversion, and integration constants. Supports both
documentation-first stub implementations and live tenant integrations.
#>
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
    <#
    .SYNOPSIS
    Returns the governance tier definition for the specified tier name.

    .DESCRIPTION
    Looks up the tier in the module-scoped GovernanceTierMap and returns its value and label.
    This is a local lookup only; no external service calls are made.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('baseline', 'recommended', 'regulated')]
        [string]$Tier
    )

    return [pscustomobject]$script:GovernanceTierMap[$Tier]
}

function Get-CopilotGovStatusScore {
    <#
    .SYNOPSIS
    Returns the numeric dashboard score for the given implementation status.

    .DESCRIPTION
    Maps a status string to its corresponding score (0–100) using the module-scoped
    DashboardStatusScores table. No external service calls are made.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('implemented', 'partial', 'monitor-only', 'playbook-only', 'not-applicable')]
        [string]$Status
    )

    return $script:DashboardStatusScores[$Status]
}

function New-CopilotGovTableName {
    <#
    .SYNOPSIS
    Generates a standardized Dataverse table name for a given solution and purpose.

    .DESCRIPTION
    Normalizes the solution slug and appends the purpose suffix to produce a consistent
    fsi_cg_<slug>_<purpose> naming convention. No Dataverse calls are made.
    #>
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
    <#
    .SYNOPSIS
    Returns the current evidence schema version string.

    .DESCRIPTION
    Returns the semantic version of the evidence schema used by this solution. This is a
    constant lookup; no external calls are made.
    #>
    [CmdletBinding()]
    param()

    return '1.1.0'
}

Export-ModuleMember -Function Get-CopilotGovTierDefinition, Get-CopilotGovStatusScore, New-CopilotGovTableName, Get-CopilotGovEvidenceSchemaVersion
