# Solution Review Disposition Record

Authoritative disposition record for the FSI-CopilotGov-Solutions 23-solution and
PR-backlog review. Every reviewed item carries an explicit disposition, the evidence
that supports it, and the rationale for the change or non-change.

> **Cloud scope.** This content targets US commercial-cloud Microsoft 365 only. See the
> [Disclaimer](../disclaimer.md).

> ⚠️ **Documentation-first repository.** Scripts and lab contracts use representative
> sample data and do not connect to live Microsoft 365 services in their repository form.
> See the [Documentation vs Runnable Assets Guide](../documentation-vs-runnable-assets-guide.md).

Read the [Project Handoff](../project-handoff.md) for the durable phase state, the
lab-execution blocker, and the resume sequence. This page records the review outcome;
the handoff records where the program stands.

## Scope Boundaries

This record does **not**:

- accept, replace, or substitute for attended live-lab evidence;
- merge, rebase, or approve any review pull request;
- assert implemented control state for any solution lacking accepted lab evidence;
- modify any solution's reviewed content, version, or control mappings;
- execute browser automation or connect to a Microsoft 365 tenant.

## Disposition Vocabulary

| Disposition | Meaning |
|-------------|---------|
| `PASS` | Verified against repository validators or accepted evidence; no change required. |
| `FIXED` | A defect was found and remediated in this repository, with validator evidence. |
| `BLOCKED` | Verification cannot complete here; the blocking gate and its owner are named. |
| `LEGAL-REVIEW` | Requires legal or compliance judgment before it can be dispositioned. |

## Review Baseline

