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
    $script:scriptsPath = Join-Path $solutionRoot 'scripts'
    $script:configPath = Join-Path $solutionRoot 'config'
    $script:docsPath = Join-Path $solutionRoot 'docs'

    function Get-JsonContent {
        param([string]$Path)
        Get-Content -Path $Path -Raw | ConvertFrom-Json
    }

    function Test-ScriptParse {
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
            Test-Path (Join-Path $script:configPath $p) | Should -BeTrue
        }
    }
    It 'has all required doc files' {
        foreach ($p in @('architecture.md', 'deployment-guide.md', 'evidence-export.md', 'prerequisites.md', 'troubleshooting.md')) {
            Test-Path (Join-Path $script:docsPath $p) | Should -BeTrue
        }
    }
    It 'has all required scripts' {
        foreach ($p in @('Deploy-Solution.ps1', 'Monitor-Compliance.ps1', 'Export-Evidence.ps1', 'CtafConfig.psm1')) {
            Test-Path (Join-Path $script:scriptsPath $p) | Should -BeTrue
        }
    }
}

Describe 'CTAF - Configuration Validation' {
    It 'default-config.json has correct solution slug' {
        $cfg = Get-JsonContent -Path (Join-Path $script:configPath 'default-config.json')
        $cfg.solution | Should -Be '21-cross-tenant-agent-federation-auditor'
        $cfg.solutionCode | Should -Be 'CTAF'
        $cfg.track | Should -Be 'B'
        $cfg.priority | Should -Be 'P1'
    }
    It 'default-config.json lists all four evidence outputs' {
        $cfg = Get-JsonContent -Path (Join-Path $script:configPath 'default-config.json')
        $cfg.evidenceOutputs.Count | Should -Be 4
    }
    It 'each tier file declares its tier name and primary controls' {
        foreach ($tier in @('baseline', 'recommended', 'regulated')) {
            $cfg = Get-JsonContent -Path (Join-Path $script:configPath ("{0}.json" -f $tier))
            $cfg.tier | Should -Be $tier
            $cfg.primaryControls | Should -Contain '2.17'
            $cfg.primaryControls | Should -Contain '2.16'
        }
    }
    It 'regulated tier has the strictest review cadence' {
        $b = Get-JsonContent -Path (Join-Path $script:configPath 'baseline.json')
        $r = Get-JsonContent -Path (Join-Path $script:configPath 'recommended.json')
        $g = Get-JsonContent -Path (Join-Path $script:configPath 'regulated.json')
        $g.federationReviewCadenceDays | Should -BeLessThan $r.federationReviewCadenceDays
        $r.federationReviewCadenceDays | Should -BeLessThan $b.federationReviewCadenceDays
    }
}

Describe 'CTAF - Script Parse Validation' {
    It 'Deploy-Solution.ps1 parses without errors' {
        Test-ScriptParse -Path (Join-Path $script:scriptsPath 'Deploy-Solution.ps1') | Should -BeTrue
    }
    It 'Monitor-Compliance.ps1 parses without errors' {
        Test-ScriptParse -Path (Join-Path $script:scriptsPath 'Monitor-Compliance.ps1') | Should -BeTrue
    }
    It 'Export-Evidence.ps1 parses without errors' {
        Test-ScriptParse -Path (Join-Path $script:scriptsPath 'Export-Evidence.ps1') | Should -BeTrue
    }
    It 'CtafConfig.psm1 parses without errors' {
        Test-ScriptParse -Path (Join-Path $script:scriptsPath 'CtafConfig.psm1') | Should -BeTrue
    }
}

Describe 'CTAF - Module Load' {
    It 'CtafConfig.psm1 imports and exposes required functions' {
        Import-Module (Join-Path $script:scriptsPath 'CtafConfig.psm1') -Force
        (Get-Command Get-CtafConfiguration -ErrorAction SilentlyContinue) | Should -Not -BeNullOrEmpty
        (Get-Command Test-CtafConfiguration -ErrorAction SilentlyContinue) | Should -Not -BeNullOrEmpty
        (Get-Command Write-CtafSha256File -ErrorAction SilentlyContinue) | Should -Not -BeNullOrEmpty
    }
    It 'Get-CtafConfiguration returns a hashtable for each tier' {
        Import-Module (Join-Path $script:scriptsPath 'CtafConfig.psm1') -Force
        foreach ($tier in @('baseline', 'recommended', 'regulated')) {
            $cfg = Get-CtafConfiguration -Tier $tier
            $cfg.tier | Should -Be $tier
            { Test-CtafConfiguration -Configuration $cfg } | Should -Not -Throw
        }
    }
}

