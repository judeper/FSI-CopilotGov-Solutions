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
            Test-Path (Join-Path $script:configPath $p) | Should -BeTrue
        }
    }
    It 'has all required doc files' {
        foreach ($p in @('architecture.md','deployment-guide.md','evidence-export.md','prerequisites.md','troubleshooting.md')) {
            Test-Path (Join-Path $script:docsPath $p) | Should -BeTrue
        }
    }
    It 'has all required scripts' {
        foreach ($p in @('Deploy-Solution.ps1','Monitor-Compliance.ps1','Export-Evidence.ps1','CsltConfig.psm1')) {
            Test-Path (Join-Path $script:scriptsPath $p) | Should -BeTrue
        }
    }
}

Describe 'CSLT - Configuration Validation' {
    Context 'default-config.json' {
        BeforeAll { $script:defaultConfig = Get-JsonContent -Path (Join-Path $script:configPath 'default-config.json') }
        It 'has correct solution slug' { $script:defaultConfig.solution | Should -Be '23-copilot-studio-lifecycle-tracker' }
        It 'has solution code CSLT' { $script:defaultConfig.solutionCode | Should -Be 'CSLT' }
        It 'has track C' { $script:defaultConfig.track | Should -Be 'C' }
        It 'has priority P1' { $script:defaultConfig.priority | Should -Be 'P1' }
        It 'declares primary controls 4.14 and 4.13' {
            $script:defaultConfig.primaryControls | Should -Contain '4.14'
            $script:defaultConfig.primaryControls | Should -Contain '4.13'
        }
        It 'declares all four evidence outputs' {
            foreach ($e in @('agent-lifecycle-inventory','publishing-approval-log','version-history','deprecation-evidence')) {
                $script:defaultConfig.evidenceOutputs | Should -Contain $e
            }
        }
    }

    Context 'baseline.json' {
        BeforeAll { $script:cfg = Get-JsonContent -Path (Join-Path $script:configPath 'baseline.json') }
        It 'has tier baseline' { $script:cfg.tier | Should -Be 'baseline' }
        It 'does not require publishing approval' { $script:cfg.publishingApprovalRequired | Should -BeFalse }
    }

    Context 'recommended.json' {
        BeforeAll { $script:cfg = Get-JsonContent -Path (Join-Path $script:configPath 'recommended.json') }
        It 'has tier recommended' { $script:cfg.tier | Should -Be 'recommended' }
        It 'requires publishing approval' { $script:cfg.publishingApprovalRequired | Should -BeTrue }
    }

    Context 'regulated.json' {
        BeforeAll { $script:cfg = Get-JsonContent -Path (Join-Path $script:configPath 'regulated.json') }
        It 'has tier regulated' { $script:cfg.tier | Should -Be 'regulated' }
        It 'requires dual approver' { $script:cfg.dualApproverRequired | Should -BeTrue }
        It 'has 30-day lifecycle review cadence' { $script:cfg.lifecycleReviewCadenceDays | Should -Be 30 }
    }
}

Describe 'CSLT - Script Validation' {
    It 'Deploy-Solution.ps1 has comment-based help' { Test-CommentBasedHelp -Path (Join-Path $script:scriptsPath 'Deploy-Solution.ps1') | Should -BeTrue }
    It 'Monitor-Compliance.ps1 has comment-based help' { Test-CommentBasedHelp -Path (Join-Path $script:scriptsPath 'Monitor-Compliance.ps1') | Should -BeTrue }
    It 'Export-Evidence.ps1 has comment-based help' { Test-CommentBasedHelp -Path (Join-Path $script:scriptsPath 'Export-Evidence.ps1') | Should -BeTrue }
    It 'Deploy-Solution.ps1 declares ConfigurationTier parameter' {
        Get-ScriptParameterName -Path (Join-Path $script:scriptsPath 'Deploy-Solution.ps1') | Should -Contain 'ConfigurationTier'
    }
    It 'Monitor-Compliance.ps1 declares OutputPath parameter' {
        Get-ScriptParameterName -Path (Join-Path $script:scriptsPath 'Monitor-Compliance.ps1') | Should -Contain 'OutputPath'
    }
    It 'Export-Evidence.ps1 declares PeriodStart parameter' {
        Get-ScriptParameterName -Path (Join-Path $script:scriptsPath 'Export-Evidence.ps1') | Should -Contain 'PeriodStart'
    }
}

