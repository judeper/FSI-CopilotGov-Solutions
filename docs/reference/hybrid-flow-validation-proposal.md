# Hybrid Flow Validation (Proposal)

> **Status:** Proposal v1.0 | **Scope:** Pilot for one solution (Solution 04 — FINRA Supervision Workflow for Copilot) | **Audience:** Repo maintainers, solution authors

## Problem Statement

This repository is documentation-first: Power Automate flows are described in
markdown narratives under `solutions/<id>/docs/flows/` and explicitly NOT
committed as exported runtime artifacts (`.zip` solution packages or raw
`definition.json` files). The policy supports compliance with our framework
posture by:

- Preventing accidental commit of tenant-specific identifiers, connection
  references, and secret-bearing fields embedded in Power Platform exports.
- Keeping the repository readable, reviewable, and free of large opaque blobs.
- Forcing authors to express intent in plain language that auditors can read.

The trade-off is a **golden-artifact gap**: an adopter who builds a flow from
the markdown has no machine-checkable way to confirm their build matches the
documented intent. A reviewer cannot diff "what the docs say" against "what
the live tenant flow actually does". Drift between the two is invisible until
an examiner asks for evidence.

This proposal pilots a hybrid approach that preserves the docs-first
invariant while adding a narrow, machine-validatable contract.

## Proposed Approach

The pilot keeps the existing markdown narrative authoritative for human
review and adds two thin layers around it:

1. **Authoritative narrative (unchanged).** Flow documentation in
   `solutions/<id>/docs/flows/*.md` remains the source of truth for human
   reviewers. All design rationale, regulatory mapping, and operator
   instructions stay there.
2. **Machine-readable flow contract (new, in-repo).** A small JSON file at
   `solutions/<id>/flows/*.flow.json` declares the structural expectations
   for the flow: trigger type, connector references, the ordered set of
   action names, condition branches, retry policy, naming pattern, and so on.
   It is intentionally **not** a Power Automate export — it is a hand-written
   contract that mirrors what the markdown describes. Sample contracts are
   marked `"sample": true`.
3. **Contract validator (new, in-repo).** `scripts/validate-flow-contract.py`
   loads each `*.flow.json`, validates it against an inline schema, and
   cross-checks that every action name listed in the contract appears at
   least once in the matching markdown narrative (and vice versa for any
   action name the markdown declares with a recognisable marker). It
   produces an OK/error report on stdout.
4. **Out-of-repo export diff (new, NOT in this PR).** In a controlled
   tenant, an operator periodically exports the live flow as a `*.zip` and
   stores it in a private artifact store (Azure Blob, internal share, or
   the operator's workstation). A future `scripts/diff-flow-export.py`
   would read the export, normalise it (strip tenant-specific GUIDs,
   connection display names, timestamps), and compare against the in-repo
   contract, reporting drift such as added/removed actions, changed
   connector kinds, or altered trigger frequency. The export itself never
   enters the repository.

The result: the markdown stays authoritative, the contract is small enough
to review by eye, and adopters who choose to opt in get a machine-checkable
golden reference without breaking the no-export rule.

## Schema Sketch for the Flow Contract

The contract schema is intentionally minimal. Each field below is required
unless marked optional.

| Field | Type | Description |
|-------|------|-------------|
| `schema_version` | string | Contract schema version (e.g., `"1.0"`). Used to gate validator behaviour as the schema evolves. |
| `solution_id` | string | Solution folder identifier (e.g., `04-finra-supervision-workflow`). Validator cross-checks the file's location. |
| `flow_name` | string | Human-readable flow name as it would appear in Power Automate. |
| `flow_id` | string | Stable in-repo identifier (kebab-case). Used to correlate with the markdown narrative file name. |
| `sample` | boolean | `true` for representative-only contracts that do not correspond to a tenant-bound flow. |
| `trigger` | object | `{ "kind": "<recurrence|automated|manual>", "details": "<short description>" }`. |
| `connectors` | array of objects | Each item: `{ "name": "<display>", "kind": "<sharedoffice365|sharedteams|...>" }`. The set of connector references the flow declares. |
| `actions` | array of objects | Ordered list. Each item: `{ "name": "<action display name>", "type": "<compose|http|condition|apply_to_each|...>" }`. Names must appear in the markdown narrative. |
| `condition_branches` | array of objects | Each item: `{ "name": "<condition action name>", "yes": ["<action name>", ...], "no": ["<action name>", ...] }`. Documents the expected control flow. |
| `error_handling` | object | `{ "configured_run_after": <bool>, "scope_pattern": "<try-catch|none>" }`. Describes the exception-handling pattern. |
| `retry_policy` | object | `{ "type": "<none|fixed|exponential>", "count": <int>, "interval": "<ISO8601 duration>" }`. Applied to network-bound actions. |
| `naming_pattern` | string | Regex (anchored) that all action names must match. Helps catch ad-hoc renames. |
| `evidence_outputs` | array of strings | Names of evidence artefacts the flow is expected to write (cross-checked with `data/evidence-catalog.json` in a future iteration). |
| `notes` | string (optional) | Free-form maintainer notes; not validated. |

## Risks

- **Schema drift.** The contract schema and the live Power Automate export
  format may diverge over time. Mitigation: version the schema
  (`schema_version`) and keep the contract intentionally narrow.
- **False positives on cosmetic export changes.** Power Platform may
  re-order non-semantic fields, rename internal identifiers, or insert
  metadata on export. The future export diff must normalise aggressively
  (sort keys, strip GUIDs, ignore `runtimeConfiguration`) before comparing.
- **Maintenance burden.** The contract is hand-written and can fall out of
  sync with both the markdown and the live flow. Mitigation: keep the
  contract small, run the validator in a future CI step (out of scope for
  this proposal), and treat contract updates as part of any flow change.
- **False sense of completeness.** A passing contract validator does not
  prove the flow is correct, only that its declared structure matches the
  documented structure. The narrative remains authoritative for intent.
- **Scope creep.** Adopters may push for a full flow-as-code surface. The
  proposal explicitly resists this: the contract is a check, not a build
  artefact.

## Acceptance Criteria for the Pilot

The pilot is considered successful when all of the following are true for
Solution 04 only:

- [ ] `solutions/04-finra-supervision-workflow/flows/supervision-review.flow.json`
      exists, declares `"sample": true`, and conforms to the schema sketch above.
- [ ] `scripts/validate-flow-contract.py` runs successfully against the
      sample contract and exits 0 with an "OK" report.
- [ ] The validator produces actionable error output when any required
      field is removed or when an action name is renamed without updating
      the markdown narrative (verified manually by maintainers).
- [ ] This proposal document is published in the Reference section of the
      docs site.
- [ ] No exported Power Automate `.zip` or `definition.json` artefact is
      committed to the repository.
- [ ] The validator is **not** wired into CI as part of the pilot. A
      follow-up decision record will determine whether to promote it.

## Out of Scope

- Implementing `scripts/diff-flow-export.py`.
- Authoring contracts for the other 22 solutions.
- Wiring the validator into `.github/workflows/`.
- Defining the private artifact store layout for tenant exports.
