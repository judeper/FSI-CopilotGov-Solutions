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

    Context 'License-assignment staging safety' {
        BeforeAll {
            $script:newDependencyArtifact = {
                param([string]$Root)
                $depDir = Join-Path $Root ('dep-' + [guid]::NewGuid().ToString('N'))
                $null = New-Item -ItemType Directory -Path $depDir -Force
                $depPath = Join-Path $depDir 'readiness-evidence.json'
                @{
                    metadata = @{ solution = '01-copilot-readiness-scanner'; tier = 'recommended'; exportedAt = (Get-Date).ToString('o') }
                    summary  = @{ overallStatus = 'partial' }
                } | ConvertTo-Json -Depth 5 | Set-Content -Path $depPath -Encoding utf8
                return $depPath
            }
        }

        It 'previews (dry-run) license assignment by default without explicit staging confirmation' {
            $depPath = & $script:newDependencyArtifact $TestDrive
            $manifest = & $script:deployScriptPath -ConfigurationTier recommended -TenantId 'contoso.onmicrosoft.com' `
                -WaveNumber 0 -ReadinessArtifactPath $depPath -OutputPath (Join-Path $TestDrive 'stage-preview') `
                -TriggerLicenseAssignment -WarningAction SilentlyContinue | Select-Object -Last 1

            $manifest.licenseAssignment.mode | Should -Be 'preview'
            $manifest.licenseAssignment.dryRunByDefault | Should -BeTrue
            @($manifest.cohort | Where-Object { $_.assignmentState -ne 'manifest-only' }).Count | Should -Be 0
        }

        It 'stages assignment intents only when live staging is explicitly confirmed' {
            $depPath = & $script:newDependencyArtifact $TestDrive
            $manifest = & $script:deployScriptPath -ConfigurationTier recommended -TenantId 'contoso.onmicrosoft.com' `
                -WaveNumber 0 -ReadinessArtifactPath $depPath -OutputPath (Join-Path $TestDrive 'stage-confirmed') `
                -TriggerLicenseAssignment -ConfirmAssignmentIntentStaging -WarningAction SilentlyContinue | Select-Object -Last 1

            $manifest.licenseAssignment.mode | Should -Be 'staged'
            @($manifest.cohort | Where-Object { $_.assignmentState -eq 'pending-assignment' }).Count | Should -BeGreaterThan 0
        }

        It 'keeps assignment in preview under -WhatIf even when staging is confirmed' {
            $depPath = & $script:newDependencyArtifact $TestDrive
            $manifest = & $script:deployScriptPath -ConfigurationTier recommended -TenantId 'contoso.onmicrosoft.com' `
                -WaveNumber 0 -ReadinessArtifactPath $depPath -OutputPath (Join-Path $TestDrive 'stage-whatif') `
                -TriggerLicenseAssignment -ConfirmAssignmentIntentStaging -WhatIf -WarningAction SilentlyContinue | Select-Object -Last 1

            $manifest.licenseAssignment.mode | Should -Be 'preview'
        }

        It 'records skuPartNumber discovery and never a hardcoded SKU GUID' {
            $depPath = & $script:newDependencyArtifact $TestDrive
            $manifest = & $script:deployScriptPath -ConfigurationTier regulated -TenantId 'contoso.onmicrosoft.com' `
                -WaveNumber 0 -ReadinessArtifactPath $depPath -OutputPath (Join-Path $TestDrive 'stage-sku') `
                -TriggerLicenseAssignment -WarningAction SilentlyContinue | Select-Object -Last 1

            $manifest.licenseAssignment.skuPartNumber | Should -Be 'Microsoft_365_Copilot'
            $manifest.licenseAssignment.skuIdSource | Should -Be 'tenant-subscribedSkus-discovery'
            ($manifest.licenseAssignment | ConvertTo-Json -Depth 6) |
                Should -Not -Match '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}'
        }

        It 'always requires explicit confirmation before staging assignment intents' {
            $content = Get-Content -Path $script:deployScriptPath -Raw
            $content | Should -Match '\$stagingConfirmed\s*=\s*\$ConfirmAssignmentIntentStaging\.IsPresent'
            $content | Should -Not -Match '\$ConfirmAssignmentIntentStaging\.IsPresent\s*-or'
        }
    }

    It 'Export-Evidence.ps1 keeps package paths relative and caller paths absolute after relocation' {
        $repoRoot = (Resolve-Path (Join-Path $script:solutionRoot '..\..')).Path
        Import-Module (Join-Path $repoRoot 'scripts\common\EvidenceExport.psm1') -Force

        $outputPath = Join-Path $TestDrive 'portable-evidence'
        $result = & $script:exportScriptPath -ConfigurationTier baseline -OutputPath $outputPath
        [System.IO.Path]::IsPathRooted($result.Package.Path) | Should -BeTrue
        foreach ($artifact in @($result.Artifacts)) {
            [System.IO.Path]::IsPathRooted($artifact.Path) | Should -BeTrue
        }

        $package = Get-Content -Path $result.Package.Path -Raw | ConvertFrom-Json
        foreach ($artifact in @($package.artifacts)) {
            [System.IO.Path]::IsPathRooted($artifact.path) | Should -BeFalse
        }

        $relocatedPath = Join-Path $TestDrive 'portable-evidence-relocated'
        Move-Item -Path $outputPath -Destination $relocatedPath
        $validation = Test-CopilotGovEvidencePackage `
            -Path (Join-Path $relocatedPath '11-risk-tiered-rollout-evidence.json') `
            -ExpectedArtifacts @('wave-readiness-log', 'approval-history', 'rollout-health-dashboard')
        $validation.IsValid | Should -BeTrue -Because ($validation.Errors -join '; ')
    }

    It 'Export-Evidence.ps1 resolves relative output from the PowerShell provider location' {
        $originalProcessDirectory = [System.Environment]::CurrentDirectory
        Push-Location $TestDrive
        try {
            [System.Environment]::CurrentDirectory = $script:solutionRoot
            $result = & $script:exportScriptPath -ConfigurationTier baseline -OutputPath '.\provider-relative'
            (Split-Path -Parent $result.Package.Path) | Should -Be (Join-Path $TestDrive 'provider-relative')
        }
        finally {
            [System.Environment]::CurrentDirectory = $originalProcessDirectory
            Pop-Location
        }
    }
}
