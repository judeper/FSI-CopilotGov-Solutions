# Prerequisites

## Microsoft Purview Requirements

- Microsoft Purview Communication Compliance must be enabled for the tenant.
- Microsoft Purview Suite (formerly Microsoft 365 E5 Compliance), Office 365 E5, or Office 365 E3 with the Advanced Compliance add-on should cover users governed by Communication Compliance policies.
- Retention and audit logging dependencies should be reviewed so supervised content remains available for reviewer workflows.
- Detecting Microsoft 365 Copilot interactions (Microsoft 365 Copilot and Microsoft 365 Copilot Chat across experiences such as Teams and Outlook) has no pay-as-you-go billing requirement and is covered by the licenses above. Detecting non-Microsoft 365 AI data — connected, enterprise, or other AI applications such as Copilot in Microsoft Fabric, Microsoft Security Copilot, or Microsoft Copilot Studio — requires pay-as-you-go billing to be enabled for the tenant.

## Required Roles

Communication Compliance uses six role groups. Assign the least-privileged role group that covers each responsibility:

- **Configure policies:** `Communication Compliance` or `Communication Compliance Admins` role group. The Microsoft Entra ID `Global Administrator` or `Compliance Administrator` roles and the Microsoft Purview portal `Organization Management` or `Compliance Administrator` role groups carry the same policy-configuration permissions.
- **Investigate alerts and cases:** `Communication Compliance`, `Communication Compliance Analysts`, or `Communication Compliance Investigators` role group. Reviewers must also be assigned as reviewers in the specific policy they investigate.
- **Read-only review support:** `Communication Compliance Viewers` role group for least-privileged, read-only access to the solution.

Keep at least one user in the `Communication Compliance` or `Communication Compliance Admins` role group to avoid a zero-administrator scenario. After role-group changes, permissions can take up to 30 minutes to apply to assigned users across the organization.

Additional tenant-specific roles may be required if the customer uses delegated administration, administrative units, or centralized security operations.

## Reviewer Requirements

Reviewers should be assigned to the `Communication Compliance Analysts` or `Communication Compliance Investigators` role groups, be assigned as reviewers in the specific policy they need to investigate, and have the appropriate security clearance to review employee and customer communications. Supervisors and legal reviewers should be assigned according to documented segregation-of-duty requirements.

## PowerShell and API Surface

Communication Compliance policies can also be created and read through Security & Compliance PowerShell (connect with `Connect-IPPSSession`) using the `New-SupervisoryReviewPolicyV2`, `Get-SupervisoryReviewPolicyV2`, `New-SupervisoryReviewRule`, `Get-SupervisoryReviewRule`, and `Set-SupervisoryReviewRule` cmdlets. These cmdlets configure the policy name, reviewers, sampling (review) percentage (`-SamplingRate`), and keyword or sensitive-information-type conditions. They do not expose the Microsoft 365 Copilot detection location or its trainable classifiers (for example, Prompt Shields and Protected material), so Copilot-scoped detection is configured in the Microsoft Purview portal. The `-WhatIf` switch is not honored in Security & Compliance PowerShell.

Reviewer queue metrics do not have a supported Microsoft Graph or Purview API for automated collection; this solution documents the manual-export pattern and does not depend on an automated API path. If the customer later extends queue metrics collection, plan for permissions equivalent to compliance data read access and application registration governance.

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
