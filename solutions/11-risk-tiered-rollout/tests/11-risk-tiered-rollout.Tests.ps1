Set-StrictMode -Version Latest

Describe 'Risk-Tiered Rollout Automation solution' {
    BeforeAll {
        $script:solutionRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
        $script:deployScriptPath = Join-Path $script:solutionRoot 'scripts\Deploy-Solution.ps1'
        $script:monitorScriptPath = Join-Path $script:solutionRoot 'scripts\Monitor-Compliance.ps1'
        $script:exportScriptPath = Join-Path $script:solutionRoot 'scripts\Export-Evidence.ps1'
    }

    It 'has required configuration files' {
        Test-Path (Join-Path $script:solutionRoot 'config\default-config.json') | Should -BeTrue
        Test-Path (Join-Path $script:solutionRoot 'config\baseline.json') | Should -BeTrue
        Test-Path (Join-Path $script:solutionRoot 'config\recommended.json') | Should -BeTrue
        Test-Path (Join-Path $script:solutionRoot 'config\regulated.json') | Should -BeTrue
    }

    It 'has required documentation files' {
        Test-Path (Join-Path $script:solutionRoot 'README.md') | Should -BeTrue
        Test-Path (Join-Path $script:solutionRoot 'docs\architecture.md') | Should -BeTrue
        Test-Path (Join-Path $script:solutionRoot 'docs\deployment-guide.md') | Should -BeTrue
        Test-Path (Join-Path $script:solutionRoot 'docs\evidence-export.md') | Should -BeTrue
        Test-Path (Join-Path $script:solutionRoot 'docs\prerequisites.md') | Should -BeTrue
        Test-Path (Join-Path $script:solutionRoot 'docs\troubleshooting.md') | Should -BeTrue
    }

    It 'Deploy-Solution.ps1 includes comment-based help' {
        $content = Get-Content -Path $script:deployScriptPath -Raw
        $content | Should -Match '<#'
        $content | Should -Match '\.SYNOPSIS'
        $content | Should -Match '\.PARAMETER\s+WaveNumber'
    }

    It 'Monitor-Compliance.ps1 accepts a WaveNumber parameter' {
        $command = Get-Command -Name $script:monitorScriptPath
        $command.Parameters.Keys | Should -Contain 'WaveNumber'
    }

    It 'Export-Evidence.ps1 references the RTR solution code' {
        $content = Get-Content -Path $script:exportScriptPath -Raw
        $content | Should -Match "-SolutionCode\s+'RTR'"
    }

    It 'default-config.json contains wave definitions' {
        $config = Get-Content -Path (Join-Path $script:solutionRoot 'config\default-config.json') -Raw | ConvertFrom-Json -Depth 20
        $config.PSObject.Properties.Name | Should -Contain 'waveDefinitions'
        $config.waveDefinitions.Count | Should -BeGreaterThan 0
    }

    It 'regulated.json retains evidence for at least 365 days' {
        $config = Get-Content -Path (Join-Path $script:solutionRoot 'config\regulated.json') -Raw | ConvertFrom-Json -Depth 20
        [int]$config.evidenceRetentionDays | Should -BeGreaterOrEqual 365
    }

    It 'Deploy-Solution.ps1 is valid PowerShell syntax' {
        $tokens = $null
        $errors = $null
        [void][System.Management.Automation.Language.Parser]::ParseFile($script:deployScriptPath, [ref]$tokens, [ref]$errors)
        @($errors).Count | Should -Be 0
    }

    It 'Monitor-Compliance.ps1 labels documentation-first wave health' {
        $monitorResult = & $script:monitorScriptPath -ConfigurationTier recommended -WaveNumber 0 -OutputPath (Join-Path $TestDrive 'monitor') 3>$null

        $monitorResult.runtimeMode | Should -Be 'documentation-first-stub'
        $monitorResult.waveHealth.Status | Should -Not -Be 'implemented'
        $monitorResult.statusWarning | Should -Match 'staged-only'
    }

    It 'Export-Evidence.ps1 keeps rollout package statuses below implemented' {
        $exportResult = & $script:exportScriptPath -ConfigurationTier regulated -OutputPath (Join-Path $TestDrive 'evidence')
        $package = Get-Content -Path $exportResult.Package.Path -Raw | ConvertFrom-Json -Depth 20
        $waveReadiness = Get-Content -Path (Join-Path $TestDrive 'evidence\RTR-wave-readiness-log.json') -Raw | ConvertFrom-Json -Depth 20

        $package.metadata.runtimeMode | Should -Be 'documentation-first-stub'
        @($package.controls | Where-Object { $_.status -eq 'implemented' }).Count | Should -Be 0
        $waveReadiness[0].dataSourceMode | Should -Be 'representative-sample'
    }
}
