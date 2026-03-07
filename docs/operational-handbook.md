# Operational Handbook

This handbook provides the operator-facing handoff layer for the repository while preserving its documentation-first charter.

## How to Use This Handbook

Use this document when:

- preparing for first-time adoption of the repository,
- handing a solution wave from implementation to steady-state operations, or
- confirming that non-production validation is complete before production execution.

## Operating Model at a Glance

1. Confirm the repository boundary with the [Documentation vs Runnable Assets Guide](./documentation-vs-runnable-assets-guide.md).
2. Complete [Identity and Secrets Prep](./getting-started/identity-and-secrets-prep.md).
3. Assign named owners in the [Operational RACI](./operational-raci.md).
4. Set review windows in the [Operational Cadence](./operational-cadence.md).
5. Publish the support path in [Escalation Procedures](./escalation-procedures.md).
6. Record the final decisions in `DELIVERY-CHECKLIST-TEMPLATE.md` or the solution-specific delivery checklist.

## Phase-Based Handoff Plan

| Phase | Objective | Required inputs | Exit criteria |
| --- | --- | --- | --- |
| Repository preflight | Confirm the repo can be adopted safely in the target tenant | Prerequisites, identity and secrets prep, documentation boundary review | Owners are named, secrets stay external, and preflight gaps are documented |
| Non-production validation | Prove the intended wave order and scripts work in a lower environment | Deployment guide, tier decision, solution-specific docs, approved test tenant | Validation outputs and operator notes are attached to the handoff package |
| Production wave rollout | Execute an approved deployment sequence with a rollback path | Change window, accountable owner, escalation contacts, evidence destination | Production execution is signed off and any manual tasks are tracked |
| Steady-state operations | Run monitoring, evidence export, and runbook upkeep on a recurring basis | Operational cadence, escalation procedures, retained evidence location | Cadence owners accept support responsibility and open issues are triaged |

## Minimum Preflight Checklist

- [ ] Review `docs\getting-started\prerequisites.md`.
- [ ] Review `docs\getting-started\identity-and-secrets-prep.md`.
- [ ] Review `docs\documentation-vs-runnable-assets-guide.md`.
- [ ] Run `pwsh -File scripts\deployment\Validate-Prerequisites.ps1`.
- [ ] Confirm the deployment wave order in `DEPLOYMENT-GUIDE.md`.
- [ ] Confirm the accountable owner, operator, and escalation path before production execution.

## Handoff Package Contents

The implementation team should provide the receiving operator or service team with:

- the relevant solution README and solution docs,
- the selected governance tier and environment notes,
- the latest delivery checklist,
- the latest deployment manifest, WhatIf output, or change record,
- the latest evidence package location and validation output, and
- the open-risks or manual-follow-up log.

## Decision Rules

- Documentation is the approval source of truth; scripts are executed only after tenant-specific review and sign-off.
- Templates are starting points and may require local adaptation before use in a regulated tenant.
- Secrets, certificates, connection references, and exported runtime assets remain outside this repository.
- If documentation, configuration, and observed behavior diverge, pause the next deployment wave until the discrepancy is resolved and recorded.
