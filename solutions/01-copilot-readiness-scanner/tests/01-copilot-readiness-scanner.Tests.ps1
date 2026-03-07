BeforeAll {
    $solutionRoot = Split-Path -Parent $PSScriptRoot
    $docsPath = Join-Path $solutionRoot 'docs'
    $configPath = Join-Path $solutionRoot 'config'
    $scriptsPath = Join-Path $solutionRoot 'scripts'

    $requiredDocs = @(
        (Join-Path $docsPath 'architecture.md'),
        (Join-Path $docsPath 'deployment-guide.md'),
        (Join-Path $docsPath 'evidence-export.md'),
        (Join-Path $docsPath 'prerequisites.md'),
        (Join-Path $docsPath 'troubleshooting.md')
    )

    $requiredScripts = @(
        (Join-Path $scriptsPath 'Deploy-Solution.ps1'),
        (Join-Path $scriptsPath 'Monitor-Compliance.ps1'),
        (Join-Path $scriptsPath 'Export-Evidence.ps1')
    )

    $requiredConfigs = @(
        (Join-Path $configPath 'default-config.json'),
        (Join-Path $configPath 'baseline.json'),
        (Join-Path $configPath 'recommended.json'),
        (Join-Path $configPath 'regulated.json')
    )

    $defaultConfigPath = Join-Path $configPath 'default-config.json'
    $baselineConfigPath = Join-Path $configPath 'baseline.json'
    $regulatedConfigPath = Join-Path $configPath 'regulated.json'
    $changelogPath = Join-Path $solutionRoot 'CHANGELOG.md'
    $evidenceDocPath = Join-Path $docsPath 'evidence-export.md'
}

Describe 'Solution structure' {
    It 'has all required documentation files' {
        foreach ($path in $requiredDocs) {
            Test-Path $path | Should -BeTrue
        }
    }

    It 'has all required script files' {
        foreach ($path in $requiredScripts) {
            Test-Path $path | Should -BeTrue
        }
    }

    It 'has all required configuration files' {
        foreach ($path in $requiredConfigs) {
            Test-Path $path | Should -BeTrue
        }
    }
}

Describe 'Configuration file content' {
    It 'default-config.json has required fields' {
        $config = Get-Content -Path $defaultConfigPath -Raw | ConvertFrom-Json -AsHashtable
        $config['solution'] | Should -Be '01-copilot-readiness-scanner'
        $config['displayName'] | Should -Be 'Copilot Readiness Assessment Scanner'
        $config['controls'] | Should -Contain '1.1'
        $config['track'] | Should -Be 'A'
    }

    It 'baseline tier has evidenceRetentionDays' {
        $config = Get-Content -Path $baselineConfigPath -Raw | ConvertFrom-Json -AsHashtable
        $config['evidenceRetentionDays'] | Should -Be 90
    }

    It 'regulated tier has longer retention than baseline' {
        $baselineConfig = Get-Content -Path $baselineConfigPath -Raw | ConvertFrom-Json -AsHashtable
        $regulatedConfig = Get-Content -Path $regulatedConfigPath -Raw | ConvertFrom-Json -AsHashtable
        [int]$regulatedConfig['evidenceRetentionDays'] | Should -BeGreaterThan ([int]$baselineConfig['evidenceRetentionDays'])
    }

    It 'config controls match catalog' {
        $config = Get-Content -Path $defaultConfigPath -Raw | ConvertFrom-Json -AsHashtable
        $config['controls'] | Should -Contain '1.1'
        $config['controls'] | Should -Contain '1.5'
        $config['controls'] | Should -Contain '1.6'
        $config['controls'] | Should -Contain '1.7'
        $config['controls'] | Should -Contain '1.9'
    }
}

Describe 'Script syntax validation' {
    It 'Deploy-Solution.ps1 has no syntax errors' {
        $errors = $null
        [System.Management.Automation.Language.Parser]::ParseFile((Join-Path $scriptsPath 'Deploy-Solution.ps1'), [ref]$null, [ref]$errors) | Out-Null
        $errors.Count | Should -Be 0
    }

    It 'Monitor-Compliance.ps1 has no syntax errors' {
        $errors = $null
        [System.Management.Automation.Language.Parser]::ParseFile((Join-Path $scriptsPath 'Monitor-Compliance.ps1'), [ref]$null, [ref]$errors) | Out-Null
        $errors.Count | Should -Be 0
    }

    It 'Export-Evidence.ps1 has no syntax errors' {
        $errors = $null
        [System.Management.Automation.Language.Parser]::ParseFile((Join-Path $scriptsPath 'Export-Evidence.ps1'), [ref]$null, [ref]$errors) | Out-Null
        $errors.Count | Should -Be 0
    }
}

Describe 'CHANGELOG format' {
    It 'CHANGELOG has v0.2.0 entry' {
        (Get-Content -Path $changelogPath -Raw) | Should -Match '## \[v0\.2\.0\]'
    }
}

Describe 'Evidence export doc' {
    It 'evidence-export.md documents readiness-scorecard' {
        (Get-Content -Path $evidenceDocPath -Raw) | Should -Match 'readiness-scorecard'
    }

    It 'evidence-export.md documents data-hygiene-findings' {
        (Get-Content -Path $evidenceDocPath -Raw) | Should -Match 'data-hygiene-findings'
    }
}

Describe 'Runtime honesty markers' {
    It 'Monitor-Compliance.ps1 labels simulated readiness output clearly' {
        $monitorOutputPath = Join-Path $TestDrive 'monitor'
        $results = @(& (Join-Path $scriptsPath 'Monitor-Compliance.ps1') -ConfigurationTier baseline -TenantId 'contoso.onmicrosoft.com' -ExportPath $monitorOutputPath 3>$null)

        $results.Count | Should -BeGreaterThan 0
        foreach ($result in $results) {
            $result.RuntimeMode | Should -Be 'documentation-first'
            $result.DataSourceMode | Should -Be 'simulated-baseline'
            $result.Status | Should -Not -Be 'implemented'
            $result.SimulationWarning | Should -Match 'no live Microsoft Graph'
        }
    }

    It 'Export-Evidence.ps1 tags sample evidence packages' {
        $evidenceOutputPath = Join-Path $TestDrive 'evidence'
        $exportResult = & (Join-Path $scriptsPath 'Export-Evidence.ps1') -ConfigurationTier baseline -TenantId 'contoso.onmicrosoft.com' -OutputPath $evidenceOutputPath
        $package = Get-Content -Path $exportResult.PackagePath -Raw | ConvertFrom-Json -Depth 20

        $package.metadata.runtimeMode | Should -Be 'documentation-first-sample-data'
        $package.summary.statusSemantics | Should -Match 'documentation-first sample evidence'
    }
}
