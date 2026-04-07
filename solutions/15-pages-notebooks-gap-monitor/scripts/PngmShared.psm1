function Get-PngmConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('baseline', 'recommended', 'regulated')]
        [string]$Tier
    )

    $configRoot = Join-Path (Split-Path -Parent $PSScriptRoot) 'config'
    $defaultConfigPath = Join-Path $configRoot 'default-config.json'
    $tierConfigPath = Join-Path $configRoot ('{0}.json' -f $Tier)

    foreach ($path in @($defaultConfigPath, $tierConfigPath)) {
        if (-not (Test-Path -Path $path)) {
            throw "Configuration file not found: $path"
        }
    }

    return [pscustomobject]@{
        Default = (Get-Content -Path $defaultConfigPath -Raw | ConvertFrom-Json)
        Tier = (Get-Content -Path $tierConfigPath -Raw | ConvertFrom-Json)
    }
}

Export-ModuleMember -Function Get-PngmConfiguration
