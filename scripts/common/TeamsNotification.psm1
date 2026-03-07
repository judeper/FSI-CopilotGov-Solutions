Set-StrictMode -Version Latest

function New-TeamsMessageCard {
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
