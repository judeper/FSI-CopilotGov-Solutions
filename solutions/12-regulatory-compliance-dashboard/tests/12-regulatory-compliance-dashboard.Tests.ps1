BeforeAll {
    $solutionRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
    $repoRoot = (Resolve-Path (Join-Path $solutionRoot '..\..')).Path
    $script:repoRoot = $repoRoot
    $script:deployScriptPath = Join-Path $solutionRoot 'scripts\Deploy-Solution.ps1'
    $script:monitorScriptPath = Join-Path $solutionRoot 'scripts\Monitor-Compliance.ps1'
    $script:exportScriptPath = Join-Path $solutionRoot 'scripts\Export-Evidence.ps1'
    $script:validateLabEvidenceScriptPath = Join-Path $solutionRoot 'scripts\Validate-LabEvidence.ps1'
    $script:labContractPath = Join-Path $solutionRoot 'lab\12-regulatory-compliance-dashboard.lab.json'
    $script:labPackageValidatorScriptPath = Join-Path $repoRoot 'scripts\validate-lab-package.ps1'
    $script:pwshPath = (Get-Command pwsh -ErrorAction Stop).Source
    $defaultConfigPath = Join-Path $solutionRoot 'config\default-config.json'
    $regulatedConfigPath = Join-Path $solutionRoot 'config\regulated.json'
    $script:defaultConfig = Get-Content -Path $defaultConfigPath -Raw | ConvertFrom-Json
    $script:regulatedConfig = Get-Content -Path $regulatedConfigPath -Raw | ConvertFrom-Json
    $contract = Get-Content -Path $script:labContractPath -Raw -Encoding utf8 | ConvertFrom-Json -Depth 50
    $verifyPhase = @($contract.execution.phases | Where-Object { $_.id -eq 'verify' })[0]
    $script:labValidationCommand = [string](@($verifyPhase.steps | Where-Object { $_.id -eq 'step-validate-schema-hash-freshness' })[0].command)
}

