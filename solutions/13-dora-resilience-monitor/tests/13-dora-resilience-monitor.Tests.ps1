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
    $script:scriptsPath = Join-Path $solutionRoot 'scripts'
    $script:configPath = Join-Path $solutionRoot 'config'
    $script:docsPath = Join-Path $solutionRoot 'docs'
    $script:labContractPath = Join-Path $solutionRoot 'lab\13-dora-resilience-monitor.lab.json'
    $script:repoRoot = (Resolve-Path (Join-Path $solutionRoot '..\..')).Path
    $script:validateLabPackageScript = Join-Path $script:repoRoot 'scripts\validate-lab-package.ps1'

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
            Test-Path (Join-Path $script:configPath $path) | Should -BeTrue
        }
    }

    It 'has all required doc files' {
        foreach ($path in @('architecture.md', 'deployment-guide.md', 'evidence-export.md', 'prerequisites.md', 'troubleshooting.md')) {
            Test-Path (Join-Path $script:docsPath $path) | Should -BeTrue
        }
    }

    It 'has all required scripts' {
        foreach ($path in @('Deploy-Solution.ps1', 'Monitor-Compliance.ps1', 'Export-Evidence.ps1')) {
            Test-Path (Join-Path $script:scriptsPath $path) | Should -BeTrue
        }
    }
}

Describe 'DORA Operational Resilience Monitor - Configuration Validation' {
    Context 'default-config.json' {
        BeforeAll {
            $script:defaultConfig = Get-JsonContent -Path (Join-Path $script:configPath 'default-config.json')
        }

        It 'has correct solution slug' {
            $script:defaultConfig.solution | Should -Be '13-dora-resilience-monitor'
        }

        It 'has correct controls' {
            @($script:defaultConfig.controls) | Should -Contain '2.7'
            @($script:defaultConfig.controls) | Should -Contain '4.9'
            @($script:defaultConfig.controls) | Should -Contain '4.10'
            @($script:defaultConfig.controls) | Should -Contain '4.11'
        }

        It 'has correct track' {
            $script:defaultConfig.track | Should -Be 'D'
        }

        It 'has solutionCode DRM' {
            $script:defaultConfig.solutionCode | Should -Be 'DRM'
        }

        It 'has monitored services list' {
            @($script:defaultConfig.defaults.monitoredServices) | Should -Contain 'Exchange Online'
            @($script:defaultConfig.defaults.monitoredServices) | Should -Contain 'SharePoint Online'
            @($script:defaultConfig.defaults.monitoredServices) | Should -Contain 'Microsoft Teams'
            @($script:defaultConfig.defaults.monitoredServices) | Should -Contain 'Microsoft Graph'
            @($script:defaultConfig.defaults.monitoredServices) | Should -Contain 'Microsoft 365 Copilot'
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

            foreach ($requiredField in @('solution', 'tier', 'controls', 'evidenceRetentionDays', 'notificationMode', 'serviceHealthPollingIntervalMinutes', 'incidentClassification', 'resilienceTestTracking', 'sentinelIntegration', 'powerAutomateFlow')) {
                $propertyNames | Should -Contain $requiredField
            }
        }

        It '<tier> has incidentClassification section' -ForEach @(
            @{ tier = 'baseline' },
            @{ tier = 'recommended' },
            @{ tier = 'regulated' }
        ) {
            $config = Get-JsonContent -Path (Join-Path $script:configPath ("{0}.json" -f $tier))
            $config.incidentClassification | Should -Not -BeNullOrEmpty
            $config.incidentClassification.severityThresholds | Should -Not -BeNullOrEmpty
        }

        It 'regulated tier has doraArticle17Reporting enabled' {
            $regulatedConfig = Get-JsonContent -Path (Join-Path $script:configPath 'regulated.json')
            $regulatedConfig.incidentClassification.doraArticle17Reporting | Should -BeTrue
        }
    }
}

