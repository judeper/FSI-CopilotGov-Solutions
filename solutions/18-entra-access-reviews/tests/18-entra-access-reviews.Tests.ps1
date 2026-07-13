Describe 'Solution structure' {
    It 'includes required solution files' {
        $solutionRoot = Join-Path $PSScriptRoot '..'
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
            'config\review-schedule.json',
            'config\reviewer-mapping.json',
            'lab\18-entra-access-reviews.lab.json',
            'scripts\Deploy-Solution.ps1',
            'scripts\Monitor-Compliance.ps1',
            'scripts\Export-Evidence.ps1',
            'scripts\New-AccessReview.ps1',
            'scripts\Get-ReviewResults.ps1',
            'scripts\Apply-ReviewDecisions.ps1',
            'scripts\Invoke-RiskTriagedReviews.ps1',
            'tests\18-entra-access-reviews.Tests.ps1'
        )

        foreach ($relativePath in $requiredPaths) {
            Test-Path -Path (Join-Path $solutionRoot $relativePath) | Should -BeTrue
        }
    }
}

Describe 'Configuration content' {
    BeforeAll {
        $solutionRoot = Join-Path $PSScriptRoot '..'
        $script:expectedControls = @('1.2', '1.6', '2.5', '2.12')
        $script:defaultConfig = (Get-Content -Path (Join-Path $solutionRoot 'config\default-config.json') -Raw) | ConvertFrom-Json
        $script:baselineConfig = (Get-Content -Path (Join-Path $solutionRoot 'config\baseline.json') -Raw) | ConvertFrom-Json
        $script:recommendedConfig = (Get-Content -Path (Join-Path $solutionRoot 'config\recommended.json') -Raw) | ConvertFrom-Json
        $script:regulatedConfig = (Get-Content -Path (Join-Path $solutionRoot 'config\regulated.json') -Raw) | ConvertFrom-Json
        $script:reviewSchedule = (Get-Content -Path (Join-Path $solutionRoot 'config\review-schedule.json') -Raw) | ConvertFrom-Json
        $script:reviewerMapping = (Get-Content -Path (Join-Path $solutionRoot 'config\reviewer-mapping.json') -Raw) | ConvertFrom-Json
    }

    It 'includes evidenceOutputs and upstreamDependency in default config' {
        @($script:defaultConfig.evidenceOutputs).Count | Should -BeGreaterThan 0
        $script:defaultConfig.upstreamDependency | Should -Be '02-oversharing-risk-assessment'
    }

    It 'uses longer retention in the regulated tier' {
        [int]$script:regulatedConfig.evidenceRetentionDays | Should -BeGreaterThan ([int]$script:recommendedConfig.evidenceRetentionDays)
        [int]$script:recommendedConfig.evidenceRetentionDays | Should -BeGreaterThan ([int]$script:baselineConfig.evidenceRetentionDays)
    }

    It 'keeps the control mapping consistent across configs' {
        (@($script:defaultConfig.controls) -join ',') | Should -Be ($script:expectedControls -join ',')
        (@($script:baselineConfig.controls) -join ',') | Should -Be ($script:expectedControls -join ',')
        (@($script:recommendedConfig.controls) -join ',') | Should -Be ($script:expectedControls -join ',')
        (@($script:regulatedConfig.controls) -join ',') | Should -Be ($script:expectedControls -join ',')
    }

    It 'defines review cadence for all risk tiers' {
        $script:reviewSchedule.reviewCadence.HIGH.frequencyDays | Should -BeGreaterThan 0
        $script:reviewSchedule.reviewCadence.MEDIUM.frequencyDays | Should -BeGreaterThan 0
        $script:reviewSchedule.reviewCadence.LOW.frequencyDays | Should -BeGreaterThan 0
        $script:reviewSchedule.reviewCadence.HIGH.frequencyMonths | Should -Be 1
        $script:reviewSchedule.reviewCadence.MEDIUM.frequencyMonths | Should -Be 3
        $script:reviewSchedule.reviewCadence.LOW.frequencyMonths | Should -Be 6
    }

    It 'keeps regulated escalation threshold at 24 hours' {
        [int]$script:regulatedConfig.escalationThresholdHours | Should -Be 24
    }

    It 'defines escalation chain in reviewer mapping' {
        @($script:reviewerMapping.escalationChain).Count | Should -BeGreaterThan 0
    }

    It 'includes all evidence outputs in tier configs' {
        @($script:baselineConfig.evidenceOutputs) | Should -Contain 'access-review-definitions'
        @($script:baselineConfig.evidenceOutputs) | Should -Contain 'review-decisions'
        @($script:baselineConfig.evidenceOutputs) | Should -Contain 'applied-actions'
    }
}

