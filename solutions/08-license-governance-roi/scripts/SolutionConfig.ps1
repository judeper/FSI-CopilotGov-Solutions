function Get-SolutionConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('baseline', 'recommended', 'regulated')]
        [string]$Tier
    )

    $defaultConfigPath = Join-Path $PSScriptRoot '..\config\default-config.json'
    $tierConfigPath = Join-Path $PSScriptRoot ("..\config\{0}.json" -f $Tier)

    $defaultConfig = Get-Content -Path $defaultConfigPath -Raw | ConvertFrom-Json -AsHashtable
    $tierConfig = Get-Content -Path $tierConfigPath -Raw | ConvertFrom-Json -AsHashtable

    $mergedConfig = [ordered]@{}
    foreach ($key in $defaultConfig.Keys) {
        if ($key -ne 'defaults') {
            $mergedConfig[$key] = $defaultConfig[$key]
        }
    }

    $mergedConfig['defaults'] = [ordered]@{}
    foreach ($key in $defaultConfig.defaults.Keys) {
        $mergedConfig.defaults[$key] = $defaultConfig.defaults[$key]
    }

    foreach ($key in $tierConfig.Keys) {
        $mergedConfig[$key] = $tierConfig[$key]
    }

    return $mergedConfig
}
