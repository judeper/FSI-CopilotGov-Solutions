#Requires -Version 7.2
<#
.SYNOPSIS
    Pester tests for DORA Operational Resilience Monitor (DRM) scaffold validation.
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

Describe 'DORA Operational Resilience Monitor - File Presence' {
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
        foreach ($path in @('Deploy-Solution.ps1', 'Monitor-Compliance.ps1', 'Export-Evidence.ps1')) {
            Test-Path (Join-Path $scriptsPath $path) | Should -BeTrue
        }
    }
}

Describe 'DORA Operational Resilience Monitor - Configuration Validation' {
    Context 'default-config.json' {
        BeforeAll {
            $defaultConfig = Get-JsonContent -Path (Join-Path $configPath 'default-config.json')
        }

        It 'has correct solution slug' {
            $defaultConfig.solution | Should -Be '13-dora-resilience-monitor'
        }

        It 'has correct controls' {
            @($defaultConfig.controls) | Should -Contain '2.7'
            @($defaultConfig.controls) | Should -Contain '4.9'
            @($defaultConfig.controls) | Should -Contain '4.10'
            @($defaultConfig.controls) | Should -Contain '4.11'
        }

        It 'has correct track' {
            $defaultConfig.track | Should -Be 'D'
        }

        It 'has solutionCode DRM' {
            $defaultConfig.solutionCode | Should -Be 'DRM'
        }

        It 'has monitored services list' {
            @($defaultConfig.defaults.monitoredServices) | Should -Contain 'Exchange Online'
            @($defaultConfig.defaults.monitoredServices) | Should -Contain 'SharePoint Online'
            @($defaultConfig.defaults.monitoredServices) | Should -Contain 'Microsoft Teams'
            @($defaultConfig.defaults.monitoredServices) | Should -Contain 'Microsoft Graph'
            @($defaultConfig.defaults.monitoredServices) | Should -Contain 'Microsoft Copilot'
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

            foreach ($requiredField in @('solution', 'tier', 'controls', 'evidenceRetentionDays', 'notificationMode', 'serviceHealthPollingIntervalMinutes', 'incidentClassification', 'resilienceTestTracking', 'sentinelIntegration', 'powerAutomateFlow')) {
                $propertyNames | Should -Contain $requiredField
            }
        }

        It '<tier> has incidentClassification section' -ForEach @(
            @{ tier = 'baseline' },
            @{ tier = 'recommended' },
            @{ tier = 'regulated' }
        ) {
            $config = Get-JsonContent -Path (Join-Path $configPath ("{0}.json" -f $tier))
            $config.incidentClassification | Should -Not -BeNullOrEmpty
            $config.incidentClassification.severityThresholds | Should -Not -BeNullOrEmpty
        }

        It 'regulated tier has doraArticle17Reporting enabled' {
            $regulatedConfig = Get-JsonContent -Path (Join-Path $configPath 'regulated.json')
            $regulatedConfig.incidentClassification.doraArticle17Reporting | Should -BeTrue
        }
    }
}

Describe 'DORA Operational Resilience Monitor - Script Validation' {
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

        It 'has ConfigurationTier parameter' {
            (Get-ScriptParameterNames -Path (Join-Path $scriptsPath 'Monitor-Compliance.ps1')) | Should -Contain 'ConfigurationTier'
        }

        It 'has ClientSecret parameter' {
            (Get-ScriptParameterNames -Path (Join-Path $scriptsPath 'Monitor-Compliance.ps1')) | Should -Contain 'ClientSecret'
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

        It 'has ConfigurationTier parameter' {
            (Get-ScriptParameterNames -Path (Join-Path $scriptsPath 'Export-Evidence.ps1')) | Should -Contain 'ConfigurationTier'
        }

        It 'has PeriodStart and PeriodEnd parameters' {
            $parameterNames = Get-ScriptParameterNames -Path (Join-Path $scriptsPath 'Export-Evidence.ps1')
            $parameterNames | Should -Contain 'PeriodStart'
            $parameterNames | Should -Contain 'PeriodEnd'
        }
    }
}

