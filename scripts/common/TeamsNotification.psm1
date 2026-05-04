<#
.SYNOPSIS
Documentation-first Teams notification helper module.

.DESCRIPTION
This module provides legacy Microsoft 365 connector MessageCard payload helpers for Teams
notification scenarios. No Teams webhook or API calls are made. New implementations should
use Teams Workflows or Adaptive Cards where possible; MessageCard payloads are retained for
legacy connector compatibility.
#>
Set-StrictMode -Version Latest

function New-TeamsMessageCard {
    <#
    .SYNOPSIS
    Creates a legacy Microsoft 365 connector MessageCard JSON structure (documentation-first). Returns the card payload
    object only. No Teams webhook or API calls are made. New implementations should use
    Teams Workflows or Adaptive Cards where possible; legacy webhook use should be tenant-approved.

    .DESCRIPTION
    Returns a legacy Microsoft 365 connector MessageCard-formatted object with the specified title, summary, and
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
