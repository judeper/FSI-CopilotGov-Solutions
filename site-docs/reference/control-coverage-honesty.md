# Control Coverage Honesty Matrix

> This page communicates how far each control mapping is implemented in this repository. The repository is documentation-first; these states make the depth of each (solution, control) mapping explicit so reviewers can calibrate trust without inflating the claim surface.

## Coverage states

| State | Meaning |
|-------|---------|
| `documentation-only` | The solution README and supporting docs describe a pattern that helps meet the control. No script in `solutions/<id>/scripts/` exercises the control flow, even with sample data. |
| `scripted-sample` | A script under `solutions/<id>/scripts/` (typically `Monitor-Compliance.ps1` or a helper invoked from it) exercises the control flow against representative sample data. The output is illustrative, not an audit artifact. |
| `evidence-export-ready` | The solution's `Export-Evidence.ps1` (or a helper it delegates to) emits an evidence package whose `controls[]` entry references the control id, in a shape that conforms to `data/evidence-schema.json`. The data is still sample, but the format is directly usable for evidence handling. |

Conservative classification rules:

- A mapping is downgraded to `scripted-sample` if the control is referenced only in `Monitor-Compliance.ps1` or in the Pester tests, and not enumerated in the evidence package's `controls[]`.
- A mapping is downgraded to `documentation-only` if the control id does not appear in any script or test under the solution folder.
- When in doubt, the mapping is downgraded, never inflated.

Programmatic source of truth: `data/control-coverage.json` (`schemaVersion: 1.1.0`), where every entry in `solutions[]` has a corresponding `solution_coverage[].coverageState`.

## Per-solution matrix

### 01-copilot-readiness-scanner

| Control | Title | Coverage state |
|---------|-------|----------------|
| `1.1` | Copilot Readiness Assessment and Data Hygiene | 📦 evidence-export-ready |
| `1.5` | Sensitivity Label Taxonomy Review for Copilot | 📦 evidence-export-ready |
| `1.6` | Permission Model Audit (SharePoint, OneDrive, Exchange, Teams, Graph) | 📦 evidence-export-ready |
| `1.7` | SharePoint Advanced Management Readiness for Copilot | 📦 evidence-export-ready |
| `1.9` | License Planning and Copilot Assignment Strategy | 📦 evidence-export-ready |

### 02-oversharing-risk-assessment

| Control | Title | Coverage state |
|---------|-------|----------------|
| `1.2` | SharePoint Oversharing Detection and Remediation (DSPM for AI) | 📦 evidence-export-ready |
| `1.3` | Restricted SharePoint Search Configuration | 📦 evidence-export-ready |
| `1.4` | Semantic Index Governance and Scope Control | 📦 evidence-export-ready |
| `1.6` | Permission Model Audit (SharePoint, OneDrive, Exchange, Teams, Graph) | 📦 evidence-export-ready |
| `2.12` | External Sharing and Guest Access Governance | 📦 evidence-export-ready |
| `2.5` | Data Minimization and Grounding Scope | 📦 evidence-export-ready |
| `3.10` | SEC Reg S-P -- Privacy of Consumer Financial Information | 📄 documentation-only |

### 03-sensitivity-label-auditor

| Control | Title | Coverage state |
|---------|-------|----------------|
| `1.5` | Sensitivity Label Taxonomy Review for Copilot | 📦 evidence-export-ready |
| `2.2` | Sensitivity Labels and Copilot Content Classification | 📦 evidence-export-ready |
| `3.11` | Record Keeping and Books-and-Records Compliance (SEC 17a-3/4, FINRA 4511) | 📦 evidence-export-ready |
| `3.12` | Evidence Collection and Audit Attestation | 📦 evidence-export-ready |

### 04-finra-supervision-workflow

| Control | Title | Coverage state |
|---------|-------|----------------|
| `3.4` | Communication Compliance Monitoring | 📦 evidence-export-ready |
| `3.5` | FINRA Rule 2210 Compliance for Copilot-Drafted Communications | 📦 evidence-export-ready |
| `3.6` | Supervision and Oversight (FINRA Rule 3110 / SEC Reg BI) | 📦 evidence-export-ready |

### 05-dlp-policy-governance

| Control | Title | Coverage state |
|---------|-------|----------------|
| `2.1` | DLP Policies for M365 Copilot Interactions | 📦 evidence-export-ready |
| `3.10` | SEC Reg S-P -- Privacy of Consumer Financial Information | 📦 evidence-export-ready |
| `3.12` | Evidence Collection and Audit Attestation | 📦 evidence-export-ready |

### 06-audit-trail-manager

| Control | Title | Coverage state |
|---------|-------|----------------|
| `3.1` | Copilot Interaction Audit Logging (Purview Unified Audit Log) | 📦 evidence-export-ready |
| `3.11` | Record Keeping and Books-and-Records Compliance (SEC 17a-3/4, FINRA 4511) | 📦 evidence-export-ready |
| `3.12` | Evidence Collection and Audit Attestation | 📦 evidence-export-ready |
| `3.2` | Data Retention Policies for Copilot Interactions | 📦 evidence-export-ready |
| `3.3` | eDiscovery for Copilot-Generated Content | 📦 evidence-export-ready |

