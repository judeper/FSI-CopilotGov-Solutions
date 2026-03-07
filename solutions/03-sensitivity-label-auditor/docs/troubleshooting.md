# Troubleshooting

## Error: Graph API permission denied for label enumeration

**Cause**

The account or app registration does not have the approved Graph permissions required to read sensitivity label policy or workload metadata.

**Resolution**

- Confirm `InformationProtectionPolicy.Read`, `Sites.Read.All`, `Files.Read.All`, and `Mail.Read` are approved where needed.
- Re-consent the app or reauthenticate the operator session after permission changes.
- Validate that the selected account can read the target workload and Purview label definitions.

## Error: `assignSensitivityLabel` returns 403

**Cause**

The tenant, workload, or calling identity does not meet the required licensing or permission prerequisites for bulk label application.

**Resolution**

- Confirm Microsoft Purview Information Protection licensing is assigned to the relevant users or service identity.
- Confirm the calling identity is approved for the intended bulk labeling action.
- Keep the solution in monitor-only mode until licensing and approval are complete.

## Error: Exchange label coverage incomplete

**Cause**

Exchange message label metadata may not be consistently exposed through the chosen collection method, especially where the Microsoft Information Protection client or equivalent processing is not uniformly deployed.

**Resolution**

- Validate the mailbox sampling approach before relying on Exchange percentages.
- Confirm message label metadata is available for the chosen pilot population.
- Document any Exchange coverage limitations in the evidence package notes.

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
- Regulated tier scans can take several hours for large tenants, especially when high-volume SharePoint and Exchange repositories are both in scope.
- Review priority sites regularly so new regulated repositories are not treated like general collaboration space.
