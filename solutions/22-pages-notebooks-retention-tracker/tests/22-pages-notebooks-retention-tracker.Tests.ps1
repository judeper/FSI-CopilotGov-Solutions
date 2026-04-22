#Requires -Version 7.2
<#
.SYNOPSIS
    Pester tests for the Pages and Notebooks Retention Tracker (PNRT) scaffold.
.DESCRIPTION
    Validates that all required files exist, configuration files contain expected
    fields, and scripts have the required parameters and help content.
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
        if ($errors) {
            throw "Unable to parse script: $Path"
        }

        return @($ast.ParamBlock.Parameters | ForEach-Object { $_.Name.VariablePath.UserPath })
    }

    function Test-CommentBasedHelp {
        param([string]$Path)
        return ((Get-Content -Path $Path -Raw) -match '(?s)<#.*?\.SYNOPSIS')
    }
}

Describe 'PNRT - File Presence' {
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
        foreach ($path in @('default-config.json', 'baseline.json', 'recommended.json', 'regulated.json')) {
            Test-Path (Join-Path $configPath $path) | Should -BeTrue
        }
    }

    It 'has all required doc files' {
        foreach ($path in @('architecture.md', 'deployment-guide.md', 'evidence-export.md', 'prerequisites.md', 'troubleshooting.md')) {
            Test-Path (Join-Path $docsPath $path) | Should -BeTrue
        }
    }

    It 'has all required scripts' {
        foreach ($path in @('Deploy-Solution.ps1', 'Monitor-Compliance.ps1', 'Export-Evidence.ps1', 'PnrtConfig.psm1')) {
            Test-Path (Join-Path $scriptsPath $path) | Should -BeTrue
        }
    }
}

Describe 'PNRT - Configuration Validation' {
    Context 'default-config.json' {
        BeforeAll {
            $defaultConfig = Get-JsonContent -Path (Join-Path $configPath 'default-config.json')
        }

        It 'has correct solution slug' {
            $defaultConfig.solution | Should -Be '22-pages-notebooks-retention-tracker'
        }

        It 'has solutionCode PNRT' {
            $defaultConfig.solutionCode | Should -Be 'PNRT'
        }

        It 'has correct track' {
            $defaultConfig.track | Should -Be 'D'
        }

        It 'has primary controls 3.14 and 3.2' {
            @($defaultConfig.primaryControls) | Should -Contain '3.14'
            @($defaultConfig.primaryControls) | Should -Contain '3.2'
        }

        It 'has supporting controls 3.3, 3.11, and 2.11' {
            @($defaultConfig.supportingControls) | Should -Contain '3.3'
            @($defaultConfig.supportingControls) | Should -Contain '3.11'
            @($defaultConfig.supportingControls) | Should -Contain '2.11'
        }

        It 'has all four evidence outputs' {
            @($defaultConfig.evidenceOutputs) | Should -Contain 'pages-retention-inventory'
            @($defaultConfig.evidenceOutputs) | Should -Contain 'notebook-retention-log'
            @($defaultConfig.evidenceOutputs) | Should -Contain 'loop-component-lineage'
            @($defaultConfig.evidenceOutputs) | Should -Contain 'branching-event-log'
        }
    }

    Context 'Each tier config' {
        It '<tier> has required fields' -ForEach @(
            @{ tier = 'baseline' },
            @{ tier = 'recommended' },
            @{ tier = 'regulated' }
        ) {
            $config = Get-JsonContent -Path (Join-Path $configPath ("{0}.json" -f $tier))
            $propertyNames = $config.PSObject.Properties.Name

            foreach ($requiredField in @('solution', 'tier', 'controls', 'evidenceRetentionDays', 'pagesRetentionDays', 'notebookRetentionDays', 'branchingAuditMode', 'retentionLabelCoverage', 'powerAutomateFlow')) {
                $propertyNames | Should -Contain $requiredField
            }
        }

        It 'regulated tier requires preservation lock and signed lineage' {
            $regulatedConfig = Get-JsonContent -Path (Join-Path $configPath 'regulated.json')
            $regulatedConfig.preservationLockRequired | Should -BeTrue
            $regulatedConfig.signedLineageRequired | Should -BeTrue
        }
    }
}