Describe 'DORA Operational Resilience Monitor - Script Validation' {
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

        It 'has ConfigurationTier parameter' {
            (Get-ScriptParameterName -Path (Join-Path $script:scriptsPath 'Monitor-Compliance.ps1')) | Should -Contain 'ConfigurationTier'
        }

        It 'has ClientSecret parameter' {
            (Get-ScriptParameterName -Path (Join-Path $script:scriptsPath 'Monitor-Compliance.ps1')) | Should -Contain 'ClientSecret'
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

        It 'has ConfigurationTier parameter' {
            (Get-ScriptParameterName -Path (Join-Path $script:scriptsPath 'Export-Evidence.ps1')) | Should -Contain 'ConfigurationTier'
        }

        It 'has PeriodStart and PeriodEnd parameters' {
            $parameterNames = Get-ScriptParameterName -Path (Join-Path $script:scriptsPath 'Export-Evidence.ps1')
            $parameterNames | Should -Contain 'PeriodStart'
            $parameterNames | Should -Contain 'PeriodEnd'
        }
    }
}

Describe 'DORA Operational Resilience Monitor - Documentation Validation' {
    BeforeAll {
        $script:readme = Get-Content -Path (Join-Path $solutionRoot 'README.md') -Raw
        $script:architecture = Get-Content -Path (Join-Path $script:docsPath 'architecture.md') -Raw
        $script:evidenceExport = Get-Content -Path (Join-Path $script:docsPath 'evidence-export.md') -Raw
    }

    It 'README.md references DORA' {
        $script:readme | Should -Match 'DORA'
    }

    It 'README.md references all four controls' {
        $script:readme | Should -Match '2\.7'
        $script:readme | Should -Match '4\.9'
        $script:readme | Should -Match '4\.10'
        $script:readme | Should -Match '4\.11'
    }

    It 'evidence-export.md references service-health-log' {
        $script:evidenceExport | Should -Match 'service-health-log'
    }

    It 'evidence-export.md references incident-register' {
        $script:evidenceExport | Should -Match 'incident-register'
    }

    It 'evidence-export.md references resilience-test-results' {
        $script:evidenceExport | Should -Match 'resilience-test-results'
    }

    It 'architecture.md references DORA Art. 17' {
        $script:architecture | Should -Match 'DORA Art\. 17'
    }

    It 'documents the current Sentinel Azure portal retirement date' {
        $prerequisites = Get-Content -Path (Join-Path $script:docsPath 'prerequisites.md') -Raw
        $script:readme | Should -Match '31 March 2027'
        $script:architecture | Should -Match '31 March 2027'
        $prerequisites | Should -Match '31 March 2027'
        $script:readme | Should -Not -Match 'July 2026'
        $script:architecture | Should -Not -Match 'July 2026'
        $prerequisites | Should -Not -Match 'July 2026'
    }
}

