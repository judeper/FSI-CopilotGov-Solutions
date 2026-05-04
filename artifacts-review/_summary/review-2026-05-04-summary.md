# Accuracy Review Summary — 2026-05-04

- **Repository:** `judeper/FSI-CopilotGov-Solutions`
- **Label:** `accuracy-review-2026-05`
- **Reviewer:** Copilot CLI accuracy-review fleet (24 sub-agents, parallel)
- **Verification source:** `learn.microsoft.com` via live `web_fetch`

## Grand totals

| Metric | Value |
|--------|-------|
| Solutions reviewed | 24 (23 solutions + 1 cross-cutting) |
| Total files reviewed | 463 |
| Files with at least one finding | 185 |
| GitHub issues created (all states) | 186 |
| Critical findings | 38 |
| Major findings | 279 |
| Minor findings | 29 |
| Style findings | 0 |
| Unverified (fetch failed) | 11 |

## Per-solution breakdown

| ID | Slug | Files reviewed | Files with findings | Critical | Major | Minor | Style | Unverified | Issues |
|----|------|----------------|---------------------|----------|-------|-------|-------|-----------|--------|
| 01 | `01-copilot-readiness-scanner` | 17 | 4 | 0 | 6 | 2 | 0 | 0 | 4 |
| 02 | `02-oversharing-risk-assessment` | 17 | 10 | 1 | 19 | 0 | 0 | 1 | 10 |
| 03 | `03-sensitivity-label-auditor` | 16 | 7 | 3 | 12 | 0 | 0 | 0 | 7 |
| 04 | `04-finra-supervision-workflow` | 27 | 9 | 1 | 15 | 0 | 0 | 0 | 9 |
| 05 | `05-dlp-policy-governance` | 17 | 5 | 0 | 8 | 0 | 0 | 0 | 5 |
| 06 | `06-audit-trail-manager` | 23 | 16 | 0 | 40 | 6 | 0 | 0 | 16 |
| 07 | `07-conditional-access-automation` | 17 | 10 | 12 | 8 | 0 | 0 | 7 | 10 |
| 08 | `08-license-governance-roi` | 17 | 8 | 2 | 7 | 6 | 0 | 0 | 8 |
| 09 | `09-feature-management-controller` | 16 | 12 | 7 | 18 | 0 | 0 | 0 | 12 |
| 10 | `10-connector-plugin-governance` | 16 | 8 | 0 | 10 | 1 | 0 | 0 | 8 |
| 11 | `11-risk-tiered-rollout` | 17 | 3 | 0 | 3 | 2 | 0 | 0 | 3 |
| 12 | `12-regulatory-compliance-dashboard` | 16 | 6 | 0 | 9 | 0 | 0 | 0 | 6 |
| 13 | `13-dora-resilience-monitor` | 17 | 4 | 1 | 4 | 2 | 0 | 0 | 4 |
| 14 | `14-communication-compliance-config` | 17 | 7 | 0 | 11 | 0 | 0 | 0 | 7 |
| 15 | `15-pages-notebooks-gap-monitor` | 17 | 7 | 0 | 8 | 0 | 0 | 0 | 7 |
| 16 | `16-item-level-oversharing-scanner` | 24 | 6 | 0 | 8 | 3 | 0 | 0 | 6 |
| 17 | `17-sharepoint-permissions-drift` | 22 | 8 | 2 | 9 | 1 | 0 | 0 | 8 |
| 18 | `18-entra-access-reviews` | 22 | 12 | 3 | 14 | 4 | 0 | 0 | 12 |
| 19 | `19-copilot-tuning-governance` | 16 | 6 | 0 | 11 | 0 | 0 | 0 | 7 |
| 20 | `20-generative-ai-model-governance-monitor` | 17 | 5 | 0 | 9 | 1 | 0 | 0 | 5 |
| 21 | `21-cross-tenant-agent-federation-auditor` | 17 | 8 | 2 | 15 | 0 | 0 | 0 | 8 |
| 22 | `22-pages-notebooks-retention-tracker` | 17 | 11 | 4 | 20 | 0 | 0 | 0 | 11 |
| 23 | `23-copilot-studio-lifecycle-tracker` | 17 | 4 | 0 | 7 | 0 | 0 | 3 | 4 |
| X-CUT | `_cross-cutting` | 44 | 9 | 0 | 8 | 1 | 0 | 0 | 9 |

## All GitHub issues by solution

### 01 — `01-copilot-readiness-scanner`

