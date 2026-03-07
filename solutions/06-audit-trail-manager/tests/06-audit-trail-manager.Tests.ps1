<#
.SYNOPSIS
Validates Copilot Interaction Audit Trail Manager solution assets.

.DESCRIPTION
Pester tests that confirm required ATM documentation, configuration, and script content are present and syntactically valid.
#>
Describe 'Copilot Interaction Audit Trail Manager solution' {
    BeforeAll {
        $solutionRoot = Split-Path -Path $PSScriptRoot -Parent
        $configRoot = Join-Path $solutionRoot 'config'
        $docsRoot = Join-Path $solutionRoot 'docs'
        $scriptsRoot = Join-Path $solutionRoot 'scripts'

        $defaultConfigPath = Join-Path $configRoot 'default-config.json'
        $regulatedConfigPath = Join-Path $configRoot 'regulated.json'
        $deployScriptPath = Join-Path $scriptsRoot 'Deploy-Solution.ps1'
        $monitorScriptPath = Join-Path $scriptsRoot 'Monitor-Compliance.ps1'
        $exportScriptPath = Join-Path $scriptsRoot 'Export-Evidence.ps1'
    }

    It 'has required configuration files' {
        @(
            (Join-Path $configRoot 'default-config.json'),
            (Join-Path $configRoot 'baseline.json'),
            (Join-Path $configRoot 'recommended.json'),
            (Join-Path $configRoot 'regulated.json')
        ) | ForEach-Object {
            Test-Path $_ | Should -BeTrue
        }
    }

    It 'has required documentation files' {
        @(
            (Join-Path $docsRoot 'architecture.md'),
            (Join-Path $docsRoot 'deployment-guide.md'),
            (Join-Path $docsRoot 'evidence-export.md'),
            (Join-Path $docsRoot 'prerequisites.md'),
            (Join-Path $docsRoot 'troubleshooting.md')
        ) | ForEach-Object {
            Test-Path $_ | Should -BeTrue
        }
    }

    It 'has top-level documentation files' {
        @(
            (Join-Path $solutionRoot 'README.md'),
            (Join-Path $solutionRoot 'CHANGELOG.md'),
            (Join-Path $solutionRoot 'DELIVERY-CHECKLIST.md')
        ) | ForEach-Object {
            Test-Path $_ | Should -BeTrue
        }
    }

    It 'default-config.json has required fields' {
        $config = Get-Content -Path $defaultConfigPath -Raw | ConvertFrom-Json -Depth 20

        $config.solution | Should -Be '06-audit-trail-manager'
        $config.controls | Should -Contain '3.1'
        $config.defaults.retentionPeriods | Should -Not -BeNullOrEmpty
        $config.defaults.retentionPeriods.byRegulation.SEC_17a4 | Should -Be 2190
    }

    It 'regulated.json has evidence retention of at least 365 days' {
        $config = Get-Content -Path $regulatedConfigPath -Raw | ConvertFrom-Json -Depth 20
        [int]$config.evidenceRetentionDays | Should -BeGreaterOrEqual 365
    }

    It 'regulated.json documents a retention schedule above 365 days' {
        $config = Get-Content -Path $regulatedConfigPath -Raw | ConvertFrom-Json -Depth 20
        $config.retentionPeriods | Should -Not -BeNullOrEmpty
        [int]$config.retentionPeriods.defaultDays | Should -BeGreaterOrEqual 365
    }

    It 'has all solution scripts' {
        @($deployScriptPath, $monitorScriptPath, $exportScriptPath) | ForEach-Object {
            Test-Path $_ | Should -BeTrue
        }
    }

    It 'solution scripts pass PowerShell syntax validation' {
        foreach ($scriptPath in @($deployScriptPath, $monitorScriptPath, $exportScriptPath)) {
            $tokens = $null
            $errors = $null
            [void][System.Management.Automation.Language.Parser]::ParseFile($scriptPath, [ref]$tokens, [ref]$errors)
            $errors | Should -BeNullOrEmpty
        }
    }

    It 'Export-Evidence.ps1 references audit-log-completeness' {
        $content = Get-Content -Path $exportScriptPath -Raw
        $content | Should -Match 'audit-log-completeness'
    }

    It 'Monitor-Compliance.ps1 references required controls' {
        $content = Get-Content -Path $monitorScriptPath -Raw
        $content | Should -Match '3\.1'
        $content | Should -Match '3\.2'
        $content | Should -Match '3\.3'
    }

    It 'Deploy-Solution.ps1 mentions retention' {
        $content = Get-Content -Path $deployScriptPath -Raw
        $content | Should -Match '(?i)retention'
    }
}