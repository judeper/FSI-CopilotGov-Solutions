# Project Handoff

Durable handoff for the FSI-CopilotGov-Solutions accuracy-review and lab-validation
program. This page is the single, authoritative resume point for the next operator
or agent. It records what has been verified, what remains, and the exact sequence
required to resume safely.

> **Cloud scope.** This content targets US commercial-cloud Microsoft 365 only. See the
> [Disclaimer](./disclaimer.md).

> ⚠️ **Documentation-first repository.** Scripts and lab contracts use representative
> sample data and do not connect to live Microsoft 365 services in their repository form.
> No live-tenant or Playwright lab run has executed. See
> [Documentation vs Runnable Assets Guide](./documentation-vs-runnable-assets-guide.md).

## Snapshot

| Field | Value |
|-------|-------|
| Snapshot date | 2026-07-15 |
| Repository branch | `main` — read the current commit from Git; this page records durable phase state rather than a self-staling HEAD |
| Phase | Serial accuracy review **complete**; governance adapter **merged**; Solution 01 lab **PARTIAL / not accepted** |
| Draft review PRs | 23 open (one per solution); all checks green; all held with `Lab status: pending` |
| Live lab runs executed | 1 — Solution 01 read-only cycle completed; no accepted evidence yet |
| Final versioning / merges | Not started — no review PR has been merged |

## Merged Foundation and Handoff

The documentation-autonomy and lab-contract foundation is merged into `main`:

| PR | Purpose | Merge commit |
|----|---------|--------------|
| [#315](https://github.com/judeper/FSI-CopilotGov-Solutions/pull/315) | Docs autonomy protection contract | `c280fad` |
| [#316](https://github.com/judeper/FSI-CopilotGov-Solutions/pull/316) | Lab validation contract foundation (schemas, validators, fixtures) | `36cf7de` |
| [#318](https://github.com/judeper/FSI-CopilotGov-Solutions/pull/318) | Align lab scope contracts with the commercial-scope linter | `61e8921` |
| [#341](https://github.com/judeper/FSI-CopilotGov-Solutions/pull/341) | Durable project handoff, repository hygiene, and agent workflow guidance | `361d34d` |

## Draft Review PRs (serial review order)

All 23 solutions were reviewed **one at a time** for Microsoft product and feature
accuracy against first-party Microsoft sources, then hardened for read-only lab
validation. Rows are listed in the serial review sequence (PR order). The **released
version** column is the released version retained by each draft; the review changes are
**not merged** into `main`. Every PR is a green draft held with
`Lab status: pending`.

> **Solution 08 version note.** The table uses the corrected v0.1.4 carried by
> PR #330 and the solution README/changelog. Current `main` still reports v0.1.3
> in `config/default-config.json` and `solutions.json`; PR #330 owns that
> reconciliation and must preserve it during finalization.

| Sol | Solution | PR | Released version | Verified review outcome | Checks | Lab |
|-----|----------|----|------------------|-------------------------|--------|-----|
| 01 | Copilot Readiness Assessment Scanner | [#317](https://github.com/judeper/FSI-CopilotGov-Solutions/pull/317) | v0.2.3 | Restored the Microsoft 365 Copilot Optimization Assessment name; clarified Retrieval API licensing vs preview pay-as-you-go; added Restricted Content Discovery as a control 1.7 readiness input; added the first read-only five-control lab contract. **Conflicting with `main` — deferred to post-lab finalization.** | Green | PARTIAL / not accepted |
| 02 | Oversharing Risk Assessment and Remediation | [#319](https://github.com/judeper/FSI-CopilotGov-Solutions/pull/319) | v0.2.4 | Migrated go-forward guidance from Restricted SharePoint Search to Restricted Content Discovery; recorded the RSS new-enablement block (2026-07-31); updated SAM roles and the Microsoft 365 E7 entitlement path; fixed detect-only counts and portable evidence; added a six-control read-only lab contract. | Green | Pending |
| 16 | Item-Level Oversharing Scanner | [#320](https://github.com/judeper/FSI-CopilotGov-Solutions/pull/320) | v0.1.3 | Synced item-level guidance with RSS retirement and Restricted Content Discovery; documented Graph owner/non-owner visibility limits; enforced the auto-remediation kill switch and HIGH/AnyoneLink approval gates; added ShouldProcess/-WhatIf protection; five-control read-only lab contract. | Green | Pending |
| 17 | SharePoint Permissions Drift Detection | [#321](https://github.com/judeper/FSI-CopilotGov-Solutions/pull/321) | v0.1.4 | Fixed a StrictMode drift-scan crash and stopped failed scans from reporting `NoDriftDetected`; gated approval/reversion behind ShouldProcess/-WhatIf; calibrated config-driven scoring; portable evidence; four-control read-only lab contract. | Green | Pending |
| 18 | Entra Access Reviews Automation | [#322](https://github.com/judeper/FSI-CopilotGov-Solutions/pull/322) | v0.1.5 | Fixed empty live-result handling and upstream dependency status; aligned access-review API enums, apply behavior, and tier settings; added end-to-end WhatIf safety and run-scoped evidence provenance; four-control read-only lab contract. | Green | Pending |
| 06 | Copilot Interaction Audit Trail Manager | [#323](https://github.com/judeper/FSI-CopilotGov-Solutions/pull/323) | v0.2.3 | Refreshed Microsoft Purview Audit and unified eDiscovery terminology, roles, and service-default retention; separated service defaults from solution-defined retention intent; corrected evidence aggregation and portable paths; five-control read-only lab contract. | Green | Pending |
| 15 | Copilot Pages and Notebooks Compliance Gap Monitor | [#324](https://github.com/judeper/FSI-CopilotGov-Solutions/pull/324) | v0.1.3 | Refreshed Copilot Pages/Notebooks/Loop/SharePoint Embedded/Purview guidance; reclassified indexing/export items as rollout-sensitive `validation-required` gaps; added a Solution 06 dependency read-back; four-control read-only lab contract. | Green | Pending |
| 22 | Pages and Notebooks Retention Tracker | [#325](https://github.com/judeper/FSI-CopilotGov-Solutions/pull/325) | v0.1.3 | Refreshed Pages/Notebooks/Loop/SharePoint Embedded storage and retention guidance; treated the eDiscovery custodian picker and Roadmap 561492 review-set behavior as tenant-validation states; true read-only -WhatIf; lab contract. | Green | Pending |
| 03 | Sensitivity Label Coverage Auditor | [#326](https://github.com/judeper/FSI-CopilotGov-Solutions/pull/326) | v0.2.4 | Re-verified Graph v1.0 label extraction/assignment, metered-API prerequisites, auto-labeling limits, and label-group migration; removed the government-only G5 SKU to align with commercial scope; read-only/detect-only lab contract. | Green | Pending |
| 05 | DLP Policy Governance for Copilot | [#327](https://github.com/judeper/FSI-CopilotGov-Solutions/pull/327) | v0.2.3 | Updated Copilot DLP lifecycle (web-search restriction GA, label-blocking GA, sensitive-prompt and external-email controls preview); documented scope/exclusivity boundaries; fixed a StrictMode export and made evidence relocatable; read-only lab contract. | Green | Pending |
| 07 | Conditional Access Policy Automation for Copilot | [#328](https://github.com/judeper/FSI-CopilotGov-Solutions/pull/328) | v0.2.5 | Re-verified Copilot targeting via the Graph `Office365` Conditional Access app suite; added Microsoft-managed/Baseline ownership boundaries and break-glass exclusions; fixed an OrderedDictionary safety-metadata bug; disabled live `-Execute` writes; read-only lab contract. | Green | Pending |
| 11 | Risk-Tiered Rollout Automation | [#329](https://github.com/judeper/FSI-CopilotGov-Solutions/pull/329) | v0.1.3 | Re-verified Copilot SKU discovery, `assignLicense` APIs, least-privilege, and group-based licensing; requires tenant `/subscribedSkus` discovery; kept assignment-intent staging preview-only so scripts never assign or remove licenses; read-only lab contract. | Green | Pending |
| 08 | License Governance and ROI Tracker | [#330](https://github.com/judeper/FSI-CopilotGov-Solutions/pull/330) | v0.1.4 | Restored the GA Graph v1.0 `copilot/reports` routes (fixed a beta regression); reconciled the already-released v0.1.4 without a new bump; removed volatile per-credit dollar claims; sanitized identity fields with fail-closed cleanup; read-only lab contract. | Green | Pending |
| 04 | FINRA Supervision Workflow for Copilot | [#331](https://github.com/judeper/FSI-CopilotGov-Solutions/pull/331) | v0.2.3 | Refreshed Communication Compliance guidance for Copilot interactions; required Dataverse `EntitySetName` discovery; replaced the immutable-log overstatement with an append-only governance pattern; made exports fail closed for repository paths; read-only lab contract. | Green | Pending |
| 14 | Communication Compliance Configurator | [#332](https://github.com/judeper/FSI-CopilotGov-Solutions/pull/332) | v0.2.4 | Refreshed Communication Compliance portal/role/reviewer/licensing/PAYG guidance; documented the supported Security & Compliance PowerShell surface; removed active-verb overstatement; added tenant-proof and fail-closed cleanup to a read-only lab contract. | Green | Pending |
| 09 | Copilot Feature Management Controller | [#333](https://github.com/judeper/FSI-CopilotGov-Solutions/pull/333) | v0.1.3 | Defined the boundary between Copilot Control System feature settings and Microsoft Agent 365/agent-registry governance; documented Teams meeting/calling Copilot policy cmdlets; recorded that no documented Graph API for Copilot feature settings was identified; read-only lab contract. | Green | Pending |
| 10 | Copilot Connector and Plugin Governance | [#334](https://github.com/judeper/FSI-CopilotGov-Solutions/pull/334) | v0.2.3 | Refreshed synced vs federated connector and MCP guidance; restored the documented preview Package Management Graph API with exact read-only endpoint/permission/license/role prerequisites; aligned inventory with the Agent 365 registry; read-only lab contract. | Green | Pending |
| 21 | Cross-Tenant Agent Federation Auditor | [#335](https://github.com/judeper/FSI-CopilotGov-Solutions/pull/335) | v0.1.3 | Removed fabricated native federation, Entra Agent ID signing/key-rotation, and MCP attestation claims; reframed around Entra cross-tenant access settings, MCP connection reviews, and Agent 365 registry inventory; two-tenant read-only lab contract. | Green | Pending |
| 23 | Copilot Studio Agent Lifecycle Tracker | [#336](https://github.com/judeper/FSI-CopilotGov-Solutions/pull/336) | v0.1.4 | Refreshed Agent 365 registry and Copilot Studio publish/republish lifecycle; documented solution-based ALM (managed/unmanaged solutions, pipelines, `pac` CLI); recorded that no canonical one-click rollback API was identified; read-only lab contract. | Green | Pending |
| 19 | Copilot Tuning Governance | [#337](https://github.com/judeper/FSI-CopilotGov-Solutions/pull/337) | v0.1.4 | Re-verified Copilot Tuning guidance (2026-07-14); kept the released v0.1.4 and recorded the review under `Unreleased`; added a read-only lab contract and hardened evidence-package portability. | Green | Pending |
| 20 | Generative AI Model Governance Monitor | [#338](https://github.com/judeper/FSI-CopilotGov-Solutions/pull/338) | v0.1.3 | Re-verified Microsoft Foundry, Azure OpenAI Guardrail, and Azure AI Content Safety guidance (2026-07-14); kept the released v0.1.3; added a read-only lab contract and strengthened identity proof, sidecar verification, and evidence minimization. | Green | Pending |
| 13 | DORA Operational Resilience Monitor | [#339](https://github.com/judeper/FSI-CopilotGov-Solutions/pull/339) | v0.1.3 | Re-verified Microsoft 365 Service Health, Microsoft Graph, Microsoft Sentinel, and official DORA guidance (2026-07-14); kept the released v0.1.3; added a read-only lab contract and made freshness/DORA-timeline behavior testable. | Green | Pending |
| 12 | Regulatory Compliance Dashboard | [#340](https://github.com/judeper/FSI-CopilotGov-Solutions/pull/340) | v0.1.3 | Terminal aggregation review against current Power BI and Microsoft Fabric guidance (2026-07-14); kept the released v0.1.3; reconciled dashboard coverage status, upstream evidence lineage, freshness/hash, and lab-disposition semantics; final read-only lab contract. | Green | Pending |

## Architecture and Ownership Boundary

Two repositories cooperate; their responsibilities do not overlap:

- **FSI-CopilotGov-Solutions (this repository)** owns the **versioned lab contracts,
  results, and package validation**: the contract and result schemas
  (`data/lab-validation-contract.schema.json`, `data/lab-validation-result.schema.json`),
  the deterministic validators (`scripts/validate-lab-contracts.py`,
  `scripts/validate-lab-result.py`, `scripts/validate-lab-package.ps1`), the fixtures,
  and each solution's `lab/<solution>.lab.json` contract. This repository stays
  documentation-first and never executes browser automation or attended tenant runs.
- **`studio-video-factory`** owns **Playwright execution and evidence capture**: it
  runs each contract against a tenant and emits `*.lab-result.json` results and portable,
  hash-verified evidence packages that this repository's validators then check.

The result file is the authoritative disposition record. Evidence packages remain
portable, hash-verified artifacts reviewable independently of the execution host. See
[Lab Validation Contract](./reference/lab-validation-contract.md).

### Studio implementation status

- [studio-video-factory PR #11](https://github.com/judep_microsoft/studio-video-factory/pull/11)
  merged the offline-by-default governance adapter foundation.
- [studio-video-factory PR #12](https://github.com/judep_microsoft/studio-video-factory/pull/12)
  merged attended evidence replay, the privacy-gated Solution 01 collector, and
  FSI-compatible package sidecars/versioning.

## Lab Execution Status

Solution 01 ran against pinned FSI commit
`e8bae78b1036c6b55d7597d576df03b69e9418c4`.

- **Result:** `PARTIAL`, `accepted: false`, `controlImplementation: partial`.
- **Passed:** three documentation-first PowerShell checks plus the two manual
  no-mutation/separation attestations.
- **Blocked:** Microsoft 365/Entra portal checks, the combined Purview/Defender/
  SharePoint/Teams portal check, and the Copilot D7 usage-report API.
- **Observed:** Power Platform admin center was authenticated; six required admin
  surfaces redirected to sign-in. The Graph endpoint returned 403 and no response
  body/token was retained.
- **Validation:** both `validate-lab-result.py` and `validate-lab-package.ps1` pass.
- **Evidence hashes:** result
  `30cd35255c1f30d1382a8c510f5f5e6b9cf6293b4e40f82dcb3d315297a03548`;
  package
  `4f1bbae69490834685eac2d3753d1c6a18bbb286ce01a4aa64f773b5d3d2c9b3`.
- **PR record:** [Solution 01 lab update](https://github.com/judeper/FSI-CopilotGov-Solutions/pull/317#issuecomment-4983757488).

## Pending Gates and Known Blockers

- **Solution 01 authentication/permission remediation (current serial gate).**
  Seed attended governance auth for the six login-walled admin surfaces and
  provide effective `Reports.Read.All` access for the D7 Copilot report, then
  rerun the pinned contract. Do not proceed to Solution 02 until Solution 01
  reaches an accepted PASS/BLOCKED/NOT-APPLICABLE disposition.
- **PR #317 conflict (deliberately deferred).** Solution 01's PR conflicts with `main`
  and is intentionally held for **post-lab finalization**. The other 22 review PRs are
  mergeable but remain unmerged with `Lab status: pending`.
- **No finalization has occurred.** No live-tenant or Playwright lab run has executed,
  no accepted evidence exists, and no review PR has been versioned-final, rebased, or merged.

## Metadata Gaps

The following canonical controls are not yet present upstream in the machine-checked
control set; the corresponding contracts intentionally omit unknown IDs from
machine-checked arrays so validation stays deterministic:

| Missing control | Solution | Notes |
|-----------------|----------|-------|
| 2.17 | 21 — Cross-Tenant Agent Federation Auditor | Omitted from machine-checked arrays until canonical |
| 3.14 | 22 — Pages and Notebooks Retention Tracker | Omitted from machine-checked arrays until canonical |
| 4.14 | 23 — Copilot Studio Agent Lifecycle Tracker | Omitted from machine-checked arrays until canonical |

## Next-Step / Resume Sequence

Execute in order. Do not run labs in parallel; the review and lab program is serial.

1. **Remediate Solution 01 prerequisites.** Complete attended sign-in for the
   six blocked admin surfaces and authorize the read-only report permission.
2. **Rerun Solution 01.** Reuse the pinned contract and privacy-gated evidence
   workflow; accept only PASS/BLOCKED/NOT-APPLICABLE with required evidence.
3. **Continue labs one at a time.** After Solution 01 is accepted, execute each
   remaining contract serially. The first cycle is
   read-only/detect-only (`mutations: []` normally); no tenant mutation is permitted.
4. **Capture and accept evidence.** Emit `*.lab-result.json` and portable evidence
   packages. Accepted `BLOCKED` and `NOT-APPLICABLE` dispositions require negative
   evidence **and** source verification and must not claim implemented control state.
   Do not include raw identifiers, secrets, or PII in evidence.
5. **Recheck, version, rebase, merge.** After accepted evidence, recheck sources, apply
   versioning where required, resolve PR #317's existing conflict, and merge all PRs
   one at a time in the documented serial order.

## Critical Gotchas

Durable engineering rules verified during the review program:

- **Read-only first cycle.** The first lab cycle is detect-only; contracts normally
  declare `mutations: []`. Any non-null `mutationRef` must resolve to a declared mutation.
- **Negative + source evidence for non-PASS dispositions.** Accepted `BLOCKED` and
  `NOT-APPLICABLE` require both negative evidence and source verification.
- **Evidence path portability.** Package artifact paths are **relative** (relocatable),
  while caller-returned artifact paths are **absolute**.
- **Provider-aware PowerShell paths.** Never use raw `GetFullPath` on relative input;
  resolve paths provider-aware so output stays portable.
- **Pester 5.7.1 + `Run.Exit`.** Pin Pester `5.7.1` and set the run configuration
  `Run.Exit` to `true` so failures propagate a non-zero exit code in CI.
- **Pester data-driven tests.** Do not define Pester tests inside a PowerShell
  `foreach` loop that relies on captured loop variables; use Pester's `-ForEach`
  parameter so values remain available at run time.
- **Strict MkDocs.** The site must build clean under `mkdocs build --strict`.
- **Commercial-only contracts.** Forward-facing solution contracts omit the optional
  `prohibitedClouds` field and rely on the commercial-scope constants.
- **No sensitive data in evidence.** No raw identifiers, secrets, or PII in any evidence
  artifact.

## Validation Commands

Run from the repository root before pushing documentation or contract changes:

```powershell
python scripts/test_docs_protection.py
python scripts/build-docs.py
python scripts/validate-contracts.py
python scripts/validate-solutions.py
python scripts/validate-documentation.py
python scripts/validate_solutions_json.py
python scripts/validate_solutions_graph.py
python scripts/validate_data_classification.py
python scripts/verify_readme_counts.py
python scripts/verify_commercial_scope.py
python scripts/validate-lab-contracts.py
python scripts/validate-lab-result.py
python scripts/test_lab_validation_contracts.py
python -m mkdocs build --strict
pwsh -Command "Get-ChildItem -Recurse -Filter *.ps1 | ForEach-Object { [System.Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$null, [ref]$null) | Out-Null }"
```

## Git Hygiene Policy

- **One modifying agent per worktree.** A modifying agent owns its worktree exclusively.
  Never run `git checkout` in another agent's worktree.
- **Remove clean local worktrees/branches after push.** Once a branch is pushed and the
  local worktree is clean, remove the worktree and local branch; prune merged worktrees.
- **Preserve remote open-PR branches.** Do not delete remote branches that back an open PR.
- **Delete merged remotes.** Remote branches for merged foundation PRs #315, #316, and
  #318 are safe to delete.

### Cleanup State

The July 2026 hygiene pass removed the 17 review worktrees, all local review
branches, the merged remote branches for #315/#316/#318, and classified generated
leftovers. The temporary handoff worktree/local branch is removed after this handoff
PR is pushed. The resulting steady state is:

- Root repository on `main` only, with no review worktrees and no local review branches.
- Merged remote branches for #315, #316, and #318 deleted.
- Remote branches backing the 23 open review PRs preserved.
- Generated leftovers removed (built `site/`, `__pycache__`, and other cache output).

## What Has NOT Happened

To prevent a false-progress restart, the following are explicitly **not** done:

- No accepted lab evidence exists.
- Solutions 02–23 have not started lab execution.
- No review PR has been versioned-final, rebased onto latest `main`, or merged.
- Solution 01 (PR #317) remains conflicting and deferred.
