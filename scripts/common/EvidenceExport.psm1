<#
.SYNOPSIS
Evidence packaging and validation module.

.DESCRIPTION
Provides SHA-256 hashing, evidence schema validation, and package assembly helpers. Validates
schema structure and hash integrity only; does not validate data freshness, collection liveness,
or whether evidence artifacts contain real tenant data versus representative sample data.
#>
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

function Get-CopilotGovEvidenceSchemaPath {
    [CmdletBinding()]
    param()

    return (Resolve-Path (Join-Path $PSScriptRoot '..\..\data\evidence-schema.json')).Path
}

function Write-CopilotGovSha256File {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not (Test-Path -Path $Path -PathType Leaf)) {
        throw "Evidence file not found: $Path"
    }

    $hash = Get-CopilotGovSha256 -Path $Path
    $hashPath = $Path + '.sha256'
    $hashLine = '{0}  {1}' -f $hash, [IO.Path]::GetFileName($Path)
    Set-Content -Path $hashPath -Value $hashLine -Encoding utf8

    return [pscustomobject]@{
        Path = $Path
        Hash = $hash
        HashPath = $hashPath
        HashLine = $hashLine
    }
}

function Read-CopilotGovSha256File {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    $hashPath = $Path + '.sha256'
    if (-not (Test-Path -Path $hashPath -PathType Leaf)) {
        throw "Hash file not found: $hashPath"
    }

    $rawValue = (Get-Content -Path $hashPath -Raw -Encoding utf8).Trim()
    $match = [regex]::Match($rawValue, '^(?<hash>[0-9a-f]{64})  (?<file>.+)$')

    return [pscustomobject]@{
        Path = $Path
        HashPath = $hashPath
        RawValue = $rawValue
        IsFormatValid = $match.Success
        ExpectedHash = if ($match.Success) { $match.Groups['hash'].Value } else { $null }
        RecordedFileName = if ($match.Success) { $match.Groups['file'].Value } else { $null }
    }
}

function Test-EvidencePackageHash {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not (Test-Path -Path $Path -PathType Leaf)) {
        throw "Evidence file not found: $Path"
    }

    $hashEntry = Read-CopilotGovSha256File -Path $Path
    $actual = Get-CopilotGovSha256 -Path $Path
    $fileName = [IO.Path]::GetFileName($Path)

    return [pscustomobject]@{
        Path = $Path
        HashPath = $hashEntry.HashPath
        Expected = $hashEntry.ExpectedHash
        Actual = $actual
        RecordedFileName = $hashEntry.RecordedFileName
        IsFormatValid = $hashEntry.IsFormatValid
        FileNameMatches = ($hashEntry.RecordedFileName -eq $fileName)
        IsValid = ($hashEntry.IsFormatValid -and ($hashEntry.RecordedFileName -eq $fileName) -and ($hashEntry.ExpectedHash -eq $actual))
    }
}

function Get-CopilotGovDocumentedArtifactNames {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$SolutionRoot
    )

    $configPath = Join-Path $SolutionRoot 'config\default-config.json'
    if (-not (Test-Path -Path $configPath -PathType Leaf)) {
        return @()
    }

    $config = Get-Content -Path $configPath -Raw -Encoding utf8 | ConvertFrom-Json -AsHashtable
    if ($config.ContainsKey('evidenceOutputs')) {
        return @($config.evidenceOutputs | ForEach-Object { [string]$_ })
    }

    if ($config.ContainsKey('defaults') -and ($config.defaults -is [System.Collections.IDictionary]) -and $config.defaults.ContainsKey('evidenceOutputs')) {
        return @($config.defaults.evidenceOutputs | ForEach-Object { [string]$_ })
    }

    return @()
}

<#
.SYNOPSIS
Validates evidence package structure, schema alignment, and hash integrity.

