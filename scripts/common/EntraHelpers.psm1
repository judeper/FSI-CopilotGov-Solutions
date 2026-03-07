<#
.SYNOPSIS
Documentation-first Entra ID helper module.

.DESCRIPTION
This module provides policy metadata helpers for Entra ID governance scenarios. No Microsoft
Graph or Entra ID API calls are made. Customers must configure actual Conditional Access or
Entra ID policies through the Azure portal or Microsoft Graph API.
#>
Set-StrictMode -Version Latest

function New-EntraPolicySummary {
    <#
    .SYNOPSIS
    Creates an Entra policy metadata summary (documentation-first). Returns policy metadata
    object only. Customer must configure actual Conditional Access or Entra ID policies through
    the Azure portal or Microsoft Graph API. No policies are created or modified.

    .DESCRIPTION
    Returns a lightweight policy summary object suitable for documentation, dashboard rendering,
    and offline validation. No authenticated Entra ID session is established.
    #>
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
