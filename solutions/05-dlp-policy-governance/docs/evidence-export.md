# Evidence Export

## Evidence package overview

`Export-Evidence.ps1` creates a package aligned to `data\evidence-schema.json`. The package references three solution-specific artifacts and writes a `.sha256` companion for each JSON file.

## Artifact details

| Artifact | File | Description |
|----------|------|-------------|
| `dlp-policy-baseline` | `dlp-policy-baseline.json` | JSON snapshot of Microsoft 365 Copilot and Copilot Chat policy-location settings plus separate complementary workload DLP baseline records when applicable |
| `policy-drift-findings` | `policy-drift-findings.json` | Array of policy changes detected since the baseline, including added, removed, or modified settings |
| `exception-attestations` | `exception-attestations.json` | Array of approved exceptions with attestor, approval date, justification, and expiry metadata |

## Baseline artifact contents

The baseline snapshot should document:

- Selected governance tier
- Microsoft 365 Copilot and Copilot Chat policy-location capabilities and availability status
- Separate complementary workload DLP locations when tenant policy design tracks them
- Policy mode expectations for standard and high-sensitivity content
- Label-specific handling for NPI and PII when required
- Included and excluded user groups
- Evidence retention and notification settings

## Product-boundary verification evidence

For a separately authorized tenant review, retain a sanitized companion review record alongside the package; these observations are not automatically produced or checked by the local scripts:

- Source URL and verification date, observed capability availability, and policy mode; distinguish preview prompt blocking from generally available web-search and label-based restrictions.
- Custom-template Copilot location, separate complementary workload policies, no administrative-unit scope, and separate SIT and sensitivity-label rules.
- The selected action and expected outcome: web-search-only restriction permits internal grounding; prompt processing restriction blocks a response; label-based blocking can retain citations while excluding content.
- Supported file type and email sent-date boundary (on or after January 1, 2025); calendar invites and direct prompt-uploaded file contents are not positive coverage cases.
- If enforcement testing is separately approved, record policy-update time and file reopen state before evaluating a result; propagation can take up to four hours.

Use [Microsoft's Copilot DLP guidance](https://learn.microsoft.com/purview/dlp-microsoft365-copilot-location-learn-about) as the product reference. Use synthetic content and redact tenant identifiers and PII. Local baseline comparisons and file hashes alone are not proof of tenant enforcement; preserve the existing evidence schema and artifact identifiers.

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
- Policy-location or complementary workload reference
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
