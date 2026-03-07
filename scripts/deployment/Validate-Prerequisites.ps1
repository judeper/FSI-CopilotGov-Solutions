[CmdletBinding()]
param()

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$pythonCommand = Get-Command python -ErrorAction SilentlyContinue
$pythonVersion = $null
if ($pythonCommand) {
    try {
        $pythonVersion = (& $pythonCommand.Source --version 2>&1).ToString().Trim()
    }
    catch {
        $pythonVersion = $null
    }
}

$documentationCoverage = [ordered]@{
    Prerequisites = Test-Path -Path (Join-Path $repoRoot 'docs\getting-started\prerequisites.md')
    IdentityAndSecretsPrep = Test-Path -Path (Join-Path $repoRoot 'docs\getting-started\identity-and-secrets-prep.md')
    DeploymentGuide = Test-Path -Path (Join-Path $repoRoot 'docs\getting-started\deployment-guide.md')
    OperationalHandbook = Test-Path -Path (Join-Path $repoRoot 'docs\operational-handbook.md')
    OperationalRaci = Test-Path -Path (Join-Path $repoRoot 'docs\operational-raci.md')
    OperationalCadence = Test-Path -Path (Join-Path $repoRoot 'docs\operational-cadence.md')
    EscalationProcedures = Test-Path -Path (Join-Path $repoRoot 'docs\escalation-procedures.md')
    DocumentationVsRunnableGuide = Test-Path -Path (Join-Path $repoRoot 'docs\documentation-vs-runnable-assets-guide.md')
    DeliveryChecklistTemplate = Test-Path -Path (Join-Path $repoRoot 'DELIVERY-CHECKLIST-TEMPLATE.md')
}

$missingDocumentation = foreach ($entry in $documentationCoverage.GetEnumerator()) {
    if (-not $entry.Value) {
        $entry.Key
    }
}

$results = [ordered]@{
    RepositoryRoot = $repoRoot
    PowerShellVersion = $PSVersionTable.PSVersion.ToString()
    PowerShellSupported = $PSVersionTable.PSVersion.Major -ge 7
    PythonVersion = $pythonVersion
    HasPython = [bool](Get-Command python -ErrorAction SilentlyContinue)
    HasDocsConfig = Test-Path -Path (Join-Path $repoRoot 'mkdocs.yml')
    HasSolutionCatalog = Test-Path -Path (Join-Path $repoRoot 'data\solution-catalog.json')
    HasEvidenceSchema = Test-Path -Path (Join-Path $repoRoot 'data\evidence-schema.json')
    DocumentationCoverage = [pscustomobject]$documentationCoverage
    MissingDocumentation = @($missingDocumentation)
    DocumentationHandoffReady = @($missingDocumentation).Count -eq 0
    RecommendedReviewOrder = @(
        'docs\getting-started\prerequisites.md',
        'docs\getting-started\identity-and-secrets-prep.md',
        'DEPLOYMENT-GUIDE.md',
        'docs\operational-handbook.md',
        'DELIVERY-CHECKLIST-TEMPLATE.md'
    )
    ValidationCommands = @(
        'python scripts/build-docs.py',
        'python scripts/validate-contracts.py',
        'python scripts/validate-solutions.py',
        'python scripts/validate-documentation.py'
    )
    DocumentationFirstBoundary = 'Repository content is documentation, templates, scripts, and evidence guidance. Secrets and tenant-specific runtime assets stay outside source control.'
    NextActions = @(
        'Confirm named owners for platform, identity, compliance, operations, and change management.',
        'Record where secrets, certificates, and connection references are stored outside the repository.',
        'Review deployment wave order and approved change windows before production execution.',
        'Use DELIVERY-CHECKLIST-TEMPLATE.md to record preflight gaps and handoff decisions.'
    )
}

[pscustomobject]$results
