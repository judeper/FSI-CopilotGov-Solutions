Describe 'FINRA Supervision Workflow for Copilot solution' {
    BeforeAll {
        $solutionRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
        $defaultConfigPath = Join-Path $solutionRoot 'config\default-config.json'
        $defaultConfig = Get-Content -Path $defaultConfigPath -Raw | ConvertFrom-Json -AsHashtable
    }

    It 'has required configuration files' {
        foreach ($file in @('default-config.json', 'baseline.json', 'recommended.json', 'regulated.json')) {
            Test-Path (Join-Path $solutionRoot "config\$file") | Should -BeTrue
        }
    }

    It 'has required documentation files' {
        foreach ($file in @('architecture.md', 'deployment-guide.md', 'evidence-export.md', 'prerequisites.md', 'troubleshooting.md')) {
            Test-Path (Join-Path $solutionRoot "docs\$file") | Should -BeTrue
        }
    }

    It 'default-config.json contains required fields' {
        $defaultConfig['solution']['slug'] | Should -Be '04-finra-supervision-workflow'
        $defaultConfig['controls'] | Should -Contain '3.4'
        $defaultConfig['controls'] | Should -Contain '3.5'
        $defaultConfig['controls'] | Should -Contain '3.6'
        $defaultConfig['defaults']['samplingRates']['Zone1']['baseline'] | Should -BeGreaterThan 0
        $defaultConfig['defaults']['samplingRates']['Zone2']['recommended'] | Should -BeGreaterThan 0
        $defaultConfig['defaults']['samplingRates']['Zone3']['regulated'] | Should -Be 100
    }

    It 'config tiers have the correct solution slug' {
        foreach ($tier in @('baseline', 'recommended', 'regulated')) {
            $tierConfig = Get-Content -Path (Join-Path $solutionRoot ("config\$tier.json")) -Raw | ConvertFrom-Json -AsHashtable
            $tierConfig['solution']['slug'] | Should -Be '04-finra-supervision-workflow'
        }
    }

    It 'regulated tier retains evidence for at least one year' {
        $regulated = Get-Content -Path (Join-Path $solutionRoot 'config\regulated.json') -Raw | ConvertFrom-Json -AsHashtable
        $regulated['evidenceRetentionDays'] | Should -BeGreaterOrEqual 365
    }

    It 'has required scripts' {
        foreach ($file in @('Deploy-Solution.ps1', 'Monitor-Compliance.ps1', 'Export-Evidence.ps1')) {
            Test-Path (Join-Path $solutionRoot "scripts\$file") | Should -BeTrue
        }
    }

    It 'scripts pass PowerShell syntax validation' {
        foreach ($file in @('Deploy-Solution.ps1', 'Monitor-Compliance.ps1', 'Export-Evidence.ps1')) {
            $tokens = $null
            $errors = $null
            $null = [System.Management.Automation.Language.Parser]::ParseFile((Join-Path $solutionRoot "scripts\$file"), [ref]$tokens, [ref]$errors)
            @($errors).Count | Should -Be 0
        }
    }

    It 'Export-Evidence.ps1 contains the required artifact type' {
        $content = Get-Content -Path (Join-Path $solutionRoot 'scripts\Export-Evidence.ps1') -Raw
        $content | Should -Match 'supervision-queue-snapshot'
    }

    It 'Monitor-Compliance.ps1 references required control identifiers' {
        $content = Get-Content -Path (Join-Path $solutionRoot 'scripts\Monitor-Compliance.ps1') -Raw
        $content | Should -Match '3.4'
        $content | Should -Match '3.5'
        $content | Should -Match '3.6'
    }
}
