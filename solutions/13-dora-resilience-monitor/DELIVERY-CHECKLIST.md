# Delivery Checklist

## Delivery Summary

| Item | Value |
|------|-------|
| Solution | DORA Operational Resilience Monitor |
| Solution Code | DRM |
| Version | v0.1.1 |
| Track | D |
| Priority | P1 |
| Controls | 2.7, 4.9, 4.10, 4.11 |
| Regulations | DORA, OCC 2011-12, FFIEC IT Handbook |
| Evidence Outputs | service-health-log, incident-register, resilience-test-results |
| Dependency | 12-regulatory-compliance-dashboard |

## Pre-Deployment

- [ ] Customer confirms the operating model for Microsoft 365 Copilot and the dependent workloads in scope.
- [ ] Microsoft 365, Entra ID, PowerShell, and network prerequisites from `docs/prerequisites.md` are verified.
- [ ] Tenant details are collected, including tenant ID, app registration ID, secret or certificate approach, and notification channel.
- [ ] Governance tier is selected: baseline, recommended, or regulated.
- [ ] Dependency expectations for 12-regulatory-compliance-dashboard are reviewed if dashboard rollup is required.
- [ ] Evidence output path and retention requirements are agreed with the customer records team.

## Configuration Review

- [ ] `config/default-config.json` reviewed for monitored services, default evidence path, and dashboard feed settings.
- [ ] `config/baseline.json` reviewed for hourly monitoring and summary notification behavior.
- [ ] `config/recommended.json` reviewed for 15-minute polling, incident register settings, and resilience tracking targets.
- [ ] `config/regulated.json` reviewed for 5-minute polling, DORA reporting thresholds, Sentinel options, and immutability settings.
- [ ] Service health endpoints are reachable from the deployment host: `graph.microsoft.com` and `admin.microsoft.com`.
- [ ] Required environment variables are documented for tenant ID, client ID, Sentinel workspace ID, and immutable storage if used.

## Deployment Steps

1. [ ] Open PowerShell 7.2 or later in `solutions/13-dora-resilience-monitor`.
2. [ ] Run `scripts\Deploy-Solution.ps1 -ConfigurationTier <tier> -WhatIf -Verbose` and review the planned manifest output.
3. [ ] Run `scripts\Deploy-Solution.ps1 -ConfigurationTier <tier> -TenantId <tenant-guid> -OutputPath .\artifacts -Verbose` to create the deployment manifest.
4. [ ] Run `scripts\Monitor-Compliance.ps1 -ConfigurationTier <tier> -OutputPath .\artifacts -Verbose` to capture the initial service-health baseline.
5. [ ] Configure the documented Power Automate flow pattern from `docs/deployment-guide.md` if alert routing or incident logging is required.
6. [ ] Run `scripts\Export-Evidence.ps1 -ConfigurationTier <tier> -OutputPath .\artifacts -Verbose` to generate examiner-ready evidence.

## Post-Deployment Validation

- [ ] Deployment manifest is present in `artifacts/` and reflects the selected tier.
- [ ] Initial monitoring output includes service-health records for all Copilot-dependent services.
- [ ] Evidence export runs successfully without script errors.
- [ ] Each JSON evidence file has a matching `.sha256` companion file.
- [ ] Control status entries are populated for 2.7, 4.9, 4.10, and 4.11.
- [ ] Dashboard feed metadata is available for the downstream dependency on 12-regulatory-compliance-dashboard.

## Evidence Review

- [ ] `service-health-log` is present and includes timestamps, workload names, and status values.
- [ ] `incident-register` is present and includes DORA incident fields, even if no reportable incidents occurred in the selected period.
- [ ] `resilience-test-results` is present and documents annual test status, RTO and RPO targets, and any known gaps.
- [ ] Evidence package overall status is reviewed as `partial` when monitor-only or partial controls remain in scope.

## Customer Handover

- [ ] README reviewed with the customer operations, compliance, and resilience stakeholders.
- [ ] Escalation path for Microsoft 365 service-health data gaps is documented.
- [ ] Support ownership for Power Automate flow maintenance is documented.
- [ ] Evidence retention and storage responsibilities are confirmed.
- [ ] Customer acknowledges dependency on external Microsoft Sentinel provisioning where control 4.11 is required.

## Sign-Off

- [ ] Delivery engineer sign-off completed.
- [ ] Customer technical owner sign-off completed.
- [ ] Customer compliance owner sign-off completed.
- [ ] Production handover date recorded.