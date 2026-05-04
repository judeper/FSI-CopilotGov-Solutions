# Framework Compatibility

This page documents how `FSI-CopilotGov-Solutions` versions are pinned to
`FSI-CopilotGov` framework versions, and how the pin is enforced.

## Why pinning matters

`FSI-CopilotGov-Solutions` consumes the framework's control taxonomy,
regulatory mappings, and evidence schema. If the solutions repository
referenced the framework on `main`, an upstream control rename or schema
change could silently break solution mappings and audit-evidence
contracts. Regulated adopters expect a deterministic, auditable
relationship between the two repositories.

## How the pin is recorded

The pinned framework reference is recorded in two places that must stay in
sync:

| Location | Field | Purpose |
|----------|-------|---------|
| `FRAMEWORK-VERSION` (repo root) | `framework_ref` / `framework_tag` | Human-readable source of truth |
| `scripts/traceability.py` | `FRAMEWORK_REPO_REF` | Used by build and validation scripts |

`scripts/validate-documentation.py` fails the build if any markdown file
references `judeper/FSI-CopilotGov` on `blob/main`, `tree/main`,
`blob/master`, or `tree/master`. All documentation links must use the
pinned commit (or, in future, a pinned tag).

## Current pin

The current pin is recorded in [`FRAMEWORK-VERSION`](https://github.com/judeper/FSI-CopilotGov-Solutions/blob/main/FRAMEWORK-VERSION)
at the repository root. It is intentionally tracked in a top-level file so
that operators reviewing the repository can confirm compatibility before
running any deployment or evidence export.

## Compatibility matrix

The table below tracks which `FSI-CopilotGov-Solutions` releases were
validated against which framework references. Update this table when
releasing a new tagged version of this repository.

| Solutions release | Framework ref | Framework tag | Notes |
|-------------------|---------------|---------------|-------|
| `v0.7.0` | `e0fb7b769529dcc008cc2066402cdabae4f369cf` | none | Latest release; pinned to commit until framework publishes signed tags. |

## Bumping the pin

When the framework publishes a release that this repository should adopt:

1. Update `framework_ref` (and `framework_tag`, if available) and
   `pinned_at` in `FRAMEWORK-VERSION`.
2. Update `FRAMEWORK_REPO_REF` in `scripts/traceability.py` to the same
   value.
3. Run `python scripts/validate-documentation.py` to confirm no
   documentation references the framework on `main` or `master`.
4. Run `python scripts/build-docs.py`, `python scripts/validate-contracts.py`,
   `python scripts/validate-solutions.py`, and
   `python scripts/validate_solutions_json.py` to confirm no contract or
   schema regressions.
5. Add a new row to the compatibility matrix above.
6. Cut a new release of `FSI-CopilotGov-Solutions` that records the new
   compatibility pair.

This procedure helps meet the cross-repository version-governance
expectation called out in the FSI portfolio critique and supports
auditors who need a single, deterministic view of which framework
revision a given solutions release was validated against.
