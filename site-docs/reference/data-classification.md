# Data Classification Matrix

This page documents per-solution data classification, residency, and retention metadata for
the 23 governance solution scaffolds in this repository. The values are conservative
documentation-first defaults sourced from each solution's `config/regulated.json` and
solution catalog metadata; production deployments must reclassify evidence per the firm's
data taxonomy.

> ⚠️ **Documentation-first repository.** Scripts use representative sample data and do not
> connect to live Microsoft 365 services. The classifications below describe what each
> solution's evidence and sample-output artifacts touch, not what a production deployment
> would necessarily process.

## How to read this matrix

- **Data classes processed** — categories of data the solution's evidence and sample
  outputs touch. Drawn from `{public, internal, confidential, restricted, regulated-pii,
  regulated-financial}`.
- **Residency options** — Microsoft 365 cloud instances where the solution's documented
  pattern can run. Drawn from `{commercial, gcc, gcc-high, dod, eu-data-boundary}`. Most
  scaffolds list `commercial` only; sovereign and EU Data Boundary residency requires
  additional tenant validation that is out of scope for the documentation-first scaffolds.
- **Retention default (days)** — sample evidence retention for the default tier; cited from
  `config/regulated.json` where present.
- **Retention max (days)** — longest tier's evidence retention; FINRA-aligned solutions use
  2555 days to support compliance with FINRA Rule 4511 and SEC Rule 17a-4 records guidance.
- **Notes** — caveats and reclassification reminders.

The machine-readable source for this page is
[`data/data-classification.json`](https://github.com/judeper/FSI-CopilotGov-Solutions/blob/main/data/data-classification.json),
validated against
[`data/data-classification.schema.json`](https://github.com/judeper/FSI-CopilotGov-Solutions/blob/main/data/data-classification.schema.json)
by `python scripts/validate_data_classification.py`.

## Matrix

| Slug | Data classes processed | Residency options | Retention default (days) | Retention max (days) | Notes |
|------|------------------------|-------------------|--------------------------|----------------------|-------|
| 01-copilot-readiness-scanner | internal, confidential | commercial | 2555 | 2555 | Sample readiness scores only; production deployments must classify findings per the firm's data taxonomy. |
| 02-oversharing-risk-assessment | internal, confidential, restricted | commercial | 2555 | 2555 | Permission and oversharing findings reference SharePoint and OneDrive scope; reclassify item-level evidence per firm policy. |
| 03-sensitivity-label-auditor | internal, confidential | commercial | 2555 | 2555 | Operates on label taxonomy metadata; sample data only and not a substitute for live Purview review. |
| 04-finra-supervision-workflow | confidential, restricted, regulated-financial, regulated-pii | commercial | 2555 | 2555 | Supervision evidence supports compliance with FINRA Rule 4511 and SEC Rule 17a-4 records retention; sample data only. |
| 05-dlp-policy-governance | confidential, restricted, regulated-pii | commercial | 365 | 365 | Documents DLP policy posture using sample match data; production exports may include sensitive identifiers and require firm-defined classification. |
| 06-audit-trail-manager | confidential, restricted, regulated-financial | commercial | 365 | 2555 | Default tier retains audit summaries for one year; regulated tier extends retention to align with FINRA Rule 4511 and SEC Rule 17a-4 expectations. |
| 07-conditional-access-automation | internal, confidential | commercial | 365 | 365 | Captures Conditional Access policy posture metadata only; sign-in user data is not exported by the scaffold. |
| 08-license-governance-roi | internal, confidential | commercial | 365 | 365 | Sample license assignment and usage indicators only; production deployments may include user identifiers requiring reclassification. |
| 09-feature-management-controller | internal, confidential | commercial | 365 | 365 | Feature toggle inventory and tier mappings only; no end-user content is processed by the scaffold. |
| 10-connector-plugin-governance | internal, confidential | commercial | 365 | 365 | Connector and plugin inventory metadata only; live connector telemetry is not collected by the scaffold. |
| 11-risk-tiered-rollout | internal, confidential | commercial | 365 | 365 | Wave cohort and approval evidence only; sample data and not a substitute for production change-management records. |
| 12-regulatory-compliance-dashboard | internal, confidential, regulated-financial | commercial | 365 | 365 | Aggregates representative control evidence into dashboard feeds; production aggregation must apply the firm's data taxonomy. |
| 13-dora-resilience-monitor | internal, confidential, regulated-financial | commercial, eu-data-boundary | 1825 | 1825 | Supports compliance with DORA operational resilience evidence retention; EU Data Boundary residency is recommended where the firm operates in the EU. |
| 14-communication-compliance-config | confidential, restricted, regulated-financial, regulated-pii | commercial | 2555 | 2555 | Communication review configuration only; the regulated tier does not pin `evidenceRetentionDays`, so the default reflects FINRA Rule 4511 and SEC Rule 17a-4 records guidance. |
| 15-pages-notebooks-gap-monitor | confidential, restricted | commercial | 2555 | 2555 | Operates on Pages and Notebooks metadata; production deployments may surface end-user content snippets that require reclassification. |
| 16-item-level-oversharing-scanner | confidential, restricted | commercial | 2555 | 2555 | Item-level permission findings only; production scans may reference filenames or paths and must be reclassified per firm policy. |
| 17-sharepoint-permissions-drift | internal, confidential, restricted | commercial | 2555 | 2555 | Permission baseline and drift indicators only; sample data and not a substitute for live SharePoint Advanced Management reviews. |
| 18-entra-access-reviews | internal, confidential, regulated-pii | commercial | 2555 | 2555 | Sample access review attestations may reference user identifiers; production deployments must classify reviewer evidence per firm policy. |
| 19-copilot-tuning-governance | confidential, restricted, regulated-financial | commercial | 2555 | 2555 | Tuning configuration and approval evidence only; production tuning datasets may include sensitive content requiring reclassification. |
| 20-generative-ai-model-governance-monitor | internal, confidential, restricted | commercial | 2555 | 2555 | Model inventory and monitoring telemetry only; sample data helps meet OCC 2011-12 and Interagency AI Guidance evidence patterns. |
| 21-cross-tenant-agent-federation-auditor | internal, confidential, restricted | commercial | 1825 | 1825 | Cross-tenant federation audit metadata only; production exports may reference partner tenant identifiers and require reclassification. |
| 22-pages-notebooks-retention-tracker | confidential, restricted | commercial | 2555 | 2555 | Retention coverage indicators for Pages and Notebooks; supports compliance with SEC Rule 17a-4 records retention expectations. |
| 23-copilot-studio-lifecycle-tracker | internal, confidential, restricted | commercial | 2555 | 2555 | Agent lifecycle and version metadata only; production deployments may include agent training data that requires reclassification. |

## Reclassification guidance

Treat every entry above as a starting point. Before any production rollout:

1. Map each evidence artifact to the firm's information classification scheme.
2. Confirm tenant residency (commercial, GCC, GCC High, DoD, or EU Data Boundary) supports
   the workloads referenced by the solution.
3. Align retention with the firm's records retention schedule and the relevant regulator's
   expectations (for example, FINRA Rule 4511 and SEC Rule 17a-4 for broker-dealers).
4. Capture any deviations from this matrix in the solution's `config/regulated.json` and
   re-run `python scripts/validate_data_classification.py`.
