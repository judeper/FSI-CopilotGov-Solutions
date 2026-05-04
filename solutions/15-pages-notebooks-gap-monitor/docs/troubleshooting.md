# Troubleshooting

## Gap Discovery Returns No Results

**Possible causes**
- The account running the script does not have the required permissions.
- Copilot Pages, Loop, or notebook features are not enabled in the tenant.
- The current deployment tier is set to baseline and no tenant identifiers were provided for an authenticated check.

**Recommended actions**
- Confirm the operator has Compliance Administrator, SharePoint Administrator, and Microsoft Purview eDiscovery Admin access as needed.
- Verify that Copilot Pages or Microsoft Loop are enabled in the tenant.
- Re-run the monitoring script with the expected tenant context and confirm the output path is writable.

## Retention Policy Not Applying to Copilot Pages or Notebooks

**Possible causes**
- The retention policy is not configured for All SharePoint Sites and does not include the relevant SharePoint Embedded container.
- The tenant retention policy has not propagated yet.
- The underlying user-owned SharePoint Embedded container is not the location assumed by the records team.
- A departed-user or legal-hold process did not add the required container before deletion or review.

**Recommended actions**
- Confirm the policy scope with Records Management and SharePoint administrators; current Microsoft guidance states Purview retention policies configured for All SharePoint Sites are enforced for Copilot Pages and Notebooks.
- Record the container URL, policy scope, and validation evidence before closing the item.
- Use the compensating control log to document manual export and supervisory review procedures if policy scope cannot be demonstrated.
- Record the issue in the preservation exception register if books-and-records impact exists.

## Microsoft Purview eDiscovery Search Missing Loop or Page Content

**Possible causes**
- The case scope does not include the correct SharePoint Embedded container, site, or workspace location.
- Full-text search within `.page` or `.loop` files in Purview review sets is not available.
- Review/export licensing or Premium case setup is not in place for the workflow being used.
- Legal hold procedures were designed around Exchange or Teams content and did not account for per-user SharePoint Embedded container inclusion.

**Recommended actions**
- Confirm the case scope, collection, review, and export settings with the Microsoft Purview eDiscovery team.
- Add the required SharePoint Embedded container URL manually for legal hold or case scope where applicable.
- Use supported export options and document the review-set full-text limitation if the investigation requires text search inside `.page` or `.loop` files.
- Update the gap status only after the tenant has been retested against the documented platform behavior.

## Compensating Control Not Accepted by Examiner

**Possible causes**
- The control description is too general and does not show who performed the action.
- No evidence of execution or supervisory approval was retained.
- The control review date is missing or overdue.

**Recommended actions**
- Add specific procedure references, owner names, approval records, and evidence locations.
- Attach supporting audit records from `06-audit-trail-manager` where available.
- Reclassify the control as incomplete if it cannot be demonstrated consistently.

## Preservation Exception Register Incomplete

**Possible causes**
- Required fields such as rationale, approver, or expiry date were not filled in.
- The legal approval chain was not defined before the exception was drafted.
- Review history entries were not updated after quarterly reassessment.

**Recommended actions**
- Confirm every exception record includes `exceptionId`, `gapId`, `regulation`, `exceptionRationale`, `approvedBy`, `approvalDate`, `expiryDate`, and `reviewHistory`.
- Obtain legal and compliance sign-off before treating the exception as active.
- Keep draft exceptions clearly labeled until approvals are complete.

## Microsoft Loop vs Copilot Pages distinction

**Clarification**
- Copilot Pages and Copilot Notebooks are independent of Loop, but they can use the same user-owned SharePoint Embedded container as Loop My workspace.
- Loop components, Loop workspaces, Copilot Pages, and Copilot Notebooks can have different admin policies, licensing requirements, and compliance limitations.
- A tenant may show different retention or Microsoft Purview eDiscovery behavior depending on whether the content is evaluated as a Page, a Notebook, a Loop component, or a SharePoint-backed artifact.

**Recommended actions**
- Document the exact storage and discovery path being assessed.
- Avoid assuming that Exchange, Teams, and Loop content share identical compliance boundaries.
- Keep the gap register updated whenever Microsoft changes the underlying workload behavior.
