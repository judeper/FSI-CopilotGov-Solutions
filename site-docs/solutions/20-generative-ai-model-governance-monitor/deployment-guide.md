# Deployment Guide

## Prerequisites

Review [docs/prerequisites.md](prerequisites.md) before deployment. The deployment script is documentation-first and does not require live Microsoft 365, Microsoft Foundry, Azure OpenAI, Microsoft Purview, or Azure AI Content Safety connectivity in v0.1.3.

## Step 1: Clone and Configure

```powershell
git clone https://github.com/judeper/FSI-CopilotGov-Solutions.git
Set-Location C:\Dev\FSI-CopilotGov-Solutions\solutions\20-generative-ai-model-governance-monitor
```

## Step 2: Select Governance Tier

Select the tier that matches the operating model:

- `baseline` — annual inventory review, documented attestation, quarterly monitoring, annual third-party review
- `recommended` — semi-annual inventory review, adapted SR 11-7 validation, monthly monitoring with output sampling, semi-annual third-party review
- `regulated` — quarterly inventory review, adapted SR 11-7 validation with independent challenge, continuous sampled monitoring with escalation thresholds, quarterly third-party review

Review `config/<tier-name>.json` against firm policy before deployment.

## Step 3: Run Deploy-Solution.ps1

Run with `-WhatIf` first to preview the manifest:

```powershell
.\scripts\Deploy-Solution.ps1 -ConfigurationTier recommended -WhatIf -Verbose
```

If acceptable, run without `-WhatIf`:

```powershell
.\scripts\Deploy-Solution.ps1 -ConfigurationTier recommended -OutputPath .\artifacts -Verbose
```

## Step 4: Run Monitor-Compliance.ps1

Record the initial monitoring snapshot (representative sample data):

```powershell
.\scripts\Monitor-Compliance.ps1 -ConfigurationTier recommended -OutputPath .\artifacts -Verbose
```

## Step 5: Run Export-Evidence.ps1

Export the five evidence artifacts:

```powershell
.\scripts\Export-Evidence.ps1 -ConfigurationTier recommended -OutputPath .\artifacts -Verbose
```

Verify the following files exist under `artifacts\`:

- `copilot-model-inventory-<tier>.json` and `.sha256`
- `validation-summary-<tier>.json` and `.sha256`
- `ongoing-monitoring-log-<tier>.json` and `.sha256`
- `content-safety-and-guardrails-<tier>.json` and `.sha256`
- `third-party-due-diligence-<tier>.json` and `.sha256`

## Step 6: Manual Workflow Handoff

The repository version of GMG is documentation-first. After evidence is exported:

1. Submit `copilot-model-inventory` to the model risk officer for inventory committee acknowledgement.
2. Submit `validation-summary` to the validation team for adapted SR 11-7 review.
3. Provide `ongoing-monitoring-log` to the operations team responsible for output sampling and escalation.
4. Provide `content-safety-and-guardrails` to the owner responsible for Foundry, Azure OpenAI, and approved provider guardrail review.
5. Provide `third-party-due-diligence` to the third-party risk team for the next vendor review cycle.

## Step 7: Lab Validation Handoff

A machine-readable lab validation contract is provided at
`solutions\20-generative-ai-model-governance-monitor\lab\20-generative-ai-model-governance-monitor.lab.json`.
The first lab cycle is **read-only and detect-only** (`mutations: []`): it proves subscription and tenant
identity, inspects an existing Microsoft Foundry resource and project (or equivalent current surface),
reviews model catalog, deployment, provider, and lifecycle metadata, records Azure OpenAI-in-Microsoft-Foundry default Guardrail policies and any separate Azure AI Content Safety status, records provider/deployment-native guardrails for non-Azure-OpenAI deployments only where documentation and read-only portal evidence confirm them, notes evaluation and monitoring visibility where present, runs the documentation-first sample scripts, and captures evidence.

The contract creates, deploys, invokes, changes, or deletes nothing. It also encodes honest negative
validation: absent preconditions (no subscription, no Foundry resource or project, insufficient read-only
role, unavailable region or feature, or no deployments) are recorded as evidence-backed `BLOCKED` or
`NOT-APPLICABLE` results rather than forcing a positive outcome. Validate the contract before handoff:

```powershell
python scripts\validate-lab-contracts.py solutions\20-generative-ai-model-governance-monitor\lab\20-generative-ai-model-governance-monitor.lab.json
```

Lab operators should also confirm four execution details before studio-lane handoff:

- **Setup identity proof requires authenticated Azure CLI (`az`) plus secure expected values** for `EXPECTED_AZURE_SUBSCRIPTION_ID` and `EXPECTED_TENANT_ID`; the command fails closed on missing expectations, sign-in failure, or mismatch.
- **Identity output is minimized** to non-identifying booleans/state metadata (`identityVerified`, `subscriptionMatch`, `tenantMatch`, `accountState`, `isDefaultSubscription`, `environmentName`) and excludes subscription IDs, tenant IDs, UPNs, endpoints, and expected variable values.
- **Evidence hash verification is non-mutating**: it imports `scripts\common\EvidenceExport.psm1` and runs `Test-EvidencePackageHash` against existing `lab-output` JSON + `.sha256` files; any missing file/sidecar or hash mismatch returns nonzero and does not call `Export-Evidence.ps1`.
- **Evidence minimization review is separate and read-only**: `step-review-evidence-minimization` manually inspects generated evidence for prohibited retained content (keys/tokens, raw subscription/tenant/user IDs, endpoint hostnames, prompts/completions, dataset or model input/output content), records only an attestation, and never copies prohibited content into retained evidence.

Execution and evidence capture run in the separate studio executor lane. The
shared contract reference is `docs\reference\lab-validation-contract.md`.

## Rollback

To roll back:

1. Remove generated manifests and evidence files from `artifacts\`.
2. Notify model risk and compliance stakeholders that the snapshot has been withdrawn.
3. Archive prior evidence packages according to the customer retention policy before deletion.
