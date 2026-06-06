# Freamon Pass-2 Verification — Solution 10: Copilot Connector and Plugin Governance

**Date:** 2026-06-05 | **Verifier:** Freamon (Research/Verification) | **Pass:** 2 (re-verification)
**Scope:** README.md, docs/*.md, scripts/*.ps1, config/*.json

---

## Findings

| File:line | Current text | Issue | Correct per MS Learn | Citation URL | Severity |
|-----------|-------------|-------|----------------------|--------------|----------|
| README.md:13 | "declarative agents — a newer extensibility path that allows organizations to define custom Copilot behaviors **through configuration rather than code**" | "Rather than code" is inaccurate. Declarative agents explicitly support pro-code tooling (Visual Studio, VS Code, M365 Agents Toolkit) and include code-based API actions. The distinguishing characteristic is that they use *Copilot's own orchestrator and models*, not that they exclude code. | "Build agents using low-code tools such as Microsoft 365 Copilot or **pro-code tools like Visual Studio or Visual Studio Code and Microsoft 365 Agents Toolkit**"; declarative agents include "Custom actions to integrate with APIs to interact with external systems in real-time." | [Agents for Microsoft 365 Copilot](https://learn.microsoft.com/en-us/microsoft-365-copilot/extensibility/agents-overview) | minor |

---

## Suggested fix (for author team — Freamon does NOT edit files)

Replace: `…through configuration rather than code.`
With: `…using Copilot's own orchestrator and models, buildable with low-code or pro-code tooling.`

---

## Spot-Check Citations (items verified clean)

| Claim verified | Source location | MS Learn citation |
|----------------|-----------------|-------------------|
| "Microsoft 365 Copilot connectors (formerly Microsoft Graph connectors)" renaming is correct; solution abbreviates to "Copilot connectors (formerly Graph connectors)" | README.md line 9 | [Copilot connectors SDK overview](https://learn.microsoft.com/en-us/graph/connecting-external-content-sdk-overview) — "The Microsoft 365 Copilot connectors (formerly Microsoft Graph connectors) SDK…" Abbreviation is informal but not incorrect. |
| Microsoft Graph Copilot connectors API uses the `/external/connections` resource path | README.md Scope Boundaries | [Work with the Copilot connectors API](https://learn.microsoft.com/en-us/graph/connecting-external-content-connectors-api-overview) — "The externalConnection resource (external connection API) is a logical container for your external data"; confirms `/external/connections` resource path. |
| "Microsoft Graph Agent Registry APIs (preview)" characterization as preview when used programmatically | docs/architecture.md line 63, docs/prerequisites.md line 23 | [Microsoft Entra built-in roles — Agent Registry Administrator](https://learn.microsoft.com/en-us/entra/identity/role-based-access-control/permissions-reference) — Agent Registry is a current feature; docs confirm managing metadata via Entra and admin center. Qualifier "preview" in context of programmatic API access is appropriate given the evolving surface. |
| AI Administrator role preferred over Global Administrator for agent and plugin governance | README.md Prerequisites section, docs/prerequisites.md line 12 | [Microsoft Entra built-in roles](https://learn.microsoft.com/en-us/entra/identity/role-based-access-control/permissions-reference) — AI Administrator role manages "all aspects of Microsoft 365 Copilot" and "copilot agents from the Integrated apps page." Correctly preferring this over Global Admin. |
