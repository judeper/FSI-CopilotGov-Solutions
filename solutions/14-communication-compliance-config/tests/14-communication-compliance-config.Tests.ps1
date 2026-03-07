Describe 'Communication Compliance Configurator' {
    BeforeAll {
        $solutionRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
        $requiredFiles = @(
            'README.md',
            'CHANGELOG.md',
            'DELIVERY-CHECKLIST.md',
            'docs\architecture.md',
            'docs\deployment-guide.md',
            'docs\evidence-export.md',
            'docs\prerequisites.md',
            'docs\troubleshooting.md',
            'scripts\Deploy-Solution.ps1',
            'scripts\Monitor-Compliance.ps1',
            'scripts\Export-Evidence.ps1',
            'config\default-config.json',
            'config\baseline.json',
            'config\recommended.json',
            'config\regulated.json',
            'tests\14-communication-compliance-config.Tests.ps1'
        ) | ForEach-Object { Join-Path $solutionRoot $_ }

        $defaultConfig = (Get-Content -Path (Join-Path $solutionRoot 'config\default-config.json') -Raw) | ConvertFrom-Json
        $baselineConfig = (Get-Content -Path (Join-Path $solutionRoot 'config\baseline.json') -Raw) | ConvertFrom-Json
        $recommendedConfig = (Get-Content -Path (Join-Path $solutionRoot 'config\recommended.json') -Raw) | ConvertFrom-Json
        $regulatedConfig = (Get-Content -Path (Join-Path $solutionRoot 'config\regulated.json') -Raw) | ConvertFrom-Json
        $readmeContent = Get-Content -Path (Join-Path $solutionRoot 'README.md') -Raw
        $evidenceDocContent = Get-Content -Path (Join-Path $solutionRoot 'docs\evidence-export.md') -Raw
        $scriptFiles = @(
            (Join-Path $solutionRoot 'scripts\Deploy-Solution.ps1'),
            (Join-Path $solutionRoot 'scripts\Monitor-Compliance.ps1'),
            (Join-Path $solutionRoot 'scripts\Export-Evidence.ps1')
        )
    }

    Context 'File presence' {
        It 'contains all required solution files' {
            foreach ($file in $requiredFiles) {
                Test-Path -Path $file | Should -BeTrue -Because "$file should exist."
            }
        }
    }

    Context 'Configuration validation' {
        It 'uses the correct solution slug, code, and controls' {
            $defaultConfig.solution | Should -Be '14-communication-compliance-config'
            $defaultConfig.solutionCode | Should -Be 'CCC'
            @($defaultConfig.controls) | Should -Contain '2.10'
            @($defaultConfig.controls) | Should -Contain '3.4'
            @($defaultConfig.controls) | Should -Contain '3.5'
            @($defaultConfig.controls) | Should -Contain '3.6'
            @($defaultConfig.controls) | Should -Contain '3.9'
        }

        It 'defines policy templates in each tier' {
            @($baselineConfig.policyTemplates).Count | Should -BeGreaterThan 0
            @($recommendedConfig.policyTemplates).Count | Should -BeGreaterThan 0
            @($regulatedConfig.policyTemplates).Count | Should -BeGreaterThan 0
        }

        It 'enables FINRA 3110 supervision in the regulated tier' {
            $regulatedConfig.finra3110SupervisionEnabled | Should -BeTrue
        }
    }

    Context 'Script syntax validation' {
        It 'parses all solution scripts without syntax errors' {
            foreach ($scriptFile in $scriptFiles) {
                $tokens = $null
                $errors = $null
                [System.Management.Automation.Language.Parser]::ParseFile($scriptFile, [ref]$tokens, [ref]$errors) > $null
                $errors.Count | Should -Be 0 -Because "$scriptFile should parse without syntax errors."
            }
        }

        It 'includes comment-based help in each script' {
            foreach ($scriptFile in $scriptFiles) {
                $content = Get-Content -Path $scriptFile -Raw
                $content | Should -Match '\.SYNOPSIS'
                $content | Should -Match '\.DESCRIPTION'
                $content | Should -Match '\.PARAMETER'
            }
        }
    }

    Context 'Documentation validation' {
        It 'references FINRA 3110 in the README' {
            $readmeContent | Should -Match 'FINRA 3110'
        }

        It 'references reviewer-queue-metrics in the evidence export guide' {
            $evidenceDocContent | Should -Match 'reviewer-queue-metrics'
        }
    }
}
