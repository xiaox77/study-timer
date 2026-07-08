$ErrorActionPreference = "Stop"

$sourceDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$installDir = Join-Path $env:LOCALAPPDATA "StudyTimer"
$desktop = [Environment]::GetFolderPath("Desktop")
$startup = [Environment]::GetFolderPath([Environment+SpecialFolder]::Startup)
$shortcutName = "Study Timer.lnk"
$wscriptPath = Join-Path $env:SystemRoot "System32\wscript.exe"

function Copy-RequiredItem {
    param(
        [string]$Name
    )

    $source = Join-Path $sourceDir $Name
    $target = Join-Path $installDir $Name
    if (-not (Test-Path -LiteralPath $source)) {
        throw "Missing required item: $source"
    }

    if ([System.IO.Path]::GetFullPath($source) -eq [System.IO.Path]::GetFullPath($target)) {
        return
    }

    if (Test-Path -LiteralPath $target) {
        Remove-Item -LiteralPath $target -Recurse -Force
    }

    Copy-Item -LiteralPath $source -Destination $target -Recurse -Force
}

function New-StudyTimerShortcut {
    param(
        [string]$ShortcutPath
    )

    $launcher = Join-Path $installDir "StartStudyTimerHidden.vbs"
    $icon = Join-Path $installDir "assets\StudyTimer.ico"
    $wsh = New-Object -ComObject WScript.Shell
    $shortcut = $wsh.CreateShortcut($ShortcutPath)
    $shortcut.TargetPath = $wscriptPath
    $shortcut.Arguments = '"' + $launcher + '"'
    $shortcut.WorkingDirectory = $installDir
    if (Test-Path -LiteralPath $icon) {
        $shortcut.IconLocation = $icon
    }
    $shortcut.Description = "Study Timer with idle auto-pause"
    $shortcut.Save()
}

New-Item -ItemType Directory -Path $installDir -Force | Out-Null

Copy-RequiredItem "StudyTimer.ps1"
Copy-RequiredItem "StartStudyTimerHidden.vbs"
Copy-RequiredItem "StartStudyTimer.cmd"
Copy-RequiredItem "assets"

New-StudyTimerShortcut (Join-Path $desktop $shortcutName)
New-StudyTimerShortcut (Join-Path $startup $shortcutName)

$launcherPath = Join-Path $installDir "StartStudyTimerHidden.vbs"
Start-Process -FilePath $wscriptPath -ArgumentList ('"' + $launcherPath + '"') -WindowStyle Hidden

Write-Host "Study Timer installed."
Write-Host "Install directory: $installDir"
Write-Host "Desktop shortcut: $(Join-Path $desktop $shortcutName)"
Write-Host "Startup shortcut: $(Join-Path $startup $shortcutName)"
