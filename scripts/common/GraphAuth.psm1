Set-StrictMode -Version Latest

function New-CopilotGovGraphContext {
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
    }
}

Export-ModuleMember -Function New-CopilotGovGraphContext
