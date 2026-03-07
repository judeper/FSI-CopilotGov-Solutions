# Evidence Export

## Evidence package overview

`Export-Evidence.ps1` creates a package aligned to `data\evidence-schema.json`. The package references three solution-specific artifacts and writes a `.sha256` companion for each JSON file.

## Artifact details

| Artifact | File | Description |
|----------|------|-------------|
| `dlp-policy-baseline` | `dlp-policy-baseline.json` | JSON snapshot of all Copilot-scoped DLP policies or baseline expectations by workload |
| `policy-drift-findings` | `policy-drift-findings.json` | Array of policy changes detected since the baseline, including added, removed, or modified settings |
| `exception-attestations` | `exception-attestations.json` | Array of approved exceptions with attestor, approval date, justification, and expiry metadata |

## Baseline artifact contents

The baseline snapshot should document:

- Selected governance tier
- In-scope Copilot workloads
- Policy mode expectations for standard and high-sensitivity content
- Label-specific handling for NPI and PII when required
- Included and excluded user groups
- Evidence retention and notification settings

## Drift findings contents

Each drift finding should include enough detail for review and escalation:

- Control ID
- Change type such as added, removed, or modified
- Severity
- Baseline value and current value
- Detection timestamp
- Reviewer-facing message

## Exception attestation contents

Each approved exception record should capture:

- Exception identifier
- Policy or workload reference
- Attestor name or role
- Approval date
- Justification
- Expiry date
- Senior sign-off details when the regulated tier requires it

## Hashing and integrity

`Export-Evidence.ps1` writes SHA-256 companion files for:

- `dlp-policy-baseline.json`
- `policy-drift-findings.json`
- `exception-attestations.json`
- `05-dlp-policy-governance-evidence.json`

Hash files use the standard `<hash>  <filename>` format to simplify external validation.
