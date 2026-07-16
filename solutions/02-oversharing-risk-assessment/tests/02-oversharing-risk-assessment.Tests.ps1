BeforeAll {
    Set-StrictMode -Version Latest

    $script:solutionRoot = Join-Path $PSScriptRoot '..'
    $script:docsRoot = Join-Path $script:solutionRoot 'docs'
    $script:configRoot = Join-Path $script:solutionRoot 'config'
    $script:scriptsRoot = Join-Path $script:solutionRoot 'scripts'
    $script:labRoot = Join-Path $script:solutionRoot 'lab'
    $script:repoRoot = (Resolve-Path (Join-Path $script:solutionRoot '..\..')).Path

    $script:deployScript = Join-Path $script:scriptsRoot 'Deploy-Solution.ps1'
    $script:monitorScript = Join-Path $script:scriptsRoot 'Monitor-Compliance.ps1'
    $script:exportScript = Join-Path $script:scriptsRoot 'Export-Evidence.ps1'
    $script:labContractPath = Join-Path $script:labRoot '02-oversharing-risk-assessment.lab.json'
    $script:labValidatorPath = Join-Path $script:repoRoot 'scripts\validate-lab-contracts.py'
    $script:pythonPath = (Get-Command python -ErrorAction Stop).Source

    $script:defaultConfig = Get-Content -Path (Join-Path $script:configRoot 'default-config.json') -Raw | ConvertFrom-Json -AsHashtable
    $script:baselineConfig = Get-Content -Path (Join-Path $script:configRoot 'baseline.json') -Raw | ConvertFrom-Json -AsHashtable
    $script:recommendedConfig = Get-Content -Path (Join-Path $script:configRoot 'recommended.json') -Raw | ConvertFrom-Json -AsHashtable
    $script:regulatedConfig = Get-Content -Path (Join-Path $script:configRoot 'regulated.json') -Raw | ConvertFrom-Json -AsHashtable
}

Describe 'Solution structure and configuration' {
    It 'includes required solution files including the lab contract' {
        $requiredPaths = @(
            'README.md',
            'CHANGELOG.md',
            'DELIVERY-CHECKLIST.md',
            'docs\architecture.md',
            'docs\deployment-guide.md',
            'docs\evidence-export.md',
            'docs\prerequisites.md',
            'docs\troubleshooting.md',
            'config\default-config.json',
            'config\baseline.json',
            'config\recommended.json',
            'config\regulated.json',
            'scripts\Deploy-Solution.ps1',
            'scripts\Monitor-Compliance.ps1',
            'scripts\Export-Evidence.ps1',
            'scripts\SharedUtilities.psm1',
            'lab\02-oversharing-risk-assessment.lab.json',
            'tests\02-oversharing-risk-assessment.Tests.ps1'
        )

        foreach ($relativePath in $requiredPaths) {
            Test-Path -Path (Join-Path $script:solutionRoot $relativePath) | Should -BeTrue
        }
    }

    It 'keeps the expected control mapping across all tiers' {
        $expectedControls = @('1.2', '1.3', '1.4', '1.6', '2.5', '2.12')
        (@($script:defaultConfig.controls) -join ',') | Should -Be ($expectedControls -join ',')
        (@($script:baselineConfig.controls) -join ',') | Should -Be ($expectedControls -join ',')
        (@($script:recommendedConfig.controls) -join ',') | Should -Be ($expectedControls -join ',')
        (@($script:regulatedConfig.controls) -join ',') | Should -Be ($expectedControls -join ',')
    }

    It 'keeps Restricted SharePoint Search disabled in all tiers and adds tiered RCD planning flags' {
        $script:defaultConfig.enableRestrictedSharePointSearch | Should -BeFalse
        $script:baselineConfig.enableRestrictedSharePointSearch | Should -BeFalse
        $script:recommendedConfig.enableRestrictedSharePointSearch | Should -BeFalse
        $script:regulatedConfig.enableRestrictedSharePointSearch | Should -BeFalse

        $script:defaultConfig.enableRestrictedContentDiscoveryPlanning | Should -BeFalse
        $script:baselineConfig.enableRestrictedContentDiscoveryPlanning | Should -BeFalse
        $script:recommendedConfig.enableRestrictedContentDiscoveryPlanning | Should -BeTrue
        $script:regulatedConfig.enableRestrictedContentDiscoveryPlanning | Should -BeTrue
    }

    It 'uses longer evidence retention in regulated and recommended tiers' {
        [int]$script:regulatedConfig.evidenceRetentionDays | Should -BeGreaterThan ([int]$script:recommendedConfig.evidenceRetentionDays)
        [int]$script:recommendedConfig.evidenceRetentionDays | Should -BeGreaterThan ([int]$script:baselineConfig.evidenceRetentionDays)
    }
}

