# Solution Structure Rules

Every solution folder should include:
- `README.md`
- `CHANGELOG.md`
- `DELIVERY-CHECKLIST.md`
- `docs/architecture.md`
- `docs/deployment-guide.md`
- `docs/evidence-export.md`
- `docs/prerequisites.md`
- `docs/troubleshooting.md`
- `scripts/Deploy-Solution.ps1`
- `scripts/Monitor-Compliance.ps1`
- `scripts/Export-Evidence.ps1`
- `config/default-config.json`
- `config/baseline.json`
- `config/recommended.json`
- `config/regulated.json`
- `tests/<solution>.Tests.ps1`

Reviewed solutions (those that have completed accuracy review) must additionally include:
- `lab/<solution>.lab.json` — the machine-readable lab validation contract.

## Reviewed Solution Lab Handoff

Once a solution completes accuracy review, it must carry its lab validation handoff:

- `lab/<solution>.lab.json` authored against `data/lab-validation-contract.schema.json` and passing `scripts/validate-lab-contracts.py`. See [Lab Validation Contract](../../docs/reference/lab-validation-contract.md). The first cycle is read-only/detect-only (`mutations: []` normally).
- `docs/deployment-guide.md` must include a lab handoff subsection describing how the contract is executed in the separate `studio-video-factory` executor lane and how evidence is captured. This repository owns the contract; the executor lane owns Playwright execution.
- `DELIVERY-CHECKLIST.md` must include lab handoff items tracking contract authored, contract validated, lab executed, and evidence accepted.

Every solution README must include these sections:
- `## Overview`
- `## Scope Boundaries` (with explicit list of what the solution does NOT do)
- `## Related Controls`
- `## Prerequisites`
- `## Deployment`
- `## Evidence Export`
- `## Regulatory Alignment`

Every solution README must begin with a standardized status line and disclaimer banner:
```
> **Status:** Documentation-first scaffold | **Version:** vX.Y.Z | **Priority:** PX | **Track:** X

> ⚠️ **Documentation-first repository.** Scripts use representative sample data and do not connect to live Microsoft 365 services.
```
