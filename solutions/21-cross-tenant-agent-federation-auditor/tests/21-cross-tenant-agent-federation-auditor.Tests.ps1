#Requires -Version 7.2
<#
.SYNOPSIS
    Pester smoke tests for the Cross-Tenant Agent Federation Auditor (CTAF) scaffold.
.DESCRIPTION
    Validates that required files exist, configuration files contain the expected
    fields, scripts parse cleanly, and the shared CtafConfig.psm1 module loads.
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

    function Test-ScriptParses {
        param([string]$Path)
        $tokens = $null
        $errors = $null
        $null = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$tokens, [ref]$errors)
        return (-not $errors -or $errors.Count -eq 0)
    }
}

Describe 'CTAF - File Presence' {
    It 'has README.md' {
        Test-Path (Join-Path $solutionRoot 'README.md') | Should -BeTrue
    }
    It 'has CHANGELOG.md' {
        Test-Path (Join-Path $solutionRoot 'CHANGELOG.md') | Should -BeTrue
    }
    It 'has DELIVERY-CHECKLIST.md' {
        Test-Path (Join-Path $solutionRoot 'DELIVERY-CHECKLIST.md') | Should -BeTrue
    }
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
        foreach ($p in @('Deploy-Solution.ps1', 'Monitor-Compliance.ps1', 'Export-Evidence.ps1', 'CtafConfig.psm1')) {
            Test-Path (Join-Path $scriptsPath $p) | Should -BeTrue
        }
    }
}

Describe 'CTAF - Configuration Validation' {
    It 'default-config.json has correct solution slug' {
        $cfg = Get-JsonContent -Path (Join-Path $configPath 'default-config.json')
        $cfg.solution | Should -Be '21-cross-tenant-agent-federation-auditor'
        $cfg.solutionCode | Should -Be 'CTAF'
        $cfg.track | Should -Be 'B'
        $cfg.priority | Should -Be 'P1'
    }
    It 'default-config.json lists all four evidence outputs' {
        $cfg = Get-JsonContent -Path (Join-Path $configPath 'default-config.json')
        $cfg.evidenceOutputs.Count | Should -Be 4
    }
    It 'each tier file declares its tier name and primary controls' {
        foreach ($tier in @('baseline', 'recommended', 'regulated')) {
            $cfg = Get-JsonContent -Path (Join-Path $configPath ("{0}.json" -f $tier))
            $cfg.tier | Should -Be $tier
            $cfg.primaryControls | Should -Contain '2.17'
            $cfg.primaryControls | Should -Contain '2.16'
        }
    }
    It 'regulated tier has the strictest review cadence' {
        $b = Get-JsonContent -Path (Join-Path $configPath 'baseline.json')
        $r = Get-JsonContent -Path (Join-Path $configPath 'recommended.json')
        $g = Get-JsonContent -Path (Join-Path $configPath 'regulated.json')
        $g.federationReviewCadenceDays | Should -BeLessThan $r.federationReviewCadenceDays
        $r.federationReviewCadenceDays | Should -BeLessThan $b.federationReviewCadenceDays
    }
}

Describe 'CTAF - Script Parse Validation' {
    It 'Deploy-Solution.ps1 parses without errors' {
        Test-ScriptParses -Path (Join-Path $scriptsPath 'Deploy-Solution.ps1') | Should -BeTrue
    }
    It 'Monitor-Compliance.ps1 parses without errors' {
        Test-ScriptParses -Path (Join-Path $scriptsPath 'Monitor-Compliance.ps1') | Should -BeTrue
    }
    It 'Export-Evidence.ps1 parses without errors' {
        Test-ScriptParses -Path (Join-Path $scriptsPath 'Export-Evidence.ps1') | Should -BeTrue
    }
    It 'CtafConfig.psm1 parses without errors' {
        Test-ScriptParses -Path (Join-Path $scriptsPath 'CtafConfig.psm1') | Should -BeTrue
    }
}

Describe 'CTAF - Module Load' {
    It 'CtafConfig.psm1 imports and exposes required functions' {
        Import-Module (Join-Path $scriptsPath 'CtafConfig.psm1') -Force
        (Get-Command Get-CtafConfiguration -ErrorAction SilentlyContinue) | Should -Not -BeNullOrEmpty
        (Get-Command Test-CtafConfiguration -ErrorAction SilentlyContinue) | Should -Not -BeNullOrEmpty
        (Get-Command Write-CtafSha256File -ErrorAction SilentlyContinue) | Should -Not -BeNullOrEmpty
    }
    It 'Get-CtafConfiguration returns a hashtable for each tier' {
        Import-Module (Join-Path $scriptsPath 'CtafConfig.psm1') -Force
        foreach ($tier in @('baseline', 'recommended', 'regulated')) {
            $cfg = Get-CtafConfiguration -Tier $tier
            $cfg.tier | Should -Be $tier
            { Test-CtafConfiguration -Configuration $cfg } | Should -Not -Throw
        }
    }
}
