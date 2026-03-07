<#
.SYNOPSIS
Creates a documentation-first Microsoft Graph context placeholder.

.DESCRIPTION
This module does not authenticate to Microsoft Graph. It returns tenant and scope metadata so
solution scripts can record their intended Graph dependencies while remaining testable in offline
or documentation-first repository states.
#>
Set-StrictMode -Version Latest

function New-CopilotGovGraphContext {
    <#
    .SYNOPSIS
    Returns placeholder Graph context metadata for repository scripts.

    .DESCRIPTION
    The returned object is a contract stub only. No tokens are requested, no authenticated session
    is created, and callers must add tenant-approved authentication logic before treating Graph
    connectivity as live.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$TenantId,

        [Parameter()]
        [string[]]$Scopes = @('https://graph.microsoft.com/.default')
    )

    return [pscustomobject]@{
        TenantId = $TenantId
        Scopes = $Scopes
        ConnectedAt = (Get-Date).ToString('o')
        Mode = 'placeholder'
        Warning = 'No authenticated Microsoft Graph session was created by GraphAuth.psm1.'
    }
}

Export-ModuleMember -Function New-CopilotGovGraphContext