Describe 'DORA Operational Resilience Monitor - Documentation Validation' {
    BeforeAll {
        $readme = Get-Content -Path (Join-Path $solutionRoot 'README.md') -Raw
        $architecture = Get-Content -Path (Join-Path $docsPath 'architecture.md') -Raw
        $evidenceExport = Get-Content -Path (Join-Path $docsPath 'evidence-export.md') -Raw
    }

    It 'README.md references DORA' {
        $readme | Should -Match 'DORA'
    }

    It 'README.md references all four controls' {
        $readme | Should -Match '2\.7'
        $readme | Should -Match '4\.9'
        $readme | Should -Match '4\.10'
        $readme | Should -Match '4\.11'
    }

    It 'evidence-export.md references service-health-log' {
        $evidenceExport | Should -Match 'service-health-log'
    }

    It 'evidence-export.md references incident-register' {
        $evidenceExport | Should -Match 'incident-register'
    }

    It 'evidence-export.md references resilience-test-results' {
        $evidenceExport | Should -Match 'resilience-test-results'
    }

    It 'architecture.md references DORA Art. 17' {
        $architecture | Should -Match 'DORA Art\. 17'
    }
}

Describe 'DORA Operational Resilience Monitor - Runtime honesty validation' {
    It 'Monitor-Compliance.ps1 labels the default local stub path' {
        $monitorResult = & (Join-Path $scriptsPath 'Monitor-Compliance.ps1') -ConfigurationTier baseline -OutputPath (Join-Path $TestDrive 'monitor') -TenantId '' -ClientId '' 3>$null

        $monitorResult.RuntimeMode | Should -Be 'local-stub'
        $monitorResult.OverallStatus | Should -Not -Be 'implemented'
        @($monitorResult.ServiceHealthSummary | Select-Object -ExpandProperty Source -Unique) | Should -Contain 'local-graph-stub'
    }

    It 'Export-Evidence.ps1 keeps stub-backed incident reporting below implemented' {
        $originalSamplePayload = $env:DRM_SERVICE_HEALTH_SAMPLE_JSON
        $originalTenant = $env:AZURE_TENANT_ID
        $originalClient = $env:AZURE_CLIENT_ID
        $originalSecret = $env:AZURE_CLIENT_SECRET

        try {
            Remove-Item Env:DRM_SERVICE_HEALTH_SAMPLE_JSON -ErrorAction SilentlyContinue
            $env:AZURE_TENANT_ID = ''
            $env:AZURE_CLIENT_ID = ''
            Remove-Item Env:AZURE_CLIENT_SECRET -ErrorAction SilentlyContinue

            $exportResult = & (Join-Path $scriptsPath 'Export-Evidence.ps1') -ConfigurationTier recommended -OutputPath (Join-Path $TestDrive 'evidence')
            $package = Get-Content -Path $exportResult.Package.Path -Raw | ConvertFrom-Json -Depth 20
            $serviceHealthLog = Get-Content -Path (Join-Path $TestDrive 'evidence\service-health-log-recommended.json') -Raw | ConvertFrom-Json -Depth 20

            ($package.controls | Where-Object { $_.controlId -eq '4.9' }).status | Should -Be 'partial'
            $package.metadata.runtimeMode | Should -Be 'local-stub'
            $serviceHealthLog.warning | Should -Match 'local Graph stub'
        }
        finally {
            if ($null -ne $originalSamplePayload) { $env:DRM_SERVICE_HEALTH_SAMPLE_JSON = $originalSamplePayload } else { Remove-Item Env:DRM_SERVICE_HEALTH_SAMPLE_JSON -ErrorAction SilentlyContinue }
            if ($null -ne $originalTenant) { $env:AZURE_TENANT_ID = $originalTenant } else { Remove-Item Env:AZURE_TENANT_ID -ErrorAction SilentlyContinue }
            if ($null -ne $originalClient) { $env:AZURE_CLIENT_ID = $originalClient } else { Remove-Item Env:AZURE_CLIENT_ID -ErrorAction SilentlyContinue }
            if ($null -ne $originalSecret) { $env:AZURE_CLIENT_SECRET = $originalSecret } else { Remove-Item Env:AZURE_CLIENT_SECRET -ErrorAction SilentlyContinue }
        }
    }
}