Describe 'PNRT - Script Validation' {
    Context 'Deploy-Solution.ps1' {
        It 'passes PowerShell syntax check' {
            $errors = $null
            [System.Management.Automation.Language.Parser]::ParseFile(
                (Join-Path $scriptsPath 'Deploy-Solution.ps1'), [ref]$null, [ref]$errors
            ) | Out-Null
            $errors | Should -BeNullOrEmpty
        }

        It 'has comment-based help' {
            Test-CommentBasedHelp -Path (Join-Path $scriptsPath 'Deploy-Solution.ps1') | Should -BeTrue
        }

        It 'has ConfigurationTier parameter' {
            (Get-ScriptParameterNames -Path (Join-Path $scriptsPath 'Deploy-Solution.ps1')) | Should -Contain 'ConfigurationTier'
        }
    }

    Context 'Monitor-Compliance.ps1' {
        It 'passes PowerShell syntax check' {
            $errors = $null
            [System.Management.Automation.Language.Parser]::ParseFile(
                (Join-Path $scriptsPath 'Monitor-Compliance.ps1'), [ref]$null, [ref]$errors
            ) | Out-Null
            $errors | Should -BeNullOrEmpty
        }

        It 'has ConfigurationTier and ClientSecret parameters' {
            $parameterNames = Get-ScriptParameterNames -Path (Join-Path $scriptsPath 'Monitor-Compliance.ps1')
            $parameterNames | Should -Contain 'ConfigurationTier'
            $parameterNames | Should -Contain 'ClientSecret'
        }
    }

    Context 'Export-Evidence.ps1' {
        It 'passes PowerShell syntax check' {
            $errors = $null
            [System.Management.Automation.Language.Parser]::ParseFile(
                (Join-Path $scriptsPath 'Export-Evidence.ps1'), [ref]$null, [ref]$errors
            ) | Out-Null
            $errors | Should -BeNullOrEmpty
        }

        It 'has PeriodStart and PeriodEnd parameters' {
            $parameterNames = Get-ScriptParameterNames -Path (Join-Path $scriptsPath 'Export-Evidence.ps1')
            $parameterNames | Should -Contain 'PeriodStart'
            $parameterNames | Should -Contain 'PeriodEnd'
        }
    }

    Context 'PnrtConfig.psm1' {
        It 'passes PowerShell syntax check' {
            $errors = $null
            [System.Management.Automation.Language.Parser]::ParseFile(
                (Join-Path $scriptsPath 'PnrtConfig.psm1'), [ref]$null, [ref]$errors
            ) | Out-Null
            $errors | Should -BeNullOrEmpty
        }
    }
}

Describe 'PNRT - Documentation Validation' {
    BeforeAll {
        $readme = Get-Content -Path (Join-Path $solutionRoot 'README.md') -Raw
        $evidenceExport = Get-Content -Path (Join-Path $docsPath 'evidence-export.md') -Raw
    }

    It 'README.md references SEC Rule 17a-4 with applicability caveat' {
        $readme | Should -Match 'SEC Rule 17a-4'
        $readme | Should -Match 'where applicable'
    }

    It 'README.md references FINRA Rule 4511' {
        $readme | Should -Match 'FINRA Rule 4511'
    }

    It 'evidence-export.md references all four evidence outputs' {
        $evidenceExport | Should -Match 'pages-retention-inventory'
        $evidenceExport | Should -Match 'notebook-retention-log'
        $evidenceExport | Should -Match 'loop-component-lineage'
        $evidenceExport | Should -Match 'branching-event-log'
    }
}
