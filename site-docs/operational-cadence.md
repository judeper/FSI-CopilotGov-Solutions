# Operational Cadence

Use this cadence to keep deployment notes, evidence exports, and support expectations current after the initial handoff.

## Recurring Cadence

| Frequency | Activity | Primary owner | Expected outputs |
| --- | --- | --- | --- |
| Before each change window | Review prerequisites, identity status, secret expiry, and pending manual tasks | Platform Owner with Identity Administrator | Updated delivery checklist and go or hold decision |
| Weekly | Review open incidents, failed monitoring runs, and documentation drift | Solution Operator with Service Desk or Operations | Issue triage notes and updated support queue |
| Monthly | Run the approved monitoring and evidence-export cycle for in-scope solutions | Solution Operator | Monitoring output, evidence package, and retained hashes |
| Quarterly | Review the RACI, escalation path, evidence location, and secret-rotation ownership | Platform Owner with Security and Compliance Lead | Refreshed operator runbook and ownership confirmation |
| After any incident or major change | Capture lessons learned and update the handoff package | Platform Owner with Solution Operator | Updated checklist, escalation notes, and follow-up actions |

## Operational Signals to Watch

- Failed or delayed monitoring jobs
- Expiring secrets or certificates
- Change windows that were approved without a matching checklist or owner
- Evidence packages missing expected artifacts or hashes
- Documentation drift between the agreed process and the script behavior observed in the tenant

## Minimum Outputs Per Cycle

- the latest deployment or monitoring result,
- the location of the latest evidence package,
- open exceptions or manual work items,
- the current accountable owner and escalation contact, and
- any documentation updates required before the next wave or audit period.
