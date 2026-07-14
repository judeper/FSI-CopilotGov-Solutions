Describe 'Copilot Feature Management Controller solution' {
    BeforeAll {
        $solutionRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
        $script:deployScript = Join-Path $solutionRoot 'scripts\Deploy-Solution.ps1'
        $script:monitorScript = Join-Path $solutionRoot 'scripts\Monitor-Compliance.ps1'
        $script:exportScript = Join-Path $solutionRoot 'scripts\Export-Evidence.ps1'
        $script:defaultConfigPath = Join-Path $solutionRoot 'config\default-config.json'
        $script:regulatedConfigPath = Join-Path $solutionRoot 'config\regulated.json'
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
        (Get-Content -Path $script:deployScript -Raw) | Should -Match '(?s)<#.*?\.SYNOPSIS.*?#>'
    }

    It 'accepts BaselinePath in Monitor-Compliance.ps1' {
        $tokens = $null
        $errors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($script:monitorScript, [ref]$tokens, [ref]$errors)
        $parameterNames = $ast.ParamBlock.Parameters.Name.VariablePath.UserPath

        $errors | Should -BeNullOrEmpty
        $parameterNames | Should -Contain 'BaselinePath'
    }

    It 'references the FMC solution code in Export-Evidence.ps1' {
        (Get-Content -Path $script:exportScript -Raw) | Should -Match "SolutionCode 'FMC'"
    }

    It 'contains rollout ring or feature configuration in default-config.json' {
        $defaultConfig = Get-Content -Path $script:defaultConfigPath -Raw | ConvertFrom-Json -AsHashtable
        ($defaultConfig.ContainsKey('rolloutRings') -or $defaultConfig.ContainsKey('featureCategories')) | Should -BeTrue
    }

    It 'sets regulated evidence retention to at least 365 days' {
        $regulatedConfig = Get-Content -Path $script:regulatedConfigPath -Raw | ConvertFrom-Json
        [int]$regulatedConfig.evidenceRetentionDays | Should -BeGreaterOrEqual 365
    }

    It 'has valid PowerShell syntax in Deploy-Solution.ps1' {
        $tokens = $null
        $errors = $null
        [System.Management.Automation.Language.Parser]::ParseFile($script:deployScript, [ref]$tokens, [ref]$errors) | Out-Null

        $errors | Should -BeNullOrEmpty
    }
}

