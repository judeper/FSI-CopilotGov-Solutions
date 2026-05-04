# Repository Threat Model

> **Status:** v1.0 | **Scope:** FSI-CopilotGov-Solutions repository (documentation-first scaffolds) | **Audience:** Adopters, security reviewers

This threat model uses the STRIDE framework (Spoofing, Tampering, Repudiation,
Information Disclosure, Denial of Service, Elevation of Privilege) at a
lightweight, repository level. It is intentionally scoped to the artifacts and
processes that this repository produces and ships. It is **not** a threat model
for any adopter's Microsoft 365 tenant or for the live Microsoft Graph,
Purview, or Power Platform services that downstream solutions integrate with.

## System Overview

FSI-CopilotGov-Solutions is a documentation-first repository: it publishes
control mappings, regulatory traceability, deployment guidance, and PowerShell
and Python sample scripts that operate on representative sample data. The
repository feeds an MkDocs site built by GitHub Actions and is consumed by
adopters who fork or copy it into their own environments and adapt the
scaffolds to their tenants. The trust boundaries that matter for this model
are:

- **Repository content boundary** — markdown, JSON/YAML metadata, and sample
  scripts in source control. Trust is established through pull request review,
  CODEOWNERS, branch protection, and the validators in `scripts/`.
- **CI / build pipeline boundary** — GitHub Actions runners that execute
  validators, build the documentation site, and run security workflows
  (`secret-scan.yml`, `codeql.yml`, `dependency-review.yml`). Runners pull
  third-party dependencies declared in `requirements-docs.txt` and Pester
  modules referenced by tests.
- **Downstream tenant boundary** — adopter-controlled Microsoft 365 tenants
  where forked copies of these scaffolds are eventually adapted to call live
  Microsoft services. This repository never crosses that boundary; tenant
  identity, secrets, and data live entirely on the adopter side.

## In-Scope Assets

- Documentation under `docs/`, `site-docs/`, and per-solution `README.md`,
  `architecture.md`, `deployment-guide.md`, `evidence-export.md`, etc.
- Sample PowerShell and Python scripts under `scripts/` and per-solution
  `scripts/` folders that emit representative sample data.
- Sample evidence-export packages and the schemas under `templates/` and
  `data/evidence-schema*`.
- Control-coverage metadata and control-mapping data under `data/`
  (`solution-catalog.json`, `control-coverage*.json`, regulatory mapping
  assets).
- The build pipeline: GitHub Actions workflows, `mkdocs.yml`, the validators
  in `scripts/validate-*.py` and `scripts/validate-evidence.ps1`, and
  `FRAMEWORK-VERSION` plus `scripts/traceability.py`.

## Out-of-Scope Assets

- **Live tenant data.** This repository never touches Microsoft Graph,
  Purview, Power Platform, or any other live tenant data. Any threats to
  live data belong in the adopter's own tenant threat model.
- **Power Automate runtime artifacts.** Exported flow ZIPs and solution
  packages are intentionally not committed; the repository documents how to
  build flows rather than shipping runnable cloud artifacts.
- **Adopter-side identity configuration.** Conditional Access policies,
  managed identities, app registrations, and secret stores are described in
  guidance documents but are configured and protected by the adopter.

## Threats

For each threat: an ID, a one-line description, the affected asset(s), a
likelihood and impact rating (low / med / high), and a mitigation summary
covering both the controls already in this repository and the recommended
follow-ups for adopters and maintainers.

### Spoofing

| ID | Threat | Affected asset | Likelihood | Impact | Mitigation (current → recommended) |
|----|--------|----------------|------------|--------|-------------------------------------|
| T-001 | A contributor or external actor opens a pull request that impersonates a maintainer or claims false review approvals to land malicious changes. | Repository content, build pipeline | Low | High | Current: branch protection, CODEOWNERS review, GitHub commit signature surface, `SECURITY.md` reporting channel. Recommended: require signed commits on protected branches and enforce two-maintainer review for changes to `scripts/` and `.github/workflows/`. |
| T-002 | An adopter installs a typosquatted package with a name similar to a dependency in `requirements-docs.txt` or a Pester module, believing it to be the legitimate one. | Sample scripts, downstream adopter environments | Low | Med | Current: pinned dependency names in `requirements-docs.txt`, `dependency-review.yml`. Recommended: pin hashes (pip `--require-hashes`) and document the exact PowerShell Gallery module IDs, owners, and minimum versions in each solution's `prerequisites.md`. |

