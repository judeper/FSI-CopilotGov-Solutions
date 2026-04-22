# Prerequisites

## Microsoft 365 Requirements

- Microsoft 365 E3 or E5 tenant with Copilot licensing for the population in scope
- Documented Copilot deployment scope (Copilot Chat, Copilot in apps, Copilot Agents) for inventory registration

## PowerShell Requirements

- PowerShell 7.2 or later
- Pester 5.x for running the included smoke tests

The repository scripts are documentation-first and do not require Microsoft Graph SDK modules in v0.1.0.

## Operating Model Requirements

- Model risk officer or equivalent role assigned and accountable for AI model risk
- Model risk committee review cadence defined and documented
- Third-party risk management process able to receive vendor governance evidence on the configured cadence
- AI incident response procedure documented for control 3.12 escalation handling

## Roles

- Model Risk Officer — owner of inventory and validation review
- Compliance Admin — review of monitoring evidence and regulatory mapping
- Third-Party Risk Manager — owner of Microsoft vendor governance review
- Entra Global Admin — required only when future versions add tenant integration

## Reference Documents

Operators are recommended to gather the following before completing tier-specific reviews:

- Federal Reserve SR 11-7 and OCC Bulletin 2011-12 supervisory guidance
- SR 26-2 / OCC Bulletin 2026-13 — note the explicit generative AI exclusion
- NIST AI RMF 1.0
- ISO/IEC 42001
- Microsoft Responsible AI documentation and Copilot transparency notes
- Microsoft SOC reports applicable to Microsoft 365 services
