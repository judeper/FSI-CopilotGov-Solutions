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
            'scripts\Deploy-Solution.ps1',
            'scripts\Monitor-Compliance.ps1',
            'scripts\Export-Evidence.ps1',
            'scripts\SharedUtilities.psm1',
            'tests\02-oversharing-risk-assessment.Tests.ps1'
        )

        foreach ($relativePath in $requiredPaths) {
            Test-Path -Path (Join-Path $solutionRoot $relativePath) | Should -BeTrue
        }
    }
}

Describe 'Configuration content' {
    BeforeAll {
        $solutionRoot = Join-Path $PSScriptRoot '..'
        $expectedControls = @('1.2', '1.3', '1.4', '1.6', '1.7', '2.5', '2.12')
        $defaultConfig = (Get-Content -Path (Join-Path $solutionRoot 'config\default-config.json') -Raw) | ConvertFrom-Json
        $baselineConfig = (Get-Content -Path (Join-Path $solutionRoot 'config\baseline.json') -Raw) | ConvertFrom-Json
        $recommendedConfig = (Get-Content -Path (Join-Path $solutionRoot 'config\recommended.json') -Raw) | ConvertFrom-Json
        $regulatedConfig = (Get-Content -Path (Join-Path $solutionRoot 'config\regulated.json') -Raw) | ConvertFrom-Json
    }

    It 'includes scanWorkloads and riskThresholds in default config' {
        @($defaultConfig.scanWorkloads).Count | Should -BeGreaterThan 0
        $defaultConfig.riskThresholds.high | Should -BeGreaterThan 0
        $defaultConfig.riskThresholds.medium | Should -BeGreaterThan 0
        $defaultConfig.riskThresholds.low | Should -Be 0
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
}

Describe 'Script syntax validation' {
    It 'parses all solution scripts without syntax errors' {
        $solutionRoot = Join-Path $PSScriptRoot '..'
        $scriptPaths = @(
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
    It 'references 01-copilot-readiness-scanner in the deployment guide' {
        $deploymentGuide = Get-Content -Path (Join-Path (Join-Path $PSScriptRoot '..') 'docs\deployment-guide.md') -Raw
        $deploymentGuide | Should -Match '01-copilot-readiness-scanner'
    }
}

Describe 'Evidence types' {
    It 'documents all expected evidence outputs' {
        $evidenceDoc = Get-Content -Path (Join-Path (Join-Path $PSScriptRoot '..') 'docs\evidence-export.md') -Raw
        $evidenceDoc | Should -Match 'oversharing-findings'
        $evidenceDoc | Should -Match 'remediation-queue'
        $evidenceDoc | Should -Match 'site-owner-attestations'
    }
}
