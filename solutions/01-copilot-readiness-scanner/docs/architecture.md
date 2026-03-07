# Architecture

Copilot Readiness Assessment Scanner uses a documentation-first architecture with three layers:

- Shared modules from `scripts/common/`
- Solution-specific PowerShell scripts under `scripts/`
- Tiered configuration files under `config/`

The implementation track will add workload-specific automation, monitoring, and evidence collection logic on top of this scaffold.