### Tampering

| ID | Threat | Affected asset | Likelihood | Impact | Mitigation (current → recommended) |
|----|--------|----------------|------------|--------|-------------------------------------|
| T-003 | A malicious or compromised upstream dependency in `requirements-docs.txt` or a Pester module pulled at CI time injects code into the build or into a published sample script. | Build pipeline, sample scripts | Low | High | Current: `dependency-review.yml`, `codeql.yml`, pinned dependency versions, validators run on every PR. Recommended: enable Dependabot version updates, pin transitive hashes, and adopt the signed-release workflow tracked under `p2-sbom-and-signing` so adopters can verify what they downloaded. |
| T-004 | An exported evidence-package sample is tampered with in transit between an adopter's CI and the auditor reviewing it (file substitution, modified rows, altered timestamps). | Evidence-export sample data, downstream adopter pipelines | Med | High | Current: `validate-evidence.ps1` checks schema and shape; evidence schemas in `data/` define expected fields. Recommended: adopters should hash-and-sign each evidence package on export, transport over an integrity-checked channel, and verify the signature before submission; the upcoming SBOM / signing work (`p2-sbom-and-signing`) provides a template. |
| T-005 | The framework reference drifts: control mappings in this repo diverge from the upstream FSI-CopilotGov framework because the pin is updated in one place and not the other. | Control-mapping data, documentation | Med | Med | Current: `FRAMEWORK-VERSION` is mirrored in `scripts/traceability.py` (`FRAMEWORK_REPO_REF`), enforced by `validate-documentation.py` (rejects unpinned `main`/`master` framework links). Recommended: a release-time check that the pin matches a signed framework release tag, plus a scheduled CI job that diffs control IDs between repos and opens an issue on drift. |

### Repudiation

| ID | Threat | Affected asset | Likelihood | Impact | Mitigation (current → recommended) |
|----|--------|----------------|------------|--------|-------------------------------------|
| T-006 | Sample evidence packages are submitted to an auditor as if they were real, regulator-grade evidence, and the submitter later disputes that the data was synthetic. | Evidence-export sample data | Med | High | Current: every solution `README.md` carries the documentation-first disclaimer banner, `validate-documentation.py` enforces the standardized status line and disclaimer, and `validate-evidence.ps1` flags packages built from sample data. Recommended: stamp every generated sample evidence package with a clearly visible `SAMPLE — NOT FOR REGULATORY SUBMISSION` watermark and record an unalterable provenance line in the package manifest. |
| T-007 | Control-coverage metadata in `data/` becomes inflated or aspirational relative to the actual behavior of the sample scripts, so the published coverage page misrepresents what the repository does. | Control-coverage metadata, documentation | Med | High | Current: the `p0-control-coverage-honesty` workstream and `docs/reference/control-coverage-honesty.md` document the de-inflation rules; `validate-contracts.py` cross-checks per-solution metadata; language rules in `validate-documentation.py` reject overstated claims. Recommended: tie any future coverage uplift to a passing scaffold test that exercises the claimed behavior, even on sample data. |
| T-008 | An adopter believes the in-repo scripts already produce production-grade evidence and uses their unmodified output to attest to a control. | Sample scripts, evidence-export sample data | Med | High | Current: standardized status line "Documentation-first scaffold" enforced on every solution README, repo-wide disclaimer banner, `docs/documentation-vs-runnable-assets-guide.md` calls out the gap explicitly. Recommended: print a runtime banner from each sample script's entry point that names the synthetic data source and links to the documentation-vs-runnable-assets guide. |

### Information Disclosure

| ID | Threat | Affected asset | Likelihood | Impact | Mitigation (current → recommended) |
|----|--------|----------------|------------|--------|-------------------------------------|
| T-009 | An adopter adapts a sample script to call live Microsoft Graph and accidentally commits a real client secret, certificate, or refresh token into a fork (or back into a PR). | Repository content, downstream adopter environments | Med | High | Current: `secret-scan.yml` runs on PRs, `SECURITY.md` documents responsible disclosure, sample scripts use placeholder credentials. Recommended: ship a `.gitignore`/`pre-commit` template alongside each solution and document `gh secret`/Key Vault patterns in `getting-started/identity-and-secrets-prep.md`; encourage GitHub push protection at the org level. |
| T-010 | Sample evidence or sample configuration files inadvertently include realistic-looking PII, internal hostnames, or tenant IDs that could be mistaken for real data. | Evidence-export sample data, control-mapping data | Low | Med | Current: sample data uses fictional tenant identifiers and naming. Recommended: add a `validate-documentation.py` check (or a paired check in another validator owned by a different agent) that scans sample data for patterns matching real GUIDs, internal domains, or credit-card / SSN-like sequences. |

