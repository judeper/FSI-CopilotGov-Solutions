Describe 'DLP Policy Governance for Copilot scaffold' {
    It 'has required configuration files' {
        Test-Path (Join-Path $PSScriptRoot '..\config\default-config.json') | Should -BeTrue
        Test-Path (Join-Path $PSScriptRoot '..\config\baseline.json') | Should -BeTrue
        Test-Path (Join-Path $PSScriptRoot '..\config\recommended.json') | Should -BeTrue
        Test-Path (Join-Path $PSScriptRoot '..\config\regulated.json') | Should -BeTrue
    }

    It 'has required documentation files' {
        Test-Path (Join-Path $PSScriptRoot '..\docs\deployment-guide.md') | Should -BeTrue
        Test-Path (Join-Path $PSScriptRoot '..\docs\evidence-export.md') | Should -BeTrue
    }
}