.DESCRIPTION
This validator confirms that the supplied package and artifact files match the shared repository
contract. It does not determine whether the package contents came from live systems or whether a
solution's control-status claims are operationally sufficient; solution scripts must record that
runtime context explicitly in package metadata, summaries, or artifact payloads.
#>
function Test-CopilotGovEvidencePackage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter()]
        [string[]]$ExpectedArtifacts = @()
    )

    $errors = @()
    $schemaPath = Get-CopilotGovEvidenceSchemaPath
    $packageHash = $null
    $package = $null

    try {
        $packageHash = Test-EvidencePackageHash -Path $Path
        if (-not $packageHash.IsValid) {
            $errors += ('Package hash validation failed for {0}.' -f $Path)
        }
    }
    catch {
        $errors += $_.Exception.Message
    }

    if (Test-Path -Path $Path -PathType Leaf) {
        $json = Get-Content -Path $Path -Raw -Encoding utf8

        try {
            $schemaValid = Test-Json -Json $json -SchemaFile $schemaPath -ErrorAction Stop
            if (-not $schemaValid) {
                $errors += ('Schema validation failed for {0}.' -f $Path)
            }
        }
        catch {
            $errors += ('Schema validation failed for {0}: {1}' -f $Path, $_.Exception.Message)
        }

        try {
            $package = $json | ConvertFrom-Json -Depth 50
        }
        catch {
            $errors += ('Could not parse evidence package JSON at {0}: {1}' -f $Path, $_.Exception.Message)
        }
    }

    if ($null -ne $package) {
        $expectedVersion = Get-CopilotGovEvidenceSchemaVersion
        if ([string]$package.metadata.exportVersion -ne $expectedVersion) {
            $errors += ('Evidence package {0} declares exportVersion {1}; expected {2}.' -f $Path, $package.metadata.exportVersion, $expectedVersion)
        }

        $artifactNames = @()
        foreach ($artifact in @($package.artifacts)) {
            $artifactName = [string]$artifact.name
            if (-not [string]::IsNullOrWhiteSpace($artifactName)) {
                $artifactNames += $artifactName
            }

            if (-not ($artifact.PSObject.Properties.Name -contains 'hash') -or [string]::IsNullOrWhiteSpace([string]$artifact.hash)) {
                $errors += ('Artifact entry {0} is missing a hash value.' -f $artifactName)
                continue
            }

            if ([string]::IsNullOrWhiteSpace([string]$artifact.path)) {
                $errors += ('Artifact entry {0} is missing a path value.' -f $artifactName)
                continue
            }

            $artifactPath = [string]$artifact.path
            if (-not (Test-Path -Path $artifactPath -PathType Leaf)) {
                $errors += ('Artifact entry {0} references a file that was not emitted: {1}' -f $artifactName, $artifactPath)
                continue
            }

            try {
                $artifactHash = Test-EvidencePackageHash -Path $artifactPath
                if (-not $artifactHash.IsValid) {
                    $errors += ('Artifact hash validation failed for {0}.' -f $artifactPath)
                    continue
                }
            }
            catch {
                $errors += $_.Exception.Message
                continue
            }

            if ([string]$artifact.hash -ne $artifactHash.Actual) {
                $errors += ('Artifact entry {0} records hash {1}, but the emitted file hash is {2}.' -f $artifactName, $artifact.hash, $artifactHash.Actual)
            }
        }

        $duplicateArtifactNames = @($artifactNames | Group-Object | Where-Object { $_.Count -gt 1 } | Select-Object -ExpandProperty Name)
        if ($duplicateArtifactNames.Count -gt 0) {
            $errors += ('Duplicate artifact names found in {0}: {1}' -f $Path, ($duplicateArtifactNames -join ', '))
        }

        if (@($ExpectedArtifacts).Count -gt 0) {
            $expected = @($ExpectedArtifacts | Sort-Object -Unique)
            $actual = @($artifactNames | Sort-Object -Unique)
            if (@(Compare-Object -ReferenceObject $expected -DifferenceObject $actual -SyncWindow 0).Count -gt 0) {
                $missing = @($expected | Where-Object { $_ -notin $actual })
                $extra = @($actual | Where-Object { $_ -notin $expected })

                if ($missing.Count -gt 0) {
                    $errors += ('Missing documented artifacts in {0}: {1}' -f $Path, ($missing -join ', '))
                }

                if ($extra.Count -gt 0) {
                    $errors += ('Unexpected artifact entries in {0}: {1}' -f $Path, ($extra -join ', '))
                }
            }
        }
    }

    return [pscustomobject]@{
        Path = $Path
        SchemaPath = $schemaPath
        IsValid = ($errors.Count -eq 0)
        Errors = $errors
        ArtifactCount = if ($null -ne $package) { @($package.artifacts).Count } else { 0 }
        Artifacts = if ($null -ne $package) { @($package.artifacts | ForEach-Object { [string]$_.name }) } else { @() }
        PackageHash = $packageHash
    }
}

<#
.SYNOPSIS
Writes a schema-aligned evidence package and companion hash file.

.DESCRIPTION
Packages the metadata, summary, controls, and artifact references exactly as supplied by the
calling solution. This helper preserves caller-provided runtime markers and honesty warnings, but
it does not infer or upgrade implementation status on the caller's behalf.
#>
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
        [object[]]$Artifacts = @(),

        [Parameter()]
        [string]$PackageFileName,

        [Parameter()]
        [string[]]$ExpectedArtifacts = @(),

        [Parameter()]
        [System.Collections.IDictionary]$AdditionalMetadata = @{},

        [Parameter()]
        [switch]$SkipValidation
    )

    $null = New-Item -ItemType Directory -Path $OutputPath -Force
    $fileName = if ([string]::IsNullOrWhiteSpace($PackageFileName)) {
        '{0}-evidence.json' -f $Solution
    }
    else {
        $PackageFileName
    }

    $filePath = Join-Path $OutputPath $fileName
    $metadata = [ordered]@{
        solution = $Solution
        solutionCode = $SolutionCode
        exportVersion = (Get-CopilotGovEvidenceSchemaVersion)
        exportedAt = (Get-Date).ToString('o')
        tier = $Tier
    }

    foreach ($key in $AdditionalMetadata.Keys) {
        $metadata[$key] = $AdditionalMetadata[$key]
    }

    $payload = [ordered]@{
        metadata = $metadata
        summary = $Summary
        controls = $Controls
        artifacts = $Artifacts
    }

    $payload | ConvertTo-Json -Depth 20 | Set-Content -Path $filePath -Encoding utf8
    $hashInfo = Write-CopilotGovSha256File -Path $filePath

    if (-not $SkipValidation) {
        $validation = Test-CopilotGovEvidencePackage -Path $filePath -ExpectedArtifacts $ExpectedArtifacts
        if (-not $validation.IsValid) {
            $details = if ($validation.Errors.Count -gt 0) {
                ($validation.Errors | ForEach-Object { ' - {0}' -f $_ }) -join [Environment]::NewLine
            }
            else {
                ' - Unknown validation error.'
            }

            throw ("Evidence package validation failed for {0}:{1}{2}" -f $filePath, [Environment]::NewLine, $details)
        }
    }

    return [pscustomobject]@{
        Path = $filePath
        Hash = $hashInfo.Hash
        HashPath = $hashInfo.HashPath
    }
}

Export-ModuleMember -Function Get-CopilotGovSha256, Get-CopilotGovEvidenceSchemaPath, Write-CopilotGovSha256File, Test-EvidencePackageHash, Get-CopilotGovDocumentedArtifactNames, Test-CopilotGovEvidencePackage, Export-SolutionEvidencePackage
