Set-StrictMode -Version Latest

function New-PurviewAssessmentRecord {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Workload,
        [Parameter(Mandatory)]
        [string]$Status,
        [Parameter()]
        [string]$Notes = ''
    )

    return [pscustomobject]@{
        Workload = $Workload
        Status = $Status
        Notes = $Notes
        CapturedAt = (Get-Date).ToString('o')
    }
}

Export-ModuleMember -Function New-PurviewAssessmentRecord
