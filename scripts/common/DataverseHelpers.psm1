<#
.SYNOPSIS
Documentation-first Dataverse helper module.

.DESCRIPTION
This module provides schema contract helpers for Dataverse table definitions. No Dataverse API
calls are made. Customers must manually deploy tables to their target Dataverse environment using
the Power Platform UI or provisioning API.
#>
Set-StrictMode -Version Latest

function ConvertTo-DataverseLogicalName {
    <#
    .SYNOPSIS
    Converts a Dataverse schema name to its lowercase logical name form.

    .DESCRIPTION
    Returns the lowercased logical name string. This is a local string transformation only; no
    Dataverse environment lookups or API calls are performed.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$SchemaName
    )

    return $SchemaName.ToLowerInvariant()
}

function New-DataverseTableContract {
    <#
    .SYNOPSIS
    Creates a Dataverse table schema contract (documentation-first). Returns table schema
    definition only. Customer must manually deploy tables to target Dataverse environment using
    Power Platform UI or provisioning API. No actual table creation or CRUD operations occur.

    .DESCRIPTION
    Returns a contract object describing the intended table schema. The object is suitable for
    offline validation, documentation generation, and integration tests but does not provision
    any Dataverse resources.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$SchemaName,
        [Parameter(Mandatory)]
        [string[]]$Columns
    )

    return [pscustomobject]@{
        SchemaName = $SchemaName
        LogicalName = (ConvertTo-DataverseLogicalName -SchemaName $SchemaName)
        Columns = $Columns
    }
}

Export-ModuleMember -Function ConvertTo-DataverseLogicalName, New-DataverseTableContract