Describe 'DORA Operational Resilience Monitor - Lab contract guards' {
    BeforeAll {
        $script:labContract = Get-Content -Path $script:labContractPath -Raw | ConvertFrom-Json -Depth 30
    }

    It 'documents the Sentinel retirement date and source correctly' {
        $sentinelClaim = @($script:labContract.microsoftSourceClaims | Where-Object { $_.id -eq 'claim-sentinel-defender-portal' }) | Select-Object -First 1
        $sentinelClaim | Should -Not -BeNullOrEmpty
        $sentinelClaim.claimText | Should -Match '31 March 2027'
        $sentinelClaim.claimText | Should -Not -Match 'July 2026'
        $sentinelClaim.sourceUrl | Should -Be 'https://learn.microsoft.com/azure/sentinel/microsoft-sentinel-defender-portal'
        @($sentinelClaim.affectedFiles) | Should -Contain 'solutions/13-dora-resilience-monitor/README.md'
        @($sentinelClaim.affectedFiles) | Should -Contain 'solutions/13-dora-resilience-monitor/CHANGELOG.md'
        @($sentinelClaim.affectedFiles) | Should -Contain 'solutions/13-dora-resilience-monitor/docs/architecture.md'
        @($sentinelClaim.affectedFiles) | Should -Contain 'solutions/13-dora-resilience-monitor/docs/prerequisites.md'
    }

    It 'keeps commercial scope without prohibitedClouds enumeration' {
        $script:labContract.scope.cloud | Should -Be 'm365-us-commercial'
        $script:labContract.scope.usCommercialOnly | Should -BeTrue
        $script:labContract.scope.PSObject.Properties.Name | Should -Not -Contain 'prohibitedClouds'
    }

    It 'verifies every claim URL and official DORA source in source-currency step' {
        $step = @($script:labContract.execution.phases |
                ForEach-Object { $_.steps } |
                Where-Object { $_.id -eq 'step-verify-source-currency' }) | Select-Object -First 1
        $step | Should -Not -BeNullOrEmpty
        $step.mode | Should -Be 'manual'
        $step.readBack.method | Should -Be 'manual'

        $stepText = @(
            [string]$step.intent,
            [string]$step.expected,
            [string]$step.operatorNote,
            [string]$step.readBack.expectation
        ) -join ' '

        foreach ($claim in @($script:labContract.microsoftSourceClaims)) {
            $stepText | Should -Match ([regex]::Escape([string]$claim.sourceUrl))
        }

        foreach ($requiredDoraSource in @(
                'https://eur-lex.europa.eu/eli/reg/2022/2554/oj',
                'https://eur-lex.europa.eu/eli/reg_del/2025/301/oj',
                'https://eur-lex.europa.eu/eli/reg_impl/2025/302/oj',
                'https://eur-lex.europa.eu/eli/reg_del/2024/1772/oj'
            )) {
            $stepText | Should -Match ([regex]::Escape($requiredDoraSource))
        }

        $stepText | Should -Match '31 March 2027'
        $stepText | Should -Match 'BLOCKED'
        $stepText | Should -Match 'follow-up'
        $stepText | Should -Match 'No network writes'
    }

    It 'uses a non-mutating hash verification command' {
        $step = @($script:labContract.execution.phases |
                ForEach-Object { $_.steps } |
                Where-Object { $_.id -eq 'step-verify-evidence-hashes' }) | Select-Object -First 1
        $step | Should -Not -BeNullOrEmpty
        $step.mode | Should -Be 'powershell'
        $step.command | Should -Match 'validate-lab-package\.ps1'
        $step.command | Should -Not -Match 'Export-Evidence\.ps1'
        $step.expected | Should -Match 'no evidence files are regenerated'
    }
}