| # | State | Title |
|---|-------|-------|
| [#11](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/11) | 🟢 open | [01] solutions/01-copilot-readiness-scanner/CHANGELOG.md — accuracy review (2026-05-04) |
| [#41](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/41) | 🟢 open | [01] solutions/01-copilot-readiness-scanner/README.md — accuracy review (2026-05-04) |
| [#43](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/43) | 🟢 open | [01] solutions/01-copilot-readiness-scanner/docs/architecture.md — accuracy review (2026-05-04) |
| [#44](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/44) | 🟢 open | [01] solutions/01-copilot-readiness-scanner/docs/prerequisites.md — accuracy review (2026-05-04) |

### 02 — `02-oversharing-risk-assessment`

| # | State | Title |
|---|-------|-------|
| [#91](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/91) | 🟢 open | [02] solutions\02-oversharing-risk-assessment\DELIVERY-CHECKLIST.md — accuracy review (2026-05-04) |
| [#93](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/93) | 🟢 open | [02] solutions\02-oversharing-risk-assessment\README.md — accuracy review (2026-05-04) |
| [#95](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/95) | 🟢 open | [02] solutions\02-oversharing-risk-assessment\docs\architecture.md — accuracy review (2026-05-04) |
| [#97](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/97) | 🟢 open | [02] solutions\02-oversharing-risk-assessment\docs\deployment-guide.md — accuracy review (2026-05-04) |
| [#99](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/99) | 🟢 open | [02] solutions\02-oversharing-risk-assessment\docs\evidence-export.md — accuracy review (2026-05-04) |
| [#101](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/101) | 🟢 open | [02] solutions\02-oversharing-risk-assessment\docs\prerequisites.md — accuracy review (2026-05-04) |
| [#103](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/103) | 🟢 open | [02] solutions\02-oversharing-risk-assessment\docs\troubleshooting.md — accuracy review (2026-05-04) |
| [#105](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/105) | 🟢 open | [02] solutions\02-oversharing-risk-assessment\scripts\Deploy-Solution.ps1 — accuracy review (2026-05-04) |
| [#107](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/107) | 🟢 open | [02] solutions\02-oversharing-risk-assessment\scripts\Export-Evidence.ps1 — accuracy review (2026-05-04) |
| [#109](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/109) | 🟢 open | [02] solutions\02-oversharing-risk-assessment\scripts\Monitor-Compliance.ps1 — accuracy review (2026-05-04) |

### 03 — `03-sensitivity-label-auditor`

| # | State | Title |
|---|-------|-------|
| [#5](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/5) | 🟢 open | [03] solutions/03-sensitivity-label-auditor/README.md — accuracy review (2026-05-04) |
| [#19](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/19) | 🟢 open | [03] solutions/03-sensitivity-label-auditor/config/default-config.json — accuracy review (2026-05-04) |
| [#21](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/21) | 🟢 open | [03] solutions/03-sensitivity-label-auditor/docs/architecture.md — accuracy review (2026-05-04) |
| [#24](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/24) | 🟢 open | [03] solutions/03-sensitivity-label-auditor/docs/prerequisites.md — accuracy review (2026-05-04) |
| [#26](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/26) | 🟢 open | [03] solutions/03-sensitivity-label-auditor/docs/troubleshooting.md — accuracy review (2026-05-04) |
| [#28](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/28) | 🟢 open | [03] solutions/03-sensitivity-label-auditor/scripts/Deploy-Solution.ps1 — accuracy review (2026-05-04) |
| [#30](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/30) | 🟢 open | [03] solutions/03-sensitivity-label-auditor/scripts/Monitor-Compliance.ps1 — accuracy review (2026-05-04) |

### 04 — `04-finra-supervision-workflow`

| # | State | Title |
|---|-------|-------|
| [#145](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/145) | 🟢 open | [04] solutions\04-finra-supervision-workflow\README.md — accuracy review (2026-05-04) |
| [#148](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/148) | 🟢 open | [04] solutions\04-finra-supervision-workflow\DELIVERY-CHECKLIST.md — accuracy review (2026-05-04) |
| [#151](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/151) | 🟢 open | [04] solutions\04-finra-supervision-workflow\docs\architecture.md — accuracy review (2026-05-04) |
| [#152](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/152) | 🟢 open | [04] solutions\04-finra-supervision-workflow\docs\deployment-guide.md — accuracy review (2026-05-04) |
| [#153](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/153) | 🟢 open | [04] solutions\04-finra-supervision-workflow\docs\prerequisites.md — accuracy review (2026-05-04) |
| [#154](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/154) | 🟢 open | [04] solutions\04-finra-supervision-workflow\docs\troubleshooting.md — accuracy review (2026-05-04) |
| [#155](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/155) | 🟢 open | [04] solutions\04-finra-supervision-workflow\config\default-config.json — accuracy review (2026-05-04) |
| [#156](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/156) | 🟢 open | [04] solutions\04-finra-supervision-workflow\scripts\Deploy-Solution.ps1 — accuracy review (2026-05-04) |
| [#157](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/157) | 🟢 open | [04] solutions\04-finra-supervision-workflow\scripts\Export-Evidence.ps1 — accuracy review (2026-05-04) |

### 05 — `05-dlp-policy-governance`

| # | State | Title |
|---|-------|-------|
| [#22](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/22) | 🟢 open | [05] solutions/05-dlp-policy-governance/README.md — accuracy review (2026-05-04) |
| [#25](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/25) | 🟢 open | [05] solutions/05-dlp-policy-governance/config/default-config.json — accuracy review (2026-05-04) |
| [#27](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/27) | 🟢 open | [05] solutions/05-dlp-policy-governance/docs/architecture.md — accuracy review (2026-05-04) |
| [#31](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/31) | 🟢 open | [05] solutions/05-dlp-policy-governance/docs/evidence-export.md — accuracy review (2026-05-04) |
| [#33](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/33) | 🟢 open | [05] solutions/05-dlp-policy-governance/docs/prerequisites.md — accuracy review (2026-05-04) |

### 06 — `06-audit-trail-manager`

| # | State | Title |
|---|-------|-------|
| [#53](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/53) | 🟢 open | [06] solutions/06-audit-trail-manager/DELIVERY-CHECKLIST.md — accuracy review (2026-05-04) |
| [#57](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/57) | 🟢 open | [06] solutions/06-audit-trail-manager/README.md — accuracy review (2026-05-04) |
| [#61](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/61) | 🟢 open | [06] solutions/06-audit-trail-manager/docs/architecture.md — accuracy review (2026-05-04) |
| [#65](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/65) | 🟢 open | [06] solutions/06-audit-trail-manager/docs/deployment-guide.md — accuracy review (2026-05-04) |
| [#68](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/68) | 🟢 open | [06] solutions/06-audit-trail-manager/docs/evidence-export.md — accuracy review (2026-05-04) |
| [#70](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/70) | 🟢 open | [06] solutions/06-audit-trail-manager/docs/prerequisites.md — accuracy review (2026-05-04) |
| [#71](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/71) | 🟢 open | [06] solutions/06-audit-trail-manager/docs/troubleshooting.md — accuracy review (2026-05-04) |
| [#76](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/76) | 🟢 open | [06] solutions/06-audit-trail-manager/config/baseline.json — accuracy review (2026-05-04) |
| [#78](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/78) | 🟢 open | [06] solutions/06-audit-trail-manager/config/default-config.json — accuracy review (2026-05-04) |
| [#80](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/80) | 🟢 open | [06] solutions/06-audit-trail-manager/config/recommended.json — accuracy review (2026-05-04) |
| [#83](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/83) | 🟢 open | [06] solutions/06-audit-trail-manager/config/regulated.json — accuracy review (2026-05-04) |
| [#86](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/86) | 🟢 open | [06] solutions/06-audit-trail-manager/artifacts/evidence-test/audit-log-completeness.json — accuracy review (2026-05-04) |
| [#88](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/88) | 🟢 open | [06] solutions/06-audit-trail-manager/artifacts/evidence-test/retention-policy-state.json — accuracy review (2026-05-04) |
| [#89](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/89) | 🟢 open | [06] solutions/06-audit-trail-manager/scripts/Deploy-Solution.ps1 — accuracy review (2026-05-04) |
| [#90](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/90) | 🟢 open | [06] solutions/06-audit-trail-manager/scripts/Export-Evidence.ps1 — accuracy review (2026-05-04) |
| [#92](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/92) | 🟢 open | [06] solutions/06-audit-trail-manager/scripts/Monitor-Compliance.ps1 — accuracy review (2026-05-04) |

### 07 — `07-conditional-access-automation`

| # | State | Title |
|---|-------|-------|
| [#116](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/116) | 🟢 open | [07] solutions/07-conditional-access-automation/README.md — accuracy review (2026-05-04) |
| [#119](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/119) | 🟢 open | [07] solutions/07-conditional-access-automation/config/default-config.json — accuracy review (2026-05-04) |
| [#122](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/122) | 🟢 open | [07] solutions/07-conditional-access-automation/config/baseline.json — accuracy review (2026-05-04) |
| [#125](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/125) | 🟢 open | [07] solutions/07-conditional-access-automation/config/recommended.json — accuracy review (2026-05-04) |
| [#129](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/129) | 🟢 open | [07] solutions/07-conditional-access-automation/config/regulated.json — accuracy review (2026-05-04) |
| [#133](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/133) | 🟢 open | [07] solutions/07-conditional-access-automation/docs/deployment-guide.md — accuracy review (2026-05-04) |
| [#136](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/136) | 🟢 open | [07] solutions/07-conditional-access-automation/docs/prerequisites.md — accuracy review (2026-05-04) |
| [#139](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/139) | 🟢 open | [07] solutions/07-conditional-access-automation/scripts/Deploy-Solution.ps1 — accuracy review (2026-05-04) |
| [#143](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/143) | 🟢 open | [07] solutions/07-conditional-access-automation/scripts/Monitor-Compliance.ps1 — accuracy review (2026-05-04) |
| [#149](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/149) | 🟢 open | [07] solutions/07-conditional-access-automation/scripts/Export-Evidence.ps1 — accuracy review (2026-05-04) |

### 08 — `08-license-governance-roi`

| # | State | Title |
|---|-------|-------|
| [#94](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/94) | 🟢 open | [08] solutions\08-license-governance-roi\README.md — accuracy review (2026-05-04) |
| [#96](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/96) | 🟢 open | [08] solutions\08-license-governance-roi\DELIVERY-CHECKLIST.md — accuracy review (2026-05-04) |
| [#98](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/98) | 🟢 open | [08] solutions\08-license-governance-roi\docs\architecture.md — accuracy review (2026-05-04) |
| [#100](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/100) | 🟢 open | [08] solutions\08-license-governance-roi\docs\deployment-guide.md — accuracy review (2026-05-04) |
| [#102](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/102) | 🟢 open | [08] solutions\08-license-governance-roi\docs\prerequisites.md — accuracy review (2026-05-04) |
| [#104](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/104) | 🟢 open | [08] solutions\08-license-governance-roi\docs\troubleshooting.md — accuracy review (2026-05-04) |
| [#106](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/106) | 🟢 open | [08] solutions\08-license-governance-roi\scripts\Deploy-Solution.ps1 — accuracy review (2026-05-04) |
| [#108](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/108) | 🟢 open | [08] solutions\08-license-governance-roi\scripts\Monitor-Compliance.ps1 — accuracy review (2026-05-04) |

### 09 — `09-feature-management-controller`

| # | State | Title |
|---|-------|-------|
| [#6](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/6) | 🟢 open | [09] solutions/09-feature-management-controller/README.md — accuracy review (2026-05-04) |
| [#9](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/9) | 🟢 open | [09] solutions/09-feature-management-controller/CHANGELOG.md — accuracy review (2026-05-04) |
| [#10](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/10) | 🟢 open | [09] solutions/09-feature-management-controller/DELIVERY-CHECKLIST.md — accuracy review (2026-05-04) |
| [#12](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/12) | 🟢 open | [09] solutions/09-feature-management-controller/docs/architecture.md — accuracy review (2026-05-04) |
| [#13](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/13) | 🟢 open | [09] solutions/09-feature-management-controller/docs/deployment-guide.md — accuracy review (2026-05-04) |
| [#14](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/14) | 🟢 open | [09] solutions/09-feature-management-controller/docs/evidence-export.md — accuracy review (2026-05-04) |
| [#15](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/15) | 🟢 open | [09] solutions/09-feature-management-controller/docs/prerequisites.md — accuracy review (2026-05-04) |
| [#16](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/16) | 🟢 open | [09] solutions/09-feature-management-controller/docs/troubleshooting.md — accuracy review (2026-05-04) |
| [#17](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/17) | 🟢 open | [09] solutions/09-feature-management-controller/config/default-config.json — accuracy review (2026-05-04) |
| [#18](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/18) | 🟢 open | [09] solutions/09-feature-management-controller/config/baseline.json — accuracy review (2026-05-04) |
| [#20](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/20) | 🟢 open | [09] solutions/09-feature-management-controller/config/recommended.json — accuracy review (2026-05-04) |
| [#23](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/23) | 🟢 open | [09] solutions/09-feature-management-controller/config/regulated.json — accuracy review (2026-05-04) |

### 10 — `10-connector-plugin-governance`

| # | State | Title |
|---|-------|-------|
| [#110](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/110) | 🟢 open | [10] solutions/10-connector-plugin-governance/README.md — accuracy review (2026-05-04) |
| [#112](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/112) | 🟢 open | [10] solutions/10-connector-plugin-governance/config/default-config.json — accuracy review (2026-05-04) |
| [#114](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/114) | 🟢 open | [10] solutions/10-connector-plugin-governance/DELIVERY-CHECKLIST.md — accuracy review (2026-05-04) |
| [#117](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/117) | 🟢 open | [10] solutions/10-connector-plugin-governance/docs/architecture.md — accuracy review (2026-05-04) |
| [#120](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/120) | 🟢 open | [10] solutions/10-connector-plugin-governance/docs/deployment-guide.md — accuracy review (2026-05-04) |
| [#123](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/123) | 🟢 open | [10] solutions/10-connector-plugin-governance/docs/prerequisites.md — accuracy review (2026-05-04) |
| [#128](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/128) | 🟢 open | [10] solutions/10-connector-plugin-governance/docs/troubleshooting.md — accuracy review (2026-05-04) |
| [#132](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/132) | 🟢 open | [10] solutions/10-connector-plugin-governance/scripts/Deploy-Solution.ps1 — accuracy review (2026-05-04) |

### 11 — `11-risk-tiered-rollout`

| # | State | Title |
|---|-------|-------|
| [#4](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/4) | 🟢 open | [11] solutions/11-risk-tiered-rollout/README.md — accuracy review (2026-05-04) |
| [#7](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/7) | 🟢 open | [11] solutions/11-risk-tiered-rollout/config/default-config.json — accuracy review (2026-05-04) |
| [#8](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/8) | 🟢 open | [11] solutions/11-risk-tiered-rollout/docs/prerequisites.md — accuracy review (2026-05-04) |

### 12 — `12-regulatory-compliance-dashboard`

| # | State | Title |
|---|-------|-------|
| [#29](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/29) | 🟢 open | [12] solutions/12-regulatory-compliance-dashboard/README.md — accuracy review (2026-05-04) |
| [#32](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/32) | 🟢 open | [12] solutions/12-regulatory-compliance-dashboard/DELIVERY-CHECKLIST.md — accuracy review (2026-05-04) |
| [#34](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/34) | 🟢 open | [12] solutions/12-regulatory-compliance-dashboard/docs/architecture.md — accuracy review (2026-05-04) |
| [#35](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/35) | 🟢 open | [12] solutions/12-regulatory-compliance-dashboard/docs/deployment-guide.md — accuracy review (2026-05-04) |
| [#36](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/36) | 🟢 open | [12] solutions/12-regulatory-compliance-dashboard/docs/prerequisites.md — accuracy review (2026-05-04) |
| [#37](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/37) | 🟢 open | [12] solutions/12-regulatory-compliance-dashboard/docs/troubleshooting.md — accuracy review (2026-05-04) |

### 13 — `13-dora-resilience-monitor`

| # | State | Title |
|---|-------|-------|
| [#140](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/140) | 🟢 open | [13] solutions/13-dora-resilience-monitor/README.md — accuracy review (2026-05-04) |
| [#142](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/142) | 🟢 open | [13] solutions/13-dora-resilience-monitor/docs/architecture.md — accuracy review (2026-05-04) |
| [#147](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/147) | 🟢 open | [13] solutions/13-dora-resilience-monitor/docs/prerequisites.md — accuracy review (2026-05-04) |
| [#150](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/150) | 🟢 open | [13] solutions/13-dora-resilience-monitor/scripts/Monitor-Compliance.ps1 — accuracy review (2026-05-04) |

### 14 — `14-communication-compliance-config`

| # | State | Title |
|---|-------|-------|
| [#38](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/38) | 🟢 open | [14] solutions\14-communication-compliance-config\README.md — accuracy review (2026-05-04) |
| [#39](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/39) | 🟢 open | [14] solutions\14-communication-compliance-config\CHANGELOG.md — accuracy review (2026-05-04) |
| [#40](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/40) | 🟢 open | [14] solutions\14-communication-compliance-config\DELIVERY-CHECKLIST.md — accuracy review (2026-05-04) |
| [#42](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/42) | 🟢 open | [14] solutions\14-communication-compliance-config\docs\architecture.md — accuracy review (2026-05-04) |
| [#166](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/166) | 🟢 open | [14] solutions\14-communication-compliance-config\docs\evidence-export.md — accuracy review (2026-05-04) |
| [#167](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/167) | 🟢 open | [14] solutions\14-communication-compliance-config\docs\deployment-guide.md — accuracy review (2026-05-04) |
| [#169](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/169) | 🟢 open | [14] solutions\14-communication-compliance-config\docs\prerequisites.md — accuracy review (2026-05-04) |

### 15 — `15-pages-notebooks-gap-monitor`

| # | State | Title |
|---|-------|-------|
| [#159](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/159) | 🟢 open | [15] solutions/15-pages-notebooks-gap-monitor/README.md — accuracy review (2026-05-04) |
| [#160](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/160) | 🟢 open | [15] solutions/15-pages-notebooks-gap-monitor/docs/architecture.md — accuracy review (2026-05-04) |
| [#161](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/161) | 🟢 open | [15] solutions/15-pages-notebooks-gap-monitor/docs/prerequisites.md — accuracy review (2026-05-04) |
| [#162](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/162) | 🟢 open | [15] solutions/15-pages-notebooks-gap-monitor/docs/troubleshooting.md — accuracy review (2026-05-04) |
| [#163](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/163) | 🟢 open | [15] solutions/15-pages-notebooks-gap-monitor/scripts/Deploy-Solution.ps1 — accuracy review (2026-05-04) |
| [#164](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/164) | 🟢 open | [15] solutions/15-pages-notebooks-gap-monitor/scripts/Monitor-Compliance.ps1 — accuracy review (2026-05-04) |
| [#165](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/165) | 🟢 open | [15] solutions/15-pages-notebooks-gap-monitor/scripts/Export-Evidence.ps1 — accuracy review (2026-05-04) |

### 16 — `16-item-level-oversharing-scanner`

| # | State | Title |
|---|-------|-------|
| [#180](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/180) | 🟢 open | [16] solutions/16-item-level-oversharing-scanner/README.md — accuracy review (2026-05-04) |
| [#181](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/181) | 🟢 open | [16] solutions/16-item-level-oversharing-scanner/DELIVERY-CHECKLIST.md — accuracy review (2026-05-04) |
| [#182](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/182) | 🟢 open | [16] solutions/16-item-level-oversharing-scanner/docs/evidence-export.md — accuracy review (2026-05-04) |
| [#183](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/183) | 🟢 open | [16] solutions/16-item-level-oversharing-scanner/docs/prerequisites.md — accuracy review (2026-05-04) |
| [#184](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/184) | 🟢 open | [16] solutions/16-item-level-oversharing-scanner/docs/troubleshooting.md — accuracy review (2026-05-04) |
| [#185](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/185) | 🟢 open | [16] solutions/16-item-level-oversharing-scanner/scripts/Export-Evidence.ps1 — accuracy review (2026-05-04) |

### 17 — `17-sharepoint-permissions-drift`

| # | State | Title |
|---|-------|-------|
| [#51](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/51) | 🟢 open | [17] solutions/17-sharepoint-permissions-drift/DELIVERY-CHECKLIST.md — accuracy review (2026-05-04) |
| [#54](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/54) | 🟢 open | [17] solutions/17-sharepoint-permissions-drift/docs/prerequisites.md — accuracy review (2026-05-04) |
| [#55](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/55) | 🟢 open | [17] solutions/17-sharepoint-permissions-drift/docs/troubleshooting.md — accuracy review (2026-05-04) |
| [#58](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/58) | 🟢 open | [17] solutions/17-sharepoint-permissions-drift/scripts/Deploy-Solution.ps1 — accuracy review (2026-05-04) |
| [#59](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/59) | 🟢 open | [17] solutions/17-sharepoint-permissions-drift/scripts/Export-Evidence.ps1 — accuracy review (2026-05-04) |
| [#62](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/62) | 🟢 open | [17] solutions/17-sharepoint-permissions-drift/scripts/Export-DriftEvidence.ps1 — accuracy review (2026-05-04) |
| [#64](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/64) | 🟢 open | [17] solutions/17-sharepoint-permissions-drift/scripts/Invoke-DriftScan.ps1 — accuracy review (2026-05-04) |
| [#66](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/66) | 🟢 open | [17] solutions/17-sharepoint-permissions-drift/scripts/Monitor-Compliance.ps1 — accuracy review (2026-05-04) |

### 18 — `18-entra-access-reviews`

| # | State | Title |
|---|-------|-------|
| [#45](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/45) | 🟢 open | [18] solutions/18-entra-access-reviews/docs/prerequisites.md — accuracy review (2026-05-04) |
| [#46](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/46) | 🟢 open | [18] solutions/18-entra-access-reviews/docs/troubleshooting.md — accuracy review (2026-05-04) |
| [#47](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/47) | 🟢 open | [18] solutions/18-entra-access-reviews/scripts/Apply-ReviewDecisions.ps1 — accuracy review (2026-05-04) |
| [#48](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/48) | 🟢 open | [18] solutions/18-entra-access-reviews/scripts/Deploy-Solution.ps1 — accuracy review (2026-05-04) |
| [#49](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/49) | 🟢 open | [18] solutions/18-entra-access-reviews/scripts/Get-ReviewResults.ps1 — accuracy review (2026-05-04) |
| [#50](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/50) | 🟢 open | [18] solutions/18-entra-access-reviews/scripts/Invoke-RiskTriagedReviews.ps1 — accuracy review (2026-05-04) |
| [#124](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/124) | 🟢 open | [18] solutions/18-entra-access-reviews/README.md — accuracy review (2026-05-04) |
| [#127](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/127) | 🟢 open | [18] solutions/18-entra-access-reviews/DELIVERY-CHECKLIST.md — accuracy review (2026-05-04) |
| [#131](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/131) | 🟢 open | [18] solutions/18-entra-access-reviews/docs/architecture.md — accuracy review (2026-05-04) |
| [#135](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/135) | 🟢 open | [18] solutions/18-entra-access-reviews/docs/deployment-guide.md — accuracy review (2026-05-04) |
| [#138](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/138) | 🟢 open | [18] solutions/18-entra-access-reviews/docs/evidence-export.md — accuracy review (2026-05-04) |
| [#144](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/144) | 🟢 open | [18] solutions/18-entra-access-reviews/scripts/New-AccessReview.ps1 — accuracy review (2026-05-04) |

### 19 — `19-copilot-tuning-governance`

| # | State | Title |
|---|-------|-------|
| [#158](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/158) | 🟢 open | [19] solutions/19-copilot-tuning-governance/README.md — accuracy review (2026-05-04) |
| [#186](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/186) | ⚫ closed | [19] solutions/19-copilot-tuning-governance/README.md — accuracy review (2026-05-04) |
| [#187](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/187) | 🟢 open | [19] solutions/19-copilot-tuning-governance/docs/architecture.md — accuracy review (2026-05-04) |
| [#188](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/188) | 🟢 open | [19] solutions/19-copilot-tuning-governance/DELIVERY-CHECKLIST.md — accuracy review (2026-05-04) |
| [#189](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/189) | 🟢 open | [19] solutions/19-copilot-tuning-governance/docs/deployment-guide.md — accuracy review (2026-05-04) |
| [#190](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/190) | 🟢 open | [19] solutions/19-copilot-tuning-governance/docs/prerequisites.md — accuracy review (2026-05-04) |
| [#191](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/191) | 🟢 open | [19] solutions/19-copilot-tuning-governance/docs/troubleshooting.md — accuracy review (2026-05-04) |

### 20 — `20-generative-ai-model-governance-monitor`

| # | State | Title |
|---|-------|-------|
| [#81](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/81) | 🟢 open | [20] solutions\20-generative-ai-model-governance-monitor\README.md — accuracy review (2026-05-04) |
| [#82](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/82) | 🟢 open | [20] solutions\20-generative-ai-model-governance-monitor\config\default-config.json — accuracy review (2026-05-04) |
| [#84](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/84) | 🟢 open | [20] solutions\20-generative-ai-model-governance-monitor\docs\architecture.md — accuracy review (2026-05-04) |
| [#85](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/85) | 🟢 open | [20] solutions\20-generative-ai-model-governance-monitor\docs\evidence-export.md — accuracy review (2026-05-04) |
| [#87](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/87) | 🟢 open | [20] solutions\20-generative-ai-model-governance-monitor\docs\prerequisites.md — accuracy review (2026-05-04) |

### 21 — `21-cross-tenant-agent-federation-auditor`

| # | State | Title |
|---|-------|-------|
| [#52](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/52) | 🟢 open | [21] solutions/21-cross-tenant-agent-federation-auditor/README.md — accuracy review (2026-05-04) |
| [#56](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/56) | 🟢 open | [21] solutions/21-cross-tenant-agent-federation-auditor/CHANGELOG.md — accuracy review (2026-05-04) |
| [#60](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/60) | 🟢 open | [21] solutions/21-cross-tenant-agent-federation-auditor/DELIVERY-CHECKLIST.md — accuracy review (2026-05-04) |
| [#63](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/63) | 🟢 open | [21] solutions/21-cross-tenant-agent-federation-auditor/docs/architecture.md — accuracy review (2026-05-04) |
| [#67](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/67) | 🟢 open | [21] solutions/21-cross-tenant-agent-federation-auditor/docs/deployment-guide.md — accuracy review (2026-05-04) |
| [#69](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/69) | 🟢 open | [21] solutions/21-cross-tenant-agent-federation-auditor/docs/evidence-export.md — accuracy review (2026-05-04) |
| [#72](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/72) | 🟢 open | [21] solutions/21-cross-tenant-agent-federation-auditor/docs/prerequisites.md — accuracy review (2026-05-04) |
| [#74](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/74) | 🟢 open | [21] solutions/21-cross-tenant-agent-federation-auditor/scripts/Monitor-Compliance.ps1 — accuracy review (2026-05-04) |

### 22 — `22-pages-notebooks-retention-tracker`

| # | State | Title |
|---|-------|-------|
| [#111](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/111) | 🟢 open | [22] solutions/22-pages-notebooks-retention-tracker/README.md — accuracy review (2026-05-04) |
| [#113](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/113) | 🟢 open | [22] solutions/22-pages-notebooks-retention-tracker/CHANGELOG.md — accuracy review (2026-05-04) |
| [#115](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/115) | 🟢 open | [22] solutions/22-pages-notebooks-retention-tracker/DELIVERY-CHECKLIST.md — accuracy review (2026-05-04) |
| [#118](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/118) | 🟢 open | [22] solutions/22-pages-notebooks-retention-tracker/docs/architecture.md — accuracy review (2026-05-04) |
| [#121](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/121) | 🟢 open | [22] solutions/22-pages-notebooks-retention-tracker/docs/deployment-guide.md — accuracy review (2026-05-04) |
| [#126](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/126) | 🟢 open | [22] solutions/22-pages-notebooks-retention-tracker/docs/evidence-export.md — accuracy review (2026-05-04) |
| [#130](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/130) | 🟢 open | [22] solutions/22-pages-notebooks-retention-tracker/docs/prerequisites.md — accuracy review (2026-05-04) |
| [#134](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/134) | 🟢 open | [22] solutions/22-pages-notebooks-retention-tracker/docs/troubleshooting.md — accuracy review (2026-05-04) |
| [#137](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/137) | 🟢 open | [22] solutions/22-pages-notebooks-retention-tracker/scripts/Deploy-Solution.ps1 — accuracy review (2026-05-04) |
| [#141](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/141) | 🟢 open | [22] solutions/22-pages-notebooks-retention-tracker/scripts/Export-Evidence.ps1 — accuracy review (2026-05-04) |
| [#146](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/146) | 🟢 open | [22] solutions/22-pages-notebooks-retention-tracker/scripts/Monitor-Compliance.ps1 — accuracy review (2026-05-04) |

### 23 — `23-copilot-studio-lifecycle-tracker`

| # | State | Title |
|---|-------|-------|
| [#73](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/73) | 🟢 open | [23] solutions/23-copilot-studio-lifecycle-tracker/README.md — accuracy review (2026-05-04) |
| [#75](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/75) | 🟢 open | [23] solutions/23-copilot-studio-lifecycle-tracker/docs/architecture.md — accuracy review (2026-05-04) |
| [#77](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/77) | 🟢 open | [23] solutions/23-copilot-studio-lifecycle-tracker/docs/prerequisites.md — accuracy review (2026-05-04) |
| [#79](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/79) | 🟢 open | [23] solutions/23-copilot-studio-lifecycle-tracker/docs/deployment-guide.md — accuracy review (2026-05-04) |

### X-CUT — `_cross-cutting`

| # | State | Title |
|---|-------|-------|
| [#168](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/168) | 🟢 open | [X-CUT] README.md — accuracy review (2026-05-04) |
| [#170](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/170) | 🟢 open | [X-CUT] CHANGELOG.md — accuracy review (2026-05-04) |
| [#171](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/171) | 🟢 open | [X-CUT] data/solution-catalog.json — accuracy review (2026-05-04) |
| [#172](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/172) | 🟢 open | [X-CUT] data/control-coverage.json — accuracy review (2026-05-04) |
| [#173](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/173) | 🟢 open | [X-CUT] docs/reference/examination-readiness.md — accuracy review (2026-05-04) |
| [#174](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/174) | 🟢 open | [X-CUT] scripts/common/GraphAuth.psm1 — accuracy review (2026-05-04) |
| [#175](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/175) | 🟢 open | [X-CUT] scripts/common/PurviewHelpers.psm1 — accuracy review (2026-05-04) |
| [#176](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/176) | 🟢 open | [X-CUT] scripts/common/TeamsNotification.psm1 — accuracy review (2026-05-04) |
| [#177](https://github.com/judeper/FSI-CopilotGov-Solutions/issues/177) | 🟢 open | [X-CUT] scripts/common/EntraHelpers.psm1 — accuracy review (2026-05-04) |

## Notes

- All findings are advisory; the repository remains a documentation-first scaffold and no solution files were modified by this review.
- Each per-solution findings report is at `artifacts-review/<slug>/review-2026-05-04.md` and contains the verbatim Microsoft Learn citations, last-updated dates, and quoted source text.
- Solutions 16 and 19 originally hit GitHub Enterprise Managed User HTTP 403 errors during inline issue creation; the issues were recovered post-flight via REST and a single duplicate (`#186`) was closed.
- One closed issue (`#186`) is a duplicate of `#158` (solution 19 README) created during recovery; it is closed and references the original.