### Denial of Service

| ID | Threat | Affected asset | Likelihood | Impact | Mitigation (current → recommended) |
|----|--------|----------------|------------|--------|-------------------------------------|
| T-011 | A pull request triggers expensive workflows (long-running CodeQL, repeated docs builds) and exhausts CI minutes for the repository. | Build pipeline | Low | Med | Current: workflows are scoped to relevant paths and run on pull_request; `dependency-review.yml` is incremental. Recommended: cap concurrency per branch (`concurrency:` group) on documentation and security workflows; require maintainer approval to run workflows for first-time external contributors. |
| T-012 | A regression in one of the validators (`validate-documentation.py`, `validate-contracts.py`, `validate-evidence.ps1`) blocks every PR and stalls the contribution pipeline. | Build pipeline | Med | Low | Current: validators are simple and deterministic, with clear error messages; build failures are easy to triage. Recommended: add unit tests for each validator's rule set under `tests/`, and require validator changes to ship with a corresponding test case. |

### Elevation of Privilege

| ID | Threat | Affected asset | Likelihood | Impact | Mitigation (current → recommended) |
|----|--------|----------------|------------|--------|-------------------------------------|
| T-013 | A workflow in `.github/workflows/` runs with broader `GITHUB_TOKEN` permissions than needed and a compromised step uses that token to write to the repository or publish releases. | Build pipeline | Low | High | Current: workflows are scoped to documentation and security checks; CodeQL and secret scanning run with read-only defaults. Recommended: explicitly declare least-privilege `permissions:` blocks at the top of every workflow, enable OIDC for any future deploy steps instead of long-lived secrets, and review this in the signed-release work tracked by `p2-sbom-and-signing`. |
| T-014 | An adopter follows a deployment guide and grants the resulting service principal or managed identity broader Microsoft Graph or Purview permissions than the scaffold actually requires. | Downstream adopter environments | Med | High | Current: per-solution `prerequisites.md` lists required permissions; `getting-started/identity-and-secrets-prep.md` describes the identity story. Recommended: track a managed-identity standard (companion document `docs/security/managed-identity-standard.md`, owned by the parallel `managed-identity-standard` agent) and reference it from every solution's prerequisites page. |

## Mitigations Cross-Reference

The following existing repository controls back the mitigations listed above.
Each entry names the artifact and the threat IDs it addresses.

| Control | Path | Mitigates |
|---------|------|-----------|
| Documentation language and section validator | `scripts/validate-documentation.py` | T-006, T-007, T-008 |
| Catalog and contract validator | `scripts/validate-contracts.py` | T-005, T-007 |
| Evidence-package shape validator | `scripts/validate-evidence.ps1` | T-004, T-006 |
| Secret scanning workflow | `.github/workflows/secret-scan.yml` | T-009 |
| CodeQL workflow | `.github/workflows/codeql.yml` | T-003, T-013 |
| Dependency review workflow | `.github/workflows/dependency-review.yml` | T-002, T-003 |
| Pinned framework reference | `FRAMEWORK-VERSION` (mirrored in `scripts/traceability.py`) | T-005 |
| Security policy | `SECURITY.md` | T-001, T-009 |

## Operator Follow-Up

- **Signed releases and SBOM.** Tracked under `p2-sbom-and-signing`. Once
  releases are signed and an SBOM is published per release, T-003 and T-004
  can be downgraded for adopters who verify signatures and consume only
  signed artifacts.
- **Managed identity standard.** Tracked under the companion
  `docs/security/managed-identity-standard.md`. Per-solution
  `prerequisites.md` should link to it once it lands, supporting T-014.
- **Threat-model review cadence.** Re-review this document at least once
  per semver-minor release of the repository, and additionally whenever a
  new validator is added, a workflow's `permissions:` block changes, or the
  framework pin in `FRAMEWORK-VERSION` is bumped. Record the review date in
  the next section's history line.

## Revision History

- v1.0 — Initial repository-level threat model. STRIDE coverage: 14 threats
  across 6 categories.
