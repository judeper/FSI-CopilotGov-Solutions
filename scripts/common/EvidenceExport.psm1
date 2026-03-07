Set-StrictMode -Version Latest
Import-Module (Join-Path $PSScriptRoot 'IntegrationConfig.psm1') -Force

function Get-CopilotGovSha256 {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    return (Get-FileHash -Path $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Export-SolutionEvidencePackage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Solution,

        [Parameter(Mandatory)]
        [string]$SolutionCode,

        [Parameter(Mandatory)]
        [ValidateSet('baseline', 'recommended', 'regulated')]
        [string]$Tier,

        [Parameter(Mandatory)]
        [string]$OutputPath,

        [Parameter()]
        [hashtable]$Summary = @{},

        [Parameter()]
        [object[]]$Controls = @(),

        [Parameter()]
        [object[]]$Artifacts = @()
    )

    $null = New-Item -ItemType Directory -Path $OutputPath -Force
    $fileName = ('{0}-evidence.json' -f $Solution)
    $filePath = Join-Path $OutputPath $fileName
    $payload = [ordered]@{
        metadata = [ordered]@{
            solution = $Solution
            solutionCode = $SolutionCode
            exportVersion = (Get-CopilotGovEvidenceSchemaVersion)
            exportedAt = (Get-Date).ToString('o')
            tier = $Tier
        }
        summary = $Summary
        controls = $Controls
        artifacts = $Artifacts
    }
    $payload | ConvertTo-Json -Depth 8 | Set-Content -Path $filePath -Encoding utf8
    $hash = Get-CopilotGovSha256 -Path $filePath
    Set-Content -Path ($filePath + '.sha256') -Value ("{0}  {1}" -f $hash, [IO.Path]::GetFileName($filePath)) -Encoding utf8
    return [pscustomobject]@{ Path = $filePath; Hash = $hash }
}

function Test-EvidencePackageHash {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    $hashFile = $Path + '.sha256'
    if (-not (Test-Path -Path $Path)) { throw "Evidence file not found: $Path" }
    if (-not (Test-Path -Path $hashFile)) { throw "Hash file not found: $hashFile" }
    $expected = (Get-Content -Path $hashFile -Raw).Split(' ')[0].Trim()
    $actual = Get-CopilotGovSha256 -Path $Path
    return [pscustomobject]@{ Path = $Path; Expected = $expected; Actual = $actual; IsValid = ($expected -eq $actual) }
}

Export-ModuleMember -Function Export-SolutionEvidencePackage, Test-EvidencePackageHash, Get-CopilotGovSha256