Describe 'FMC functional tests' {
    BeforeAll {
        $solutionRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
        $script:monitorScript = Join-Path $solutionRoot 'scripts\Monitor-Compliance.ps1'
        $script:deployScript = Join-Path $solutionRoot 'scripts\Deploy-Solution.ps1'
        $script:exportScript = Join-Path $solutionRoot 'scripts\Export-Evidence.ps1'

        # Extract function definitions from scripts using AST for isolated testing
        foreach ($scriptPath in @($script:monitorScript, $script:deployScript, $script:exportScript)) {
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

    Context 'Get-PowerAutomateFlowPlan' {
        It 'defers ring promotion when BaselineOnly is specified' {
            $configuration = @{
                powerAutomate = @{
                    documentationFirst = $true
                    flows = @(
                        @{
                            name = 'FMC-DriftMonitor'
                            trigger = 'Hourly recurrence'
                            purpose = 'Collect current feature state.'
                        },
                        @{
                            name = 'FMC-RingPromotion'
                            trigger = 'On-demand'
                            purpose = 'Document ring promotions.'
                        }
                    )
                }
            }

            $result = Get-PowerAutomateFlowPlan -Configuration $configuration -Environment 'Test' -BaselineOnly
            $ringPromotion = $result | Where-Object { $_.name -eq 'FMC-RingPromotion' } | Select-Object -First 1
            $driftMonitor = $result | Where-Object { $_.name -eq 'FMC-DriftMonitor' } | Select-Object -First 1

            $ringPromotion.deploymentState | Should -Be 'deferred'
            $driftMonitor.deploymentState | Should -Be 'documented'
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

    Context 'Test-BaselineIntegrity' {
        BeforeEach {
            $integrityTestRoot = Join-Path $solutionRoot ('artifacts\test-integrity\{0}' -f [guid]::NewGuid().Guid)
            $null = New-Item -ItemType Directory -Path $integrityTestRoot -Force
            $baselineUnderTest = Join-Path $integrityTestRoot 'feature-state-baseline.json'
            '{"features":[{"featureId":"test-feature","displayName":"Test Feature","expectedEnabled":true,"expectedRing":"General Availability"}]}' | Set-Content -Path $baselineUnderTest -Encoding utf8
        }

        AfterEach {
            if (Test-Path -Path $integrityTestRoot) {
                Remove-Item -Path $integrityTestRoot -Recurse -Force
            }
        }

        It 'accepts a matching SHA-256 companion file' {
            $hash = (Get-FileHash -Path $baselineUnderTest -Algorithm SHA256).Hash
            "$hash  $baselineUnderTest" | Set-Content -Path "${baselineUnderTest}.sha256" -Encoding utf8

            { Test-BaselineIntegrity -BaselinePath $baselineUnderTest } | Should -Not -Throw
        }

        It 'throws on a mismatched SHA-256 companion file' {
            $mismatchedHash = '0' * 64
            "$mismatchedHash  $baselineUnderTest" | Set-Content -Path "${baselineUnderTest}.sha256" -Encoding utf8

            { Test-BaselineIntegrity -BaselinePath $baselineUnderTest } | Should -Throw '*SHA-256 hash mismatch*'
        }

        It 'allows monitoring to continue when the SHA-256 companion file is missing' {
            { Test-BaselineIntegrity -BaselinePath $baselineUnderTest -WarningAction SilentlyContinue } | Should -Not -Throw
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
                $script:exportScript, [ref]$tokens, [ref]$errors) | Out-Null
            $errors | Should -BeNullOrEmpty
        }
    }
}

Describe 'FMC evidence portability and honesty' {
    BeforeAll {
        $script:solutionRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
        $script:repoRoot = (Resolve-Path (Join-Path $script:solutionRoot '..\..')).Path
        $script:exportScriptPath = Join-Path $script:solutionRoot 'scripts\Export-Evidence.ps1'
        Import-Module (Join-Path $script:repoRoot 'scripts\common\EvidenceExport.psm1') -Force
    }

    It 'stores package-relative paths, returns absolute paths, reports partial-only controls, and validates after relocation' {
        $outputPath = Join-Path $TestDrive 'portable-evidence'
        $result = & $script:exportScriptPath -ConfigurationTier regulated -OutputPath $outputPath

        [System.IO.Path]::IsPathRooted($result.Package.Path) | Should -BeTrue
        foreach ($artifact in @($result.Artifacts)) {
            [System.IO.Path]::IsPathRooted($artifact.path) | Should -BeTrue
        }

        $package = Get-Content -Path $result.Package.Path -Raw | ConvertFrom-Json
        foreach ($artifact in @($package.artifacts)) {
            [System.IO.Path]::IsPathRooted($artifact.path) | Should -BeFalse
        }
        @($package.controls | Where-Object { $_.status -eq 'implemented' }).Count | Should -Be 0
        $package.metadata.runtimeMode | Should -Be 'documentation-first'
        $package.metadata.dataSourceMode | Should -Be 'representative-sample'

        $relocatedPath = Join-Path $TestDrive 'portable-evidence-relocated'
        Move-Item -Path $outputPath -Destination $relocatedPath
        $validation = Test-CopilotGovEvidencePackage `
            -Path (Join-Path $relocatedPath '09-feature-management-controller-evidence.json') `
            -ExpectedArtifacts @('feature-state-baseline', 'rollout-ring-history', 'drift-findings')
        $validation.IsValid | Should -BeTrue -Because ($validation.Errors -join '; ')
    }

    It 'resolves relative output from the PowerShell provider location' {
        $originalProcessDirectory = [System.Environment]::CurrentDirectory
        Push-Location $TestDrive
        try {
            [System.Environment]::CurrentDirectory = $script:solutionRoot
            $result = & $script:exportScriptPath -ConfigurationTier baseline -OutputPath '.\provider-relative'
            (Split-Path -Parent $result.Package.Path) | Should -Be (Join-Path $TestDrive 'provider-relative')
        }
        finally {
            [System.Environment]::CurrentDirectory = $originalProcessDirectory
            Pop-Location
        }
    }
}

Describe 'FMC documentation currency' {
    BeforeAll {
        $script:solutionRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
        $script:readme = Get-Content -Path (Join-Path $script:solutionRoot 'README.md') -Raw
        $script:architecture = Get-Content -Path (Join-Path $script:solutionRoot 'docs\architecture.md') -Raw
        $script:prerequisites = Get-Content -Path (Join-Path $script:solutionRoot 'docs\prerequisites.md') -Raw
        $script:defaultConfig = Get-Content -Path (Join-Path $script:solutionRoot 'config\default-config.json') -Raw | ConvertFrom-Json
    }

    It 'documents the Teams meeting and calling Copilot policy cmdlets' {
        $script:architecture | Should -Match 'Set-CsTeamsMeetingPolicy -Copilot'
        $script:architecture | Should -Match 'Set-CsTeamsCallingPolicy -Copilot'
        $script:prerequisites | Should -Match 'Get-CsTeamsMeetingPolicy'
        $script:prerequisites | Should -Match 'Get-CsTeamsCallingPolicy'
    }

    It 'distinguishes the Cloud Policy web-search toggle from the Purview DLP web-search action' {
        $script:architecture | Should -Match 'Allow web search in Copilot'
        $script:architecture | Should -Match 'Performing Web Searches'
        $script:defaultConfig.webGroundingGovernance.purviewDlpWebSearchBoundary.action | Should -Match 'Performing Web Searches'
    }

    It 'documents the Microsoft Agent 365 and Entra Agent ID boundary' {
        $script:readme | Should -Match 'Microsoft Agent 365'
        $script:readme | Should -Match 'Entra Agent ID'
    }

    It 'does not configure a Copilot feature-management Graph endpoint' {
        $null -eq $script:defaultConfig.graph.endpoint | Should -BeTrue
        $solutionRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
        foreach ($scriptName in @('Deploy-Solution.ps1', 'Monitor-Compliance.ps1', 'Export-Evidence.ps1')) {
            $content = Get-Content -Path (Join-Path $solutionRoot "scripts\$scriptName") -Raw
            $content | Should -Not -Match 'graph\.microsoft\.com/[^ ]*copilot'
        }
    }
}