Describe 'CSLT - Lab Contract' {
    BeforeAll {
        $script:labPath = Join-Path $solutionRoot 'lab\23-copilot-studio-lifecycle-tracker.lab.json'
        if (Test-Path $script:labPath) { $script:lab = Get-JsonContent -Path $script:labPath }
    }
    It 'has a lab contract file' { Test-Path $script:labPath | Should -BeTrue }
    It 'declares the matching solution id' { $script:lab.solution.id | Should -Be '23-copilot-studio-lifecycle-tracker' }
    It 'is read-only with an empty mutations array' { @($script:lab.mutations).Count | Should -Be 0 }
    It 'sets US commercial scope' {
        $script:lab.scope.cloud | Should -Be 'm365-us-commercial'
        $script:lab.scope.usCommercialOnly | Should -BeTrue
    }
    It 'uses only null mutation references in every step' {
        $rawContract = Get-Content -Path $script:labPath -Raw
        $withoutNullMutationRefs = [regex]::Replace($rawContract, '"mutationRef"\s*:\s*null', '')
        $withoutNullMutationRefs | Should -Not -Match '"mutationRef"'
    }
    It 'declares only controls present in the framework control set' {
        $allowedControls = @('4.13','1.10','1.16','4.5','4.12')
        @($script:lab.controls | Where-Object { $_ -notin $allowedControls }) | Should -BeNullOrEmpty
    }
}

Describe 'CSLT - Evidence portability and provider paths' {
    BeforeAll {
        $script:solutionRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
        $script:repoRoot = (Resolve-Path (Join-Path $script:solutionRoot '..\..')).Path
        $script:deployScript = Join-Path $script:solutionRoot 'scripts\Deploy-Solution.ps1'
        $script:monitorScript = Join-Path $script:solutionRoot 'scripts\Monitor-Compliance.ps1'
        $script:exportScript = Join-Path $script:solutionRoot 'scripts\Export-Evidence.ps1'
        Import-Module (Join-Path $script:repoRoot 'scripts\common\EvidenceExport.psm1') -Force
    }

    It 'stores package-relative paths, returns absolute paths, and validates after relocation' {
        $outputPath = Join-Path $TestDrive 'portable-evidence'
        $result = & $script:exportScript -ConfigurationTier baseline -OutputPath $outputPath -PassThru
        [System.IO.Path]::IsPathRooted($result.PackagePath) | Should -BeTrue
        foreach ($artifact in @($result.Artifacts)) {
            [System.IO.Path]::IsPathRooted($artifact.path) | Should -BeTrue
        }

        foreach ($artifact in @($result.Package.artifacts)) {
            [System.IO.Path]::IsPathRooted($artifact.path) | Should -BeFalse
        }

        $relocatedPath = Join-Path $TestDrive 'portable-evidence-relocated'
        Move-Item -Path $outputPath -Destination $relocatedPath
        $validation = Test-CopilotGovEvidencePackage `
            -Path (Join-Path $relocatedPath '23-copilot-studio-lifecycle-tracker-evidence.json') `
            -ExpectedArtifacts @('agent-lifecycle-inventory', 'publishing-approval-log', 'version-history', 'deprecation-evidence')
        $validation.IsValid | Should -BeTrue -Because ($validation.Errors -join '; ')
    }

    It 'resolves relative output from the PowerShell provider location' {
        $originalProcessDirectory = [System.Environment]::CurrentDirectory
        Push-Location $TestDrive
        try {
            [System.Environment]::CurrentDirectory = $script:solutionRoot
            $deploy = & $script:deployScript -ConfigurationTier baseline -OutputPath '.\provider-deploy'
            $monitor = & $script:monitorScript -ConfigurationTier baseline -OutputPath '.\provider-monitor' -PassThru
            $export = & $script:exportScript -ConfigurationTier baseline -OutputPath '.\provider-export' -PassThru
            $deploy.outputPath | Should -Be (Join-Path $TestDrive 'provider-deploy')
            (Split-Path -Parent $monitor.outputPath) | Should -Be (Join-Path $TestDrive 'provider-monitor')
            (Split-Path -Parent $export.PackagePath) | Should -Be (Join-Path $TestDrive 'provider-export')
        }
        finally {
            [System.Environment]::CurrentDirectory = $originalProcessDirectory
            Pop-Location
        }
    }
}
