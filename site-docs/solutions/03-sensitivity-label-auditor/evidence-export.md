# Evidence Export

## Evidence Package Contract

Evidence is exported as a JSON package aligned to `..\..\data\evidence-schema.json`. Every JSON evidence file receives a companion `.sha256` file so audit teams can confirm integrity after transfer or retention.

Required top-level package fields:

- `metadata`
- `summary`
- `controls`
- `artifacts`

Required metadata fields:

- `solution`
- `solutionCode`
- `exportVersion`
- `exportedAt`
- `tier`

## Evidence Outputs

### `label-coverage-report`

Purpose:

- provides per-workload label coverage percentages
- records labeled count and unlabeled count
- shows distribution by label tier
- compares the current run to the previous retained run when trend data is available

Typical contents:

- tenant and tier metadata
- SharePoint, OneDrive, and Exchange coverage summaries
- overall coverage percentage
- trend versus previous run
- notes on any workload-specific collection assumptions

### `label-gap-findings`

Purpose:

- inventories unlabeled content by site, drive, or mailbox
- records the risk score for each container
- captures the derived remediation priority

Typical contents:

- workload
- container identifier
- unlabeled item count
- unlabeled percent
- risk score
- remediation priority score
- priority classification and supporting notes

### `remediation-manifest`

Purpose:

- provides a prioritized list of containers or items that should enter the next labeling wave
- suggests the likely target label based on risk posture
- supports review and approval before bulk labeling begins

Typical contents:

- manifest item identifier
- workload and container reference
- priority
- suggested label
- recommended action
- owner review notes

## Control Status Mapping

| Control | Status | Evidence interpretation |
|---------|--------|-------------------------|
| 1.5 | Partial | Taxonomy review is still a manual governance task, but the export proves what taxonomy snapshot and coverage state were reviewed. |
| 2.2 | Monitor-only | The export reports whether content is labeled and where classification gaps remain. |
| 3.11 | Partial | Coverage metrics and gap findings support records classification review in regulated repositories and mailboxes. |
| 3.12 | Monitor-only | Evidence packaging is automated, but formal attestation remains outside the script. |

## Retention Guidance

- Baseline tier typically supports short operational retention for remediation follow-up.
- Recommended tier should retain evidence long enough to support quarterly governance review.
- Regulated tier should retain classification evidence for seven years where required by the organization's books-and-records obligations.

For regulated deployments, SEC 17a-4 requires seven-year retention of records classification evidence, so teams should store exported packages and hash files in the approved evidence repository with immutability or equivalent protection where mandated.

## Evidence Immutability Limitations

The `regulated.json` configuration sets `immutableEvidenceStorage: true` and `requireExaminerReadyEvidence: true`, but `Export-Evidence.ps1` writes artifacts and their `.sha256` companion files to a standard writable directory. An actor with write access to the output path can modify evidence files and regenerate matching hashes without detection. The SHA-256 companion files verify transfer integrity but do not provide tamper evidence on their own.

To enforce true immutability for regulated deployments:

- Store exported evidence packages in WORM (Write Once Read Many) storage such as Azure Immutable Blob Storage or a compliant records management system.
- Apply cryptographic signing (e.g., code-signing certificates or detached PGP signatures) to evidence packages before archival so any post-export modification is detectable.
- Restrict write access to the evidence output directory using role-based access controls so only the export service identity can write new packages.

These measures are external to the solution and must be configured as part of the organization's evidence retention infrastructure.
