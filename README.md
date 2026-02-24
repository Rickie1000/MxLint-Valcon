# MxLint-Valcon
This repository contains the MxLint Studio Pro extension and our shared custom ruleset.  
The custom rules are version-controlled and synced into the Mendix cache so the extension can load them.

---

## Repository Structure

- `extensions/MxLintExtension/`  
  The MxLint Studio Pro extension (committed so everyone uses the same version)

- `mxlint-rules/`  
  **Source of truth** for custom rules (committed)

- `scripts/Sync-MxLintRules.ps1`  
  Sync script that copies custom rules into the Mendix cache

> `.mendix-cache/` is **not** committed (generated/cache folder)

---

## One-Time Setup (Windows)

### 1) Allow PowerShell script execution
Open **PowerShell as Administrator** and run:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned
