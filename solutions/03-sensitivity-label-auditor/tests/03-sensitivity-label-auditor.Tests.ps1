BeforeAll {
    $solutionRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
    $script:expectedControls = @('1.5', '2.2', '3.11', '3.12')
    $script:scriptPaths = @(
        Join-Path $solutionRoot 'scripts\Deploy-Solution.ps1'
        Join-Path $solutionRoot 'scripts\Monitor-Compliance.ps1'
        Join-Path $solutionRoot 'scripts\Export-Evidence.ps1'
    )
}

Describe 'Solution structure' {
    It 'contains the required root files' {
        Test-Path (Join-Path $solutionRoot 'README.md') | Should -BeTrue
        Test-Path (Join-Path $solutionRoot 'CHANGELOG.md') | Should -BeTrue
        Test-Path (Join-Path $solutionRoot 'DELIVERY-CHECKLIST.md') | Should -BeTrue
    }

    It 'contains all required documentation files' {
        $requiredDocs = @(
            'docs\architecture.md'
            'docs\deployment-guide.md'
            'docs\evidence-export.md'
            'docs\prerequisites.md'
            'docs\troubleshooting.md'
        )

        foreach ($relativePath in $requiredDocs) {
            Test-Path (Join-Path $solutionRoot $relativePath) | Should -BeTrue
        }
    }

    It 'contains required scripts and configuration files' {
        $requiredFiles = @(
            'scripts\Deploy-Solution.ps1'
            'scripts\Monitor-Compliance.ps1'
            'scripts\Export-Evidence.ps1'
            'config\default-config.json'
            'config\baseline.json'
            'config\recommended.json'
            'config\regulated.json'
        )

        foreach ($relativePath in $requiredFiles) {
            Test-Path (Join-Path $solutionRoot $relativePath) | Should -BeTrue
        }
    }
}

Describe 'Configuration content' {
    It 'default config exposes workloads and coverage threshold' {
        $config = Get-Content (Join-Path $solutionRoot 'config\default-config.json') -Raw | ConvertFrom-Json -Depth 20
        $config.PSObject.Properties.Name | Should -Contain 'workloadsToAudit'
        $config.PSObject.Properties.Name | Should -Contain 'coverageThreshold'
        @($config.workloadsToAudit) | Should -Contain 'sharePoint'
        @($config.workloadsToAudit) | Should -Contain 'oneDrive'
        @($config.workloadsToAudit) | Should -Contain 'exchange'
    }

    It 'regulated tier retains evidence for seven years' {
        $regulated = Get-Content (Join-Path $solutionRoot 'config\regulated.json') -Raw | ConvertFrom-Json -Depth 20
        [int]$regulated.evidenceRetentionDays | Should -Be 2555
    }

    It 'configurations carry the mapped controls' {
        $configFiles = @(
            'config\default-config.json'
            'config\baseline.json'
            'config\recommended.json'
            'config\regulated.json'
        )

        foreach ($relativePath in $configFiles) {
            $config = Get-Content (Join-Path $solutionRoot $relativePath) -Raw | ConvertFrom-Json -Depth 20
            (Compare-Object -ReferenceObject $script:expectedControls -DifferenceObject @($config.controls)) | Should -BeNullOrEmpty
        }
    }
}

Describe 'Script syntax validation' {
    It 'parses <_>' -ForEach $script:scriptPaths {
        $tokens = $null
        $errors = $null
        $null = [System.Management.Automation.Language.Parser]::ParseFile($_, [ref]$tokens, [ref]$errors)

        $errors | Should -BeNullOrEmpty
    }
}

Describe 'Dependency declarations' {
    It 'references both solution 01 and solution 02 in deployment guidance' {
        $deploymentGuide = Get-Content (Join-Path $solutionRoot 'docs\deployment-guide.md') -Raw
        $deploymentGuide | Should -Match '01-copilot-readiness-scanner'
        $deploymentGuide | Should -Match '02-oversharing-risk-assessment'
    }
}

Describe 'Evidence types' {
    It 'documents all required evidence outputs' {
        $evidenceDoc = Get-Content (Join-Path $solutionRoot 'docs\evidence-export.md') -Raw
        $evidenceDoc | Should -Match 'label-coverage-report'
        $evidenceDoc | Should -Match 'label-gap-findings'
        $evidenceDoc | Should -Match 'remediation-manifest'
    }
}

Describe 'Regulatory content' {
    It 'mentions Microsoft Purview in prerequisites' {
        $prerequisites = Get-Content (Join-Path $solutionRoot 'docs\prerequisites.md') -Raw
        $prerequisites | Should -Match 'Microsoft Purview'
    }
}

Describe 'Evidence export portability' {
    BeforeAll {
        $script:repoRoot = (Resolve-Path (Join-Path $solutionRoot '..\..')).Path
        Import-Module (Join-Path $script:repoRoot 'scripts\common\EvidenceExport.psm1') -Force
        $script:exportScript = Join-Path $solutionRoot 'scripts\Export-Evidence.ps1'
        $script:exportDir = Join-Path $TestDrive 'evidence'
        $script:exportResult = & $script:exportScript -ConfigurationTier baseline -TenantId 'lab-tenant' -OutputPath $script:exportDir
        $script:packagePath = Join-Path $script:exportDir 'evidence-package.json'
        $script:package = Get-Content $script:packagePath -Raw | ConvertFrom-Json -Depth 30
    }

    It 'records package-relative (non-rooted) artifact paths' {
        @($script:package.artifacts).Count | Should -BeGreaterThan 0
        foreach ($artifact in @($script:package.artifacts)) {
            [System.IO.Path]::IsPathRooted([string]$artifact.path) | Should -BeFalse -Because "artifact $($artifact.name) must use a package-relative path for relocation safety"
        }
    }

    It 'returns rooted artifact paths for callers' {
        foreach ($artifact in @($script:exportResult.artifactPaths)) {
            [System.IO.Path]::IsPathRooted([string]$artifact.path) | Should -BeTrue -Because "caller path for $($artifact.name) must remain directly usable"
            Test-Path -Path $artifact.path -PathType Leaf | Should -BeTrue
        }
    }

    It 'remains valid after the evidence package is relocated' {
        $relocated = Join-Path $TestDrive 'relocated'
        Move-Item -Path $script:exportDir -Destination $relocated
        $relocatedPackage = Join-Path $relocated 'evidence-package.json'
        $result = Test-CopilotGovEvidencePackage -Path $relocatedPackage -ExpectedArtifacts @('label-coverage-report', 'label-gap-findings', 'remediation-manifest')
        $result.IsValid | Should -BeTrue -Because ($result.Errors -join '; ')
    }
}
