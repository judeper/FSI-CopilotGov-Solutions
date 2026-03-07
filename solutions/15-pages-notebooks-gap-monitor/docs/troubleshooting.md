# Troubleshooting

## Gap Discovery Returns No Results

**Possible causes**
- The account running the script does not have the required permissions.
- Copilot Pages, Loop, or notebook features are not enabled in the tenant.
- The current deployment tier is set to baseline and no tenant identifiers were provided for an authenticated check.

**Recommended actions**
- Confirm the operator has Compliance Administrator, SharePoint Administrator, and eDiscovery Admin access as needed.
- Verify that Copilot Pages or Microsoft Loop are enabled in the tenant.
- Re-run the monitoring script with the expected tenant context and confirm the output path is writable.

## Retention Policy Not Applying to Copilot Pages

**Possible causes**
- The Page is stored in a Loop-backed workspace that does not inherit the expected retention behavior at creation time.
- The tenant retention policy has not propagated yet.
- The underlying SharePoint location is not the one assumed by the records team.

**Recommended actions**
- Treat the condition as an open gap until verified.
- Use the compensating control log to document manual export and supervisory review procedures.
- Record the issue in the preservation exception register if books-and-records impact exists.
- Monitor Microsoft release notes for changes to Copilot Pages or Loop retention support.

## eDiscovery Search Missing Loop Content

**Possible causes**
- Loop workspace content is not yet surfaced consistently for the search workflow being used.
- The case scope does not include the correct site or workspace location.
- Legal hold procedures were designed around Exchange or Teams content and did not account for Loop-backed content.

**Recommended actions**
- Confirm the tenant configuration and case scope with the eDiscovery team.
- Use manual exports and case-file documentation while native coverage is under review.
- Update the gap status only after the tenant has been retested against the new platform behavior.

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
- Copilot Pages is the user-facing collaboration experience.
- Microsoft Loop provides the fluid content and workspace model used by many Pages scenarios.
- A tenant may show different retention or eDiscovery behavior depending on whether the content is evaluated as a Page, a Loop component, or a SharePoint-backed artifact.

**Recommended actions**
- Document the exact storage and discovery path being assessed.
- Avoid assuming that Exchange, Teams, and Loop content share identical compliance boundaries.
- Keep the gap register updated whenever Microsoft changes the underlying workload behavior.
