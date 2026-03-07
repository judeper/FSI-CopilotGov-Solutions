Set-StrictMode -Version Latest

function ConvertTo-DataverseLogicalName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$SchemaName
    )

    return $SchemaName.ToLowerInvariant()
}

function New-DataverseTableContract {
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