Describe 'CTAF - Configuration Accuracy' {
    It 'tier files do not declare fabricated MCP or Agent ID signing/key-rotation capabilities' {
        $forbidden = @(
            'mcpTrustAttestationRequired', 'mcpAttestationRevalidationRequired', 'mcpAttestation',
            'verifySigningKey', 'maxAttestationAgeDays', 'requireExternalAttestor', 'alertOnAttestationStale',
            'agentIdSigningRequired', 'agentIdKeyRotationTrackingEnabled', 'agentIdRotation',
            'maxKeyAgeDays', 'requireDualKeyDuringRotation', 'alertOnRotationOverdue'
        )
        foreach ($tier in @('baseline', 'recommended', 'regulated')) {
            $raw = Get-Content -Path (Join-Path $script:configPath ("{0}.json" -f $tier)) -Raw
            foreach ($token in $forbidden) {
                $raw | Should -Not -Match ([regex]::Escape($token))
            }
        }
    }

    It 'tier files declare reframed connection-review and governance-review fields' {
        foreach ($tier in @('baseline', 'recommended', 'regulated')) {
            $cfg = Get-JsonContent -Path (Join-Path $script:configPath ("{0}.json" -f $tier))
            $names = $cfg.PSObject.Properties.Name
            $names | Should -Contain 'mcpConnectionReviewRequired'
            $names | Should -Contain 'agentIdGovernanceReviewRequired'
            $names | Should -Contain 'agentIdCredentialReviewEnabled'
            $names | Should -Contain 'mcpConnectionReview'
        }
    }

    It 'Get-CtafConfiguration exposes reframed keys and drops signing/key-rotation keys' {
        Import-Module (Join-Path $script:scriptsPath 'CtafConfig.psm1') -Force
        foreach ($tier in @('baseline', 'recommended', 'regulated')) {
            $cfg = Get-CtafConfiguration -Tier $tier
            $cfg.Contains('mcpConnectionReviewRequired') | Should -BeTrue
            $cfg.Contains('agentIdGovernanceReviewRequired') | Should -BeTrue
            $cfg.Contains('agentIdCredentialReviewEnabled') | Should -BeTrue
            $cfg.Contains('agentIdSigningRequired') | Should -BeFalse
            $cfg.Contains('mcpAttestation') | Should -BeFalse
        }
    }
}

Describe 'CTAF - Read-Only WhatIf and Evidence Portability' {
    BeforeAll {
        $script:smokeOutputPath = Join-Path $solutionRoot 'artifacts\pester'
        if (Test-Path -Path $script:smokeOutputPath) { Remove-Item -Path $script:smokeOutputPath -Recurse -Force }
    }
    AfterAll {
        if (Test-Path -Path $script:smokeOutputPath) { Remove-Item -Path $script:smokeOutputPath -Recurse -Force }
    }

    It 'Monitor-Compliance.ps1 -WhatIf returns sample data without writing a snapshot' {
        $whatIfOutputPath = Join-Path $script:smokeOutputPath 'monitor-whatif'
        $snapshot = & (Join-Path $script:scriptsPath 'Monitor-Compliance.ps1') -ConfigurationTier baseline -OutputPath $whatIfOutputPath -PassThru -WhatIf
        $snapshot.RuntimeMode | Should -Be 'sample'
        @($snapshot.FederationInventory).Count | Should -BeGreaterThan 0
        Test-Path -Path (Join-Path $whatIfOutputPath 'ctaf-monitoring-snapshot-baseline.json') | Should -BeFalse
    }

    It 'Export-Evidence.ps1 -WhatIf returns a plan without writing artifacts or a package' {
        $whatIfOutputPath = Join-Path $script:smokeOutputPath 'export-whatif'
        $result = & (Join-Path $script:scriptsPath 'Export-Evidence.ps1') -ConfigurationTier baseline -OutputPath $whatIfOutputPath -PassThru -WhatIf
        @($result.Artifacts).Count | Should -Be 4
        $result.PackagePath | Should -BeNullOrEmpty
        foreach ($artifact in @($result.Artifacts)) { $artifact.hash | Should -BeNullOrEmpty }
        Test-Path -Path $whatIfOutputPath | Should -BeFalse
    }

    It 'Export-Evidence.ps1 records package-relative artifact paths and usable absolute return paths' {
        $exportOutputPath = Join-Path $script:smokeOutputPath 'export-portable'
        $result = & (Join-Path $script:scriptsPath 'Export-Evidence.ps1') -ConfigurationTier baseline -OutputPath $exportOutputPath -PassThru
        [System.IO.Path]::IsPathRooted($result.PackagePath) | Should -BeTrue
        foreach ($artifact in @($result.Artifacts)) { [System.IO.Path]::IsPathRooted($artifact.path) | Should -BeTrue }
        $package = Get-Content -Path $result.PackagePath -Raw | ConvertFrom-Json
        foreach ($artifact in @($package.artifacts)) {
            [System.IO.Path]::IsPathRooted($artifact.path) | Should -BeFalse
            $artifact.path | Should -Be ([System.IO.Path]::GetFileName($artifact.path))
        }
    }

    It 'evidence package validates after the output directory is relocated' {
        $repoRoot = (Resolve-Path (Join-Path $solutionRoot '..\..')).Path
        Import-Module (Join-Path $repoRoot 'scripts\common\EvidenceExport.psm1') -Force
        $exportOutputPath = Join-Path $script:smokeOutputPath 'export-relocate'
        $result = & (Join-Path $script:scriptsPath 'Export-Evidence.ps1') -ConfigurationTier baseline -OutputPath $exportOutputPath -PassThru
        $packageName = [System.IO.Path]::GetFileName($result.PackagePath)
        $relocatedPath = Join-Path $script:smokeOutputPath 'export-relocated'
        if (Test-Path -Path $relocatedPath) { Remove-Item -Path $relocatedPath -Recurse -Force }
        Copy-Item -Path $exportOutputPath -Destination $relocatedPath -Recurse
        Remove-Item -Path $exportOutputPath -Recurse -Force
        $validation = Test-CopilotGovEvidencePackage -Path (Join-Path $relocatedPath $packageName) -ExpectedArtifacts @('agent-federation-inventory', 'cross-tenant-trust-assessment', 'mcp-trust-relationship-log', 'agent-id-attestation-evidence')
        $validation.IsValid | Should -BeTrue
    }

    It 'Monitor and Export resolve relative output from the PowerShell provider location' {
        $originalProcessDirectory = [System.Environment]::CurrentDirectory
        Push-Location $TestDrive
        try {
            [System.Environment]::CurrentDirectory = $solutionRoot
            $monitor = & (Join-Path $script:scriptsPath 'Monitor-Compliance.ps1') -ConfigurationTier baseline -OutputPath '.\provider-monitor' -PassThru
            $export = & (Join-Path $script:scriptsPath 'Export-Evidence.ps1') -ConfigurationTier baseline -OutputPath '.\provider-export' -PassThru
            (Split-Path -Parent $monitor.OutputPath) | Should -Be (Join-Path $TestDrive 'provider-monitor')
            (Split-Path -Parent $export.PackagePath) | Should -Be (Join-Path $TestDrive 'provider-export')
        }
        finally {
            [System.Environment]::CurrentDirectory = $originalProcessDirectory
            Pop-Location
        }
    }
}

Describe 'CTAF - Lab Validation Contract' {
    BeforeAll {
        $script:labContractPath = Join-Path $solutionRoot 'lab\21-cross-tenant-agent-federation-auditor.lab.json'
    }

    It 'has a lab contract file' {
        Test-Path -Path $script:labContractPath -PathType Leaf | Should -BeTrue
    }

    It 'declares a read-only template contract with no mutations' {
        $contract = Get-JsonContent -Path $script:labContractPath
        $contract.solution.id | Should -Be '21-cross-tenant-agent-federation-auditor'
        $contract.solution.binding | Should -Be 'template'
        $contract.scope.cloud | Should -Be 'm365-us-commercial'
        @($contract.mutations).Count | Should -Be 0
    }

    It 'only lists controls present in controls-master.json' {
        $repoRoot = (Resolve-Path (Join-Path $solutionRoot '..\..')).Path
        $masterControls = @((Get-JsonContent -Path (Join-Path $repoRoot 'data\controls-master.json')).control_id)
        $contract = Get-JsonContent -Path $script:labContractPath
        foreach ($controlId in @($contract.controls)) { $masterControls | Should -Contain $controlId }
    }
}
