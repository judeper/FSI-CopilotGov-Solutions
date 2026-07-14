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
    $script:scriptsPath = Join-Path $solutionRoot 'scripts'
    $script:configPath = Join-Path $solutionRoot 'config'
    $script:docsPath = Join-Path $solutionRoot 'docs'

    function Get-JsonContent {
        param([string]$Path)
        Get-Content -Path $Path -Raw | ConvertFrom-Json
    }

    function Get-ScriptParameterName {
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
            Test-Path (Join-Path $script:configPath $path) | Should -BeTrue
        }
    }

    It 'has all required doc files' {
        foreach ($path in @('architecture.md', 'deployment-guide.md', 'evidence-export.md', 'prerequisites.md', 'troubleshooting.md')) {
            Test-Path (Join-Path $script:docsPath $path) | Should -BeTrue
        }
    }

    It 'has all required scripts' {
        foreach ($path in @('Deploy-Solution.ps1', 'Monitor-Compliance.ps1', 'Export-Evidence.ps1', 'PnrtConfig.psm1')) {
            Test-Path (Join-Path $script:scriptsPath $path) | Should -BeTrue
        }
    }
}

Describe 'PNRT - Configuration Validation' {
    Context 'default-config.json' {
        BeforeAll {
            $script:defaultConfig = Get-JsonContent -Path (Join-Path $script:configPath 'default-config.json')
        }

        It 'has correct solution slug' {
            $script:defaultConfig.solution | Should -Be '22-pages-notebooks-retention-tracker'
        }

        It 'has solutionCode PNRT' {
            $script:defaultConfig.solutionCode | Should -Be 'PNRT'
        }

        It 'has correct track' {
            $script:defaultConfig.track | Should -Be 'D'
        }

        It 'has primary controls 3.14 and 3.2' {
            @($script:defaultConfig.primaryControls) | Should -Contain '3.14'
            @($script:defaultConfig.primaryControls) | Should -Contain '3.2'
        }

        It 'has supporting controls 3.3, 3.11, and 2.11' {
            @($script:defaultConfig.supportingControls) | Should -Contain '3.3'
            @($script:defaultConfig.supportingControls) | Should -Contain '3.11'
            @($script:defaultConfig.supportingControls) | Should -Contain '2.11'
        }

        It 'has all four evidence outputs' {
            @($script:defaultConfig.evidenceOutputs) | Should -Contain 'pages-retention-inventory'
            @($script:defaultConfig.evidenceOutputs) | Should -Contain 'notebook-retention-log'
            @($script:defaultConfig.evidenceOutputs) | Should -Contain 'loop-component-lineage'
            @($script:defaultConfig.evidenceOutputs) | Should -Contain 'branching-event-log'
        }
    }

    Context 'Each tier config' {
        It '<tier> has required fields' -ForEach @(
            @{ tier = 'baseline' },
            @{ tier = 'recommended' },
            @{ tier = 'regulated' }
        ) {
            $config = Get-JsonContent -Path (Join-Path $script:configPath ("{0}.json" -f $tier))
            $propertyNames = $config.PSObject.Properties.Name

            foreach ($requiredField in @('solution', 'tier', 'controls', 'evidenceRetentionDays', 'pagesRetentionDays', 'notebookRetentionDays', 'branchingAuditMode', 'branchingAuditRequired', 'retentionLabelCoverage', 'powerAutomateFlow')) {
                $propertyNames | Should -Contain $requiredField
            }
        }

        It 'regulated tier requires preservation lock and signed lineage' {
            $regulatedConfig = Get-JsonContent -Path (Join-Path $script:configPath 'regulated.json')
            $regulatedConfig.preservationLockRequired | Should -BeTrue
            $regulatedConfig.signedLineageRequired | Should -BeTrue
        }
    }

    Context 'PnrtConfig.psm1 range validation' {
        BeforeAll {
            Import-Module (Join-Path $script:scriptsPath 'PnrtConfig.psm1') -Force
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
                (Join-Path $script:scriptsPath 'Deploy-Solution.ps1'), [ref]$null, [ref]$errors
            ) | Out-Null
            $errors | Should -BeNullOrEmpty
        }

        It 'has comment-based help' {
            Test-CommentBasedHelp -Path (Join-Path $script:scriptsPath 'Deploy-Solution.ps1') | Should -BeTrue
        }

        It 'has ConfigurationTier parameter' {
            (Get-ScriptParameterName -Path (Join-Path $script:scriptsPath 'Deploy-Solution.ps1')) | Should -Contain 'ConfigurationTier'
        }
    }

    Context 'Monitor-Compliance.ps1' {
        It 'passes PowerShell syntax check' {
            $errors = $null
            [System.Management.Automation.Language.Parser]::ParseFile(
                (Join-Path $script:scriptsPath 'Monitor-Compliance.ps1'), [ref]$null, [ref]$errors
            ) | Out-Null
            $errors | Should -BeNullOrEmpty
        }

        It 'has ConfigurationTier and ClientSecret parameters' {
            $parameterNames = Get-ScriptParameterName -Path (Join-Path $script:scriptsPath 'Monitor-Compliance.ps1')
            $parameterNames | Should -Contain 'ConfigurationTier'
            $parameterNames | Should -Contain 'ClientSecret'
        }
    }

    Context 'Export-Evidence.ps1' {
        It 'passes PowerShell syntax check' {
            $errors = $null
            [System.Management.Automation.Language.Parser]::ParseFile(
                (Join-Path $script:scriptsPath 'Export-Evidence.ps1'), [ref]$null, [ref]$errors
            ) | Out-Null
            $errors | Should -BeNullOrEmpty
        }

        It 'has PeriodStart and PeriodEnd parameters' {
            $parameterNames = Get-ScriptParameterName -Path (Join-Path $script:scriptsPath 'Export-Evidence.ps1')
            $parameterNames | Should -Contain 'PeriodStart'
            $parameterNames | Should -Contain 'PeriodEnd'
        }
    }

    Context 'PnrtConfig.psm1' {
        It 'passes PowerShell syntax check' {
            $errors = $null
            [System.Management.Automation.Language.Parser]::ParseFile(
                (Join-Path $script:scriptsPath 'PnrtConfig.psm1'), [ref]$null, [ref]$errors
            ) | Out-Null
            $errors | Should -BeNullOrEmpty
        }
    }
}

