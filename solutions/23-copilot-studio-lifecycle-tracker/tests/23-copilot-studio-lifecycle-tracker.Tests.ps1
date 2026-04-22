#Requires -Version 7.2
<#
.SYNOPSIS
    Pester smoke tests for Copilot Studio Agent Lifecycle Tracker (CSLT) scaffold.
.DESCRIPTION
    Validates required files exist, configuration files contain expected fields,
    and scripts have the required parameters and comment-based help.
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

    function Get-ScriptParameterNames {
        param([string]$Path)
        $tokens = $null
        $errors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$tokens, [ref]$errors)
        if ($errors) { throw "Unable to parse script: $Path" }
        return @($ast.ParamBlock.Parameters | ForEach-Object { $_.Name.VariablePath.UserPath })
    }

    function Test-CommentBasedHelp {
        param([string]$Path)
        return ((Get-Content -Path $Path -Raw) -match '(?s)<#.*?\.SYNOPSIS')
    }
}

Describe 'CSLT - File Presence' {
    It 'has README.md' { Test-Path (Join-Path $solutionRoot 'README.md') | Should -BeTrue }
    It 'has CHANGELOG.md' { Test-Path (Join-Path $solutionRoot 'CHANGELOG.md') | Should -BeTrue }
    It 'has DELIVERY-CHECKLIST.md' { Test-Path (Join-Path $solutionRoot 'DELIVERY-CHECKLIST.md') | Should -BeTrue }
    It 'has all required config files' {
        foreach ($p in @('default-config.json','baseline.json','recommended.json','regulated.json')) {
            Test-Path (Join-Path $configPath $p) | Should -BeTrue
        }
    }
    It 'has all required doc files' {
        foreach ($p in @('architecture.md','deployment-guide.md','evidence-export.md','prerequisites.md','troubleshooting.md')) {
            Test-Path (Join-Path $docsPath $p) | Should -BeTrue
        }
    }
    It 'has all required scripts' {
        foreach ($p in @('Deploy-Solution.ps1','Monitor-Compliance.ps1','Export-Evidence.ps1','CsltConfig.psm1')) {
            Test-Path (Join-Path $scriptsPath $p) | Should -BeTrue
        }
    }
}

Describe 'CSLT - Configuration Validation' {
    Context 'default-config.json' {
        BeforeAll { $defaultConfig = Get-JsonContent -Path (Join-Path $configPath 'default-config.json') }
        It 'has correct solution slug' { $defaultConfig.solution | Should -Be '23-copilot-studio-lifecycle-tracker' }
        It 'has solution code CSLT' { $defaultConfig.solutionCode | Should -Be 'CSLT' }
        It 'has track C' { $defaultConfig.track | Should -Be 'C' }
        It 'has priority P1' { $defaultConfig.priority | Should -Be 'P1' }
        It 'declares primary controls 4.14 and 4.13' {
            $defaultConfig.primaryControls | Should -Contain '4.14'
            $defaultConfig.primaryControls | Should -Contain '4.13'
        }
        It 'declares all four evidence outputs' {
            foreach ($e in @('agent-lifecycle-inventory','publishing-approval-log','version-history','deprecation-evidence')) {
                $defaultConfig.evidenceOutputs | Should -Contain $e
            }
        }
    }

    Context 'baseline.json' {
        BeforeAll { $cfg = Get-JsonContent -Path (Join-Path $configPath 'baseline.json') }
        It 'has tier baseline' { $cfg.tier | Should -Be 'baseline' }
        It 'does not require publishing approval' { $cfg.publishingApprovalRequired | Should -BeFalse }
    }

    Context 'recommended.json' {
        BeforeAll { $cfg = Get-JsonContent -Path (Join-Path $configPath 'recommended.json') }
        It 'has tier recommended' { $cfg.tier | Should -Be 'recommended' }
        It 'requires publishing approval' { $cfg.publishingApprovalRequired | Should -BeTrue }
    }

    Context 'regulated.json' {
        BeforeAll { $cfg = Get-JsonContent -Path (Join-Path $configPath 'regulated.json') }
        It 'has tier regulated' { $cfg.tier | Should -Be 'regulated' }
        It 'requires dual approver' { $cfg.dualApproverRequired | Should -BeTrue }
        It 'has 30-day lifecycle review cadence' { $cfg.lifecycleReviewCadenceDays | Should -Be 30 }
    }
}

Describe 'CSLT - Script Validation' {
    It 'Deploy-Solution.ps1 has comment-based help' { Test-CommentBasedHelp -Path (Join-Path $scriptsPath 'Deploy-Solution.ps1') | Should -BeTrue }
    It 'Monitor-Compliance.ps1 has comment-based help' { Test-CommentBasedHelp -Path (Join-Path $scriptsPath 'Monitor-Compliance.ps1') | Should -BeTrue }
    It 'Export-Evidence.ps1 has comment-based help' { Test-CommentBasedHelp -Path (Join-Path $scriptsPath 'Export-Evidence.ps1') | Should -BeTrue }
    It 'Deploy-Solution.ps1 declares ConfigurationTier parameter' {
        Get-ScriptParameterNames -Path (Join-Path $scriptsPath 'Deploy-Solution.ps1') | Should -Contain 'ConfigurationTier'
    }
    It 'Monitor-Compliance.ps1 declares OutputPath parameter' {
        Get-ScriptParameterNames -Path (Join-Path $scriptsPath 'Monitor-Compliance.ps1') | Should -Contain 'OutputPath'
    }
    It 'Export-Evidence.ps1 declares PeriodStart parameter' {
        Get-ScriptParameterNames -Path (Join-Path $scriptsPath 'Export-Evidence.ps1') | Should -Contain 'PeriodStart'
    }
}