Describe 'DORA Operational Resilience Monitor - Runtime honesty validation' {
    It 'Monitor-Compliance.ps1 labels the default local stub path' {
        $monitorResult = & (Join-Path $script:scriptsPath 'Monitor-Compliance.ps1') -ConfigurationTier baseline -OutputPath (Join-Path $TestDrive 'monitor') -TenantId '' -ClientId '' 3>$null

        $monitorResult.RuntimeMode | Should -Be 'local-stub'
        $monitorResult.OverallStatus | Should -Not -Be 'implemented'
        @($monitorResult.ServiceHealthSummary | Select-Object -ExpandProperty Source -Unique) | Should -Contain 'local-graph-stub'
    }

    It 'Monitor-Compliance.ps1 treats Microsoft Graph serviceOperational samples as non-incident' {
        $originalSamplePayload = $env:DRM_SERVICE_HEALTH_SAMPLE_JSON

        try {
            $env:DRM_SERVICE_HEALTH_SAMPLE_JSON = '[{"service":"Microsoft Graph","status":"serviceOperational","downtimeMinutes":0,"affectedUserPct":0,"impactDescription":"Graph service is operational."}]'
            $monitorResult = & (Join-Path $script:scriptsPath 'Monitor-Compliance.ps1') -ConfigurationTier baseline -OutputPath (Join-Path $TestDrive 'graph-operational') -TenantId '' -ClientId '' 3>$null

            $monitorResult.RuntimeMode | Should -Be 'sample-json'
            @($monitorResult.IncidentFindings).Count | Should -Be 0
            ($monitorResult.ServiceHealthSummary | Select-Object -First 1).Status | Should -Be 'serviceOperational'
        }
        finally {
            if ($null -ne $originalSamplePayload) { $env:DRM_SERVICE_HEALTH_SAMPLE_JSON = $originalSamplePayload } else { Remove-Item Env:DRM_SERVICE_HEALTH_SAMPLE_JSON -ErrorAction SilentlyContinue }
        }
    }

    It 'Monitor-Compliance.ps1 treats Microsoft Graph serviceDegradation samples as open incidents' {
        $originalSamplePayload = $env:DRM_SERVICE_HEALTH_SAMPLE_JSON

        try {
            $env:DRM_SERVICE_HEALTH_SAMPLE_JSON = '[{"service":"Microsoft Graph","status":"serviceDegradation","downtimeMinutes":5,"affectedUserPct":5,"impactDescription":"Representative service degradation."}]'
            $monitorResult = & (Join-Path $script:scriptsPath 'Monitor-Compliance.ps1') -ConfigurationTier baseline -OutputPath (Join-Path $TestDrive 'graph-degradation') -TenantId '' -ClientId '' 3>$null

            $monitorResult.RuntimeMode | Should -Be 'sample-json'
            @($monitorResult.IncidentFindings).Count | Should -Be 1
            ($monitorResult.IncidentFindings | Select-Object -First 1).status | Should -Be 'open'
        }
        finally {
            if ($null -ne $originalSamplePayload) { $env:DRM_SERVICE_HEALTH_SAMPLE_JSON = $originalSamplePayload } else { Remove-Item Env:DRM_SERVICE_HEALTH_SAMPLE_JSON -ErrorAction SilentlyContinue }
        }
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

            $exportResult = & (Join-Path $script:scriptsPath 'Export-Evidence.ps1') -ConfigurationTier recommended -OutputPath (Join-Path $TestDrive 'evidence')
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

Describe 'DORA Operational Resilience Monitor - Freshness metadata' {
    It 'surfaces an explicit timestamp gap for missing source timestamps instead of defaulting to current' {
        $originalSamplePayload = $env:DRM_SERVICE_HEALTH_SAMPLE_JSON
        try {
            $env:DRM_SERVICE_HEALTH_SAMPLE_JSON = '[{"service":"Microsoft 365 Copilot","status":"serviceDegradation","downtimeMinutes":90,"affectedUserPct":30}]'
            $monitorResult = & (Join-Path $script:scriptsPath 'Monitor-Compliance.ps1') -ConfigurationTier regulated -OutputPath (Join-Path $TestDrive 'fresh-gap') -TenantId '' -ClientId '' 3>$null

            $record = $monitorResult.ServiceHealthSummary | Select-Object -First 1
            $record.Freshness.hasTimestampGap | Should -BeTrue
            $record.Freshness.status | Should -Be 'unknown'
            $record.SourceLastModified | Should -BeNullOrEmpty
            $record.DetectedAt | Should -BeNullOrEmpty
            $monitorResult.Freshness.OverallStatus | Should -Be 'gap'
            $monitorResult.Freshness.TimestampGapCount | Should -Be 1
        }
        finally {
            if ($null -ne $originalSamplePayload) { $env:DRM_SERVICE_HEALTH_SAMPLE_JSON = $originalSamplePayload } else { Remove-Item Env:DRM_SERVICE_HEALTH_SAMPLE_JSON -ErrorAction SilentlyContinue }
        }
    }

    It 'flags stale source-provided records against the staleness threshold' {
        $originalSamplePayload = $env:DRM_SERVICE_HEALTH_SAMPLE_JSON
        try {
            $staleTimestamp = (Get-Date).ToUniversalTime().AddHours(-6).ToString('o')
            $env:DRM_SERVICE_HEALTH_SAMPLE_JSON = ('[{{"service":"Microsoft Graph","status":"serviceDegradation","downtimeMinutes":5,"affectedUserPct":5,"lastUpdated":"{0}"}}]' -f $staleTimestamp)
            $monitorResult = & (Join-Path $script:scriptsPath 'Monitor-Compliance.ps1') -ConfigurationTier regulated -OutputPath (Join-Path $TestDrive 'fresh-stale') -TenantId '' -ClientId '' 3>$null

            $record = $monitorResult.ServiceHealthSummary | Select-Object -First 1
            $record.Freshness.status | Should -Be 'stale'
            $record.Freshness.isStale | Should -BeTrue
            $record.Freshness.hasTimestampGap | Should -BeFalse
            $record.SourceLastModified | Should -Not -BeNullOrEmpty
            $record.CollectionTime | Should -Not -Be $record.SourceLastModified
            $monitorResult.Freshness.OverallStatus | Should -Be 'stale'
        }
        finally {
            if ($null -ne $originalSamplePayload) { $env:DRM_SERVICE_HEALTH_SAMPLE_JSON = $originalSamplePayload } else { Remove-Item Env:DRM_SERVICE_HEALTH_SAMPLE_JSON -ErrorAction SilentlyContinue }
        }
    }

    It 'labels synthetic stub freshness as not-applicable rather than current' {
        $originalSamplePayload = $env:DRM_SERVICE_HEALTH_SAMPLE_JSON
        try {
            Remove-Item Env:DRM_SERVICE_HEALTH_SAMPLE_JSON -ErrorAction SilentlyContinue
            $monitorResult = & (Join-Path $script:scriptsPath 'Monitor-Compliance.ps1') -ConfigurationTier baseline -OutputPath (Join-Path $TestDrive 'fresh-stub') -TenantId '' -ClientId '' 3>$null

            $record = $monitorResult.ServiceHealthSummary | Select-Object -First 1
            $record.Freshness.status | Should -Be 'not-applicable'
            $record.TimestampProvenance | Should -Be 'synthetic-stub'
            $monitorResult.Freshness.OverallStatus | Should -Be 'not-applicable'
        }
        finally {
            if ($null -ne $originalSamplePayload) { $env:DRM_SERVICE_HEALTH_SAMPLE_JSON = $originalSamplePayload } else { Remove-Item Env:DRM_SERVICE_HEALTH_SAMPLE_JSON -ErrorAction SilentlyContinue }
        }
    }

    It 'emits UTC ISO 8601 collection timestamps' {
        $originalSamplePayload = $env:DRM_SERVICE_HEALTH_SAMPLE_JSON
        try {
            Remove-Item Env:DRM_SERVICE_HEALTH_SAMPLE_JSON -ErrorAction SilentlyContinue
            $monitorResult = & (Join-Path $script:scriptsPath 'Monitor-Compliance.ps1') -ConfigurationTier baseline -OutputPath (Join-Path $TestDrive 'fresh-utc') -TenantId '' -ClientId '' 3>$null

            $monitorResult.CollectionTime | Should -Match 'Z$'
            $monitorResult.Freshness.CollectionTime | Should -Match 'Z$'
        }
        finally {
            if ($null -ne $originalSamplePayload) { $env:DRM_SERVICE_HEALTH_SAMPLE_JSON = $originalSamplePayload } else { Remove-Item Env:DRM_SERVICE_HEALTH_SAMPLE_JSON -ErrorAction SilentlyContinue }
        }
    }
}

Describe 'DORA Operational Resilience Monitor - DORA reporting timeline metadata' {
    It 'anchors intermediate and final reports to the prior reporting stage per DORA RTS' {
        $originalSamplePayload = $env:DRM_SERVICE_HEALTH_SAMPLE_JSON
        try {
            $detectedAt = '2026-03-10T08:00:00Z'
            $env:DRM_SERVICE_HEALTH_SAMPLE_JSON = ('[{{"service":"Microsoft 365 Copilot","status":"serviceDegradation","downtimeMinutes":180,"affectedUserPct":40,"incidentId":"DRM-TEST-01","detectedAt":"{0}","lastUpdated":"{0}"}}]' -f $detectedAt)
            & (Join-Path $script:scriptsPath 'Export-Evidence.ps1') -ConfigurationTier regulated -OutputPath (Join-Path $TestDrive 'dora-anchor') 3>$null | Out-Null
            $register = Get-Content -Path (Join-Path $TestDrive 'dora-anchor\incident-register-regulated.json') -Raw | ConvertFrom-Json -Depth 20
            $incident = $register.records | Select-Object -First 1

            # ConvertFrom-Json returns DateTime objects with a consistent kind, so compare intervals
            # between same-origin values rather than re-parsing the serialized strings.
            $detected = $incident.detectedAt
            [math]::Round(($incident.initialNotificationDueAt - $detected).TotalHours, 2) | Should -Be 4
            [math]::Round(($incident.initialNotificationLatestFromAwarenessAt - $detected).TotalHours, 2) | Should -Be 24
            [math]::Round(($incident.intermediateReportDueAt - $detected).TotalHours, 2) | Should -Be 76
            [math]::Round(($incident.finalReportDueAt - $incident.intermediateReportDueAt).TotalDays, 2) | Should -Be 30
            $incident.reportingTimelineGap | Should -BeFalse
        }
        finally {
            if ($null -ne $originalSamplePayload) { $env:DRM_SERVICE_HEALTH_SAMPLE_JSON = $originalSamplePayload } else { Remove-Item Env:DRM_SERVICE_HEALTH_SAMPLE_JSON -ErrorAction SilentlyContinue }
        }
    }

    Describe 'DORA Operational Resilience Monitor - Evidence hash verification portability' {
        It 'includes Delegated Regulation 2024/1772 in reporting timeline metadata' {
            & (Join-Path $script:scriptsPath 'Export-Evidence.ps1') -ConfigurationTier regulated -OutputPath (Join-Path $TestDrive 'dora-2024-1772') 3>$null | Out-Null
            $register = Get-Content -Path (Join-Path $TestDrive 'dora-2024-1772\incident-register-regulated.json') -Raw | ConvertFrom-Json -Depth 20
            $register.reportingTimeline.regulatorySource | Should -Match '2024/1772'
            $register.reportingTimeline.regulatorySource | Should -Match '2025/302'
        }

        It 'writes package artifacts as relative paths while keeping absolute caller output paths' {
            $absoluteOutputPath = Join-Path $TestDrive 'absolute-output\nested'
            $exportResult = & (Join-Path $script:scriptsPath 'Export-Evidence.ps1') -ConfigurationTier regulated -OutputPath $absoluteOutputPath -PassThru 3>$null
            $packagePath = $exportResult.Package.Path
            $packagePath | Should -Match '^[A-Za-z]:\\'

            $package = Get-Content -Path $packagePath -Raw | ConvertFrom-Json -Depth 20
            foreach ($artifact in @($package.artifacts)) {
                [IO.Path]::IsPathRooted([string]$artifact.path) | Should -BeFalse
                $resolvedArtifactPath = Join-Path (Split-Path -Path $packagePath -Parent) ([string]$artifact.path)
                Test-Path -Path $resolvedArtifactPath -PathType Leaf | Should -BeTrue
            }
        }

        It 'passes hash/package validation for untouched output and relocated package copies' {
            $sourceOutputPath = Join-Path $TestDrive 'hash-pass'
            & (Join-Path $script:scriptsPath 'Export-Evidence.ps1') -ConfigurationTier regulated -OutputPath $sourceOutputPath 3>$null | Out-Null
            $sourcePackagePath = Join-Path $sourceOutputPath '13-dora-resilience-monitor-evidence.json'

            { & $script:validateLabPackageScript -Path $sourcePackagePath } | Should -Not -Throw

            $relocatedOutputPath = Join-Path $TestDrive 'hash-pass-relocated'
            $null = New-Item -ItemType Directory -Path $relocatedOutputPath -Force
            Copy-Item -Path (Join-Path $sourceOutputPath '*') -Destination $relocatedOutputPath -Recurse -Force
            $relocatedPackagePath = Join-Path $relocatedOutputPath '13-dora-resilience-monitor-evidence.json'
            { & $script:validateLabPackageScript -Path $relocatedPackagePath } | Should -Not -Throw
        }

        It 'fails validation when an artifact is tampered after export' {
            $tamperPath = Join-Path $TestDrive 'hash-tamper'
            & (Join-Path $script:scriptsPath 'Export-Evidence.ps1') -ConfigurationTier regulated -OutputPath $tamperPath 3>$null | Out-Null
            $artifactPath = Join-Path $tamperPath 'service-health-log-regulated.json'
            Add-Content -Path $artifactPath -Value "`n "

            { & $script:validateLabPackageScript -Path (Join-Path $tamperPath '13-dora-resilience-monitor-evidence.json') } | Should -Throw
        }

        It 'fails validation when an artifact sidecar hash file is missing' {
            $missingSidecarPath = Join-Path $TestDrive 'hash-missing-sidecar'
            & (Join-Path $script:scriptsPath 'Export-Evidence.ps1') -ConfigurationTier regulated -OutputPath $missingSidecarPath 3>$null | Out-Null
            Remove-Item -Path (Join-Path $missingSidecarPath 'incident-register-regulated.json.sha256') -Force

            { & $script:validateLabPackageScript -Path (Join-Path $missingSidecarPath '13-dora-resilience-monitor-evidence.json') } | Should -Throw
        }
    }

    It 'cites official DORA regulatory sources in the incident-register reporting timeline' {
        $originalSamplePayload = $env:DRM_SERVICE_HEALTH_SAMPLE_JSON
        try {
            Remove-Item Env:DRM_SERVICE_HEALTH_SAMPLE_JSON -ErrorAction SilentlyContinue
            & (Join-Path $script:scriptsPath 'Export-Evidence.ps1') -ConfigurationTier regulated -OutputPath (Join-Path $TestDrive 'dora-cite') 3>$null | Out-Null
            $register = Get-Content -Path (Join-Path $TestDrive 'dora-cite\incident-register-regulated.json') -Raw | ConvertFrom-Json -Depth 20

            $register.reportingTimeline.regulatorySource | Should -Match '2022/2554'
            $register.reportingTimeline.regulatorySource | Should -Match '2025/301'
            $register.reportingTimeline.disclaimer | Should -Match 'Not legal advice'
        }
        finally {
            if ($null -ne $originalSamplePayload) { $env:DRM_SERVICE_HEALTH_SAMPLE_JSON = $originalSamplePayload } else { Remove-Item Env:DRM_SERVICE_HEALTH_SAMPLE_JSON -ErrorAction SilentlyContinue }
        }
    }

    It 'does not fabricate incident report due dates when the source omits detection time' {
        $originalSamplePayload = $env:DRM_SERVICE_HEALTH_SAMPLE_JSON
        try {
            $env:DRM_SERVICE_HEALTH_SAMPLE_JSON = '[{"service":"Microsoft 365 Copilot","status":"serviceDegradation","downtimeMinutes":180,"affectedUserPct":40,"incidentId":"DRM-TEST-02"}]'
            & (Join-Path $script:scriptsPath 'Export-Evidence.ps1') -ConfigurationTier regulated -OutputPath (Join-Path $TestDrive 'dora-gap') 3>$null | Out-Null
            $register = Get-Content -Path (Join-Path $TestDrive 'dora-gap\incident-register-regulated.json') -Raw | ConvertFrom-Json -Depth 20
            $incident = $register.records | Select-Object -First 1

            $incident.detectedAt | Should -BeNullOrEmpty
            $incident.initialNotificationDueAt | Should -BeNullOrEmpty
            $incident.intermediateReportDueAt | Should -BeNullOrEmpty
            $incident.finalReportDueAt | Should -BeNullOrEmpty
            $incident.reportingTimelineGap | Should -BeTrue
        }
        finally {
            if ($null -ne $originalSamplePayload) { $env:DRM_SERVICE_HEALTH_SAMPLE_JSON = $originalSamplePayload } else { Remove-Item Env:DRM_SERVICE_HEALTH_SAMPLE_JSON -ErrorAction SilentlyContinue }
        }
    }
}
