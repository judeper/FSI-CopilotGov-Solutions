[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet('baseline', 'recommended', 'regulated')]
    [string]$ConfigurationTier = 'baseline',

    [Parameter()]
    [string]$OutputRoot = (Join-Path ([IO.Path]::GetTempPath()) 'fsi-copilotgov-evidence-validation'),

    [Parameter()]
    [switch]$KeepOutput
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Import-Module (Join-Path $repoRoot 'scripts\common\EvidenceExport.psm1') -Force

function Get-SolutionSlugs {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$RepositoryRoot
    )

    $configPath = Join-Path $RepositoryRoot 'scripts\solution-config.yml'
    $config = Get-Content -Path $configPath -Raw -Encoding utf8 | ConvertFrom-Json -AsHashtable
    return @($config.solutions.Keys | Sort-Object)
}

function Get-ExportInvocationParameters {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ScriptPath,

        [Parameter(Mandatory)]
        [string]$OutputPath,

        [Parameter(Mandatory)]
        [string]$ConfigurationTier
    )

    $command = Get-Command $ScriptPath
    $parameters = @{
        OutputPath = $OutputPath
    }

    if ($command.Parameters.ContainsKey('ConfigurationTier')) {
        $parameters.ConfigurationTier = $ConfigurationTier
    }

    if ($command.Parameters.ContainsKey('TenantId')) {
        $parameters.TenantId = '00000000-0000-0000-0000-000000000000'
    }

    foreach ($periodParameter in @(
            @{ Name = 'PeriodStart'; StringValue = '2026-01-01'; DateValue = [datetime]'2026-01-01' },
            @{ Name = 'PeriodEnd'; StringValue = '2026-01-31'; DateValue = [datetime]'2026-01-31' }
        )) {
        if (-not $command.Parameters.ContainsKey($periodParameter.Name)) {
            continue
        }

        $parameterMetadata = $command.Parameters[$periodParameter.Name]
        if ($parameterMetadata.ParameterType -eq [string]) {
            $parameters[$periodParameter.Name] = $periodParameter.StringValue
        }
        else {
            $parameters[$periodParameter.Name] = $periodParameter.DateValue
        }
    }

    if ($command.Parameters.ContainsKey('PassThru')) {
        $parameters.PassThru = $true
    }

    return $parameters
}

function Get-EvidencePackagePath {
    [CmdletBinding()]
    param(
        [Parameter()]
        [object]$Result,

        [Parameter(Mandatory)]
        [string]$OutputPath
    )

    if ($null -ne $Result) {
        foreach ($propertyName in @('PackagePath', 'packagePath', 'EvidencePackagePath', 'evidencePackagePath')) {
            if (($Result.PSObject.Properties.Name -contains $propertyName) -and -not [string]::IsNullOrWhiteSpace([string]$Result.$propertyName)) {
                return [string]$Result.$propertyName
            }
        }

        foreach ($containerName in @('Package', 'package', 'EvidencePackage', 'evidencePackage', 'evidencePackageResult')) {
            if (-not ($Result.PSObject.Properties.Name -contains $containerName)) {
                continue
            }

            $container = $Result.$containerName
            if (($null -ne $container) -and ($container.PSObject.Properties.Name -contains 'Path') -and -not [string]::IsNullOrWhiteSpace([string]$container.Path)) {
                return [string]$container.Path
            }
        }
    }

    $candidates = @(
        Get-ChildItem -Path $OutputPath -Filter '*.json' -File | Where-Object {
            try {
                $document = Get-Content -Path $_.FullName -Raw -Encoding utf8 | ConvertFrom-Json -Depth 50
                $document.PSObject.Properties.Name -contains 'metadata' -and
                $document.PSObject.Properties.Name -contains 'summary' -and
                $document.PSObject.Properties.Name -contains 'controls' -and
                $document.PSObject.Properties.Name -contains 'artifacts'
            }
            catch {
                $false
            }
        } | Select-Object -ExpandProperty FullName
    )

    if ($candidates.Count -eq 1) {
        return $candidates[0]
    }

    return $null
}