| Field | Value |
|-------|-------|
| Review date | 2026-07-25 |
| Repository baseline | `4a4d3e2766cf3305f2d4b8f7e80369612aeb685c` (issue baseline) |
| Reviewed `main` | `d1620f6` |
| Solutions reviewed | 23 |
| Draft review pull requests reviewed | 21 (#320–#340) |
| Deterministic validators run on `main` | 14 of 14 `PASS` |

## Program-Level Findings

### F-1 — Shared lab test module forced an N-way conflict — `FIXED`

**Observed.** 20 of the 21 draft review pull requests reported `CONFLICTING`. A
`git merge-tree` pass against `main` showed a single shared conflict path in every
case: `scripts/test_lab_validation_contracts.py`. Pull requests #330 and #335 carried
additional metadata conflicts (see F-3).

**Cause.** The module asserted contract coverage through hardcoded per-solution
assertions. Adding a reviewed solution therefore required editing the same region of
the same file on every review branch, which guaranteed a conflict for each branch
after the first.

**Remediation.** The module now derives coverage from the filesystem by discovering
`solutions/*/lab/*.lab.json`. Reviewed solutions no longer require an edit to the
shared module, so the conflict source is removed at its origin. A guard test fails if
discovery returns nothing, so an empty result cannot make the suite vacuously pass.

**Validation.** `python scripts/test_lab_validation_contracts.py` — 12 tests, exit 0.

### F-2 — Branch edits silently dropped accepted-solution coverage — `FIXED`

**Observed.** Each review branch replaced the Solution 01 and Solution 02 contract
assertions with an assertion for its own solution. Merging any single branch would
have removed test coverage for the two solutions that already hold accepted lab
evidence, without any validator reporting the loss.

**Cause.** Same root cause as F-1: coverage was enumerated by hand rather than
derived.

**Remediation.** Coverage is now derived, so it grows as contracts land and cannot be
narrowed by a branch edit.

**Validation.** In the test-merge pass below, every resolved merge reported
`Lab contract validation passed: 3 file(s) checked` — Solutions 01 and 02 retained
alongside the branch's own contract.

### F-3 — Stale `solutions.json` snapshots would revert released versions — `BLOCKED`

**Observed.** Pull request #330 and pull request #335 each carry a `solutions.json`
regenerated before Solutions 01 and 02 were released. Both branches record Solution 01
at `0.2.3` and Solution 02 at `0.2.4`, while `main` records the released `0.2.4` and
`0.2.5`. Pull request #330 additionally conflicts on `solutions-graph.json`.

**Impact.** Accepting either branch snapshot wholesale would revert the released
version metadata for two solutions that hold accepted lab evidence.

**Resolution rule (for the branch owner).** Do not accept the branch snapshot
wholesale. Regenerate `solutions.json` and `solutions-graph.json` from `main` and
reapply only the branch's own solution entry — Solution 08 `0.1.4` for #330, and the
Solution 21 summary rewrite for #335. This is consistent with the Solution 08 version
note in the [Project Handoff](../project-handoff.md).

**Why `BLOCKED` here.** The correction belongs on the review branches, which are owned
by the serial review program and remain gated on lab evidence. Changing them from this
review would modify reviewed content outside this record's scope.

### F-4 — Legal or compliance escalation — none identified

No item in this review required legal or compliance judgment, so no item carries a
`LEGAL-REVIEW` disposition. Regulatory naming and cautious-language checks passed
across all forward-facing files (`validate-documentation.py`, 379 markdown files;
`verify_commercial_scope.py`, 489 forward-facing files).

## Repository Validation Evidence

Run against the reviewed `main` and re-run against the change in this record.

| Validator | Result | Detail |
|-----------|--------|--------|
| `scripts/test_docs_protection.py` | `PASS` | 5 tests |
| `scripts/build-docs.py` | `PASS` | Documentation build inputs refreshed |
| `scripts/validate-contracts.py` | `PASS` | Contract validation passed |
| `scripts/validate-solutions.py` | `PASS` | 23 solutions validated |
| `scripts/validate-documentation.py` | `PASS` | 379 markdown files checked |
| `scripts/validate_solutions_json.py` | `PASS` | 23 solutions validated |
| `scripts/validate_solutions_graph.py` | `PASS` | 23 solutions; 56 framework controls referenced |
| `scripts/validate_data_classification.py` | `PASS` | Matrix validation passed |
| `scripts/verify_readme_counts.py` | `PASS` | 23 solutions; 58 controls; 243 playbooks |
| `scripts/verify_commercial_scope.py` | `PASS` | 489 forward-facing files; commercial-cloud scope clean |
| `scripts/validate-lab-contracts.py` | `PASS` | Repository contracts validated |
| `scripts/validate-lab-result.py` | `PASS` | 0 results present; zero-result case allowed |
| `scripts/test_lab_validation_contracts.py` | `PASS` | 12 tests |
| `python -m mkdocs build --strict` | `PASS` | Exit 0 |
| PowerShell parse check | `PASS` | All `*.ps1` parse without error |

## Lab Contract Verification — All 23 Solutions

Every solution's `lab/<solution>.lab.json` was extracted from its pull request head and
validated with the validator on `main` (`scripts/validate-lab-contracts.py`).

**Result: 23 of 23 contracts valid.**

Invariants verified across all 23 contracts:

| Invariant | Expected | Observed |
|-----------|----------|----------|
| `schemaVersion` | `1.0.0` | `1.0.0` in all 23 |
| `mutations` | empty (read-only first cycle) | `0` in all 23 |
| Step `mutationRef` | none | `0` in all 23 |
| `scope.cloud` | `m365-us-commercial` | all 23 |
| `scope.usCommercialOnly` | `true` | all 23 |
| `prohibitedClouds` | omitted (commercial-only) | omitted in all 23 |
| `execution.phases` | 4 | `4` in all 23 |

| Sol | Solution | PR | Contract | Steps | Source claims | Disposition |
|-----|----------|----|----------|-------|---------------|-------------|
| 01 | Copilot Readiness Assessment Scanner | merged | valid | 9 | 8 | `PASS` |
| 02 | Oversharing Risk Assessment and Remediation | merged | valid | 8 | 5 | `PASS` |
| 03 | Sensitivity Label Coverage Auditor | [#326](https://github.com/judeper/FSI-CopilotGov-Solutions/pull/326) | valid | 8 | 6 | `BLOCKED` |
| 04 | FINRA Supervision Workflow for Copilot | [#331](https://github.com/judeper/FSI-CopilotGov-Solutions/pull/331) | valid | 9 | 5 | `BLOCKED` |
| 05 | DLP Policy Governance for Copilot | [#327](https://github.com/judeper/FSI-CopilotGov-Solutions/pull/327) | valid | 9 | 10 | `BLOCKED` |
| 06 | Copilot Interaction Audit Trail Manager | [#323](https://github.com/judeper/FSI-CopilotGov-Solutions/pull/323) | valid | 8 | 7 | `BLOCKED` |
| 07 | Conditional Access Policy Automation for Copilot | [#328](https://github.com/judeper/FSI-CopilotGov-Solutions/pull/328) | valid | 9 | 5 | `BLOCKED` |
| 08 | License Governance and ROI Tracker | [#330](https://github.com/judeper/FSI-CopilotGov-Solutions/pull/330) | valid | 10 | 6 | `BLOCKED` |
| 09 | Copilot Feature Management Controller | [#333](https://github.com/judeper/FSI-CopilotGov-Solutions/pull/333) | valid | 11 | 7 | `BLOCKED` |
| 10 | Copilot Connector and Plugin Governance | [#334](https://github.com/judeper/FSI-CopilotGov-Solutions/pull/334) | valid | 12 | 9 | `BLOCKED` |
| 11 | Risk-Tiered Rollout Automation | [#329](https://github.com/judeper/FSI-CopilotGov-Solutions/pull/329) | valid | 8 | 6 | `BLOCKED` |
| 12 | Regulatory Compliance Dashboard | [#340](https://github.com/judeper/FSI-CopilotGov-Solutions/pull/340) | valid | 8 | 6 | `BLOCKED` |
| 13 | DORA Operational Resilience Monitor | [#339](https://github.com/judeper/FSI-CopilotGov-Solutions/pull/339) | valid | 11 | 5 | `BLOCKED` |
| 14 | Communication Compliance Configurator | [#332](https://github.com/judeper/FSI-CopilotGov-Solutions/pull/332) | valid | 12 | 8 | `BLOCKED` |
| 15 | Copilot Pages and Notebooks Compliance Gap Monitor | [#324](https://github.com/judeper/FSI-CopilotGov-Solutions/pull/324) | valid | 7 | 4 | `BLOCKED` |
| 16 | Item-Level Oversharing Scanner | [#320](https://github.com/judeper/FSI-CopilotGov-Solutions/pull/320) | valid | 7 | 4 | `BLOCKED` |
| 17 | SharePoint Permissions Drift Detection | [#321](https://github.com/judeper/FSI-CopilotGov-Solutions/pull/321) | valid | 7 | 3 | `BLOCKED` |
| 18 | Entra Access Reviews Automation | [#322](https://github.com/judeper/FSI-CopilotGov-Solutions/pull/322) | valid | 7 | 3 | `BLOCKED` |
| 19 | Copilot Tuning Governance | [#337](https://github.com/judeper/FSI-CopilotGov-Solutions/pull/337) | valid | 7 | 5 | `BLOCKED` |
| 20 | Generative AI Model Governance Monitor | [#338](https://github.com/judeper/FSI-CopilotGov-Solutions/pull/338) | valid | 12 | 8 | `BLOCKED` |
| 21 | Cross-Tenant Agent Federation Auditor | [#335](https://github.com/judeper/FSI-CopilotGov-Solutions/pull/335) | valid | 11 | 7 | `BLOCKED` |
| 22 | Pages and Notebooks Retention Tracker | [#325](https://github.com/judeper/FSI-CopilotGov-Solutions/pull/325) | valid | 8 | 5 | `BLOCKED` |
| 23 | Copilot Studio Agent Lifecycle Tracker | [#336](https://github.com/judeper/FSI-CopilotGov-Solutions/pull/336) | valid | 11 | 6 | `BLOCKED` |

**Blocking gate for Solutions 03–23.** Accepted attended live-lab evidence does not yet
exist. This repository cannot produce it: it stays documentation-first, and Playwright
execution and evidence capture are owned by the separate `studio-video-factory`
executor lane. Solution 16 holds an initial `PARTIAL` result that is explicitly not
accepted. No solution in this table without accepted evidence claims implemented
control state.

**Control-mapping note.** Contracts for Solutions 20, 21, 22, and 23 omit controls
`3.8a`, `2.17`, `3.14`, and `4.14` from machine-checked arrays because those IDs are
not yet canonical upstream. This matches the Metadata Gaps table in the
[Project Handoff](../project-handoff.md) and keeps validation deterministic.

## Pull Request Backlog Disposition

Each pull request was test-merged against the remediated `main`. Where the shared lab
test module conflicted, it was resolved by the documented rule — take `main`'s
discovery-driven module and drop the branch's edit, which is now redundant. The full
lab test suite and the contract validator were then run on the merged tree.

**Resolution rule for `scripts/test_lab_validation_contracts.py`:** take `main`'s
version. The branch edit only existed to register that branch's contract, and
discovery now performs that registration automatically.

| PR | Sol | Pre-fix merge state | Post-fix test-merge | Suite on merged tree | Contracts seen | Disposition |
|----|-----|---------------------|---------------------|----------------------|----------------|-------------|
| [#320](https://github.com/judeper/FSI-CopilotGov-Solutions/pull/320) | 16 | Mergeable | Clean | `PASS` | 3 | `BLOCKED` on lab evidence |
| [#321](https://github.com/judeper/FSI-CopilotGov-Solutions/pull/321) | 17 | Conflicting | Resolved by rule | `PASS` | 3 | `BLOCKED` on lab evidence |
| [#322](https://github.com/judeper/FSI-CopilotGov-Solutions/pull/322) | 18 | Conflicting | Resolved by rule | `PASS` | 3 | `BLOCKED` on lab evidence |
| [#323](https://github.com/judeper/FSI-CopilotGov-Solutions/pull/323) | 06 | Conflicting | Resolved by rule | `PASS` | 3 | `BLOCKED` on lab evidence |
| [#324](https://github.com/judeper/FSI-CopilotGov-Solutions/pull/324) | 15 | Conflicting | Resolved by rule | `PASS` | 3 | `BLOCKED` on lab evidence |
| [#325](https://github.com/judeper/FSI-CopilotGov-Solutions/pull/325) | 22 | Conflicting | Resolved by rule | `PASS` | 3 | `BLOCKED` on lab evidence |
| [#326](https://github.com/judeper/FSI-CopilotGov-Solutions/pull/326) | 03 | Conflicting | Resolved by rule | `PASS` | 3 | `BLOCKED` on lab evidence |
| [#327](https://github.com/judeper/FSI-CopilotGov-Solutions/pull/327) | 05 | Conflicting | Resolved by rule | `PASS` | 3 | `BLOCKED` on lab evidence |
| [#328](https://github.com/judeper/FSI-CopilotGov-Solutions/pull/328) | 07 | Conflicting | Resolved by rule | `PASS` | 3 | `BLOCKED` on lab evidence |
| [#329](https://github.com/judeper/FSI-CopilotGov-Solutions/pull/329) | 11 | Conflicting | Resolved by rule | `PASS` | 3 | `BLOCKED` on lab evidence |
| [#330](https://github.com/judeper/FSI-CopilotGov-Solutions/pull/330) | 08 | Conflicting | Residual: `solutions.json`, `solutions-graph.json` | not run | — | `BLOCKED` on F-3 and lab evidence |
| [#331](https://github.com/judeper/FSI-CopilotGov-Solutions/pull/331) | 04 | Conflicting | Resolved by rule | `PASS` | 3 | `BLOCKED` on lab evidence |
| [#332](https://github.com/judeper/FSI-CopilotGov-Solutions/pull/332) | 14 | Conflicting | Resolved by rule | `PASS` | 3 | `BLOCKED` on lab evidence |
| [#333](https://github.com/judeper/FSI-CopilotGov-Solutions/pull/333) | 09 | Conflicting | Resolved by rule | `PASS` | 3 | `BLOCKED` on lab evidence |
| [#334](https://github.com/judeper/FSI-CopilotGov-Solutions/pull/334) | 10 | Conflicting | Resolved by rule | `PASS` | 3 | `BLOCKED` on lab evidence |
| [#335](https://github.com/judeper/FSI-CopilotGov-Solutions/pull/335) | 21 | Conflicting | Residual: `solutions.json` | not run | — | `BLOCKED` on F-3 and lab evidence |
| [#336](https://github.com/judeper/FSI-CopilotGov-Solutions/pull/336) | 23 | Conflicting | Resolved by rule | `PASS` | 3 | `BLOCKED` on lab evidence |
| [#337](https://github.com/judeper/FSI-CopilotGov-Solutions/pull/337) | 19 | Conflicting | Resolved by rule | `PASS` | 3 | `BLOCKED` on lab evidence |
| [#338](https://github.com/judeper/FSI-CopilotGov-Solutions/pull/338) | 20 | Conflicting | Resolved by rule | `PASS` | 3 | `BLOCKED` on lab evidence |
| [#339](https://github.com/judeper/FSI-CopilotGov-Solutions/pull/339) | 13 | Conflicting | Resolved by rule | `PASS` | 3 | `BLOCKED` on lab evidence |
| [#340](https://github.com/judeper/FSI-CopilotGov-Solutions/pull/340) | 12 | Conflicting | Resolved by rule | `PASS` | 3 | `BLOCKED` on lab evidence |

`Contracts seen` is the number of lab contracts the validator discovered on the merged
tree: Solutions 01 and 02 plus the branch's own contract. That count is the direct
evidence that F-2 is remediated — no branch narrows accepted-solution coverage.

**Structural conflict repair: 19 of 20 conflicting pull requests are resolved by a
single documented rule. The remaining 2 need the F-3 metadata correction on their own
branches.**

## Merge Policy Assessment

The merge policy for this program requires repository validation, source grounding,
exact-head independent approval, a clean merge state, and accepted live-lab evidence.

| Gate | State |
|------|-------|
| Repository validation | Satisfied on `main` and on this change (15 of 15 checks). |
| Structural merge state | Repaired for 19 of 20 conflicting pull requests; 2 need F-3. |
| Contract schema validity | Satisfied for all 23 solutions. |
| Accepted live-lab evidence | **Not satisfied** for Solutions 03–23. |
| Exact-head independent approval | Not applicable while evidence is outstanding. |

**Conclusion: no review pull request is eligible for merge.** All 21 remain correctly
draft. This record changes no pull request state, approves nothing, and merges nothing.

## Recommended Next Actions

Ordered, and consistent with the resume sequence in the
[Project Handoff](../project-handoff.md).

1. Land the F-1 and F-2 remediation on `main` so the shared conflict source is gone
   before any branch is rebased.
2. Rebase the 19 rule-resolvable pull requests onto the remediated `main`, taking
   `main`'s `scripts/test_lab_validation_contracts.py` and dropping the branch edit.
3. Apply the F-3 correction to #330 and #335: regenerate `solutions.json` and
   `solutions-graph.json` from `main` and reapply only that branch's own entry.
4. Resolve the Solution 16 account-picker blocker, then continue the serial lab program
   one solution at a time. Never auto-select an identity.
5. Merge only after accepted evidence exists for that solution, one pull request at a
   time, in the documented serial order.
