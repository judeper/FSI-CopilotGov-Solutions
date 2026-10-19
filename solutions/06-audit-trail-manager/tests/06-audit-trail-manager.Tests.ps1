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
    }

    Describe 'ATM generated guidance for <tier>' -ForEach @(
        @{ tier = 'baseline'; expectedStatus = 'partial'; expectedDays = 1095; expectedCases = 1; expectedHolds = 0; expectedCustodians = 2 }
        @{ tier = 'recommended'; expectedStatus = 'partial'; expectedDays = 1825; expectedCases = 1; expectedHolds = 2; expectedCustodians = 5 }
        @{ tier = 'regulated'; expectedStatus = 'implemented'; expectedDays = 2555; expectedCases = 2; expectedHolds = 4; expectedCustodians = 8 }
    ) {
        BeforeAll {
            $solutionRoot = Split-Path -Path $PSScriptRoot -Parent
            $scriptsRoot = Join-Path $solutionRoot 'scripts'
            $outputRoot = Join-Path $TestDrive $tier
            $deployment = & (Join-Path $scriptsRoot 'Deploy-Solution.ps1') -ConfigurationTier $tier -OutputPath (Join-Path $outputRoot 'deployment')
            $export = & (Join-Path $scriptsRoot 'Export-Evidence.ps1') -ConfigurationTier $tier -OutputPath (Join-Path $outputRoot 'evidence') -PeriodStart 2026-10-01 -PeriodEnd 2026-10-18
            $monitor = & (Join-Path $scriptsRoot 'Monitor-Compliance.ps1') -ConfigurationTier $tier -OutputPath (Join-Path $outputRoot 'monitor')
            $retention = Get-Content $deployment.RetentionManifestPath -Raw | ConvertFrom-Json
            $requirements = Get-Content $deployment.AuditRequirementsPath -Raw | ConvertFrom-Json
            $manifest = Get-Content $deployment.DeploymentManifestPath -Raw | ConvertFrom-Json
            $audit = Get-Content (Join-Path $outputRoot 'evidence\audit-log-completeness.json') -Raw | ConvertFrom-Json
            $state = Get-Content (Join-Path $outputRoot 'evidence\retention-policy-state.json') -Raw | ConvertFrom-Json
            $ediscovery = Get-Content (Join-Path $outputRoot 'evidence\ediscovery-readiness-package.json') -Raw | ConvertFrom-Json
            $package = Get-Content $export.PackagePath -Raw | ConvertFrom-Json
            $tierConfig = Get-Content (Join-Path $solutionRoot "config\$tier.json") -Raw | ConvertFrom-Json
        }

        It 'distinguishes newer and older retention locations without a blanket cmdlet substitution' {
            foreach ($policy in $retention.policies) {
                $policy.policyApplication | Should -Match 'Microsoft Copilot experiences.*New-AppRetentionCompliancePolicy.*Set-AppRetentionCompliancePolicy.*New-AppRetentionComplianceRule.*Set-AppRetentionComplianceRule'
                $policy.policyApplication | Should -Match 'Exchange mailboxes and SharePoint sites.*New-RetentionCompliancePolicy.*Set-RetentionCompliancePolicy.*New-RetentionComplianceRule.*Set-RetentionComplianceRule'
                $policy.policyApplication | Should -Match 'Teams chats without Copilot interactions.*AppRetentionCompliance'
                $policy.policyApplication | Should -Match 'Teams channel messages.*older.*RetentionCompliance'
                $policy.policyApplication | Should -Match 'https://learn.microsoft.com/purview/retention-cmdlets'
                $policy.policyApplication | Should -Not -Match 'cmdlets such as New-RetentionCompliancePolicy'
                $policy.policyApplication | Should -Match 'content retention.*not audit log retention'
            }
        }

        It 'describes retained content rather than audit operation names' {
            foreach ($policy in $retention.policies) {
                $policy.targetArtifacts | Should -Contain 'Copilot user prompts and responses'
                $policy.targetArtifacts | Should -Contain 'SharePoint files'
                $policy.targetArtifacts | Should -Not -Contain 'CopilotInteraction'
                $policy.targetArtifacts | Should -Not -Contain 'FileAccessed'
                $policy.workloads | Should -Contain 'Microsoft Copilot experiences'
            }
        }

        It 'marks completeness placeholders non-executable in both emitted validation fields' {
            foreach ($instruction in @($requirements.unifiedAuditLog.validationCommand, $audit.ualStatus.validationCommand)) {
                $instruction | Should -Match '^Not executable: Check-AuditLogCompleteness is an unimplemented placeholder'
                $instruction | Should -Match 'https://learn.microsoft.com/purview/audit-search'
                $instruction | Should -Not -Be 'Check-AuditLogCompleteness'
            }
            $manifest.nextSteps -join ' ' | Should -Not -Match 'Run Check-AuditLogCompleteness'
            $manifest.nextSteps -join ' ' | Should -Match 'not executable'
            $manifest.nextSteps -join ' ' | Should -Match 'local sample evidence.*not tenant observations'
        }

        It 'limits retention labels to supported files and explicitly excludes interaction messages' {
            $state.labels | Should -HaveCount 1
            $state.labels[0].appliesTo | Should -Match '^Supported files in SharePoint and OneDrive only'
            $state.labels[0].appliesTo | Should -Match 'not Copilot interaction messages.*retention policies'
            $state.labels[0].appliesTo | Should -Not -Match 'Copilot interaction artifacts and supporting files'
            foreach ($control in @(
                ($monitor.controls | Where-Object controlId -EQ '3.11'),
                ($package.controls | Where-Object controlId -EQ '3.11')
            )) {
                $control.notes | Should -Match 'supported files'
                $control.notes | Should -Match 'not Copilot interaction messages'
                $control.notes | Should -Match 'not observed tenant state'
                $control.status | Should -Be 'implemented'
            }
        }

        It 'separates standard Copilot audit capture from licensed premium capabilities and content retention' {
            $notes = $audit.notes -join ' '
            $notes | Should -Match 'Audit \(Standard\).*when auditing is enabled'
            $notes | Should -Match 'Audit \(Premium\).*longer retention'
            $notes | Should -Not -Match 'Copilot event detail depends on Microsoft 365 audit level'
            $notes | Should -Match 'Content retention policies do not configure audit log retention'
            $notes | Should -Match 'Local sample only.*not observed tenant events'
            $state.notes -join ' ' | Should -Match 'Local sample only.*not observed tenant state'
        }

        It 'preserves configured values, sample counts, evidence fields and tier status logic' {
            $requirements.unifiedAuditLog.requiredAuditLevel | Should -Be $tierConfig.auditLevel
            $audit.ualStatus.auditLevel | Should -Be $tierConfig.auditLevel
            $audit.ualStatus.enabledCheck | Should -Be 'check'
            $audit.ualStatus.PSObject.Properties.Name -join ',' | Should -Be 'enabledCheck,auditLevel,validationCommand,latencyNote'
            $audit.requiredEventTypes -join ',' | Should -Be 'CopilotInteraction,FileAccessed'
            $audit.capturedEventTypes -join ',' | Should -Be ($tierConfig.auditEventTypes -join ',')
            $audit.sampleCounts | Should -HaveCount 2
            foreach ($count in $audit.sampleCounts) {
                $count.sampleCount | Should -Be 0
                $count.status | Should -Be 'pending-tenant-query'
            }
            $audit.periodStart | Should -Be '2026-10-01'
            $audit.periodEnd | Should -Be '2026-10-18'
            $audit.tenantId | Should -Be 'not-specified'
            $state.activePolicies | Should -HaveCount 4
            foreach ($policy in $state.activePolicies) {
                $policy.configuredDays | Should -Be $expectedDays
                $policy.meetsMinimum | Should -Be ($policy.configuredDays -ge $policy.minimumDays)
            }
            $state.labels[0].required | Should -Be $tierConfig.retentionLabelRequired
            $state.labels[0].publishingMode | Should -Be $tierConfig.retentionPolicyMode
            $ediscovery.caseCount | Should -Be $expectedCases
            $ediscovery.holdCount | Should -Be $expectedHolds
            $ediscovery.custodianCount | Should -Be $expectedCustodians
            $monitor.overallStatus | Should -Be $expectedStatus
            $package.summary.overallStatus | Should -Be $expectedStatus
            $manifest.status | Should -Be 'documentation-first'
            @($monitor.controls.status) -join ',' | Should -Be (@($package.controls.status) -join ',')
            $state.PSObject.Properties.Name -join ',' | Should -Be 'solution,solutionCode,tier,tenantId,generatedAt,activePolicies,labels,retentionPeriodsByRegulation,wormDocumentationRequired,immutableStorageAttestationRequired,notes'
        }

        It 'retains monitor-only status when optional audit and retention checks are disabled' {
            $unchecked = & (Join-Path $scriptsRoot 'Monitor-Compliance.ps1') -ConfigurationTier $tier -OutputPath (Join-Path $outputRoot 'unchecked') -CheckRetention $false -CheckAuditLevel $false
            ($unchecked.controls | Where-Object controlId -EQ '3.1').status | Should -Be 'monitor-only'
            ($unchecked.controls | Where-Object controlId -EQ '3.2').status | Should -Be 'monitor-only'
        }

        It 'writes a schema-valid package and independently verifiable companion hashes' {
            $repoRoot = Split-Path (Split-Path $solutionRoot -Parent) -Parent
            Get-Content $export.PackagePath -Raw | Test-Json -SchemaFile (Join-Path $repoRoot 'data\evidence-schema.json') | Should -BeTrue
            foreach ($path in @($export.ArtifactPaths) + @($export.PackagePath)) {
                $sidecar = (Get-Content "$path.sha256" -Raw).Trim()
                $sidecar | Should -BeExactly ('{0}  {1}' -f (Get-FileHash $path -Algorithm SHA256).Hash.ToLowerInvariant(), (Split-Path $path -Leaf))
            }
        }
    }

    Describe 'ATM maintained evidence samples' {
        It 'keeps maintained sample bytes in UTF-8 without BOM and LF on every checkout' {
            $fixtureRoot = Join-Path (Split-Path $PSScriptRoot -Parent) 'artifacts\evidence-test'
            foreach ($sample in Get-ChildItem $fixtureRoot -Filter '*.json' -File) {
                $bytes = [IO.File]::ReadAllBytes($sample.FullName)
                $bytes | Should -Not -Contain 13
                [Convert]::ToHexString($bytes[0..2]) | Should -Not -Be 'EFBBBF'
                $bytes[-1] | Should -Be 10
            }
        }

        It 'has corrected guidance and valid hashes for every maintained JSON sample' {
            $fixtureRoot = Join-Path (Split-Path $PSScriptRoot -Parent) 'artifacts\evidence-test'
            $samples = @(Get-ChildItem $fixtureRoot -Filter '*.json' -File)
            $samples | Should -HaveCount 3
            foreach ($sample in $samples) {
                (Get-Content "$($sample.FullName).sha256" -Raw).Trim() | Should -BeExactly ('{0}  {1}' -f (Get-FileHash $sample.FullName -Algorithm SHA256).Hash.ToLowerInvariant(), $sample.Name)
            }
            $audit = Get-Content (Join-Path $fixtureRoot 'audit-log-completeness.json') -Raw | ConvertFrom-Json
            $state = Get-Content (Join-Path $fixtureRoot 'retention-policy-state.json') -Raw | ConvertFrom-Json
            $audit.ualStatus.validationCommand | Should -Match '^Not executable:'
            $state.labels[0].appliesTo | Should -Match 'not Copilot interaction messages'
        }
    }

    Describe 'ATM JSON writer byte contract' {
        It 'writes canonical LF bytes without changing multiline or Unicode values' {
            Import-Module (Join-Path $scriptsRoot 'AtmShared.psm1') -Force
            $inputObject = [ordered]@{
                notes = @("first`r`nsecond", "third`nfourth")
                displayName = "Copilot $([char]0x2014) sample"
            }
            $path = Join-Path $TestDrive 'writer\sample.json'
            Write-AtmJsonFile -Path $path -InputObject $inputObject | Should -Be $path
            $bytes = [IO.File]::ReadAllBytes($path)
            $bytes | Should -Not -Contain 13
            [Convert]::ToHexString($bytes[0..2]) | Should -Not -Be 'EFBBBF'
            $bytes[-1] | Should -Be 10
            $bytes[-2] | Should -Not -Be 10
            $expectedJson = (($inputObject | ConvertTo-Json -Depth 20) -replace "`r`n?", "`n") + "`n"
            [Convert]::ToHexString($bytes) | Should -BeExactly ([Convert]::ToHexString([Text.Encoding]::UTF8.GetBytes($expectedJson)))
            $roundTrip = Get-Content $path -Raw | ConvertFrom-Json
            $roundTrip.notes[0] | Should -BeExactly $inputObject.notes[0]
            $roundTrip.notes[1] | Should -BeExactly $inputObject.notes[1]
            $roundTrip.displayName | Should -BeExactly $inputObject.displayName
        }
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
}