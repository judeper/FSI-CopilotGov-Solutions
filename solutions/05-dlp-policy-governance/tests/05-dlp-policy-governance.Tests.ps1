Describe 'DLP Policy Governance for Copilot solution' {
    BeforeAll {
        $solutionRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
        $script:configRoot = Join-Path $solutionRoot 'config'
        $script:docsRoot = Join-Path $solutionRoot 'docs'
        $scriptsRoot = Join-Path $solutionRoot 'scripts'
        $script:testFiles = @(
            (Join-Path $scriptsRoot 'Common-Functions.ps1'),
            (Join-Path $scriptsRoot 'Deploy-Solution.ps1'),
            (Join-Path $scriptsRoot 'Monitor-Compliance.ps1'),
            (Join-Path $scriptsRoot 'Export-Evidence.ps1')
        )
    }

    It 'has required configuration files' {
        Test-Path (Join-Path $script:configRoot 'default-config.json') | Should -BeTrue
        Test-Path (Join-Path $script:configRoot 'baseline.json') | Should -BeTrue
        Test-Path (Join-Path $script:configRoot 'recommended.json') | Should -BeTrue
        Test-Path (Join-Path $script:configRoot 'regulated.json') | Should -BeTrue
    }

    It 'has required documentation files' {
        Test-Path (Join-Path $script:docsRoot 'architecture.md') | Should -BeTrue
        Test-Path (Join-Path $script:docsRoot 'deployment-guide.md') | Should -BeTrue
        Test-Path (Join-Path $script:docsRoot 'evidence-export.md') | Should -BeTrue
        Test-Path (Join-Path $script:docsRoot 'prerequisites.md') | Should -BeTrue
        Test-Path (Join-Path $script:docsRoot 'troubleshooting.md') | Should -BeTrue
    }

    It 'default-config.json contains required fields' {
        $config = Get-Content (Join-Path $script:configRoot 'default-config.json') -Raw | ConvertFrom-Json -Depth 20
        $config.solution | Should -Be '05-dlp-policy-governance'
        @($config.controls) | Should -Contain '2.1'
        $config.defaults.copilotPolicyLocation | Should -Be 'Microsoft 365 Copilot and Copilot Chat'
        @($config.defaults.copilotCapabilities.id) | Should -Contain 'sensitiveInformationTypesInPrompts'
        @($config.defaults.copilotCapabilities.id) | Should -Contain 'sensitivityLabelsOnSupportedFilesAndEmails'
        @($config.defaults.complementaryWorkloadDlpPolicyLocations) | Should -Contain 'Exchange'
    }

    It 'baseline.json has the correct tier and solution' {
        $config = Get-Content (Join-Path $script:configRoot 'baseline.json') -Raw | ConvertFrom-Json -Depth 20
        $config.tier | Should -Be 'baseline'
        $config.solution | Should -Be '05-dlp-policy-governance'
    }

    It 'regulated.json retains evidence for at least 365 days' {
        $config = Get-Content (Join-Path $script:configRoot 'regulated.json') -Raw | ConvertFrom-Json -Depth 20
        [int]$config.evidenceRetentionDays | Should -BeGreaterOrEqual 365
    }

    It 'has all required scripts' {
        foreach ($path in $script:testFiles) {
            Test-Path $path | Should -BeTrue
        }
    }

    It 'scripts pass PowerShell syntax validation' {
        foreach ($path in $script:testFiles) {
            $tokens = $null
            $errors = $null
            [void][System.Management.Automation.Language.Parser]::ParseFile($path, [ref]$tokens, [ref]$errors)
            $errors.Count | Should -Be 0 -Because $path
        }
    }

    It 'Export-Evidence.ps1 references dlp-policy-baseline' {
        $content = Get-Content (Join-Path $scriptsRoot 'Export-Evidence.ps1') -Raw
        $content | Should -Match 'dlp-policy-baseline'
    }

    It 'Monitor-Compliance.ps1 references control 2.1' {
        $content = Get-Content (Join-Path $scriptsRoot 'Monitor-Compliance.ps1') -Raw
        $content | Should -Match '2\.1'
    }

    It 'CHANGELOG has v0.2.3 entry' {
        $changelog = Get-Content (Join-Path $solutionRoot 'CHANGELOG.md') -Raw
        $changelog | Should -Match 'v0\.2\.3'
    }
}

