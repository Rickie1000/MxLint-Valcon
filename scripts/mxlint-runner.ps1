param(
  [string]$ProjectDir = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
  [int[]]$Ports = @(3210,3211,3212,3213)
)

$RunScript = Join-Path $ProjectDir "scripts\run-mxlint.ps1"

if (!(Test-Path $RunScript)) {
  throw "run-mxlint.ps1 not found at: $RunScript"
}

function Get-FreePort {
  param([int[]]$Ports)
  foreach ($p in $Ports) {
    try {
      $listener = New-Object System.Net.HttpListener
      $listener.Prefixes.Add("http://127.0.0.1:$p/")
      $listener.Start()
      return @{ Port = $p; Listener = $listener }
    } catch {
      # port in use -> try next
    }
  }
  throw "No free port found in: $($Ports -join ', ')"
}

$bind = Get-FreePort -Ports $Ports
$port = $bind.Port
$http = $bind.Listener

Write-Host "MxLint runner listening on http://127.0.0.1:$port/run"
Write-Host "ProjectDir: $ProjectDir"

while ($http.IsListening) {
  $ctx = $http.GetContext()
  Write-Host ("[{0}] {1} {2}" -f (Get-Date), $ctx.Request.HttpMethod, $ctx.Request.Url.AbsolutePath)
  $req = $ctx.Request
  $res = $ctx.Response

  try {
    if ($req.Url.AbsolutePath -ne "/run") {
      $res.StatusCode = 404
      $bytes = [Text.Encoding]::UTF8.GetBytes("Not found")
      $res.OutputStream.Write($bytes, 0, $bytes.Length)
      $res.Close()
      continue
    }

    if ($req.HttpMethod -ne "POST") {
      $res.StatusCode = 405
      $bytes = [Text.Encoding]::UTF8.GetBytes("Use POST")
      $res.OutputStream.Write($bytes, 0, $bytes.Length)
      $res.Close()
      continue
    }

    # Run lint
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "powershell.exe"
    $psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$RunScript`" -ProjectDir `"$ProjectDir`""
    $psi.WorkingDirectory = $ProjectDir
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError  = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true

    $p = New-Object System.Diagnostics.Process
    $p.StartInfo = $psi
    [void]$p.Start()
    $stdout = $p.StandardOutput.ReadToEnd()
    $stderr = $p.StandardError.ReadToEnd()
    $p.WaitForExit()
    Write-Host "ExitCode: $($p.ExitCode)"
    if ($stdout) { Write-Host $stdout }
    if ($stderr) { Write-Host $stderr }

    if ($p.ExitCode -eq 0) {
      $res.StatusCode = 200
      $body = "OK`n$stdout"
    } else {
      $res.StatusCode = 500
      $body = "FAILED (exit $($p.ExitCode))`n$stdout`n$stderr"
    }

    $bytes = [Text.Encoding]::UTF8.GetBytes($body)
    $res.ContentType = "text/plain"
    $res.OutputStream.Write($bytes, 0, $bytes.Length)
    $res.Close()
  } catch {
    $res.StatusCode = 500
    $bytes = [Text.Encoding]::UTF8.GetBytes("Runner error: $($_.Exception.Message)")
    $res.OutputStream.Write($bytes, 0, $bytes.Length)
    $res.Close()
  }
}