Describe 'Conditional Access Policy Automation for Copilot' {
    BeforeAll {
        $solutionRoot = Split-Path $PSScriptRoot -Parent
        $script:defaultConfigPath = Join-Path $solutionRoot 'config\default-config.json'
        $script:regulatedConfigPath = Join-Path $solutionRoot 'config\regulated.json'
        $script:baselineConfigPath = Join-Path $solutionRoot 'config\baseline.json'
        $script:deployScriptPath = Join-Path $solutionRoot 'scripts\Deploy-Solution.ps1'
        $script:monitorScriptPath = Join-Path $solutionRoot 'scripts\Monitor-Compliance.ps1'
        $script:exportScriptPath = Join-Path $solutionRoot 'scripts\Export-Evidence.ps1'
    }

    It 'has required config files' {
        foreach ($relativePath in @(
            'config\default-config.json',
            'config\baseline.json',
            'config\recommended.json',
            'config\regulated.json'
        )) {
            Test-Path (Join-Path $solutionRoot $relativePath) | Should -BeTrue
        }
    }

    It 'has required documentation files' {
        foreach ($relativePath in @(
            'docs\architecture.md',
            'docs\deployment-guide.md',
            'docs\evidence-export.md',
            'docs\prerequisites.md',
            'docs\troubleshooting.md'
        )) {
            Test-Path (Join-Path $solutionRoot $relativePath) | Should -BeTrue
        }
    }

    It 'default-config.json defines required fields' {
        $config = Get-Content -Path $script:defaultConfigPath -Raw | ConvertFrom-Json -AsHashtable
        $config.solution | Should -Be '07-conditional-access-automation'
        $config.controls | Should -Contain '2.3'
        $config.ContainsKey('defaults') | Should -BeTrue
        $config.defaults.ContainsKey('copilotAppIds') | Should -BeTrue
    }

    It 'configuration status stays documentation-first' {
        foreach ($configPath in @($script:defaultConfigPath, $script:baselineConfigPath, $script:regulatedConfigPath, (Join-Path $solutionRoot 'config\\recommended.json'))) {
            $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json -AsHashtable
            $config.status | Should -Be 'Documentation-first scaffold'
        }
    }

    It 'default-config.json contains Graph-supported Conditional Access targets' {
        $config = Get-Content -Path $script:defaultConfigPath -Raw | ConvertFrom-Json -AsHashtable
        @($config.defaults.copilotAppIds).Count | Should -BeGreaterThan 0
        $config.defaults.copilotAppIds | Should -Contain 'Office365'
        @($config.defaults.copilotAppIds).Count | Should -Be 1
    }

    It 'does not reintroduce the unverifiable Copilot first-party app ID (issue #218 regression guard)' {
        $unverifiableAppId = 'fb8d773d-7ef8-4ec0-a117-179f88add510'
        foreach ($configPath in @(
            $script:defaultConfigPath,
            $script:baselineConfigPath,
            (Join-Path $solutionRoot 'config\recommended.json'),
            $script:regulatedConfigPath
        )) {
            $raw = Get-Content -Path $configPath -Raw
            $raw | Should -Not -Match $unverifiableAppId -Because 'the Enterprise Copilot Platform app ID is not published on Microsoft Learn; target the Office365 app suite instead (issue #218)'
        }
    }

    It 'retains the Office365 app-suite target across baseline, recommended, and regulated tiers' {
        foreach ($configPath in @(
            $script:baselineConfigPath,
            (Join-Path $solutionRoot 'config\recommended.json'),
            $script:regulatedConfigPath
        )) {
            $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json -AsHashtable
            @($config.copilotAppIds) | Should -Contain 'Office365'
        }
    }

    It 'default-config.json requires MFA for all risk tiers' {
        $config = Get-Content -Path $script:defaultConfigPath -Raw | ConvertFrom-Json -AsHashtable
        foreach ($tier in @('low', 'medium', 'high')) {
            $config.defaults.riskTiers[$tier].mfaRequired | Should -BeTrue -Because "MFA should be required for the '$tier' risk tier"
        }
    }

    It 'regulated.json keeps evidence retention at or above 365 days' {
        $regulated = Get-Content -Path $script:regulatedConfigPath -Raw | ConvertFrom-Json -AsHashtable
        ($regulated.evidenceRetentionDays -ge 365) | Should -BeTrue
    }

    It 'all required scripts exist' {
        foreach ($scriptPath in @($script:deployScriptPath, $script:monitorScriptPath, $script:exportScriptPath)) {
            Test-Path $scriptPath | Should -BeTrue
        }
    }

    It 'solution scripts parse without syntax errors' {
        foreach ($scriptFile in Get-ChildItem -Path (Join-Path $solutionRoot 'scripts') -Filter '*.ps1') {
            $tokens = $null
            $errors = $null
            $null = [System.Management.Automation.Language.Parser]::ParseFile($scriptFile.FullName, [ref]$tokens, [ref]$errors)
            $errors | Should -BeNullOrEmpty -Because $scriptFile.Name
        }
    }

    It 'Export-Evidence.ps1 references ca-policy-state' {
        (Get-Content -Path $script:exportScriptPath -Raw) | Should -Match 'ca-policy-state'
    }

    It 'Monitor-Compliance.ps1 references controls 2.3 and 2.9' {
        $content = Get-Content -Path $script:monitorScriptPath -Raw
        $content | Should -Match '2\.3'
        $content | Should -Match '2\.9'
    }

    It 'Deploy-Solution.ps1 references Copilot configuration' {
        (Get-Content -Path $script:deployScriptPath -Raw) | Should -Match '(?i)copilotappids|copilot'
    }

    It 'Deploy-Solution.ps1 New-PolicyTemplate uses correct sessionControls schema' {
        $content = Get-Content -Path $script:deployScriptPath -Raw
        $content | Should -Match 'persistentBrowser\s*=\s*\[ordered\]@\{'
        $content | Should -Match "mode\s*=\s*'never'"
        $content | Should -Match 'isEnabled\s*=\s*\$true'
        $content | Should -Match 'signInFrequency\s*=\s*\[ordered\]@\{'
        $content | Should -Match "type\s*=\s*'hours'"
        $content | Should -Not -Match 'signInFrequencyHours'
    }

    It 'Deploy-Solution.ps1 Get-PolicyRequestBody defaults to report-only mode' {
        $content = Get-Content -Path $script:deployScriptPath -Raw
        $content | Should -Match 'enabledForReportingButNotEnforced'
    }

    It 'deployment guide stays repository-local for validation guidance' {
        $content = Get-Content -Path (Join-Path $solutionRoot 'docs\\deployment-guide.md') -Raw
        $content | Should -Not -Match 'FSI-AgentGov-Solutions'
        $content | Should -Match 'Monitor-Compliance\.ps1'
    }

    It 'Deploy-Solution.ps1 disables live execution in the documentation-first scaffold' {
        $content = Get-Content -Path $script:deployScriptPath -Raw
        $content | Should -Match 'Live -Execute is disabled'
    }

    It 'all three scripts contain sessionControls with correct Graph API format' {
        foreach ($scriptPath in @($script:deployScriptPath, $script:monitorScriptPath, $script:exportScriptPath)) {
            $content = Get-Content -Path $scriptPath -Raw
            $content | Should -Match 'sessionControls' -Because (Split-Path $scriptPath -Leaf)
            $content | Should -Match 'persistentBrowser' -Because (Split-Path $scriptPath -Leaf)
            $content | Should -Match 'signInFrequency' -Because (Split-Path $scriptPath -Leaf)
        }
    }

    It 'all three scripts document duplicated utility functions' {
        foreach ($scriptPath in @($script:deployScriptPath, $script:monitorScriptPath, $script:exportScriptPath)) {
            $content = Get-Content -Path $scriptPath -Raw
            $content | Should -Match 'duplicated across' -Because (Split-Path $scriptPath -Leaf)
        }
    }

    It 'default-config.json defines an emergencyAccessExclusionGroupIds break-glass slot' {
        $config = Get-Content -Path $script:defaultConfigPath -Raw | ConvertFrom-Json -AsHashtable
        $config.defaults.ContainsKey('emergencyAccessExclusionGroupIds') | Should -BeTrue
        @($config.defaults.emergencyAccessExclusionGroupIds).Count | Should -Be 0 -Because 'the scaffold ships without a live break-glass group; operators must populate it'
    }

    It 'all three scripts model an emergency-access excludeGroups slot in generated policies' {
        foreach ($scriptPath in @($script:deployScriptPath, $script:monitorScriptPath, $script:exportScriptPath)) {
            $content = Get-Content -Path $scriptPath -Raw
            $content | Should -Match 'excludeGroups = @\(\$emergencyExclusionGroupIds\)' -Because (Split-Path $scriptPath -Leaf)
            $content | Should -Match 'requiresBreakGlassExclusion' -Because (Split-Path $scriptPath -Leaf)
        }
    }

    It 'Deploy-Solution.ps1 does not use ContainsKey on ordered policy-template collections (issue: OrderedDictionary has no ContainsKey)' {
        $content = Get-Content -Path $script:deployScriptPath -Raw
        $content | Should -Not -Match '\$_\.ContainsKey\(' -Because 'policy templates are [ordered] dictionaries; ContainsKey throws at runtime, silently defeating -Execute safety gates'
        $content | Should -Match "\`$_\.Contains\('requiresBreakGlassExclusion'\)"
    }

    It 'Deploy-Solution.ps1 generates a break-glass excludeGroups slot and flags unpopulated policies (behavioral)' {
        $outputPath = Join-Path $TestDrive 'deploy-baseline'
        $null = & $script:deployScriptPath -ConfigurationTier baseline -TenantId 'contoso.onmicrosoft.com' -OutputPath $outputPath 3>$null
        $templates = Get-Content -Path (Join-Path $outputPath 'ca-policy-templates.json') -Raw | ConvertFrom-Json
        foreach ($policy in $templates) {
            $policy.conditions.users.PSObject.Properties.Name | Should -Contain 'excludeGroups' -Because $policy.displayName
            $policy.requiresBreakGlassExclusion | Should -BeTrue -Because "$($policy.displayName) has no emergency-access exclusion configured by default"
            $policy.manualReviewRequired | Should -BeTrue -Because $policy.displayName
        }
        $graphCommands = Get-Content -Path (Join-Path $outputPath 'graph-api-commands.ps1') -Raw
        $graphCommands | Should -Match 'break-glass' -Because 'generated Graph commands must warn about excluding emergency-access accounts'
    }

    It 'Deploy-Solution.ps1 -Execute always fails closed (behavioral)' {
        $outputPath = Join-Path $TestDrive 'deploy-execute-gate'
        { & $script:deployScriptPath -ConfigurationTier baseline -TenantId 'contoso.onmicrosoft.com' -OutputPath $outputPath -Execute 3>$null } |
            Should -Throw '*Live -Execute is disabled*'
    }

    It 'Export-Evidence.ps1 builds a hash-verified evidence package and embeds the excludeGroups slot (behavioral)' {
        $packagePath = Join-Path $TestDrive 'evidence'
        $null = & $script:exportScriptPath -ConfigurationTier recommended -OutputPath $packagePath 3>$null
        $state = Get-Content -Path (Join-Path $packagePath 'ca-policy-state.json') -Raw | ConvertFrom-Json
        @($state.policies)[0].conditions.users.PSObject.Properties.Name | Should -Contain 'excludeGroups'
        foreach ($name in @(
            'ca-policy-state.json',
            'drift-alert-summary.json',
            'access-exception-register.json',
            '07-conditional-access-automation-evidence.json'
        )) {
            $file = Join-Path $packagePath $name
            Test-Path $file | Should -BeTrue -Because $name
            $shaPath = "$file.sha256"
            Test-Path $shaPath | Should -BeTrue -Because $name
            $stored = (Get-Content -Path $shaPath -Raw).Split(' ')[0]
            $actual = (Get-FileHash -Path $file -Algorithm SHA256).Hash.ToLower()
            $stored | Should -Be $actual -Because $name
        }
    }

    It 'Export-Evidence.ps1 keeps package paths relative and caller paths absolute after relocation' {
        $repoRoot = (Resolve-Path (Join-Path $solutionRoot '..\..')).Path
        Import-Module (Join-Path $repoRoot 'scripts\common\EvidenceExport.psm1') -Force

        $outputPath = Join-Path $TestDrive 'portable-evidence'
        $result = & $script:exportScriptPath -ConfigurationTier baseline -OutputPath $outputPath 3>$null
        [System.IO.Path]::IsPathRooted($result.EvidencePackagePath) | Should -BeTrue
        foreach ($artifact in @($result.Artifacts)) {
            [System.IO.Path]::IsPathRooted($artifact.path) | Should -BeTrue
        }

        $package = Get-Content -Path $result.EvidencePackagePath -Raw | ConvertFrom-Json
        foreach ($artifact in @($package.artifacts)) {
            [System.IO.Path]::IsPathRooted($artifact.path) | Should -BeFalse
        }

        $relocatedPath = Join-Path $TestDrive 'portable-evidence-relocated'
        Move-Item -Path $outputPath -Destination $relocatedPath
        $validation = Test-CopilotGovEvidencePackage `
            -Path (Join-Path $relocatedPath '07-conditional-access-automation-evidence.json') `
            -ExpectedArtifacts @('ca-policy-state', 'drift-alert-summary', 'access-exception-register')
        $validation.IsValid | Should -BeTrue -Because ($validation.Errors -join '; ')
    }

    It 'Export-Evidence.ps1 resolves relative output from the PowerShell provider location' {
        $originalProcessDirectory = [System.Environment]::CurrentDirectory
        Push-Location $TestDrive
        try {
            [System.Environment]::CurrentDirectory = $solutionRoot
            $result = & $script:exportScriptPath -ConfigurationTier baseline -OutputPath '.\provider-relative' 3>$null
            (Split-Path -Parent $result.EvidencePackagePath) | Should -Be (Join-Path $TestDrive 'provider-relative')
        }
        finally {
            [System.Environment]::CurrentDirectory = $originalProcessDirectory
            Pop-Location
        }
    }
}
