#Requires -Version 7.2
<#
.SYNOPSIS
    Pester smoke tests for the Generative AI Model Governance Monitor (GMG) scaffold.

.DESCRIPTION
    Validates that all required files exist, configuration files contain expected
    fields, scripts parse, and config loads through GmgConfig.psm1.
#>

BeforeAll {
    $solutionRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
    $script:repoRoot = (Resolve-Path (Join-Path $solutionRoot '..\..')).Path
    $script:scriptsPath = Join-Path $solutionRoot 'scripts'
    $script:configPath = Join-Path $solutionRoot 'config'
    $script:docsPath = Join-Path $solutionRoot 'docs'

    function Get-JsonContent {
        param([string]$Path)
        Get-Content -Path $Path -Raw | ConvertFrom-Json
    }

    function Test-PowerShellParse {
        param([string]$Path)
        $errors = $null
        [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$null, [ref]$errors) | Out-Null
        return (-not $errors)
    }
}

Describe 'GMG - File Presence' {
    It 'has README.md'             { Test-Path (Join-Path $solutionRoot 'README.md')             | Should -BeTrue }
    It 'has CHANGELOG.md'          { Test-Path (Join-Path $solutionRoot 'CHANGELOG.md')          | Should -BeTrue }
    It 'has DELIVERY-CHECKLIST.md' { Test-Path (Join-Path $solutionRoot 'DELIVERY-CHECKLIST.md') | Should -BeTrue }

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
        foreach ($p in @('Deploy-Solution.ps1', 'Monitor-Compliance.ps1', 'Export-Evidence.ps1', 'GmgConfig.psm1')) {
            Test-Path (Join-Path $script:scriptsPath $p) | Should -BeTrue
        }
    }
}

