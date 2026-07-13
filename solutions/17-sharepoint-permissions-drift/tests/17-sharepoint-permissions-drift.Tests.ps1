BeforeAll {
    $script:solutionRoot = Join-Path $PSScriptRoot '..'
    $script:repoRoot = (Resolve-Path (Join-Path $script:solutionRoot '..\..')).Path
    $script:labContractPath = Join-Path $script:solutionRoot 'lab\17-sharepoint-permissions-drift.lab.json'

    function New-IsolatedSolutionSandbox {
        param(
            [string]$Name = 'sandbox'
        )

        $sandboxRoot = Join-Path $TestDrive $Name
        $sandboxSolutionsRoot = Join-Path $sandboxRoot 'solutions'
        $sandboxSolutionRoot = Join-Path $sandboxSolutionsRoot '17-sharepoint-permissions-drift'
        $sandboxScriptsRoot = Join-Path $sandboxRoot 'scripts'
        $sandboxCommonRoot = Join-Path $sandboxScriptsRoot 'common'

        $null = New-Item -ItemType Directory -Path $sandboxSolutionsRoot -Force
        $null = New-Item -ItemType Directory -Path $sandboxScriptsRoot -Force

        Copy-Item -Path $script:solutionRoot -Destination $sandboxSolutionRoot -Recurse -Force
        Copy-Item -Path (Join-Path $script:repoRoot 'scripts\common') -Destination $sandboxCommonRoot -Recurse -Force

        return $sandboxSolutionRoot
    }
}

