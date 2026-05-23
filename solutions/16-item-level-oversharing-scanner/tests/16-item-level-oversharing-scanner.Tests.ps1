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
            'config\risk-thresholds.json',
            'config\remediation-policy.json',
            'config\baseline.json',
            'config\recommended.json',
            'config\regulated.json',
            'scripts\Get-ItemLevelPermissions.ps1',
            'scripts\Export-OversharedItems.ps1',
            'scripts\Invoke-BulkRemediation.ps1',
            'scripts\Deploy-Solution.ps1',
            'scripts\Monitor-Compliance.ps1',
            'scripts\Export-Evidence.ps1',
            'tests\16-item-level-oversharing-scanner.Tests.ps1'
        )

        foreach ($relativePath in $requiredPaths) {
            Test-Path -Path (Join-Path $solutionRoot $relativePath) | Should -BeTrue
        }
    }
}

Describe 'Configuration content' {
    BeforeAll {
        $solutionRoot = Join-Path $PSScriptRoot '..'
        $script:expectedControls = @('1.2', '1.3', '1.4', '1.6', '2.5')
        $script:defaultConfig = (Get-Content -Path (Join-Path $solutionRoot 'config\default-config.json') -Raw) | ConvertFrom-Json
        $script:baselineConfig = (Get-Content -Path (Join-Path $solutionRoot 'config\baseline.json') -Raw) | ConvertFrom-Json
        $script:recommendedConfig = (Get-Content -Path (Join-Path $solutionRoot 'config\recommended.json') -Raw) | ConvertFrom-Json
        $script:regulatedConfig = (Get-Content -Path (Join-Path $solutionRoot 'config\regulated.json') -Raw) | ConvertFrom-Json
    }

    It 'includes riskThresholds in default config' {
        $script:defaultConfig.riskThresholds.high | Should -BeGreaterThan 0
        $script:defaultConfig.riskThresholds.medium | Should -BeGreaterThan 0
        $script:defaultConfig.riskThresholds.low | Should -Be 0
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

    It 'includes evidenceOutputs in all tier configs' {
        $expectedOutputs = @('item-oversharing-findings', 'risk-scored-report', 'remediation-actions')
        (@($script:baselineConfig.evidenceOutputs) -join ',') | Should -Be ($expectedOutputs -join ',')
        (@($script:recommendedConfig.evidenceOutputs) -join ',') | Should -Be ($expectedOutputs -join ',')
        (@($script:regulatedConfig.evidenceOutputs) -join ',') | Should -Be ($expectedOutputs -join ',')
    }

    It 'validates risk-thresholds.json is valid JSON' {
        $riskThresholds = (Get-Content -Path (Join-Path $solutionRoot 'config\risk-thresholds.json') -Raw) | ConvertFrom-Json
        $riskThresholds | Should -Not -BeNullOrEmpty
        $riskThresholds.baseRiskScores | Should -Not -BeNullOrEmpty
        $riskThresholds.contentTypeWeights | Should -Not -BeNullOrEmpty
    }

    It 'validates remediation-policy.json is valid JSON' {
        $policy = (Get-Content -Path (Join-Path $solutionRoot 'config\remediation-policy.json') -Raw) | ConvertFrom-Json
        $policy | Should -Not -BeNullOrEmpty
        $policy.HIGH.mode | Should -Be 'approval-gate'
        $policy.autoRemediationEnabled | Should -Be $false
    }
}

Describe 'Script syntax validation' {
    It 'parses all solution scripts without syntax errors' {
        $solutionRoot = Join-Path $PSScriptRoot '..'
        $scriptPaths = @(
            (Join-Path $solutionRoot 'scripts\Get-ItemLevelPermissions.ps1'),
            (Join-Path $solutionRoot 'scripts\Export-OversharedItems.ps1'),
            (Join-Path $solutionRoot 'scripts\Invoke-BulkRemediation.ps1'),
            (Join-Path $solutionRoot 'scripts\Deploy-Solution.ps1'),
            (Join-Path $solutionRoot 'scripts\Monitor-Compliance.ps1'),
            (Join-Path $solutionRoot 'scripts\Export-Evidence.ps1')
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
        $evidenceDoc | Should -Match 'item-oversharing-findings'
        $evidenceDoc | Should -Match 'risk-scored-report'
        $evidenceDoc | Should -Match 'remediation-actions'
    }
}

Describe 'README content' {
    BeforeAll {
        $script:readmeContent = Get-Content -Path (Join-Path (Join-Path $PSScriptRoot '..') 'README.md') -Raw
    }

    It 'includes required sections' {
        $requiredSections = @(
            '## Overview',
            '## Scope Boundaries',
            '## Related Controls',
            '## Prerequisites',
            '## Deployment',
            '## Evidence Export',
            '## Regulatory Alignment'
        )

        foreach ($section in $requiredSections) {
            $escaped = [regex]::Escape($section)
            $script:readmeContent | Should -Match $escaped
        }
    }

    It 'includes the standardized status line' {
        $script:readmeContent | Should -Match 'Status:.*Documentation-first scaffold'
    }

    It 'includes the disclaimer banner' {
        $script:readmeContent | Should -Match 'Documentation-first repository'
    }
}
