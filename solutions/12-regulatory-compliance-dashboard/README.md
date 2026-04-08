# Regulatory Compliance Dashboard

> **Status:** Documentation-first scaffold | **Version:** v0.1.0 | **Priority:** P0 | **Track:** C

> ⚠️ **Documentation-first repository.** Scripts use representative sample data and do not connect to live Microsoft 365 services. See [Disclaimer](../../docs/disclaimer.md) and [Documentation vs Runnable Assets Guide](../../docs/documentation-vs-runnable-assets-guide.md).

## Overview

The Regulatory Compliance Dashboard documents the single-pane-of-glass operating model for FSI Copilot governance posture. It documents the aggregation pattern for consolidating control evidence into Dataverse and Power BI; customers must deploy Dataverse connections and Power BI workspace bindings to enable live dashboarding. In the repository state it provides seeded control-status snapshots, fallback monitoring output, and Power BI dataset specifications so control owners, audit teams, and executives can review the intended design before implementation.

This solution supports compliance with FINRA 4511, FINRA 3110, SEC 17a-4, OCC 2011-12, DORA, and GLBA 501(b) by presenting consolidated evidence rather than making direct control changes. Examination readiness improves as more upstream solutions publish current evidence packages and package hashes.

## Features

| Feature | What it does | Primary controls | Evidence output |
|---------|--------------|------------------|-----------------|
| Control status RAG | Normalizes control statuses into executive red, amber, and green indicators with contract scores of 100, 50, 25, 10, and 0. | 3.7, 4.7 | control-status-snapshot |
| Evidence freshness monitoring | Flags stale or missing evidence exports so audit teams can focus on controls that need refreshed documentation. | 3.8, 3.12 | control-status-snapshot |
| Regulatory coverage matrix | Maps control implementation and evidence packages to FINRA, SEC, OCC, DORA, GLBA, and optional SOX 404 reporting views. | 3.7, 3.13 | framework-coverage-matrix |
| Examination readiness packages | Bundles evidence references, export hashes, and solution ownership metadata for regulator and internal audit requests. | 3.8, 3.12, 3.13 | dashboard-export |
| Maturity score trending | Tracks governance maturity over time by weighting control scores and highlighting adoption and benchmarking changes. | 4.5, 4.7 | control-status-snapshot, dashboard-export |

## Scope Boundaries

> **Important:** This solution provides governance scaffolds, templates, and documentation-first
> scripts. It does not modify tenant state or connect to live services in its repository form.

- ❌ Does not deploy Power BI reports or dashboards (dashboard specifications and dataset designs are documented, not deployed)
- ❌ Does not connect to Dataverse APIs (table schemas and seed data are provided for manual deployment)
- ❌ Does not deploy Power Automate flows (evidence aggregation and freshness monitoring flows are documented, not exported)
- ❌ Does not aggregate evidence from upstream solutions automatically (aggregation patterns are documented for customer implementation)
- ❌ Does not produce production evidence (evidence packages contain sample data for format validation)

## Architecture

```text
+----------------------------------+      +----------------------------------+      +----------------------------------+
| Solutions 01-11                 | ---> | Dataverse fsi_cg_rcd_*           | ---> | Power BI Regulatory Compliance   |
| Evidence exports and hashes     |      | baseline, finding, evidence      |      | Dashboard and executive views    |
+----------------------------------+      +----------------------------------+      +----------------------------------+
          |                                              ^                                              |
          |                                              |                                              v
          +---------> RCD-EvidenceAggregator flow -------+                                dashboard-export packages
```

The diagram above illustrates the documented target-state architecture; the repository does not deploy these integrations automatically. The dashboard design also supports evidence from solutions 13-15 as those solutions are deployed. Power BI assets are documentation-led — this repository defines the dataset, measures, pages, and row-level security expectations without including binary `.pbix` or `.pbit` files — and all repository outputs should be treated as seeded reference artifacts rather than a live aggregator.

## Quick Start

1. Review [Prerequisites](./docs/prerequisites.md) and confirm dependency solutions `06-audit-trail-manager` and `11-risk-tiered-rollout` are deployed.
2. Review [Deployment Guide](./docs/deployment-guide.md) to plan Dataverse, Power Automate, and Power BI configuration.
3. Select a governance tier from `config\baseline.json`, `config\recommended.json`, or `config\regulated.json`.
4. Run `scripts\Deploy-Solution.ps1` to generate the initial seeded control status snapshot and Dataverse manifest used during implementation.
5. Build the Power BI report from the documented template specification in `docs/architecture.md`, manually bind it to the Dataverse tables, and configure scheduled refresh when a live aggregation environment is ready. No binary `.pbix` is included in this repository.
6. Run `scripts\Export-Evidence.ps1` after each deployment change to publish the dashboard evidence package and companion `.sha256` file.

## Solution Components

