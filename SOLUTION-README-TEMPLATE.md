# {{Solution Name}}

> **Status:** Documentation-first scaffold | **Version:** v0.1.0 | **Priority:** P0 | **Track:** A

> ⚠️ **Documentation-first repository.** Scripts use representative sample data and do not connect to live Microsoft 365 services. See [Disclaimer](../../docs/disclaimer.md) and [Documentation vs Runnable Assets Guide](../../docs/documentation-vs-runnable-assets-guide.md).

## Overview

{{Brief description of the solution's purpose, target audience, and governance value. Reference applicable regulations using cautious language such as "supports compliance with" or "helps meet". Note that the solution is documentation-first for Power Automate and Power BI assets.}}

## Features

| Capability | What the solution does | Compliance value |
|------------|------------------------|------------------|
| {{Feature 1}} | {{Description. Note documentation-first posture where applicable.}} | {{Which controls this supports}} |
| {{Feature 2}} | {{Description}} | {{Controls}} |

## Scope Boundaries

> **Important:** This solution provides governance scaffolds, templates, and documentation-first
> scripts. It does not modify tenant state or connect to live services in its repository form.

- ❌ {{Does not do X (live API, tenant modification, etc.)}}
- ❌ {{Does not do Y}}
- ❌ Does not deploy Power Automate flows (governance workflows are documented, not exported)
- ❌ Does not create Dataverse tables (schema contracts are provided for manual deployment)
- ❌ Does not produce production evidence (evidence packages contain sample data for format validation)

## Architecture

{{ASCII diagram or description of solution layers and data flow. Reference docs/architecture.md for details.}}

See [docs/architecture.md](./docs/architecture.md) for the detailed component model and data flow.

## Quick Start

1. Review [docs/prerequisites.md](./docs/prerequisites.md) and confirm workload permissions, licenses, and PowerShell modules.
2. Select the target governance tier from `config\baseline.json`, `config\recommended.json`, or `config\regulated.json`.
3. Update solution settings in `config\default-config.json` and the selected tier file.
4. Run `scripts\Deploy-Solution.ps1` with `-WhatIf` to preview the deployment manifest.
5. Run `scripts\Monitor-Compliance.ps1` to generate a compliance baseline with representative sample data.
6. Run `scripts\Export-Evidence.ps1` to generate the evidence package with SHA-256 companion files.

## Solution Components

| Path | Purpose |
|------|---------|
| `scripts/Deploy-Solution.ps1` | {{Purpose}} |
| `scripts/Monitor-Compliance.ps1` | {{Purpose}} |
| `scripts/Export-Evidence.ps1` | {{Purpose}} |
| `config/default-config.json` | {{Purpose}} |
| `config/baseline.json` | Baseline governance tier settings |
| `config/recommended.json` | Recommended governance tier settings |
| `config/regulated.json` | Regulated governance tier settings |
| `docs/architecture.md` | Detailed architecture and data flow |
| `docs/deployment-guide.md` | Step-by-step deployment guide |
| `docs/evidence-export.md` | Evidence output definitions and export process |
| `docs/prerequisites.md` | Licensing, permissions, and environment requirements |
| `docs/troubleshooting.md` | Common issues and resolutions |
| `tests/{{solution-slug}}.Tests.ps1` | Pester validation tests |

## Deployment

See [docs/deployment-guide.md](./docs/deployment-guide.md) for the complete deployment workflow.

## Prerequisites

See [docs/prerequisites.md](./docs/prerequisites.md) for the full requirements list.

## Related Controls

| Control | Title | How this solution supports |
|---------|-------|---------------------------|
| {{X.Y}} | {{Control title}} | {{How the solution supports this control}} |

## Regulatory Alignment

| Regulation | Relevance |
|------------|-----------|
| {{Regulation name and section}} | {{How the solution supports compliance}} |

## Evidence Export

{{Description of evidence outputs and their purpose. Reference docs/evidence-export.md for details.}}

See [docs/evidence-export.md](./docs/evidence-export.md) for artifact definitions, schema details, and export process.

## Known Limitations

- {{Limitation 1}}
- {{Limitation 2}}
