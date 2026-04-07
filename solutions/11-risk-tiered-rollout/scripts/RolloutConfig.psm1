<#
.SYNOPSIS
Shared configuration utilities for Risk-Tiered Rollout Automation scripts.

.DESCRIPTION
Provides JSON configuration loading, deep-copy, merge, and rollout configuration
resolution used by Deploy-Solution.ps1, Monitor-Compliance.ps1, and Export-Evidence.ps1.
#>

function Read-JsonConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not (Test-Path -Path $Path)) {
        throw "File was not found: $Path"
    }

    return Get-Content -Path $Path -Raw | ConvertFrom-Json -AsHashtable -Depth 20
}

function Copy-ConfigValue {
    [CmdletBinding()]
    param(
        [Parameter()]
        [object]$Value
    )

    if ($null -eq $Value) {
        return $null
    }

    if ($Value -is [System.Collections.IDictionary]) {
        $copy = [ordered]@{}
        foreach ($key in $Value.Keys) {
            $copy[$key] = Copy-ConfigValue -Value $Value[$key]
        }

        return $copy
    }

    if (($Value -is [System.Collections.IEnumerable]) -and -not ($Value -is [string])) {
        $items = @()
        foreach ($item in $Value) {
            $items += ,(Copy-ConfigValue -Value $item)
        }

        return $items
    }

    return $Value
}

function Merge-Hashtable {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$Base,

        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$Overlay
    )

    $result = [ordered]@{}

    foreach ($key in $Base.Keys) {
        $result[$key] = Copy-ConfigValue -Value $Base[$key]
    }

    foreach ($key in $Overlay.Keys) {
        if (
            $result.Contains($key) -and
            ($result[$key] -is [System.Collections.IDictionary]) -and
            ($Overlay[$key] -is [System.Collections.IDictionary])
        ) {
            $result[$key] = Merge-Hashtable -Base $result[$key] -Overlay $Overlay[$key]
            continue
        }

        $result[$key] = Copy-ConfigValue -Value $Overlay[$key]
    }

    return $result
}

function Get-RolloutConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Tier,

        [Parameter(Mandatory)]
        [string]$SolutionRoot
    )

    $defaultConfigPath = Join-Path $SolutionRoot 'config\default-config.json'
    $tierConfigPath = Join-Path $SolutionRoot ("config\{0}.json" -f $Tier)
    $defaultConfig = Read-JsonConfiguration -Path $defaultConfigPath
    $tierConfig = Read-JsonConfiguration -Path $tierConfigPath

    return Merge-Hashtable -Base $defaultConfig -Overlay $tierConfig
}

Export-ModuleMember -Function Read-JsonConfiguration, Copy-ConfigValue, Merge-Hashtable, Get-RolloutConfiguration