Describe 'Documentation regression checks' {
    It 'keeps Scope Boundaries honest about sample mode, opt-in Graph, and no tenant writes' {
        $readme = Get-Content -Path (Join-Path $script:solutionRoot 'README.md') -Raw
        $readme | Should -Match 'Default/sample mode does not connect'
        $readme | Should -Match 'Optional read-only Microsoft Graph mode'
        $readme | Should -Match 'Does not execute tenant writes'
    }

    It 'includes the lab contract in the README component table' {
        $readme = Get-Content -Path (Join-Path $script:solutionRoot 'README.md') -Raw
        $readme | Should -Match 'lab\\02-oversharing-risk-assessment\.lab\.json'
    }

    It 'keeps v0.2.5 release metadata and accepted lab markers aligned' {
        $readme = Get-Content -Path (Join-Path $script:solutionRoot 'README.md') -Raw
        $changelog = Get-Content -Path (Join-Path $script:solutionRoot 'CHANGELOG.md') -Raw
        $checklist = Get-Content -Path (Join-Path $script:solutionRoot 'DELIVERY-CHECKLIST.md') -Raw

        $readme | Should -Match '\*\*Version:\*\* v0\.2\.5'
        $readme | Should -Match 'Last Verified:\*\* 2026-07-16'
        $readme | Should -Match 'Accepted `PASS` on 2026-07-16'

        $script:defaultConfig.version | Should -Be 'v0.2.5'
        $changelog | Should -Match '## \[v0\.2\.5\]'
        $changelog | Should -Match '### Validated'
        $checklist | Should -Match '## Lab Validation Acceptance'
    }

    It 'documents SAM role and entitlement updates plus qualified PnP guidance' {
        $prereq = Get-Content -Path (Join-Path $script:docsRoot 'prerequisites.md') -Raw
        $troubleshooting = Get-Content -Path (Join-Path $script:docsRoot 'troubleshooting.md') -Raw

        $prereq | Should -Match 'Microsoft 365 E7'
        $prereq | Should -Match 'SharePoint Advanced Management Administrator'
        $prereq | Should -Match 'Compliance Administrator \(for Purview/DSPM tasks\)'
        $prereq | Should -Match 'project-documented; validate in your lab'
        $troubleshooting | Should -Match 'project-documented runtime pattern'
    }

    It 'documents RSS retirement and RCD go-forward guidance across core docs and scripts' {
        $pathsToCheck = @(
            (Join-Path $script:solutionRoot 'README.md'),
            (Join-Path $script:solutionRoot 'DELIVERY-CHECKLIST.md'),
            (Join-Path $script:docsRoot 'architecture.md'),
            (Join-Path $script:docsRoot 'deployment-guide.md'),
            (Join-Path $script:docsRoot 'evidence-export.md'),
            (Join-Path $script:docsRoot 'troubleshooting.md'),
            (Join-Path $script:scriptsRoot 'Deploy-Solution.ps1'),
            (Join-Path $script:scriptsRoot 'Export-Evidence.ps1')
        )

        foreach ($path in $pathsToCheck) {
            $content = Get-Content -Path $path -Raw
            $content | Should -Match 'Restricted Content Discovery'
            $content | Should -Match '2026-07-31'
        }
    }

    It 'does not publish unverified 2027 retirement dates in solution files' {
        $filesToScan = @(
            Get-ChildItem -Path $script:solutionRoot -Recurse -File -Include *.md,*.ps1,*.json |
                Where-Object { $_.FullName -notmatch '[\\/]tests[\\/]' }
        )

        foreach ($file in $filesToScan) {
            (Get-Content -Path $file.FullName -Raw) | Should -Not -Match '2027'
        }
    }
}

