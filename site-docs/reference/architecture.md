# Repository Architecture

The repository is organized around four layers:

1. `data/` stores machine-readable control, framework, and solution metadata.
2. `scripts/common/` stores reusable PowerShell modules for authentication, evidence export, Dataverse naming, and notifications.
3. `solutions/` stores the solution-specific docs, scripts, configs, and tests.
4. `templates/` stores starter policy, dashboard, and regulatory mapping artifacts.

A documentation build step assembles `site-docs/` from root docs and solution READMEs before MkDocs publication.

## Layer Details

### Data Layer (`data/`)

Machine-readable JSON files that define the shared contract for controls, frameworks, solutions, and evidence schemas. These files are validated by `scripts/validate-contracts.py` and must not be modified without deliberate validation.

### Shared Modules Layer (`scripts/common/`)

Seven PowerShell modules provide reusable functions across all 18 solutions:

| Module | Purpose | Implementation Scope |
|--------|---------|---------------------|
| GraphAuth.psm1 | Graph context placeholder | Returns metadata only; no actual authentication |
| EvidenceExport.psm1 | Evidence packaging and SHA-256 hashing | Functional; validates schema and hash integrity |
| IntegrationConfig.psm1 | Tier mapping, status scores, Dataverse naming | Functional; shared configuration contract |
| DataverseHelpers.psm1 | Dataverse table schema contracts | Schema contracts only; no CRUD operations |
| PurviewHelpers.psm1 | Purview assessment record structures | Record structures only; no Purview API calls |
| EntraHelpers.psm1 | Entra ID policy metadata helpers | Metadata only; no Entra ID API calls |
| TeamsNotification.psm1 | Teams MessageCard payload helpers | Payload generation only; no webhook calls |

All modules except EvidenceExport and IntegrationConfig are documentation-first stubs that return metadata structures without connecting to live services.

### Solutions Layer (`solutions/`)

Eighteen solution folders, each containing a consistent structure:

- `README.md` — Solution overview, features, scope boundaries, and regulatory alignment
- `CHANGELOG.md` — Version history
- `DELIVERY-CHECKLIST.md` — Pre-delivery validation and sign-off tracker
- `scripts/` — `Deploy-Solution.ps1`, `Monitor-Compliance.ps1`, `Export-Evidence.ps1`
- `config/` — `default-config.json`, `baseline.json`, `recommended.json`, `regulated.json`
- `docs/` — `architecture.md`, `deployment-guide.md`, `evidence-export.md`, `prerequisites.md`, `troubleshooting.md`
- `tests/` — Pester test file validating structure, syntax, configuration, and runtime honesty

### Templates Layer (`templates/`)

Starter policy templates, dashboard feed schemas, and regulatory mapping artifacts that customers adapt to their tenant configuration.
