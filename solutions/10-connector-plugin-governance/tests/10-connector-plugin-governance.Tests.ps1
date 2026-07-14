BeforeAll {
    $solutionRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
    $script:configRoot = Join-Path $solutionRoot 'config'
    $script:docsRoot = Join-Path $solutionRoot 'docs'
    $script:scriptsRoot = Join-Path $solutionRoot 'scripts'
}

Describe 'Copilot Connector and Plugin Governance solution content' {
    It 'has required configuration files' {
        @(
            'default-config.json',
            'baseline.json',
            'recommended.json',
            'regulated.json'
        ) | ForEach-Object {
            Test-Path (Join-Path $script:configRoot $_) | Should -BeTrue
        }
    }

    It 'has required documentation files' {
        @(
            'architecture.md',
            'deployment-guide.md',
            'evidence-export.md',
            'prerequisites.md',
            'troubleshooting.md'
        ) | ForEach-Object {
            Test-Path (Join-Path $script:docsRoot $_) | Should -BeTrue
        }
    }

    It 'documents comment-based help in Deploy-Solution.ps1' {
        $deployScript = Get-Content -Path (Join-Path $script:scriptsRoot 'Deploy-Solution.ps1') -Raw
        $deployScript.Contains('.SYNOPSIS') | Should -BeTrue
        $deployScript.Contains('.DESCRIPTION') | Should -BeTrue
    }

    It 'accepts the AlertOnNewConnectors parameter in Monitor-Compliance.ps1' {
        $command = Get-Command (Join-Path $script:scriptsRoot 'Monitor-Compliance.ps1')
        $command.Parameters.ContainsKey('AlertOnNewConnectors') | Should -BeTrue
    }

    It 'references the correct solution code in Export-Evidence.ps1' {
        $exportScript = Get-Content -Path (Join-Path $script:scriptsRoot 'Export-Evidence.ps1') -Raw
        $exportScript.Contains("-SolutionCode 'CPG'") | Should -BeTrue
    }

    It 'contains connector risk configuration in default-config.json' {
        $defaultConfig = Get-Content -Path (Join-Path $script:configRoot 'default-config.json') -Raw | ConvertFrom-Json -Depth 20
        ($defaultConfig.PSObject.Properties.Name -contains 'connectorRiskCategories') | Should -BeTrue
        ($defaultConfig.PSObject.Properties.Name -contains 'blockedConnectorIds') | Should -BeTrue
    }

    It 'retains regulated evidence for at least 365 days' {
        $regulatedConfig = Get-Content -Path (Join-Path $script:configRoot 'regulated.json') -Raw | ConvertFrom-Json -Depth 20
        [int]$regulatedConfig.evidenceRetentionDays | Should -BeGreaterOrEqual 365
    }

    It 'has valid PowerShell syntax in Deploy-Solution.ps1' {
        $errors = $null
        $tokens = $null
        [System.Management.Automation.Language.Parser]::ParseFile(
            (Join-Path $script:scriptsRoot 'Deploy-Solution.ps1'),
            [ref]$tokens,
            [ref]$errors
        ) | Out-Null

        $errors.Count | Should -Be 0
    }

    It 'has valid PowerShell syntax in Export-Evidence.ps1' {
        $errors = $null
        $tokens = $null
        [System.Management.Automation.Language.Parser]::ParseFile(
            (Join-Path $script:scriptsRoot 'Export-Evidence.ps1'),
            [ref]$tokens,
            [ref]$errors
        ) | Out-Null

        $errors.Count | Should -Be 0
    }

    It 'has valid PowerShell syntax in Monitor-Compliance.ps1' {
        $errors = $null
        $tokens = $null
        [System.Management.Automation.Language.Parser]::ParseFile(
            (Join-Path $script:scriptsRoot 'Monitor-Compliance.ps1'),
            [ref]$tokens,
            [ref]$errors
        ) | Out-Null

        $errors.Count | Should -Be 0
    }
}

