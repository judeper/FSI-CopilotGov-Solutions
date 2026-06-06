# Freamon — History

## Seed (2026-06-05)
- **Project:** FSI-CopilotGov-Solutions — 23 documentation-first governance solutions for M365 Copilot in regulated FSI.
- **User:** Jude. Priority: **accuracy over cost** — cite every correction to Microsoft Learn.
- **My job:** Verify Microsoft product & feature accuracy (feature names, capabilities, licensing, API/cmdlet/Graph references) of each solution vs Microsoft Learn. Produce evidenced findings; I do NOT edit files.
- **Tools:** `microsoft_docs_search`, `microsoft_docs_fetch`, `microsoft_code_sample_search`.
- **Out of scope this assignment:** regulatory/control-mapping accuracy.

## Learnings

### Solution 03 — Sensitivity Label Coverage Auditor (2026-06-05)
- **Recurring error to watch for project-wide:** auto-labeling throughput cap is **100,000 files per TENANT per day**, not "per policy." Solution 03 got this wrong 4×. Source: https://learn.microsoft.com/purview/apply-sensitivity-label-automatically (also: max 100 policies/tenant, 100 locations each).
- **`assignSensitivityLabel` is a METERED Graph API** (billable; metered APIs must be enabled) AND protected; Global cloud only (no USGov L4/L5/DoD/China 21Vianet); least-priv `Files.ReadWrite.All`, higher `Sites.ReadWrite.All`; 202 long-running. https://learn.microsoft.com/graph/api/driveitem-assignsensitivitylabel?view=graph-rest-1.0
- **`extractSensitivityLabels` is v1.0 GA**, least-priv `Files.Read.All`. https://learn.microsoft.com/graph/api/driveitem-extractsensitivitylabels?view=graph-rest-1.0
- **Label-definition enumeration `/security/informationProtection/sensitivityLabels` is beta-only** (microsoft.graph.security namespace), delegated `InformationProtectionPolicy.Read` / app `InformationProtectionPolicy.Read.All`. https://learn.microsoft.com/graph/api/security-informationprotection-list-sensitivitylabels?view=graph-rest-beta
- **Parent labels → label groups migration is real & irreversible**, auto for new tenants from Oct 1 2025, else via Purview portal banner. https://learn.microsoft.com/purview/migrate-sensitivity-label-scheme
- Graph `message` resource has NO first-class sensitivity-label field — Exchange label evidence legitimately needs Purview export / headers / extended properties. This pattern likely repeats in solutions 06/14.
- **Tooling note:** `microsoft_docs_search` outputs are dumped to a temp .txt (50KB+); parse with regex/Substring in PowerShell, not ConvertFrom-Json (multiple JSON roots concatenated — fails).
- Overall solution 03 Microsoft-accuracy is HIGH: only the per-policy cap scoping error was material. Good baseline for grading siblings.

### Solution 02 — Oversharing Risk Assessment (2026-06-05)
- **PnP.PowerShell minimum version moved to 7.4.0** (official install docs). Any repo text saying "7.2 or later" is now wrong — flag as major. Source: https://pnp.github.io/powershell/articles/installation.html
- **PnP.PowerShell is NOT on Microsoft Learn** — it's community/Microsoft-stewarded at pnp.github.io. Use that as authoritative source for PnP version/auth facts and note the source.
- PnP multi-tenant shared app was retired (Sept 2024); users MUST register their own Entra ID app and pass `-ClientId` to `Connect-PnPOnline`. Verified at pnp.github.io/powershell/articles/authentication.html.
- **SAM (SharePoint Advanced Management) licensing** = eligible base license (O365 E3/E5/A5, M365 E1/E3/E5/A5/GCC...) + EITHER ≥1 user with a Microsoft 365 Copilot license OR the standalone add-on. Exact add-on SKU name = "SharePoint Advanced Management **Plan 1**" (a.k.a. "SAM standalone"). Product name has no "Microsoft" prefix. Source: sharepoint-advanced-management-prerequisites.
- **Restricted SharePoint Search**: official name; allowed list max **100 sites**; short-term measure; honors existing permissions; not a long-term/security solution. Solution 02 stated this correctly.
- **DSPM for AI (classic)**: default weekly data risk assessment = **top 100 SharePoint sites by usage**. Note there's now a non-classic DSPM for AI; docs that say "classic" are being precise. Source: purview/dspm-for-ai.
- **Graph `driveItem: extractSensitivityLabels`** (POST): least-privileged `Files.Read.All`; higher incl. `Sites.Read.All`. Solution's "Files.Read.All or Sites.Read.All" is accurate.
- **Copilot encrypted-label behavior**: users need **VIEW + EXTRACT** usage rights for AI apps to return data. Source: purview/ai-m365-copilot-considerations.
- **Tooling tip**: `microsoft_docs_search` output is dumped to a temp .txt file (often >40KB) and is NOT a single clean JSON object (multiple objects/array). Don't `ConvertFrom-Json` the whole file — use substring/regex/IndexOf on the raw text instead.

### Solution 01 (CRS) — 2026-06-05
- **Recurring naming nits to watch across solutions:**
  - "Microsoft 365 Copilot Retrieval API" — repos sometimes drop "365" ("Microsoft Copilot Retrieval API"). API is in **preview** as of now. Cite: learn.microsoft.com/microsoft-365/copilot/extensibility/api/ai-services/retrieval/overview.
  - Entra role **"Directory Readers"** is plural; watch for singular "Directory Reader" in prereq role tables.
  - Watch for unverifiable Microsoft "program/offering" names (e.g., "Microsoft 365 Copilot Optimization Assessment") — these may be partner engagements not documented on Microsoft Learn. Mark unable-to-verify, don't assume.
- **Verified-real and safe to trust across solutions (don't re-flag):**
  - Graph scope `LicenseAssignment.Read.All` IS real (id e2f98668-2877-4f38-a2f4-8202e0717aa1), plus Organization/Directory/AuditLog/Reports.Read.All.
  - "Copilot Control System" (M365 admin center), "AI Administrator" Entra role, "SharePoint Advanced Management" (SAM), "Microsoft Purview Suite", Copilot Chat free tier, SharePoint agents pay-as-you-go — all current/accurate.
  - Modules Microsoft.Graph / ExchangeOnlineManagement / PnP.PowerShell / MicrosoftTeams — all real.
- **Tooling note:** `microsoft_docs_search` saves large output to temp files (single-line JSON). Use a Python/PowerShell `IndexOf`+`Substring` snippet to extract context windows rather than Select-String (which matches the whole line).

## Pass-2 Re-Verification (2026-06-05)
- **Outcome:** 16 CLEAN / 7 minor findings across all 23 solutions; all findings cited to MS Learn and addressed by Pearlman; PR #290 approved and merged to main.
