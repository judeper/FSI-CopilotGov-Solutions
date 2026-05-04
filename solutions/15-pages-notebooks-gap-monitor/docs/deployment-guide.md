# Deployment Guide

## Overview

This guide walks through the deployment sequence for Copilot Pages and Notebooks Compliance Gap Monitor. The goal is to establish a documented baseline of supported-but-validate items and documented limitations, assign compensating controls, and export evidence that supports compliance review. The solution is documentation-led and depends on `06-audit-trail-manager` for audit and retention baseline context.

## Prerequisites

- Review [prerequisites](./prerequisites.md).
- Confirm `06-audit-trail-manager` is deployed and baseline retention evidence has been reviewed.
- Select the governance tier to use for the tenant: `baseline`, `recommended`, or `regulated`.
- Identify compliance, legal, records management, and Microsoft Purview eDiscovery reviewers.

## Step 1: Run gap discovery to baseline current state

Run the monitoring script with the baseline tier to create an initial gap snapshot.

```powershell
pwsh -File .\scripts\Monitor-Compliance.ps1 -ConfigurationTier baseline -OutputPath .\artifacts\baseline -PassThru
```

Review the output for supported-but-validate items and documented limitations related to Pages and Notebooks retention policy scope, Purview eDiscovery review-set search, SharePoint Embedded legal hold, retention labels, Information Barriers, notebook preservation verification, and sharing controls.

## Step 2: Review discovered items and classify severity

Review the generated monitoring output with compliance and legal stakeholders. Confirm that each discovered item has:

- the correct affected capability
- the correct regulation mapping
- an owner
- a severity rating of high, medium, or low
- a clear statement of whether a Microsoft platform update is required or tenant validation is sufficient

## Step 3: Assign compensating controls to each open item

For every open limitation or validation item, assign the control that will reduce risk while the item remains open. Typical controls include:

- retention policy scope validation and manual export when scope cannot be demonstrated
- restricted sharing and site membership review
- enhanced audit logging through `06-audit-trail-manager`
- quarterly notebook storage, retention label, and export validation
- legal-hold container inclusion review for SharePoint Embedded content

Document the owner, approval date, and review due date for each compensating control.

## Step 4: Get legal and compliance sign-off on preservation exceptions

Where a documented limitation or validation item has books-and-records impact, prepare a preservation exception entry for review. Legal and compliance reviewers should confirm:

- the exception rationale
- the regulation affected
- the interim control in place
- the expiry date and review cadence
- the escalation path if the documented limitation or validation item remains open

## Step 5: Run Deploy-Solution.ps1 to initialize the gap register

After the review meeting, initialize the tier-aware deployment manifest and gap register.

```powershell
pwsh -File .\scripts\Deploy-Solution.ps1 -ConfigurationTier recommended -OutputPath .\artifacts\deployment
```

Use the `regulated` tier when preservation exception tracking and legal sign-off must be captured as part of deployment readiness.

## Step 6: Configure Power Automate flow for ongoing gap monitoring

Configure the documentation-first Power Automate flow or equivalent review workflow to support:

- scheduled quarterly reassessment reminders
- approval routing for preservation exceptions
- assignment of gap owners and reviewers
- follow-up review when Microsoft publishes relevant Message Center updates

Connection references and environment variables should follow the shared naming contract for this solution.

## Step 7: Export initial evidence package

Export the three primary evidence artifacts and the package manifest.

```powershell
pwsh -File .\scripts\Export-Evidence.ps1 -ConfigurationTier regulated -OutputPath .\artifacts\evidence -PassThru
```

Validate that the output includes:

- `gap-findings`
- `compensating-control-log`
- `preservation-exception-register`
- the combined evidence package JSON
- the companion SHA-256 hash file

## Step 8: Schedule quarterly review cycle

Add the solution to the compliance calendar with a recurring quarterly review. The review should cover:

- new Pages, Loop, or notebook capabilities enabled in the tenant
- any Microsoft release notes or Message Center posts that may change an open limitation or validation requirement
- the current status of compensating controls
- the approval state of preservation exceptions
- any changes required to the evidence narrative for internal audit or examiner discussions

## Operational Notes

- This solution supports compliance with regulatory review expectations by documenting limitations, validation items, and manual controls.
- It does not automatically change retention policies, legal holds, or Microsoft Purview eDiscovery scope.
- Human review remains mandatory before any item is marked mitigated or closed.
