# Troubleshooting

## Agent inventory returning incomplete results

**Symptoms**

- Expected agents are missing from `alg-agent-registry.json`
- User-created Copilot Studio agents do not appear in the exported manifest
- IT-developed agents are missing from the inventory output

**Common causes**

- The M365 Admin Center agent management features are not yet enabled for the tenant
- The Copilot Studio admin account lacks access to the target environment
- User-created agents are in personal scope and have not been shared or published to the org catalog
- The agent was created in a different Copilot Studio environment

**Resolution**

1. Confirm that M365 Admin Center agent management is enabled and the admin account has appropriate access.
2. Validate Copilot Studio admin permissions for the target environment.
3. Review Copilot Studio agent sharing settings to confirm whether user-created agents are visible in the admin catalog.
4. Compare agent results to the Copilot Studio admin center to identify missing agent records.

## Approval flow notifications not sending

**Symptoms**

- `ALG-ApprovalRouter` creates requests but reviewers do not receive tasks
- Teams or email notifications do not appear for new agent findings
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

## Dataverse duplicate agent entries

**Symptoms**

- The same agent appears multiple times in `fsi_cg_alg_baseline`
- Findings reopen for agents that were already reviewed
- Evidence records do not line up with a single baseline record

**Common causes**

- No alternate key on `agentId`
- Agent IDs were normalized differently between PowerShell and Power Automate
- Manual imports added duplicate rows before key enforcement was enabled

**Resolution**

1. Create or validate an alternate key on `agentId` in `fsi_cg_alg_baseline`.
2. Normalize agent IDs before import and use the same casing across scripts and flows.
3. Merge duplicate Dataverse rows, then rerun the initial inventory to confirm the baseline is stable.
4. Update the import mapping so findings link to the surviving baseline record.

## Risk classification disagreements

**Symptoms**

- Security reviewers disagree with the assigned Microsoft-published, IT-developed, user-created, or blocked result
- IT-developed agents are being treated as user-created
- Microsoft-published agents are flagged for approval when business teams expected auto-approval

**Common causes**

- The selected tier does not match the expected operating model
- The agent publisher type metadata is incomplete or incorrect
- The agent risk category configuration needs refinement
- Manual exception handling was not recorded after the initial review

**Resolution**

1. Review the active tier JSON file and confirm the intended approval model.
2. Validate the agent's `publisherType` value and whether it was correctly classified during inventory.
3. Update agent risk categories or approved agent IDs where policy allows.
4. Record any approved exception in the approval register.

## Sharing policy audit showing unexpected drift

**Symptoms**

- Sharing policy audit flags org-wide sharing as non-compliant when it was previously approved
- External sharing settings appear to have changed without a governance record
- Catalog visibility controls do not match the expected configuration

**Common causes**

- An admin changed Copilot Studio sharing settings outside the governance workflow
- The governance tier was updated without rerunning the sharing policy audit
- Tenant-level Copilot Studio admin settings were modified by a different admin role

**Resolution**

1. Review the current Copilot Studio admin center sharing policy settings.
2. Compare current settings to the expected values in the selected tier configuration.
3. Document any approved policy changes in the sharing policy audit evidence.
4. Rerun `Monitor-Compliance.ps1` to update the compliance status after policy changes are documented.

## DORA third-party register integration gaps

**Symptoms**

- Approved agents with third-party dependencies are visible in ALG but missing from the enterprise DORA register
- Audit requests require manual cross-checking between Dataverse and the third-party register
- Monitoring shows approved agents without a linked vendor review record

**Common causes**

- The DORA register uses a different vendor identifier than the agent inventory
- The export process was not mapped to the enterprise third-party risk workflow
- Manual reconciliation responsibilities were not assigned after approval

**Resolution**

1. Export `agent-registry` and `approval-register` after each review cycle.
2. Map agent publishers and dependencies to the enterprise vendor ID used by the DORA register.
3. Assign an owner to reconcile newly approved agent deployments on a scheduled basis.
4. Track unresolved reconciliation gaps as findings until the DORA register is updated.