Describe 'Regulatory Compliance Dashboard package' {
    AfterEach {
        $labOutputPath = Join-Path $script:repoRoot 'lab-output'
        if (Test-Path -Path $labOutputPath) {
            Remove-Item -Path $labOutputPath -Recurse -Force
        }
    }

    It 'has required configuration files' {
        Test-Path (Join-Path $solutionRoot 'config\default-config.json') | Should -BeTrue
        Test-Path (Join-Path $solutionRoot 'config\baseline.json') | Should -BeTrue
        Test-Path (Join-Path $solutionRoot 'config\recommended.json') | Should -BeTrue
        Test-Path (Join-Path $solutionRoot 'config\regulated.json') | Should -BeTrue
    }

    It 'has required documentation files' {
        Test-Path (Join-Path $solutionRoot 'README.md') | Should -BeTrue
        Test-Path (Join-Path $solutionRoot 'docs\architecture.md') | Should -BeTrue
        Test-Path (Join-Path $solutionRoot 'docs\deployment-guide.md') | Should -BeTrue
        Test-Path (Join-Path $solutionRoot 'docs\evidence-export.md') | Should -BeTrue
        Test-Path (Join-Path $solutionRoot 'docs\prerequisites.md') | Should -BeTrue
        Test-Path (Join-Path $solutionRoot 'docs\troubleshooting.md') | Should -BeTrue
    }

    It 'includes comment-based help in Deploy-Solution.ps1' {
        $deployScriptContent = Get-Content -Path $script:deployScriptPath -Raw
        $deployScriptContent | Should -Match '<#'
        $deployScriptContent | Should -Match '\.SYNOPSIS'
    }

    It 'accepts the FreshnessThresholdHours parameter in Monitor-Compliance.ps1' {
        (Get-Content -Path $script:monitorScriptPath -Raw) | Should -Match 'FreshnessThresholdHours'
    }

    It 'references the RCD solution code in Export-Evidence.ps1' {
        (Get-Content -Path $script:exportScriptPath -Raw) | Should -Match "SolutionCode 'RCD'"
    }

    It 'defines regulatory frameworks in default-config.json' {
        $script:defaultConfig.regulatoryFrameworks.Count | Should -BeGreaterThan 0
    }

    It 'lab contract captures read-only Viewer and scope boundaries for first-cycle validation' {
        $contract = Get-Content -Path $script:labContractPath -Raw -Encoding utf8 | ConvertFrom-Json -Depth 50
        $groupsClaim = @($contract.microsoftSourceClaims | Where-Object { $_.id -eq 'claim-powerbi-rest-readonly' })[0]
        $workspaceStep = @(@($contract.execution.phases | Where-Object { $_.id -eq 'exercise' })[0].steps | Where-Object { $_.id -eq 'step-inspect-workspace-readonly' })[0]
        $viewerStep = @(@($contract.execution.phases | Where-Object { $_.id -eq 'exercise' })[0].steps | Where-Object { $_.id -eq 'step-inspect-report-semanticmodel-readonly' })[0]
        $readonlyArtifact = @($contract.evidence.requiredArtifacts | Where-Object { $_.id -eq 'artifact-readonly-inspection' })[0]

        [string]$groupsClaim.sourceUrl | Should -Be 'https://learn.microsoft.com/en-us/rest/api/power-bi/groups/get-groups'
        [string]$groupsClaim.claimText | Should -Match 'GET /v1\.0/myorg/groups'
        [string]$groupsClaim.claimText | Should -Match 'Workspace\.Read\.All'
        [string]$groupsClaim.claimText | Should -Match 'Workspace\.ReadWrite\.All'
        [string]$contract.prerequisites.notes | Should -Match 'no Workspace\.ReadWrite\.All'
        [string]$contract.prerequisites.notes | Should -Match 'Missing scope or consent.*BLOCKED'
        [string]$workspaceStep.expected | Should -Match 'aggregate count and boolean target-workspace-match'
        [string]$workspaceStep.expected | Should -Match 'Missing Workspace\.Read\.All scope.*BLOCKED'
        [string]$viewerStep.expected | Should -Match 'does not require Build permission or edit roles'
        [string]$viewerStep.expected | Should -Match 'Viewer does not inspect model-view tables/measures directly'
        [string]$readonlyArtifact.description | Should -Match 'aggregate counts and boolean workspace-match'
    }

    It 'retains regulated evidence for at least 365 days' {
        [int]$script:regulatedConfig.evidenceRetentionDays | Should -BeGreaterOrEqual 365
    }

    It 'parses Deploy-Solution.ps1 without syntax errors' {
        $tokens = $null
        $parseErrors = $null
        [void][System.Management.Automation.Language.Parser]::ParseFile($script:deployScriptPath, [ref]$tokens, [ref]$parseErrors)
        $parseErrors.Count | Should -Be 0
    }

    It 'Monitor-Compliance.ps1 marks fallback output as documentation-first' {
        $monitorResult = & $script:monitorScriptPath -ConfigurationTier baseline -OutputPath (Join-Path $TestDrive 'monitor') 3>$null

        $monitorResult.SnapshotSource | Should -Be 'fallback-defaults'
        $monitorResult.SnapshotSourcePath | Should -BeNullOrEmpty
        $monitorResult.RuntimeMode | Should -Be 'documentation-first-fallback'
        @($monitorResult.Controls | Where-Object { $_.status -eq 'implemented' }).Count | Should -Be 0
    }

    It 'Export-Evidence.ps1 keeps seeded dashboard controls below implemented' {
        $exportResult = & $script:exportScriptPath -ConfigurationTier recommended -OutputPath (Join-Path $TestDrive 'evidence')
        $package = Get-Content -Path $exportResult.Package.Path -Raw | ConvertFrom-Json -Depth 20
        $dashboardExport = Get-Content -Path (Join-Path $TestDrive 'evidence\dashboard-export.json') -Raw | ConvertFrom-Json -Depth 20

        $package.metadata.runtimeMode | Should -Be 'documentation-first-seed'
        @($package.controls | Where-Object { $_.status -eq 'implemented' }).Count | Should -Be 0
        $dashboardExport.warning | Should -Match 'seeded dashboard artifacts'
    }

    It 'Export-Evidence.ps1 surfaces a data-quality gap instead of appearing current' {
        $evidenceDir = Join-Path $TestDrive 'evidence-freshness'
        & $script:exportScriptPath -ConfigurationTier recommended -OutputPath $evidenceDir | Out-Null

        $dashboardExport = Get-Content -Path (Join-Path $evidenceDir 'dashboard-export.json') -Raw | ConvertFrom-Json -Depth 20
        $dashboardExport.dataQuality.overall | Should -Be 'gap'
        $dashboardExport.dataQuality.resolvedPackages | Should -Be 0
        @($dashboardExport.referencedEvidencePackages | Where-Object { $_.freshnessStatus -eq 'current' }).Count | Should -Be 0
        @($dashboardExport.referencedEvidencePackages).Where({ $_.freshnessStatus -eq 'unknown' }).Count | Should -BeGreaterThan 0

        $coverage = Get-Content -Path (Join-Path $evidenceDir 'framework-coverage-matrix.json') -Raw | ConvertFrom-Json -Depth 20
        @($coverage | Where-Object { $_.evidenceFreshnessState -eq 'current' }).Count | Should -Be 0

        $snapshot = Get-Content -Path (Join-Path $evidenceDir 'control-status-snapshot.json') -Raw | ConvertFrom-Json -Depth 20
        $snapshot[0].lastEvidenceDate | Should -BeNullOrEmpty
        $snapshot[0].freshnessState | Should -Be 'not-applicable'
        $snapshot[0].timestampProvenance | Should -Be 'synthetic-seed'
    }

    It 'Validate-LabEvidence.ps1 accepts playbook-only and not-applicable coverage states' {
        $outputPath = Join-Path $TestDrive 'validate-lab-coverage-valid'
        & $script:exportScriptPath -ConfigurationTier recommended -OutputPath $outputPath | Out-Null
        & $script:monitorScriptPath -ConfigurationTier recommended -OutputPath $outputPath 3>$null | Out-Null

        $snapshotPath = Join-Path $outputPath 'control-status-snapshot.json'
        $snapshot = @(Get-Content -Path $snapshotPath -Raw -Encoding utf8 | ConvertFrom-Json -Depth 20)
        $snapshot[0].status = 'playbook-only'
        $snapshot[0].score = 10
        $snapshot[1].status = 'not-applicable'
        $snapshot[1].score = 0
        $snapshot | ConvertTo-Json -Depth 20 | Set-Content -Path $snapshotPath -Encoding utf8

        $snapshotHash = (Get-FileHash -Path $snapshotPath -Algorithm SHA256).Hash.ToLowerInvariant()
        Set-Content -Path ($snapshotPath + '.sha256') -Value ('{0}  {1}' -f $snapshotHash, (Split-Path -Path $snapshotPath -Leaf)) -Encoding utf8
        $packagePath = Join-Path $outputPath '12-regulatory-compliance-dashboard-evidence.json'
        $package = Get-Content -Path $packagePath -Raw -Encoding utf8 | ConvertFrom-Json -Depth 20
        @($package.artifacts | Where-Object { [string]$_.path -eq 'control-status-snapshot.json' })[0].hash = $snapshotHash
        $package | ConvertTo-Json -Depth 20 | Set-Content -Path $packagePath -Encoding utf8
        $packageHash = (Get-FileHash -Path $packagePath -Algorithm SHA256).Hash.ToLowerInvariant()
        Set-Content -Path ($packagePath + '.sha256') -Value ('{0}  {1}' -f $packageHash, (Split-Path -Path $packagePath -Leaf)) -Encoding utf8

        { & $script:validateLabEvidenceScriptPath -OutputPath $outputPath | Out-Null } | Should -Not -Throw
    }

    It 'Validate-LabEvidence.ps1 rejects non-coverage status values' -ForEach @(
        @{ InvalidStatus = 'not-implemented' },
        @{ InvalidStatus = 'PASS' },
        @{ InvalidStatus = 'BLOCKED' }
    ) {
        param($InvalidStatus)

        $outputPath = Join-Path $TestDrive ('validate-lab-coverage-invalid-{0}' -f ([string]$InvalidStatus).ToLowerInvariant())
        & $script:exportScriptPath -ConfigurationTier recommended -OutputPath $outputPath | Out-Null
        & $script:monitorScriptPath -ConfigurationTier recommended -OutputPath $outputPath 3>$null | Out-Null

        $snapshotPath = Join-Path $outputPath 'control-status-snapshot.json'
        $snapshot = @(Get-Content -Path $snapshotPath -Raw -Encoding utf8 | ConvertFrom-Json -Depth 20)
        $snapshot[0].status = $InvalidStatus
        $snapshot | ConvertTo-Json -Depth 20 | Set-Content -Path $snapshotPath -Encoding utf8

        $snapshotHash = (Get-FileHash -Path $snapshotPath -Algorithm SHA256).Hash.ToLowerInvariant()
        Set-Content -Path ($snapshotPath + '.sha256') -Value ('{0}  {1}' -f $snapshotHash, (Split-Path -Path $snapshotPath -Leaf)) -Encoding utf8
        $packagePath = Join-Path $outputPath '12-regulatory-compliance-dashboard-evidence.json'
        $package = Get-Content -Path $packagePath -Raw -Encoding utf8 | ConvertFrom-Json -Depth 20
        @($package.artifacts | Where-Object { [string]$_.path -eq 'control-status-snapshot.json' })[0].hash = $snapshotHash
        $package | ConvertTo-Json -Depth 20 | Set-Content -Path $packagePath -Encoding utf8
        $packageHash = (Get-FileHash -Path $packagePath -Algorithm SHA256).Hash.ToLowerInvariant()
        Set-Content -Path ($packagePath + '.sha256') -Value ('{0}  {1}' -f $packageHash, (Split-Path -Path $packagePath -Leaf)) -Encoding utf8

        { & $script:validateLabEvidenceScriptPath -OutputPath $outputPath | Out-Null } | Should -Throw -ExpectedMessage "*$InvalidStatus*"
    }

    It 'dashboard control-feed schema allows all canonical coverage states' {
        $schemaPath = Join-Path $script:repoRoot 'templates\dashboard\control-feed-schema.json'
        $schema = Get-Content -Path $schemaPath -Raw -Encoding utf8 | ConvertFrom-Json -Depth 20
        $expectedStatuses = @('implemented', 'partial', 'monitor-only', 'playbook-only', 'not-applicable')
        $actualStatuses = @($schema.allowedStatuses)

        $actualStatuses.Count | Should -Be 5
        @(Compare-Object -ReferenceObject ($expectedStatuses | Sort-Object) -DifferenceObject ($actualStatuses | Sort-Object)).Count | Should -Be 0
    }

    It 'Monitor-Compliance.ps1 consumes Export-Evidence snapshot in the same output folder' {
        $outputPath = Join-Path $TestDrive 'monitor-handoff'
        & $script:exportScriptPath -ConfigurationTier recommended -OutputPath $outputPath | Out-Null
        $monitorResult = & $script:monitorScriptPath -ConfigurationTier recommended -OutputPath $outputPath 3>$null

        $monitorResult.SnapshotSource | Should -Be 'control-status-snapshot'
        $monitorResult.SnapshotSourcePath | Should -Be (Join-Path $outputPath 'control-status-snapshot.json')
        $monitorResult.RuntimeMode | Should -Be 'seeded-or-live-snapshot'
        @($monitorResult.Controls | Where-Object { $_.dataSourceMode -eq 'documentation-first-seed' }).Count | Should -Be 6
        $monitorResult.DataQualityGap | Should -BeTrue
    }

    It 'Monitor-Compliance.ps1 prefers rcd-control-status-snapshot.json when both snapshots exist' {
        $outputPath = Join-Path $TestDrive 'monitor-preferred-source'
        & $script:exportScriptPath -ConfigurationTier baseline -OutputPath $outputPath | Out-Null
        $seedSnapshotPath = Join-Path $outputPath 'control-status-snapshot.json'
        $preferredSnapshotPath = Join-Path $outputPath 'rcd-control-status-snapshot.json'
        $seedControls = @(Get-Content -Path $seedSnapshotPath -Raw | ConvertFrom-Json -Depth 20)
        $seedControls[0].status = 'implemented'
        $seedControls[0].score = 100
        $seedControls[0].notes = 'preferred-snapshot-marker'

        [ordered]@{
            metadata = @{ generatedBy = 'test' }
            controls = $seedControls
        } | ConvertTo-Json -Depth 20 | Set-Content -Path $preferredSnapshotPath -Encoding utf8

        $monitorResult = & $script:monitorScriptPath -ConfigurationTier baseline -OutputPath $outputPath 3>$null
        $monitorResult.SnapshotSource | Should -Be 'rcd-control-status-snapshot'
        ($monitorResult.Controls | Where-Object { $_.controlId -eq '3.7' } | Select-Object -ExpandProperty notes) | Should -Be 'preferred-snapshot-marker'
    }

    It 'Monitor-Compliance.ps1 reports missing evidence timestamps as unknown gaps' {
        $monitorResult = & $script:monitorScriptPath -ConfigurationTier baseline -OutputPath (Join-Path $TestDrive 'monitor-gap') 3>$null

        $monitorResult.DataQualityGap | Should -BeTrue
        [int]$monitorResult.TimestampGapControlCount | Should -Be 6
        @($monitorResult.StaleEvidence | Where-Object { $_.timestampProvenance -eq 'missing' }).Count | Should -Be 6
        @($monitorResult.StaleEvidence | Where-Object { $_.freshnessState -eq 'unknown' }).Count | Should -Be 6
    }

    It 'Monitor-Compliance.ps1 handles malformed timestamps without crashing and marks them invalid' {
        $outputPath = Join-Path $TestDrive 'monitor-invalid-timestamp'
        $snapshotPath = Join-Path $outputPath 'rcd-control-status-snapshot.json'
        $null = New-Item -ItemType Directory -Path $outputPath -Force
        @(
            [pscustomobject]@{
                controlId = '3.7'
                controlTitle = 'Invalid timestamp test'
                status = 'partial'
                score = 50
                lastEvidenceDate = 'not-a-date'
                sourceLastModified = 'not-a-date'
                notes = 'invalid timestamp'
            }
        ) | ConvertTo-Json -Depth 10 | Set-Content -Path $snapshotPath -Encoding utf8

        $monitorResult = & $script:monitorScriptPath -ConfigurationTier baseline -OutputPath $outputPath 3>$null
        $monitorResult | Should -Not -BeNullOrEmpty
        $monitorResult.DataQualityGap | Should -BeTrue
        [int]$monitorResult.TimestampGapControlCount | Should -Be 1
        $monitorResult.StaleEvidence[0].timestampProvenance | Should -Be 'invalid'
        $monitorResult.StaleEvidence[0].timestampState | Should -Be 'invalid-format'
        $monitorResult.StaleEvidence[0].freshnessState | Should -Be 'unknown'
    }

    It 'Monitor-Compliance.ps1 treats future source timestamps as unknown and never current' {
        $outputPath = Join-Path $TestDrive 'monitor-future-timestamp'
        $snapshotPath = Join-Path $outputPath 'rcd-control-status-snapshot.json'
        $null = New-Item -ItemType Directory -Path $outputPath -Force
        $futureTimestamp = (Get-Date).ToUniversalTime().AddHours(12).ToString('o')
        @(
            [pscustomobject]@{
                controlId = '3.8'
                controlTitle = 'Future timestamp test'
                status = 'partial'
                score = 50
                lastEvidenceDate = $futureTimestamp
                sourceLastModified = $futureTimestamp
                notes = 'future timestamp'
            }
        ) | ConvertTo-Json -Depth 10 | Set-Content -Path $snapshotPath -Encoding utf8

        $monitorResult = & $script:monitorScriptPath -ConfigurationTier baseline -OutputPath $outputPath 3>$null
        $monitorResult.DataQualityGap | Should -BeTrue
        [int]$monitorResult.TimestampGapControlCount | Should -Be 1
        $monitorResult.StaleEvidence[0].timestampProvenance | Should -Be 'invalid'
        $monitorResult.StaleEvidence[0].timestampState | Should -Be 'future'
        $monitorResult.StaleEvidence[0].freshnessState | Should -Be 'unknown'
        $monitorResult.StaleEvidence[0].reason | Should -Match 'future'
    }

    It 'Monitor-Compliance.ps1 preserves valid fresh and stale source timestamp behavior' {
        $outputPath = Join-Path $TestDrive 'monitor-fresh-stale'
        $snapshotPath = Join-Path $outputPath 'rcd-control-status-snapshot.json'
        $null = New-Item -ItemType Directory -Path $outputPath -Force
        $freshTimestamp = (Get-Date).ToUniversalTime().AddHours(-1).ToString('o')
        $staleTimestamp = (Get-Date).ToUniversalTime().AddHours(-48).ToString('o')
        @(
            [pscustomobject]@{
                controlId = '3.7'
                controlTitle = 'Fresh control'
                status = 'partial'
                score = 50
                lastEvidenceDate = $freshTimestamp
                sourceLastModified = $freshTimestamp
            },
            [pscustomobject]@{
                controlId = '3.8'
                controlTitle = 'Stale control'
                status = 'partial'
                score = 50
                lastEvidenceDate = $staleTimestamp
                sourceLastModified = $staleTimestamp
            }
        ) | ConvertTo-Json -Depth 10 | Set-Content -Path $snapshotPath -Encoding utf8

        $monitorResult = & $script:monitorScriptPath -ConfigurationTier baseline -OutputPath $outputPath -FreshnessThresholdHours 25 3>$null
        $monitorResult.DataQualityGap | Should -BeFalse
        [int]$monitorResult.TimestampGapControlCount | Should -Be 0
        @($monitorResult.StaleEvidence).Count | Should -Be 1
        $monitorResult.StaleEvidence[0].controlId | Should -Be '3.8'
        $monitorResult.StaleEvidence[0].timestampProvenance | Should -Be 'source-provided'
        $monitorResult.StaleEvidence[0].freshnessState | Should -Be 'stale'
    }

    It 'Export-Evidence.ps1 emits absolute package paths and relative artifact paths' {
        $outputPath = Join-Path $TestDrive 'portable-package'
        $exportResult = & $script:exportScriptPath -ConfigurationTier recommended -OutputPath $outputPath
        $packagePath = $exportResult.Package.Path
        $packageDirectory = Split-Path -Path $packagePath -Parent
        $package = Get-Content -Path $packagePath -Raw | ConvertFrom-Json -Depth 20

        [IO.Path]::IsPathRooted($packagePath) | Should -BeTrue
        foreach ($artifact in @($package.artifacts)) {
            [IO.Path]::IsPathRooted([string]$artifact.path) | Should -BeFalse
            Test-Path (Join-Path $packageDirectory ([string]$artifact.path)) | Should -BeTrue
        }
    }

    It 'Export-Evidence.ps1 resolves relative output paths from the active location and relocated packages validate' {
        $workingRoot = Join-Path $TestDrive 'relative-output-root'
        $null = New-Item -ItemType Directory -Path $workingRoot -Force
        $relativeOutputPath = 'lab-output'

        Push-Location $workingRoot
        try {
            $exportResult = & $script:exportScriptPath -ConfigurationTier baseline -OutputPath $relativeOutputPath
        }
        finally {
            Pop-Location
        }

        $expectedOutputPath = Join-Path $workingRoot $relativeOutputPath
        [IO.Path]::IsPathRooted($exportResult.Package.Path) | Should -BeTrue
        ($exportResult.Package.Path.StartsWith($expectedOutputPath, [System.StringComparison]::OrdinalIgnoreCase)) | Should -BeTrue

        $relocatedOutputPath = Join-Path $TestDrive 'relocated-lab-output'
        Copy-Item -Path $expectedOutputPath -Destination $relocatedOutputPath -Recurse
        $relocatedPackagePath = Join-Path $relocatedOutputPath '12-regulatory-compliance-dashboard-evidence.json'
        { & $script:labPackageValidatorScriptPath -Path $relocatedPackagePath | Out-Null } | Should -Not -Throw
    }

    It 'lab verification command passes for untouched generated output' {
        $workingDirectory = $script:repoRoot
        $labOutput = Join-Path $workingDirectory 'lab-output'
        & $script:exportScriptPath -ConfigurationTier recommended -OutputPath $labOutput | Out-Null
        & $script:monitorScriptPath -ConfigurationTier recommended -OutputPath $labOutput 3>$null | Out-Null

        Push-Location $workingDirectory
        try {
            $output = & $script:pwshPath -NoLogo -NoProfile -Command $script:labValidationCommand 2>&1
            $result = [pscustomobject]@{ ExitCode = $LASTEXITCODE; Output = ($output | Out-String) }
        }
        finally {
            Pop-Location
        }
        $result.ExitCode | Should -Be 0
    }

    It 'lab verification command fails when an emitted artifact is tampered' {
        $workingDirectory = $script:repoRoot
        $labOutput = Join-Path $workingDirectory 'lab-output'
        & $script:exportScriptPath -ConfigurationTier recommended -OutputPath $labOutput | Out-Null
        & $script:monitorScriptPath -ConfigurationTier recommended -OutputPath $labOutput 3>$null | Out-Null

        Add-Content -Path (Join-Path $labOutput 'dashboard-export.json') -Value 'tamper'
        Push-Location $workingDirectory
        try {
            $output = & $script:pwshPath -NoLogo -NoProfile -Command $script:labValidationCommand 2>&1
            $result = [pscustomobject]@{ ExitCode = $LASTEXITCODE; Output = ($output | Out-String) }
        }
        finally {
            Pop-Location
        }
        $result.ExitCode | Should -Not -Be 0
        $result.Output | Should -Match 'Artifact hash validation failed'
    }

    It 'lab verification command fails when a sidecar file is missing' {
        $workingDirectory = $script:repoRoot
        $labOutput = Join-Path $workingDirectory 'lab-output'
        & $script:exportScriptPath -ConfigurationTier recommended -OutputPath $labOutput | Out-Null
        & $script:monitorScriptPath -ConfigurationTier recommended -OutputPath $labOutput 3>$null | Out-Null

        Remove-Item -Path (Join-Path $labOutput 'dashboard-export.json.sha256') -Force
        Push-Location $workingDirectory
        try {
            $output = & $script:pwshPath -NoLogo -NoProfile -Command $script:labValidationCommand 2>&1
            $result = [pscustomobject]@{ ExitCode = $LASTEXITCODE; Output = ($output | Out-String) }
        }
        finally {
            Pop-Location
        }
        $result.ExitCode | Should -Not -Be 0
        $result.Output | Should -Match 'Hash file not found'
    }

    It 'lab verification command fails for schema-invalid package content' {
        $workingDirectory = $script:repoRoot
        $labOutput = Join-Path $workingDirectory 'lab-output'
        & $script:exportScriptPath -ConfigurationTier recommended -OutputPath $labOutput | Out-Null
        & $script:monitorScriptPath -ConfigurationTier recommended -OutputPath $labOutput 3>$null | Out-Null

        $packagePath = Join-Path $labOutput '12-regulatory-compliance-dashboard-evidence.json'
        $package = Get-Content -Path $packagePath -Raw | ConvertFrom-Json -Depth 20
        $package.metadata.PSObject.Properties.Remove('exportVersion')
        $package | ConvertTo-Json -Depth 20 | Set-Content -Path $packagePath -Encoding utf8
        $hash = (Get-FileHash -Path $packagePath -Algorithm SHA256).Hash.ToLowerInvariant()
        Set-Content -Path ($packagePath + '.sha256') -Value ('{0}  {1}' -f $hash, (Split-Path -Path $packagePath -Leaf)) -Encoding utf8

        Push-Location $workingDirectory
        try {
            $output = & $script:pwshPath -NoLogo -NoProfile -Command $script:labValidationCommand 2>&1
            $result = [pscustomobject]@{ ExitCode = $LASTEXITCODE; Output = ($output | Out-String) }
        }
        finally {
            Pop-Location
        }
        $result.ExitCode | Should -Not -Be 0
            $result.Output | Should -Match 'Schema validation failed|exportVersion'
    }
}
