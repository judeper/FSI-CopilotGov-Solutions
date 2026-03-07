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
