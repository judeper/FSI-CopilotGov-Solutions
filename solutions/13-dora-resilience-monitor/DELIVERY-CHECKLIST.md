# DORA Operational Resilience Monitor Delivery Checklist

## Delivery Summary

- Solution: DORA Operational Resilience Monitor
- Version: v0.1.0
- Track: D
- Priority: P1

## Files to Include

- README.md
- CHANGELOG.md
- DELIVERY-CHECKLIST.md
- docs/*.md
- scripts/*.ps1
- config/*.json
- tests/13-dora-resilience-monitor.Tests.ps1

## Pre-Delivery Validation

- [ ] `python scripts/validate-contracts.py`
- [ ] `python scripts/validate-solutions.py`
- [ ] PowerShell syntax validation completed
- [ ] Evidence export verified with a companion hash file

## Customer Validation

- [ ] Review prerequisites and mapped controls
- [ ] Confirm chosen governance tier
- [ ] Run the scaffold deployment script in a non-production tenant first
- [ ] Review evidence export output and dashboard feed requirements

## Communication Template

Share the README, delivery checklist, mapped controls, prerequisites, and evidence expectations with the implementation team before customization begins.