Describe 'Script syntax validation' {
    It 'parses all solution scripts without syntax errors' {
        $solutionRoot = Join-Path $PSScriptRoot '..'
        $scriptPaths = @(
            (Join-Path $solutionRoot 'scripts\Deploy-Solution.ps1'),
            (Join-Path $solutionRoot 'scripts\Monitor-Compliance.ps1'),
            (Join-Path $solutionRoot 'scripts\Export-Evidence.ps1'),
            (Join-Path $solutionRoot 'scripts\New-AccessReview.ps1'),
            (Join-Path $solutionRoot 'scripts\Get-ReviewResults.ps1'),
            (Join-Path $solutionRoot 'scripts\Apply-ReviewDecisions.ps1'),
            (Join-Path $solutionRoot 'scripts\Invoke-RiskTriagedReviews.ps1')
        )

        foreach ($scriptPath in $scriptPaths) {
            $tokens = $null
            $errors = $null
            $ast = [System.Management.Automation.Language.Parser]::ParseFile($scriptPath, [ref]$tokens, [ref]$errors)

            $ast | Should -Not -BeNullOrEmpty
            @($errors).Count | Should -Be 0
        }
    }
}

Describe 'Dependency declaration' {
    It 'references 02-oversharing-risk-assessment in the deployment guide' {
        $deploymentGuide = Get-Content -Path (Join-Path (Join-Path $PSScriptRoot '..') 'docs\deployment-guide.md') -Raw
        $deploymentGuide | Should -Match '02-oversharing-risk-assessment'
    }
}

Describe 'Evidence types' {
    It 'documents all expected evidence outputs' {
        $evidenceDoc = Get-Content -Path (Join-Path (Join-Path $PSScriptRoot '..') 'docs\evidence-export.md') -Raw
        $evidenceDoc | Should -Match 'access-review-definitions'
        $evidenceDoc | Should -Match 'review-decisions'
        $evidenceDoc | Should -Match 'applied-actions'
    }
}

