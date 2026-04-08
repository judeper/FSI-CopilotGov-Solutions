# Examination Readiness

Each solution ships an evidence-export pattern that supports consistent examination preparation across controls and regulations. `Key Regulations` remains the concise reviewer-facing list, while `Framework IDs` is the complete machine-readable crosswalk back to `data/frameworks-master.json`.

| Solution | Evidence Outputs | Key Regulations | Framework IDs |
|----------|------------------|-----------------|---------------|
| Copilot Readiness Assessment Scanner | readiness-scorecard, data-hygiene-findings, remediation-plan | FINRA 3110, SEC Reg S-P, GLBA 501(b), OCC 2011-12, FFIEC IT Handbook, SOX 302/404, Interagency AI Guidance | finra-3110, sec-reg-sp, glba-501b, sox-302-404, occ-2011-12, ffiec-it-handbook, interagency-ai-guidance |
| Oversharing Risk Assessment and Remediation | oversharing-findings, remediation-queue, site-owner-attestations | GLBA 501(b), SEC Reg S-P, FINRA 4511, FFIEC IT Handbook, SOX 302/404 | finra-4511, sec-reg-sp, glba-501b, sox-302-404, ffiec-it-handbook |
| Sensitivity Label Coverage Auditor | label-coverage-report, label-gap-findings, remediation-manifest | FINRA 4511, SEC 17a-4, GDPR, GLBA 501(b) | finra-4511, sec-17a3, sec-17a4, sec-reg-sp, glba-501b, sox-302-404, ffiec-it-handbook, gdpr |
| FINRA Supervision Workflow for Copilot | supervision-queue-snapshot, review-disposition-log, sampling-summary | FINRA 3110, FINRA 2210, SEC Reg BI | finra-2210, finra-3110, sec-reg-bi |
| DLP Policy Governance for Copilot | dlp-policy-baseline, policy-drift-findings, exception-attestations | GLBA 501(b), SEC Reg S-P, DORA, GDPR, FINRA 4511, SOX 302/404 | finra-4511, sec-reg-sp, glba-501b, sox-302-404, dora, gdpr |
| Copilot Interaction Audit Trail Manager | audit-log-completeness, retention-policy-state, ediscovery-readiness-package | SEC 17a-3, SEC 17a-4, FINRA 4511, CFTC 1.31, SOX 404 | finra-4511, sec-17a3, sec-17a4, sox-302-404, cftc-1-31 |
| Conditional Access Policy Automation for Copilot | ca-policy-state, drift-alert-summary, access-exception-register | OCC 2011-12, FINRA 3110, DORA | finra-3110, glba-501b, occ-2011-12, ffiec-it-handbook, dora |
| License Governance and ROI Tracker | license-utilization-report, roi-scorecard, reallocation-recommendations | OCC 2011-12, SOX 404, GLBA 501(b), FFIEC IT Handbook | glba-501b, sox-302-404, occ-2011-12, ffiec-it-handbook |
| Copilot Feature Management Controller | feature-state-baseline, rollout-ring-history, drift-findings | SEC Reg FD, FINRA 3110 | finra-3110, finra-4511, sec-17a4, sec-reg-sp, sec-reg-fd, glba-501b, sox-302-404, occ-2011-12, ffiec-it-handbook |
| Copilot Connector and Plugin Governance | connector-inventory, approval-register, data-flow-attestations | FINRA 3110, OCC 2011-12, DORA | finra-3110, glba-501b, sox-302-404, occ-2011-12, ffiec-it-handbook, interagency-ai-guidance, dora |
| Risk-Tiered Rollout Automation | wave-readiness-log, approval-history, rollout-health-dashboard | OCC 2011-12, FINRA 3110, DORA | finra-3110, glba-501b, sox-302-404, occ-2011-12, ffiec-it-handbook, interagency-ai-guidance, dora |
| Regulatory Compliance Dashboard | control-status-snapshot, framework-coverage-matrix, dashboard-export | FINRA 4511, FINRA 3110, SEC 17a-4, OCC 2011-12, DORA, GLBA 501(b) | finra-3110, finra-4511, sec-17a4, sec-reg-sp, glba-501b, sox-302-404, occ-2011-12, sr-11-7, ffiec-it-handbook, dora |
| DORA Operational Resilience Monitor | service-health-log, incident-register, resilience-test-results | DORA, OCC 2011-12, FFIEC IT Handbook | glba-501b, sox-302-404, occ-2011-12, ffiec-it-handbook, dora, gdpr |
| Communication Compliance Configurator | policy-template-export, reviewer-queue-metrics, lexicon-update-log | FINRA 2210, FINRA 3110, SEC Reg BI, FCA SYSC 10, GLBA 501(b), SOX 302/404 | finra-2210, finra-3110, sec-reg-bi, fca-sysc-10, glba-501b, sox-302-404 |
| Copilot Pages and Notebooks Compliance Gap Monitor | gap-findings, compensating-control-log, preservation-exception-register | SEC 17a-4, FINRA 4511, SOX 404 | finra-4511, sec-17a3, sec-17a4, glba-501b, sox-302-404 |
| Item-Level Oversharing Scanner | item-oversharing-findings, risk-scored-report, remediation-actions | GLBA 501(b), SEC Reg S-P, FINRA 4511, FFIEC IT Handbook, SOX 302/404 | finra-4511, sec-reg-sp, glba-501b, sox-302-404, ffiec-it-handbook |
| SharePoint Permissions Drift Detection | drift-report, baseline-snapshot, reversion-log | GLBA 501(b), SEC Reg S-P, FINRA 4511, FFIEC IT Handbook, SOX 302/404 | finra-4511, sec-reg-sp, glba-501b, sox-302-404, ffiec-it-handbook |
| Entra Access Reviews Automation | access-review-definitions, review-decisions, applied-actions | GLBA 501(b), SEC Reg S-P, FINRA 4511, FFIEC IT Handbook, SOX 302/404 | finra-4511, sec-reg-sp, glba-501b, sox-302-404, ffiec-it-handbook |
| Agent Lifecycle and Deployment Governance | agent-registry, approval-register, sharing-policy-audit | FINRA 3110, SEC Reg S-P, GLBA 501(b), OCC 2011-12, SOX 302/404, FFIEC IT Handbook, Interagency AI Guidance, DORA | finra-3110, sec-reg-sp, glba-501b, sox-302-404, occ-2011-12, ffiec-it-handbook, interagency-ai-guidance, dora |

Unified evidence export is orchestrated through `scripts/deployment/Export-CopilotGovernanceEvidence.ps1` and validated with `scripts/deployment/Test-EvidenceIntegrity.ps1`.

Framework playbook links published into `site-docs/` are pinned to `FSI-CopilotGov` commit `e0fb7b769529dcc008cc2066402cdabae4f369cf`.
