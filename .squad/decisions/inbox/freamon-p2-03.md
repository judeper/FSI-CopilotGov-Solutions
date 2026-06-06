# Freamon Pass-2 Re-Verification — Solution 03: Sensitivity Label Coverage Auditor

**Date:** 2026-06-05 | **Pass:** 2 (second-opinion re-check) | **Model:** claude-opus-4.7

## Findings

| File:line | Current text | Issue | Correct per MS Learn | Citation URL | Severity |
|-----------|-------------|-------|---------------------|-------------|----------|
| `README.md` line 150 / `docs/architecture.md` line 162 | "Service-side auto-labeling can now override existing lower-priority labels on files (previously only emails). Remediation manifests should account for this capability." | The parenthetical "(previously only emails)" is not supported by current MS Learn documentation. The auto-labeling policy comparison table shows "Replace manually applied label that has lower priority: Yes (configurable)" with no "email only" restriction — meaning this capability is not (and apparently has not been) restricted to emails only in service-side auto-labeling policies. Two other features in the same table do carry "(email only)" qualifiers but this one does not. The "previously only emails" historical claim cannot be verified from current MS Learn. | MS Learn auto-labeling policy comparison table shows "Replace manually applied label that has lower priority" as "Yes (configurable)" for service-side auto-labeling policies with no email-only restriction. The current behavior (override applies to files) is correct; only the historical parenthetical is unsupported. | https://learn.microsoft.com/en-us/purview/apply-sensitivity-label-automatically | minor |

---

## Spot-Check Citations Confirmed (claims that remain accurate)

| Claim verified | File | Current text | MS Learn verdict | Citation URL |
|----------------|------|-------------|-----------------|-------------|
| Auto-labeling policy 100,000 file/tenant/day processing cap | `README.md` line 17 / `docs/architecture.md` line 162 | "the daily 100,000 file per tenant processing cap" | ✅ Confirmed. MS Learn: "Maximum of 100,000 automatically labeled files in your tenant per day." | https://learn.microsoft.com/en-us/purview/apply-sensitivity-label-automatically |
| `assignSensitivityLabel` is a protected and metered API available only in Global service; least-privileged permission is `Files.ReadWrite.All` | `README.md` lines 146-147 | "protected and metered SharePoint and OneDrive Microsoft Graph API for files at rest; approved bulk application scenarios require protected API validation beyond permission consent, metered API enablement (charges may apply)...use in the Global service" | ✅ Confirmed. MS Learn: "This API is part of the Microsoft SharePoint and OneDrive APIs that perform advanced premium administrative functions, and is considered as protected...This is a metered API and some charges for use may apply." Cloud table: Global ✅, L4 ❌, L5 ❌, China ❌. Permissions: Delegated/Application least-privileged = `Files.ReadWrite.All`. | https://learn.microsoft.com/en-us/graph/api/driveitem-assignsensitivitylabel |
| `GET /security/informationProtection/sensitivityLabels` is a beta-only endpoint; uses `InformationProtectionPolicy.Read` (delegated) and `InformationProtectionPolicy.Read.All` (application) | `docs/prerequisites.md` line 31-32 / `docs/architecture.md` line 79 | "Organization label definition enumeration currently uses Microsoft Graph beta `/security/informationProtection/sensitivityLabels`" | ✅ Confirmed. MS Learn page explicitly states beta-only (`/beta/...`); permissions table: Delegated = `InformationProtectionPolicy.Read`, Application = `InformationProtectionPolicy.Read.All`. | https://learn.microsoft.com/en-us/graph/api/security-informationprotection-list-sensitivitylabels |
| Label group migration from parent labels is irreversible; triggered by Purview portal banner | `README.md` line 149 | "Microsoft is replacing parent labels with label groups. Migration is irreversible; automatic migration applies only in documented cases, and other tenants should migrate when the Microsoft Purview portal banner is available." | ✅ Confirmed. MS Learn: "Label migration is irreversible." Automatic migration for new tenants from October 1, 2025 or when no new sublabel will be created; others migrate via portal information banner. | https://learn.microsoft.com/purview/migrate-sensitivity-label-scheme |

---

## Remediation recommendation

The finding above is **minor** and requires no immediate correction to prevent misuse — the current behavior (override works for files) is correctly stated, and the historical parenthetical does not affect remediation-manifest guidance. However, to eliminate an unverifiable claim, consider removing or softening the parenthetical:

> **Suggested edit (README.md line 150 and architecture.md line 162):**  
> Change: "Service-side auto-labeling can now override existing lower-priority labels on files (previously only emails)."  
> To: "Service-side auto-labeling policies can be configured to override existing lower-priority manually applied labels on files."