Describe 'CPG evidence portability and honesty' {
    BeforeAll {
        $script:solutionRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
        $script:repoRoot = (Resolve-Path (Join-Path $script:solutionRoot '..\..')).Path
        $script:exportScriptPath = Join-Path $script:solutionRoot 'scripts\Export-Evidence.ps1'
        Import-Module (Join-Path $script:repoRoot 'scripts\common\EvidenceExport.psm1') -Force
    }

    It 'stores package-relative paths, returns absolute paths, reports partial-only controls, and validates after relocation' {
        $outputPath = Join-Path $TestDrive 'portable-evidence'
        $result = & $script:exportScriptPath -ConfigurationTier regulated -OutputPath $outputPath

        [System.IO.Path]::IsPathRooted($result.Package.Path) | Should -BeTrue
        foreach ($artifact in @($result.Artifacts)) {
            [System.IO.Path]::IsPathRooted($artifact.path) | Should -BeTrue
        }

        $package = Get-Content -Path $result.Package.Path -Raw | ConvertFrom-Json
        foreach ($artifact in @($package.artifacts)) {
            [System.IO.Path]::IsPathRooted($artifact.path) | Should -BeFalse
        }
        @($package.controls | Where-Object { $_.status -eq 'implemented' }).Count | Should -Be 0
        $package.metadata.runtimeMode | Should -Be 'documentation-first'
        $package.metadata.dataSourceMode | Should -Be 'representative-sample'

        $relocatedPath = Join-Path $TestDrive 'portable-evidence-relocated'
        Move-Item -Path $outputPath -Destination $relocatedPath
        $validation = Test-CopilotGovEvidencePackage `
            -Path (Join-Path $relocatedPath '10-connector-plugin-governance-evidence.json') `
            -ExpectedArtifacts @('connector-inventory', 'approval-register', 'data-flow-attestations')
        $validation.IsValid | Should -BeTrue -Because ($validation.Errors -join '; ')
    }

    It 'resolves relative output from the PowerShell provider location' {
        $originalProcessDirectory = [System.Environment]::CurrentDirectory
        Push-Location $TestDrive
        try {
            [System.Environment]::CurrentDirectory = $script:solutionRoot
            $result = & $script:exportScriptPath -ConfigurationTier baseline -OutputPath '.\provider-relative'
            (Split-Path -Parent $result.Package.Path) | Should -Be (Join-Path $TestDrive 'provider-relative')
        }
        finally {
            [System.Environment]::CurrentDirectory = $originalProcessDirectory
            Pop-Location
        }
    }
}

Describe 'CPG documentation currency' {
    BeforeAll {
        $script:solutionRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
        $script:readme = Get-Content -Path (Join-Path $script:solutionRoot 'README.md') -Raw
        $script:architecture = Get-Content -Path (Join-Path $script:solutionRoot 'docs\architecture.md') -Raw
        $script:prerequisites = Get-Content -Path (Join-Path $script:solutionRoot 'docs\prerequisites.md') -Raw
        $script:defaultConfig = Get-Content -Path (Join-Path $script:solutionRoot 'config\default-config.json') -Raw | ConvertFrom-Json
    }

    It 'documents the synced and federated Copilot connector models and MCP' {
        $script:readme | Should -Match 'synced connectors'
        $script:readme | Should -Match 'federated connectors'
        $script:readme | Should -Match 'Model Context Protocol'
        $script:readme | Should -Match 'early access preview'
    }

    It 'documents the Microsoft Agent 365 registry, Entra Agent ID, and least-privilege AI Reader role' {
        $script:readme | Should -Match 'Microsoft Agent 365'
        $script:readme | Should -Match 'Entra Agent ID'
        $script:readme | Should -Match 'AI Reader'
        $script:architecture | Should -Match 'Agents > All agents > Registry'
    }

    It 'documents the Agent 365 Package Management API as preview and read-only for this lab cycle' {
        $script:readme | Should -Match 'Package Management API'
        $script:readme | Should -Match 'CopilotPackages\.Read\.All'
        $script:architecture | Should -Match '/v1\.0/copilot/admin/catalog/packages'
        $script:prerequisites | Should -Match 'Microsoft Agent 365 license'
    }

    It 'uses current sample connector IDs in the blocked list' {
        $blocked = @($script:defaultConfig.blockedConnectorIds)
        $blocked | Should -Contain 'shared_twitter'
        $blocked | Should -Not -Contain 'shared_x'
        $blocked | Should -Not -Contain 'shared_boxpersonal'
    }
}

Describe 'CPG lab contract' {
    BeforeAll {
        $script:solutionRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
        $script:labContractPath = Join-Path $script:solutionRoot 'lab\10-connector-plugin-governance.lab.json'
    }

    It 'ships a read-only lab validation contract' {
        Test-Path -Path $script:labContractPath | Should -BeTrue
        $contract = Get-Content -Path $script:labContractPath -Raw | ConvertFrom-Json
        $contract.solution.id | Should -Be '10-connector-plugin-governance'
        @($contract.mutations).Count | Should -Be 0
        $contract.scope.cloud | Should -Be 'm365-us-commercial'
    }
}