Describe 'Script syntax validation' {
    It 'parses all PowerShell scripts without syntax errors' {
        $scriptPaths = @($script:deployScript, $script:monitorScript, $script:exportScript)
        foreach ($scriptPath in $scriptPaths) {
            $tokens = $null
            $errors = $null
            [System.Management.Automation.Language.Parser]::ParseFile($scriptPath, [ref]$tokens, [ref]$errors) | Out-Null
            @($errors).Count | Should -Be 0
        }
    }
}

Describe 'Deploy-Solution.ps1 behavior regressions' {
    BeforeAll {
        $script:dependencyRoot = [System.IO.Path]::GetFullPath((Join-Path $script:scriptsRoot '..\..\01-copilot-readiness-scanner\artifacts'))
        $script:dependencyBackup = $null
        if (Test-Path -Path $script:dependencyRoot) {
            $script:dependencyBackup = "$script:dependencyRoot.pester-backup"
            if (Test-Path -Path $script:dependencyBackup) {
                Remove-Item -Path $script:dependencyBackup -Recurse -Force
            }
            Move-Item -Path $script:dependencyRoot -Destination $script:dependencyBackup
        }
    }

    AfterAll {
        if ($null -ne $script:dependencyBackup -and (Test-Path -Path $script:dependencyBackup)) {
            Move-Item -Path $script:dependencyBackup -Destination $script:dependencyRoot
        }
    }

    It 'returns a preview dependency result for WhatIf when upstream output is missing' {
        $previewOutputPath = Join-Path $TestDrive 'deploy-preview'
        $output = & $script:deployScript -ConfigurationTier recommended -TenantId '00000000-0000-0000-0000-000000000000' -ScanMode DetectOnly -OutputPath $previewOutputPath -WhatIf 3>&1

        $warnings = @($output | Where-Object { $_ -is [System.Management.Automation.WarningRecord] })
        @($warnings).Count | Should -BeGreaterThan 0
        (($warnings | ForEach-Object { $_.Message }) -join ' ') | Should -Match 'Upstream dependency output path not found'

        $result = $output | Where-Object { $_ -is [pscustomobject] } | Select-Object -Last 1
        $result.DependencyStatus | Should -Be 'preview-blocked-missing-upstream-output'
        $result.RestrictedSharePointSearchStatus | Should -Be 'legacy-not-requested'
        $result.RestrictedContentDiscoveryStatus | Should -Be 'planning-enabled'
        Test-Path -Path $result.DeploymentManifestPath | Should -BeFalse
    }

    It 'throws for real deployment when upstream output is missing' {
        $realOutputPath = Join-Path $TestDrive 'deploy-real'
        {
            & $script:deployScript -ConfigurationTier recommended -TenantId '00000000-0000-0000-0000-000000000000' -ScanMode DetectOnly -OutputPath $realOutputPath
        } | Should -Throw '*Upstream dependency output path not found*'
    }
}

