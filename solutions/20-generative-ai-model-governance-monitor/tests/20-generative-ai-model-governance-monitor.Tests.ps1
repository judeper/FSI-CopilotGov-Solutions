#Requires -Version 7.2
<#
.SYNOPSIS
    Pester smoke tests for the Generative AI Model Governance Monitor (GMG) scaffold.

.DESCRIPTION
    Validates that all required files exist, configuration files contain expected
    fields, scripts parse, and config loads through GmgConfig.psm1.
#>

BeforeAll {
    $solutionRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
    $scriptsPath = Join-Path $solutionRoot 'scripts'
    $configPath = Join-Path $solutionRoot 'config'
    $docsPath = Join-Path $solutionRoot 'docs'

    function Get-JsonContent {
        param([string]$Path)
        Get-Content -Path $Path -Raw | ConvertFrom-Json
    }

    function Test-PowerShellParse {
        param([string]$Path)
        $errors = $null
        [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$null, [ref]$errors) | Out-Null
        return (-not $errors)
    }
}

Describe 'GMG - File Presence' {
    It 'has README.md'             { Test-Path (Join-Path $solutionRoot 'README.md')             | Should -BeTrue }
    It 'has CHANGELOG.md'          { Test-Path (Join-Path $solutionRoot 'CHANGELOG.md')          | Should -BeTrue }
    It 'has DELIVERY-CHECKLIST.md' { Test-Path (Join-Path $solutionRoot 'DELIVERY-CHECKLIST.md') | Should -BeTrue }

    It 'has all required config files' {
        foreach ($p in @('default-config.json', 'baseline.json', 'recommended.json', 'regulated.json')) {
            Test-Path (Join-Path $configPath $p) | Should -BeTrue
        }
    }

    It 'has all required doc files' {
        foreach ($p in @('architecture.md', 'deployment-guide.md', 'evidence-export.md', 'prerequisites.md', 'troubleshooting.md')) {
            Test-Path (Join-Path $docsPath $p) | Should -BeTrue
        }
    }

    It 'has all required scripts' {
        foreach ($p in @('Deploy-Solution.ps1', 'Monitor-Compliance.ps1', 'Export-Evidence.ps1', 'GmgConfig.psm1')) {
            Test-Path (Join-Path $scriptsPath $p) | Should -BeTrue
        }
    }
}

Describe 'GMG - Configuration Validation' {
    Context 'default-config.json' {
        BeforeAll { $defaultConfig = Get-JsonContent -Path (Join-Path $configPath 'default-config.json') }

        It 'has correct solution slug' { $defaultConfig.solution     | Should -Be '20-generative-ai-model-governance-monitor' }
        It 'has solutionCode GMG'      { $defaultConfig.solutionCode | Should -Be 'GMG' }
        It 'has track D'               { $defaultConfig.track        | Should -Be 'D' }
        It 'has primary controls 3.8a and 3.8' {
            @($defaultConfig.primaryControls) | Should -Contain '3.8a'
            @($defaultConfig.primaryControls) | Should -Contain '3.8'
        }
        It 'cites Federal Reserve SR 11-7 and OCC Bulletin 2011-12' {
            @($defaultConfig.regulations) | Should -Contain 'Federal Reserve SR 11-7'
            @($defaultConfig.regulations) | Should -Contain 'OCC Bulletin 2011-12 (Supervisory Guidance on Model Risk Management)'
        }
        It 'lists all four evidence outputs' {
            foreach ($e in @('copilot-model-inventory', 'validation-summary', 'ongoing-monitoring-log', 'third-party-due-diligence')) {
                @($defaultConfig.evidenceOutputs) | Should -Contain $e
            }
        }
    }

    Context 'Each tier config' {
        It '<tier> has required fields' -ForEach @(
            @{ tier = 'baseline' }, @{ tier = 'recommended' }, @{ tier = 'regulated' }
        ) {
            $config = Get-JsonContent -Path (Join-Path $configPath ("{0}.json" -f $tier))
            $propertyNames = $config.PSObject.Properties.Name
            foreach ($f in @('solution', 'tier', 'controls', 'model_inventory_review_cadence_days', 'monitoring_log_retention_days', 'validation_assessment_required', 'third_party_review_cadence_days', 'ongoingMonitoring', 'evidenceRetentionDays', 'notificationMode')) {
                $propertyNames | Should -Contain $f
            }
        }

        It 'regulated tier requires independent challenge' {
            $regulated = Get-JsonContent -Path (Join-Path $configPath 'regulated.json')
            $regulated.independentChallenge.enabled | Should -BeTrue
            $regulated.validation_assessment_required | Should -Match 'independent-challenge'
        }
    }
}

Describe 'GMG - Script Parse Validation' {
    It '<script> parses' -ForEach @(
        @{ script = 'Deploy-Solution.ps1' },
        @{ script = 'Monitor-Compliance.ps1' },
        @{ script = 'Export-Evidence.ps1' },
        @{ script = 'GmgConfig.psm1' }
    ) {
        Test-PowerShellParse -Path (Join-Path $scriptsPath $script) | Should -BeTrue
    }
}

Describe 'GMG - Config Loader Smoke Test' {
    BeforeAll {
        Import-Module (Join-Path $scriptsPath 'GmgConfig.psm1') -Force
    }

    It 'Get-GmgConfiguration loads <tier> tier' -ForEach @(
        @{ tier = 'baseline' }, @{ tier = 'recommended' }, @{ tier = 'regulated' }
    ) {
        $config = Get-GmgConfiguration -Tier $tier
        $config.tier | Should -Be $tier
        { Test-GmgConfiguration -Configuration $config } | Should -Not -Throw
    }
}

Describe 'GMG - Documentation Validation' {
    BeforeAll {
        $readme        = Get-Content -Path (Join-Path $solutionRoot 'README.md') -Raw
        $architecture  = Get-Content -Path (Join-Path $docsPath 'architecture.md') -Raw
        $evidenceExport = Get-Content -Path (Join-Path $docsPath 'evidence-export.md') -Raw
    }

    It 'README references SR 26-2 / OCC Bulletin 2026-13' { $readme | Should -Match 'SR 26-2 / OCC Bulletin 2026-13' }
    It 'README references SR 11-7' { $readme | Should -Match 'SR 11-7' }
    It 'README references all primary controls' {
        $readme | Should -Match '3\.8a'
        $readme | Should -Match '3\.8'
    }
    It 'architecture.md references SR 11-7' { $architecture | Should -Match 'SR 11-7' }
    It 'evidence-export.md references all four outputs' {
        $evidenceExport | Should -Match 'copilot-model-inventory'
        $evidenceExport | Should -Match 'validation-summary'
        $evidenceExport | Should -Match 'ongoing-monitoring-log'
        $evidenceExport | Should -Match 'third-party-due-diligence'
    }
}
