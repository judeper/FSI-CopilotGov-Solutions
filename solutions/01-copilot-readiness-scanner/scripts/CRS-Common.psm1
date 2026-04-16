<#
.SYNOPSIS
Shared utility functions for the Copilot Readiness Assessment Scanner.

.DESCRIPTION
Provides common helper functions used by Deploy-Solution.ps1, Monitor-Compliance.ps1,
and Export-Evidence.ps1 to avoid duplication and drift across scripts.
#>

function Get-RepositoryRoot {
    [CmdletBinding()]
    param()

    return (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
}

function Get-SolutionRoot {
    [CmdletBinding()]
    param()

    return (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
}

function Import-SharedModule {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ModuleName,

        [Parameter()]
        [switch]$Optional
    )

    $modulePath = Join-Path (Join-Path (Get-RepositoryRoot) 'scripts\common') $ModuleName
    if (-not (Test-Path -Path $modulePath)) {
        if ($Optional) {
            return $false
        }

        throw "Shared module not found: $modulePath"
    }

    Import-Module $modulePath -Force -Global
    return $true
}

function Merge-Hashtable {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$Base,

        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$Overlay
    )

    $merged = [ordered]@{}

    foreach ($key in $Base.Keys) {
        $merged[$key] = $Base[$key]
    }

    foreach ($key in $Overlay.Keys) {
        if (
            $merged.Contains($key) -and
            ($merged[$key] -is [System.Collections.IDictionary]) -and
            ($Overlay[$key] -is [System.Collections.IDictionary])
        ) {
            $merged[$key] = Merge-Hashtable -Base $merged[$key] -Overlay $Overlay[$key]
        }
        else {
            $merged[$key] = $Overlay[$key]
        }
    }

    return $merged
}

function Get-SolutionConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('baseline', 'recommended', 'regulated')]
        [string]$Tier
    )

    $solutionRoot = Get-SolutionRoot
    $defaultConfigPath = Join-Path $solutionRoot 'config\default-config.json'
    $tierConfigPath = Join-Path $solutionRoot ("config\{0}.json" -f $Tier)

    if (-not (Test-Path -Path $defaultConfigPath)) {
        throw "Default configuration file not found: $defaultConfigPath"
    }

    if (-not (Test-Path -Path $tierConfigPath)) {
        throw "Tier configuration file not found: $tierConfigPath"
    }

    $defaultConfig = Get-Content -Path $defaultConfigPath -Raw | ConvertFrom-Json -AsHashtable
    $tierConfig = Get-Content -Path $tierConfigPath -Raw | ConvertFrom-Json -AsHashtable

    return (Merge-Hashtable -Base $defaultConfig -Overlay $tierConfig)
}

Export-ModuleMember -Function Get-RepositoryRoot, Get-SolutionRoot, Import-SharedModule, Merge-Hashtable, Get-SolutionConfiguration