Describe 'DLP for Copilot capability currency' {
    BeforeAll {
        $configRoot = Join-Path (Resolve-Path (Join-Path $PSScriptRoot '..')).Path 'config'
        $script:capabilities = (Get-Content (Join-Path $configRoot 'default-config.json') -Raw | ConvertFrom-Json -Depth 20).defaults.copilotCapabilities
    }

    It 'marks external web-search grounding restriction as generally available' {
        ($script:capabilities | Where-Object { $_.id -eq 'externalWebSearchGroundingRestriction' }).availability | Should -Be 'generallyAvailable'
    }

    It 'retains sensitive-information-type prompt blocking as preview' {
        ($script:capabilities | Where-Object { $_.id -eq 'sensitiveInformationTypesInPrompts' }).availability | Should -Be 'preview'
    }

    It 'keeps sensitivity-label file and email blocking generally available' {
        ($script:capabilities | Where-Object { $_.id -eq 'sensitivityLabelsOnSupportedFilesAndEmails' }).availability | Should -Be 'generallyAvailable'
    }

    It 'documents the external-email exclusion capability as preview with sender-domain scope' {
        $externalEmail = $script:capabilities | Where-Object { $_.id -eq 'externalEmailGroundingRestriction' }
        $externalEmail | Should -Not -BeNullOrEmpty
        $externalEmail.availability | Should -Be 'preview'
        $externalEmail.condition | Should -Be 'Email is received from > External users'
        $externalEmail.action | Should -Be 'Prevent Copilot from processing content'
    }
}

Describe 'DLP Policy Governance behavioral checks' {
    BeforeAll {
        $script:solutionRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
        $script:configRoot = Join-Path $script:solutionRoot 'config'
        $script:scriptsRoot = Join-Path $script:solutionRoot 'scripts'
        . (Join-Path $script:scriptsRoot 'Common-Functions.ps1')
        $script:defaultConfig = Read-JsonFile -Path (Join-Path $script:configRoot 'default-config.json')
    }

    It 'New-DlpPolicyTemplate returns one complementary-workload policy per tier workload' {
        $tier = Read-JsonFile -Path (Join-Path $script:configRoot 'recommended.json')
        $policies = @(New-DlpPolicyTemplate -DefaultConfig $script:defaultConfig -TierConfig $tier)
        $policies.Count | Should -Be (@($tier.copilotWorkloads).Count)
        @($policies | ForEach-Object { $_.workload }) | Should -Contain 'Exchange'
        @($policies | ForEach-Object { $_.policyLayer } | Sort-Object -Unique) | Should -Be 'complementary-workload-dlp'
        ($policies | Where-Object { $_.workload -eq 'Teams' }).highSensitivityMode | Should -Be 'Block'
    }

    It 'Get-CopilotCapabilityId returns all documented capability ids including the external-email preview' {
        $ids = @(Get-CopilotCapabilityId -DefaultConfig $script:defaultConfig)
        $ids | Should -Contain 'externalWebSearchGroundingRestriction'
        $ids | Should -Contain 'externalEmailGroundingRestriction'
    }
}

Describe 'Monitor-Compliance drift detection' {
    BeforeAll {
        $script:monitor = Join-Path (Resolve-Path (Join-Path $PSScriptRoot '..')).Path 'scripts\Monitor-Compliance.ps1'
    }

    It 'emits a high-severity baseline-missing finding when no baseline exists' {
        $out = Join-Path $TestDrive 'nobaseline'
        $missingBaseline = Join-Path $out 'dlp-policy-baseline.json'
        $result = & $script:monitor -ConfigurationTier recommended -BaselinePath $missingBaseline -OutputPath $out
        $result.baselinePresent | Should -BeFalse
        $findings = Get-Content (Join-Path $out 'policy-drift-findings.json') -Raw | ConvertFrom-Json
        @($findings | Where-Object { $_.controlId -eq '3.10' -and $_.severity -eq 'high' }).Count | Should -BeGreaterThan 0
    }

    It 'detects a workload coverage gap when the baseline omits a tier workload' {
        $out = Join-Path $TestDrive 'partialbaseline'
        New-Item -ItemType Directory -Path $out -Force | Out-Null
        $baseline = [ordered]@{
            solution                                = '05-dlp-policy-governance'
            tier                                    = 'recommended'
            exceptionHandling                       = [ordered]@{ approvalRequired = $true; approverRole = 'Compliance Administrator' }
            complementaryWorkloadDlpPolicyLocations = @('Teams')
            policies                                = @(
                [ordered]@{
                    workload           = 'Teams'
                    mode               = 'Audit'
                    highSensitivityMode = 'Block'
                    labelSpecificModes = [ordered]@{ NPI = 'Block'; PII = 'Block' }
                }
            )
        }
        $baseline | ConvertTo-Json -Depth 10 | Set-Content -Path (Join-Path $out 'dlp-policy-baseline.json') -Encoding utf8
        $null = & $script:monitor -ConfigurationTier recommended -BaselinePath (Join-Path $out 'dlp-policy-baseline.json') -OutputPath $out
        $findings = Get-Content (Join-Path $out 'policy-drift-findings.json') -Raw | ConvertFrom-Json
        @($findings | Where-Object { $_.controlId -eq '2.1' -and $_.category -eq 'workloadCoverage' }).Count | Should -BeGreaterThan 0
    }
}