### 07-conditional-access-automation

| Control | Title | Coverage state |
|---------|-------|----------------|
| `2.3` | Conditional Access Policies for Copilot Workloads | 📦 evidence-export-ready |
| `2.6` | Copilot Web Search and Web Grounding Controls | 📦 evidence-export-ready |
| `2.9` | Defender for Cloud Apps — Copilot Session Controls | 📦 evidence-export-ready |

### 08-license-governance-roi

| Control | Title | Coverage state |
|---------|-------|----------------|
| `1.9` | License Planning and Copilot Assignment Strategy | 📦 evidence-export-ready |
| `4.5` | Copilot Usage Analytics and Adoption Reporting | 📦 evidence-export-ready |
| `4.6` | Microsoft Viva Insights -- Copilot Impact Measurement | 📦 evidence-export-ready |
| `4.8` | Cost Allocation and License Optimization | 📦 evidence-export-ready |

### 09-feature-management-controller

| Control | Title | Coverage state |
|---------|-------|----------------|
| `2.6` | Copilot Web Search and Web Grounding Controls | 📦 evidence-export-ready |
| `4.1` | Copilot Admin Settings and Feature Management | 📦 evidence-export-ready |
| `4.12` | Change Management for Copilot Feature Rollouts | 📦 evidence-export-ready |
| `4.13` | Copilot Extensibility Governance (Plugin Lifecycle, Connector Monitoring) | 📦 evidence-export-ready |
| `4.2` | Copilot in Teams Meetings Governance | 📦 evidence-export-ready |
| `4.3` | Copilot in Teams Phone and Queues Governance | 📦 evidence-export-ready |
| `4.4` | Copilot in Viva Suite Governance | 📦 evidence-export-ready |

### 10-connector-plugin-governance

| Control | Title | Coverage state |
|---------|-------|----------------|
| `1.13` | Extensibility Readiness (Graph Connectors, Plugins, Declarative Agents) | 📦 evidence-export-ready |
| `2.13` | Plugin and Graph Connector Security Governance | 📦 evidence-export-ready |
| `2.14` | Declarative Agents from SharePoint — Creation and Sharing Governance | 📦 evidence-export-ready |
| `2.16` | Federated Copilot Connector and Model Context Protocol (MCP) Governance | 📄 documentation-only |
| `4.13` | Copilot Extensibility Governance (Plugin Lifecycle, Connector Monitoring) | 📦 evidence-export-ready |

### 11-risk-tiered-rollout

| Control | Title | Coverage state |
|---------|-------|----------------|
| `1.11` | Organizational Change Management and Adoption Planning | 📦 evidence-export-ready |
| `1.12` | Training and Awareness Program | 📦 evidence-export-ready |
| `1.9` | License Planning and Copilot Assignment Strategy | 📦 evidence-export-ready |
| `4.12` | Change Management for Copilot Feature Rollouts | 📦 evidence-export-ready |

### 12-regulatory-compliance-dashboard

| Control | Title | Coverage state |
|---------|-------|----------------|
| `2.10` | Insider Risk Detection for Copilot Usage Patterns | 📄 documentation-only |
| `2.7` | Data Residency and Cross-Border Data Flow Governance | 📄 documentation-only |
| `3.12` | Evidence Collection and Audit Attestation | 📦 evidence-export-ready |
| `3.13` | FFIEC IT Examination Handbook Alignment | 📦 evidence-export-ready |
| `3.7` | Regulatory Reporting (FINRA, SEC, SOX, GLBA, CFPB UDAAP) | 📦 evidence-export-ready |
| `3.8` | Model Risk Management Alignment (OCC 2011-12 / SR 11-7) | 📦 evidence-export-ready |
| `4.5` | Copilot Usage Analytics and Adoption Reporting | 📦 evidence-export-ready |
| `4.7` | Copilot Feedback and Telemetry Data Governance | 📦 evidence-export-ready |

### 13-dora-resilience-monitor

| Control | Title | Coverage state |
|---------|-------|----------------|
| `2.7` | Data Residency and Cross-Border Data Flow Governance | 📦 evidence-export-ready |
| `4.10` | Business Continuity and Disaster Recovery for Copilot Dependency | 📦 evidence-export-ready |
| `4.11` | Microsoft Sentinel Integration for Copilot Events | 📦 evidence-export-ready |
| `4.9` | Incident Reporting and Root Cause Analysis | 📦 evidence-export-ready |

### 14-communication-compliance-config

