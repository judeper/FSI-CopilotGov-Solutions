# Deployment Guide

## 1. Verify the dependency solution

1. Confirm `solutions\03-sensitivity-label-auditor` has completed its latest label review.
2. Validate that the NPI, PII, and high-sensitivity labels referenced by this solution are current.
3. Record the dependency review in the delivery checklist before continuing.

## 2. Prepare access and modules

Run the following from PowerShell 7 if the modules are not already installed:

```powershell
Install-Module ExchangeOnlineManagement -Scope CurrentUser
Install-Module Microsoft.Graph -Scope CurrentUser
```

Connect to the required services with read permissions:

```powershell
Connect-ExchangeOnline -ShowBanner:$false
Connect-IPPSSession
Connect-MgGraph -Scopes 'InformationProtectionPolicy.Read', 'Policy.Read.All'
```

### Microsoft Purview portal reference

DLP policies for the Copilot policy location are created and reviewed in the [Microsoft Purview portal](https://purview.microsoft.com) under **Data Loss Prevention** > **Policies**. When configuring a policy for this location:

- The **Microsoft 365 Copilot and Copilot Chat** location is available only in the **Custom** policy template, and selecting it disables all other locations for that policy.
- Use a separate rule for the **Content contains > Sensitive information types** condition and for the **Content contains > Sensitivity labels** condition; Microsoft Purview does not allow both conditions in the same rule.
- Use **policy simulation mode** to validate a policy in detect-only form before enforcement; the enforceable state is **Turn the policy on immediately**.
- Policy updates can take up to four hours to reflect in the Microsoft 365 Copilot and Copilot Chat experience.
- Read-only policy metadata is available through Security & Compliance PowerShell (`Get-DlpCompliancePolicy`, `Get-DlpComplianceRule`).
- Preserve `EnforcementPlanes` and `Locations` in policy evidence so the operator can identify the `CopilotExperiences` enforcement plane or the Applications workload location; policy name and mode alone do not prove Copilot scope.

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

## 7. Lab validation handoff

The read-only lab validation contract at `lab\05-dlp-policy-governance.lab.json` defines the first validation cycle for this solution. That cycle is **detect-only**: it uses view-only DLP PowerShell access and read-only portal access to inspect current tenant DLP policy configuration, Copilot scope fields, simulation state, prerequisites, and cited Microsoft sources without creating or enforcing any policy (`mutations: []`). Use the contract to confirm currency of the Copilot DLP policy location claims (external web-search restriction and sensitivity-label blocking are generally available; sensitive-information-type prompt blocking and external-email exclusion are preview) before planning any enforcement change. Record honest `BLOCKED` or `NOT-APPLICABLE` dispositions when a preview feature, license, role, policy, or rollout is absent in the target tenant.
