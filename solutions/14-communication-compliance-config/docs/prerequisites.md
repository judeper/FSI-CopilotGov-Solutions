# Prerequisites

## Microsoft Purview Requirements

- Microsoft Purview Communication Compliance must be enabled for the tenant.
- Microsoft Purview Suite (formerly Microsoft 365 E5 Compliance), Office 365 E5, or Office 365 E3 with the Advanced Compliance add-on should cover users governed by Communication Compliance policies.
- Retention and audit logging dependencies should be reviewed so supervised content remains available for reviewer workflows.

## Required Roles

Minimum roles for deployment and operations:

- `Communication Compliance Admins` role group for Communication Compliance administration
- Microsoft Entra ID `Compliance Administrator` role or Microsoft Purview portal `Compliance Administrator` role group, as appropriate
- `Communication Compliance Viewers` or Global Reader for reporting, audit, and validation support

Additional tenant-specific roles may be required if the customer uses delegated administration, administrative units, or centralized security operations.

## Reviewer Requirements

Reviewers should be assigned to the `Communication Compliance Analysts` or `Communication Compliance Investigators` role groups, be assigned as reviewers in the specific policy they need to investigate, and have the appropriate security clearance to review employee and customer communications. Supervisors and legal reviewers should be assigned according to documented segregation-of-duty requirements.

## API Permissions

If the customer plans to extend queue metrics collection through Microsoft Graph or a future Purview API, plan for permissions equivalent to compliance data read access and application registration governance. This solution version documents the integration pattern but does not depend on an automated API path.

## Dependencies

- `04-finra-supervision-workflow` must be deployed first.
- Shared modules under `scripts\common\` must remain available.
- Reviewer groups, escalation contacts, and legal approvers should exist before deployment.

## Legal and Compliance Sign-off

Lexicon words and policy templates should be approved by Legal and Compliance before deployment. Sign-off should cover:

- AI disclosure language
- promotional language terms
- best-interest and conflict-of-interest indicators
- escalation thresholds and dual-review criteria
