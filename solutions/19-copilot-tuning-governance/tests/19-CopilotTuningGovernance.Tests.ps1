Describe 'Solution structure' {
    It 'includes required solution files' {
        $solutionRoot = Join-Path $PSScriptRoot '..'
        $requiredPaths = @(
            'README.md',
            'CHANGELOG.md',
            'DELIVERY-CHECKLIST.md',
            'docs\architecture.md',
            'docs\deployment-guide.md',
            'docs\evidence-export.md',
            'docs\prerequisites.md',
            'docs\troubleshooting.md',
            'config\default-config.json',
            'config\baseline.json',
            'config\recommended.json',
            'config\regulated.json',
            'scripts\Deploy-Solution.ps1',
            'scripts\Monitor-Compliance.ps1',
            'scripts\Export-Evidence.ps1',
            'tests\19-CopilotTuningGovernance.Tests.ps1'
        )

        foreach ($relativePath in $requiredPaths) {
            Test-Path -Path (Join-Path $solutionRoot $relativePath) | Should -BeTrue
        }
    }
}

Describe 'Configuration content' {
    BeforeAll {
        $solutionRoot = Join-Path $PSScriptRoot '..'
        $expectedControls = @('1.16', '3.8')
        $defaultConfig = (Get-Content -Path (Join-Path $solutionRoot 'config\default-config.json') -Raw) | ConvertFrom-Json
        $baselineConfig = (Get-Content -Path (Join-Path $solutionRoot 'config\baseline.json') -Raw) | ConvertFrom-Json
        $recommendedConfig = (Get-Content -Path (Join-Path $solutionRoot 'config\recommended.json') -Raw) | ConvertFrom-Json
        $regulatedConfig = (Get-Content -Path (Join-Path $solutionRoot 'config\regulated.json') -Raw) | ConvertFrom-Json
    }

    It 'includes evidenceOutputs in default config' {
        @($defaultConfig.evidenceOutputs).Count | Should -BeGreaterThan 0
    }

    It 'uses longer retention in the regulated tier' {
        [int]$regulatedConfig.evidenceRetentionDays | Should -BeGreaterThan ([int]$recommendedConfig.evidenceRetentionDays)
        [int]$recommendedConfig.evidenceRetentionDays | Should -BeGreaterThan ([int]$baselineConfig.evidenceRetentionDays)
    }

    It 'keeps the control mapping consistent across configs' {
        (@($defaultConfig.controls) -join ',') | Should -Be ($expectedControls -join ',')
        (@($baselineConfig.controls) -join ',') | Should -Be ($expectedControls -join ',')
        (@($recommendedConfig.controls) -join ',') | Should -Be ($expectedControls -join ',')
        (@($regulatedConfig.controls) -join ',') | Should -Be ($expectedControls -join ',')
    }

    It 'disables tuning in baseline tier' {
        $baselineConfig.tuningEnabled | Should -BeFalse
    }

    It 'enables tuning in recommended tier' {
        $recommendedConfig.tuningEnabled | Should -BeTrue
    }

    It 'enables tuning in regulated tier' {
        $regulatedConfig.tuningEnabled | Should -BeTrue
    }

    It 'requires approval workflow in recommended and regulated tiers' {
        $recommendedConfig.requireApprovalWorkflow | Should -BeTrue
        $regulatedConfig.requireApprovalWorkflow | Should -BeTrue
    }

    It 'requires owner attestation only in regulated tier' {
        $baselineConfig.requireOwnerAttestation | Should -BeFalse
        $recommendedConfig.requireOwnerAttestation | Should -BeFalse
        $regulatedConfig.requireOwnerAttestation | Should -BeTrue
    }

    It 'includes all evidence outputs in tier configs' {
        @($baselineConfig.evidenceOutputs) | Should -Contain 'tuning-requests'
        @($baselineConfig.evidenceOutputs) | Should -Contain 'model-inventory'
        @($baselineConfig.evidenceOutputs) | Should -Contain 'risk-assessments'
    }

    It 'includes required framework IDs in default config' {
        @($defaultConfig.framework_ids) | Should -Contain 'glba-501b'
        @($defaultConfig.framework_ids) | Should -Contain 'occ-2011-12'
        @($defaultConfig.framework_ids) | Should -Contain 'sr-11-7'
        @($defaultConfig.framework_ids) | Should -Contain 'interagency-ai-guidance'
        @($defaultConfig.framework_ids) | Should -Contain 'eu-ai-act'
    }
}

Describe 'Script syntax validation' {
    It 'parses all solution scripts without syntax errors' {
        $solutionRoot = Join-Path $PSScriptRoot '..'
        $scriptPaths = @(
            (Join-Path $solutionRoot 'scripts\Deploy-Solution.ps1'),
            (Join-Path $solutionRoot 'scripts\Monitor-Compliance.ps1'),
            (Join-Path $solutionRoot 'scripts\Export-Evidence.ps1')
        )

        foreach ($scriptPath in $scriptPaths) {
            $tokens = $null
            $errors = $null
            $ast = [System.Management.Automation.Language.Parser]::ParseFile($scriptPath, [ref]$tokens, [ref]$errors)

            $ast | Should -Not -BeNullOrEmpty
            @($errors).Count | Should -Be 0
        }
    }
}

Describe 'README content' {
    BeforeAll {
        $readmeContent = Get-Content -Path (Join-Path (Join-Path $PSScriptRoot '..') 'README.md') -Raw
    }

    It 'contains required sections' {
        $readmeContent | Should -Match '## Overview'
        $readmeContent | Should -Match '## Scope Boundaries'
        $readmeContent | Should -Match '## Related Controls'
        $readmeContent | Should -Match '## Prerequisites'
        $readmeContent | Should -Match '## Deployment'
        $readmeContent | Should -Match '## Evidence Export'
        $readmeContent | Should -Match '## Regulatory Alignment'
    }

    It 'contains the standardized status line' {
        $readmeContent | Should -Match 'Status:.*Documentation-first scaffold.*Version:.*v0\.1\.0.*Priority:.*P1.*Track:.*A'
    }

    It 'contains the disclaimer banner' {
        $readmeContent | Should -Match 'Documentation-first repository'
        $readmeContent | Should -Match 'disclaimer\.md'
        $readmeContent | Should -Match 'documentation-vs-runnable-assets-guide\.md'
    }

    It 'does not contain overstated compliance language' {
        $readmeContent | Should -Not -Match 'ensures compliance'
        $readmeContent | Should -Not -Match 'guarantees'
        $readmeContent | Should -Not -Match 'will prevent'
        $readmeContent | Should -Not -Match 'eliminates risk'
    }
}

Describe 'Evidence types' {
    It 'documents all expected evidence outputs' {
        $evidenceDoc = Get-Content -Path (Join-Path (Join-Path $PSScriptRoot '..') 'docs\evidence-export.md') -Raw
        $evidenceDoc | Should -Match 'tuning-requests'
        $evidenceDoc | Should -Match 'model-inventory'
        $evidenceDoc | Should -Match 'risk-assessments'
    }
}