Describe 'PNRT - Script Smoke Tests' {
    It 'runs Deploy-Solution.ps1 and writes a deployment manifest' {
        $deployOutputPath = Join-Path $smokeOutputPath 'deploy'
        $manifest = & (Join-Path $script:scriptsPath 'Deploy-Solution.ps1') -ConfigurationTier baseline -OutputPath $deployOutputPath -TenantId '00000000-0000-0000-0000-000000000000'
        $manifestPath = Join-Path $deployOutputPath '22-pages-notebooks-retention-tracker-deployment-baseline.json'

        Test-Path -Path $manifestPath -PathType Leaf | Should -BeTrue
        $manifest.solution | Should -Be '22-pages-notebooks-retention-tracker'
        $manifest.branchingAuditRequired | Should -BeTrue
    }

    It 'runs Monitor-Compliance.ps1 and writes a sample-data snapshot' {
        $monitorOutputPath = Join-Path $smokeOutputPath 'monitor'
        $snapshot = & (Join-Path $script:scriptsPath 'Monitor-Compliance.ps1') -ConfigurationTier baseline -OutputPath $monitorOutputPath -PassThru
        $snapshotPath = Join-Path $monitorOutputPath 'monitor-snapshot-baseline.json'

        Test-Path -Path $snapshotPath -PathType Leaf | Should -BeTrue
        $snapshot.RuntimeMode | Should -Be 'sample-data'
        @($snapshot.Pages).Count | Should -BeGreaterThan 0
        @($snapshot.InternalSampleLineageEvents).Count | Should -BeGreaterThan 0
        $snapshot.BranchingAuditRequired | Should -BeTrue
    }

    It 'runs Export-Evidence.ps1 and writes artifacts with matching SHA-256 companions' {
        $evidenceOutputPath = Join-Path $smokeOutputPath 'evidence'
        $result = & (Join-Path $script:scriptsPath 'Export-Evidence.ps1') -ConfigurationTier baseline -OutputPath $evidenceOutputPath -PeriodStart (Get-Date).Date.AddDays(-1) -PeriodEnd (Get-Date).Date -PassThru

        @($result.Artifacts).Count | Should -Be 4
        foreach ($artifact in @($result.Artifacts)) {
            Assert-HashCompanionMatchesFile -Path $artifact.path
        }

        Assert-HashCompanionMatchesFile -Path $result.PackagePath
    }
}

