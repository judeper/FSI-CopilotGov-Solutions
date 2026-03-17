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
        $expectedControls = @('1.2', '1.6', '2.5', '2.12')
        $defaultConfig = (Get-Content -Path (Join-Path $solutionRoot 'config\default-config.json') -Raw) | ConvertFrom-Json
        $baselineConfig = (Get-Content -Path (Join-Path $solutionRoot 'config\baseline.json') -Raw) | ConvertFrom-Json
        $recommendedConfig = (Get-Content -Path (Join-Path $solutionRoot 'config\recommended.json') -Raw) | ConvertFrom-Json
        $regulatedConfig = (Get-Content -Path (Join-Path $solutionRoot 'config\regulated.json') -Raw) | ConvertFrom-Json
        $reviewSchedule = (Get-Content -Path (Join-Path $solutionRoot 'config\review-schedule.json') -Raw) | ConvertFrom-Json
        $reviewerMapping = (Get-Content -Path (Join-Path $solutionRoot 'config\reviewer-mapping.json') -Raw) | ConvertFrom-Json
    }

    It 'includes evidenceOutputs and upstreamDependency in default config' {
        @($defaultConfig.evidenceOutputs).Count | Should -BeGreaterThan 0
        $defaultConfig.upstreamDependency | Should -Be '02-oversharing-risk-assessment'
    }

    It 'uses longer retention in the regulated tier' {
        [int]$regulatedConfig.evidenceRetentionDays | Should -BeGreaterThan ([int]$recommendedConfig.evidenceRetentionDays)
        [int]$recommendedConfig.evidenceRetentionDays | Should -BeGreaterThan ([int]$baselineConfig.evidenceRetentionDays)
    }

    It 'keeps the control mapping consistent across configs' {
        (@($defaultConfig.controls) -join ',') | Should -Be ($expectedControls -join ',')
        (@($baselineConfig.controls) -join ',') | Should -Be ($expectedControls -join ',')
        (@($recommendedConfig.controls) -join ',') | Should -Be ($expectedControls -join ',')
        (@($regulatedConfig.controls) -join ',') | Should -Be ($expectedControls -join ',')
    }

    It 'defines review cadence for all risk tiers' {
        $reviewSchedule.reviewCadence.HIGH.frequencyDays | Should -BeGreaterThan 0
        $reviewSchedule.reviewCadence.MEDIUM.frequencyDays | Should -BeGreaterThan 0
        $reviewSchedule.reviewCadence.LOW.frequencyDays | Should -BeGreaterThan 0
    }

    It 'defines escalation chain in reviewer mapping' {
        @($reviewerMapping.escalationChain).Count | Should -BeGreaterThan 0
    }

    It 'includes all evidence outputs in tier configs' {
        @($baselineConfig.evidenceOutputs) | Should -Contain 'access-review-definitions'
        @($baselineConfig.evidenceOutputs) | Should -Contain 'review-decisions'
        @($baselineConfig.evidenceOutputs) | Should -Contain 'applied-actions'
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
