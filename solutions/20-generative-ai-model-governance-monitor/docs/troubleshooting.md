# Troubleshooting

## Configuration Issues

### Configuration file not found

If the script reports `Configuration file not found`, confirm that the selected tier file exists under `config/` and that the working directory is the solution root.

### Missing required fields

If `Test-GmgConfiguration` reports missing fields, compare the tier JSON file with the repository baseline and restore the missing keys. The required fields are listed in `scripts/GmgConfig.psm1`.

## Script Issues

### PowerShell parse error

Run the parse check command from the README to confirm script integrity:

```powershell
Get-ChildItem scripts\*.ps1 | ForEach-Object {
    $tokens = $null; $errors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$tokens, [ref]$errors)
    if ($errors) { "FAIL: $($_.Name): $errors" } else { "OK: $($_.Name)" }
}
```

### Script reports representative sample data

This is expected. v0.1.0 is documentation-first. Live integration with Microsoft Graph, Purview, or Sentinel is deferred.

## Evidence Issues

### SHA-256 mismatch

A SHA-256 mismatch indicates the JSON file changed after the companion sidecar was written.

- Re-run `scripts\Export-Evidence.ps1` to regenerate the artifact and its sidecar.
- Do not edit exported JSON files by hand after the sidecar is written.

### Output path errors

If export fails because the output path is invalid:

- Confirm the deployment account can create directories in the target path.
- Use a local or approved network path with stable write access.

## Regulatory Mapping Questions

### Why does GMG cite SR 11-7 / OCC Bulletin 2011-12 if it has been superseded?

SR 26-2 / OCC Bulletin 2026-13 supersede SR 11-7 and OCC Bulletin 2011-12 for traditional models, but explicitly exclude generative AI from their scope. Per supervisory guidance, the SR 11-7 / OCC Bulletin 2011-12 model risk principles continue to be applied to generative AI as an interim approach. GMG documents this interim applicability so the firm can show how it maintains model-risk discipline for Copilot during the exclusion period.

### Does running GMG satisfy SR 11-7?

No. GMG aids in meeting model inventory, validation, and ongoing monitoring elements of SR 11-7 / OCC Bulletin 2011-12 for Copilot, but it does not on its own satisfy any regulatory obligation. The firm's model risk officer and validation team must perform their own validation work and review.

## Common Error Messages

| Error Message | Likely Cause | Resolution |
|---------------|--------------|------------|
| `Configuration file not found` | Tier JSON file path is wrong or missing | Confirm the selected tier file exists under `config/` |
| `GMG configuration is missing required fields` | JSON edited without preserving mandatory keys | Compare with repository baseline and restore missing properties |
| `Hash file not found` | Evidence package was moved or edited after export | Re-export the evidence package |
