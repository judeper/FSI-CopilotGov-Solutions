#Requires -Version 7.2
<#
.SYNOPSIS
    Pester tests for the Pages and Notebooks Retention Tracker (PNRT) scaffold.
.DESCRIPTION
    Validates that all required files exist, configuration files contain expected
    fields, scripts have the required parameters and help content, and sample-data
    smoke tests produce expected artifacts.
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

    function Assert-HashCompanionMatchesFile {
        param([string]$Path)

        Test-Path -Path $Path -PathType Leaf | Should -BeTrue
        $hashPath = "$Path.sha256"
        Test-Path -Path $hashPath -PathType Leaf | Should -BeTrue

        $actualHash = (Get-FileHash -Path $Path -Algorithm SHA256).Hash.ToLowerInvariant()
        $hashLine = (Get-Content -Path $hashPath -Raw -Encoding utf8).Trim()
        $fileNamePattern = [regex]::Escape([IO.Path]::GetFileName($Path))

        $hashLine | Should -Match ("^[0-9a-f]{{64}}  {0}$" -f $fileNamePattern)
        (($hashLine -split '\s+')[0]) | Should -Be $actualHash
    }

    $smokeOutputPath = Join-Path $solutionRoot 'artifacts\pester-smoke'
    if (Test-Path -Path $smokeOutputPath) {
        Remove-Item -Path $smokeOutputPath -Recurse -Force
    }
}

AfterAll {
    if ($smokeOutputPath -and (Test-Path -Path $smokeOutputPath)) {
        Remove-Item -Path $smokeOutputPath -Recurse -Force
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

            foreach ($requiredField in @('solution', 'tier', 'controls', 'evidenceRetentionDays', 'pagesRetentionDays', 'notebookRetentionDays', 'branchingAuditMode', 'branchingAuditRequired', 'retentionLabelCoverage', 'powerAutomateFlow')) {
                $propertyNames | Should -Contain $requiredField
            }
        }

        It 'regulated tier requires preservation lock and signed lineage' {
            $regulatedConfig = Get-JsonContent -Path (Join-Path $configPath 'regulated.json')
            $regulatedConfig.preservationLockRequired | Should -BeTrue
            $regulatedConfig.signedLineageRequired | Should -BeTrue
        }
    }

    Context 'PnrtConfig.psm1 range validation' {
        BeforeAll {
            Import-Module (Join-Path $scriptsPath 'PnrtConfig.psm1') -Force
        }

        It 'rejects zero, negative, and out-of-range numeric settings' {
            $zeroPages = Get-PnrtConfiguration -Tier baseline
            $zeroPages['pagesRetentionDays'] = 0
            { Test-PnrtConfiguration -Configuration $zeroPages } | Should -Throw '*pagesRetentionDays*'

            $negativeNotebook = Get-PnrtConfiguration -Tier baseline
            $negativeNotebook['notebookRetentionDays'] = -1
            { Test-PnrtConfiguration -Configuration $negativeNotebook } | Should -Throw '*notebookRetentionDays*'

            $zeroEvidence = Get-PnrtConfiguration -Tier baseline
            $zeroEvidence['evidenceRetentionDays'] = 0
            { Test-PnrtConfiguration -Configuration $zeroEvidence } | Should -Throw '*evidenceRetentionDays*'

            $invalidCoverage = Get-PnrtConfiguration -Tier baseline
            $invalidCoverage['retentionLabelCoverage']['minimumCoveragePct'] = 101
            { Test-PnrtConfiguration -Configuration $invalidCoverage } | Should -Throw '*minimumCoveragePct*'
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

Describe 'PNRT - Script Smoke Tests' {
    It 'runs Deploy-Solution.ps1 and writes a deployment manifest' {
        $deployOutputPath = Join-Path $smokeOutputPath 'deploy'
        $manifest = & (Join-Path $scriptsPath 'Deploy-Solution.ps1') -ConfigurationTier baseline -OutputPath $deployOutputPath -TenantId '00000000-0000-0000-0000-000000000000'
        $manifestPath = Join-Path $deployOutputPath '22-pages-notebooks-retention-tracker-deployment-baseline.json'

        Test-Path -Path $manifestPath -PathType Leaf | Should -BeTrue
        $manifest.solution | Should -Be '22-pages-notebooks-retention-tracker'
        $manifest.branchingAuditRequired | Should -BeTrue
    }

    It 'runs Monitor-Compliance.ps1 and writes a sample-data snapshot' {
        $monitorOutputPath = Join-Path $smokeOutputPath 'monitor'
        $snapshot = & (Join-Path $scriptsPath 'Monitor-Compliance.ps1') -ConfigurationTier baseline -OutputPath $monitorOutputPath -PassThru
        $snapshotPath = Join-Path $monitorOutputPath 'monitor-snapshot-baseline.json'

        Test-Path -Path $snapshotPath -PathType Leaf | Should -BeTrue
        $snapshot.RuntimeMode | Should -Be 'sample-data'
        @($snapshot.Pages).Count | Should -BeGreaterThan 0
        @($snapshot.InternalSampleLineageEvents).Count | Should -BeGreaterThan 0
        $snapshot.BranchingAuditRequired | Should -BeTrue
    }

    It 'runs Export-Evidence.ps1 and writes artifacts with matching SHA-256 companions' {
        $evidenceOutputPath = Join-Path $smokeOutputPath 'evidence'
        $result = & (Join-Path $scriptsPath 'Export-Evidence.ps1') -ConfigurationTier baseline -OutputPath $evidenceOutputPath -PeriodStart (Get-Date).Date.AddDays(-1) -PeriodEnd (Get-Date).Date -PassThru

        @($result.Artifacts).Count | Should -Be 4
        foreach ($artifact in @($result.Artifacts)) {
            Assert-HashCompanionMatchesFile -Path $artifact.path
        }

        Assert-HashCompanionMatchesFile -Path $result.PackagePath
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
