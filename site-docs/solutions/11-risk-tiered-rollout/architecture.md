# Architecture

## Solution Purpose

Risk-Tiered Rollout Automation documents Copilot rollout coordination by risk tier so lower-risk users can enter earlier pilot waves while regulated and privileged users wait for stronger prerequisite coverage and explicit approvals. The design assumes a documentation-first implementation for Power Automate and Power BI assets and uses PowerShell to generate auditable manifests, staged assignment plans, and monitoring outputs.

## Component Diagram

```text
+----------------------------------------------+
| 01-copilot-readiness-scanner                 |
| readiness-scorecard and remediation outputs  |
+----------------------------------------------+
                     |
                     v
+----------------------------------------------+
| Risk Tier Classifier                         |
| - Applies Tier 1, Tier 2, Tier 3 rules       |
| - Tags users with prerequisite expectations   |
+----------------------------------------------+
                     |
                     v
+----------------------------------------------+
| Wave Sequencer                               |
| - Selects configured wave                    |
| - Builds cohort manifest                     |
+----------------------------------------------+
                     |
                     v
+----------------------------------------------+
| Gate Checker                                 |
| - Validates readiness freshness              |
| - Evaluates approvals and thresholds         |
+----------------------------------------------+
                     |
                     v
+----------------------------------------------+
| Assignment Staging                           |
| - Generates license-assignment manifests     |
| - Leaves execution to customer-run tooling   |
+----------------------------------------------+
                     |
                     v
+----------------------------------------------+
| Power BI Health Dashboard                    |
| - Wave health score                          |
| - Approval state                             |
| - Pending and blocked users                  |
+----------------------------------------------+
```

> Note: The License Assigner component generates wave manifests and gate-criteria evaluations.
> It does not execute license assignments or modify tenant state. Manual approval and execution
> by the platform operator is required for each wave.

## Risk Tiers

| Risk Tier | Description | Required Controls Before Rollout |
|-----------|-------------|----------------------------------|
| Tier 1 - Standard Users | General knowledge workers with the lowest operational risk. Eligible for Wave 0 and Wave 1 after basic readiness checks. | Current readiness scan, seat availability, service-desk coverage |
| Tier 2 - Regulated Role Users | Compliance officers, legal, and HR users who require stronger data-handling and supervision safeguards. Eligible after Tier 1 waves show stability. | Tier 1 controls plus DLP validation, supervision evidence, approval workflow completion |
| Tier 3 - Privileged or Executive Users | C-suite leaders, IT administrators, and traders where privilege, market sensitivity, or concentration risk is highest. Enter only after earlier waves are stable. | Tier 2 controls plus CA policy validation, DLP enforcement, audit trail verification, CAB approval |

## Wave Definitions

The canonical design contains four waves. Lower governance tiers intentionally stop earlier:

- Baseline uses Wave 0 and Wave 1 only.
- Recommended uses Wave 0 through Wave 2.
- Regulated uses Wave 0 through Wave 3.

| Wave | Target Cohort | Rollout Intent |
|------|---------------|----------------|
| Wave 0 | Pilot 50 users, Tier 1 | Validate prerequisite checks, help-desk readiness, and initial assignment workflow on a low-risk pilot |
| Wave 1 | 500 users, Tier 1 and Tier 2 | Expand after Wave 0 success and introduce regulated-role users with added DLP and supervision checks |
| Wave 2 | Full Tier 1 and Tier 2 population | Move to scaled deployment after sustained operational stability and acceptable issue volume |
| Wave 3 | Tier 3 population | Release to privileged and executive users only after all prior waves pass and CAB approval is documented |

## Gate Criteria by Wave

| Wave | Gate Criteria |
|------|---------------|
| Wave 0 | Readiness scanner completed successfully, readiness data is current, minimum readiness threshold met, service desk and support roster confirmed, reserved Copilot seats available |
| Wave 1 | Wave 0 health score meets threshold, Tier 2 DLP rules verified, supervision coverage confirmed, approval flow completed, open incident count below configured limit |
| Wave 2 | Wave 1 stable for the configured observation period, training or communications completion recorded, backlog within threshold, rollout dashboard healthy, approval history complete |
| Wave 3 | Wave 2 stable, Tier 3 CA policy validated, DLP coverage confirmed, audit trail enabled, CAB approval captured, DORA resilience review completed |

## Power Automate Flow Design

The repository keeps Power Automate assets documentation-first. The following flow definitions describe the intended operating model:

| Flow | Trigger | Purpose | Output |
|------|---------|---------|--------|
| `Wave-Readiness-Check` | New readiness-scanner evidence package or scheduled review | Reads readiness outputs from solution 01, applies risk-tier rules, and writes per-user findings to Dataverse | Updated readiness status and blocked-user list |
| `Gate-Approval-Request` | Wave manifest created or gate review submitted | Routes expansion approvals to business owners, control owners, and CAB approvers based on the selected tier | Approval record and expansion decision |
| `License-Assignment-Trigger` | Gate approved | Generates a license-assignment manifest for the approved cohort and records the intended action set for evidence export | Assignment log and exception list |

## Dataverse Tables

The rollout solution uses the following Dataverse table names:

| Table | Purpose | Example Fields |
|-------|---------|----------------|
| `fsi_cg_rtr_baseline` | Stores per-user baseline rollout records and wave assignments | `userPrincipalName`, `riskTier`, `waveNumber`, `assignmentState`, `lastReadinessReview` |
| `fsi_cg_rtr_finding` | Stores blockers, gate failures, and manual-review requirements | `findingType`, `waveNumber`, `severity`, `owner`, `dueDate` |
| `fsi_cg_rtr_evidence` | Stores evidence-package metadata and artifact references | `artifactType`, `artifactPath`, `hash`, `exportedAt`, `controlId` |

## Integration with 01-copilot-readiness-scanner

`01-copilot-readiness-scanner` is a hard dependency because rollout automation should not expand users without current readiness data. The expected integration pattern is:

1. Solution 01 exports a recent evidence package and any supporting readiness artifacts.
2. `Wave-Readiness-Check` reads the exported readiness status and confirms the package age is within the configured freshness threshold.
3. The Risk Tier Classifier combines readiness evidence with role attributes to label each user as Tier 1, Tier 2, or Tier 3.
4. Any stale, incomplete, or failing readiness result is written to `fsi_cg_rtr_finding` and blocks wave expansion until remediated.

## Architecture Notes

- PowerShell produces auditable manifest and monitoring outputs even before tenant-specific APIs are connected, and the repository keeps cohort inputs at representative-sample depth until live feeds are added.
- Power Automate owns approval routing and operational notifications in the target environment.
- Power BI consumes the Dataverse evidence tables and manifest outputs to present rollout health to operations, risk, and compliance stakeholders.
