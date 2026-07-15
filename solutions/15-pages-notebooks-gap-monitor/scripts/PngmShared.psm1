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

function Get-PngmDependencyStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$RepoRoot,

        [Parameter(Mandatory)]
        [string[]]$Dependencies
    )

    $dependencyChecks = foreach ($dependency in @($Dependencies)) {
        $solutionPath = Join-Path $RepoRoot ("solutions\{0}" -f $dependency)
        $exportScriptPath = Join-Path $solutionPath 'scripts\Export-Evidence.ps1'
        $sampleEvidencePath = Join-Path $solutionPath ("artifacts\evidence-test\{0}-evidence.json" -f $dependency)
        $solutionPresent = Test-Path -Path $solutionPath
        $exportScriptPresent = Test-Path -Path $exportScriptPath

        [pscustomobject]@{
            dependency = $dependency
            solutionPath = $solutionPath
            solutionPresent = $solutionPresent
            exportScriptPresent = $exportScriptPresent
            sampleEvidencePresent = (Test-Path -Path $sampleEvidencePath)
            status = if ($solutionPresent -and $exportScriptPresent) { 'repository-present' } else { 'missing' }
            notes = if ($solutionPresent -and $exportScriptPresent) {
                'Dependency solution scaffold is present. Validate recent dependency evidence before regulated attestation.'
            }
            else {
                'Dependency scaffold is missing from the repository path.'
            }
        }
    }

    $missing = @($dependencyChecks | Where-Object { $_.status -eq 'missing' })

    return [pscustomobject]@{
        dependencies = $dependencyChecks
        missingDependencyCount = $missing.Count
        hasMissingDependencies = ($missing.Count -gt 0)
    }
}

function Get-PngmControlState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$TierConfiguration,

        [Parameter(Mandatory)]
        [object[]]$TrackedGaps,

        [Parameter(Mandatory)]
        [object[]]$CompensatingControls
    )

    $controlsRequired = [bool]$TierConfiguration.compensatingControlsRequired
    $inPlaceGapIds = @(
        $CompensatingControls |
        Where-Object { $_.status -eq 'in-place' } |
        ForEach-Object { $_.gapId }
    )

    $controlMap = [ordered]@{
        '2.11' = @('PNGM-GAP-004')
        '3.2' = @('PNGM-GAP-001', 'PNGM-GAP-003', 'PNGM-GAP-005')
        '3.3' = @('PNGM-GAP-002', 'PNGM-GAP-005')
        '3.11' = @('PNGM-GAP-003', 'PNGM-GAP-005')
    }

    $controlNotes = [ordered]@{
        '2.11' = 'Tracks Conditional Access app-level behavior, sharing boundaries, and the Information Barriers limitation for SharePoint Embedded content.'
        '3.2' = 'Tracks retention-policy scope validation, notebook lifecycle safeguards, and retention-label handling limits.'
        '3.3' = 'Tracks eDiscovery review-set indexing rollout validation and legal-hold container scoping procedures.'
        '3.11' = 'Tracks books-and-records preservation dependencies for notebook recovery limits and legal-hold workflows.'
    }

    $controlStates = foreach ($controlId in $controlMap.Keys) {
        $relatedGapIds = $controlMap[$controlId]
        $relatedGaps = @($TrackedGaps | Where-Object { $relatedGapIds -contains $_.gapId })
        $openGaps = @($relatedGaps | Where-Object { $_.status -eq 'open' })
        $validationGaps = @($relatedGaps | Where-Object { $_.status -eq 'validation-required' })
        $openWithControls = @($openGaps | Where-Object { $inPlaceGapIds -contains $_.gapId })

        $status = 'monitor-only'
        if ($openGaps.Count -gt 0) {
            if ($openWithControls.Count -gt 0) {
                $status = 'partial'
            }
        }
        elseif ($validationGaps.Count -gt 0 -and $controlsRequired) {
            $status = 'partial'
        }

        [pscustomobject]@{
            controlId = $controlId
            status = $status
            notes = $controlNotes[$controlId]
        }
    }

    return @($controlStates)
}

Export-ModuleMember -Function Get-PngmConfiguration, Get-PngmDependencyStatus, Get-PngmControlState
