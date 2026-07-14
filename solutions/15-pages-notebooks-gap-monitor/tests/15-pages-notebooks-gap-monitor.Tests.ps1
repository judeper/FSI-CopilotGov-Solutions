BeforeAll {
    $solutionRoot = Split-Path -Parent $PSScriptRoot
    $configRoot = Join-Path $solutionRoot 'config'
    $docsRoot = Join-Path $solutionRoot 'docs'
    $scriptsRoot = Join-Path $solutionRoot 'scripts'

    $script:requiredFiles = @(
        'README.md',
        'CHANGELOG.md',
        'DELIVERY-CHECKLIST.md',
        'config\default-config.json',
        'config\baseline.json',
        'config\recommended.json',
        'config\regulated.json',
        'docs\architecture.md',
        'docs\deployment-guide.md',
        'docs\evidence-export.md',
        'docs\prerequisites.md',
        'docs\troubleshooting.md',
        'scripts\Deploy-Solution.ps1',
        'scripts\Monitor-Compliance.ps1',
        'scripts\Export-Evidence.ps1',
        'scripts\PngmShared.psm1',
        'lab\15-pages-notebooks-gap-monitor.lab.json'
    )

    $script:defaultConfig = Get-Content (Join-Path $configRoot 'default-config.json') -Raw | ConvertFrom-Json
    $script:regulatedConfig = Get-Content (Join-Path $configRoot 'regulated.json') -Raw | ConvertFrom-Json
    $script:readmeContent = Get-Content (Join-Path $solutionRoot 'README.md') -Raw
    $script:evidenceExportContent = Get-Content (Join-Path $docsRoot 'evidence-export.md') -Raw
    $deployScriptPath = Join-Path $scriptsRoot 'Deploy-Solution.ps1'
    $monitorScriptPath = Join-Path $scriptsRoot 'Monitor-Compliance.ps1'
    $exportScriptPath = Join-Path $scriptsRoot 'Export-Evidence.ps1'
    $script:scriptPaths = @($deployScriptPath, $monitorScriptPath, $exportScriptPath)
    $script:deployScriptContent = Get-Content $deployScriptPath -Raw
    $script:deployScriptPath = $deployScriptPath
    $script:monitorScriptPath = $monitorScriptPath
    $script:exportScriptPath = $exportScriptPath
    $script:testArtifactsRoot = Join-Path $solutionRoot 'artifacts\pester-behavior'
    $script:labContractPath = Join-Path $solutionRoot 'lab\15-pages-notebooks-gap-monitor.lab.json'

    if (Test-Path -Path $script:testArtifactsRoot) {
        Remove-Item -Path $script:testArtifactsRoot -Recurse -Force
    }
}

AfterAll {
    if (Test-Path -Path $script:testArtifactsRoot) {
        Remove-Item -Path $script:testArtifactsRoot -Recurse -Force
    }
}

