BeforeAll {
    $solutionRoot = Split-Path -Parent $PSScriptRoot
    $configRoot = Join-Path $solutionRoot 'config'
    $docsRoot = Join-Path $solutionRoot 'docs'
    $scriptsRoot = Join-Path $solutionRoot 'scripts'

    $requiredFiles = @(
        'README.md',
        'CHANGELOG.md',
        'DELIVERY-CHECKLIST.md',
        'config\default-config.json',
        'config\baseline.json',
        'config\recommended.json',
        'config\regulated.json',
        'docs\architecture.md',
        'docs\deployment-guide.md',
        'docs\evidence-export.md',
        'docs\prerequisites.md',
        'docs\troubleshooting.md',
        'scripts\Deploy-Solution.ps1',
        'scripts\Monitor-Compliance.ps1',
        'scripts\Export-Evidence.ps1',
        'scripts\PngmShared.psm1'
    )

    $defaultConfig = Get-Content (Join-Path $configRoot 'default-config.json') -Raw | ConvertFrom-Json
    $regulatedConfig = Get-Content (Join-Path $configRoot 'regulated.json') -Raw | ConvertFrom-Json
    $readmeContent = Get-Content (Join-Path $solutionRoot 'README.md') -Raw
    $evidenceExportContent = Get-Content (Join-Path $docsRoot 'evidence-export.md') -Raw
    $deployScriptPath = Join-Path $scriptsRoot 'Deploy-Solution.ps1'
    $monitorScriptPath = Join-Path $scriptsRoot 'Monitor-Compliance.ps1'
    $exportScriptPath = Join-Path $scriptsRoot 'Export-Evidence.ps1'
    $scriptPaths = @($deployScriptPath, $monitorScriptPath, $exportScriptPath)
    $deployScriptContent = Get-Content $deployScriptPath -Raw
}

Describe 'Copilot Pages and Notebooks Compliance Gap Monitor' {
    Context 'file presence' {
        It 'has all required files' {
            foreach ($relativePath in $requiredFiles) {
                Test-Path (Join-Path $solutionRoot $relativePath) | Should -BeTrue
            }
        }
    }

    Context 'configuration' {
        It 'has the correct solution slug, code, and controls' {
            $defaultConfig.solution | Should -Be '15-pages-notebooks-gap-monitor'
            $defaultConfig.solutionCode | Should -Be 'PNGM'
            @($defaultConfig.controls) | Should -HaveCount 4
            @($defaultConfig.controls) | Should -Contain '2.11'
            @($defaultConfig.controls) | Should -Contain '3.2'
            @($defaultConfig.controls) | Should -Contain '3.3'
            @($defaultConfig.controls) | Should -Contain '3.11'
        }

        It 'enables preservation exception tracking for the regulated tier' {
            $regulatedConfig.preservationExceptionTracking | Should -BeTrue
        }
    }

    Context 'script validation' {
        It 'parses all PowerShell scripts without syntax errors' {
            foreach ($scriptPath in $scriptPaths) {
                $tokens = $null
                $errors = $null
                [System.Management.Automation.Language.Parser]::ParseFile($scriptPath, [ref]$tokens, [ref]$errors) | Out-Null
                @($errors).Count | Should -Be 0
            }
        }

        It 'supports WhatIf on Deploy-Solution.ps1' {
            $deployScriptContent | Should -Match 'CmdletBinding\(SupportsShouldProcess\)'
        }
    }

    Context 'documentation content' {
        It 'mentions gap monitoring and SEC 17a-4 in the README' {
            $readmeContent | Should -Match '(?i)gap'
            $readmeContent | Should -Match 'SEC 17a-4'
        }

        It 'references all evidence outputs in evidence-export.md' {
            $evidenceExportContent | Should -Match 'gap-findings'
            $evidenceExportContent | Should -Match 'compensating-control-log'
            $evidenceExportContent | Should -Match 'preservation-exception-register'
        }
    }
}
