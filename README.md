# Study Timer

A Windows desktop study timer with idle auto-pause.

## Download

Download the portable package here:

[StudyTimer-portable.zip](dist/StudyTimer-portable.zip)

## Features

- Starts automatically after Windows login.
- Counts study time when keyboard or mouse activity is detected.
- Auto-pauses after 5 minutes of computer idle time.
- Clicking the window close button hides the app to the system tray; timing continues in the background.
- Double-click the tray icon to show the timer again.
- Click `Finish` to end the current timing session and write a log entry.

## Install

1. Download and unzip `StudyTimer-portable.zip`.
2. Double-click `Install-StudyTimer.cmd`.
3. The installer creates a desktop shortcut and a Windows startup shortcut.

Default install location:

```text
%LOCALAPPDATA%\StudyTimer
```

## Uninstall

Double-click `Uninstall-StudyTimer.cmd`.

## Logs

Study records are saved in the install directory:

```text
StudyTimer_log.csv
```

## Files

- `StudyTimer.ps1`: main app.
- `StartStudyTimerHidden.vbs`: hidden launcher that avoids a PowerShell console window.
- `assets/`: UI images and icon resources.
- `Install-StudyTimer.ps1` / `.cmd`: installer.
- `Uninstall-StudyTimer.ps1` / `.cmd`: uninstaller.

## Notice

Image assets were supplied by the user. Before public or commercial redistribution, confirm that the images are licensed for that use.
