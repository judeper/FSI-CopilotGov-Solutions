# Architecture

## Purpose

Solution 16 provides a documentation-first pattern for detecting item-level oversharing within SharePoint document libraries that Microsoft 365 Copilot could surface during grounded responses. While solution 02 operates at the site and workspace level, solution 16 drills into individual files and folders to identify permissions that are broader than intended.

## Text-Based Component Diagram

```text
+-----------------------------------------------+
| 02-oversharing-risk-assessment output         |
| - site-level oversharing findings             |
| - high-risk sites identified                  |
| - remediation queue                           |
+--------------------------+--------------------+
                           |
                           v
+---------------------------------------------------------------+
| Deploy-Solution.ps1                                            |
| - loads default + tier config                                  |
| - validates upstream dependency output                         |
| - records deployment manifest                                  |
+--------------------------+------------------------------------+
                           |
                           v
+---------------------------------------------------------------+
| Get-ItemLevelPermissions.ps1                                   |
| - connects via PnP PowerShell                                  |
| - enumerates document libraries per site                       |
| - retrieves per-item permission entries                        |
| - flags overshared items (anyone links, org links,             |
|   external users, broad groups)                                |
| - outputs flat CSV with item details                           |
+--------------------------+------------------------------------+
                           |
                           v
+---------------------------------------------------------------+
| Export-OversharedItems.ps1                                      |
| - reads item permissions CSV                                   |
| - applies FSI risk scoring (HIGH/MEDIUM/LOW)                   |
| - applies content-type risk weighting from                     |
|   config/risk-thresholds.json                                  |
| - outputs risk-scored report CSV + summary JSON                |
+-----------+----------------------+----------------------------+
            |                      |
            v                      v
+-----------------------+   +-----------------------+
| risk-scored-report    |   | summary JSON          |
| - item details        |   | - counts by risk tier |
| - risk tier + score   |   | - weighted scores     |
| - share type          |   | - content categories  |
+-----------+-----------+   +-----------------------+
            |
            v
+---------------------------------------------------------------+
| Invoke-BulkRemediation.ps1                                     |
| - reads risk-scored report                                     |
| - HIGH items: writes to pending-approvals.json                 |
| - MEDIUM/LOW: follows remediation-policy.json                  |
| - actions: remove link, remove external user,                  |
|   downgrade org link Edit → View                               |
| - logs all actions to evidence file                            |
+--------------------------+------------------------------------+
                           |
                           v
+---------------------------------------------------------------+
| Export-Evidence.ps1                                             |
| - item-oversharing-findings                                    |
| - risk-scored-report                                           |
| - remediation-actions                                          |
| - JSON + SHA-256 outputs                                       |
+---------------------------------------------------------------+
```

## Core Data Flow

1. `Deploy-Solution.ps1` loads `default-config.json` and the selected governance tier.
2. The deployment process checks that solution 02-oversharing-risk-assessment has exported site-level findings that can guide item-level scanning scope.
3. `Get-ItemLevelPermissions.ps1` connects to SharePoint via PnP PowerShell and enumerates all document libraries in each target site. For each item (file or folder), it retrieves permission entries and flags those that indicate oversharing.
4. The scan produces a flat CSV with one row per overshared item, including the site URL, library name, item path, share type, sensitivity label, and last modified date.
5. `Export-OversharedItems.ps1` reads the scan CSV and applies risk scoring based on sharing type and sensitivity label. Content-type weights from `config/risk-thresholds.json` are applied to produce a final weighted score.
6. Items are classified as HIGH (anyone links, external users with sensitive labels), MEDIUM (org-wide edit links, external users without sensitive labels), or LOW (broad group access without sensitive labels).
7. `Invoke-BulkRemediation.ps1` reads the scored report and applies remediation actions. HIGH items always require approval. MEDIUM and LOW items follow the policy defined in `config/remediation-policy.json`.
8. `Export-Evidence.ps1` packages scan results, scored reports, and remediation actions into schema-aligned JSON plus SHA-256 checksum files.

## Risk Classification Engine

The classification engine assigns a base risk score based on sharing type, then applies content-type weighting multipliers.

| Share Type | Base Score | Risk Interpretation |
|------------|-----------|---------------------|
| AnyoneLink | 90 | Always HIGH — anonymous access to any content is the highest risk |
| ExternalUser | 70 | HIGH when combined with sensitive label; MEDIUM otherwise |
| OrgLinkEdit | 50 | MEDIUM — organization-wide edit access exceeds least-privilege |
| BroadGroup | 30 | LOW — broad internal groups such as "Everyone" or "All Company" |

Content-type weighting multipliers:

| Content Category | Weight | Keywords |
|------------------|--------|----------|
| Customer PII | 1.5x | SSN, account number, customer, KYC |
| Trading Data | 1.5x | MNPI, trade, position, portfolio |
| Legal Documents | 1.3x | legal, litigation, privileged, contract |
| Regulatory Filing | 1.4x | SEC, FINRA, FFIEC, examination |

## Remediation Policy

| Risk Tier | Default Mode | Behavior |
|-----------|-------------|----------|
| HIGH | `approval-gate` | Always writes to `pending-approvals.json`; does not act without approval |
| MEDIUM | `approval-gate` | Follows `config/remediation-policy.json` setting |
| LOW | `approval-gate` | Follows `config/remediation-policy.json` setting |

Auto-remediation is intentionally disabled by default because FSI content typically requires legal, compliance, and records-management review before permissions are changed.

## Integration with 02-oversharing-risk-assessment

Solution 02 provides the site-level context used to focus solution 16 on the most relevant document libraries. Typical integration points include:

- Using site-level findings to prioritize which sites warrant item-level scanning
- Comparing site-level risk tiers against item-level findings to validate or escalate risk assessments
- Using solution 02 remediation queue data to coordinate item-level and site-level cleanup waves
