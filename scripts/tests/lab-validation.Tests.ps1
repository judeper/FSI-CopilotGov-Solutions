BeforeAll {
    $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
    $modulePath = Join-Path $repoRoot 'scripts/common/EvidenceExport.psm1'
    $wrapperPath = Join-Path $repoRoot 'scripts/validate-lab-package.ps1'
    $fixturesRoot = Join-Path $PSScriptRoot 'fixtures'
    $packagePath = Join-Path $fixturesRoot 'lab-package/portable-evidence.json'
    $resultValidatorPath = Join-Path $repoRoot 'scripts/validate-lab-result.py'
    $contractValidatorPath = Join-Path $repoRoot 'scripts/validate-lab-contracts.py'
    $solution04ContractPath = Join-Path $repoRoot 'solutions/04-finra-supervision-workflow/lab/04-finra-supervision-workflow.lab.json'
    $validResultPath = Join-Path $fixturesRoot 'lab-results/valid/01-copilot-readiness-scanner/lab/01-copilot-readiness-scanner.lab-result.json'
    $readOnlyResultPath = Join-Path $fixturesRoot 'lab-results/valid/read-only-no-mutations/01-copilot-readiness-scanner/lab/01-copilot-readiness-scanner.lab-result.json'
    $invalidResultPath = Join-Path $fixturesRoot 'lab-results/invalid/01-copilot-readiness-scanner/lab/01-copilot-readiness-scanner.lab-result.json'
    $missingMutationRefResultPath = Join-Path $fixturesRoot 'lab-results/invalid/mutation-executed-without-ref/01-copilot-readiness-scanner/lab/01-copilot-readiness-scanner.lab-result.json'
    $pwshPath = (Get-Command pwsh -ErrorAction Stop).Source
    $pythonPath = (Get-Command python -ErrorAction Stop).Source

    Import-Module $modulePath -Force
}

AfterAll {
    Remove-Module EvidenceExport -ErrorAction SilentlyContinue
}

Describe 'Portable evidence package validation' {
    It 'resolves relative artifact paths from the package directory' {
        Push-Location $repoRoot
        try {
            $validation = Test-CopilotGovEvidencePackage -Path $packagePath -ExpectedArtifacts @('lab-summary')
        }
        finally {
            Pop-Location
        }

        $validation.IsValid | Should -BeTrue
        $validation.ArtifactCount | Should -Be 1
    }
}

Describe 'validate-lab-package wrapper' {
    It 'succeeds for valid package and result fixtures' {
        $output = & $pwshPath -NoLogo -NoProfile -File $wrapperPath -Path $packagePath -ResultPath $validResultPath 2>&1
        $LASTEXITCODE | Should -Be 0
        ($output | Out-String) | Should -Match 'Lab package validation passed'
    }

    It 'returns a nonzero exit code for invalid result fixtures' {
        $null = & $pwshPath -NoLogo -NoProfile -File $wrapperPath -Path $packagePath -ResultPath $invalidResultPath 2>&1
        $LASTEXITCODE | Should -Not -Be 0
    }
}

Describe 'Repository lab contract validation' {
    It 'validates the FINRA supervision workflow (solution 04) lab contract' {
        $output = & $pythonPath $contractValidatorPath $solution04ContractPath 2>&1
        $LASTEXITCODE | Should -Be 0
        ($output | Out-String) | Should -Match 'validation passed'
    }
}

Describe 'validate-lab-result mutation execution semantics' {
    It 'accepts a read-only fixture with zero executed mutations and not-required cleanup' {
        $output = & $pythonPath $resultValidatorPath $readOnlyResultPath 2>&1
        $LASTEXITCODE | Should -Be 0
        ($output | Out-String) | Should -Match 'validation passed'
    }

    It 'rejects mutationExecuted=true when mutationRef is null' {
        $output = & $pythonPath $resultValidatorPath $missingMutationRefResultPath 2>&1
        $LASTEXITCODE | Should -Not -Be 0
        ($output | Out-String) | Should -Match 'mutationExecuted=true requires a non-null mutationRef'
    }
}
