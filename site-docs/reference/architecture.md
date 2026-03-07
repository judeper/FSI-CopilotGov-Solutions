# Repository Architecture

The repository is organized around four layers:

1. `data/` stores machine-readable control, framework, and solution metadata.
2. `scripts/common/` stores reusable PowerShell modules for authentication, evidence export, Dataverse naming, and notifications.
3. `solutions/` stores the solution-specific docs, scripts, configs, and tests.
4. `templates/` stores starter policy, dashboard, and regulatory mapping artifacts.

A documentation build step assembles `site-docs/` from root docs and solution READMEs before MkDocs publication.
