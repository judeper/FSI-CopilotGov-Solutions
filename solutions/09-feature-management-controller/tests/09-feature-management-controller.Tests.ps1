Describe 'Copilot Feature Management Controller solution' {
    BeforeAll {
        $solutionRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
        $deployScript = Join-Path $solutionRoot 'scripts\Deploy-Solution.ps1'
        $monitorScript = Join-Path $solutionRoot 'scripts\Monitor-Compliance.ps1'
        $exportScript = Join-Path $solutionRoot 'scripts\Export-Evidence.ps1'
        $defaultConfigPath = Join-Path $solutionRoot 'config\default-config.json'
        $regulatedConfigPath = Join-Path $solutionRoot 'config\regulated.json'
    }

    It 'has required configuration files' {
        @(
            'config\default-config.json',
            'config\baseline.json',
            'config\recommended.json',
            'config\regulated.json'
        ) | ForEach-Object {
            Test-Path (Join-Path $solutionRoot $_) | Should -BeTrue
        }
    }

    It 'has required documentation files' {
        @(
            'README.md',
            'CHANGELOG.md',
            'DELIVERY-CHECKLIST.md',
            'docs\architecture.md',
            'docs\deployment-guide.md',
            'docs\evidence-export.md',
            'docs\prerequisites.md',
            'docs\troubleshooting.md'
        ) | ForEach-Object {
            Test-Path (Join-Path $solutionRoot $_) | Should -BeTrue
        }
    }

    It 'includes comment-based help in Deploy-Solution.ps1' {
        (Get-Content -Path $deployScript -Raw) | Should -Match '(?s)<#.*?\.SYNOPSIS.*?#>'
    }

    It 'accepts BaselinePath in Monitor-Compliance.ps1' {
        $tokens = $null
        $errors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($monitorScript, [ref]$tokens, [ref]$errors)
        $parameterNames = $ast.ParamBlock.Parameters.Name.VariablePath.UserPath

        $errors | Should -BeNullOrEmpty
        $parameterNames | Should -Contain 'BaselinePath'
    }

    It 'references the FMC solution code in Export-Evidence.ps1' {
        (Get-Content -Path $exportScript -Raw) | Should -Match "SolutionCode 'FMC'"
    }

    It 'contains rollout ring or feature configuration in default-config.json' {
        $defaultConfig = Get-Content -Path $defaultConfigPath -Raw | ConvertFrom-Json -AsHashtable
        ($defaultConfig.ContainsKey('rolloutRings') -or $defaultConfig.ContainsKey('featureCategories')) | Should -BeTrue
    }

    It 'sets regulated evidence retention to at least 365 days' {
        $regulatedConfig = Get-Content -Path $regulatedConfigPath -Raw | ConvertFrom-Json
        [int]$regulatedConfig.evidenceRetentionDays | Should -BeGreaterOrEqual 365
    }

    It 'has valid PowerShell syntax in Deploy-Solution.ps1' {
        $tokens = $null
        $errors = $null
        [System.Management.Automation.Language.Parser]::ParseFile($deployScript, [ref]$tokens, [ref]$errors) | Out-Null

        $errors | Should -BeNullOrEmpty
    }
}
