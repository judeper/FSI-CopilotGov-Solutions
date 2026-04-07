Describe 'Copilot Feature Management Controller solution' {
    BeforeAll {
        $solutionRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
        $deployScript = Join-Path $solutionRoot 'scripts\Deploy-Solution.ps1'
        $monitorScript = Join-Path $solutionRoot 'scripts\Monitor-Compliance.ps1'
        $exportScript = Join-Path $solutionRoot 'scripts\Export-Evidence.ps1'
        $defaultConfigPath = Join-Path $solutionRoot 'config\default-config.json'
        $regulatedConfigPath = Join-Path $solutionRoot 'config\regulated.json'
    }

    It 'has required configuration files' {
        @(
            'config\default-config.json',
            'config\baseline.json',
            'config\recommended.json',
            'config\regulated.json'
        ) | ForEach-Object {
            Test-Path (Join-Path $solutionRoot $_) | Should -BeTrue
        }
    }

    It 'has required documentation files' {
        @(
            'README.md',
            'CHANGELOG.md',
            'DELIVERY-CHECKLIST.md',
            'docs\architecture.md',
            'docs\deployment-guide.md',
            'docs\evidence-export.md',
            'docs\prerequisites.md',
            'docs\troubleshooting.md'
        ) | ForEach-Object {
            Test-Path (Join-Path $solutionRoot $_) | Should -BeTrue
        }
    }

    It 'includes comment-based help in Deploy-Solution.ps1' {
        (Get-Content -Path $deployScript -Raw) | Should -Match '(?s)<#.*?\.SYNOPSIS.*?#>'
    }

    It 'accepts BaselinePath in Monitor-Compliance.ps1' {
        $tokens = $null
        $errors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($monitorScript, [ref]$tokens, [ref]$errors)
        $parameterNames = $ast.ParamBlock.Parameters.Name.VariablePath.UserPath

        $errors | Should -BeNullOrEmpty
        $parameterNames | Should -Contain 'BaselinePath'
    }

    It 'references the FMC solution code in Export-Evidence.ps1' {
        (Get-Content -Path $exportScript -Raw) | Should -Match "SolutionCode 'FMC'"
    }

    It 'contains rollout ring or feature configuration in default-config.json' {
        $defaultConfig = Get-Content -Path $defaultConfigPath -Raw | ConvertFrom-Json -AsHashtable
        ($defaultConfig.ContainsKey('rolloutRings') -or $defaultConfig.ContainsKey('featureCategories')) | Should -BeTrue
    }

    It 'sets regulated evidence retention to at least 365 days' {
        $regulatedConfig = Get-Content -Path $regulatedConfigPath -Raw | ConvertFrom-Json
        [int]$regulatedConfig.evidenceRetentionDays | Should -BeGreaterOrEqual 365
    }

    It 'has valid PowerShell syntax in Deploy-Solution.ps1' {
        $tokens = $null
        $errors = $null
        [System.Management.Automation.Language.Parser]::ParseFile($deployScript, [ref]$tokens, [ref]$errors) | Out-Null

        $errors | Should -BeNullOrEmpty
    }
}

