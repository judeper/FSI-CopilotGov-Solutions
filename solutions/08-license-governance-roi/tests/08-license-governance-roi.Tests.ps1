Set-StrictMode -Version Latest

Describe 'License Governance and ROI Tracker solution' {
    BeforeAll {
        $script:solutionRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
    }

    It 'has required configuration files' {
        Test-Path (Join-Path $script:solutionRoot 'config\default-config.json') | Should -BeTrue
        Test-Path (Join-Path $script:solutionRoot 'config\baseline.json') | Should -BeTrue
        Test-Path (Join-Path $script:solutionRoot 'config\recommended.json') | Should -BeTrue
        Test-Path (Join-Path $script:solutionRoot 'config\regulated.json') | Should -BeTrue
    }

    It 'has required documentation files' {
        Test-Path (Join-Path $script:solutionRoot 'docs\architecture.md') | Should -BeTrue
        Test-Path (Join-Path $script:solutionRoot 'docs\deployment-guide.md') | Should -BeTrue
        Test-Path (Join-Path $script:solutionRoot 'docs\evidence-export.md') | Should -BeTrue
        Test-Path (Join-Path $script:solutionRoot 'docs\prerequisites.md') | Should -BeTrue
        Test-Path (Join-Path $script:solutionRoot 'docs\troubleshooting.md') | Should -BeTrue
    }

    It 'Deploy-Solution.ps1 has comment-based help' {
        $scriptPath = Join-Path $script:solutionRoot 'scripts\Deploy-Solution.ps1'
        Test-Path $scriptPath | Should -BeTrue
        (Get-Help $scriptPath -ErrorAction Stop).Synopsis | Should -Match 'deployment manifest'
    }

    It 'Monitor-Compliance.ps1 accepts ConfigurationTier parameter' {
        $scriptPath = Join-Path $script:solutionRoot 'scripts\Monitor-Compliance.ps1'
        $command = Get-Command $scriptPath -ErrorAction Stop
        $command.Parameters.Keys | Should -Contain 'ConfigurationTier'
    }

    It 'Export-Evidence.ps1 references the correct solution code' {
        $scriptPath = Join-Path $script:solutionRoot 'scripts\Export-Evidence.ps1'
        (Get-Content -Path $scriptPath -Raw) | Should -Match "-SolutionCode 'LGR'"
    }

    It 'default-config.json contains the expected controls' {
        $config = Get-Content -Path (Join-Path $script:solutionRoot 'config\default-config.json') -Raw | ConvertFrom-Json
        $config.version | Should -Be 'v0.1.4'
        $config.controls | Should -Contain '1.9'
        $config.controls | Should -Contain '4.5'
        $config.controls | Should -Contain '4.6'
        $config.controls | Should -Contain '4.8'
    }

    It 'regulated.json keeps evidenceRetentionDays at or above 365' {
        $config = Get-Content -Path (Join-Path $script:solutionRoot 'config\regulated.json') -Raw | ConvertFrom-Json
        $config.evidenceRetentionDays | Should -BeGreaterOrEqual 365
    }

    It 'baseline.json defines an inactivityThresholdDays property' {
        $config = Get-Content -Path (Join-Path $script:solutionRoot 'config\baseline.json') -Raw | ConvertFrom-Json
        $config.PSObject.Properties.Name | Should -Contain 'inactivityThresholdDays'
    }

    It 'uses the generally available v1.0 Copilot usage report path' {
        foreach ($scriptName in @('Deploy-Solution.ps1', 'Monitor-Compliance.ps1')) {
            $content = Get-Content -Path (Join-Path $script:solutionRoot "scripts\$scriptName") -Raw
            $content | Should -Match '/v1\.0/copilot/reports/'
            $content | Should -Not -Match '/beta/copilot/reports/'
        }
    }
}

Describe 'License Governance evidence portability and honesty' {
    BeforeAll {
        $script:solutionRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
        $script:repoRoot = (Resolve-Path (Join-Path $script:solutionRoot '..\..')).Path
        $script:exportScriptPath = Join-Path $script:solutionRoot 'scripts\Export-Evidence.ps1'
        Import-Module (Join-Path $script:repoRoot 'scripts\common\EvidenceExport.psm1') -Force
    }

    It 'stores package-relative paths, returns absolute paths, and validates after relocation' {
        $outputPath = Join-Path $TestDrive 'portable-evidence'
        $result = & $script:exportScriptPath -ConfigurationTier baseline -OutputPath $outputPath
        [System.IO.Path]::IsPathRooted($result.evidencePackage.Path) | Should -BeTrue
        foreach ($artifact in @($result.artifacts)) {
            [System.IO.Path]::IsPathRooted($artifact.path) | Should -BeTrue
        }

        $package = Get-Content -Path $result.evidencePackage.Path -Raw | ConvertFrom-Json
        foreach ($artifact in @($package.artifacts)) {
            [System.IO.Path]::IsPathRooted($artifact.path) | Should -BeFalse
        }
        @($package.controls | Where-Object { $_.status -eq 'implemented' }).Count | Should -Be 0

        $relocatedPath = Join-Path $TestDrive 'portable-evidence-relocated'
        Move-Item -Path $outputPath -Destination $relocatedPath
        $validation = Test-CopilotGovEvidencePackage `
            -Path (Join-Path $relocatedPath '08-license-governance-roi-evidence.json') `
            -ExpectedArtifacts @('license-utilization-report', 'roi-scorecard', 'reallocation-recommendations')
        $validation.IsValid | Should -BeTrue -Because ($validation.Errors -join '; ')
    }

    It 'resolves relative output from the PowerShell provider location' {
        $originalProcessDirectory = [System.Environment]::CurrentDirectory
        Push-Location $TestDrive
        try {
            [System.Environment]::CurrentDirectory = $script:solutionRoot
            $result = & $script:exportScriptPath -ConfigurationTier baseline -OutputPath '.\provider-relative'
            (Split-Path -Parent $result.evidencePackage.Path) | Should -Be (Join-Path $TestDrive 'provider-relative')
        }
        finally {
            [System.Environment]::CurrentDirectory = $originalProcessDirectory
            Pop-Location
        }
    }
}
