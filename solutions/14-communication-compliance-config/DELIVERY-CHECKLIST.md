# Delivery Checklist

## Delivery Summary

- Solution: Microsoft Purview Communication Compliance Configurator (`14-communication-compliance-config`)
- Code: `CCC`
- Version: `v0.1.0`
- Track / Priority / Phase: `D / P1 / 3`
- Dependency: `04-finra-supervision-workflow`
- Evidence outputs: `policy-template-export`, `reviewer-queue-metrics`, `lexicon-update-log`

## Pre-Deployment

- [ ] Confirm Microsoft Purview Communication Compliance licensing is available for the target tenant.
- [ ] Confirm Microsoft 365 E5 Compliance or equivalent add-on requirements are met.
- [ ] Confirm reviewer assignments for Compliance, Supervision, and Legal are approved.
- [ ] Confirm supervised lexicon words were reviewed by Legal and Compliance.
- [ ] Confirm escalation mailbox or queue owner is documented.
- [ ] Confirm `04-finra-supervision-workflow` is deployed and operating procedures are available.

## Configuration Review

- [ ] Review `config\default-config.json` for solution metadata, reviewer defaults, and integration references.
- [ ] Review `config\baseline.json` for baseline policy templates, lexicon words, and sampling thresholds.
- [ ] Review `config\recommended.json` for escalation settings and insider risk correlation planning.
- [ ] Review `config\regulated.json` for FINRA 3110 supervision, SEC Reg BI, and FCA SYSC 10 options.
- [ ] Validate that communication compliance policies were tested in a non-production tenant before production deployment.

## Deployment Steps

1. Run `scripts\Deploy-Solution.ps1 -ConfigurationTier <baseline|recommended|regulated> -TenantId <tenant-guid> -WhatIf` to preview deployment artifacts.
2. Run `scripts\Deploy-Solution.ps1 -ConfigurationTier <baseline|recommended|regulated> -TenantId <tenant-guid>` to generate the final deployment manifest and policy templates.
3. Use the generated files under `artifacts\deployment\policy-templates\` to create or update policies in the Microsoft Purview compliance portal.
4. Configure reviewer assignments and escalation rules by using the workflow section in `artifacts\deployment\communication-compliance-config-deployment-manifest.json`.
5. Publish supervised lexicon keywords in Purview after Legal and Compliance approval.
6. Run `scripts\Monitor-Compliance.ps1 -ConfigurationTier <tier>` to capture baseline queue metrics and identify policy coverage gaps.
7. Run `scripts\Export-Evidence.ps1 -ConfigurationTier <tier>` to package required evidence outputs.

## Post-Deployment Validation

- [ ] Confirm expected Microsoft Purview Communication Compliance policies are active in the Microsoft Purview portal.
- [ ] Confirm reviewer queue access is available to assigned reviewers.
- [ ] Confirm escalation routing aligns to the supervision workflow dependency.
- [ ] Confirm queue age and overdue counts are within the selected SLA threshold.
- [ ] Confirm `scripts\Export-Evidence.ps1` completes successfully and writes a JSON evidence package plus SHA-256 hash.

## Evidence Review

- [ ] `policy-template-export` is present and reflects the deployed tier.
- [ ] `reviewer-queue-metrics` is present and includes current queue health fields.
- [ ] `lexicon-update-log` is present and lists approved keyword updates.
- [ ] Evidence package metadata contains the correct solution slug, solution code, tier, and export version.

## Customer Handover

- [ ] Compliance team is trained on the reviewer user interface and disposition process.
- [ ] Supervisors understand escalation triggers and SLA expectations.
- [ ] Legal and Compliance owners receive the lexicon governance process.
- [ ] Examination support contacts and evidence retrieval path are documented.
- [ ] Manual Purview portal steps are documented for future updates.

## Sign-off

- [ ] Solution Owner sign-off
- [ ] Compliance Lead sign-off
- [ ] Legal Reviewer sign-off
- [ ] Operations Lead sign-off
- [ ] Customer Acceptance sign-off
