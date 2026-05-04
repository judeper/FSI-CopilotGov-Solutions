# Architecture

## Overview

Sensitivity Label Coverage Auditor is a monitoring-first solution that measures how much Copilot-accessible content is protected by sensitivity labels. It focuses on three workloads that commonly hold regulated FSI data: SharePoint, OneDrive, and Exchange. The solution collects label coverage data, identifies unlabeled gaps, ranks remediation candidates, and packages evidence for audit and control review.

## Text-Based Component Diagram

```text
+-------------------------------+
| config\default-config.json    |
| config\baseline.json          |
| config\recommended.json       |
| config\regulated.json         |
+---------------+---------------+
                |
                v
+-------------------------------------------+
| scripts\Deploy-Solution.ps1               |
| - loads tier config                       |
| - snapshots label taxonomy                |
| - validates upstream dependencies         |
+----------------------+--------------------+
                       |
                       v
+-------------------------------------------+
| scripts\Monitor-Compliance.ps1            |
| - queries workload coverage sources       |
| - calculates coverage metrics             |
| - cross-references oversharing findings   |
| - produces gap findings and manifest      |
+-----------+---------------+---------------+
            |               | 
            |               +-----------------------------+
            |                                             |
            v                                             v
+--------------------+      +--------------------+   +--------------------+
| SharePoint files   |      | OneDrive files     |   | Exchange evidence   |
| Graph drive action |      | Graph drive action |   | Purview export      |
| label assignments  |      | label assignments  |   | headers/properties  |
+--------------------+      +--------------------+   +--------------------+
            \                    |                     /
             \                   |                    /
              +------------------+-------------------+
                                 |
                                 v
+-----------------------------------------------------+
| Coverage calculator and gap analyzer                |
| - labeled count                                     |
| - unlabeled count                                   |
| - coverage percent                                  |
| - distribution by label tier                        |
| - remediation priority score                        |
+----------------------+------------------------------+
                       |
                       v
+-------------------------------------------+
| scripts\Export-Evidence.ps1               |
| - label-coverage-report                   |
| - label-gap-findings                      |
| - remediation-manifest                    |
| - evidence package and SHA-256 files      |
+----------------------+--------------------+
                       |
                       v
+-------------------------------------------+
| Power Automate flows (documentation-first)|
| - LabelGapAlert                           |
| - RemediationManifestApproval             |
+-------------------------------------------+
```

## Data Flow

1. `scripts\Deploy-Solution.ps1` loads the selected governance tier, records a snapshot of the configured label taxonomy, and confirms upstream dependencies are available.
2. `scripts\Monitor-Compliance.ps1` is designed to query approved coverage sources for:
   - SharePoint and OneDrive drive items through `driveItem: extractSensitivityLabels`, using returned `sensitivityLabelAssignment` values for supported file types and documenting locked, encrypted, or unsupported files as limitations
   - Exchange message labeling evidence from a tenant-approved Purview audit/activity export, documented Internet message headers, or documented extended-property collection pattern because Microsoft Graph message resources do not expose a first-class sensitivity-label field
   - Sensitivity label definitions needed for tier mapping through Microsoft Graph beta `/security/informationProtection/sensitivityLabels`, with beta change-management caveats
3. The coverage calculator converts raw counts into workload metrics:
   - labeled count
   - unlabeled count
   - coverage percent
   - distribution by label tier
4. The gap analyzer identifies unlabeled sites, drives, and mailboxes and calculates remediation priority.
5. The remediation manifest generator ranks corrective actions and suggests the next label based on workload sensitivity and risk score.
6. `scripts\Export-Evidence.ps1` packages the coverage report, gap findings, and remediation manifest into evidence outputs with SHA-256 companions.
7. Documented Power Automate flow designs describe how to notify stakeholders and route remediation for review after tenant approval.

## Workloads

### SharePoint

- Primary focus for regulated team sites, records repositories, policy libraries, and collaboration sites used by supervised functions.
- Coverage collection centers on site drives and document libraries where unlabeled files remain available to Copilot grounding.

### OneDrive

- Used for personal working files that may contain customer data, financial analysis, or draft materials before they move to governed repositories.
- Coverage review highlights business users with large unlabeled stores or repeated exceptions in priority business units.

### Exchange

- Used for regulated correspondence, customer communications, supervisory review, and evidence collection.
- Coverage assessment focuses on mailboxes where sensitivity labels support classification, retention review, and downstream recordkeeping controls.

## Label Coverage Metrics

The solution calculates the following metrics for each workload and for the overall tenant scope:

- **Labeled count:** number of items with an assigned sensitivity label.
- **Unlabeled count:** number of items with no recognized sensitivity label.
- **Coverage percent:** `(labeled count / total items) * 100`.
- **Distribution by label tier:** counts grouped into the FSI taxonomy from Tier 1 Public through Tier 5 Restricted.

These metrics are summarized in `label-coverage-report` so control owners can compare current performance to target thresholds.

## Gap Prioritization

Remediation priority is calculated with a simple, explainable formula:

```text
site risk score * unlabeled percent = remediation priority score
```

Interpretation guidance:

- Higher site or mailbox risk scores should be assigned to regulated repositories, customer data stores, supervisory mailboxes, or trading-related locations.
- Priority sites listed in configuration are automatically escalated to HIGH priority when unlabeled content is present.
- Oversharing findings from solution 02 can raise priority even when raw unlabeled percentages are similar.

## Power Automate Flows

### LabelGapAlert

- Triggered by newly exported gap findings or a below-threshold coverage result.
- Sends summary notifications to compliance operations, records management, and workload owners.
- Includes workload, container, unlabeled count, remediation priority, and evidence links.

### RemediationManifestApproval

- Triggered when a new remediation manifest is generated for a regulated or recommended deployment.
- Routes the manifest to data owners and governance reviewers for approval before bulk labeling begins.
- Captures reviewer name, approval date, and rollout wave references for audit support.

Both flows are documentation-first in this version. The design is intentionally separated from deployment so organizations can implement tenant-approved approval logic and notification destinations.

## Integration with Other Solutions

### Integration with 01-copilot-readiness-scanner

- Uses readiness outputs to confirm workload scope and determine which business units are in the initial Copilot rollout.
- Helps avoid scanning non-approved repositories before governance scope is finalized.

### Integration with 02-oversharing-risk-assessment

- Cross-references oversharing findings to raise the priority of unlabeled sites, drives, and mailboxes that already present elevated exposure risk.
- Aligns remediation planning so unlabeled content in high-risk areas is handled before lower-risk general collaboration areas.

## Operational Notes

- Auto-labeling policies alone may not clear the backlog in large tenants because of the 100,000 file per day processing limit.
- `assignSensitivityLabel` should be reserved for approved bulk remediation scenarios after business-owner review.
- Regulated-tier deployments should store exported evidence in immutable or otherwise protected repositories aligned to the organization's recordkeeping model.