Describe 'Export-Evidence resilience and integrity' {
    BeforeAll {
        $script:export = Join-Path (Resolve-Path (Join-Path $PSScriptRoot '..')).Path 'scripts\Export-Evidence.ps1'
    }

    It 'does not throw when a pre-seeded baseline omits complementaryWorkloadDlpPolicyLocations' {
        $out = Join-Path $TestDrive 'fallback'
        New-Item -ItemType Directory -Path $out -Force | Out-Null
        $baseline = [ordered]@{
            solution          = '05-dlp-policy-governance'
            tier              = 'baseline'
            exceptionHandling = [ordered]@{ approvalRequired = $false; approverRole = 'Service Owner' }
            policies          = @()
        }
        $baseline | ConvertTo-Json -Depth 10 | Set-Content -Path (Join-Path $out 'dlp-policy-baseline.json') -Encoding utf8
        { & $script:export -ConfigurationTier baseline -OutputPath $out -PeriodStart '2026-01-01' -PeriodEnd '2026-01-31' } | Should -Not -Throw
    }

    It 'writes an evidence package whose SHA-256 companion matches the emitted file' {
        $out = Join-Path $TestDrive 'integrity'
        $null = & $script:export -ConfigurationTier baseline -OutputPath $out -PeriodStart '2026-01-01' -PeriodEnd '2026-01-31'
        $packagePath = Join-Path $out '05-dlp-policy-governance-evidence.json'
        Test-Path $packagePath | Should -BeTrue
        Test-Path ($packagePath + '.sha256') | Should -BeTrue
        $recordedHash = ((Get-Content ($packagePath + '.sha256') -Raw).Trim() -split '\s+')[0]
        $actualHash = (Get-FileHash -Path $packagePath -Algorithm SHA256).Hash.ToLowerInvariant()
        $recordedHash | Should -Be $actualHash
    }

    It 'keeps package paths relative and caller paths absolute after relocation' {
        $repoRoot = (Resolve-Path (Join-Path (Split-Path $script:solutionRoot -Parent) '..')).Path
        Import-Module (Join-Path $repoRoot 'scripts\common\EvidenceExport.psm1') -Force

        $out = Join-Path $TestDrive 'portable'
        $result = & $script:export -ConfigurationTier baseline -OutputPath $out -PeriodStart '2026-01-01' -PeriodEnd '2026-01-31'
        [System.IO.Path]::IsPathRooted($result.evidencePackagePath) | Should -BeTrue
        foreach ($path in @($result.baselineArtifact, $result.driftArtifact, $result.exceptionArtifact)) {
            [System.IO.Path]::IsPathRooted($path) | Should -BeTrue
        }

        $package = Get-Content -Path $result.evidencePackagePath -Raw | ConvertFrom-Json
        foreach ($artifact in @($package.artifacts)) {
            [System.IO.Path]::IsPathRooted($artifact.path) | Should -BeFalse
        }

        $relocated = Join-Path $TestDrive 'portable-relocated'
        Move-Item -Path $out -Destination $relocated
        $validation = Test-CopilotGovEvidencePackage `
            -Path (Join-Path $relocated '05-dlp-policy-governance-evidence.json') `
            -ExpectedArtifacts @('dlp-policy-baseline', 'policy-drift-findings', 'exception-attestations')
        $validation.IsValid | Should -BeTrue -Because ($validation.Errors -join '; ')
    }

    It 'resolves relative output paths from the PowerShell location' {
        $originalProcessDirectory = [System.Environment]::CurrentDirectory
        Push-Location $TestDrive
        try {
            [System.Environment]::CurrentDirectory = $script:solutionRoot
            $result = & $script:export `
                -ConfigurationTier baseline `
                -OutputPath '.\provider-relative' `
                -PeriodStart '2026-01-01' `
                -PeriodEnd '2026-01-31'

            $expectedDirectory = Join-Path $TestDrive 'provider-relative'
            (Split-Path -Parent $result.evidencePackagePath) | Should -Be $expectedDirectory
            Test-Path -Path $result.evidencePackagePath -PathType Leaf | Should -BeTrue
        }
        finally {
            [System.Environment]::CurrentDirectory = $originalProcessDirectory
            Pop-Location
        }
    }
}