Describe 'Solution 17 — SharePoint Permissions Drift Detection' {

    Describe 'Solution structure' {
        It 'includes required solution files' {
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
                'config\baseline-config.json',
                'config\auto-revert-policy.json',
                'lab\17-sharepoint-permissions-drift.lab.json',
                'scripts\Deploy-Solution.ps1',
                'scripts\Monitor-Compliance.ps1',
                'scripts\Export-Evidence.ps1',
                'scripts\New-PermissionsBaseline.ps1',
                'scripts\Invoke-DriftScan.ps1',
                'scripts\Invoke-DriftReversion.ps1',
                'scripts\Export-DriftEvidence.ps1'
            )

            foreach ($relativePath in $requiredPaths) {
                $fullPath = Join-Path $script:solutionRoot $relativePath
                Test-Path -Path $fullPath | Should -BeTrue -Because "required file '$relativePath' should exist"
            }
        }

        It 'includes Pester test file' {
            $testFiles = Get-ChildItem -Path (Join-Path $script:solutionRoot 'tests') -Filter '*.Tests.ps1'
            $testFiles.Count | Should -BeGreaterOrEqual 1
        }
    }

    Describe 'Configuration content' {
        It 'parses default-config.json as valid JSON' {
            $configPath = Join-Path $script:solutionRoot 'config\default-config.json'
            $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json
            $config | Should -Not -BeNullOrEmpty
            $config.solution | Should -Be '17-sharepoint-permissions-drift'
            $config.solutionCode | Should -Be 'SPD'
            $config.version | Should -Be 'v0.1.4'
        }

        It 'parses baseline-config.json as valid JSON' {
            $configPath = Join-Path $script:solutionRoot 'config\baseline-config.json'
            $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json
            $config | Should -Not -BeNullOrEmpty
            $config.scope | Should -Not -BeNullOrEmpty
        }

        It 'parses auto-revert-policy.json as valid JSON' {
            $configPath = Join-Path $script:solutionRoot 'config\auto-revert-policy.json'
            $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json
            $config | Should -Not -BeNullOrEmpty
            $config.reversionMode | Should -Be 'approval-gate'
            $config.autoRevertEnabled | Should -Be $false
        }

        It 'includes expected fields in all tier configs' {
            $tiers = @('baseline', 'recommended', 'regulated')
            foreach ($tier in $tiers) {
                $configPath = Join-Path $script:solutionRoot "config\$tier.json"
                $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json
                $config | Should -Not -BeNullOrEmpty -Because "tier config '$tier.json' should parse"
                $config.controls | Should -Not -BeNullOrEmpty -Because "tier config '$tier.json' should have controls"
                $config.evidenceOutputs | Should -Not -BeNullOrEmpty -Because "tier config '$tier.json' should have evidenceOutputs"
            }
        }

        It 'has increasing evidence retention across tiers' {
            $baselineConfig = Get-Content -Path (Join-Path $script:solutionRoot 'config\baseline.json') -Raw | ConvertFrom-Json
            $recommendedConfig = Get-Content -Path (Join-Path $script:solutionRoot 'config\recommended.json') -Raw | ConvertFrom-Json
            $regulatedConfig = Get-Content -Path (Join-Path $script:solutionRoot 'config\regulated.json') -Raw | ConvertFrom-Json

            $baselineConfig.evidenceRetentionDays | Should -BeLessThan $recommendedConfig.evidenceRetentionDays
            $recommendedConfig.evidenceRetentionDays | Should -BeLessThan $regulatedConfig.evidenceRetentionDays
        }
    }

    Describe 'Script syntax validation' {
        It 'parses all solution scripts without syntax errors' {
            $scriptFiles = Get-ChildItem -Path (Join-Path $script:solutionRoot 'scripts') -Filter '*.ps1'
            foreach ($script in $scriptFiles) {
                $errors = $null
                $tokens = $null
                $ast = [System.Management.Automation.Language.Parser]::ParseFile(
                    $script.FullName,
                    [ref]$tokens,
                    [ref]$errors
                )
                $ast | Should -Not -BeNullOrEmpty -Because "script '$($script.Name)' should parse successfully"
                @($errors).Count | Should -Be 0 -Because "script '$($script.Name)' should have no parse errors"
            }
        }
    }

    Describe 'Dependency declaration' {
        It 'references upstream solution in default-config.json' {
            $config = Get-Content -Path (Join-Path $script:solutionRoot 'config\default-config.json') -Raw | ConvertFrom-Json
            $config.upstreamDependency | Should -Be '02-oversharing-risk-assessment'
        }

        It 'references upstream solution in documentation' {
            $readme = Get-Content -Path (Join-Path $script:solutionRoot 'README.md') -Raw
            $readme | Should -Match '02-oversharing-risk-assessment'
        }
    }

    Describe 'Evidence types' {
        It 'documents all expected evidence outputs in default config' {
            $config = Get-Content -Path (Join-Path $script:solutionRoot 'config\default-config.json') -Raw | ConvertFrom-Json
            $config.evidenceOutputs | Should -Contain 'drift-report'
            $config.evidenceOutputs | Should -Contain 'baseline-snapshot'
            $config.evidenceOutputs | Should -Contain 'reversion-log'
        }
    }

    Describe 'README compliance' {
        BeforeAll {
            $script:readme = Get-Content -Path (Join-Path $script:solutionRoot 'README.md') -Raw
        }

        It 'includes the standardized status line' {
            $script:readme | Should -Match '\*\*Status:\*\* Documentation-first scaffold'
        }

        It 'includes the disclaimer banner' {
            $script:readme | Should -Match 'Documentation-first repository'
        }

        It 'includes Scope Boundaries section' {
            $script:readme | Should -Match '## Scope Boundaries'
        }

        It 'includes Related Controls section' {
            $script:readme | Should -Match '## Related Controls'
        }

        It 'includes Regulatory Alignment section' {
            $script:readme | Should -Match '## Regulatory Alignment'
        }

        It 'includes implementation handoff and lab contract sections' {
            $script:readme | Should -Match '## Implementation Handoff'
            $script:readme | Should -Match '## Lab Validation Contract'
        }

        It 'does not contain forbidden language' {
            $script:readme | Should -Not -Match 'ensures compliance'
            $script:readme | Should -Not -Match 'guarantees'
            $script:readme | Should -Not -Match 'will prevent'
            $script:readme | Should -Not -Match 'eliminates risk'
        }
    }

    Describe 'Lab validation contract' {
        It 'uses template binding with no mutations' {
            $contract = Get-Content -Path $script:labContractPath -Raw | ConvertFrom-Json -Depth 20

            $contract.solution.binding | Should -Be 'template'
            @($contract.mutations).Count | Should -Be 0
            @($contract.controls) | Should -Contain '1.2'
            @($contract.controls) | Should -Contain '1.4'
            @($contract.controls) | Should -Contain '1.6'
            @($contract.controls) | Should -Contain '2.5'
        }

        It 'documents SharePoint and Entra portal verification scope' {
            $contract = Get-Content -Path $script:labContractPath -Raw | ConvertFrom-Json -Depth 20
            @($contract.portals) | Should -Contain 'sharepoint-admin-center'
            @($contract.portals) | Should -Contain 'microsoft-entra-admin-center'
            @($contract.portals) | Should -Contain 'manual-verification'
        }
    }

    Describe 'Script behavior tests' {
        It 'Invoke-DriftScan handles empty drift categories under StrictMode' {
            $sandboxSolutionRoot = New-IsolatedSolutionSandbox -Name 'scan-empty-categories'
            $baselinesDir = Join-Path $sandboxSolutionRoot 'baselines'
            $reportsDir = Join-Path $sandboxSolutionRoot 'reports'
            $baselinePath = Join-Path $baselinesDir 'baseline-empty.json'

            $null = New-Item -ItemType Directory -Path $baselinesDir -Force
            $baseline = [pscustomobject]@{
                capturedAt = (Get-Date).ToString('o')
                tenantUrl  = 'https://contoso.sharepoint.com'
                siteCount  = 1
                sites      = @(
                    [pscustomobject]@{
                        siteUrl = 'https://contoso.sharepoint.com/sites/No-Match'
                        uniquePermissions = @()
                    }
                )
            }
            $baseline | ConvertTo-Json -Depth 10 | Set-Content -Path $baselinePath -Encoding UTF8

            $scanScript = Join-Path $sandboxSolutionRoot 'scripts\Invoke-DriftScan.ps1'
            $scanResult = & $scanScript -TenantUrl 'https://contoso.sharepoint.com' -BaselinePath $baselinePath -OutputPath $reportsDir

            $scanResult.TotalDrift | Should -Be 0
            $scanResult.HighRisk | Should -Be 0
            $scanResult.MediumRisk | Should -Be 0
            $scanResult.LowRisk | Should -Be 0
        }

        It 'Invoke-DriftScan assigns non-LOW risk to organization-wide ADDED drift' {
            $sandboxSolutionRoot = New-IsolatedSolutionSandbox -Name 'scan-orgwide-weighting'
            $reportsDir = Join-Path $sandboxSolutionRoot 'reports'
            $missingBaseline = Join-Path $sandboxSolutionRoot 'baselines\missing-baseline.json'
            $scanScript = Join-Path $sandboxSolutionRoot 'scripts\Invoke-DriftScan.ps1'

            $scanResult = & $scanScript -TenantUrl 'https://contoso.sharepoint.com' -BaselinePath $missingBaseline -OutputPath $reportsDir
            $report = Get-Content -Path $scanResult.ReportFile -Raw | ConvertFrom-Json -Depth 20
            $organizationWideItem = @($report.items | Where-Object { $_.After.principalType -eq 'OrganizationWide' } | Select-Object -First 1)[0]

            $organizationWideItem | Should -Not -BeNullOrEmpty
            [int]$organizationWideItem.RiskScore | Should -BeGreaterOrEqual 40
            $organizationWideItem.RiskTier | Should -Not -Be 'LOW'
        }

        It 'Invoke-DriftScan applies boundary scoring and keeps Trading Full Control escalation non-LOW' {
            $sandboxSolutionRoot = New-IsolatedSolutionSandbox -Name 'scan-boundary-math'
            $reportsDir = Join-Path $sandboxSolutionRoot 'reports'
            $missingBaseline = Join-Path $sandboxSolutionRoot 'baselines\missing-baseline.json'
            $scanScript = Join-Path $sandboxSolutionRoot 'scripts\Invoke-DriftScan.ps1'

            $scanResult = & $scanScript -TenantUrl 'https://contoso.sharepoint.com' -BaselinePath $missingBaseline -OutputPath $reportsDir
            $report = Get-Content -Path $scanResult.ReportFile -Raw | ConvertFrom-Json -Depth 20

            $externalFullControl = @(
                $report.items | Where-Object {
                    $_.DriftType -eq 'ADDED' -and
                    $_.After.principalType -eq 'ExternalUser' -and
                    $_.After.permissionLevel -eq 'Full Control'
                } | Select-Object -First 1
            )[0]
            $tradingEscalation = @(
                $report.items | Where-Object {
                    $_.SiteUrl -like '*/sites/Trading-Desk' -and
                    $_.DriftType -eq 'CHANGED' -and
                    $_.After.permissionLevel -eq 'Full Control'
                } | Select-Object -First 1
            )[0]

            $externalFullControl | Should -Not -BeNullOrEmpty
            [int]$externalFullControl.RiskScore | Should -Be 70
            $externalFullControl.RiskTier | Should -Be 'HIGH'

            $tradingEscalation | Should -Not -BeNullOrEmpty
            [int]$tradingEscalation.RiskScore | Should -Be 40
            $tradingEscalation.RiskTier | Should -Be 'MEDIUM'
        }

        It 'Invoke-DriftScan honors explicit ConfigPath scoring overrides' {
            $sandboxSolutionRoot = New-IsolatedSolutionSandbox -Name 'scan-explicit-config-path'
            $reportsDir = Join-Path $sandboxSolutionRoot 'reports'
            $missingBaseline = Join-Path $sandboxSolutionRoot 'baselines\missing-baseline.json'
            $scanScript = Join-Path $sandboxSolutionRoot 'scripts\Invoke-DriftScan.ps1'
            $customConfigPath = Join-Path $sandboxSolutionRoot 'config\custom-risk-config.json'

            $customConfig = Get-Content -Path (Join-Path $sandboxSolutionRoot 'config\default-config.json') -Raw | ConvertFrom-Json -AsHashtable
            $customConfig['riskThresholds']['high'] = 90
            $customConfig['riskThresholds']['medium'] = 60
            $customConfig['driftTypeWeights']['permissionLevel']['FullControl'] = 20
            $customConfig | ConvertTo-Json -Depth 20 | Set-Content -Path $customConfigPath -Encoding UTF8

            $scanResult = & $scanScript -TenantUrl 'https://contoso.sharepoint.com' -BaselinePath $missingBaseline -OutputPath $reportsDir -ConfigPath $customConfigPath
            $report = Get-Content -Path $scanResult.ReportFile -Raw | ConvertFrom-Json -Depth 20
            $externalFullControl = @(
                $report.items | Where-Object {
                    $_.DriftType -eq 'ADDED' -and
                    $_.After.principalType -eq 'ExternalUser' -and
                    $_.After.permissionLevel -eq 'Full Control'
                } | Select-Object -First 1
            )[0]

            $externalFullControl | Should -Not -BeNullOrEmpty
            [int]$externalFullControl.RiskScore | Should -Be 60
            $externalFullControl.RiskTier | Should -Be 'MEDIUM'
        }

        It 'Monitor-Compliance reports truthful missing and stale baseline status' {
            $sandboxSolutionRoot = New-IsolatedSolutionSandbox -Name 'monitor-baseline-status'
            $monitorScript = Join-Path $sandboxSolutionRoot 'scripts\Monitor-Compliance.ps1'
            $monitorOutput = Join-Path $sandboxSolutionRoot 'artifacts'

            $missingResult = & $monitorScript -ConfigurationTier baseline -TenantId 'test-tenant' -TenantUrl 'https://contoso.sharepoint.com' -OutputPath $monitorOutput
            $missingResult.BaselineStatus | Should -Be 'Missing'

            $baselinesDir = Join-Path $sandboxSolutionRoot 'baselines'
            $null = New-Item -ItemType Directory -Path $baselinesDir -Force
            $staleBaselinePath = Join-Path $baselinesDir 'baseline-stale.json'
            $pointerPath = Join-Path $baselinesDir 'latest-baseline.json'

            ([pscustomobject]@{ capturedAt = (Get-Date).AddHours(-72).ToString('o'); tenantUrl = 'https://contoso.sharepoint.com'; siteCount = 0; sites = @() } |
                ConvertTo-Json -Depth 10) | Set-Content -Path $staleBaselinePath -Encoding UTF8
            ([pscustomobject]@{ baselinePath = 'baseline-stale.json'; capturedAt = (Get-Date).AddHours(-72).ToString('o'); siteCount = 0 } |
                ConvertTo-Json -Depth 10) | Set-Content -Path $pointerPath -Encoding UTF8

            $staleResult = & $monitorScript -ConfigurationTier baseline -TenantId 'test-tenant' -TenantUrl 'https://contoso.sharepoint.com' -OutputPath $monitorOutput
            $staleResult.BaselineStatus | Should -Be 'Stale'
        }

        It 'Monitor-Compliance surfaces ScanFailed with scan error details' {
            $sandboxSolutionRoot = New-IsolatedSolutionSandbox -Name 'monitor-scan-failure'
            $monitorScript = Join-Path $sandboxSolutionRoot 'scripts\Monitor-Compliance.ps1'
            $baselinesDir = Join-Path $sandboxSolutionRoot 'baselines'
            $null = New-Item -ItemType Directory -Path $baselinesDir -Force

            $pointerPath = Join-Path $baselinesDir 'latest-baseline.json'
            $invalidBaselinePath = Join-Path $baselinesDir 'baseline-invalid.json'
            'this is not json' | Set-Content -Path $invalidBaselinePath -Encoding UTF8
            ([pscustomobject]@{ baselinePath = 'baseline-invalid.json'; capturedAt = (Get-Date).ToString('o'); siteCount = 1 } |
                ConvertTo-Json -Depth 10) | Set-Content -Path $pointerPath -Encoding UTF8

            $result = & $monitorScript -ConfigurationTier baseline -TenantId 'test-tenant' -TenantUrl 'https://contoso.sharepoint.com' -OutputPath (Join-Path $sandboxSolutionRoot 'artifacts')
            $result.Status | Should -Be 'ScanFailed'
            $result.Status | Should -Not -Be 'NoDriftDetected'

            $summary = Get-Content -Path $result.SummaryFile -Raw | ConvertFrom-Json -Depth 20
            $summary.status | Should -Be 'ScanFailed'
            $summary.scanError | Should -Not -BeNullOrEmpty
        }

        It 'Invoke-DriftReversion WhatIf performs no mail or file mutations' {
            $sandboxSolutionRoot = New-IsolatedSolutionSandbox -Name 'reversion-whatif'
            $reportsDir = Join-Path $sandboxSolutionRoot 'reports'
            $null = New-Item -ItemType Directory -Path $reportsDir -Force
            $driftReportPath = Join-Path $reportsDir 'drift-report-test.json'

            $driftReport = [pscustomobject]@{
                generatedAt = (Get-Date).ToString('o')
                tenantUrl = 'https://contoso.sharepoint.com'
                baselinePath = '.\baselines\latest-baseline.json'
                totalDriftItems = 1
                summary = [pscustomobject]@{ added = 1; removed = 0; changed = 0; high = 0; medium = 1; low = 0 }
                items = @(
                    [pscustomobject]@{
                        SiteUrl = 'https://contoso.sharepoint.com/sites/Finance'
                        ItemPath = 'Shared Documents'
                        DriftType = 'ADDED'
                        Before = $null
                        After = [pscustomobject]@{ principalName = 'External Consultant'; principalType = 'ExternalUser'; permissionLevel = 'Contribute' }
                        RiskScore = 45
                        RiskTier = 'MEDIUM'
                        DetectedAt = (Get-Date).ToString('o')
                    }
                )
            }
            $driftReport | ConvertTo-Json -Depth 10 | Set-Content -Path $driftReportPath -Encoding UTF8

            $reversionScript = Join-Path $sandboxSolutionRoot 'scripts\Invoke-DriftReversion.ps1'
            $result = & $reversionScript -DriftReportPath $driftReportPath -ConfigPath (Join-Path $sandboxSolutionRoot 'config\auto-revert-policy.json') -WhatIf

            $result.RevertedCount | Should -Be 0
            Test-Path -Path (Join-Path $reportsDir 'pending-approvals.json') | Should -BeFalse
            @(Get-ChildItem -Path $reportsDir -Filter 'reversion-log-*.json' -ErrorAction SilentlyContinue).Count | Should -Be 0
        }

        It 'Invoke-DriftReversion AutoRevert fails loudly when LOW and MEDIUM scopes are disabled' {
            $sandboxSolutionRoot = New-IsolatedSolutionSandbox -Name 'reversion-autorevert-disabled-scopes'
            $reportsDir = Join-Path $sandboxSolutionRoot 'reports'
            $null = New-Item -ItemType Directory -Path $reportsDir -Force
            $driftReportPath = Join-Path $reportsDir 'drift-report-test.json'

            ([pscustomobject]@{
                generatedAt = (Get-Date).ToString('o')
                tenantUrl = 'https://contoso.sharepoint.com'
                baselinePath = '.\baselines\latest-baseline.json'
                totalDriftItems = 1
                summary = [pscustomobject]@{ added = 1; removed = 0; changed = 0; high = 0; medium = 1; low = 0 }
                items = @(
                    [pscustomobject]@{
                        SiteUrl = 'https://contoso.sharepoint.com/sites/Finance'
                        ItemPath = 'Shared Documents'
                        DriftType = 'ADDED'
                        Before = $null
                        After = [pscustomobject]@{ principalName = 'External Consultant'; principalType = 'ExternalUser'; permissionLevel = 'Contribute' }
                        RiskScore = 45
                        RiskTier = 'MEDIUM'
                        DetectedAt = (Get-Date).ToString('o')
                    }
                )
            } | ConvertTo-Json -Depth 10) | Set-Content -Path $driftReportPath -Encoding UTF8

            $reversionScript = Join-Path $sandboxSolutionRoot 'scripts\Invoke-DriftReversion.ps1'
            { & $reversionScript -DriftReportPath $driftReportPath -ConfigPath (Join-Path $sandboxSolutionRoot 'config\auto-revert-policy.json') -AutoRevert } | Should -Throw '*LOW/MEDIUM*'
        }

        It 'Deploy-Solution sources manifest version from default-config.json' {
            $deployScriptContent = Get-Content -Path (Join-Path $script:solutionRoot 'scripts\Deploy-Solution.ps1') -Raw
            $deployScriptContent | Should -Not -Match "version\s*=\s*'v0\.1\.3'"
            $deployScriptContent | Should -Match "ContainsKey\('version'\)"
        }
    }
}
