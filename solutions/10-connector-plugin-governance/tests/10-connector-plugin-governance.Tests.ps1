BeforeAll {
    $solutionRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
    $configRoot = Join-Path $solutionRoot 'config'
    $docsRoot = Join-Path $solutionRoot 'docs'
    $scriptsRoot = Join-Path $solutionRoot 'scripts'
}

Describe 'Copilot Connector and Plugin Governance solution content' {
    It 'has required configuration files' {
        @(
            'default-config.json',
            'baseline.json',
            'recommended.json',
            'regulated.json'
        ) | ForEach-Object {
            Test-Path (Join-Path $configRoot $_) | Should -BeTrue
        }
    }

    It 'has required documentation files' {
        @(
            'architecture.md',
            'deployment-guide.md',
            'evidence-export.md',
            'prerequisites.md',
            'troubleshooting.md'
        ) | ForEach-Object {
            Test-Path (Join-Path $docsRoot $_) | Should -BeTrue
        }
    }

    It 'documents comment-based help in Deploy-Solution.ps1' {
        $deployScript = Get-Content -Path (Join-Path $scriptsRoot 'Deploy-Solution.ps1') -Raw
        $deployScript.Contains('.SYNOPSIS') | Should -BeTrue
        $deployScript.Contains('.DESCRIPTION') | Should -BeTrue
    }

    It 'accepts the AlertOnNewConnectors parameter in Monitor-Compliance.ps1' {
        $command = Get-Command (Join-Path $scriptsRoot 'Monitor-Compliance.ps1')
        $command.Parameters.ContainsKey('AlertOnNewConnectors') | Should -BeTrue
    }

    It 'references the correct solution code in Export-Evidence.ps1' {
        $exportScript = Get-Content -Path (Join-Path $scriptsRoot 'Export-Evidence.ps1') -Raw
        $exportScript.Contains("-SolutionCode 'CPG'") | Should -BeTrue
    }

    It 'contains connector risk configuration in default-config.json' {
        $defaultConfig = Get-Content -Path (Join-Path $configRoot 'default-config.json') -Raw | ConvertFrom-Json -Depth 20
        ($defaultConfig.PSObject.Properties.Name -contains 'connectorRiskCategories') | Should -BeTrue
        ($defaultConfig.PSObject.Properties.Name -contains 'blockedConnectorIds') | Should -BeTrue
    }

    It 'retains regulated evidence for at least 365 days' {
        $regulatedConfig = Get-Content -Path (Join-Path $configRoot 'regulated.json') -Raw | ConvertFrom-Json -Depth 20
        [int]$regulatedConfig.evidenceRetentionDays | Should -BeGreaterOrEqual 365
    }

    It 'has valid PowerShell syntax in Deploy-Solution.ps1' {
        $errors = $null
        $tokens = $null
        [System.Management.Automation.Language.Parser]::ParseFile(
            (Join-Path $scriptsRoot 'Deploy-Solution.ps1'),
            [ref]$tokens,
            [ref]$errors
        ) | Out-Null

        $errors.Count | Should -Be 0
    }

    It 'has valid PowerShell syntax in Export-Evidence.ps1' {
        $errors = $null
        $tokens = $null
        [System.Management.Automation.Language.Parser]::ParseFile(
            (Join-Path $scriptsRoot 'Export-Evidence.ps1'),
            [ref]$tokens,
            [ref]$errors
        ) | Out-Null

        $errors.Count | Should -Be 0
    }

    It 'has valid PowerShell syntax in Monitor-Compliance.ps1' {
        $errors = $null
        $tokens = $null
        [System.Management.Automation.Language.Parser]::ParseFile(
            (Join-Path $scriptsRoot 'Monitor-Compliance.ps1'),
            [ref]$tokens,
            [ref]$errors
        ) | Out-Null

        $errors.Count | Should -Be 0
    }
}
