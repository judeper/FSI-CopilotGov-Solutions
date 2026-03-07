# Escalation Procedures

Use this procedure to route preflight blockers, deployment issues, and steady-state operational incidents without relying on tribal knowledge.

## Severity Model

| Severity | Example trigger | Response expectation |
| --- | --- | --- |
| Sev 1 | Production deployment caused a critical outage or control failure with immediate business impact | Immediate operator engagement and executive notification |
| Sev 2 | High-risk control gap, failed production wave, or identity or secret issue that blocks regulated workloads | Same business day escalation to platform, identity, and compliance owners |
| Sev 3 | Non-production blocker, documentation gap, or evidence-package issue that does not yet affect production operations | Triage in the next operations cycle and assign remediation owner |
| Sev 4 | Improvement request or backlog item with no current service impact | Track in normal governance review |

## Escalation Path

| Trigger | Primary responder | Next escalation | Required artifacts |
| --- | --- | --- | --- |
| Preflight or deployment blocker | Solution Operator | Platform Owner and Change Manager | Delivery checklist, WhatIf output, recent configuration notes |
| Identity, access, or secret expiry issue | Identity Administrator | Platform Owner and Security and Compliance Lead | Identity record, expiry details, vault reference, affected scripts |
| Missing or invalid evidence package | Solution Operator | Security and Compliance Lead | Evidence package path, validation output, reporting period |
| Monitoring failure or recurring alert | Service Desk or Operations | Platform Owner | Monitoring log, last successful run, affected solution wave |
| Documentation drift or unclear operator ownership | Platform Owner | Executive Sponsor if production timing is at risk | Current handbook, checklist, and change record |

## Incident Packet

Capture the following before escalating beyond the primary responder:

- affected solution or deployment wave,
- selected governance tier and environment,
- recent change window or deployment manifest,
- the exact script, command, or document involved,
- error output or evidence-validation result, and
- current owner, escalation contact, and proposed hold or rollback action.

## Stop or Continue Rules

- Pause the next production wave when ownership, secret handling, or evidence retention is unclear.
- Treat a documentation or checklist gap as a release blocker until the runbook is updated and approved.
- Escalate to Microsoft, a managed services partner, or another vendor only after the internal owner can provide the incident packet without exposing secrets in the ticket.
