<#
.SYNOPSIS
Validates Copilot Interaction Audit Trail Manager solution assets.

.DESCRIPTION
Pester tests that confirm required ATM documentation, configuration, and script content are present and syntactically valid.
#>
Describe 'Copilot Interaction Audit Trail Manager solution' {
    BeforeAll {
        $solutionRoot = Split-Path -Path $PSScriptRoot -Parent
        $configRoot = Join-Path $solutionRoot 'config'
        $script:docsRoot = Join-Path $solutionRoot 'docs'
        $scriptsRoot = Join-Path $solutionRoot 'scripts'

        $script:defaultConfigPath = Join-Path $configRoot 'default-config.json'
        $script:regulatedConfigPath = Join-Path $configRoot 'regulated.json'
        $script:deployScriptPath = Join-Path $scriptsRoot 'Deploy-Solution.ps1'
        $script:monitorScriptPath = Join-Path $scriptsRoot 'Monitor-Compliance.ps1'
        $script:exportScriptPath = Join-Path $scriptsRoot 'Export-Evidence.ps1'
        $script:labContractPath = Join-Path $solutionRoot 'lab\06-audit-trail-manager.lab.json'
    }

    It 'has required configuration files' {
        @(
            (Join-Path $configRoot 'default-config.json'),
            (Join-Path $configRoot 'baseline.json'),
            (Join-Path $configRoot 'recommended.json'),
            (Join-Path $configRoot 'regulated.json')
        ) | ForEach-Object {
            Test-Path $_ | Should -BeTrue
        }
    }

    It 'has required documentation files' {
        @(
            (Join-Path $script:docsRoot 'architecture.md'),
            (Join-Path $script:docsRoot 'deployment-guide.md'),
            (Join-Path $script:docsRoot 'evidence-export.md'),
            (Join-Path $script:docsRoot 'prerequisites.md'),
            (Join-Path $script:docsRoot 'troubleshooting.md')
        ) | ForEach-Object {
            Test-Path $_ | Should -BeTrue
        }
    }

    It 'has top-level documentation files' {
        @(
            (Join-Path $solutionRoot 'README.md'),
            (Join-Path $solutionRoot 'CHANGELOG.md'),
            (Join-Path $solutionRoot 'DELIVERY-CHECKLIST.md')
        ) | ForEach-Object {
            Test-Path $_ | Should -BeTrue
        }
    }

    It 'has the lab validation contract file' {
        Test-Path $script:labContractPath | Should -BeTrue
    }

    It 'default-config.json has required fields' {
        $config = Get-Content -Path $script:defaultConfigPath -Raw | ConvertFrom-Json -Depth 20

        $config.solution | Should -Be '06-audit-trail-manager'
        $config.controls | Should -Contain '3.1'
        $config.defaults.retentionPeriods | Should -Not -BeNullOrEmpty
        $config.defaults.retentionPeriods.byRegulation.SEC_17a4 | Should -Be 2190
    }

    It 'regulated.json has evidence retention of at least 365 days' {
        $config = Get-Content -Path $script:regulatedConfigPath -Raw | ConvertFrom-Json -Depth 20
        [int]$config.evidenceRetentionDays | Should -BeGreaterOrEqual 365
    }

    It 'regulated.json documents a retention schedule above 365 days' {
        $config = Get-Content -Path $script:regulatedConfigPath -Raw | ConvertFrom-Json -Depth 20
        $config.retentionPeriods | Should -Not -BeNullOrEmpty
        [int]$config.retentionPeriods.defaultDays | Should -BeGreaterOrEqual 365
    }

    It 'has all solution scripts' {
        @($script:deployScriptPath, $script:monitorScriptPath, $script:exportScriptPath) | ForEach-Object {
            Test-Path $_ | Should -BeTrue
        }
    }

    It 'solution scripts pass PowerShell syntax validation' {
        foreach ($scriptPath in @($script:deployScriptPath, $script:monitorScriptPath, $script:exportScriptPath)) {
            $tokens = $null
            $errors = $null
            [void][System.Management.Automation.Language.Parser]::ParseFile($scriptPath, [ref]$tokens, [ref]$errors)
            $errors | Should -BeNullOrEmpty
        }
    }

    It 'Export-Evidence.ps1 references audit-log-completeness' {
        $content = Get-Content -Path $script:exportScriptPath -Raw
        $content | Should -Match 'audit-log-completeness'
    }

    It 'Monitor-Compliance.ps1 references required controls' {
        $content = Get-Content -Path $script:monitorScriptPath -Raw
        $content | Should -Match '3\.1'
        $content | Should -Match '3\.2'
        $content | Should -Match '3\.3'
    }

    It 'Deploy-Solution.ps1 mentions retention' {
        $content = Get-Content -Path $script:deployScriptPath -Raw
        $content | Should -Match '(?i)retention'
    }

    It 'Export-Evidence.ps1 supports WhatIf without writing artifacts' {
        $outputPath = Join-Path $solutionRoot ("artifacts\test-output\whatif-{0}" -f ([guid]::NewGuid().ToString('N')))

        try {
            $result = & $script:exportScriptPath `
                -ConfigurationTier baseline `
                -OutputPath $outputPath `
                -PeriodStart ([datetime]'2026-06-01') `
                -PeriodEnd ([datetime]'2026-06-30') `
                -TenantId 'not-specified' `
                -WhatIf

            $result | Should -BeNullOrEmpty
            Test-Path $outputPath | Should -BeFalse
        }
        finally {
            if (Test-Path $outputPath) {
                Remove-Item -Path $outputPath -Recurse -Force
            }
        }
    }

    It 'writes package-relative artifact paths while returning absolute package metadata' {
        $outputPath = Join-Path $solutionRoot ("artifacts\test-output\portable-{0}" -f ([guid]::NewGuid().ToString('N')))

        try {
            $result = & $script:exportScriptPath `
                -ConfigurationTier baseline `
                -OutputPath $outputPath `
                -PeriodStart ([datetime]'2026-06-01') `
                -PeriodEnd ([datetime]'2026-06-30') `
                -TenantId 'not-specified'

            [System.IO.Path]::IsPathRooted([string]$result.PackagePath) | Should -BeTrue
            @($result.ArtifactPaths) | Should -Not -BeNullOrEmpty
            foreach ($artifactPath in @($result.ArtifactPaths)) {
                [System.IO.Path]::IsPathRooted([string]$artifactPath) | Should -BeTrue
            }

            $package = Get-Content -Path $result.PackagePath -Raw | ConvertFrom-Json -Depth 20
            @($package.artifacts) | Should -Not -BeNullOrEmpty
            $packageDirectory = Split-Path -Path $result.PackagePath -Parent

            foreach ($artifact in @($package.artifacts)) {
                [System.IO.Path]::IsPathRooted([string]$artifact.path) | Should -BeFalse
                [string]$artifact.path | Should -Not -Match '[\\/]'
                Test-Path (Join-Path $packageDirectory ([string]$artifact.path)) | Should -BeTrue
            }
        }
        finally {
            if (Test-Path $outputPath) {
                Remove-Item -Path $outputPath -Recurse -Force
            }
        }
    }

    It 'derives overall status from control statuses and not retention gap count only' {
        $outputPath = Join-Path $solutionRoot ("artifacts\test-output\status-{0}" -f ([guid]::NewGuid().ToString('N')))
        $originalConfig = Get-Content -Path $script:regulatedConfigPath -Raw

        try {
            $config = $originalConfig | ConvertFrom-Json -Depth 20
            $config.powerAutomate.exceptionAlertsEnabled = $false
            $updatedConfig = $config | ConvertTo-Json -Depth 20
            [System.IO.File]::WriteAllText($script:regulatedConfigPath, $updatedConfig, [System.Text.UTF8Encoding]::new($false))

            $result = & $script:exportScriptPath `
                -ConfigurationTier regulated `
                -OutputPath $outputPath `
                -PeriodStart ([datetime]'2026-06-01') `
                -PeriodEnd ([datetime]'2026-06-30') `
                -TenantId 'not-specified'

            $package = Get-Content -Path $result.PackagePath -Raw | ConvertFrom-Json -Depth 20
            $control312 = @($package.controls | Where-Object { $_.controlId -eq '3.12' })[0]

            $control312.status | Should -Be 'monitor-only'
            $package.summary.overallStatus | Should -Be 'monitor-only'
            $package.summary.findingCount | Should -Be 0
        }
        finally {
            [System.IO.File]::WriteAllText($script:regulatedConfigPath, $originalConfig, [System.Text.UTF8Encoding]::new($false))
            if (Test-Path $outputPath) {
                Remove-Item -Path $outputPath -Recurse -Force
            }
        }
    }
}