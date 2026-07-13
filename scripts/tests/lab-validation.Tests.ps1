BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
    $script:modulePath = Join-Path $script:repoRoot 'scripts/common/EvidenceExport.psm1'
    $script:wrapperPath = Join-Path $script:repoRoot 'scripts/validate-lab-package.ps1'
    $script:fixturesRoot = Join-Path $PSScriptRoot 'fixtures'
    $script:packagePath = Join-Path $script:fixturesRoot 'lab-package/portable-evidence.json'
    $script:resultValidatorPath = Join-Path $script:repoRoot 'scripts/validate-lab-result.py'
    $script:validResultPath = Join-Path $script:fixturesRoot 'lab-results/valid/01-copilot-readiness-scanner/lab/01-copilot-readiness-scanner.lab-result.json'
    $script:readOnlyResultPath = Join-Path $script:fixturesRoot 'lab-results/valid/read-only-no-mutations/01-copilot-readiness-scanner/lab/01-copilot-readiness-scanner.lab-result.json'
    $script:invalidResultPath = Join-Path $script:fixturesRoot 'lab-results/invalid/01-copilot-readiness-scanner/lab/01-copilot-readiness-scanner.lab-result.json'
    $script:missingMutationRefResultPath = Join-Path $script:fixturesRoot 'lab-results/invalid/mutation-executed-without-ref/01-copilot-readiness-scanner/lab/01-copilot-readiness-scanner.lab-result.json'
    $script:pwshPath = (Get-Command pwsh -ErrorAction Stop).Source
    $script:pythonPath = (Get-Command python -ErrorAction Stop).Source

    Import-Module $script:modulePath -Force
}

AfterAll {
    Remove-Module EvidenceExport -ErrorAction SilentlyContinue
}

Describe 'Portable evidence package validation' {
    It 'resolves relative artifact paths from the package directory' {
        Push-Location $script:repoRoot
        try {
            $validation = Test-CopilotGovEvidencePackage -Path $script:packagePath -ExpectedArtifacts @('lab-summary')
        }
        finally {
            Pop-Location
        }

        $validation.IsValid | Should -BeTrue
        $validation.ArtifactCount | Should -Be 1
    }

    It 'rewrites rooted artifact paths to relative entries while returning an absolute package path' {
        $outputPath = Join-Path $TestDrive 'portable-evidence-rooted'
        $artifactDirectory = Join-Path $outputPath 'artifact-data'
        $artifactPath = Join-Path $artifactDirectory 'lab-summary.json'
        $null = New-Item -ItemType Directory -Path $artifactDirectory -Force
        '{ "status": "sample" }' | Set-Content -Path $artifactPath -Encoding UTF8
        $artifactHash = Write-CopilotGovSha256File -Path $artifactPath

        $export = Export-SolutionEvidencePackage `
            -Solution 'lab-validation' `
            -SolutionCode 'LAB' `
            -Tier 'baseline' `
            -OutputPath $outputPath `
            -Summary @{ overallStatus = 'partial'; recordCount = 1 } `
            -Controls @(
                [pscustomobject]@{
                    controlId = '1.1'
                    status = 'partial'
                    notes = 'Portable evidence regression test control entry.'
                }
            ) `
            -Artifacts @(
                [pscustomobject]@{
                    name = 'lab-summary'
                    type = 'json'
                    path = (Resolve-Path -Path $artifactPath).Path
                    hash = $artifactHash.Hash
                }
            ) `
            -ExpectedArtifacts @('lab-summary')

        [IO.Path]::IsPathRooted($export.Path) | Should -BeTrue

        $package = Get-Content -Path $export.Path -Raw | ConvertFrom-Json -Depth 20
        [IO.Path]::IsPathRooted([string]$package.artifacts[0].path) | Should -BeFalse

        $validation = Test-CopilotGovEvidencePackage -Path $export.Path -ExpectedArtifacts @('lab-summary')
        $validation.IsValid | Should -BeTrue
    }
}

Describe 'validate-lab-package wrapper' {
    It 'succeeds for valid package and result fixtures' {
        $output = & $script:pwshPath -NoLogo -NoProfile -File $script:wrapperPath -Path $script:packagePath -ResultPath $script:validResultPath 2>&1
        $LASTEXITCODE | Should -Be 0
        ($output | Out-String) | Should -Match 'Lab package validation passed'
    }

    It 'returns a nonzero exit code for invalid result fixtures' {
        $null = & $script:pwshPath -NoLogo -NoProfile -File $script:wrapperPath -Path $script:packagePath -ResultPath $script:invalidResultPath 2>&1
        $LASTEXITCODE | Should -Not -Be 0
    }
}

Describe 'validate-lab-result mutation execution semantics' {
    It 'accepts a read-only fixture with zero executed mutations and not-required cleanup' {
        $output = & $script:pythonPath $script:resultValidatorPath $script:readOnlyResultPath 2>&1
        $LASTEXITCODE | Should -Be 0
        ($output | Out-String) | Should -Match 'validation passed'
    }

    It 'rejects mutationExecuted=true when mutationRef is null' {
        $output = & $script:pythonPath $script:resultValidatorPath $script:missingMutationRefResultPath 2>&1
        $LASTEXITCODE | Should -Not -Be 0
        ($output | Out-String) | Should -Match 'mutationExecuted=true requires a non-null mutationRef'
    }
}
