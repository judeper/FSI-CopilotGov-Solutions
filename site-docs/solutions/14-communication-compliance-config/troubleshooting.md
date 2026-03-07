# Troubleshooting

## Policy Not Capturing Copilot Content

Possible causes and checks:

- Confirm the policy scope includes the Copilot-assisted communication channels in use.
- Confirm the customer documented how Copilot interactions are labeled or identified in content.
- Confirm any retention label or retention policy dependency does not remove the message before review.
- Confirm policy publication was completed in the Microsoft Purview portal after templates were generated.

## Reviewer Queue Empty Despite Known Policy Matches

Possible causes and checks:

- Wait for policy propagation. New Communication Compliance policies can take time to begin matching.
- Confirm reviewers were assigned to the correct policy.
- Confirm the users or locations under supervision are in scope.
- Confirm the content source and channel are supported by the deployed policy.

## Lexicon Keywords Not Triggering

Possible causes and checks:

- Confirm the updated lexicon was published after editing.
- Confirm exact-match versus near-match settings align to the keyword design.
- Confirm phrase casing, punctuation, and tokenization do not prevent a match.
- Confirm the selected policy references the intended lexicon list.

## Evidence Export Failures

Possible causes and checks:

- Confirm the output path exists or can be created.
- Confirm the shared module `scripts\common\EvidenceExport.psm1` is present.
- Confirm the selected tier configuration file contains valid JSON.
- Re-run the script with `-PassThru` to review the artifact summary and generated paths.

## FINRA and SEC Examination Readiness Gaps

Common readiness gaps:

- Missing documentation of reviewer assignments or escalation timers.
- No retained approval history for lexicon updates.
- Policy templates generated but not published in the Purview portal.
- No evidence package showing queue metrics or supervisory follow-up.

## FCA SYSC 10 Conflict of Interest Monitoring Gaps

Common readiness gaps:

- Conflict-of-interest indicators are not included in the supervised lexicon.
- Proprietary product references are not routed for legal or supervisory review.
- Escalation rules do not identify conflicts or compensation-related language.

## Common Error Messages

| Error | Likely Cause | Recommended Action |
|-------|--------------|--------------------|
| `Configuration tier file not found.` | Missing or renamed JSON tier file | Restore the expected file name in `config\` |
| `Unknown policy template ID` | Tier config references a template not defined in the script catalog | Update the tier config or add the template definition |
| `Evidence file not found` | Evidence package path is incorrect or export failed | Re-run `Export-Evidence.ps1` and inspect the output directory |
| `Hash file not found` | Evidence package was not fully written | Confirm the export completed and the output path is writable |
| `Manual activation status file not present.` | Purview activation verification was not recorded | Add the manual activation status record after portal publication |
