# MxLint-Valcon
## Shared custom rules (team workflow)

This project uses **MxLint** inside **Mendix Studio Pro** with a shared, version-controlled ruleset.  
The **custom rules are stored in Git** and automatically **synced into the Mendix cache**, because `.mendix-cache/` is a generated folder and should not be the source of truth.

---

## ✅ Repository structure

| Path | Purpose | Committed |
|------|---------|-----------|
| `extensions/MxLintExtension/` | MxLint Studio Pro extension files | ✅ Yes |
| `mxlint-rules/` | **Source of truth** for custom rules | ✅ Yes |
| `scripts/Sync-MxLintRules.ps1` | Copies rules into `.mendix-cache` | ✅ Yes |
| `.mendix-cache/` | Generated cache folder used by Mendix/MxLint | ❌ No |

> **Important:** Do **not** edit rules inside `.mendix-cache/`. Always edit rules in `mxlint-rules/` and then run the sync script.

---

## 🧩 One-time setup (Windows)

### 1) Allow PowerShell scripts
Open **PowerShell as Administrator** and run:


```powershell Set-ExecutionPolicy -ExecutionPolicy RemoteSigned```


### 2) Enable Studio Pro extension development mode

1. Locate your Mendix Studio Pro 10.24.8 shortcut (Start Menu or Desktop)
2. Right-click → Properties
3. In the Target field, append (after the closing quote):


