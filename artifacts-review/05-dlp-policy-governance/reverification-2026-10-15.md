# Solution 05 technical re-verification - 2026-10-15

Local handoff for issue #844. Scope: technical product accuracy only, US commercial-cloud Microsoft 365. No regulatory mappings, regulatory wording, runtime code, or tenant state were changed. Version remains v0.2.3; `Last Verified` is 2026-10-15.

## Result and discrepancies

The three modeled capability identifiers and their availability remain accurate: prompt SIT blocking is preview; external web-search restriction and sensitivity-label file/email blocking are generally available. The current Microsoft article also covers Cowork and external-email blocking (preview); neither is silently added to this solution's baseline.

| Discrepancy or missing boundary | Correction / propagation | Source |
|---|---|---|
| README and prerequisites made Power Automate Premium an unconditional exception-flow prerequisite. | Approvals is a standard connector. License the complete connector set rather than requiring Premium for approvals alone; document the approvals database prerequisite. Propagated to deployment, troubleshooting, and delivery checks. | S7 |
| README, prerequisites, deployment, and troubleshooting implied a separate Exchange Online connection was required to read DLP metadata. | `Connect-IPPSSession` provides Security & Compliance cmdlets subject to RBAC. A separate `Connect-ExchangeOnline` session is not a prerequisite. Graph supplies supporting label/Entra policy metadata, not DLP reads through these scopes. Local scaffold scripts need no service connections. Existing connection-stub code is unchanged: opening an additional session is redundant, not a functional failure. | S3-S6 |
| Troubleshooting attributed missing Exchange scope to licensing rather than Copilot-location exclusivity. | Exchange and other workload locations must be represented in separate policies. | S1 |
| Implementation and acceptance guidance omitted important rule and evaluation boundaries. | Added Custom-template-only availability, unsupported administrative units, separate SIT/label rules within one Copilot policy, internal grounding with web-search-only restriction, possible citations after label blocking, up-to-four-hour propagation, and Office file-open evaluation. Propagated to architecture, deployment, troubleshooting, checklist, and evidence instructions. | S1 |
| README duplicated web-search restriction in its capability bullets. | Kept distinct prompt-processing and web-search-only bullets with their different outcomes. | S1 |

## Claims re-checked

| Claim / surface | Outcome |
|---|---|
| Location name, Custom template, location exclusivity, administrative units | Confirmed against S1; no renamed policy location or supported administrative-unit scope inferred from the article's expanded title. |
| Prompt SIT blocking | Preview and rollout-dependent; out-of-box/custom SITs; blocks a response and internal/web searches for that prompt. Confirmed against S1. |
| External web-search restriction | Supported separately from prompt processing; allowed internal sources can still ground a response. Confirmed against S1; no invented GA date. |
| Sensitivity-label file/email blocking | Supported stored/open files and email sent on or after January 1, 2025; no calendar invites. Citations can remain without item content. Confirmed against S1. |
| Direct prompt-uploaded files | This policy location checks typed prompt text, not uploaded file contents. Confirmed against S1; no claim about all Endpoint DLP capabilities. |
| Policy actions and conditions | Three existing config identifiers match S1. SIT and label conditions cannot share a rule, but separate rules can share a policy. |
| Permissions / role names | README examples and prerequisites role/group list remain in S1; Security Reader is not listed for policy create/edit. Least privilege retained. |
| Purview licensing | S2 separates prompt safeguards for Copilot/Copilot Chat users from eligible plans for file/email processing restrictions. No Copilot add-on requirement is inferred solely for Chat prompt safeguards. |
| PowerShell and Graph | S3-S5 confirm Security & Compliance session and read cmdlets. S6 confirms delegated `InformationProtectionPolicy.Read` and `Policy.Read.All`; no organization-wide application access is implied by the former. |
| Power Automate approvals | S7 confirms standard connector licensing, Dataverse prerequisite, and first-run environment-admin database provisioning in a non-default environment. |
| Alerts, notifications, simulation, timing | S1 supports all three operational surfaces, up to four hours for changes, and label evaluation at file open in Word/Excel/PowerPoint. |
| Screenshots / live API integration | README has no screenshots or live Graph DLP endpoint to verify. Repository scripts remain sample/local scaffolds, not tenant validation. |
| Governance tiers, dependencies, evidence names | Repository-defined contracts, not Microsoft feature/licensing promises. Their values and regulatory mappings are unchanged. |

## Sources

All Microsoft sources below were searched/fetched live with the Microsoft Learn tools on 2026-10-15. No Message Center or roadmap rollout date is asserted, so no release-communications lookup was necessary.

- **S1:** [Copilot DLP capabilities, roles, conditions, and limitations](https://learn.microsoft.com/purview/dlp-microsoft365-copilot-location-learn-about)
- **S2:** [Microsoft Purview service description - Copilot DLP licensing](https://learn.microsoft.com/office365/servicedescriptions/microsoft-365-service-descriptions/microsoft-365-tenantlevel-services-licensing-guidance/microsoft-purview-service-description#microsoft-purview-data-loss-prevention-dlp-for-microsoft-copilot)
- **S3:** [Connect to Security & Compliance PowerShell](https://learn.microsoft.com/powershell/exchange/connect-to-scc-powershell)
- **S4:** [Get-DlpCompliancePolicy](https://learn.microsoft.com/powershell/module/exchangepowershell/get-dlpcompliancepolicy)
- **S5:** [Get-DlpComplianceRule](https://learn.microsoft.com/powershell/module/exchangepowershell/get-dlpcompliancerule)
- **S6:** [Microsoft Graph permissions reference](https://learn.microsoft.com/graph/permissions-reference)
- **S7:** [Get started with approvals - prerequisites and licensing](https://learn.microsoft.com/power-automate/get-started-approvals)

## Downstream artifacts reviewed

Discovery searched the solution identifier, title, links, prompt-blocking and web-search claims, and broader Copilot/DLP references across source docs, solutions, metadata, generated docs, and historical reviews. Listed paths are repository-relative. A grouped row explicitly names each artifact with the same disposition.

### Solution-owned implementation and verification artifacts

| Artifact | Disposition and reason |
|---|---|
| `solutions/05-dlp-policy-governance/README.md` | Changed: date, technical corrections, boundaries, live-source links. Regulatory text untouched. |
| `solutions/05-dlp-policy-governance/docs/architecture.md` | Changed: policy/rule boundaries and connection requirements. |
| `solutions/05-dlp-policy-governance/docs/deployment-guide.md` | Changed: optional collection, current portal review checkpoints, licensing and evaluation timing. |
| `solutions/05-dlp-policy-governance/docs/prerequisites.md` | Changed: connector-dependent licensing, database and session requirements, delegated scope clarification. |
| `solutions/05-dlp-policy-governance/docs/troubleshooting.md` | Changed: exclusivity, sessions, rule separation, expected outcomes, timing, upload and licensing guidance. |
| `solutions/05-dlp-policy-governance/docs/evidence-export.md` | Changed: sanitized product-boundary evidence instructions; manual observations distinguished from local script output. |
| `solutions/05-dlp-policy-governance/DELIVERY-CHECKLIST.md` | Changed: acceptance checks mirror product boundaries; no tenant checkbox marked complete. |
| `solutions/05-dlp-policy-governance/CHANGELOG.md` | Changed: appended current review under Unreleased; prior history preserved. |
| `solutions/05-dlp-policy-governance/config/default-config.json` | Unchanged: three capabilities, availability, canonical action/condition names, exclusivity, and no-admin-unit metadata already match S1. |
| `solutions/05-dlp-policy-governance/config/baseline.json`, `solutions/05-dlp-policy-governance/config/recommended.json`, `solutions/05-dlp-policy-governance/config/regulated.json` | Unchanged: local tier intent, not native portal mode names; no capability lifecycle change or tier/regulatory redesign required. |
| `solutions/05-dlp-policy-governance/scripts/Deploy-Solution.ps1`, `solutions/05-dlp-policy-governance/scripts/Common-Functions.ps1` | Unchanged: local templates and optional connection stubs. No live DLP creation or automatic product-boundary verification added. |
| `solutions/05-dlp-policy-governance/scripts/Monitor-Compliance.ps1`, `solutions/05-dlp-policy-governance/scripts/Export-Evidence.ps1` | Unchanged: local comparisons and existing evidence format. Documentation explicitly requires a separate sanitized record for product-boundary observations. |
| `solutions/05-dlp-policy-governance/tests/05-dlp-policy-governance.Tests.ps1` | Unchanged: structural/config/syntax tests still apply; not tenant-enforcement tests. |
| `solutions/05-dlp-policy-governance/lab/05-dlp-policy-governance.lab.json` | Absent in this worktree; no contract to regenerate or claim executed. Historical review-branch status is not proof of a main-branch contract or accepted lab. |

### Dependents, catalogs, and metadata

| Artifact | Disposition and reason |
|---|---|
| `solutions/07-conditional-access-automation/README.md` | Unchanged: depends on a reviewed DLP baseline, not Premium approvals or a separate Exchange session. No repeated corrected mechanism. |
| `solutions/07-conditional-access-automation/DELIVERY-CHECKLIST.md` | Unchanged: requires tenant validation of Solution 05; current review does not complete that dependency. |
| `solutions/07-conditional-access-automation/docs/architecture.md` | Unchanged: generic DLP dependency; does not restate the corrected licensing/session/rule claims. |
| `solutions/07-conditional-access-automation/docs/deployment-guide.md` | Unchanged: readiness reference only; its Conditional Access Graph permissions are a different surface. |
| `solutions/07-conditional-access-automation/docs/prerequisites.md` | Unchanged: dependency and Conditional Access requirements, not Copilot DLP implementation detail. |
| `solutions/07-conditional-access-automation/config/default-config.json` | Unchanged: dependency identifier remains valid. |
| `README.md`, `DEPLOYMENT-GUIDE.md`, `AGENTS.md`, `mkdocs.yml`, `scripts/solution-config.yml` | Unchanged: solution name, links, navigation, priority, version, tier, and scaffold status remain valid. |
| `docs/solutions/index.md` | Unchanged after generator: only solution name/priority/control identifiers, no repeated corrected claim. |
| `docs/reference/control-coverage.md`, `docs/reference/control-coverage-honesty.md` | Unchanged: coverage identifiers/state are not changed by a product-source review. |
| `docs/reference/data-classification.md`, `docs/reference/examination-readiness.md` | Unchanged: classification/evidence identifiers and regulatory mappings preserved. |
| `docs/reference/tier-applicability.md` | Unchanged after generator: tier applicability unchanged. |
| `docs/project-handoff.md`, `docs/reference/solution-review-disposition.md` | Unchanged: historical review/serial lab status, not a claim that this worktree has accepted Solution 05 lab evidence. |
| `data/solution-catalog.json`, `data/solution-to-playbooks.json` | Unchanged: version, identity, dependencies, artifact names, and upstream links unchanged; see external-reference caveat below. |
| `data/control-coverage.json`, `data/data-classification.json`, `data/frameworks-master.json`, `data/controls-master.json` | Unchanged: canonical mappings/classification/control titles; no regulatory reassessment or corrected product mechanism to propagate. |
| `templates/regulatory-mappings/dora.json`, `templates/regulatory-mappings/finra-4511.json`, `templates/regulatory-mappings/gdpr.json`, `templates/regulatory-mappings/glba-501b.json`, `templates/regulatory-mappings/sec-reg-sp.json`, `templates/regulatory-mappings/sox-302-404.json` | Unchanged: regulation-to-solution references intentionally preserved. |

### Broader repeated-claim search results

| Artifact | Disposition and reason |
|---|---|
| `solutions/06-audit-trail-manager/docs/troubleshooting.md`, `solutions/06-audit-trail-manager/CHANGELOG.md` | Unchanged: retention troubleshooting and historical review, not the corrected Copilot DLP mechanisms. |
| `solutions/08-license-governance-roi/README.md`, `solutions/08-license-governance-roi/docs/architecture.md` | Unchanged: unrelated license/cost/reporting claims matched broad search terms; no correction in this review propagates to them. |
| `solutions/09-feature-management-controller/README.md`, `solutions/09-feature-management-controller/DELIVERY-CHECKLIST.md`, `solutions/09-feature-management-controller/CHANGELOG.md` | Unchanged: Cloud Policy service web-search governance, not prompt-SIT DLP web-search restriction. |
| `solutions/09-feature-management-controller/docs/architecture.md`, `solutions/09-feature-management-controller/docs/deployment-guide.md`, `solutions/09-feature-management-controller/docs/evidence-export.md`, `solutions/09-feature-management-controller/docs/prerequisites.md` | Unchanged: Cloud Policy feature-state/permission/evidence surface, not a restatement of corrected DLP claims. |
| `solutions/09-feature-management-controller/config/default-config.json`, `solutions/09-feature-management-controller/config/baseline.json`, `solutions/09-feature-management-controller/config/recommended.json`, `solutions/09-feature-management-controller/config/regulated.json` | Unchanged: separate `Allow web search in Copilot` control. |
| `solutions/14-communication-compliance-config/docs/architecture.md`, `solutions/14-communication-compliance-config/docs/evidence-export.md`, `solutions/14-communication-compliance-config/CHANGELOG.md` | Unchanged: Insider Risk Management AI signals/history, not Copilot DLP blocking conditions. |
| `solutions/15-pages-notebooks-gap-monitor/docs/architecture.md` | Unchanged: Pages DLP surface, not this dedicated policy-location contract. |

### Generated outputs and historical records

| Artifact | Disposition and reason |
|---|---|
| `site-docs/solutions/05-dlp-policy-governance/index.md` | Changed by generator: README corrections/date/source links mirrored. |
| `site-docs/solutions/05-dlp-policy-governance/architecture.md`, `site-docs/solutions/05-dlp-policy-governance/deployment-guide.md`, `site-docs/solutions/05-dlp-policy-governance/evidence-export.md`, `site-docs/solutions/05-dlp-policy-governance/prerequisites.md`, `site-docs/solutions/05-dlp-policy-governance/troubleshooting.md` | Changed by generator: corresponding implementation/evidence guidance mirrored. |
| `site-docs/solutions/07-conditional-access-automation/index.md`, `site-docs/solutions/07-conditional-access-automation/architecture.md`, `site-docs/solutions/07-conditional-access-automation/deployment-guide.md`, `site-docs/solutions/07-conditional-access-automation/prerequisites.md` | Unchanged after generator: source dependency guidance unchanged. |
| `site-docs/solutions/index.md`, `site-docs/project-handoff.md` | Unchanged after generator: source catalog/historical status unchanged. |
| `site-docs/reference/control-coverage.md`, `site-docs/reference/control-coverage-honesty.md`, `site-docs/reference/data-classification.md`, `site-docs/reference/examination-readiness.md`, `site-docs/reference/tier-applicability.md`, `site-docs/reference/solution-review-disposition.md` | Unchanged after generator: source mapping/status/tier artifacts unchanged. |
| `solutions.json`, `solutions-graph.json` | Regenerated: generation timestamps only; no modeled name, version, controls, counts, or metadata changed. Neither schema carries Last Verified; that date is mirrored in the generated solution page. |
| `artifacts-review/05-dlp-policy-governance/review-2026-05-04.md`, `artifacts-review/_metadata-deltas/05-dlp-policy-governance.json` | Unchanged: immutable prior review/version-delta record, not current deployment instructions. |
| `artifacts-review/_summary/review-2026-05-04-summary.md`, `artifacts-review/_summary/remediation-2026-05-04-summary.md`, `artifacts-review/_summary/triage-2026-05-22.md` | Unchanged: historical findings, not rewritten as current technical guidance. |

### Linked framework playbooks (outside this worktree)

`data/solution-to-playbooks.json` links to the separate `judeper/FSI-CopilotGov` repository. Read-only review used the repository's pinned ref `e0fb7b769529dcc008cc2066402cdabae4f369cf` from `scripts/traceability.py`, not an unpinned branch. These are not local runtime dependencies and were not edited or executed.

All paths below are relative to that external repository:

| Artifact | Disposition and technical review |
|---|---|
| `docs/playbooks/control-implementations/2.1/portal-walkthrough.md` | Unchanged externally; outstanding product discrepancies: mandatory separate SIT/label policies and optional other locations in a Copilot policy contradict S1. Its universal E5 prerequisite must not replace S2's prompt/file distinction. |
| `docs/playbooks/control-implementations/2.1/powershell-setup.md` | Unchanged externally; insists on separate policies. Only the documented read/session pattern was reused here; no creation examples were executed or adopted. |
| `docs/playbooks/control-implementations/2.1/verification-testing.md` | Unchanged externally; assumes separate policies and universal default-policy presence. Its criteria are not imported as this scaffold's acceptance tests; preview availability and content-vs-citation outcomes must be reviewed using S1. |
| `docs/playbooks/control-implementations/2.1/troubleshooting.md` | Unchanged externally; mandatory separate policies, universal E5 prerequisites, and 24-hour Copilot propagation guidance differ from S1/S2. Local troubleshooting now states separate rules, location exclusivity, the licensing distinction, and up-to-four-hour Copilot propagation. |
| `docs/playbooks/control-implementations/3.10/portal-walkthrough.md`, `docs/playbooks/control-implementations/3.10/powershell-setup.md` | Unchanged externally; DLP setup mixes workload/governance examples. Do not treat these as a supported same-policy Copilot-location recipe or import their broader license/Graph-write prerequisites into read-only Solution 05. Regulatory statements were not reassessed. |
| `docs/playbooks/control-implementations/3.10/verification-testing.md`, `docs/playbooks/control-implementations/3.10/troubleshooting.md` | Unchanged externally; workload transmission/response examples are not this location's typed-prompt or label enforcement criteria. Local evidence instructions separate those surfaces. Regulatory statements were not reassessed. |
| `docs/playbooks/control-implementations/3.12/portal-walkthrough.md`, `docs/playbooks/control-implementations/3.12/powershell-setup.md` | Unchanged externally; generic evidence collection. The PowerShell DLP read pattern uses `Connect-IPPSSession`, consistent with S3-S5. Broader evidence-product licensing is not a requirement for this scaffold's local export. |
| `docs/playbooks/control-implementations/3.12/verification-testing.md`, `docs/playbooks/control-implementations/3.12/troubleshooting.md` | Unchanged externally; generic evidence completeness/storage checks, no repeated corrected Copilot DLP mechanism. |

**External follow-up:** the trusted parent should route the above product-only framework discrepancies to that repository's owner. This local commit does not repair pinned external content or certify it as current. No external regulatory statement, mapping, or retention requirement was changed. Use the corrected local guides and S1-S7 for this solution's technical boundaries.

## Generators

Run from the repository root:

```powershell
python scripts\build-docs.py
python scripts\build_solutions_json.py
python scripts\build_solutions_graph.py
```

`build-docs.py` regenerated `site-docs/` and the tier matrix; only the six Solution 05 pages listed above changed. Index/graph builders regenerated `solutions.json` and `solutions-graph.json` with timestamp-only differences. No `build_content_graph.py` exists in this repository. Generated files were not hand-edited.

## Validation and execution boundary

Local validation passed:

- `python scripts\test_docs_protection.py` - 5 tests.
- `python scripts\validate-contracts.py`, `python scripts\validate-solutions.py`, `python scripts\validate-documentation.py` - passed; 23 solutions and 381 Markdown files checked.
- `python scripts\validate_solutions_json.py`, `python scripts\validate_solutions_graph.py`, `python scripts\validate_data_classification.py`, `python scripts\verify_readme_counts.py`, `python scripts\verify_commercial_scope.py`, `python scripts\sync-agent-md-versions.py --check` - passed.
- `python scripts\validate-lab-contracts.py`, `python scripts\validate-lab-result.py`, `python scripts\test_lab_validation_contracts.py` - passed; 2 existing contracts, no solution result files, and 12 validator tests. This does not imply a Solution 05 lab run.
- `python -m mkdocs build --strict` - passed.
- Pester **5.7.1** with `Run.Exit = $true`, targeting `solutions\05-dlp-policy-governance\tests\05-dlp-policy-governance.Tests.ps1` and `scripts\tests\lab-validation.Tests.ps1` - **15 passed, 0 failed**.
- `scripts\validate-lab-package.ps1` against `scripts\tests\fixtures\lab-package\portable-evidence.json` and the matching valid Solution 01 result fixture - passed.
- `scripts\validate-evidence.ps1 -ConfigurationTier baseline` - all **23** sample solution exports passed.
- Parsed every repository `.ps1` with the PowerShell language parser - no errors.
- `git diff --check` - passed. Exact comparisons confirmed the README regulatory overview/alignment text is unchanged, all six generated Solution 05 pages match their sources, and index/graph differences are timestamps only.

The archived Linus override references `verify_controls.py` and `verify_language_rules.py`; neither exists here. The repository's current documentation/solution/contract/language validators above were used instead.

No browser automation, tenant enforcement test, Power Platform artifact authoring, credential inspection, GitHub operation, remote push, or issue/PR write was performed. This is source re-verification plus local validation, not accepted lab evidence. The trusted parent owns publication and should include this report's Sources and Downstream artifacts reviewed sections in its PR description.
