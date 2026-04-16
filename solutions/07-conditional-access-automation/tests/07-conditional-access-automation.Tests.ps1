Describe 'Conditional Access Policy Automation for Copilot' {
    BeforeAll {
        $solutionRoot = Split-Path $PSScriptRoot -Parent
        $defaultConfigPath = Join-Path $solutionRoot 'config\default-config.json'
        $regulatedConfigPath = Join-Path $solutionRoot 'config\regulated.json'
        $baselineConfigPath = Join-Path $solutionRoot 'config\baseline.json'
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

    It 'configuration status stays documentation-first' {
        foreach ($configPath in @($defaultConfigPath, $baselineConfigPath, $regulatedConfigPath, (Join-Path $solutionRoot 'config\\recommended.json'))) {
            $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json -AsHashtable
            $config.status | Should -Be 'Documentation-first scaffold'
        }
    }

    It 'default-config.json contains non-empty Copilot app IDs' {
        $config = Get-Content -Path $defaultConfigPath -Raw | ConvertFrom-Json -AsHashtable
        @($config.defaults.copilotAppIds).Count | Should -BeGreaterThan 0
        $config.defaults.copilotAppIds | Should -Contain 'fb8d773d-7ef8-4ec0-a117-179f88add510'
    }

    It 'default-config.json requires MFA for all risk tiers' {
        $config = Get-Content -Path $defaultConfigPath -Raw | ConvertFrom-Json -AsHashtable
        foreach ($tier in @('low', 'medium', 'high')) {
            $config.defaults.riskTiers[$tier].mfaRequired | Should -BeTrue -Because "MFA should be required for the '$tier' risk tier"
        }
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

    It 'Deploy-Solution.ps1 New-PolicyTemplate uses correct sessionControls schema' {
        $content = Get-Content -Path $deployScriptPath -Raw
        $content | Should -Match 'persistentBrowser\s*=\s*\[ordered\]@\{'
        $content | Should -Match "mode\s*=\s*'never'"
        $content | Should -Match 'isEnabled\s*=\s*\$true'
        $content | Should -Match 'signInFrequency\s*=\s*\[ordered\]@\{'
        $content | Should -Match "type\s*=\s*'hours'"
        $content | Should -Not -Match 'signInFrequencyHours'
    }

    It 'Deploy-Solution.ps1 Get-PolicyRequestBody defaults to report-only mode' {
        $content = Get-Content -Path $deployScriptPath -Raw
        $content | Should -Match 'enabledForReportingButNotEnforced'
    }

    It 'deployment guide stays repository-local for validation guidance' {
        $content = Get-Content -Path (Join-Path $solutionRoot 'docs\\deployment-guide.md') -Raw
        $content | Should -Not -Match 'FSI-AgentGov-Solutions'
        $content | Should -Match 'Monitor-Compliance\.ps1'
    }

    It 'Deploy-Solution.ps1 -Execute path includes error handling' {
        $content = Get-Content -Path $deployScriptPath -Raw
        $content | Should -Match 'try\s*\{'
        $content | Should -Match 'catch\s*\{'
    }

    It 'all three scripts contain sessionControls with correct Graph API format' {
        foreach ($scriptPath in @($deployScriptPath, $monitorScriptPath, $exportScriptPath)) {
            $content = Get-Content -Path $scriptPath -Raw
            $content | Should -Match 'sessionControls' -Because (Split-Path $scriptPath -Leaf)
            $content | Should -Match 'persistentBrowser' -Because (Split-Path $scriptPath -Leaf)
            $content | Should -Match 'signInFrequency' -Because (Split-Path $scriptPath -Leaf)
        }
    }

    It 'all three scripts document duplicated utility functions' {
        foreach ($scriptPath in @($deployScriptPath, $monitorScriptPath, $exportScriptPath)) {
            $content = Get-Content -Path $scriptPath -Raw
            $content | Should -Match 'duplicated across' -Because (Split-Path $scriptPath -Leaf)
        }
    }
}
