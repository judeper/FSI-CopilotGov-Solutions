# Troubleshooting

## Error: Graph API authentication failures

**Symptoms**

- `Connect-CopilotGovGraph` fails with authentication errors
- Token request returns 401 or 403 responses

**Actions**

- Confirm the correct TenantId, ClientId, and ClientSecret are being used
- Verify the app registration has the required Graph permissions (AccessReview.ReadWrite.All, Sites.Read.All)
- Confirm admin consent has been granted for the required permissions
- Check that conditional access policies do not block the execution host

## Error: AccessReview.ReadWrite.All permission not granted

**Symptoms**

- Access review creation returns 403 Forbidden
- GET requests to `/identityGovernance/accessReviews/definitions` fail

**Actions**

- Verify the app registration has `AccessReview.ReadWrite.All` application permission
- Confirm an authorized administrator has granted consent: Privileged Role Administrator for Microsoft Graph application permissions, or Cloud Application Administrator, AI Administrator, or Application Administrator where supported for delegated consent
- Check the app registration in Microsoft Entra ID for pending consent requests

## Error: Graph API throttling during bulk review creation

**Symptoms**

- Requests slow down sharply when creating reviews for many sites
- API calls return HTTP 429 responses

**Actions**

- Reduce the number of sites per batch
- Start with resources mapped to HIGH-risk sites before expanding to MEDIUM and LOW
- The shared `Invoke-CopilotGovGraphRequest` function includes retry and backoff handling
- Run bulk creation during a lower-usage window

## Error: Site owner resolution fails

**Symptoms**

- Reviewer assignment defaults to fallback (compliance-officer) for most sites
- SharePoint site properties do not return owner information

**Actions**

- Verify the operator has SharePoint Administrator rights
- Confirm Sites.Read.All permission is granted for the app registration
- Check that site ownership is assigned and current in SharePoint admin center
- Update site owner information before re-running review creation

## Error: Review decisions not returned

**Symptoms**

- `Get-ReviewResults.ps1` returns empty decision sets
- Active review instances show no pending or completed decisions

**Actions**

- Confirm the review definition ID and instance ID are valid
- Verify the review has not expired before decisions were submitted
- Check that reviewers have received notification and have access to the review portal
- Confirm the review scope includes the expected users and groups

## Error: Deny decision application fails

**Symptoms**

- `Apply-ReviewDecisions.ps1` reports errors when applying decisions
- Users retain access after deny decisions are recorded

**Actions**

- Verify the operator has sufficient permissions to apply decisions on the reviewed Microsoft Entra resource
- Confirm the review instance status allows decision application
- Check that the mapped group, access package, or site association has not been deleted or restructured since the review was created
- Review the error log for specific Graph API error details

## Tip: Start with a small pilot set

Run the first execution with a small number of resources mapped to HIGH-risk sites so reviewer assignment, notification delivery, and decision collection can be validated before scaling to hundreds of sites.

## Tip: Monitor review expiry proactively

Use `Get-ReviewResults.ps1` regularly to identify reviews approaching their expiry window. The default reminder threshold is 48 hours, which can be adjusted in `config/review-schedule.json` via the `reminderDays` setting.
