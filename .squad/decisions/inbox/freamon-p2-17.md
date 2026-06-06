# Freamon Pass-2 Verification Report — Solution 17: SharePoint Permissions Drift Detection

**Date:** 2026-06-05 | **Pass:** 2 (re-verification) | **Verifier:** Freamon (Research/Verification)

---

## Findings

| File:line | Current text | Issue | Correct per MS Learn | Citation URL | Severity |
|-----------|-------------|-------|----------------------|--------------|----------|
| `docs/architecture.md:49` | "specifically the Permission state reports, Sharing links report, and EEEU (Everyone Except External Users) insights" | "Permission state reports" is not the current official report name in SharePoint Advanced Management Data Access Governance. The current name is "Site permissions" report (snapshot: "Site permissions across your organization"). No report named "Permission state reports" appears in current MS Learn documentation. "Sharing links report" ✓ and "EEEU" ✓ are correct. | Current report names (as of 2026-06): **Snapshot reports:** "Site permissions across your organization", "Sensitivity labels for files"; **Activity reports:** "Sharing links reports", "Shared with 'Everyone except external users' (EEEU)" reports | https://learn.microsoft.com/sharepoint/data-access-governance-reports | minor |

---

## Spot-Check Citations (Claims Verified Correct)

1. **`PnP.PowerShell` is a .NET 8.0 based module** — `docs/prerequisites.md:37` note about v3.x and .NET 8.0 is consistent with MS Learn. Citation: https://learn.microsoft.com/powershell/sharepoint/sharepoint-pnp/sharepoint-pnp-cmdlets

2. **Graph permissions `Files.Read.All`, `Sites.Read.All`, `Sites.FullControl.All`, `Mail.Send`, `User.Read.All`, `GroupMember.Read.All`** — All valid Graph application permissions for the described operations. SharePoint permission enumeration and mail notification patterns verified consistent with MS Learn Graph permissions reference. Citation: https://learn.microsoft.com/en-us/graph/permissions-reference

3. **`POST /users/{sender}/sendMail` or `POST /me/sendMail`** — Graph mail send endpoints referenced in `docs/architecture.md:55` are correct. Citation: https://learn.microsoft.com/en-us/graph/api/user-sendmail

---

## Verdict

**FINDING: 1 minor** — One report name inaccuracy in `docs/architecture.md`. All other product and feature claims verified against current Microsoft Learn documentation. No blockers or major issues found.