| Path | Purpose |
|------|---------|
| `scripts\Deploy-Solution.ps1` | Validates dependencies, inventories upstream evidence, seeds Dataverse table contracts, and writes the initial control status snapshot seed. |
| `scripts\Monitor-Compliance.ps1` | Calculates maturity score, checks evidence freshness, and returns a structured dashboard health object from a seeded or fallback snapshot. |
| `scripts\Export-Evidence.ps1` | Publishes documentation-first control status, framework coverage, and dashboard export metadata using the shared evidence package contract. |
| `config\default-config.json` | Defines shared defaults, Dataverse table names, Power BI dataset tables, regulatory frameworks, and maturity score weights. |
| `config\baseline.json` | Baseline tier with daily aggregation, 48 hour freshness threshold, and FINRA plus OCC coverage only. |
| `config\recommended.json` | Recommended tier with daily aggregation, 25 hour freshness threshold, all six primary regulatory frameworks, and maturity scoring enabled. |
| `config\regulated.json` | Regulated tier with hourly freshness checks, automatic examination packaging, strict retention, and optional SOX 404 coverage. |
| `docs\architecture.md` | Documents the end-to-end design for Dataverse, flows, Power BI dataset, DAX measures, and dependency integrations. |
| `tests\12-regulatory-compliance-dashboard.Tests.ps1` | Validates required files, script help, parameter presence, configuration content, and PowerShell syntax. |

## Deployment

Deployment is intentionally staged:

1. Prepare Dataverse tables and environment variables.
2. Deploy the three Power Automate flows that aggregate evidence, monitor freshness, and package examination output.
3. Run the deployment script to seed the baseline status table and generate the manifest used by Power BI.
4. Build the Power BI report from the documented template specification, then configure dataset refresh and row-level security.

## Prerequisites Summary

- Solutions `06-audit-trail-manager` and `11-risk-tiered-rollout` deployed in the same environment.
- Power BI Pro or Premium Per User licensing for authors and workspace administrators.
- Dataverse capacity of at least 1 GB for baseline, finding, and evidence tables.
- Power Automate Premium licensing for scheduled aggregation and freshness monitoring.
- Power BI Admin and Dataverse System Administrator permissions for deployment operators.
- Microsoft 365 E5 Compliance if Purview-backed evidence references are required.

## Related Controls

| Control | Title | Playbooks |
|---------|-------|-----------|
| 3.7 | Compliance Posture Reporting and Executive Dashboards (Regulatory Reporting (FINRA, SEC, SOX, GLBA, CFPB UDAAP)) | [Architecture](docs/architecture.md) / [Deployment Guide](docs/deployment-guide.md) / [Troubleshooting](docs/troubleshooting.md) |
| 3.8 | Regulatory Examination Readiness Reporting (Model Risk Management Alignment (OCC 2011-12 / SR 11-7)) | [Evidence Export](docs/evidence-export.md) / [Deployment Guide](docs/deployment-guide.md) / [Troubleshooting](docs/troubleshooting.md) |
| 3.12 | Evidence Collection and Audit Attestation | [Evidence Export](docs/evidence-export.md) / [Architecture](docs/architecture.md) / [Troubleshooting](docs/troubleshooting.md) |
| 3.13 | Third-Party Audit and Regulatory Reporting (FFIEC IT Examination Handbook Alignment) | [Architecture](docs/architecture.md) / [Evidence Export](docs/evidence-export.md) / [Troubleshooting](docs/troubleshooting.md) |
| 4.5 | Copilot Usage Analytics and Adoption Reporting | [Architecture](docs/architecture.md) / [Deployment Guide](docs/deployment-guide.md) / [Troubleshooting](docs/troubleshooting.md) |
| 4.7 | Governance Maturity Scoring and Benchmarking (Copilot Feedback and Telemetry Data Governance) | [Architecture](docs/architecture.md) / [Deployment Guide](docs/deployment-guide.md) / [Troubleshooting](docs/troubleshooting.md) |

## Regulatory Alignment

The dashboard supports compliance with these regulations by surfacing consolidated evidence status, coverage mapping, and export timestamps. It does not replace the underlying books and records, supervision, or retention controls implemented by source systems.

| Regulation | Dashboard alignment |
|------------|---------------------|
| FINRA 4511 | Highlights books and records evidence freshness and cross-references upstream export packages used to support supervisory record retention. |
| FINRA 3110 | Summarizes supervision control posture and implementation gaps for executive and compliance review. |
| SEC 17a-4 | Provides dashboard export references, evidence timestamps, and coverage mapping that support records retention and examination package assembly. |
| OCC 2011-12 | Tracks maturity score trends, model governance coverage, and readiness reporting for risk and control committees. |
| DORA | Consolidates operational resilience and governance evidence into a single coverage matrix for EU-regulated reporting. |
| GLBA 501(b) | Surfaces control coverage and evidence freshness relevant to governance, safeguards monitoring, and attestation packages. |

## Evidence Export

This solution publishes the following evidence outputs:

| Evidence output | Purpose |
|-----------------|---------|
| `control-status-snapshot` | Current control statuses, contract scores, evidence freshness timestamps, and source solution references. |
| `framework-coverage-matrix` | Control-to-regulation mapping used by Power BI heatmaps and examination readiness filters. |
| `dashboard-export` | Report metadata, workbook export details, and packaged references for auditor or regulator consumption. |

All evidence packages must align to `../../data/evidence-schema.json` and include a companion `.sha256` file.

## Known Limitations

- Power BI assets are documentation-led in this repository; the `.pbix` and `.pbit` binaries are intentionally not stored here.
- Repository outputs are seeded or fallback artifacts until Dataverse ingestion flows and Power BI workspace bindings are manually implemented in the target environment. Deployment scripts do not provision live Dataverse connections, Power Automate flows, or Power BI workspace bindings.
- Examination readiness packages depend on upstream solutions 01-15 being deployed and exporting current evidence.
- The dashboard reports implementation state and evidence freshness but does not remediate source control gaps directly.
