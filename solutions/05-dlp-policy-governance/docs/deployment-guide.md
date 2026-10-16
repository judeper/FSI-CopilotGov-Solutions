# Deployment Guide

## 1. Verify the dependency solution

1. Confirm `solutions\03-sensitivity-label-auditor` has completed its latest label review.
2. Validate that the NPI, PII, and high-sensitivity labels referenced by this solution are current.
3. Record the dependency review in the delivery checklist before continuing.

## 2. Prepare access and modules

Local scaffold generation does not require tenant connections. The following setup is for optional, separately implemented read-only collection; repository scripts do not collect live policies.

Run the following from PowerShell 7 if the modules are not already installed:

```powershell
Install-Module ExchangeOnlineManagement -Scope CurrentUser
Install-Module Microsoft.Graph -Scope CurrentUser
```

Connect to the required services with read permissions:

```powershell
Connect-IPPSSession
Connect-MgGraph -Scopes 'InformationProtectionPolicy.Read', 'Policy.Read.All'
```

`Connect-IPPSSession` supplies the Security & Compliance cmdlets; a separate Exchange Online session is not required for `Get-DlpCompliancePolicy` or `Get-DlpComplianceRule`. Graph is only for supporting label and Entra ID policy metadata, not DLP policy reads. The generated Exchange connection stub opens both sessions for convenience, not as a DLP requirement. See [Microsoft's connection guidance](https://learn.microsoft.com/powershell/exchange/connect-to-scc-powershell).

### Copilot policy review checkpoints

Review existing policies read-only in the [Microsoft Purview portal](https://purview.microsoft.com), under **Data Loss Prevention** > **Policies**. Do not create or modify policies as part of this review.

- Confirm the **Custom** template and **Microsoft 365 Copilot and Copilot Chat** location; other workload locations belong in separate policies. Administrative units are unsupported for the Copilot location.
- Review **Content contains** > **Sensitive information types** with **Prevent Copilot from processing content** > **Processing prompts** (preview) or **Performing Web Searches** (generally available). Only the former blocks a response; the latter still permits allowed internal grounding.
- Review **Content contains** > **Sensitivity labels** with **Prevent Copilot from processing content** in a separate rule from SIT conditions. Labeled items can remain in citations without contributing content.
- Record tenant availability rather than assuming preview rollout. Alerts, notifications, and simulation mode are supported; solution-defined `Audit` / `Block` values are governance expectations, not literal portal policy-mode names.
- For separately approved enforcement testing, allow up to four hours after policy updates and reopen Word, Excel, or PowerPoint files after mid-session label changes. Use synthetic content only; direct prompt-uploaded file contents are not evaluated by this location.

Source: [Copilot DLP capabilities and boundaries](https://learn.microsoft.com/purview/dlp-microsoft365-copilot-location-learn-about).

## 3. Create the baseline snapshot

From `solutions\05-dlp-policy-governance`, run:

```powershell
.\scripts\Deploy-Solution.ps1 `
    -ConfigurationTier recommended `
    -OutputPath .\artifacts `
    -BaselinePath .\artifacts\dlp-policy-baseline.json
```

Expected outputs:

- `artifacts\dlp-policy-baseline.json`
- `artifacts\deployment-manifest.json`
- `artifacts\connection-stubs\graph-connection.stub.ps1`
- `artifacts\connection-stubs\exchange-online-connection.stub.ps1`

## 4. Configure the Power Automate exception flow

The Approvals connector is standard; Premium is not required solely for approvals. Confirm licenses for any additional connectors and Dataverse database provisioning before deployment. See [approvals prerequisites and licensing](https://learn.microsoft.com/power-automate/get-started-approvals).

Use the documented flow design to create an exception approval process that:

1. Accepts requests for temporary DLP policy deviations.
2. Validates the request against the latest baseline and drift findings.
3. Routes approval to the correct role for the selected tier.
4. Writes approved exceptions to the structured attestation log.
5. Preserves approval date, attestor, justification, and expiry fields.

## 5. Schedule drift monitoring

Schedule `Monitor-Compliance.ps1` using the cadence defined by the chosen tier:

- Baseline: weekly
- Recommended: daily
- Regulated: real-time or near-real-time orchestration

Example command:

```powershell
.\scripts\Monitor-Compliance.ps1 `
    -ConfigurationTier recommended `
    -BaselinePath .\artifacts\dlp-policy-baseline.json `
    -OutputPath .\artifacts `
    -AlertOnDrift
```

## 6. Validate evidence export

Run the export command for the reporting period that needs review:

```powershell
.\scripts\Export-Evidence.ps1 `
    -ConfigurationTier recommended `
    -OutputPath .\artifacts `
    -PeriodStart 2026-01-01 `
    -PeriodEnd 2026-01-31
```

Confirm the following files exist after export:

- `artifacts\dlp-policy-baseline.json`
- `artifacts\policy-drift-findings.json`
- `artifacts\exception-attestations.json`
- `artifacts\05-dlp-policy-governance-evidence.json`
- SHA-256 companion files for each JSON artifact