Describe 'Monitor-Compliance.ps1 behavior regressions' {
    It 'uses supplied scanned-site count for sample sensitivity label coverage' {
        $monitorOutputPath = Join-Path $TestDrive 'monitor-sharepoint'
        $findings = @(
            & $script:monitorScript `
                -ConfigurationTier baseline `
                -TenantId '00000000-0000-0000-0000-000000000000' `
                -WorkloadsToScan sharePoint `
                -MaxSites 1 `
                -ExportPath $monitorOutputPath
        )

        @($findings).Count | Should -Be 1
        $summaryPath = Join-Path $monitorOutputPath 'monitor-summary.json'
        Test-Path -Path $summaryPath | Should -BeTrue

        $summary = Get-Content -Path $summaryPath -Raw | ConvertFrom-Json
        [int]$summary.SensitivityLabelCoverage.TotalSitesScanned | Should -Be 3
        [int]$summary.SensitivityLabelCoverage.TotalSitesScanned | Should -BeGreaterThan @($findings).Count
    }
}

Describe 'Export-Evidence.ps1 behavior regressions' {
    It 'generates owner attestation records for regulated tier without IncludeAttestations' {
        $outputPath = Join-Path $TestDrive 'evidence-regulated'
        $result = & $script:exportScript -ConfigurationTier regulated -TenantId '00000000-0000-0000-0000-000000000000' -OutputPath $outputPath -PeriodStart ([datetime]'2026-07-01') -PeriodEnd ([datetime]'2026-07-08')

        $result.Attestations | Should -BeGreaterThan 0
        $attestationPath = Join-Path $outputPath 'site-owner-attestations.json'
        $attestationRows = @(Get-Content -Path $attestationPath -Raw | ConvertFrom-Json)
        (@($attestationRows | Where-Object { $_.attestationStatus -eq 'requested' })).Count | Should -BeGreaterThan 0
    }

    It 'keeps IncludeAttestations optional for non-regulated tiers' {
        $outputPath = Join-Path $TestDrive 'evidence-recommended'
        $result = & $script:exportScript -ConfigurationTier recommended -TenantId '00000000-0000-0000-0000-000000000000' -OutputPath $outputPath -PeriodStart ([datetime]'2026-07-01') -PeriodEnd ([datetime]'2026-07-08')

        $result.Attestations | Should -Be 1
        $attestationPath = Join-Path $outputPath 'site-owner-attestations.json'
        $attestationRows = @(Get-Content -Path $attestationPath -Raw | ConvertFrom-Json)
        $attestationRows[0].attestationStatus | Should -Be 'not-requested'
    }

    It 'writes package-relative artifact paths while returning an absolute PackagePath' {
        $outputPath = Join-Path $TestDrive 'evidence-relative-paths'
        $result = & $script:exportScript -ConfigurationTier recommended -TenantId '00000000-0000-0000-0000-000000000000' -OutputPath $outputPath -PeriodStart ([datetime]'2026-07-01') -PeriodEnd ([datetime]'2026-07-08')

        [System.IO.Path]::IsPathRooted([string]$result.PackagePath) | Should -BeTrue
        Test-Path -Path $result.PackagePath | Should -BeTrue

        $package = Get-Content -Path $result.PackagePath -Raw | ConvertFrom-Json -Depth 20
        foreach ($artifact in @($package.artifacts)) {
            [System.IO.Path]::IsPathRooted([string]$artifact.path) | Should -BeFalse
            [string]$artifact.path | Should -Not -Match '[\\/]'
        }
    }
}

Describe 'Lab contract validation' {
    It 'defines a read-only contract with expected control mapping and scope semantics' {
        $contract = Get-Content -Path $script:labContractPath -Raw | ConvertFrom-Json -Depth 20

        (@($contract.controls) -join ',') | Should -Be '1.2,1.3,1.4,1.6,2.5,2.12'
        $contract.scope.cloud | Should -Be 'm365-us-commercial'
        $contract.scope.usCommercialOnly | Should -BeTrue
        $contract.scope.PSObject.Properties.Name | Should -Not -Contain 'prohibitedClouds'
        @($contract.mutations).Count | Should -Be 0

        foreach ($phase in @($contract.execution.phases)) {
            foreach ($step in @($phase.steps)) {
                $step.mutationRef | Should -BeNullOrEmpty
            }
        }
    }

    It 'passes the repository lab contract validator' {
        $output = & $script:pythonPath $script:labValidatorPath $script:labContractPath 2>&1
        $LASTEXITCODE | Should -Be 0
        (($output | Out-String).ToLowerInvariant()) | Should -Match 'validation passed'
    }
}
