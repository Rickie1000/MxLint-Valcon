# Example: Run-MxLint.ps1
param(
  [string]$ProjectDir = "C:\Users\RickSchreuder\MxLintOutput"
)

$ErrorActionPreference = "Stop"

# 1) export model
& "$ProjectDir\mxlint-cli.exe" export-model --input "$ProjectDir" --output "$ProjectDir\modelsource"

# 2) lint and write JSON report (the UI will later fetch this)
& "$ProjectDir\mxlint-cli.exe" lint --modelsource "$ProjectDir\modelsource" --rules "$ProjectDir\.mendix-cache\rules" --json-file "$ProjectDir\.mendix-cache\lint-results.json"