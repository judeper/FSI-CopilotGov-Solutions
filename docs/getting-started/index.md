# Getting Started

Use this sequence to move from repository review to an operator-ready deployment plan.

1. Review [prerequisites](./prerequisites.md).
2. Complete [identity and secrets prep](./identity-and-secrets-prep.md).
3. Clarify the documentation-first boundary with the [documentation vs runnable assets guide](../documentation-vs-runnable-assets-guide.md).
4. Use the [deployment guide](./deployment-guide.md) to choose the wave order for the relevant solutions.
5. Use the [operational handbook](../operational-handbook.md), [operational RACI](../operational-raci.md), [operational cadence](../operational-cadence.md), and [escalation procedures](../escalation-procedures.md) to define steady-state ownership.
6. Run `pwsh -File scripts\deployment\Validate-Prerequisites.ps1` and capture the outcome in `DELIVERY-CHECKLIST-TEMPLATE.md` before any tenant-specific deployment work.
