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
            'config\risk-thresholds.json',
            'config\remediation-policy.json',
            'config\baseline.json',
            'config\recommended.json',
            'config\regulated.json',
            'scripts\Get-ItemLevelPermissions.ps1',
            'scripts\Export-OversharedItems.ps1',
            'scripts\Invoke-BulkRemediation.ps1',
            'scripts\Deploy-Solution.ps1',
            'scripts\Monitor-Compliance.ps1',
            'scripts\Export-Evidence.ps1',
            'tests\16-item-level-oversharing-scanner.Tests.ps1'
        )

        foreach ($relativePath in $requiredPaths) {
            Test-Path -Path (Join-Path $solutionRoot $relativePath) | Should -BeTrue
        }
    }
}

Describe 'Configuration content' {
    BeforeAll {
        $solutionRoot = Join-Path $PSScriptRoot '..'
        $script:expectedControls = @('1.2', '1.3', '1.4', '1.6', '2.5')
        $script:defaultConfig = (Get-Content -Path (Join-Path $solutionRoot 'config\default-config.json') -Raw) | ConvertFrom-Json
        $script:baselineConfig = (Get-Content -Path (Join-Path $solutionRoot 'config\baseline.json') -Raw) | ConvertFrom-Json
        $script:recommendedConfig = (Get-Content -Path (Join-Path $solutionRoot 'config\recommended.json') -Raw) | ConvertFrom-Json
        $script:regulatedConfig = (Get-Content -Path (Join-Path $solutionRoot 'config\regulated.json') -Raw) | ConvertFrom-Json
    }

    It 'includes riskThresholds in default config' {
        $script:defaultConfig.riskThresholds.high | Should -BeGreaterThan 0
        $script:defaultConfig.riskThresholds.medium | Should -BeGreaterThan 0
        $script:defaultConfig.riskThresholds.low | Should -Be 0
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

    It 'includes evidenceOutputs in all tier configs' {
        $expectedOutputs = @('item-oversharing-findings', 'risk-scored-report', 'remediation-actions')
        (@($script:baselineConfig.evidenceOutputs) -join ',') | Should -Be ($expectedOutputs -join ',')
        (@($script:recommendedConfig.evidenceOutputs) -join ',') | Should -Be ($expectedOutputs -join ',')
        (@($script:regulatedConfig.evidenceOutputs) -join ',') | Should -Be ($expectedOutputs -join ',')
    }

    It 'validates risk-thresholds.json is valid JSON' {
        $riskThresholds = (Get-Content -Path (Join-Path $solutionRoot 'config\risk-thresholds.json') -Raw) | ConvertFrom-Json
        $riskThresholds | Should -Not -BeNullOrEmpty
        $riskThresholds.baseRiskScores | Should -Not -BeNullOrEmpty
        $riskThresholds.contentTypeWeights | Should -Not -BeNullOrEmpty
    }

    It 'validates remediation-policy.json is valid JSON' {
        $policy = (Get-Content -Path (Join-Path $solutionRoot 'config\remediation-policy.json') -Raw) | ConvertFrom-Json
        $policy | Should -Not -BeNullOrEmpty
        $policy.HIGH.mode | Should -Be 'approval-gate'
        $policy.autoRemediationEnabled | Should -Be $false
    }
}

Describe 'Script syntax validation' {
    It 'parses all solution scripts without syntax errors' {
        $solutionRoot = Join-Path $PSScriptRoot '..'
        $scriptPaths = @(
            (Join-Path $solutionRoot 'scripts\Get-ItemLevelPermissions.ps1'),
            (Join-Path $solutionRoot 'scripts\Export-OversharedItems.ps1'),
            (Join-Path $solutionRoot 'scripts\Invoke-BulkRemediation.ps1'),
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

Describe 'Dependency declaration' {
    It 'references 02-oversharing-risk-assessment in the deployment guide' {
        $deploymentGuide = Get-Content -Path (Join-Path (Join-Path $PSScriptRoot '..') 'docs\deployment-guide.md') -Raw
        $deploymentGuide | Should -Match '02-oversharing-risk-assessment'
    }
}

Describe 'Evidence types' {
    It 'documents all expected evidence outputs' {
        $evidenceDoc = Get-Content -Path (Join-Path (Join-Path $PSScriptRoot '..') 'docs\evidence-export.md') -Raw
        $evidenceDoc | Should -Match 'item-oversharing-findings'
        $evidenceDoc | Should -Match 'risk-scored-report'
        $evidenceDoc | Should -Match 'remediation-actions'
    }
}

Describe 'README content' {
    BeforeAll {
        $script:readmeContent = Get-Content -Path (Join-Path (Join-Path $PSScriptRoot '..') 'README.md') -Raw
    }

    It 'includes required sections' {
        $requiredSections = @(
            '## Overview',
            '## Scope Boundaries',
            '## Related Controls',
            '## Prerequisites',
            '## Deployment',
            '## Evidence Export',
            '## Regulatory Alignment'
        )

        foreach ($section in $requiredSections) {
            $escaped = [regex]::Escape($section)
            $script:readmeContent | Should -Match $escaped
        }
    }

    It 'includes the standardized status line' {
        $script:readmeContent | Should -Match 'Status:.*Documentation-first scaffold'
    }

    It 'includes the disclaimer banner' {
        $script:readmeContent | Should -Match 'Documentation-first repository'
    }
}

Describe 'Behavioral safeguards' {
    BeforeAll {
        $script:solutionRoot = Join-Path $PSScriptRoot '..'
        $script:repoRoot = (Resolve-Path (Join-Path $script:solutionRoot '..\..')).Path
        $script:scoreScript = Join-Path $script:solutionRoot 'scripts\Export-OversharedItems.ps1'
        $script:remediationScript = Join-Path $script:solutionRoot 'scripts\Invoke-BulkRemediation.ps1'
        $script:evidenceScript = Join-Path $script:solutionRoot 'scripts\Export-Evidence.ps1'
        Import-Module (Join-Path $script:repoRoot 'scripts\common\EvidenceExport.psm1') -Force
    }

    It 'forces AnyoneLink findings to HIGH risk even when thresholds would otherwise classify lower' {
        $scanPath = Join-Path $TestDrive 'item-permissions.csv'
        $configPath = Join-Path $TestDrive 'risk-thresholds.json'
        $outputPath = Join-Path $TestDrive 'scored'

        @(
            [pscustomobject]@{
                SiteUrl = 'https://contoso.sharepoint.com/sites/sample'
                LibraryName = 'Documents'
                ItemPath = '/sites/sample/Documents/test.txt'
                ItemType = 'File'
                SharedWith = 'Anonymous'
                ShareType = 'AnyoneLink'
                SensitivityLabel = ''
                LastModified = '2026-07-13'
            }
        ) | Export-Csv -Path $scanPath -NoTypeInformation -Encoding UTF8

        @{
            baseRiskScores = @{
                AnyoneLink = 10
                ExternalUser = 10
                OrgLinkEdit = 10
                BroadGroup = 10
            }
            contentTypeWeights = @{}
            riskThresholds = @{
                high = 999
                medium = 500
                low = 0
            }
        } | ConvertTo-Json -Depth 5 | Set-Content -Path $configPath -Encoding UTF8

        $null = & $script:scoreScript -InputPath $scanPath -OutputPath $outputPath -ConfigPath $configPath
        $report = @(Import-Csv -Path (Join-Path $outputPath 'risk-scored-report.csv') -Encoding UTF8)

        $report.Count | Should -Be 1
        $report[0].RiskTier | Should -Be 'HIGH'
    }

    It 'forces approval-gate behavior for all tiers when autoRemediationEnabled is false' {
        $inputPath = Join-Path $TestDrive 'risk-scored-report.csv'
        $configPath = Join-Path $TestDrive 'remediation-policy.json'
        $outputPath = Join-Path $TestDrive 'remediation-kill-switch'

        @(
            [pscustomobject]@{
                SiteUrl = 'https://contoso.sharepoint.com/sites/sample'
                ItemPath = '/sites/sample/Documents/medium.txt'
                ShareType = 'OrgLink'
                RiskTier = 'MEDIUM'
                WeightedScore = '55'
            }
        ) | Export-Csv -Path $inputPath -NoTypeInformation -Encoding UTF8

        @{
            HIGH = @{ mode = 'auto-remediate' }
            MEDIUM = @{ mode = 'auto-remediate' }
            LOW = @{ mode = 'auto-remediate' }
            autoRemediationEnabled = $false
        } | ConvertTo-Json -Depth 5 | Set-Content -Path $configPath -Encoding UTF8

        $result = & $script:remediationScript -InputPath $inputPath -OutputPath $outputPath -ConfigPath $configPath
        $pending = @((Get-Content -Path (Join-Path $outputPath 'pending-approvals.json') -Raw -Encoding UTF8) | ConvertFrom-Json)
        $log = @((Get-Content -Path (Join-Path $outputPath 'remediation-log.json') -Raw -Encoding UTF8) | ConvertFrom-Json)

        $result.PendingApprovals | Should -Be 1
        $pending.Count | Should -Be 1
        $log.Count | Should -Be 1
        $log[0].status | Should -Be 'pending-approval'
        $log[0].notes | Should -Match 'autoRemediationEnabled is false or absent'
    }

    It 'treats missing autoRemediationEnabled as disabled and forces approval-gate behavior' {
        $inputPath = Join-Path $TestDrive 'risk-scored-report-missing-kill-switch.csv'
        $configPath = Join-Path $TestDrive 'remediation-policy-missing-kill-switch.json'
        $outputPath = Join-Path $TestDrive 'remediation-missing-kill-switch'

        @(
            [pscustomobject]@{
                SiteUrl = 'https://contoso.sharepoint.com/sites/sample'
                ItemPath = '/sites/sample/Documents/medium-missing-switch.txt'
                ShareType = 'OrgLink'
                RiskTier = 'MEDIUM'
                WeightedScore = '55'
            }
        ) | Export-Csv -Path $inputPath -NoTypeInformation -Encoding UTF8

        @{
            HIGH = @{ mode = 'auto-remediate' }
            MEDIUM = @{ mode = 'auto-remediate' }
            LOW = @{ mode = 'auto-remediate' }
        } | ConvertTo-Json -Depth 5 | Set-Content -Path $configPath -Encoding UTF8

        $result = & $script:remediationScript -InputPath $inputPath -OutputPath $outputPath -ConfigPath $configPath
        $pending = @((Get-Content -Path (Join-Path $outputPath 'pending-approvals.json') -Raw -Encoding UTF8) | ConvertFrom-Json)
        $log = @((Get-Content -Path (Join-Path $outputPath 'remediation-log.json') -Raw -Encoding UTF8) | ConvertFrom-Json)

        $result.GlobalAutoRemediationEnabled | Should -BeFalse
        $pending.Count | Should -Be 1
        $log[0].status | Should -Be 'pending-approval'
        $log[0].notes | Should -Match 'autoRemediationEnabled is false or absent'
    }

    It 'never auto-remediates HIGH risk items even when HIGH mode is auto-remediate' {
        $inputPath = Join-Path $TestDrive 'risk-scored-report-high.csv'
        $configPath = Join-Path $TestDrive 'remediation-policy-high.json'
        $outputPath = Join-Path $TestDrive 'remediation-high'

        @(
            [pscustomobject]@{
                SiteUrl = 'https://contoso.sharepoint.com/sites/sample'
                ItemPath = '/sites/sample/Documents/high.txt'
                ShareType = 'ExternalUser'
                RiskTier = 'HIGH'
                WeightedScore = '95'
            }
        ) | Export-Csv -Path $inputPath -NoTypeInformation -Encoding UTF8

        @{
            HIGH = @{ mode = 'auto-remediate' }
            MEDIUM = @{ mode = 'auto-remediate' }
            LOW = @{ mode = 'auto-remediate' }
            autoRemediationEnabled = $true
        } | ConvertTo-Json -Depth 5 | Set-Content -Path $configPath -Encoding UTF8

        $result = & $script:remediationScript -InputPath $inputPath -OutputPath $outputPath -ConfigPath $configPath
        $pending = @((Get-Content -Path (Join-Path $outputPath 'pending-approvals.json') -Raw -Encoding UTF8) | ConvertFrom-Json)
        $log = @((Get-Content -Path (Join-Path $outputPath 'remediation-log.json') -Raw -Encoding UTF8) | ConvertFrom-Json)

        $result.PendingApprovals | Should -Be 1
        $pending.Count | Should -Be 1
        $log[0].status | Should -Be 'pending-approval'
        $log[0].notes | Should -Match 'HIGH risk always requires approval'
    }

    It 'routes AnyoneLink items to HIGH approval handling when risk tier is lower in input' {
        $inputPath = Join-Path $TestDrive 'risk-scored-report-anyone.csv'
        $configPath = Join-Path $TestDrive 'remediation-policy-anyone.json'
        $outputPath = Join-Path $TestDrive 'remediation-anyone'

        @(
            [pscustomobject]@{
                SiteUrl = 'https://contoso.sharepoint.com/sites/sample'
                ItemPath = '/sites/sample/Documents/anyone.txt'
                ShareType = 'AnyoneLink'
                RiskTier = 'LOW'
                WeightedScore = '10'
            }
        ) | Export-Csv -Path $inputPath -NoTypeInformation -Encoding UTF8

        @{
            HIGH = @{ mode = 'auto-remediate' }
            MEDIUM = @{ mode = 'approval-gate' }
            LOW = @{ mode = 'auto-remediate' }
            autoRemediationEnabled = $true
        } | ConvertTo-Json -Depth 5 | Set-Content -Path $configPath -Encoding UTF8

        $null = & $script:remediationScript -InputPath $inputPath -OutputPath $outputPath -ConfigPath $configPath
        $pending = @((Get-Content -Path (Join-Path $outputPath 'pending-approvals.json') -Raw -Encoding UTF8) | ConvertFrom-Json)
        $log = @((Get-Content -Path (Join-Path $outputPath 'remediation-log.json') -Raw -Encoding UTF8) | ConvertFrom-Json)

        $pending.Count | Should -Be 1
        $log[0].riskTier | Should -Be 'HIGH'
        $log[0].status | Should -Be 'pending-approval'
    }

    It 'uses WhatIf to avoid auto-remediation mutation and records planned status' {
        $inputPath = Join-Path $TestDrive 'risk-scored-report-whatif.csv'
        $configPath = Join-Path $TestDrive 'remediation-policy-whatif.json'
        $outputPath = Join-Path $TestDrive 'remediation-whatif'

        @(
            [pscustomobject]@{
                SiteUrl = 'https://contoso.sharepoint.com/sites/sample'
                ItemPath = '/sites/sample/Documents/low.txt'
                ShareType = 'BroadGroup'
                RiskTier = 'LOW'
                WeightedScore = '20'
            }
        ) | Export-Csv -Path $inputPath -NoTypeInformation -Encoding UTF8

        @{
            HIGH = @{ mode = 'approval-gate' }
            MEDIUM = @{ mode = 'approval-gate' }
            LOW = @{ mode = 'auto-remediate' }
            autoRemediationEnabled = $true
        } | ConvertTo-Json -Depth 5 | Set-Content -Path $configPath -Encoding UTF8

        $result = & $script:remediationScript -InputPath $inputPath -OutputPath $outputPath -ConfigPath $configPath -WhatIf
        $pending = @((Get-Content -Path (Join-Path $outputPath 'pending-approvals.json') -Raw -Encoding UTF8) | ConvertFrom-Json)
        $log = @((Get-Content -Path (Join-Path $outputPath 'remediation-log.json') -Raw -Encoding UTF8) | ConvertFrom-Json)

        $pending.Count | Should -Be 0
        $log.Count | Should -Be 1
        $log[0].status | Should -Be 'planned-whatif'
        [string]$log[0].executedAt | Should -Be ''
        $result.PlannedNoChange | Should -Be 1
    }

    It 'writes relative artifact paths and passes evidence hash/package round-trip validation' {
        $scanPath = Join-Path $TestDrive 'scan.csv'
        $scoredPath = Join-Path $TestDrive 'scored.csv'
        $remediationPath = Join-Path $TestDrive 'remediation-log.json'
        $evidenceOutputPath = Join-Path $TestDrive 'evidence'

        @(
            [pscustomobject]@{
                SiteUrl = 'https://contoso.sharepoint.com/sites/sample'
                LibraryName = 'Documents'
                ItemPath = '/sites/sample/Documents/overshared.docx'
                ItemType = 'File'
                SharedWith = 'Anonymous'
                ShareType = 'AnyoneLink'
                SensitivityLabel = 'Confidential'
                LastModified = '2026-07-13'
            }
        ) | Export-Csv -Path $scanPath -NoTypeInformation -Encoding UTF8

        @(
            [pscustomobject]@{
                SiteUrl = 'https://contoso.sharepoint.com/sites/sample'
                LibraryName = 'Documents'
                ItemPath = '/sites/sample/Documents/overshared.docx'
                ItemType = 'File'
                SharedWith = 'Anonymous'
                ShareType = 'AnyoneLink'
                SensitivityLabel = 'Confidential'
                LastModified = '2026-07-13'
                RiskTier = 'HIGH'
                BaseScore = '90'
                WeightedScore = '90'
                ContentCategory = 'general'
            }
        ) | Export-Csv -Path $scoredPath -NoTypeInformation -Encoding UTF8

        @(
            [pscustomobject]@{
                actionId = 'IOS-0001'
                siteUrl = 'https://contoso.sharepoint.com/sites/sample'
                itemPath = '/sites/sample/Documents/overshared.docx'
                shareType = 'AnyoneLink'
                riskTier = 'HIGH'
                action = 'Remove anonymous sharing link'
                status = 'pending-approval'
                approvalRequired = $true
                approvedBy = $null
                executedAt = $null
                notes = 'Awaiting approval.'
            }
        ) | ConvertTo-Json -Depth 5 | Set-Content -Path $remediationPath -Encoding UTF8

        $result = & $script:evidenceScript `
            -ConfigurationTier baseline `
            -TenantId '00000000-0000-0000-0000-000000000000' `
            -OutputPath $evidenceOutputPath `
            -ScanFindingsPath $scanPath `
            -ScoredReportPath $scoredPath `
            -RemediationLogPath $remediationPath

        [System.IO.Path]::IsPathRooted([string]$result.PackagePath) | Should -BeTrue
        $package = (Get-Content -Path $result.PackagePath -Raw -Encoding UTF8) | ConvertFrom-Json
        $absoluteArtifactPaths = @($package.artifacts | Where-Object { [System.IO.Path]::IsPathRooted([string]$_.path) })
        $absoluteArtifactPaths.Count | Should -Be 0

        $validation = Test-CopilotGovEvidencePackage -Path $result.PackagePath -ExpectedArtifacts @('item-oversharing-findings', 'risk-scored-report', 'remediation-actions')
        $validation.IsValid | Should -BeTrue
    }
}
