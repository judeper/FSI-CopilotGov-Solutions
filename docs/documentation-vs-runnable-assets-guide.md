# Documentation vs Runnable Assets Guide

This repository is documentation-first: it ships guidance, templates, scripts, and evidence patterns, but it does not replace tenant-specific design review or runtime material.

## Asset Types

| Asset type | Examples | Operator use | What stays outside the repository |
| --- | --- | --- | --- |
| Authoritative documentation | `README.md`, `DEPLOYMENT-GUIDE.md`, `docs/`, solution READMEs and solution docs | Review first and use as the approval baseline for deployment and support | Tenant-specific approvals, local implementation notes that have not been published |
| Starter templates and config baselines | `templates/`, `config/*.json`, delivery checklist template | Adapt to the target tenant, tier, and operating model before production use | Live tenant objects, environment-specific configuration values, connection references |
| Validation and preflight scripts | `scripts/build-docs.py`, `scripts/validate-*.py`, `scripts/deployment/Validate-Prerequisites.ps1` | Run directly to validate repository structure, documentation, and preflight readiness | None, unless your local environment stores output in a secure workspace |
| Solution deployment and monitoring scripts | `solutions/*/scripts/Deploy-Solution.ps1`, `Monitor-Compliance.ps1`, `Export-Evidence.ps1` | Run only after operator review, tier confirmation, and environment-specific approvals | Secrets, certificates, app registrations, tenant-side runtime state |
| Machine-readable contracts | `data/*.json`, `scripts/common/IntegrationConfig.psm1` | Treat as controlled shared contracts and change only with deliberate validation | Customer-specific overrides that should not alter the shared contract |
| Runtime assets not included by design | Exported Power Automate flows, app packages, secrets, certificates, production-only manifests | Document how to create or store them safely in each tenant | The assets themselves |

## Operator Rules of Thumb

1. Read the documentation before you run the scripts.
2. Treat templates as starting points, not production-ready tenant state.
3. Keep credentials, secrets, certificates, and runtime exports outside source control.
4. Record every tenant-specific decision in the handoff checklist or change record.

## If Documentation and Scripts Diverge

1. Stop the next deployment wave.
2. Record the discrepancy in `DELIVERY-CHECKLIST-TEMPLATE.md` or the solution-specific checklist.
3. Update the documentation or script so that the approved runbook matches the observed behavior.
4. Re-run the repository validation commands before continuing.
