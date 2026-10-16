# Troubleshooting

## Error: Graph API permission denied for label enumeration

**Cause**

The account or app registration does not have the approved Graph permissions required to read sensitivity label policy or workload metadata.

**Resolution**

| Scenario | Required permission | Notes |
|----------|---------------------|-------|
| Delegated label enumeration | `InformationProtectionPolicy.Read` | Reads labels available to the signed-in user through Microsoft Graph beta. |
| Application label enumeration | `InformationProtectionPolicy.Read.All` | Required for app-only organization label enumeration through Microsoft Graph beta. |
| SharePoint and OneDrive label extraction | `Files.Read.All` | Least-privileged permission for `driveItem: extractSensitivityLabels`. |
| Exchange labeling evidence | `Mail.Read` or approved Purview export access | Use only with a documented tenant source because Graph messages do not include a first-class sensitivity-label field. |

- Re-consent the app or reauthenticate the operator session after permission changes.
- Validate that the selected account can read the target workload and Purview label definitions.
- Confirm beta API use for `/security/informationProtection/sensitivityLabels` is approved by tenant change governance.
- Check the route as well as consent: delegated lookup uses `/me/security/informationProtection/sensitivityLabels`; the organization route `/security/informationProtection/sensitivityLabels` requires application permissions. [Microsoft documents these APIs as beta and unsupported in production applications](https://learn.microsoft.com/graph/api/security-informationprotection-list-sensitivitylabels?view=graph-rest-beta).

## Error: `assignSensitivityLabel` returns 403

**Cause**

The tenant, workload, or calling identity does not meet the required licensing, protected API validation, cloud availability, or permission prerequisites for bulk label application.

**Resolution**

- Confirm feature-specific licensing, required base service plans, and benefiting-user coverage against `prerequisites.md` and the [Microsoft Purview service description](https://learn.microsoft.com/office365/servicedescriptions/microsoft-365-service-descriptions/microsoft-365-tenantlevel-services-licensing-guidance/microsoft-purview-service-description); do not infer service-side automatic-labeling entitlement from manual-labeling access.
- Confirm protected API validation is complete for the SharePoint and OneDrive `assignSensitivityLabel` API before attempting bulk assignment. Note that `assignSensitivityLabel` is a metered Graph API; metered APIs must be enabled and charges may apply for bulk usage.
- Confirm the calling identity has the least-privileged `Files.ReadWrite.All` permission, or `Sites.ReadWrite.All` only when the tenant-approved design requires the broader permission.
- Confirm the target cloud is supported for the API; Microsoft Learn documents the API as available in the Global service. Verify current API availability on Microsoft Learn before attempting bulk assignment.
- Handle the `202 Accepted` long-running operation response and monitor the `Location` URL until the assignment finishes.
- Check file limitations, including unsupported file types, locked files, double-key encrypted files, and encrypted files that SharePoint cannot open for label processing.
- Keep the solution in monitor-only mode until licensing, protected API validation, and approval are complete.

## Error: Exchange label coverage incomplete

**Cause**

Exchange message label metadata may not be consistently exposed through the chosen collection method, especially where the Microsoft Purview Information Protection client or equivalent processing is not uniformly deployed.

**Resolution**

- Validate the mailbox sampling approach before relying on Exchange percentages.
- Confirm message label metadata is available for the chosen pilot population.
- Document any Exchange coverage limitations in the evidence package notes.
- Microsoft Graph messages have no documented first-class Purview sensitivity-label field. For an approved header-based collector, `internetMessageHeaders` requires `$select`; the documented [MIP email metadata](https://learn.microsoft.com/information-protection/develop/concept-mip-metadata) uses `MSIP_Labels`. Validate source completeness before treating missing metadata as label absence; legacy Outlook sensitivity values are not Purview label IDs.

## Error: Large tenant scan timeouts

**Cause**

The tenant contains more items than can be scanned within the current run window or API throttle envelope.

**Resolution**

- Run `Monitor-Compliance.ps1` with `-MaxItemsPerWorkload` to constrain the first pass.
- Break scanning into workload-specific runs and compare results over time.
- Review Graph throttling and adjust scheduling to reduce peak-time contention.

## Error: Label taxonomy changed between scans

**Cause**

The Purview label set was updated after the baseline scan, so coverage trend comparisons no longer reflect the same taxonomy snapshot.

**Resolution**

- Re-run `Deploy-Solution.ps1` to capture a fresh taxonomy snapshot.
- Flag the affected reporting period as a taxonomy transition in the audit notes.
- Compare only like-for-like label sets when generating trend narratives.

## Tips

- Run with `-WorkloadsToAudit sharePoint` first before adding Exchange when tuning the first deployment.
- Live-collector duration depends on supported content, API throttling, and scope; the sample scripts do not establish tenant scan duration.
- When planning auto-labeling waves, use the dedicated article's currently documented 500,000-files-per-tenant daily ceiling while recording the conflicting 100,000 statement in the SharePoint/OneDrive PDF guidance. See `deployment-guide.md`; no throughput is established by sample runs.
- Review priority sites regularly so new regulated repositories are not treated like general collaboration space.
