# Troubleshooting

## Configuration Issues

### `Configuration file not found`

- Confirm the selected tier file exists under `config/`.
- Confirm `config/default-config.json` is present.

### `PNRT configuration is missing required fields`

- Compare the JSON file with the repository baseline and restore missing properties such as `pagesRetentionDays`, `notebookRetentionDays`, `branchingAuditMode`, or `loopProvenanceRequired`.

## Pages Inventory Issues

### Missing Pages

If expected Copilot Pages are not in the inventory:

- Confirm the executing identity has read access to the SharePoint Embedded container or documented file/export surface that holds the Page.
- Confirm the SharePoint Embedded container URL, Purview audit/export visibility, or documented Microsoft Graph DriveItem/export access is available for the Page.
- Record the gap as a manual inventory addition until a documented live integration is wired.

### Internal sample lineage or version-history context looks wrong

- Verify the row is marked as PNRT internal sample taxonomy and is not treated as a Microsoft 365 product event.
- Compare production evidence against Purview audit logs and version-history exports rather than branch, fork, or mutability state names.

## Notebook Retention Issues

### OneNote section or folder shows `none` for retention-policy source

- Check the OneNote section file, parent folder, SharePoint site, or OneDrive library for an applied retention label or policy.
- Confirm Microsoft Purview policies have been published for the location that stores the section file.
- Add manual annotation if a record-level label is intentionally not assigned or if only policy coverage applies.

### Inheritance lookup is incomplete

- Confirm Purview read access for the executing identity.
- Re-run inventory after policy changes are published.

## Loop Component Issues

### Component lineage is empty

- Verify SharePoint Embedded container discovery, Loop workspace context, or documented Graph file/export access is available from the deployment host.
- Confirm the Loop workspace is included in the seed list under `config/default-config.json`.

### Signed lineage hash missing in regulated tier

- Confirm `signedLineageRequired` is set to true and the supplemental signing process is configured.
- Re-run the export after the signing step completes.

## Evidence Export Failures

### SHA-256 mismatch

- Re-run `scripts\Export-Evidence.ps1` to regenerate the artifact and its hash.
- Do not edit exported JSON files by hand after the hash is created.

### Output path issues

- Confirm the deployment account can create directories and files in the target path.
- Avoid output paths that are redirected or automatically synchronized during active export.

## Common Error Messages

| Error Message | Likely Cause | Resolution |
|---------------|--------------|------------|
| `Configuration file not found` | Tier JSON path is wrong or missing | Confirm the selected tier file exists under `config/` |
| `PNRT configuration is missing required fields` | JSON edited without preserving mandatory keys | Restore missing properties from the repository baseline |
| `No Pages were returned` | Live integration not wired or insufficient SharePoint Embedded, Purview, or documented Graph file/export access | Use sample data path for now and revisit when documented integration is implemented |
| `Hash file not found` | Evidence package was moved or edited after export | Re-export the evidence package and keep JSON and `.sha256` files together |

## Escalation

Escalate to Microsoft Support when SharePoint Embedded, documented Microsoft Graph DriveItem/export, or Purview endpoints return persistent errors during inventory runs. Collect the tenant ID, executing identity, UTC timestamps, and any correlation IDs returned by the failing endpoint.
