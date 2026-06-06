# Freamon Pass-2 Verification — Solution 16: Item-Level Oversharing Scanner

**Verifier:** Freamon (Research / Verification)
**Pass:** 2 (second-opinion re-check against current MS Learn)
**Date:** 2026-06-05
**Scope:** README.md, docs/*.md, scripts/*.ps1, config/*.json

---

## VERDICT: CLEAN — no product/feature inaccuracies found (pass-2 re-verification).

All verifiable Microsoft product and feature claims were confirmed accurate against current Microsoft Learn documentation. PnP.PowerShell-specific version constraints (7.4 requirement, Azure Automation module limit) are community-library claims not directly verifiable via MS Learn (PnP.PowerShell is not a Microsoft-provided module and MS Learn explicitly notes this), and were appropriately not flagged.

---

## Spot-Check Citations

| Claim verified | File:location | Result | Citation |
|---|---|---|---|
| "`Files.Read.All` is the least-privileged application permission" for listing driveItem permissions | `docs/prerequisites.md:39` | ✅ CONFIRMED — MS Learn driveItem permissions table: "Application | Files.Read.All | Files.ReadWrite.All, Sites.Read.All, Sites.ReadWrite.All" — `Files.Read.All` is listed as the least-privileged application permission | https://learn.microsoft.com/en-us/graph/api/driveitem-list-permissions |
| "Microsoft Purview Data Security Posture Management (DSPM) … if using DSPM for AI, document it as DSPM for AI (classic)" | `docs/prerequisites.md:7` | ✅ CONFIRMED — MS Learn article is literally titled "Learn about Data Security Posture Management for AI - (classic)" and states the classic version "is now replaced with a new version" | https://learn.microsoft.com/en-us/purview/dspm-for-ai |
| PnP PowerShell is ".NET 8.0 based" | `docs/prerequisites.md:35` | ✅ CONFIRMED — MS Learn: "PnP PowerShell is a .NET 8.0 based PowerShell Module" | https://learn.microsoft.com/en-us/powershell/sharepoint/sharepoint-pnp/sharepoint-pnp-cmdlets |

---

## Caveats on Non-MS-Learn Claims

The following claims in `docs/prerequisites.md` are about the community PnP.PowerShell module, not a Microsoft-provided product. MS Learn explicitly states "It is not a Microsoft-provided module so there's no SLA or direct support for this open-source component from Microsoft." These claims were **not flagged** because they cannot be verified or refuted via MS Learn.

- "PnP.PowerShell 3.x requires PowerShell 7.4 or later" — community module requirement, not on MS Learn
- "The multi-tenant PnP app was removed in September 2024" — community announcement, not on MS Learn  
- "Azure Automation environments are limited to PnP.PowerShell 2.12.0 (PowerShell 7.2 only)" — community compatibility note

These should be validated against the PnP GitHub repository (https://github.com/pnp/powershell) rather than MS Learn if a future pass targets them.

---

## Notes

- The `SharePoint Advanced Management` licensing recommendation in prerequisites is consistent with the product as a premium add-on for SharePoint Online. Not independently spot-checked as it is a general recommendation (not a specific feature claim).
- The driveItem permissions note ("SharePoint Embedded requires `FileStorageContainer.Selected`") was found on MS Learn. The solution scans standard SharePoint document libraries, not SharePoint Embedded containers directly, so this is not a gap in the prerequisites documentation.
