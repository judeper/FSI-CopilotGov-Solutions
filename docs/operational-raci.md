# Operational RACI

Use this matrix to remove ambiguity about who approves, executes, and supports each adoption activity.

## Roles

- **Executive Sponsor** — approves scope, timing, and risk acceptance.
- **Platform Owner** — accountable for tenant-side deployment and steady-state ownership.
- **Solution Operator** — runs the repository scripts and records deployment results.
- **Identity Administrator** — provisions workload access, app registrations, certificates, and secret rotation.
- **Security and Compliance Lead** — reviews control impact, evidence handling, and exception tracking.
- **Service Desk or Operations** — receives incidents, monitors recurring jobs, and coordinates support.
- **Change Manager** — owns change windows, release approval, and rollback decisions.

## Matrix

| Activity | Executive Sponsor | Platform Owner | Solution Operator | Identity Administrator | Security and Compliance Lead | Service Desk or Operations | Change Manager |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Confirm repository scope and solution wave order | A | R | C | I | C | I | C |
| Approve operator identities, roles, and secret storage | I | A | C | R | C | I | I |
| Confirm documentation-first boundary and excluded runtime assets | I | A | R | C | C | I | I |
| Execute non-production validation | I | A | R | C | C | I | C |
| Approve production deployment window | C | A | R | I | C | I | R |
| Validate evidence package and retention location | I | A | R | I | R | C | I |
| Own recurring monitoring and operational cadence | I | A | R | C | C | R | I |
| Receive and escalate incidents | I | A | C | C | C | R | I |
| Maintain handoff notes, exceptions, and runbook updates | I | A | R | C | C | C | I |

## Minimum Ownership Standard

Do not begin production execution until each activity has one named accountable owner and one named operator or support contact.
