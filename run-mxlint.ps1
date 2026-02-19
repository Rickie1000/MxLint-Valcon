param(
  [string]$ProjectDir = ".",
  [string]$MxlintExe = ".\mxlint-v3.11.0-windows-amd64.exe",
  [string]$RulesDir  = ".mendix-cache\rules",
  [string]$OutputDir = "C:\Users\RickSchreuder\MxLintOutput"
)

& $MxlintExe export-model -i $ProjectDir -o $OutputDir

& $MxlintExe lint --modelsource $OutputDir -r $RulesDir
