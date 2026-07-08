$ErrorActionPreference = "Stop"

$installDir = Join-Path $env:LOCALAPPDATA "StudyTimer"
$targetScript = Join-Path $installDir "StudyTimer.ps1"
$desktopShortcut = Join-Path ([Environment]::GetFolderPath("Desktop")) "Study Timer.lnk"
$startupShortcut = Join-Path ([Environment]::GetFolderPath([Environment+SpecialFolder]::Startup)) "Study Timer.lnk"

if (Test-Path -LiteralPath $targetScript) {
    $escapedScript = [regex]::Escape($targetScript)
    Get-CimInstance Win32_Process -Filter "name = 'powershell.exe'" |
        Where-Object { $_.CommandLine -match $escapedScript } |
        ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
}

Remove-Item -LiteralPath $desktopShortcut -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $startupShortcut -Force -ErrorAction SilentlyContinue

if (Test-Path -LiteralPath $installDir) {
    Remove-Item -LiteralPath $installDir -Recurse -Force
}

Write-Host "Study Timer uninstalled."
