$port = 8099
$listener = [System.Net.HttpListener]::new()
$listener.Prefixes.Add("http://localhost:$port/")
$listener.Start()

Write-Host "MxLint Runner UI: http://localhost:$port/"

function Write-Response([System.Net.HttpListenerResponse]$res, [string]$text, [string]$contentType="text/html; charset=utf-8") {
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($text)
  $res.ContentType = $contentType
  $res.ContentLength64 = $bytes.Length
  $res.OutputStream.Write($bytes, 0, $bytes.Length)
  $res.OutputStream.Close()
}

$page = @"
<!doctype html>
<html>
<head>
  <meta charset="utf-8" />
  <title>MxLint Runner</title>
  <style>
    body { font-family: system-ui, Arial; padding: 24px; }
    button { padding: 10px 14px; border: 0; border-radius: 10px; cursor: pointer; }
    pre { margin-top: 12px; padding: 12px; border-radius: 10px; background: #f5f5f5; height: 360px; overflow:auto; }
  </style>
</head>
<body>
  <h2>MxLint Manual Run</h2>
  <button onclick="run()">Run lint now</button>
  <pre id="out">Ready.</pre>
  <script>
    async function run(){
      const out = document.getElementById("out");
      out.textContent = "Running…";
      const r = await fetch("/run", { method: "POST" });
      out.textContent = await r.text();
    }
  </script>
</body>
</html>
"@

while ($listener.IsListening) {
  $ctx = $listener.GetContext()
  $req = $ctx.Request
  $res = $ctx.Response

  if ($req.HttpMethod -eq "GET" -and $req.RawUrl -eq "/") {
    Write-Response $res $page
    continue
  }

  if ($req.HttpMethod -eq "POST" -and $req.RawUrl -eq "/run") {
    try {
      $output = & powershell -NoProfile -ExecutionPolicy Bypass -File ".\run-mxlint.ps1" 2>&1 | Out-String
      Write-Response $res $output "text/plain; charset=utf-8"
    } catch {
      Write-Response $res ("ERROR`n" + $_.Exception.Message) "text/plain; charset=utf-8"
    }
    continue
  }

  $res.StatusCode = 404
  Write-Response $res "Not found" "text/plain; charset=utf-8"
}
