Describe 'Conditional Access Policy Automation for Copilot' {
    BeforeAll {
        $solutionRoot = Split-Path $PSScriptRoot -Parent
        $defaultConfigPath = Join-Path $solutionRoot 'config\default-config.json'
        $regulatedConfigPath = Join-Path $solutionRoot 'config\regulated.json'
        $deployScriptPath = Join-Path $solutionRoot 'scripts\Deploy-Solution.ps1'
        $monitorScriptPath = Join-Path $solutionRoot 'scripts\Monitor-Compliance.ps1'
        $exportScriptPath = Join-Path $solutionRoot 'scripts\Export-Evidence.ps1'
    }

    It 'has required config files' {
        foreach ($relativePath in @(
            'config\default-config.json',
            'config\baseline.json',
            'config\recommended.json',
            'config\regulated.json'
        )) {
            Test-Path (Join-Path $solutionRoot $relativePath) | Should -BeTrue
        }
    }

    It 'has required documentation files' {
        foreach ($relativePath in @(
            'docs\architecture.md',
            'docs\deployment-guide.md',
            'docs\evidence-export.md',
            'docs\prerequisites.md',
            'docs\troubleshooting.md'
        )) {
            Test-Path (Join-Path $solutionRoot $relativePath) | Should -BeTrue
        }
    }

    It 'default-config.json defines required fields' {
        $config = Get-Content -Path $defaultConfigPath -Raw | ConvertFrom-Json -AsHashtable
        $config.solution | Should -Be '07-conditional-access-automation'
        $config.controls | Should -Contain '2.3'
        $config.ContainsKey('defaults') | Should -BeTrue
        $config.defaults.ContainsKey('copilotAppIds') | Should -BeTrue
    }

    It 'default-config.json contains non-empty Copilot app IDs' {
        $config = Get-Content -Path $defaultConfigPath -Raw | ConvertFrom-Json -AsHashtable
        @($config.defaults.copilotAppIds).Count | Should -BeGreaterThan 0
        $config.defaults.copilotAppIds | Should -Contain '2d7f3606-b07d-41d1-b9d2-0d0c9296a6e4'
    }

    It 'regulated.json keeps evidence retention at or above 365 days' {
        $regulated = Get-Content -Path $regulatedConfigPath -Raw | ConvertFrom-Json -AsHashtable
        ($regulated.evidenceRetentionDays -ge 365) | Should -BeTrue
    }

    It 'all required scripts exist' {
        foreach ($scriptPath in @($deployScriptPath, $monitorScriptPath, $exportScriptPath)) {
            Test-Path $scriptPath | Should -BeTrue
        }
    }

    It 'solution scripts parse without syntax errors' {
        foreach ($scriptFile in Get-ChildItem -Path (Join-Path $solutionRoot 'scripts') -Filter '*.ps1') {
            $tokens = $null
            $errors = $null
            $null = [System.Management.Automation.Language.Parser]::ParseFile($scriptFile.FullName, [ref]$tokens, [ref]$errors)
            $errors | Should -BeNullOrEmpty -Because $scriptFile.Name
        }
    }

    It 'Export-Evidence.ps1 references ca-policy-state' {
        (Get-Content -Path $exportScriptPath -Raw) | Should -Match 'ca-policy-state'
    }

    It 'Monitor-Compliance.ps1 references controls 2.3 and 2.9' {
        $content = Get-Content -Path $monitorScriptPath -Raw
        $content | Should -Match '2\.3'
        $content | Should -Match '2\.9'
    }

    It 'Deploy-Solution.ps1 references Copilot configuration' {
        (Get-Content -Path $deployScriptPath -Raw) | Should -Match '(?i)copilotappids|copilot'
    }
}
