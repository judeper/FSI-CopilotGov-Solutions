# Examination Readiness

Each solution ships an evidence-export pattern that supports consistent examination preparation across controls and regulations.

| Solution | Evidence Outputs | Key Regulations |
|----------|------------------|-----------------|
| Copilot Readiness Assessment Scanner | readiness-scorecard, data-hygiene-findings, remediation-plan | FINRA 3110, SEC Reg S-P, GLBA 501(b), OCC 2011-12, FFIEC IT Handbook |
| Oversharing Risk Assessment and Remediation | oversharing-findings, remediation-queue, site-owner-attestations | GLBA 501(b), SEC Reg S-P, FINRA 4511, FFIEC IT Handbook |
| Sensitivity Label Coverage Auditor | label-coverage-report, label-gap-findings, remediation-manifest | FINRA 4511, SEC 17a-4, GDPR, GLBA 501(b) |
| FINRA Supervision Workflow for Copilot | supervision-queue-snapshot, review-disposition-log, sampling-summary | FINRA 3110, FINRA 2210, SEC Reg BI |
| DLP Policy Governance for Copilot | dlp-policy-baseline, policy-drift-findings, exception-attestations | GLBA 501(b), SEC Reg S-P, DORA, GDPR |
| Copilot Interaction Audit Trail Manager | audit-log-completeness, retention-policy-state, ediscovery-readiness-package | SEC 17a-3, SEC 17a-4, FINRA 4511, CFTC 1.31, SOX 404 |
| Conditional Access Policy Automation for Copilot | ca-policy-state, drift-alert-summary, access-exception-register | OCC 2011-12, FINRA 3110, DORA |
| License Governance and ROI Tracker | license-utilization-report, roi-scorecard, reallocation-recommendations | OCC 2011-12, SOX 404 |
| Copilot Feature Management Controller | feature-state-baseline, rollout-ring-history, drift-findings | SEC Reg FD, FINRA 3110 |
| Copilot Connector and Plugin Governance | connector-inventory, approval-register, data-flow-attestations | FINRA 3110, OCC 2011-12, DORA |
| Risk-Tiered Rollout Automation | wave-readiness-log, approval-history, rollout-health-dashboard | OCC 2011-12, FINRA 3110, DORA |
| Regulatory Compliance Dashboard | control-status-snapshot, framework-coverage-matrix, dashboard-export | FINRA 4511, FINRA 3110, SEC 17a-4, OCC 2011-12, DORA, GLBA 501(b) |
| DORA Operational Resilience Monitor | service-health-log, incident-register, resilience-test-results | DORA, OCC 2011-12, FFIEC IT Handbook |
| Communication Compliance Configurator | policy-template-export, reviewer-queue-metrics, lexicon-update-log | FINRA 2210, FINRA 3110, SEC Reg BI, FCA SYSC 10 |
| Copilot Pages and Notebooks Compliance Gap Monitor | gap-findings, compensating-control-log, preservation-exception-register | SEC 17a-4, FINRA 4511, SOX 404 |

Unified evidence export is orchestrated through `scripts/deployment/Export-CopilotGovernanceEvidence.ps1` and validated with `scripts/deployment/Test-EvidenceIntegrity.ps1`.
