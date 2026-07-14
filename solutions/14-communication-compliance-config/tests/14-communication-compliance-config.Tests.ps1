Describe 'Microsoft Purview Communication Compliance Configurator' {
    BeforeAll {
        $solutionRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
        $script:requiredFiles = @(
            'README.md',
            'CHANGELOG.md',
            'DELIVERY-CHECKLIST.md',
            'docs\architecture.md',
            'docs\deployment-guide.md',
            'docs\evidence-export.md',
            'docs\prerequisites.md',
            'docs\troubleshooting.md',
            'scripts\CCC-Common.psm1',
            'scripts\Deploy-Solution.ps1',
            'scripts\Monitor-Compliance.ps1',
            'scripts\Export-Evidence.ps1',
            'config\default-config.json',
            'config\baseline.json',
            'config\recommended.json',
            'config\regulated.json',
            'tests\14-communication-compliance-config.Tests.ps1'
        ) | ForEach-Object { Join-Path $solutionRoot $_ }

        $script:defaultConfig = (Get-Content -Path (Join-Path $solutionRoot 'config\default-config.json') -Raw) | ConvertFrom-Json
        $script:baselineConfig = (Get-Content -Path (Join-Path $solutionRoot 'config\baseline.json') -Raw) | ConvertFrom-Json
        $script:recommendedConfig = (Get-Content -Path (Join-Path $solutionRoot 'config\recommended.json') -Raw) | ConvertFrom-Json
        $script:regulatedConfig = (Get-Content -Path (Join-Path $solutionRoot 'config\regulated.json') -Raw) | ConvertFrom-Json
        $script:readmeContent = Get-Content -Path (Join-Path $solutionRoot 'README.md') -Raw
        $script:evidenceDocContent = Get-Content -Path (Join-Path $solutionRoot 'docs\evidence-export.md') -Raw
        $script:prerequisitesContent = Get-Content -Path (Join-Path $solutionRoot 'docs\prerequisites.md') -Raw
        $script:architectureContent = Get-Content -Path (Join-Path $solutionRoot 'docs\architecture.md') -Raw
        $script:deploymentContent = Get-Content -Path (Join-Path $solutionRoot 'docs\deployment-guide.md') -Raw
        $script:scriptFiles = @(
            (Join-Path $solutionRoot 'scripts\Deploy-Solution.ps1'),
            (Join-Path $solutionRoot 'scripts\Monitor-Compliance.ps1'),
            (Join-Path $solutionRoot 'scripts\Export-Evidence.ps1'),
            (Join-Path $solutionRoot 'scripts\CCC-Common.psm1')
        )
        $script:deployScript = Join-Path $solutionRoot 'scripts\Deploy-Solution.ps1'
        $script:monitorScript = Join-Path $solutionRoot 'scripts\Monitor-Compliance.ps1'
        $script:exportScript = Join-Path $solutionRoot 'scripts\Export-Evidence.ps1'
        $script:testArtifactRoot = Join-Path $solutionRoot 'artifacts\pester-tests'
    }

    Context 'File presence' {
        It 'contains all required solution files' {
            foreach ($file in $script:requiredFiles) {
                Test-Path -Path $file | Should -BeTrue -Because "$file should exist."
            }
        }
    }

    Context 'Configuration validation' {
        It 'uses the correct solution slug, code, and controls' {
            $script:defaultConfig.solution | Should -Be '14-communication-compliance-config'
            $script:defaultConfig.solutionCode | Should -Be 'CCC'
            @($script:defaultConfig.controls) | Should -Contain '2.10'
            @($script:defaultConfig.controls) | Should -Contain '3.4'
            @($script:defaultConfig.controls) | Should -Contain '3.5'
            @($script:defaultConfig.controls) | Should -Contain '3.6'
            @($script:defaultConfig.controls) | Should -Contain '3.9'
        }

        It 'defines policy templates in each tier' {
            @($script:baselineConfig.policyTemplates).Count | Should -BeGreaterThan 0
            @($script:recommendedConfig.policyTemplates).Count | Should -BeGreaterThan 0
            @($script:regulatedConfig.policyTemplates).Count | Should -BeGreaterThan 0
        }

        It 'enables FINRA 3110 supervision in the regulated tier' {
            $script:regulatedConfig.finra3110SupervisionEnabled | Should -BeTrue
        }
    }

    Context 'Script syntax validation' {
        It 'parses all solution scripts without syntax errors' {
            foreach ($scriptFile in $script:scriptFiles) {
                $tokens = $null
                $errors = $null
                [System.Management.Automation.Language.Parser]::ParseFile($scriptFile, [ref]$tokens, [ref]$errors) > $null
                $errors.Count | Should -Be 0 -Because "$scriptFile should parse without syntax errors."
            }
        }

        It 'includes comment-based help in each script' {
            foreach ($scriptFile in $script:scriptFiles) {
                $content = Get-Content -Path $scriptFile -Raw
                $content | Should -Match '\.SYNOPSIS'
                $content | Should -Match '\.DESCRIPTION'
                if ($scriptFile -like '*.ps1') {
                    $content | Should -Match '\.PARAMETER'
                }
            }
        }
    }

    Context 'Documentation validation' {
        It 'references FINRA 3110 in the README' {
            $script:readmeContent | Should -Match 'FINRA 3110'
        }

        It 'references reviewer-queue-metrics in the evidence export guide' {
            $script:evidenceDocContent | Should -Match 'reviewer-queue-metrics'
        }

        It 'documents the Security & Compliance PowerShell SupervisoryReview surface and its Copilot limitation' {
            $script:prerequisitesContent | Should -Match 'SupervisoryReviewPolicyV2'
            $script:prerequisitesContent | Should -Match 'SupervisoryReviewRule'
            $script:prerequisitesContent | Should -Match 'Copilot detection location'
        }

        It 'documents the pay-as-you-go boundary for non-Microsoft 365 AI data' {
            $script:prerequisitesContent | Should -Match 'pay-as-you-go'
            $script:prerequisitesContent | Should -Match 'no pay-as-you-go billing requirement'
        }

        It 'does not overstate Communication Compliance policy publication as portal-only' {
            $script:readmeContent | Should -Not -Match 'still requires manual portal actions'
            $script:architectureContent | Should -Not -Match 'publication still requires manual steps'
        }

        It 'references the current Detect Microsoft Copilot interactions template in the deployment guide' {
            $script:deploymentContent | Should -Match 'Detect Microsoft Copilot interactions'
        }
    }

    Context 'Script output contracts' {
        BeforeAll {
            if (Test-Path -Path $script:testArtifactRoot) {
                Remove-Item -Path $script:testArtifactRoot -Recurse -Force
            }
            $null = New-Item -ItemType Directory -Path $script:testArtifactRoot -Force
        }

        It 'returns the expected deployment output schema and tier progression' {
            $results = @{}
            foreach ($tier in @('baseline', 'recommended', 'regulated')) {
                $results[$tier] = & $script:deployScript -ConfigurationTier $tier -OutputPath (Join-Path $script:testArtifactRoot "deploy-$tier") -TenantId '' -WhatIf
            }

            $expectedProperties = @(
                'Solution',
                'SolutionCode',
                'Tier',
                'TierLabel',
                'TierValue',
                'TenantId',
                'PolicyTemplateCount',
                'ReviewerSlaHours',
                'SamplingRate',
                'PolicyTemplatePath',
                'ManifestPath',
                'ManualPortalDeploymentRequired',
                'AllCopilotContentMonitored',
                'Dependency'
            )

            foreach ($tier in $results.Keys) {
                foreach ($property in $expectedProperties) {
                    $results[$tier].PSObject.Properties.Name | Should -Contain $property
                }
            }

            ($results['baseline'].PolicyTemplateCount -lt $results['recommended'].PolicyTemplateCount) | Should -BeTrue
            ($results['recommended'].PolicyTemplateCount -lt $results['regulated'].PolicyTemplateCount) | Should -BeTrue
            ($results['baseline'].ReviewerSlaHours -gt $results['recommended'].ReviewerSlaHours) | Should -BeTrue
            ($results['recommended'].ReviewerSlaHours -gt $results['regulated'].ReviewerSlaHours) | Should -BeTrue
            ($results['baseline'].SamplingRate -lt $results['recommended'].SamplingRate) | Should -BeTrue
            ($results['recommended'].SamplingRate -lt $results['regulated'].SamplingRate) | Should -BeTrue
            $results['regulated'].AllCopilotContentMonitored | Should -BeTrue
        }

        It 'returns the expected monitoring output schema and applies queue thresholds' {
            $outputPath = Join-Path $script:testArtifactRoot 'monitor-regulated'
            $emptySecret = [System.Security.SecureString]::new()
            $result = & $script:monitorScript -ConfigurationTier regulated -OutputPath $outputPath -TenantId '' -ClientId '' -ClientSecret $emptySecret -PassThru

            foreach ($property in @('solution', 'solutionCode', 'displayName', 'tier', 'tierLabel', 'generatedAt', 'overallStatus', 'statusScore', 'queueMetrics', 'policyCoverage', 'lexiconStatus')) {
                $result.PSObject.Properties.Name | Should -Contain $property
            }

            foreach ($property in @('snapshotDate', 'totalPending', 'avgAgeHours', 'p90AgeHours', 'dispositionBreakdown', 'escalatedCount', 'overdueCount', 'reviewerSlaHours', 'queueHealthThresholds', 'queueHealthEvaluation', 'queueHealthy', 'collectionMethod', 'tenantId', 'clientId', 'credentialSupplied', 'notes')) {
                $result.queueMetrics.PSObject.Properties.Name | Should -Contain $property
            }

            $result.queueMetrics.queueHealthThresholds.maxAverageAgeHours | Should -Be 24
            $result.queueMetrics.queueHealthThresholds.maxP90AgeHours | Should -Be 72
            $result.queueMetrics.queueHealthThresholds.maxOverdueCount | Should -Be 5
            $result.queueMetrics.queueHealthEvaluation.averageAgeWithinThreshold | Should -BeTrue
            $result.queueMetrics.credentialSupplied | Should -BeFalse
            Test-Path -Path (Join-Path $outputPath 'communication-compliance-status.json') | Should -BeTrue
        }

        It 'returns the expected evidence output schema and lexicon artifact fields' {
            $outputPath = Join-Path $script:testArtifactRoot 'evidence-baseline'
            $result = & $script:exportScript -ConfigurationTier baseline -OutputPath $outputPath -PeriodStart ([datetime]'2026-05-01T00:00:00Z') -PeriodEnd ([datetime]'2026-05-23T00:00:00Z') -PassThru

            foreach ($property in @('Solution', 'SolutionCode', 'Tier', 'TierLabel', 'OverallStatus', 'OverallStatusScore', 'PeriodStart', 'PeriodEnd', 'ArtifactCount', 'PackagePath', 'PackageHash')) {
                $result.PSObject.Properties.Name | Should -Contain $property
            }

            $result.ArtifactCount | Should -Be 3
            Test-Path -Path $result.PackagePath | Should -BeTrue
            foreach ($artifact in @($result.Artifacts)) {
                [System.IO.Path]::IsPathRooted($artifact.path) | Should -BeTrue
            }
            $lexiconLogPath = Join-Path $outputPath 'artifact-data\lexicon-update-log.json'
            $lexiconLog = Get-Content -Path $lexiconLogPath -Raw | ConvertFrom-Json
            $lexiconLog.PSObject.Properties.Name | Should -Contain 'wordAdded'
            $lexiconLog.PSObject.Properties.Name | Should -Contain 'wordRemoved'
            @($lexiconLog.wordAdded).Count | Should -BeGreaterThan 0
            @($lexiconLog.wordRemoved).Count | Should -BeGreaterThan 0
        }

        It 'writes package-relative artifact paths for relocation safety' {
            $outputPath = Join-Path $script:testArtifactRoot 'evidence-portable'
            $result = & $script:exportScript -ConfigurationTier recommended -OutputPath $outputPath -PassThru
            $packageDirectory = Split-Path -Path $result.PackagePath -Parent
            $package = Get-Content -Path $result.PackagePath -Raw | ConvertFrom-Json

            foreach ($artifact in $package.artifacts) {
                [System.IO.Path]::IsPathRooted($artifact.path) | Should -BeFalse -Because 'package artifact paths should be relative for relocation safety'
                $artifact.path | Should -Match '^artifact-data/'
                Test-Path -Path (Join-Path $packageDirectory $artifact.path) | Should -BeTrue
            }

            $relocatedPath = Join-Path $script:testArtifactRoot 'evidence-portable-relocated'
            Move-Item -Path $outputPath -Destination $relocatedPath
            $repoRoot = (Resolve-Path (Join-Path $solutionRoot '..\..')).Path
            Import-Module (Join-Path $repoRoot 'scripts\common\EvidenceExport.psm1') -Force
            $validation = Test-CopilotGovEvidencePackage `
                -Path (Join-Path $relocatedPath '14-communication-compliance-config-evidence.json') `
                -ExpectedArtifacts @('policy-template-export', 'reviewer-queue-metrics', 'lexicon-update-log')
            $validation.IsValid | Should -BeTrue -Because ($validation.Errors -join '; ')
        }

        AfterAll {
            if (Test-Path -Path $script:testArtifactRoot) {
                Remove-Item -Path $script:testArtifactRoot -Recurse -Force
            }
        }
    }

    Context 'CCC-Common module functional tests' {
        BeforeAll {
            Import-Module (Join-Path $solutionRoot 'scripts\CCC-Common.psm1') -Force
        }

        It 'ConvertTo-Hashtable returns null for null input' {
            $result = ConvertTo-Hashtable -InputObject $null
            $result | Should -BeNullOrEmpty
        }

        It 'ConvertTo-Hashtable converts PSCustomObject to hashtable' {
            $obj = [pscustomobject]@{ Name = 'Test'; Value = 42 }
            $result = ConvertTo-Hashtable -InputObject $obj
            $result | Should -BeOfType [hashtable]
            $result['Name'] | Should -Be 'Test'
            $result['Value'] | Should -Be 42
        }

        It 'ConvertTo-Hashtable converts nested objects recursively' {
            $obj = [pscustomobject]@{
                Outer = [pscustomobject]@{ Inner = 'deep' }
            }
            $result = ConvertTo-Hashtable -InputObject $obj
            $result['Outer'] | Should -BeOfType [hashtable]
            $result['Outer']['Inner'] | Should -Be 'deep'
        }

        It 'ConvertTo-Hashtable preserves string values without wrapping' {
            $result = ConvertTo-Hashtable -InputObject 'plain string'
            $result | Should -Be 'plain string'
        }

        It 'ConvertTo-Hashtable converts arrays of objects' {
            $arr = @(
                [pscustomobject]@{ Id = 1 },
                [pscustomobject]@{ Id = 2 }
            )
            $result = ConvertTo-Hashtable -InputObject $arr
            $result.Count | Should -Be 2
            $result[0]['Id'] | Should -Be 1
            $result[1]['Id'] | Should -Be 2
        }

        It 'Merge-Hashtable overlays keys onto base' {
            $base = @{ A = 1; B = 2 }
            $overlay = @{ B = 99; C = 3 }
            $result = Merge-Hashtable -Base $base -Overlay $overlay
            $result['A'] | Should -Be 1
            $result['B'] | Should -Be 99
            $result['C'] | Should -Be 3
        }

        It 'Merge-Hashtable merges nested hashtables recursively' {
            $base = @{ Nested = @{ X = 1; Y = 2 } }
            $overlay = @{ Nested = @{ Y = 99; Z = 3 } }
            $result = Merge-Hashtable -Base $base -Overlay $overlay
            $result['Nested']['X'] | Should -Be 1
            $result['Nested']['Y'] | Should -Be 99
            $result['Nested']['Z'] | Should -Be 3
        }

        It 'Get-SolutionConfiguration loads and merges tier configs' {
            $configRoot = Join-Path $solutionRoot 'config'
            $result = Get-SolutionConfiguration -ConfigRoot $configRoot -Tier 'baseline'
            $result | Should -BeOfType [hashtable]
            $result['solutionCode'] | Should -Be 'CCC'
            $result['tier'] | Should -Be 'baseline'
        }

        It 'Get-SolutionConfiguration throws for missing config root' {
            { Get-SolutionConfiguration -ConfigRoot 'C:\nonexistent\path' -Tier 'baseline' } | Should -Throw
        }

        It 'Get-PolicyCatalogDefinition returns expected template keys' {
            $configRoot = Join-Path $solutionRoot 'config'
            $config = Get-SolutionConfiguration -ConfigRoot $configRoot -Tier 'regulated'
            $catalog = Get-PolicyCatalogDefinition -Config $config
            $catalog | Should -BeOfType [hashtable]
            $catalog.ContainsKey('CopilotAIDisclosure') | Should -BeTrue
            $catalog.ContainsKey('FinancialAdviceReview') | Should -BeTrue
            $catalog.ContainsKey('DualReviewSupervision') | Should -BeTrue
        }

        AfterAll {
            Remove-Module CCC-Common -ErrorAction SilentlyContinue
        }
    }
}
