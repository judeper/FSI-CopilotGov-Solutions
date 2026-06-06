# Freamon Pass-2 Re-Verification: Solution 08 — License Governance and ROI Tracker

**Verified:** 2026-06-05 | **Verifier:** Freamon (Research / Verification) | **Pass:** 2 (second-opinion)

---

## VERDICT: 1 MINOR finding — outdated billing unit terminology in two files.

---

## Findings Table

| File:line | Current text | Issue | Correct per MS Learn | Citation URL | Severity |
|---|---|---|---|---|---|
| `README.md:13` | "The Copilot Studio **message meter** is billed at **$0.01 per message**." | Outdated unit. Microsoft changed the Copilot Studio billing currency from *messages* to *Copilot Credits* effective September 1, 2025. The pay-as-you-go meter now counts and bills in *Copilot Credits*, not messages. The rate ($0.01) is unchanged, but the unit name is wrong. | "The Copilot Studio pay-as-you-go meter is billed at **$0.01 per Copilot Credit**." | [Pay-as-you-go meters — Power Platform](https://learn.microsoft.com/en-us/power-platform/admin/pay-as-you-go-meters): "The Copilot Studio pay-as-you-go meter counts the total number of **Copilot credits** consumed by agents… **$0.01 per credit**" | **minor** |
| `docs/architecture.md:128` | "The Copilot Studio **message meter** is billed at **$0.01 per message** for classic bot interactions." | Same outdated unit issue as README.md:13. The per-feature billing rates are now expressed in Copilot Credits per action type (e.g., 1 credit for classic answer, 2 for generative answer), not as a flat rate "per message". | "The Copilot Studio pay-as-you-go meter is billed at **$0.01 per Copilot Credit**. A classic answer costs 1 Copilot Credit; a generative answer costs 2 Copilot Credits." | [Copilot Studio billing rates](https://learn.microsoft.com/en-us/microsoft-copilot-studio/requirements-messages-management#copilot-credits-billing-rates) and [Pay-as-you-go meters](https://learn.microsoft.com/en-us/power-platform/admin/pay-as-you-go-meters) | **minor** |

**Root cause note:** The CHANGELOG (line 8) states "Clarified that $0.01-per-message is the Copilot Studio message meter rate" — this entry from pass-1 is itself outdated because the Microsoft Learn documentation now says "$0.01 per credit." The pass-1 fix updated some "message pack" references but left the "per message" unit in these two locations.

---

## Spot-Check Citations (Claims Confirmed Accurate)

| Claim verified | File | Microsoft Learn source | Result |
|---|---|---|---|
| Prepaid Copilot Studio capacity packs include "25,000 Copilot Credits per month per pack" | README.md:13 | [Use Copilot Studio prepaid capacity packs](https://learn.microsoft.com/en-us/microsoft-copilot-studio/admin-use-capacity-packs): "Each capacity pack is a tenant license that includes **25,000 Copilot Credits per month**." | ✅ Confirmed. |
| `LicenseAssignment.Read.All` is the correct least-privileged permission for `GET /v1.0/subscribedSkus` | docs/prerequisites.md:14 | [List subscribedSkus — Microsoft Graph](https://learn.microsoft.com/en-us/graph/api/subscribedsku-list): least-privileged = `LicenseAssignment.Read.All` | ✅ Confirmed. |
| `GET /v1.0/copilot/reports/getMicrosoft365CopilotUsageUserDetail(period='D30')` endpoint | docs/architecture.md:64 | [copilotReportRoot: getMicrosoft365CopilotUsageUserDetail](https://learn.microsoft.com/en-us/microsoft-365/copilot/extensibility/api/admin-settings/reports/copilotreportroot-getmicrosoft365copilotusageuserdetail) — endpoint is available at both `/v1.0` and `/beta` under `/copilot/reports/` | ✅ Confirmed: v1.0 path is correct. |
| `Reports.Read.All` permission for Copilot usage reports | docs/prerequisites.md:13 | [copilotReportRoot: getMicrosoft365CopilotUsageUserDetail](https://learn.microsoft.com/en-us/microsoft-365/copilot/extensibility/api/admin-settings/reports/copilotreportroot-getmicrosoft365copilotusageuserdetail) — permissions section | ✅ Confirmed. |
| "Starting on September 1, 2025, the common currency for agents changed from *messages* to *Copilot Credits*. There's no change in the quantity per prepaid pack or to the pay-as-you-go rate." — supports the finding above | — | [Copilot Studio licensing](https://learn.microsoft.com/en-us/microsoft-copilot-studio/billing-licensing) | ✅ Confirms the terminology change; the dollar amount ($0.01) remains correct; the unit ("message" → "Copilot Credit") does not. |
