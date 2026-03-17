BeforeAll {
    $solutionRoot = Join-Path $PSScriptRoot '..'
}

Describe 'Solution 17 — SharePoint Permissions Drift Detection' {

    Describe 'Solution structure' {
        It 'includes required solution files' {
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
                'config\baseline-config.json',
                'config\auto-revert-policy.json',
                'scripts\Deploy-Solution.ps1',
                'scripts\Monitor-Compliance.ps1',
                'scripts\Export-Evidence.ps1',
                'scripts\New-PermissionsBaseline.ps1',
                'scripts\Invoke-DriftScan.ps1',
                'scripts\Invoke-DriftReversion.ps1',
                'scripts\Export-DriftEvidence.ps1'
            )

            foreach ($relativePath in $requiredPaths) {
                $fullPath = Join-Path $solutionRoot $relativePath
                Test-Path -Path $fullPath | Should -BeTrue -Because "required file '$relativePath' should exist"
            }
        }

        It 'includes Pester test file' {
            $testFiles = Get-ChildItem -Path (Join-Path $solutionRoot 'tests') -Filter '*.Tests.ps1'
            $testFiles.Count | Should -BeGreaterOrEqual 1
        }
    }

    Describe 'Configuration content' {
        It 'parses default-config.json as valid JSON' {
            $configPath = Join-Path $solutionRoot 'config\default-config.json'
            $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json
            $config | Should -Not -BeNullOrEmpty
            $config.solution | Should -Be '17-sharepoint-permissions-drift'
            $config.solutionCode | Should -Be 'SPD'
        }

        It 'parses baseline-config.json as valid JSON' {
            $configPath = Join-Path $solutionRoot 'config\baseline-config.json'
            $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json
            $config | Should -Not -BeNullOrEmpty
            $config.scope | Should -Not -BeNullOrEmpty
        }

        It 'parses auto-revert-policy.json as valid JSON' {
            $configPath = Join-Path $solutionRoot 'config\auto-revert-policy.json'
            $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json
            $config | Should -Not -BeNullOrEmpty
            $config.reversionMode | Should -Be 'approval-gate'
            $config.autoRevertEnabled | Should -Be $false
        }

        It 'includes expected fields in all tier configs' {
            $tiers = @('baseline', 'recommended', 'regulated')
            foreach ($tier in $tiers) {
                $configPath = Join-Path $solutionRoot "config\$tier.json"
                $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json
                $config | Should -Not -BeNullOrEmpty -Because "tier config '$tier.json' should parse"
                $config.controls | Should -Not -BeNullOrEmpty -Because "tier config '$tier.json' should have controls"
                $config.evidenceOutputs | Should -Not -BeNullOrEmpty -Because "tier config '$tier.json' should have evidenceOutputs"
            }
        }

        It 'has increasing evidence retention across tiers' {
            $baselineConfig = Get-Content -Path (Join-Path $solutionRoot 'config\baseline.json') -Raw | ConvertFrom-Json
            $recommendedConfig = Get-Content -Path (Join-Path $solutionRoot 'config\recommended.json') -Raw | ConvertFrom-Json
            $regulatedConfig = Get-Content -Path (Join-Path $solutionRoot 'config\regulated.json') -Raw | ConvertFrom-Json

            $baselineConfig.evidenceRetentionDays | Should -BeLessThan $recommendedConfig.evidenceRetentionDays
            $recommendedConfig.evidenceRetentionDays | Should -BeLessThan $regulatedConfig.evidenceRetentionDays
        }

        It 'has consistent controls across all tier configs' {
            $defaultConfig = Get-Content -Path (Join-Path $solutionRoot 'config\default-config.json') -Raw | ConvertFrom-Json
            $tiers = @('baseline', 'recommended', 'regulated')
            foreach ($tier in $tiers) {
                $tierConfig = Get-Content -Path (Join-Path $solutionRoot "config\$tier.json") -Raw | ConvertFrom-Json
                $tierConfig.controls.Count | Should -Be $defaultConfig.controls.Count -Because "tier '$tier' should have the same number of controls as default"
            }
        }
    }

    Describe 'Script syntax validation' {
        It 'parses all solution scripts without syntax errors' {
            $scriptFiles = Get-ChildItem -Path (Join-Path $solutionRoot 'scripts') -Filter '*.ps1'
            foreach ($script in $scriptFiles) {
                $errors = $null
                $tokens = $null
                $ast = [System.Management.Automation.Language.Parser]::ParseFile(
                    $script.FullName,
                    [ref]$tokens,
                    [ref]$errors
                )
                $ast | Should -Not -BeNullOrEmpty -Because "script '$($script.Name)' should parse successfully"
                $errors.Count | Should -Be 0 -Because "script '$($script.Name)' should have no parse errors"
            }
        }
    }

    Describe 'Dependency declaration' {
        It 'references upstream solution in default-config.json' {
            $config = Get-Content -Path (Join-Path $solutionRoot 'config\default-config.json') -Raw | ConvertFrom-Json
            $config.upstreamDependency | Should -Be '02-oversharing-risk-assessment'
        }

        It 'references upstream solution in documentation' {
            $readme = Get-Content -Path (Join-Path $solutionRoot 'README.md') -Raw
            $readme | Should -Match '02-oversharing-risk-assessment'
        }
    }

    Describe 'Evidence types' {
        It 'documents all expected evidence outputs in default config' {
            $config = Get-Content -Path (Join-Path $solutionRoot 'config\default-config.json') -Raw | ConvertFrom-Json
            $config.evidenceOutputs | Should -Contain 'drift-report'
            $config.evidenceOutputs | Should -Contain 'baseline-snapshot'
            $config.evidenceOutputs | Should -Contain 'reversion-log'
        }
    }

    Describe 'README compliance' {
        BeforeAll {
            $readme = Get-Content -Path (Join-Path $solutionRoot 'README.md') -Raw
        }

        It 'includes the standardized status line' {
            $readme | Should -Match '\*\*Status:\*\* Documentation-first scaffold'
        }

        It 'includes the disclaimer banner' {
            $readme | Should -Match 'Documentation-first repository'
        }

        It 'includes Scope Boundaries section' {
            $readme | Should -Match '## Scope Boundaries'
        }

        It 'includes Related Controls section' {
            $readme | Should -Match '## Related Controls'
        }

        It 'includes Regulatory Alignment section' {
            $readme | Should -Match '## Regulatory Alignment'
        }

        It 'does not contain forbidden language' {
            $readme | Should -Not -Match 'ensures compliance'
            $readme | Should -Not -Match 'guarantees'
            $readme | Should -Not -Match 'will prevent'
            $readme | Should -Not -Match 'eliminates risk'
        }
    }
}
