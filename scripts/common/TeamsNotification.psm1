<#
.SYNOPSIS
Documentation-first Teams notification helper module.

.DESCRIPTION
This module provides MessageCard payload helpers for Teams notification scenarios. No Teams
webhook or API calls are made. Customers must configure and send notifications through their
own Power Automate flow or webhook endpoint.
#>
Set-StrictMode -Version Latest

function New-TeamsMessageCard {
    <#
    .SYNOPSIS
    Creates a Teams MessageCard JSON structure (documentation-first). Returns the card payload
    object only. No Teams webhook or API calls are made. Customer must configure and send
    notifications through their own Power Automate flow or webhook endpoint.

    .DESCRIPTION
    Returns an Office 365 MessageCard-formatted object with the specified title, summary, and
    theme color. The object is suitable for serialization and offline validation but is not
    transmitted to any endpoint.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Title,
        [Parameter(Mandatory)]
        [string]$Summary,
        [Parameter()]
        [string]$ThemeColor = '0078D4'
    )

    return [pscustomobject]@{
        '@type' = 'MessageCard'
        '@context' = 'https://schema.org/extensions'
        themeColor = $ThemeColor
        summary = $Summary
        title = $Title
    }
}

Export-ModuleMember -Function New-TeamsMessageCard