function New-ValidationResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Solution,

        [Parameter(Mandatory)]
        [bool]$Passed,

        [Parameter()]
        [string]$PackagePath = '',

        [Parameter()]
        [string[]]$Details = @()
    )

    return [pscustomobject]@{
        Solution = $Solution
        Passed = $Passed
        PackagePath = $PackagePath
        Details = @($Details)
    }
}

$outputRootPath = [IO.Path]::GetFullPath($OutputRoot)
if (Test-Path -Path $outputRootPath) {
    Remove-Item -Path $outputRootPath -Recurse -Force
}

$null = New-Item -ItemType Directory -Path $outputRootPath -Force
$results = @()

try {
    foreach ($slug in Get-SolutionSlugs -RepositoryRoot $repoRoot) {
        $solutionRoot = Join-Path $repoRoot ("solutions\{0}" -f $slug)
        $scriptPath = Join-Path $solutionRoot 'scripts\Export-Evidence.ps1'
        $solutionOutputPath = Join-Path $outputRootPath $slug
        $null = New-Item -ItemType Directory -Path $solutionOutputPath -Force

        $expectedArtifacts = Get-CopilotGovDocumentedArtifactNames -SolutionRoot $solutionRoot
        if ($expectedArtifacts.Count -eq 0) {
            $results += New-ValidationResult -Solution $slug -Passed $false -Details @('No documented evidenceOutputs declaration found in config\default-config.json.')
            continue
        }

        try {
            $parameters = Get-ExportInvocationParameters -ScriptPath $scriptPath -OutputPath $solutionOutputPath -ConfigurationTier $ConfigurationTier
            $allResults = @(& $scriptPath @parameters)
            $result = if ($allResults.Count -gt 0) { $allResults[-1] } else { $null }
        }
        catch {
            $results += New-ValidationResult -Solution $slug -Passed $false -Details @($_.Exception.Message)
            continue
        }

        $packagePath = Get-EvidencePackagePath -Result $result -OutputPath $solutionOutputPath
        if ([string]::IsNullOrWhiteSpace($packagePath)) {
            $results += New-ValidationResult -Solution $slug -Passed $false -Details @('Could not determine evidence package path from export output.')
            continue
        }

        try {
            $validation = Test-CopilotGovEvidencePackage -Path $packagePath -ExpectedArtifacts $expectedArtifacts
        }
        catch {
            $results += New-ValidationResult -Solution $slug -Passed $false -PackagePath $packagePath -Details @($_.Exception.Message)
            continue
        }

        if (-not $validation.IsValid) {
            $results += New-ValidationResult -Solution $slug -Passed $false -PackagePath $packagePath -Details $validation.Errors
            continue
        }

        $results += New-ValidationResult -Solution $slug -Passed $true -PackagePath $packagePath -Details @(
            'Schema validation passed.',
            ('Validated artifacts: {0}' -f ($validation.Artifacts -join ', '))
        )
    }

    $results | Sort-Object Solution | Format-Table Solution, Passed, PackagePath -AutoSize

    $failures = @($results | Where-Object { -not $_.Passed })
    if ($failures.Count -gt 0) {
        $messages = foreach ($failure in $failures) {
            '{0}: {1}' -f $failure.Solution, ($failure.Details -join ' | ')
        }

        throw ("Evidence validation failed for {0} solution(s):{1}{2}" -f $failures.Count, [Environment]::NewLine, ($messages -join [Environment]::NewLine))
    }

    Write-Host ('Evidence validation passed for {0} solution exports.' -f $results.Count)
}
finally {
    if ((-not $KeepOutput) -and (Test-Path -Path $outputRootPath)) {
        Remove-Item -Path $outputRootPath -Recurse -Force
    }
}
