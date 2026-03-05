param(
  # Root van je Mendix project (default: huidige folder)
  [string]$ProjectRoot = (Get-Location).Path,

  # Bronmap in je repo (de regels die je wél commit)
  [string]$SourceDir = "mxlint-rules\",

  # Doelmap waar de extension/CLI de regels oppikt
  # (jouw setup gebruikt .mendix-cache\rules\..., dus we syncen daar naartoe)
  [string]$TargetDir = ".mendix-cache\rules",

  # Optioneel: target leegmaken voordat je kopieert
  [switch]$CleanTarget
)

$src = Join-Path $ProjectRoot $SourceDir
$dst = Join-Path $ProjectRoot $TargetDir

if (!(Test-Path $src)) {
  throw "SourceDir not found: $src`nExpected: $ProjectRoot\$SourceDir"
}

if (!(Test-Path $dst)) {
  New-Item -ItemType Directory -Force -Path $dst | Out-Null
}

if ($CleanTarget) {
  Write-Host "Cleaning target folder: $dst"
  Get-ChildItem -Path $dst -Force | Remove-Item -Recurse -Force
}

Write-Host "Syncing MxLint rules..."
Write-Host "  From: $src"
Write-Host "  To:   $dst"

Copy-Item -Path (Join-Path $src "*") -Destination $dst -Recurse -Force

Write-Host "Done. If Studio Pro is open: restart Studio Pro to ensure rules are reloaded."