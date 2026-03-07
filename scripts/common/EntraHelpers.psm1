Set-StrictMode -Version Latest

function New-EntraPolicySummary {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$PolicyName,
        [Parameter(Mandatory)]
        [string]$Tier,
        [Parameter()]
        [string]$Status = 'planned'
    )

    return [pscustomobject]@{
        PolicyName = $PolicyName
        Tier = $Tier
        Status = $Status
    }
}

Export-ModuleMember -Function New-EntraPolicySummary
