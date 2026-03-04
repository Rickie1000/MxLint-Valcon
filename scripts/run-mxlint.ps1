param(
  [string]$ProjectDir = ".",
  [string]$OutputDir = ".MxLintOutput"
)

$ProjectDir = (Resolve-Path $ProjectDir).Path
$MxlintExe  = Join-Path $ProjectDir "mxlint-cli.exe"
$RulesDir   = Join-Path $ProjectDir ".mendix-cache\rules"
$OutputDir  = Join-Path $ProjectDir $OutputDir

if (!(Test-Path $MxlintExe)) {
  throw "mxlint-cli.exe not found at: $MxlintExe"
}
if (!(Test-Path $RulesDir)) {
  throw "Rules directory not found at: $RulesDir"
}

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

# 1) export model
& $MxlintExe export-model -i $ProjectDir -o $OutputDir
if ($LASTEXITCODE -ne 0) { throw "export-model failed with exit code $LASTEXITCODE" }

# 2) lint and write JSON report
& $MxlintExe lint --modelsource $OutputDir -r $RulesDir

# Exit code convention:
# 0 = no findings
# 1 = findings (lint failures) -> still success for running the tool
# >1 = execution error
if ($LASTEXITCODE -gt 1) {
  throw "mxlint execution failed with exit code $LASTEXITCODE"
}
