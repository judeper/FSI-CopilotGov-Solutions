<#
.SYNOPSIS
Documentation-first Microsoft Purview helper module.

.DESCRIPTION
This module provides assessment record helpers for Purview compliance scenarios. No Microsoft
Purview API calls are made. Customers must configure actual assessment scanning through the
Microsoft Purview portal.
#>
Set-StrictMode -Version Latest

function New-PurviewAssessmentRecord {
    <#
    .SYNOPSIS
    Creates a Purview assessment record structure (documentation-first). Returns record object
    only. No Microsoft Purview API calls are made. Customer must configure actual assessment
    scanning through the Microsoft Purview portal.

    .DESCRIPTION
    Returns a timestamped assessment record object suitable for documentation, offline validation,
    and evidence collection workflows. No authenticated Purview session is established.
    #>
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
