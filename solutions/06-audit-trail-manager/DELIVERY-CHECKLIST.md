# Delivery Checklist

Use this checklist before handing the Copilot Interaction Audit Trail Manager solution to deployment or examination support teams.

## Audit readiness

- [ ] Unified Audit Log is enabled in the Microsoft 365 tenant.
- [ ] `CopilotInteraction` events are confirmed in the validation window; `ConnectedAIAppInteraction` or `AIAppInteraction` are included only when custom or third-party AI apps are in scope.
- [ ] Required supporting events such as `FileAccessed` are included in the monitoring scope.
- [ ] Audit tier for the selected tier is documented as Audit (Standard) or Audit (Premium) as required.

## Retention readiness

- [ ] Purview retention policies are applied for Copilot interaction artifacts.
- [ ] Retention labels are scoped to the intended Copilot records and supporting evidence artifacts.
- [ ] Retention schedule is documented for SEC 17a-4, FINRA 4511, CFTC 1.31, and SOX 404.
- [ ] WORM or immutable storage documentation is attached for regulated deployments.

## Microsoft Purview eDiscovery readiness

- [ ] Microsoft Purview eDiscovery cases are created or referenced for the selected tier.
- [ ] Holds are configured for required custodians or record locations.
- [ ] Preservation status, hold counts, and custodian counts are documented.
- [ ] Legal hold owners and examination response contacts are recorded.

## Reporting and alerting readiness

- [ ] Power BI dashboard is operational and refresh ownership is assigned.
- [ ] Power Automate retention exception alerts are configured and tested.
- [ ] Compliance findings are reviewed and open exceptions are documented.

## Evidence readiness

- [ ] `audit-log-completeness.json` is generated and reviewed.
- [ ] `retention-policy-state.json` is generated and reviewed.
- [ ] `ediscovery-readiness-package.json` is generated and reviewed.
- [ ] SHA-256 companion files validate successfully.
- [ ] The full evidence package is archived with the deployment record.

## Sign-Off

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Solution Owner | | | |
| Security Lead | | | |
| Compliance Lead | | | |
| Customer Understanding | ☐ Customer confirms they understand this solution uses representative sample data and requires tenant binding for production use. | | |