Describe 'FMC functional tests' {
    BeforeAll {
        $solutionRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
        $monitorScript = Join-Path $solutionRoot 'scripts\Monitor-Compliance.ps1'
        $deployScript = Join-Path $solutionRoot 'scripts\Deploy-Solution.ps1'
        $exportScript = Join-Path $solutionRoot 'scripts\Export-Evidence.ps1'

        # Extract function definitions from scripts using AST for isolated testing
        foreach ($scriptPath in @($monitorScript, $deployScript, $exportScript)) {
            $tokens = $null; $errors = $null
            $ast = [System.Management.Automation.Language.Parser]::ParseFile(
                $scriptPath, [ref]$tokens, [ref]$errors)
            $functionDefs = $ast.FindAll(
                { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $false)
            foreach ($funcDef in $functionDefs) {
                . ([scriptblock]::Create($funcDef.Extent.Text))
            }
        }
    }

    Context 'Compare-FeatureBaseline' {
        It 'detects ring mismatch drift' {
            $baseline = [pscustomobject]@{
                features = @(
                    [pscustomobject]@{
                        featureId       = 'test-feature'
                        displayName     = 'Test Feature'
                        sourceSystem    = 'Test'
                        category        = 'test'
                        expectedEnabled = $true
                        expectedRing    = 'Early Adopters'
                    }
                )
            }
            $currentState = @(
                [pscustomobject]@{
                    featureId      = 'test-feature'
                    displayName    = 'Test Feature'
                    currentEnabled = $true
                    currentRing    = 'General Availability'
                }
            )

            $findings = Compare-FeatureBaseline -BaselineDocument $baseline -CurrentState $currentState
            @($findings).Count | Should -BeGreaterOrEqual 1
            @($findings | Where-Object { $_.driftType -eq 'ringMismatch' }).Count | Should -Be 1
        }

        It 'detects enablement mismatch drift' {
            $baseline = [pscustomobject]@{
                features = @(
                    [pscustomobject]@{
                        featureId       = 'test-feature'
                        displayName     = 'Test Feature'
                        sourceSystem    = 'Test'
                        category        = 'test'
                        expectedEnabled = $true
                        expectedRing    = 'General Availability'
                    }
                )
            }
            $currentState = @(
                [pscustomobject]@{
                    featureId      = 'test-feature'
                    displayName    = 'Test Feature'
                    currentEnabled = $false
                    currentRing    = 'General Availability'
                }
            )

            $findings = Compare-FeatureBaseline -BaselineDocument $baseline -CurrentState $currentState
            @($findings).Count | Should -BeGreaterOrEqual 1
            @($findings | Where-Object { $_.driftType -eq 'enablementMismatch' }).Count | Should -Be 1
        }

        It 'returns empty findings when no drift exists' {
            $baseline = [pscustomobject]@{
                features = @(
                    [pscustomobject]@{
                        featureId       = 'test-feature'
                        displayName     = 'Test Feature'
                        sourceSystem    = 'Test'
                        category        = 'test'
                        expectedEnabled = $true
                        expectedRing    = 'General Availability'
                    }
                )
            }
            $currentState = @(
                [pscustomobject]@{
                    featureId      = 'test-feature'
                    displayName    = 'Test Feature'
                    currentEnabled = $true
                    currentRing    = 'General Availability'
                }
            )

            $findings = Compare-FeatureBaseline -BaselineDocument $baseline -CurrentState $currentState
            @($findings).Count | Should -Be 0
        }

        It 'detects unexpected features not in baseline' {
            $baseline = [pscustomobject]@{
                features = @(
                    [pscustomobject]@{
                        featureId       = 'approved-feature'
                        displayName     = 'Approved Feature'
                        sourceSystem    = 'Test'
                        category        = 'test'
                        expectedEnabled = $true
                        expectedRing    = 'General Availability'
                    }
                )
            }
            $currentState = @(
                [pscustomobject]@{
                    featureId      = 'approved-feature'
                    displayName    = 'Approved Feature'
                    currentEnabled = $true
                    currentRing    = 'General Availability'
                },
                [pscustomobject]@{
                    featureId      = 'unexpected-feature'
                    displayName    = 'Unexpected Feature'
                    currentEnabled = $true
                    currentRing    = 'General Availability'
                }
            )

            $findings = Compare-FeatureBaseline -BaselineDocument $baseline -CurrentState $currentState
            @($findings | Where-Object { $_.driftType -eq 'unexpectedFeature' }).Count | Should -Be 1
        }
    }

    Context 'Set-FeatureRolloutRing' {
        It 'assigns feature to the specified ring with WhatIf' {
            $feature = [pscustomobject]@{
                featureId   = 'test-feature'
                displayName = 'Test Feature'
            }
            $ringDef = @{
                targetPercentage = 15
                approvalRequired = $true
                enabled          = $true
            }

            $result = Set-FeatureRolloutRing -Feature $feature -TargetRing 'Early Adopters' -RingDefinition $ringDef -Environment 'Test' -WhatIf
            $result.featureId | Should -Be 'test-feature'
            $result.targetRing | Should -Be 'Early Adopters'
            $result.targetPercentage | Should -Be 15
            $result.action | Should -Be 'whatif'
        }
    }

    Context 'Get-StableFeatureHash' {
        It 'produces deterministic output across calls' {
            $hash1 = Get-StableFeatureHash -FeatureId 'test-feature'
            $hash2 = Get-StableFeatureHash -FeatureId 'test-feature'
            $hash1 | Should -Be $hash2
        }

        It 'produces different values for different feature IDs' {
            $hash1 = Get-StableFeatureHash -FeatureId 'feature-a'
            $hash2 = Get-StableFeatureHash -FeatureId 'feature-b'
            $hash1 | Should -Not -Be $hash2
        }
    }

    Context 'Evidence export tier awareness' {
        It 'baseline tier does not define third-party-plugin-execution feature' {
            $baselineConfig = Get-Content -Path (Join-Path $solutionRoot 'config\baseline.json') -Raw | ConvertFrom-Json
            $featureIds = @($baselineConfig.features | ForEach-Object { $_.featureId })
            $featureIds | Should -Not -Contain 'third-party-plugin-execution'
        }

        It 'regulated tier defines third-party-plugin-execution feature' {
            $regulatedConfig = Get-Content -Path (Join-Path $solutionRoot 'config\regulated.json') -Raw | ConvertFrom-Json
            $featureIds = @($regulatedConfig.features | ForEach-Object { $_.featureId })
            $featureIds | Should -Contain 'third-party-plugin-execution'
        }

        It 'export script has valid PowerShell syntax after changes' {
            $tokens = $null; $errors = $null
            [System.Management.Automation.Language.Parser]::ParseFile(
                $exportScript, [ref]$tokens, [ref]$errors) | Out-Null
            $errors | Should -BeNullOrEmpty
        }
    }
}
