# Lab Validation Contract Reference

This reference defines the machine-readable lab contract and result model used by this repository's documentation-first validation workflow.

## Scope Boundaries

- The contract format is scoped to **US commercial-cloud Microsoft 365** lab validation.
- Contracts define validation intent and safety controls; they do **not** deploy tenant assets by themselves.
- This repository stores schemas, validators, and representative fixtures only.
- Playwright execution, browser automation, and attended tenant runs remain in the separate studio executor lane.
- Contract evidence supports compliance with control verification expectations, but it does not replace control-owner judgment.

Contracts must set `scope.cloud` to `m365-us-commercial` and `scope.usCommercialOnly` to `true`. The optional `prohibitedClouds` field is reserved for non-published fixtures or consumers that need explicit exclusions; forward-facing solution contracts should omit it and rely on the commercial-scope constants.

## Contract, Result, and Evidence Lifecycle

1. Author a contract (`*.lab.json`) using `data/lab-validation-contract.schema.json`.
2. Validate contract structure and semantics with `scripts/validate-lab-contracts.py`.
3. Execute the contract in the external studio lane.
4. Emit a result (`*.lab-result.json`) using `data/lab-validation-result.schema.json`.
5. Validate result semantics with `scripts/validate-lab-result.py`.
6. Validate portable evidence packages with `scripts/validate-lab-package.ps1`.

The result file is the authoritative disposition record. Evidence packages remain portable, hash-verified artifacts that can be reviewed independently of the execution host.

## Disposition Semantics

- `PASS`: validation intent completed with required read-backs and evidence.
- `PARTIAL`: some validation completed, but additional follow-up is required.
- `BLOCKED`: execution was prevented by a prerequisite or platform gate; negative and source evidence is still required.
- `NOT-APPLICABLE`: scenario intentionally does not apply; source evidence is still required.
- `FAIL`: execution produced a failing outcome and does not satisfy acceptance.

Accepted `BLOCKED` and accepted `NOT-APPLICABLE` results are valid only when they include negative evidence and source verification. They must not claim implemented control state.

## Safe Mutation Classes

Contracts classify mutable steps with one of these reversibility classes:

- `read-only`: no tenant mutation is allowed.
- `reversible`: mutation must include paired cleanup and read-back proof.
- `delayed-cleanup`: mutation cleanup may occur in a controlled follow-up window.
- `tenant-reset`: mutation requires explicit break-glass approval and reset ownership.
- `prohibited`: action must not run in the lab executor.

`mutations` remains a required top-level array, but it may be empty for read-only contracts that do not declare any mutable operations. Any non-null execution-step `mutationRef` must resolve to a declared mutation ID.

Result files use explicit mutation execution flags per step:

- `mutationExecuted: true` requires a non-null `mutationRef`.
- `mutationExecuted: false` requires `mutationRef: null`.

Cleanup semantics are fail-closed: `cleanup.state: not-required` is valid only when no step reports `mutationExecuted: true`.

## Source Hierarchy

Contracts require first-party Microsoft sources and source verification dates. For generally available claims, citations must resolve to Microsoft Learn. Source verification remains explicit in result files so reviewers can separate source drift from runtime execution outcomes.

## Studio Executor Separation

`FSI-CopilotGov-Solutions` owns contract definition and validation rules. The studio executor owns runtime execution and evidence capture. This separation keeps repository content documentation-first while still supporting repeatable, machine-validated lab evidence workflows.
