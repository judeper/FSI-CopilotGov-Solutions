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
        $script:expectedControls = @('1.16', '3.8')
        $script:defaultConfig = (Get-Content -Path (Join-Path $solutionRoot 'config\default-config.json') -Raw) | ConvertFrom-Json
        $script:baselineConfig = (Get-Content -Path (Join-Path $solutionRoot 'config\baseline.json') -Raw) | ConvertFrom-Json
        $script:recommendedConfig = (Get-Content -Path (Join-Path $solutionRoot 'config\recommended.json') -Raw) | ConvertFrom-Json
        $script:regulatedConfig = (Get-Content -Path (Join-Path $solutionRoot 'config\regulated.json') -Raw) | ConvertFrom-Json
    }

    It 'includes evidenceOutputs in default config' {
        @($script:defaultConfig.evidenceOutputs).Count | Should -BeGreaterThan 0
    }

    It 'uses longer retention in the regulated tier' {
        [int]$script:regulatedConfig.evidenceRetentionDays | Should -BeGreaterThan ([int]$script:recommendedConfig.evidenceRetentionDays)
        [int]$script:recommendedConfig.evidenceRetentionDays | Should -BeGreaterThan ([int]$script:baselineConfig.evidenceRetentionDays)
    }

    It 'keeps the control mapping consistent across configs' {
        (@($script:defaultConfig.controls) -join ',') | Should -Be ($script:expectedControls -join ',')
        (@($script:baselineConfig.controls) -join ',') | Should -Be ($script:expectedControls -join ',')
        (@($script:recommendedConfig.controls) -join ',') | Should -Be ($script:expectedControls -join ',')
        (@($script:regulatedConfig.controls) -join ',') | Should -Be ($script:expectedControls -join ',')
    }

    It 'disables tuning in baseline tier' {
        $script:baselineConfig.tuningEnabled | Should -BeFalse
    }

    It 'enables tuning in recommended tier' {
        $script:recommendedConfig.tuningEnabled | Should -BeTrue
    }

    It 'enables tuning in regulated tier' {
        $script:regulatedConfig.tuningEnabled | Should -BeTrue
    }

    It 'requires approval workflow in recommended and regulated tiers' {
        $script:recommendedConfig.requireApprovalWorkflow | Should -BeTrue
        $script:regulatedConfig.requireApprovalWorkflow | Should -BeTrue
    }

    It 'requires owner attestation only in regulated tier' {
        $script:baselineConfig.requireOwnerAttestation | Should -BeFalse
        $script:recommendedConfig.requireOwnerAttestation | Should -BeFalse
        $script:regulatedConfig.requireOwnerAttestation | Should -BeTrue
    }

    It 'includes all evidence outputs in tier configs' {
        @($script:baselineConfig.evidenceOutputs) | Should -Contain 'tuning-requests'
        @($script:baselineConfig.evidenceOutputs) | Should -Contain 'model-inventory'
        @($script:baselineConfig.evidenceOutputs) | Should -Contain 'risk-assessments'
    }

    It 'includes required framework IDs in default config' {
        @($script:defaultConfig.framework_ids) | Should -Contain 'glba-501b'
        @($script:defaultConfig.framework_ids) | Should -Contain 'occ-2011-12'
        @($script:defaultConfig.framework_ids) | Should -Contain 'sr-11-7'
        @($script:defaultConfig.framework_ids) | Should -Contain 'interagency-ai-guidance'
        @($script:defaultConfig.framework_ids) | Should -Contain 'eu-ai-act'
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
        $script:readmeContent = Get-Content -Path (Join-Path (Join-Path $PSScriptRoot '..') 'README.md') -Raw
    }

    It 'contains required sections' {
        $script:readmeContent | Should -Match '## Overview'
        $script:readmeContent | Should -Match '## Scope Boundaries'
        $script:readmeContent | Should -Match '## Related Controls'
        $script:readmeContent | Should -Match '## Prerequisites'
        $script:readmeContent | Should -Match '## Deployment'
        $script:readmeContent | Should -Match '## Evidence Export'
        $script:readmeContent | Should -Match '## Regulatory Alignment'
    }

    It 'contains the standardized status line' {
        $script:readmeContent | Should -Match 'Status:.*Documentation-first scaffold.*Version:.*v0\.1\.4.*Priority:.*P1.*Track:.*A'
    }

    It 'contains the disclaimer banner' {
        $script:readmeContent | Should -Match 'Documentation-first repository'
        $script:readmeContent | Should -Match 'disclaimer\.md'
        $script:readmeContent | Should -Match 'documentation-vs-runnable-assets-guide\.md'
    }

    It 'does not contain overstated compliance language' {
        $script:readmeContent | Should -Not -Match 'ensures compliance'
        $script:readmeContent | Should -Not -Match 'guarantees'
        $script:readmeContent | Should -Not -Match 'will prevent'
        $script:readmeContent | Should -Not -Match 'eliminates risk'
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
