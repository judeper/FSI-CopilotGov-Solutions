# Evidence Export

## Overview

The Copilot Readiness Assessment Scanner exports operational evidence that can be retained for audit support, supervisory review, and Power BI reporting. All exported JSON files use a companion SHA-256 file so downstream teams can verify that evidence has not changed after publication.

## Evidence Types

| Evidence Type | Description | Typical Consumer |
|---------------|-------------|------------------|
| `readiness-scorecard` | Consolidated readiness summary with weighted score, domain roll-up, tier, and period metadata | Security leadership, platform owner, audit liaison |
| `data-hygiene-findings` | Detailed findings for data exposure, labeling, permission drift, and governance gaps | Compliance engineering, collaboration administrators |
| `remediation-plan` | Prioritized remediation actions, target owners, due dates, and status expectations | Program manager, control owner, service owner |

## Package Structure

The export process writes three artifact files and one package file to the selected output path.

```text
artifacts\
|-- CRS-readiness-scorecard-recommended-20260206-20260307.json
|-- CRS-readiness-scorecard-recommended-20260206-20260307.json.sha256
|-- CRS-data-hygiene-findings-recommended-20260206-20260307.json
|-- CRS-data-hygiene-findings-recommended-20260206-20260307.json.sha256
|-- CRS-remediation-plan-recommended-20260206-20260307.json
|-- CRS-remediation-plan-recommended-20260206-20260307.json.sha256
|-- CRS-evidence-package-recommended-20260206-20260307.json
`-- CRS-evidence-package-recommended-20260206-20260307.json.sha256
```

## How to Invoke `Export-Evidence.ps1`

```powershell
.\scripts\Export-Evidence.ps1 `
    -ConfigurationTier recommended `
    -TenantId 'contoso.onmicrosoft.com' `
    -OutputPath '.\artifacts' `
    -PeriodStart (Get-Date).AddDays(-30) `
    -PeriodEnd (Get-Date)
```

The script returns a summary object containing the package path, overall status, record counts, and artifact count.

## Output File Naming Convention

The solution uses the following convention:

- Artifact files: `CRS-<artifact-name>-<tier>-<periodStart>-<periodEnd>.json`
- Package file: `CRS-evidence-package-<tier>-<periodStart>-<periodEnd>.json`
- Date format: `yyyyMMdd`

This naming scheme keeps artifact type, governance tier, and reporting period visible in the filename for easier downstream processing.

## SHA-256 Companion File

Every JSON file is written with a matching `.sha256` file containing:

- the lowercase SHA-256 hash
- two spaces
- the file name

Example:

```text
2b43d9673f78f1d816146f4c77e6d2e4d7a4fe48f87b8d556b02bb66f0f45a44  CRS-readiness-scorecard-recommended-20260206-20260307.json
```

## Evidence Package Contract

The package file aligns to `../../data/evidence-schema.json` and includes:

- `metadata`
  - `solution`
  - `solutionCode`
  - `exportVersion`
  - `exportedAt`
  - `tier`
  - `periodStart`
  - `periodEnd`
- `summary`
  - `overallStatus`
  - `recordCount`
  - `findingCount`
  - `exceptionCount`
- `controls`
  - one entry per mapped control with `controlId`, `status`, and `notes`
- `artifacts`
  - one entry per evidence artifact with `name`, `type`, `path`, and `hash`

## Evidence Integrity Warning

> **Important:** The SHA-256 companion files provide tamper detection only when the hash values are stored or verified independently of the evidence artifacts. If both the artifact and its `.sha256` file reside in the same mutable directory, an actor with write access can modify both. For regulated-tier deployments (SEC 17a-4, FINRA 3110), store evidence in WORM-capable storage or use externally signed manifests. See [architecture.md](./architecture.md) for detailed guidance.

## Control Status Entries

The package includes entries for the following controls:

- 1.1 Copilot Readiness Assessment and Data Hygiene
- 1.5 Sensitivity Label Taxonomy Review
- 1.6 Permission Model Audit
- 1.7 SharePoint Advanced Management Readiness
- 1.9 License Planning and Copilot Assignment Strategy

Expected statuses use the shared contract values:

- `implemented`
- `partial`
- `monitor-only`
- `playbook-only`

For this solution, some controls remain `partial` or `monitor-only` because parts of the control response depend on human review, remediation approval, or customer-owned storage controls outside the scanner itself.
