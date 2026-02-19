$EXE = ".\mxlint-v3.11.0-windows-amd64.exe"

Write-Host "Bezig met starten van MxLint voor Microflow Steps..." -ForegroundColor Cyan

if (Test-Path $EXE) {
    # Jouw specifieke commando met afwijkende output folder en poort
    & $EXE serve -i . -o "C:\Users\RickSchreuder\MxLintOutput" -r ".mendix-cache\rules" -p 8082 -d 1000
} else {
    Write-Host "FOUT: Kan de executable niet vinden in deze map!" -ForegroundColor Red
    pause
}