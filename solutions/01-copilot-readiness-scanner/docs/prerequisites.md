# Prerequisites

## Overview

The Copilot Readiness Assessment Scanner requires Microsoft 365 administrative read access across multiple workloads, PowerShell modules for tenant connectivity, and access to shared repository contracts. Review these prerequisites before attempting deployment or evidence export.

## Required Microsoft 365 Licensing

At minimum, the target environment should have:

- Microsoft 365 E3 or E5 for core productivity, identity, and compliance inventory
- Microsoft 365 Copilot licenses for the pilot or production cohort being assessed
- Microsoft Purview capabilities appropriate for sensitivity labels and retention inventory
- Microsoft Defender capabilities appropriate for the security posture checks being reviewed

Recommended for fuller signal coverage:

- Microsoft 365 E5 or equivalent add-ons where Purview, Defender, or advanced audit signals are needed
- SharePoint Advanced Management licensing if the customer wants to validate control 1.7 readiness in more detail

## Required Azure AD and Microsoft 365 Roles

The simplest deployment model is to use a Global Administrator account in a controlled non-production or delegated operations process. If the customer prefers least privilege, the following role combination is typically required:

| Workload Area | Role Requirement | Purpose |
|---------------|------------------|---------|
| Tenant-wide setup | Global Administrator or Privileged Role Administrator plus Global Reader | Initial validation, broad tenant read access, role confirmation |
| Licensing | License Administrator or Global Reader | Read Copilot and Microsoft 365 SKU assignments |
| Entra identity | Security Reader and Directory Reader | Review role assignments, guests, and identity posture |
| Defender security | Security Reader | Read Defender posture and exposure signals |
| Purview compliance | Compliance Administrator or Compliance Data Administrator | Review labels, retention, and compliance configuration |
| SharePoint and OneDrive | SharePoint Administrator | Review site inventory, sharing posture, and management readiness |
| Teams | Teams Administrator or Teams Communications Administrator | Review Teams-related readiness dependencies |
| Power Platform | Power Platform Administrator | Review environments, connectors, and DLP posture |

## Required Permissions Per Workload

The exact API permissions depend on the final authentication model, but the scanner expects the operator or service principal to have access equivalent to the following workload scopes:

| Workload | Example Access Needed | Why It Is Needed |
|----------|-----------------------|------------------|
| Microsoft Graph | `Organization.Read.All`, `Directory.Read.All`, `AuditLog.Read.All`, `Reports.Read.All` | Tenant metadata, identity posture, and readiness signals |
| Licensing | User and SKU read access | Copilot assignment strategy and license drift checks |
| Purview | Label and retention configuration read access | Sensitivity label and records readiness review |
| SharePoint Online | Tenant admin read access and PnP connection rights | Site inventory, sharing posture, advanced management readiness |
| Teams | Teams admin read access | Teams workload dependencies and sharing context |
| Power Platform | Admin API read access | Environment governance and DLP coverage review |

## PowerShell Modules Required

Install the following modules on the operator workstation:

- `Microsoft.Graph`
- `ExchangeOnlineManagement`
- `PnP.PowerShell`
- `MicrosoftTeams`

Recommended local tools:

- PowerShell 7.4 or later
- Python 3.11 or later for repository validation scripts

## Network and Connectivity Requirements

Ensure the operator workstation or automation runner can reach:

- `https://graph.microsoft.com`
- Microsoft Purview and compliance endpoints used by the tenant
- SharePoint Online admin URLs, for example `https://<tenant>-admin.sharepoint.com`
- Teams and Power Platform admin endpoints
- The configured evidence output storage location

If the environment uses proxy inspection or egress restrictions, allow outbound TLS access to the Microsoft 365 administrative endpoints required by the chosen scan domains.

## Shared Module Dependencies

This solution depends on shared repository components but does not modify them:

- `..\..\..\scripts\common\IntegrationConfig.psm1`
- `..\..\..\scripts\common\GraphAuth.psm1`
- `..\..\..\scripts\common\EvidenceExport.psm1`
- `..\..\..\data\evidence-schema.json`

The solution scripts reference these shared contracts to stay aligned with repository-wide evidence, status, and tier handling.