Describe 'Copilot Pages and Notebooks Compliance Gap Monitor' {
    Context 'file presence' {
        It 'has all required files' {
            foreach ($relativePath in $script:requiredFiles) {
                Test-Path (Join-Path $solutionRoot $relativePath) | Should -BeTrue
            }
        }
    }

    Context 'configuration' {
        It 'has the correct solution slug, code, and controls' {
            $script:defaultConfig.solution | Should -Be '15-pages-notebooks-gap-monitor'
            $script:defaultConfig.solutionCode | Should -Be 'PNGM'
            @($script:defaultConfig.controls) | Should -HaveCount 4
            @($script:defaultConfig.controls) | Should -Contain '2.11'
            @($script:defaultConfig.controls) | Should -Contain '3.2'
            @($script:defaultConfig.controls) | Should -Contain '3.3'
            @($script:defaultConfig.controls) | Should -Contain '3.11'
        }

        It 'enables preservation exception tracking for the regulated tier' {
            $script:regulatedConfig.preservationExceptionTracking | Should -BeTrue
        }
    }

    Context 'script validation' {
        It 'parses all PowerShell scripts without syntax errors' {
            foreach ($scriptPath in $script:scriptPaths) {
                $tokens = $null
                $errors = $null
                [System.Management.Automation.Language.Parser]::ParseFile($scriptPath, [ref]$tokens, [ref]$errors) | Out-Null
                @($errors).Count | Should -Be 0
            }
        }

        It 'supports WhatIf on Deploy-Solution.ps1' {
            $script:deployScriptContent | Should -Match 'CmdletBinding\(SupportsShouldProcess\)'
        }
    }

    Context 'documentation content' {
        It 'mentions gap monitoring and SEC 17a-4 in the README' {
            $script:readmeContent | Should -Match '(?i)gap'
            $script:readmeContent | Should -Match 'SEC 17a-4'
        }

        It 'references all evidence outputs in evidence-export.md' {
            $script:evidenceExportContent | Should -Match 'gap-findings'
            $script:evidenceExportContent | Should -Match 'compensating-control-log'
            $script:evidenceExportContent | Should -Match 'preservation-exception-register'
        }
    }

    Context 'behavioral script checks' {
        It 'includes dependency status in deployment output' {
            $deployOutputPath = Join-Path $script:testArtifactsRoot 'deploy'
            $result = & $script:deployScriptPath -ConfigurationTier recommended -OutputPath $deployOutputPath

            $result.dependencyMissingCount | Should -Be 0
            Test-Path -Path $result.manifestPath | Should -BeTrue

            $manifest = Get-Content -Path $result.manifestPath -Raw | ConvertFrom-Json
            $manifest.dependencyStatus.hasMissingDependencies | Should -BeFalse
            @($manifest.dependencyStatus.dependencies).dependency | Should -Contain '06-audit-trail-manager'
        }

        It 'marks rollout-sensitive gaps as validation-required in evidence exports' {
            $exportOutputPath = Join-Path $script:testArtifactsRoot 'evidence'
            $relativeOutputPath = [System.IO.Path]::GetRelativePath((Get-Location).Path, $exportOutputPath)
            $result = & $script:exportScriptPath -ConfigurationTier regulated -OutputPath $relativeOutputPath -PassThru

            Test-Path -Path $result.packagePath | Should -BeTrue
            Test-Path -Path ($result.packagePath + '.sha256') | Should -BeTrue
            [System.IO.Path]::IsPathRooted([string]$result.packagePath) | Should -BeTrue

            $package = Get-Content -Path $result.packagePath -Raw | ConvertFrom-Json
            foreach ($artifact in @($package.artifacts)) {
                [System.IO.Path]::IsPathRooted([string]$artifact.path) | Should -BeFalse
                Test-Path -Path (Join-Path $exportOutputPath $artifact.path) | Should -BeTrue
            }

            $gapFindingsPath = Join-Path $exportOutputPath '15-pages-notebooks-gap-monitor-gap-findings.json'
            $gapFindings = Get-Content -Path $gapFindingsPath -Raw | ConvertFrom-Json
            $gap002 = @($gapFindings.records | Where-Object { $_.gapId -eq 'PNGM-GAP-002' })[0]
            $gap005 = @($gapFindings.records | Where-Object { $_.gapId -eq 'PNGM-GAP-005' })[0]

            $gap002.status | Should -Be 'validation-required'
            $gap005.status | Should -Be 'validation-required'
            $gap002.severity | Should -Be 'medium'
            $gap005.severity | Should -Be 'medium'
        }

        It 'aggregates regulated monitor control states as partial' {
            $monitorOutputPath = Join-Path $script:testArtifactsRoot 'monitor'
            $result = & $script:monitorScriptPath -ConfigurationTier regulated -OutputPath $monitorOutputPath -PassThru -WhatIf

            $result.overallStatus | Should -Be 'partial'
            $result.validationRequiredGapCount | Should -BeGreaterThan 0
            @($result.controls | Where-Object { $_.status -eq 'partial' }).Count | Should -Be 4
            $result.dependencyStatus.hasMissingDependencies | Should -BeFalse
        }

        It 'keeps lab contract read-only with no mutations' {
            $contract = Get-Content -Path $script:labContractPath -Raw | ConvertFrom-Json
            $contract.solution.id | Should -Be '15-pages-notebooks-gap-monitor'
            $contract.solution.binding | Should -Be 'template'
            @($contract.mutations).Count | Should -Be 0
            $contract.scope.cloud | Should -Be 'm365-us-commercial'
            $contract.scope.usCommercialOnly | Should -BeTrue
        }
    }
}