Describe 'Script behavior contracts' {
    BeforeAll {
        $script:solutionRoot = Join-Path $PSScriptRoot '..'
        $script:testArtifactRoot = Join-Path $script:solutionRoot 'artifacts\test-output'
        if (Test-Path -Path $script:testArtifactRoot) {
            Remove-Item -Path $script:testArtifactRoot -Recurse -Force
        }
        $null = New-Item -ItemType Directory -Path $script:testArtifactRoot -Force

        $script:newReviewScript = Join-Path $script:solutionRoot 'scripts\New-AccessReview.ps1'
        $script:getResultsScript = Join-Path $script:solutionRoot 'scripts\Get-ReviewResults.ps1'
        $script:applyScript = Join-Path $script:solutionRoot 'scripts\Apply-ReviewDecisions.ps1'
        $script:invokeScript = Join-Path $script:solutionRoot 'scripts\Invoke-RiskTriagedReviews.ps1'
        $script:deployScript = Join-Path $script:solutionRoot 'scripts\Deploy-Solution.ps1'
        $script:monitorScript = Join-Path $script:solutionRoot 'scripts\Monitor-Compliance.ps1'
        $script:exportScript = Join-Path $script:solutionRoot 'scripts\Export-Evidence.ps1'
    }

    AfterAll {
        if (Test-Path -Path $script:testArtifactRoot) {
            Remove-Item -Path $script:testArtifactRoot -Recurse -Force
        }
    }

    It 'returns truthful dependency status without throwing in Deploy-Solution WhatIf mode' {
        $result = & $script:deployScript -ConfigurationTier baseline -TenantId '00000000-0000-0000-0000-000000000000' -OutputPath (Join-Path $script:testArtifactRoot 'deploy') -WhatIf
        $result.DependencyStatus | Should -BeIn @('not-found', 'empty', 'validated')
    }

    It 'uses tier configuration as authoritative source for auto-apply in New-AccessReview' {
        $baselineOutput = Join-Path $script:testArtifactRoot 'new-review-baseline'
        $recommendedOutput = Join-Path $script:testArtifactRoot 'new-review-recommended'

        $baselineResult = & $script:newReviewScript -TenantId '00000000-0000-0000-0000-000000000000' -ConfigurationTier baseline -OutputPath $baselineOutput
        $recommendedResult = & $script:newReviewScript -TenantId '00000000-0000-0000-0000-000000000000' -ConfigurationTier recommended -OutputPath $recommendedOutput

        $baselineResult.AutoApplyDecisions | Should -BeFalse
        $recommendedResult.AutoApplyDecisions | Should -BeTrue

        $recommendedDefinitions = @(Get-Content -Path (Join-Path $recommendedOutput 'access-review-definitions.json') -Raw | ConvertFrom-Json)
        @($recommendedDefinitions | Where-Object { $_.autoApplyDecisionsEnabled -eq $true }).Count | Should -BeGreaterThan 0
    }

    It 'omits invalid defaultDecision None in New-AccessReview settings payload' {
        (Get-Content -Path $script:newReviewScript -Raw) | Should -Not -Match "defaultDecision\s*=\s*'None'"
    }

    It 'honors escalation enablement and tier thresholds in Get-ReviewResults' {
        $baselineResult = & $script:getResultsScript -TenantId '00000000-0000-0000-0000-000000000000' -ConfigurationTier baseline -OutputPath (Join-Path $script:testArtifactRoot 'results-baseline')
        $recommendedResult = & $script:getResultsScript -TenantId '00000000-0000-0000-0000-000000000000' -ConfigurationTier recommended -OutputPath (Join-Path $script:testArtifactRoot 'results-recommended')
        $regulatedResult = & $script:getResultsScript -TenantId '00000000-0000-0000-0000-000000000000' -ConfigurationTier regulated -OutputPath (Join-Path $script:testArtifactRoot 'results-regulated')
        $overrideResult = & $script:getResultsScript -TenantId '00000000-0000-0000-0000-000000000000' -ConfigurationTier recommended -EscalationThresholdHours 24 -OutputPath (Join-Path $script:testArtifactRoot 'results-override')

        $baselineResult.EscalationEnabled | Should -BeFalse
        $baselineResult.EscalationAlerts | Should -Be 0

        $recommendedResult.EscalationEnabled | Should -BeTrue
        $recommendedResult.EscalationThresholdHours | Should -Be 48
        $recommendedResult.EscalationAlerts | Should -BeGreaterThan 0

        $regulatedResult.EscalationThresholdHours | Should -Be 24
        $regulatedResult.EscalationAlerts | Should -Be 0

        $overrideResult.EscalationThresholdHours | Should -Be 24
        $overrideResult.EscalationAlerts | Should -Be 0
    }

    It 'keeps review decision output shape stable for siteUrl and riskTier fields' {
        $resultPath = Join-Path $script:testArtifactRoot 'results-shape'
        $null = & $script:getResultsScript -TenantId '00000000-0000-0000-0000-000000000000' -ConfigurationTier recommended -OutputPath $resultPath
        $decisions = @(Get-Content -Path (Join-Path $resultPath 'review-decisions.json') -Raw | ConvertFrom-Json)

        @($decisions | Where-Object { [string]::IsNullOrWhiteSpace([string]$_.siteUrl) }).Count | Should -Be 0
        @($decisions | Where-Object { [string]::IsNullOrWhiteSpace([string]$_.riskTier) }).Count | Should -Be 0
    }

    It 'removes Recommendation decision mapping and filters applyDecisions to completed instances in script logic' {
        $applyScriptContent = Get-Content -Path $script:applyScript -Raw
        $applyScriptContent | Should -Not -Match "'Recommendation'"
        $applyScriptContent | Should -Match 'Skipping instance'
        $applyScriptContent | Should -Match 'is not Completed\.'
    }

    It 'supports WhatIf orchestration without interactive confirmations' {
        $invokeResult = & $script:invokeScript -TenantId '00000000-0000-0000-0000-000000000000' -ConfigurationTier recommended -OutputPath (Join-Path $script:testArtifactRoot 'invoke-whatif') -WhatIf
        $invokeResult.SummaryPath | Should -Not -BeNullOrEmpty
        (Get-Content -Path $script:invokeScript -Raw) | Should -Match 'SupportsShouldProcess = \$true'
    }

    It 'exports evidence from the current orchestrator output path' {
        $orchestratorOutput = Join-Path $script:testArtifactRoot 'invoke-custom-output'
        $null = & $script:invokeScript `
            -TenantId '00000000-0000-0000-0000-000000000000' `
            -ConfigurationTier recommended `
            -OutputPath $orchestratorOutput `
            -Confirm:$false

        $packagePath = Join-Path $orchestratorOutput 'evidence\18-entra-access-reviews-evidence-package.json'
        Test-Path -Path $packagePath | Should -BeTrue

        $package = Get-Content -Path $packagePath -Raw | ConvertFrom-Json
        $package.metadata.dataSource | Should -Be 'emitted-artifacts'
        $resolvedOrchestratorOutput = [System.IO.Path]::GetFullPath($orchestratorOutput)
        $package.metadata.dataSourceNotes | Should -Match ([regex]::Escape($resolvedOrchestratorOutput))
    }

    It 'uses emitted review artifacts for Monitor-Compliance when available' {
        $artifactPath = Join-Path $script:testArtifactRoot 'monitor-artifacts'
        $null = New-Item -ItemType Directory -Path $artifactPath -Force
        @(
            [pscustomobject]@{
                reviewDefinitionId = 'ear-site-100-review'
                siteUrl = 'https://contoso.sharepoint.com/sites/Sample'
                riskTier = 'HIGH'
                reviewer = 'sample-owner@contoso.com'
            }
        ) | ConvertTo-Json -Depth 10 | Set-Content -Path (Join-Path $artifactPath 'access-review-definitions.json') -Encoding utf8
        @(
            [pscustomobject]@{
                reviewDefinitionId = 'ear-site-100-review'
                instanceId = 'instance-100'
                decisionId = 'decision-100'
                decision = 'Approve'
                status = 'completed'
                reviewedAt = (Get-Date).AddDays(-1).ToString('o')
                instanceEndDateTime = (Get-Date).AddDays(5).ToString('o')
                siteUrl = 'https://contoso.sharepoint.com/sites/Sample'
                riskTier = 'HIGH'
            }
        ) | ConvertTo-Json -Depth 10 | Set-Content -Path (Join-Path $artifactPath 'review-decisions.json') -Encoding utf8

        $monitorOutput = Join-Path $script:testArtifactRoot 'monitor-output'
        $null = & $script:monitorScript -ConfigurationTier recommended -TenantId '00000000-0000-0000-0000-000000000000' -ReviewArtifactsPath $artifactPath -ExportPath $monitorOutput
        $monitorSummary = Get-Content -Path (Join-Path $monitorOutput 'compliance-status.json') -Raw | ConvertFrom-Json
        $monitorSummary.dataSource | Should -Be 'emitted-artifacts'
    }

    It 'writes relative artifact paths in evidence package while returning an absolute PackagePath' {
        $artifactPath = Join-Path $script:testArtifactRoot 'evidence-artifacts'
        $null = New-Item -ItemType Directory -Path $artifactPath -Force
        @(
            [pscustomobject]@{
                reviewDefinitionId = 'ear-site-200-review'
                siteUrl = 'https://contoso.sharepoint.com/sites/AnotherSample'
                riskTier = 'MEDIUM'
                reviewer = 'owner@contoso.com'
            }
        ) | ConvertTo-Json -Depth 10 | Set-Content -Path (Join-Path $artifactPath 'access-review-definitions.json') -Encoding utf8
        @(
            [pscustomobject]@{
                reviewDefinitionId = 'ear-site-200-review'
                instanceId = 'instance-200'
                decisionId = 'decision-200'
                decision = 'NotReviewed'
                status = 'pending'
                siteUrl = 'https://contoso.sharepoint.com/sites/AnotherSample'
                riskTier = 'MEDIUM'
            }
        ) | ConvertTo-Json -Depth 10 | Set-Content -Path (Join-Path $artifactPath 'review-decisions.json') -Encoding utf8
        @() | ConvertTo-Json -Depth 10 | Set-Content -Path (Join-Path $artifactPath 'applied-actions.json') -Encoding utf8

        $evidenceOutput = Join-Path $script:testArtifactRoot 'evidence-output'
        $exportResult = & $script:exportScript -ConfigurationTier recommended -TenantId '00000000-0000-0000-0000-000000000000' -ReviewArtifactsPath $artifactPath -OutputPath $evidenceOutput
        [System.IO.Path]::IsPathRooted([string]$exportResult.PackagePath) | Should -BeTrue

        $package = Get-Content -Path $exportResult.PackagePath -Raw | ConvertFrom-Json
        foreach ($artifact in @($package.artifacts)) {
            [System.IO.Path]::IsPathRooted([string]$artifact.path) | Should -BeFalse
        }
    }

    It 'passes lab contract schema validation for solution 18 contract file' {
        $repoRoot = [System.IO.Path]::GetFullPath((Join-Path $script:solutionRoot '..\..'))
        $validatorPath = Join-Path $repoRoot 'scripts\validate-lab-contracts.py'
        $contractPath = Join-Path $script:solutionRoot 'lab\18-entra-access-reviews.lab.json'

        $output = & python $validatorPath $contractPath 2>&1
        $LASTEXITCODE | Should -Be 0 -Because ($output -join [Environment]::NewLine)
    }
}
