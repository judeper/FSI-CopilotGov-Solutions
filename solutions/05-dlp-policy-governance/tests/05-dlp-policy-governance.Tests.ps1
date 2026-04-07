Describe 'DLP Policy Governance for Copilot solution' {
    BeforeAll {
        $solutionRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
        $configRoot = Join-Path $solutionRoot 'config'
        $docsRoot = Join-Path $solutionRoot 'docs'
        $scriptsRoot = Join-Path $solutionRoot 'scripts'
        $testFiles = @(
            (Join-Path $scriptsRoot 'Common-Functions.ps1'),
            (Join-Path $scriptsRoot 'Deploy-Solution.ps1'),
            (Join-Path $scriptsRoot 'Monitor-Compliance.ps1'),
            (Join-Path $scriptsRoot 'Export-Evidence.ps1')
        )
    }

    It 'has required configuration files' {
        Test-Path (Join-Path $configRoot 'default-config.json') | Should -BeTrue
        Test-Path (Join-Path $configRoot 'baseline.json') | Should -BeTrue
        Test-Path (Join-Path $configRoot 'recommended.json') | Should -BeTrue
        Test-Path (Join-Path $configRoot 'regulated.json') | Should -BeTrue
    }

    It 'has required documentation files' {
        Test-Path (Join-Path $docsRoot 'architecture.md') | Should -BeTrue
        Test-Path (Join-Path $docsRoot 'deployment-guide.md') | Should -BeTrue
        Test-Path (Join-Path $docsRoot 'evidence-export.md') | Should -BeTrue
        Test-Path (Join-Path $docsRoot 'prerequisites.md') | Should -BeTrue
        Test-Path (Join-Path $docsRoot 'troubleshooting.md') | Should -BeTrue
    }

    It 'default-config.json contains required fields' {
        $config = Get-Content (Join-Path $configRoot 'default-config.json') -Raw | ConvertFrom-Json -Depth 20
        $config.solution | Should -Be '05-dlp-policy-governance'
        @($config.controls) | Should -Contain '2.1'
        @($config.defaults.copilotWorkloads) | Should -Contain 'Teams'
        @($config.defaults.copilotWorkloads) | Should -Contain 'Exchange'
    }

    It 'baseline.json has the correct tier and solution' {
        $config = Get-Content (Join-Path $configRoot 'baseline.json') -Raw | ConvertFrom-Json -Depth 20
        $config.tier | Should -Be 'baseline'
        $config.solution | Should -Be '05-dlp-policy-governance'
    }

    It 'regulated.json retains evidence for at least 365 days' {
        $config = Get-Content (Join-Path $configRoot 'regulated.json') -Raw | ConvertFrom-Json -Depth 20
        [int]$config.evidenceRetentionDays | Should -BeGreaterOrEqual 365
    }

    It 'has all required scripts' {
        foreach ($path in $testFiles) {
            Test-Path $path | Should -BeTrue
        }
    }

    It 'scripts pass PowerShell syntax validation' {
        foreach ($path in $testFiles) {
            $tokens = $null
            $errors = $null
            [void][System.Management.Automation.Language.Parser]::ParseFile($path, [ref]$tokens, [ref]$errors)
            $errors.Count | Should -Be 0 -Because $path
        }
    }

    It 'Export-Evidence.ps1 references dlp-policy-baseline' {
        $content = Get-Content (Join-Path $scriptsRoot 'Export-Evidence.ps1') -Raw
        $content | Should -Match 'dlp-policy-baseline'
    }

    It 'Monitor-Compliance.ps1 references control 2.1' {
        $content = Get-Content (Join-Path $scriptsRoot 'Monitor-Compliance.ps1') -Raw
        $content | Should -Match '2\.1'
    }
}
