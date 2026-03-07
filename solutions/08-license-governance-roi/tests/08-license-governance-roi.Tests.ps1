Set-StrictMode -Version Latest

Describe 'License Governance and ROI Tracker solution' {
    BeforeAll {
        $solutionRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
    }

    It 'has required configuration files' {
        Test-Path (Join-Path $solutionRoot 'config\default-config.json') | Should -BeTrue
        Test-Path (Join-Path $solutionRoot 'config\baseline.json') | Should -BeTrue
        Test-Path (Join-Path $solutionRoot 'config\recommended.json') | Should -BeTrue
        Test-Path (Join-Path $solutionRoot 'config\regulated.json') | Should -BeTrue
    }

    It 'has required documentation files' {
        Test-Path (Join-Path $solutionRoot 'docs\architecture.md') | Should -BeTrue
        Test-Path (Join-Path $solutionRoot 'docs\deployment-guide.md') | Should -BeTrue
        Test-Path (Join-Path $solutionRoot 'docs\evidence-export.md') | Should -BeTrue
        Test-Path (Join-Path $solutionRoot 'docs\prerequisites.md') | Should -BeTrue
        Test-Path (Join-Path $solutionRoot 'docs\troubleshooting.md') | Should -BeTrue
    }

    It 'Deploy-Solution.ps1 has comment-based help' {
        $scriptPath = Join-Path $solutionRoot 'scripts\Deploy-Solution.ps1'
        Test-Path $scriptPath | Should -BeTrue
        (Get-Help $scriptPath -ErrorAction Stop).Synopsis | Should -Match 'deployment manifest'
    }

    It 'Monitor-Compliance.ps1 accepts ConfigurationTier parameter' {
        $scriptPath = Join-Path $solutionRoot 'scripts\Monitor-Compliance.ps1'
        $command = Get-Command $scriptPath -ErrorAction Stop
        $command.Parameters.Keys | Should -Contain 'ConfigurationTier'
    }

    It 'Export-Evidence.ps1 references the correct solution code' {
        $scriptPath = Join-Path $solutionRoot 'scripts\Export-Evidence.ps1'
        (Get-Content -Path $scriptPath -Raw) | Should -Match "-SolutionCode 'LGR'"
    }

    It 'default-config.json contains the expected controls' {
        $config = Get-Content -Path (Join-Path $solutionRoot 'config\default-config.json') -Raw | ConvertFrom-Json
        $config.controls | Should -Contain '1.9'
        $config.controls | Should -Contain '4.5'
        $config.controls | Should -Contain '4.6'
        $config.controls | Should -Contain '4.8'
    }

    It 'regulated.json keeps evidenceRetentionDays at or above 365' {
        $config = Get-Content -Path (Join-Path $solutionRoot 'config\regulated.json') -Raw | ConvertFrom-Json
        $config.evidenceRetentionDays | Should -BeGreaterOrEqual 365
    }

    It 'baseline.json defines an inactivityThresholdDays property' {
        $config = Get-Content -Path (Join-Path $solutionRoot 'config\baseline.json') -Raw | ConvertFrom-Json
        $config.PSObject.Properties.Name | Should -Contain 'inactivityThresholdDays'
    }
}