Describe 'PNRT - Read-Only WhatIf and Evidence Portability' {
    It 'Monitor-Compliance.ps1 -WhatIf returns sample data without writing a snapshot' {
        $whatIfOutputPath = Join-Path $smokeOutputPath 'monitor-whatif'
        $snapshot = & (Join-Path $script:scriptsPath 'Monitor-Compliance.ps1') -ConfigurationTier baseline -OutputPath $whatIfOutputPath -PassThru -WhatIf

        $snapshot.RuntimeMode | Should -Be 'sample-data'
        @($snapshot.Pages).Count | Should -BeGreaterThan 0
        Test-Path -Path (Join-Path $whatIfOutputPath 'monitor-snapshot-baseline.json') | Should -BeFalse
    }

    It 'Export-Evidence.ps1 -WhatIf returns a plan without writing artifacts or a package' {
        $whatIfOutputPath = Join-Path $smokeOutputPath 'export-whatif'
        $result = & (Join-Path $script:scriptsPath 'Export-Evidence.ps1') -ConfigurationTier baseline -OutputPath $whatIfOutputPath -PassThru -WhatIf

        @($result.Artifacts).Count | Should -Be 4
        $result.PackagePath | Should -BeNullOrEmpty
        foreach ($artifact in @($result.Artifacts)) {
            $artifact.hash | Should -BeNullOrEmpty
        }
        Test-Path -Path $whatIfOutputPath | Should -BeFalse
    }

    It 'Export-Evidence.ps1 records package-relative artifact paths and usable absolute return paths' {
        $exportOutputPath = Join-Path $smokeOutputPath 'export-portable'
        $result = & (Join-Path $script:scriptsPath 'Export-Evidence.ps1') -ConfigurationTier baseline -OutputPath $exportOutputPath -PassThru

        [System.IO.Path]::IsPathRooted($result.PackagePath) | Should -BeTrue
        foreach ($artifact in @($result.Artifacts)) {
            [System.IO.Path]::IsPathRooted($artifact.path) | Should -BeTrue
        }

        $package = Get-Content -Path $result.PackagePath -Raw | ConvertFrom-Json
        foreach ($artifact in @($package.artifacts)) {
            [System.IO.Path]::IsPathRooted($artifact.path) | Should -BeFalse
            $artifact.path | Should -Be ([System.IO.Path]::GetFileName($artifact.path))
        }
    }

    It 'evidence package validates after the output directory is relocated' {
        $repoRoot = (Resolve-Path (Join-Path $solutionRoot '..\..')).Path
        Import-Module (Join-Path $repoRoot 'scripts\common\EvidenceExport.psm1') -Force

        $exportOutputPath = Join-Path $smokeOutputPath 'export-relocate'
        $result = & (Join-Path $script:scriptsPath 'Export-Evidence.ps1') -ConfigurationTier baseline -OutputPath $exportOutputPath -PassThru
        $packageName = [System.IO.Path]::GetFileName($result.PackagePath)

        $relocatedPath = Join-Path $smokeOutputPath 'export-relocated'
        if (Test-Path -Path $relocatedPath) { Remove-Item -Path $relocatedPath -Recurse -Force }
        Copy-Item -Path $exportOutputPath -Destination $relocatedPath -Recurse
        Remove-Item -Path $exportOutputPath -Recurse -Force

        $validation = Test-CopilotGovEvidencePackage -Path (Join-Path $relocatedPath $packageName) -ExpectedArtifacts @('pages-retention-inventory', 'notebook-retention-log', 'loop-component-lineage', 'branching-event-log')
        $validation.IsValid | Should -BeTrue
    }
}

Describe 'PNRT - Lab Validation Contract' {
    BeforeAll {
        $script:labContractPath = Join-Path $solutionRoot 'lab\22-pages-notebooks-retention-tracker.lab.json'
    }

    It 'has a lab contract file' {
        Test-Path -Path $script:labContractPath -PathType Leaf | Should -BeTrue
    }

    It 'declares a read-only template contract with no mutations' {
        $contract = Get-JsonContent -Path $script:labContractPath
        $contract.solution.id | Should -Be '22-pages-notebooks-retention-tracker'
        $contract.solution.binding | Should -Be 'template'
        $contract.scope.cloud | Should -Be 'm365-us-commercial'
        @($contract.mutations).Count | Should -Be 0
    }

    It 'only lists controls present in controls-master.json' {
        $repoRoot = (Resolve-Path (Join-Path $solutionRoot '..\..')).Path
        $masterControls = @((Get-JsonContent -Path (Join-Path $repoRoot 'data\controls-master.json')).control_id)
        $contract = Get-JsonContent -Path $script:labContractPath
        foreach ($controlId in @($contract.controls)) {
            $masterControls | Should -Contain $controlId
        }
    }
}

Describe 'PNRT - Documentation Validation' {
    BeforeAll {
        $script:readme = Get-Content -Path (Join-Path $solutionRoot 'README.md') -Raw
        $script:evidenceExport = Get-Content -Path (Join-Path $script:docsPath 'evidence-export.md') -Raw
    }

    It 'README.md references SEC Rule 17a-4 with applicability caveat' {
        $script:readme | Should -Match 'SEC Rule 17a-4'
        $script:readme | Should -Match 'where applicable'
    }

    It 'README.md references FINRA Rule 4511' {
        $script:readme | Should -Match 'FINRA Rule 4511'
    }

    It 'evidence-export.md references all four evidence outputs' {
        $script:evidenceExport | Should -Match 'pages-retention-inventory'
        $script:evidenceExport | Should -Match 'notebook-retention-log'
        $script:evidenceExport | Should -Match 'loop-component-lineage'
        $script:evidenceExport | Should -Match 'branching-event-log'
    }
}