Describe 'GMG - Configuration Validation' {
    Context 'default-config.json' {
        BeforeAll { $script:defaultConfig = Get-JsonContent -Path (Join-Path $script:configPath 'default-config.json') }

        It 'has correct solution slug' { $script:defaultConfig.solution     | Should -Be '20-generative-ai-model-governance-monitor' }
        It 'has solutionCode GMG'      { $script:defaultConfig.solutionCode | Should -Be 'GMG' }
        It 'has track D'               { $script:defaultConfig.track        | Should -Be 'D' }
        It 'has primary controls 3.8a and 3.8' {
            @($script:defaultConfig.primaryControls) | Should -Contain '3.8a'
            @($script:defaultConfig.primaryControls) | Should -Contain '3.8'
        }
        It 'cites Federal Reserve SR 11-7 and OCC Bulletin 2011-12 model risk guidance' {
            @($script:defaultConfig.regulations) | Should -Contain 'Federal Reserve SR 11-7'
            @($script:defaultConfig.regulations) | Should -Contain 'OCC Bulletin 2011-12 (Supervisory Guidance on Model Risk Management)'
        }
        It 'lists all five evidence outputs' {
            foreach ($e in @('copilot-model-inventory', 'validation-summary', 'ongoing-monitoring-log', 'content-safety-and-guardrails', 'third-party-due-diligence')) {
                @($script:defaultConfig.evidenceOutputs) | Should -Contain $e
            }
        }
        It 'lists structured model sources and content safety defaults' {
            @($script:defaultConfig.defaults.trackedModelSources).Count | Should -BeGreaterOrEqual 4
            @($script:defaultConfig.defaults.trackedModelSources.modelSource) | Should -Contain 'azureopenai'
            @($script:defaultConfig.defaults.trackedModelSources.modelSource) | Should -Contain 'partner'
            $script:defaultConfig.defaults.contentSafetyDefaults.promptShields | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Each tier config' {
        It '<tier> has required fields' -ForEach @(
            @{ tier = 'baseline' }, @{ tier = 'recommended' }, @{ tier = 'regulated' }
        ) {
            $config = Get-JsonContent -Path (Join-Path $script:configPath ("{0}.json" -f $tier))
            $propertyNames = $config.PSObject.Properties.Name
            foreach ($f in @('solution', 'tier', 'controls', 'model_inventory_review_cadence_days', 'monitoring_log_retention_days', 'validation_assessment_required', 'third_party_review_cadence_days', 'ongoingMonitoring', 'evidenceRetentionDays', 'notificationMode')) {
                $propertyNames | Should -Contain $f
            }
        }

        It 'regulated tier requires independent challenge' {
            $regulated = Get-JsonContent -Path (Join-Path $script:configPath 'regulated.json')
            $regulated.independentChallenge.enabled | Should -BeTrue
            $regulated.validation_assessment_required | Should -Match 'independent-challenge'
        }
    }
}

Describe 'GMG - Script Parse Validation' {
    It '<script> parses' -ForEach @(
        @{ script = 'Deploy-Solution.ps1' },
        @{ script = 'Monitor-Compliance.ps1' },
        @{ script = 'Export-Evidence.ps1' },
        @{ script = 'GmgConfig.psm1' }
    ) {
        Test-PowerShellParse -Path (Join-Path $script:scriptsPath $script) | Should -BeTrue
    }
}

Describe 'GMG - Config Loader Smoke Test' {
    BeforeAll {
        Import-Module (Join-Path $script:scriptsPath 'GmgConfig.psm1') -Force
    }

    It 'Get-GmgConfiguration loads <tier> tier' -ForEach @(
        @{ tier = 'baseline' }, @{ tier = 'recommended' }, @{ tier = 'regulated' }
    ) {
        $config = Get-GmgConfiguration -Tier $tier
        $config.tier | Should -Be $tier
        { Test-GmgConfiguration -Configuration $config } | Should -Not -Throw
    }
}

Describe 'GMG - Documentation Validation' {
    BeforeAll {
        $script:readme        = Get-Content -Path (Join-Path $solutionRoot 'README.md') -Raw
        $script:architecture  = Get-Content -Path (Join-Path $script:docsPath 'architecture.md') -Raw
        $script:evidenceExport = Get-Content -Path (Join-Path $script:docsPath 'evidence-export.md') -Raw
    }

    It 'README references SR 26-2 / OCC Bulletin 2026-13' { $script:readme | Should -Match 'SR 26-2 / OCC Bulletin 2026-13' }
    It 'README references SR 11-7' { $script:readme | Should -Match 'SR 11-7' }
    It 'README references all primary controls' {
        $script:readme | Should -Match '3\.8a'
        $script:readme | Should -Match '3\.8'
    }
    It 'architecture.md references SR 11-7' { $script:architecture | Should -Match 'SR 11-7' }
    It 'evidence-export.md references all five outputs' {
        $script:evidenceExport | Should -Match 'copilot-model-inventory'
        $script:evidenceExport | Should -Match 'validation-summary'
        $script:evidenceExport | Should -Match 'ongoing-monitoring-log'
        $script:evidenceExport | Should -Match 'content-safety-and-guardrails'
        $script:evidenceExport | Should -Match 'third-party-due-diligence'
    }
}

Describe 'GMG - Microsoft Currency and Scope Accuracy' {
    BeforeAll {
        $script:readme        = Get-Content -Path (Join-Path $solutionRoot 'README.md') -Raw
        $script:prerequisites = Get-Content -Path (Join-Path $script:docsPath 'prerequisites.md') -Raw
        $script:architecture  = Get-Content -Path (Join-Path $script:docsPath 'architecture.md') -Raw
        $script:evidenceExport = Get-Content -Path (Join-Path $script:docsPath 'evidence-export.md') -Raw
        $script:defaultConfig = Get-JsonContent -Path (Join-Path $script:configPath 'default-config.json')
    }

    It 'Scope Boundaries state the solution does not govern Microsoft-hosted Copilot foundation models' {
        $script:readme | Should -Match 'does not govern.*foundation models|foundation models behind Microsoft 365 Copilot'
    }

    It 'README does not equate Microsoft 365 Copilot governance with Foundry governance' {
        $script:readme | Should -Match 'does not equate Microsoft 365 Copilot governance'
    }

    It 'Solution docs use the canonical Azure OpenAI default Guardrail source and remove the classic source URL' {
        foreach ($doc in @($script:readme, $script:prerequisites, $script:architecture, $script:evidenceExport)) {
            $doc | Should -Match 'default-safety-policies'
            $doc | Should -Not -Match 'foundry-classic/foundry-models/concepts/content-filter'
        }
    }

    It 'README and architecture narrow built-in guardrail claims to Azure OpenAI and avoid uniform provider claims' {
        $script:readme | Should -Match 'Azure OpenAI deployments in Microsoft Foundry default configurable Guardrail policies'
        $script:readme | Should -Match 'non-Azure-OpenAI'
        $script:readme | Should -Match 'provider/deployment-native guardrails.*only where'
        $script:architecture | Should -Match 'non-Azure-OpenAI Foundry/provider deployments'
        $script:architecture | Should -Match 'documentation and read-only portal'
    }

    It 'prerequisites clarify Azure OpenAI default Guardrails and separate optional standalone Content Safety' {
        $script:prerequisites | Should -Match 'Azure OpenAI deployments in Microsoft Foundry default configurable Guardrail policies'
        $script:prerequisites | Should -Match 'Azure AI Content Safety remains a separate optional standalone service'
    }

    It 'architecture avoids blanket enablement claims for optional guardrail controls' {
        $script:architecture | Should -Match 'other supported controls where enabled'
    }

    It 'config sample values align to Azure OpenAI default guardrails and provider-native coverage' {
        $foundryAzureOpenAi = @($script:defaultConfig.defaults.trackedModelSources | Where-Object { $_.sourceId -eq 'foundry-azure-openai' })[0]
        $foundryPartner = @($script:defaultConfig.defaults.trackedModelSources | Where-Object { $_.sourceId -eq 'foundry-partner-community' })[0]

        $foundryAzureOpenAi.contentSafetyProfile | Should -Be 'azure-openai-default-guardrails'
        $foundryPartner.contentSafetyProfile | Should -Be 'provider-native-guardrails-documented-where-visible'
        $script:defaultConfig.defaults.contentSafetyDefaults.contentSafetyResourceStatus | Should -Be 'azure-ai-content-safety-standalone-optional'
    }

    It 'uses current Microsoft Foundry branding and no legacy Azure AI Foundry / Studio names in forward-facing docs' {
        $script:readme        | Should -Not -Match 'Azure AI Foundry|Azure AI Studio'
        $script:prerequisites | Should -Not -Match 'Azure AI Foundry|Azure AI Studio'
        $script:architecture  | Should -Not -Match 'Azure AI Foundry|Azure AI Studio'
        $script:readme        | Should -Match 'Microsoft Foundry'
    }
}

Describe 'GMG - Lab Validation Contract' {
    BeforeAll {
        $script:labPath = Join-Path $solutionRoot 'lab/20-generative-ai-model-governance-monitor.lab.json'
        $script:lab = Get-JsonContent -Path $script:labPath
    }

    It 'lab contract file exists' {
        Test-Path $script:labPath | Should -BeTrue
    }

    It 'first cycle is read-only with an empty mutations array' {
        @($script:lab.mutations).Count | Should -Be 0
    }

    It 'no execution step references a mutation' {
        foreach ($phase in $script:lab.execution.phases) {
            foreach ($step in $phase.steps) {
                $step.mutationRef | Should -BeNullOrEmpty
            }
        }
    }

    It 'includes the four required execution phases' {
        $phaseIds = @($script:lab.execution.phases.id)
        foreach ($required in @('setup', 'exercise', 'verify', 'cleanup')) {
            $phaseIds | Should -Contain $required
        }
    }

    It 'accepts negative BLOCKED and NOT-APPLICABLE dispositions' {
        @($script:lab.dispositionRules.acceptedDispositions) | Should -Contain 'BLOCKED'
        @($script:lab.dispositionRules.acceptedDispositions) | Should -Contain 'NOT-APPLICABLE'
    }

    It 'records a negative-validation step for absent preconditions' {
        $stepIds = @($script:lab.execution.phases.steps.id)
        $stepIds | Should -Contain 'step-record-negative-validation'
    }

    It 'uses explicit Azure CLI identity verification with expected environment values, sanitized output, and fail-closed behavior' {
        $setupPhase = @($script:lab.execution.phases | Where-Object { $_.id -eq 'setup' })[0]
        $identityStep = @($setupPhase.steps | Where-Object { $_.id -eq 'step-confirm-subscription-identity' })[0]

        $identityStep.command | Should -Match 'EXPECTED_AZURE_SUBSCRIPTION_ID'
        $identityStep.command | Should -Match 'EXPECTED_TENANT_ID'
        $identityStep.command | Should -Match 'id:id,tenantId:tenantId,state:state,isDefault:isDefault,environmentName:environmentName'
        $identityStep.command | Should -Match 'Missing required EXPECTED_AZURE_SUBSCRIPTION_ID or EXPECTED_TENANT_ID'
        $identityStep.command | Should -Match 'did not match expected subscription/tenant'
        $identityStep.command | Should -Not -Match 'user.name|upn|accessToken|refreshToken'
        $identityStep.readBack.expectation | Should -Match 'without exposing identifiers'
    }

    It 'uses canonical Azure OpenAI guardrail source and narrowed provider wording' {
        $builtInClaim = @($script:lab.microsoftSourceClaims | Where-Object { $_.id -eq 'claim-content-filter-guardrails' })[0]
        $standaloneClaim = @($script:lab.microsoftSourceClaims | Where-Object { $_.id -eq 'claim-content-safety-standalone-service' })[0]
        $exercisePhase = @($script:lab.execution.phases | Where-Object { $_.id -eq 'exercise' })[0]
        $guardrailStep = @($exercisePhase.steps | Where-Object { $_.id -eq 'step-inspect-content-filter-guardrails' })[0]

        $builtInClaim.sourceUrl | Should -Be 'https://learn.microsoft.com/en-us/azure/foundry/openai/concepts/default-safety-policies'
        $builtInClaim.claimText | Should -Match 'Azure OpenAI deployments in Microsoft Foundry have default configurable Guardrail policies'
        $builtInClaim.claimText | Should -Match 'hate/fairness'
        $builtInClaim.claimText | Should -Match 'sexual'
        $builtInClaim.claimText | Should -Match 'violence'
        $builtInClaim.claimText | Should -Match 'self-harm'
        $standaloneClaim.claimText | Should -Match 'separate optional standalone service'

        $guardrailStep.expected | Should -Match 'non-Azure-OpenAI Foundry/provider deployments'
        $guardrailStep.expected | Should -Match 'only provider/deployment-native guardrails that are documented and visible'
        $guardrailStep.operatorNote | Should -Match 'do not assume built-in Guardrails across every Foundry model/provider deployment'
    }

    It 'verifies existing evidence hashes with Test-EvidencePackageHash and does not claim sensitive-content inspection' {
        $verifyPhase = @($script:lab.execution.phases | Where-Object { $_.id -eq 'verify' })[0]
        $hashStep = @($verifyPhase.steps | Where-Object { $_.id -eq 'step-verify-evidence-integrity' })[0]

        $hashStep.command | Should -Match 'scripts/common/EvidenceExport.psm1'
        $hashStep.command | Should -Match 'Test-EvidencePackageHash'
        $hashStep.command | Should -Not -Match 'Export-Evidence.ps1'
        $hashStep.expected | Should -Match 'artifact/sidecar pair'
        $hashStep.readBack.expectation | Should -Match 'hash'
        $hashStep.readBack.expectation | Should -Not -Match 'sensitive content'
    }

    It 'defines a separate read-only minimization review step and PASS attestation artifact' {
        $verifyPhase = @($script:lab.execution.phases | Where-Object { $_.id -eq 'verify' })[0]
        $minStep = @($verifyPhase.steps | Where-Object { $_.id -eq 'step-review-evidence-minimization' })[0]
        $artifact = @($script:lab.evidence.requiredArtifacts | Where-Object { $_.id -eq 'artifact-evidence-minimization-attestation' })[0]

        $minStep.mode | Should -Be 'manual'
        $minStep.expected | Should -Match 'keys/tokens'
        $minStep.expected | Should -Match 'raw subscription/tenant/user IDs'
        $minStep.expected | Should -Match 'endpoint hostnames'
        $minStep.expected | Should -Match 'prompts/completions'
        $minStep.expected | Should -Match 'dataset or model input/output content'
        $minStep.operatorNote | Should -Match 'Do not copy prohibited content'

        @($artifact.requiredForDispositions) | Should -Contain 'PASS'
        @($artifact.requiredForDispositions) | Should -Not -Contain 'BLOCKED'
        @($artifact.requiredForDispositions) | Should -Not -Contain 'NOT-APPLICABLE'
        $artifact.description | Should -Match 'Read-only attestation'
    }

    It 'is US commercial cloud scoped as a documentation-first template' {
        $script:lab.scope.cloud | Should -Be 'm365-us-commercial'
        $script:lab.solution.binding | Should -Be 'template'
    }
}

Describe 'GMG - Hash Verification Regression' {
    BeforeAll {
        Import-Module (Join-Path $script:repoRoot 'scripts\common\EvidenceExport.psm1') -Force
    }

    It 'passes untouched artifact hash and fails after tampering without regenerating sidecars' {
        $fixtureDir = Join-Path $script:repoRoot 'scripts\tests\fixtures\lab-package\artifacts'
        $artifactName = 'lab-summary.json'
        $fixtureArtifact = Join-Path $fixtureDir $artifactName
        $fixtureSidecar = "$fixtureArtifact.sha256"

        Test-Path $fixtureArtifact | Should -BeTrue
        Test-Path $fixtureSidecar | Should -BeTrue

        $testArtifact = Join-Path $TestDrive $artifactName
        Copy-Item -Path $fixtureArtifact -Destination $testArtifact
        Copy-Item -Path $fixtureSidecar -Destination "$testArtifact.sha256"

        $passResult = Test-EvidencePackageHash -Path $testArtifact
        $passResult.IsValid | Should -BeTrue

        $tamperedContent = (Get-Content -Path $testArtifact -Raw -Encoding utf8) + "`n "
        Set-Content -Path $testArtifact -Value $tamperedContent -Encoding utf8

        $failResult = Test-EvidencePackageHash -Path $testArtifact
        $failResult.IsValid | Should -BeFalse
    }
}
