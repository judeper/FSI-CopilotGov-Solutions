# Troubleshooting

## Connector enumeration returning incomplete results

**Symptoms**

- Expected connectors are missing from `cpg-connector-inventory.json`
- Custom connectors appear in Power Platform but not in the exported manifest
- Graph connector or plugin related app registrations are missing from review output

**Common causes**

- The script was pointed at the wrong Power Platform environment ID
- The Power Platform Administrator account lacks access to the target environment
- Microsoft Graph inventory permissions were not approved for the reviewer or service principal
- Custom connectors were created in a different environment or solution layer

**Resolution**

1. Confirm the `-Environment` parameter value and rerun `Deploy-Solution.ps1`.
2. Validate Power Platform Admin API permissions for the target admin account.
3. Review environment specific custom connectors and ensure they were published.
4. Compare connector results to Microsoft Graph app registration inventory for missing plugin dependencies.

## Approval flow notifications not sending

**Symptoms**

- `CPG-ApprovalRouter` creates requests but reviewers do not receive tasks
- Teams or email notifications do not appear for new connector findings
- Approval items remain in a submitted state without reviewer activity

**Common causes**

- The approver mailbox or distribution group is incorrect
- Connection references in Power Automate are expired or not shared with the flow owner
- Teams app policy blocks the notification channel or reviewer access
- The reviewer account does not have Power Automate Premium licensing

**Resolution**

1. Confirm the `-ApproverEmail` value used during deployment.
2. Reauthenticate flow connection references and rerun the trigger.
3. Validate Teams policy, mailbox routing, and reviewer licensing.
4. Review the flow run history to confirm whether the failure is notification related or approval action related.

## Dataverse duplicate connector entries

**Symptoms**

- The same connector appears multiple times in `fsi_cg_cpg_baseline`
- Findings reopen for connectors that were already reviewed
- Evidence records do not line up with a single baseline record

**Common causes**

- No alternate key on `connectorId`
- Connector IDs were normalized differently between PowerShell and Power Automate
- Manual imports added duplicate rows before key enforcement was enabled

**Resolution**

1. Create or validate an alternate key on `connectorId` in `fsi_cg_cpg_baseline`.
2. Normalize connector IDs before import and use the same casing across scripts and flows.
3. Merge duplicate Dataverse rows, then rerun the initial inventory to confirm the baseline is stable.
4. Update the import mapping so findings link to the surviving baseline record.

## Risk classification disagreements

**Symptoms**

- Security reviewers disagree with the assigned low, medium, high, or blocked result
- Certified third-party connectors are being treated as high risk
- Microsoft-built connectors are flagged for approval when business teams expected auto-approval

**Common causes**

- The selected tier does not match the expected operating model
- The connector crosses a regulated financial data boundary that requires a stricter treatment
- The blocked connector list or publisher classification needs refinement
- Manual exception handling was not recorded after the initial review

**Resolution**

1. Review the active tier JSON file and confirm the intended approval model.
2. Validate the connector's `dataFlowBoundaries` value and whether it reaches regulated systems.
3. Update blocked connector IDs or approved Microsoft-built connector IDs where policy allows.
4. Record any approved exception in the approval register and corresponding data-flow attestation.

## DORA third-party risk register integration gaps

**Symptoms**

- Approved third-party connectors are visible in CPG but missing from the enterprise DORA register
- Audit requests require manual cross-checking between Dataverse and the third-party register
- Monitoring shows approved integrations without a linked vendor review record

**Common causes**

- The DORA register uses a different vendor identifier than the connector inventory
- The export process was not mapped to the enterprise third-party risk workflow
- Manual reconciliation responsibilities were not assigned after approval

**Resolution**

1. Export `connector-inventory` and `approval-register` after each review cycle.
2. Map connector publishers to the enterprise vendor ID used by the DORA register.
3. Assign an owner to reconcile newly approved third-party integrations on a scheduled basis.
4. Track unresolved reconciliation gaps as findings until the DORA register is updated.
