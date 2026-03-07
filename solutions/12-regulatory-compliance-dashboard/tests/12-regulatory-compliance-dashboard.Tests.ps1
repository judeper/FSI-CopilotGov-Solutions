BeforeAll {
    $solutionRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
    $deployScriptPath = Join-Path $solutionRoot 'scripts\Deploy-Solution.ps1'
    $monitorScriptPath = Join-Path $solutionRoot 'scripts\Monitor-Compliance.ps1'
    $exportScriptPath = Join-Path $solutionRoot 'scripts\Export-Evidence.ps1'
    $defaultConfigPath = Join-Path $solutionRoot 'config\default-config.json'
    $regulatedConfigPath = Join-Path $solutionRoot 'config\regulated.json'
    $defaultConfig = Get-Content -Path $defaultConfigPath -Raw | ConvertFrom-Json
    $regulatedConfig = Get-Content -Path $regulatedConfigPath -Raw | ConvertFrom-Json
}

Describe 'Regulatory Compliance Dashboard package' {
    It 'has required configuration files' {
        Test-Path (Join-Path $solutionRoot 'config\default-config.json') | Should -BeTrue
        Test-Path (Join-Path $solutionRoot 'config\baseline.json') | Should -BeTrue
        Test-Path (Join-Path $solutionRoot 'config\recommended.json') | Should -BeTrue
        Test-Path (Join-Path $solutionRoot 'config\regulated.json') | Should -BeTrue
    }

    It 'has required documentation files' {
        Test-Path (Join-Path $solutionRoot 'README.md') | Should -BeTrue
        Test-Path (Join-Path $solutionRoot 'docs\architecture.md') | Should -BeTrue
        Test-Path (Join-Path $solutionRoot 'docs\deployment-guide.md') | Should -BeTrue
        Test-Path (Join-Path $solutionRoot 'docs\evidence-export.md') | Should -BeTrue
        Test-Path (Join-Path $solutionRoot 'docs\prerequisites.md') | Should -BeTrue
        Test-Path (Join-Path $solutionRoot 'docs\troubleshooting.md') | Should -BeTrue
    }

    It 'includes comment-based help in Deploy-Solution.ps1' {
        $deployScriptContent = Get-Content -Path $deployScriptPath -Raw
        $deployScriptContent | Should -Match '<#'
        $deployScriptContent | Should -Match '\.SYNOPSIS'
    }

    It 'accepts the FreshnessThresholdHours parameter in Monitor-Compliance.ps1' {
        (Get-Content -Path $monitorScriptPath -Raw) | Should -Match 'FreshnessThresholdHours'
    }

    It 'references the RCD solution code in Export-Evidence.ps1' {
        (Get-Content -Path $exportScriptPath -Raw) | Should -Match "SolutionCode 'RCD'"
    }

    It 'defines regulatory frameworks in default-config.json' {
        $defaultConfig.regulatoryFrameworks.Count | Should -BeGreaterThan 0
    }

    It 'retains regulated evidence for at least 365 days' {
        [int]$regulatedConfig.evidenceRetentionDays | Should -BeGreaterOrEqual 365
    }

    It 'parses Deploy-Solution.ps1 without syntax errors' {
        $tokens = $null
        $parseErrors = $null
        [void][System.Management.Automation.Language.Parser]::ParseFile($deployScriptPath, [ref]$tokens, [ref]$parseErrors)
        $parseErrors.Count | Should -Be 0
    }

    It 'Monitor-Compliance.ps1 marks fallback output as documentation-first' {
        $monitorResult = & $monitorScriptPath -ConfigurationTier baseline -OutputPath (Join-Path $TestDrive 'monitor') 3>$null

        $monitorResult.SnapshotSource | Should -Be 'fallback-defaults'
        $monitorResult.RuntimeMode | Should -Be 'documentation-first-fallback'
        @($monitorResult.Controls | Where-Object { $_.status -eq 'implemented' }).Count | Should -Be 0
    }

    It 'Export-Evidence.ps1 keeps seeded dashboard controls below implemented' {
        $exportResult = & $exportScriptPath -ConfigurationTier recommended -OutputPath (Join-Path $TestDrive 'evidence')
        $package = Get-Content -Path $exportResult.Package.Path -Raw | ConvertFrom-Json -Depth 20
        $dashboardExport = Get-Content -Path (Join-Path $TestDrive 'evidence\dashboard-export.json') -Raw | ConvertFrom-Json -Depth 20

        $package.metadata.runtimeMode | Should -Be 'documentation-first-seed'
        @($package.controls | Where-Object { $_.status -eq 'implemented' }).Count | Should -Be 0
        $dashboardExport.warning | Should -Match 'seeded dashboard artifacts'
    }
}
