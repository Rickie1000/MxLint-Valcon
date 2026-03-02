param(
  [string]$ProjectDir = ".",
  [string]$MxlintExe = ".\mxlint-cli.exe",
  [string]$RulesDir  = ".mendix-cache\rules",
  [string]$OutputDir = "C:\Users\RickSchreuder\MxLintOutput"
)

& $MxlintExe export-model -i $ProjectDir -o $OutputDir

& $MxlintExe lint --modelsource $OutputDir -r $RulesDir