| Control | Title | Coverage state |
|---------|-------|----------------|
| `2.10` | Insider Risk Detection for Copilot Usage Patterns | 📦 evidence-export-ready |
| `3.4` | Communication Compliance Monitoring | 📦 evidence-export-ready |
| `3.5` | FINRA Rule 2210 Compliance for Copilot-Drafted Communications | 📦 evidence-export-ready |
| `3.6` | Supervision and Oversight (FINRA Rule 3110 / SEC Reg BI) | 📦 evidence-export-ready |
| `3.9` | AI Disclosure, Transparency, and SEC Marketing Rule | 📦 evidence-export-ready |

### 15-pages-notebooks-gap-monitor

| Control | Title | Coverage state |
|---------|-------|----------------|
| `2.11` | Copilot Pages Security and Sharing Controls | 📦 evidence-export-ready |
| `3.11` | Record Keeping and Books-and-Records Compliance (SEC 17a-3/4, FINRA 4511) | 📦 evidence-export-ready |
| `3.2` | Data Retention Policies for Copilot Interactions | 📦 evidence-export-ready |
| `3.3` | eDiscovery for Copilot-Generated Content | 📦 evidence-export-ready |

### 16-item-level-oversharing-scanner

| Control | Title | Coverage state |
|---------|-------|----------------|
| `1.14` | Item-Level Permission Scanning | 📄 documentation-only |
| `1.2` | SharePoint Oversharing Detection and Remediation (DSPM for AI) | 📦 evidence-export-ready |
| `1.3` | Restricted SharePoint Search Configuration | 📦 evidence-export-ready |
| `1.4` | Semantic Index Governance and Scope Control | 📦 evidence-export-ready |
| `1.6` | Permission Model Audit (SharePoint, OneDrive, Exchange, Teams, Graph) | 📦 evidence-export-ready |
| `2.5` | Data Minimization and Grounding Scope | 📦 evidence-export-ready |

### 17-sharepoint-permissions-drift

| Control | Title | Coverage state |
|---------|-------|----------------|
| `1.15` | SharePoint Permissions Drift Detection | 📄 documentation-only |
| `1.2` | SharePoint Oversharing Detection and Remediation (DSPM for AI) | 📦 evidence-export-ready |
| `1.4` | Semantic Index Governance and Scope Control | 📦 evidence-export-ready |
| `1.6` | Permission Model Audit (SharePoint, OneDrive, Exchange, Teams, Graph) | 📦 evidence-export-ready |
| `2.5` | Data Minimization and Grounding Scope | 📦 evidence-export-ready |

### 18-entra-access-reviews

| Control | Title | Coverage state |
|---------|-------|----------------|
| `1.2` | SharePoint Oversharing Detection and Remediation (DSPM for AI) | 📦 evidence-export-ready |
| `1.6` | Permission Model Audit (SharePoint, OneDrive, Exchange, Teams, Graph) | 📦 evidence-export-ready |
| `2.12` | External Sharing and Guest Access Governance | 📦 evidence-export-ready |
| `2.5` | Data Minimization and Grounding Scope | 📦 evidence-export-ready |

### 19-copilot-tuning-governance

| Control | Title | Coverage state |
|---------|-------|----------------|
| `1.16` | Copilot Tuning Governance | 📦 evidence-export-ready |

## Portfolio totals

| Solution | documentation-only | scripted-sample | evidence-export-ready |
|----------|-------------------:|----------------:|----------------------:|
| `01-copilot-readiness-scanner` | 0 | 0 | 5 |
| `02-oversharing-risk-assessment` | 1 | 0 | 6 |
| `03-sensitivity-label-auditor` | 0 | 0 | 4 |
| `04-finra-supervision-workflow` | 0 | 0 | 3 |
| `05-dlp-policy-governance` | 0 | 0 | 3 |
| `06-audit-trail-manager` | 0 | 0 | 5 |
| `07-conditional-access-automation` | 0 | 0 | 3 |
| `08-license-governance-roi` | 0 | 0 | 4 |
| `09-feature-management-controller` | 0 | 0 | 7 |
| `10-connector-plugin-governance` | 1 | 0 | 4 |
| `11-risk-tiered-rollout` | 0 | 0 | 4 |
| `12-regulatory-compliance-dashboard` | 2 | 0 | 6 |
| `13-dora-resilience-monitor` | 0 | 0 | 4 |
| `14-communication-compliance-config` | 0 | 0 | 5 |
| `15-pages-notebooks-gap-monitor` | 0 | 0 | 4 |
| `16-item-level-oversharing-scanner` | 1 | 0 | 5 |
| `17-sharepoint-permissions-drift` | 1 | 0 | 4 |
| `18-entra-access-reviews` | 0 | 0 | 4 |
| `19-copilot-tuning-governance` | 0 | 0 | 1 |
| **Total** | **6** | **0** | **81** |

Solutions whose mappings are not yet present in `data/control-coverage.json` (currently `20-generative-ai-model-governance-monitor`, `21-cross-tenant-agent-federation-auditor`, `22-pages-notebooks-retention-tracker`, `23-copilot-studio-lifecycle-tracker`) do not appear in the matrix above. They will be added once the coverage map is extended; until then their READMEs remain unannotated to avoid inventing mappings.
