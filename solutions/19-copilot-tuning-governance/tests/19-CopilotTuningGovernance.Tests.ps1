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

Describe 'Evidence export portability' {
    BeforeAll {
        $script:solutionRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
        $script:repoRoot = (Resolve-Path (Join-Path $script:solutionRoot '..\..')).Path
        Import-Module (Join-Path $script:repoRoot 'scripts\common\EvidenceExport.psm1') -Force
        $script:exportScript = Join-Path $script:solutionRoot 'scripts\Export-Evidence.ps1'
        $script:exportDir = Join-Path $TestDrive 'evidence'
        $script:exportResult = & $script:exportScript -ConfigurationTier regulated -TenantId 'lab-tenant' -OutputPath $script:exportDir
        $script:packagePath = Join-Path $script:exportDir '19-copilot-tuning-governance-evidence-package.json'
        $script:package = Get-Content $script:packagePath -Raw | ConvertFrom-Json -Depth 30
        $script:expectedArtifacts = @('tuning-requests', 'model-inventory', 'risk-assessments')
    }

    It 'records package-relative (non-rooted) artifact paths' {
        @($script:package.artifacts).Count | Should -BeGreaterThan 0
        foreach ($artifact in @($script:package.artifacts)) {
            [System.IO.Path]::IsPathRooted([string]$artifact.path) | Should -BeFalse -Because "artifact $($artifact.name) must use a package-relative path for relocation safety"
        }
    }

    It 'returns rooted artifact paths for callers' {
        @($script:exportResult.ArtifactPaths).Count | Should -BeGreaterThan 0
        foreach ($artifact in @($script:exportResult.ArtifactPaths)) {
            [System.IO.Path]::IsPathRooted([string]$artifact.path) | Should -BeTrue -Because "caller path for $($artifact.name) must remain directly usable"
            Test-Path -Path $artifact.path -PathType Leaf | Should -BeTrue
        }
    }

    It 'resolves relative OutputPath from the active PowerShell location instead of Environment.CurrentDirectory' {
        $originalLocation = (Get-Location).Path
        $originalCurrentDirectory = [System.Environment]::CurrentDirectory
        $psLocationRoot = Join-Path $TestDrive ("ps-location-{0}" -f [guid]::NewGuid().ToString('N'))
        $envCurrentDirectoryRoot = Join-Path $TestDrive ("env-cwd-{0}" -f [guid]::NewGuid().ToString('N'))
        $relativeOutputPath = "evidence-{0}" -f [guid]::NewGuid().ToString('N')
        $expectedOutputDirectory = Join-Path $psLocationRoot $relativeOutputPath
        $wrongOutputDirectory = Join-Path $envCurrentDirectoryRoot $relativeOutputPath

        $null = New-Item -Path $psLocationRoot -ItemType Directory -Force
        $null = New-Item -Path $envCurrentDirectoryRoot -ItemType Directory -Force

        try {
            Set-Location -LiteralPath $psLocationRoot
            [System.Environment]::CurrentDirectory = $envCurrentDirectoryRoot

            $result = & $script:exportScript -ConfigurationTier regulated -TenantId 'lab-tenant' -OutputPath $relativeOutputPath
            $resolvedExpectedOutput = (Resolve-Path -LiteralPath $expectedOutputDirectory).Path

            $result.EvidenceDirectory | Should -Be $resolvedExpectedOutput
            Test-Path -LiteralPath (Join-Path $expectedOutputDirectory '19-copilot-tuning-governance-evidence-package.json') | Should -BeTrue
            Test-Path -LiteralPath $wrongOutputDirectory | Should -BeFalse
        }
        finally {
            Set-Location -LiteralPath $originalLocation
            [System.Environment]::CurrentDirectory = $originalCurrentDirectory

            if (Test-Path -LiteralPath $expectedOutputDirectory) {
                Remove-Item -LiteralPath $expectedOutputDirectory -Recurse -Force
            }
            if (Test-Path -LiteralPath $wrongOutputDirectory) {
                Remove-Item -LiteralPath $wrongOutputDirectory -Recurse -Force
            }
            if (Test-Path -LiteralPath $psLocationRoot) {
                Remove-Item -LiteralPath $psLocationRoot -Recurse -Force
            }
            if (Test-Path -LiteralPath $envCurrentDirectoryRoot) {
                Remove-Item -LiteralPath $envCurrentDirectoryRoot -Recurse -Force
            }
        }
    }

    It 'remains valid after the evidence package is relocated' {
        $relocated = Join-Path $TestDrive 'relocated'
        Move-Item -Path $script:exportDir -Destination $relocated
        $relocatedPackage = Join-Path $relocated '19-copilot-tuning-governance-evidence-package.json'
        $result = Test-CopilotGovEvidencePackage -Path $relocatedPackage -ExpectedArtifacts $script:expectedArtifacts
        $result.IsValid | Should -BeTrue -Because ($result.Errors -join '; ')
    }
}

Describe 'Lab validation contract' {
    BeforeAll {
        $script:labContractPath = Join-Path (Join-Path $PSScriptRoot '..') 'lab\19-copilot-tuning-governance.lab.json'
        $script:labContract = if (Test-Path $script:labContractPath) {
            Get-Content -Path $script:labContractPath -Raw | ConvertFrom-Json -Depth 30
        }
        else {
            $null
        }
    }

    It 'ships a lab contract file for the solution' {
        Test-Path -Path $script:labContractPath | Should -BeTrue
    }

    It 'is read-only and detect-only (no mutations declared)' {
        @($script:labContract.mutations).Count | Should -Be 0
        foreach ($phase in @($script:labContract.execution.phases)) {
            foreach ($step in @($phase.steps)) {
                $step.mutationRef | Should -BeNullOrEmpty -Because "read-only lab steps must not reference a mutation"
            }
        }
    }

    It 'is scoped to US commercial-cloud Microsoft 365' {
        $script:labContract.scope.cloud | Should -Be 'm365-us-commercial'
        $script:labContract.scope.usCommercialOnly | Should -BeTrue
    }

    It 'covers the solution controls and required execution phases' {
        @($script:labContract.controls) | Should -Contain '1.16'
        @($script:labContract.controls) | Should -Contain '3.8'
        $phaseIds = @($script:labContract.execution.phases | ForEach-Object { $_.id })
        foreach ($required in @('setup', 'exercise', 'verify', 'cleanup')) {
            $phaseIds | Should -Contain $required
        }
    }
}
