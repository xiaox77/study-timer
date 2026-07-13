$ErrorActionPreference = "Stop"

$script:SingleInstanceMutex = New-Object System.Threading.Mutex($false, "Global\CodexStudyTimer")
if (-not $script:SingleInstanceMutex.WaitOne(0, $false)) {
    return
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

Add-Type @"
using System;
using System.Runtime.InteropServices;

public static class StudyIdle
{
    [StructLayout(LayoutKind.Sequential)]
    private struct LASTINPUTINFO
    {
        public uint cbSize;
        public uint dwTime;
    }

    [DllImport("user32.dll")]
    private static extern bool GetLastInputInfo(ref LASTINPUTINFO plii);

    public static TimeSpan GetIdleTime()
    {
        LASTINPUTINFO info = new LASTINPUTINFO();
        info.cbSize = (uint)System.Runtime.InteropServices.Marshal.SizeOf(typeof(LASTINPUTINFO));
        if (!GetLastInputInfo(ref info))
        {
            return TimeSpan.Zero;
        }

        uint elapsed = ((uint)Environment.TickCount) - info.dwTime;
        return TimeSpan.FromMilliseconds(elapsed);
    }
}
"@

$script:IdleThreshold = [TimeSpan]::FromMinutes(5)
$script:MaxTickInterval = [TimeSpan]::FromSeconds(10)
$script:StudyTime = [TimeSpan]::Zero
$script:LastTick = Get-Date
$script:ManualPaused = $false
$script:AllowExit = $false
$script:TrayTipShown = $false
$script:SessionStart = Get-Date
$script:LogPath = Join-Path $PSScriptRoot "StudyTimer_log.csv"
$script:AssetsDir = Join-Path $PSScriptRoot "assets"
$script:BackgroundPath = Join-Path $script:AssetsDir "ui_frame.png"
$script:IconPath = Join-Path $script:AssetsDir "StudyTimer.ico"

function Format-Duration {
    param([TimeSpan]$Duration)

    if ($Duration.TotalHours -ge 1) {
        return "{0:00}:{1:00}:{2:00}" -f [math]::Floor($Duration.TotalHours), $Duration.Minutes, $Duration.Seconds
    }

    return "{0:00}:{1:00}" -f $Duration.Minutes, $Duration.Seconds
}

function Write-StudyLog {
    if ($script:StudyTime.TotalSeconds -lt 1) {
        return
    }

    $exists = Test-Path -LiteralPath $script:LogPath
    if (-not $exists) {
        "start_time,end_time,active_seconds,active_time" | Out-File -LiteralPath $script:LogPath -Encoding UTF8
    }

    $end = Get-Date
    $line = '"{0}","{1}",{2},"{3}"' -f `
        $script:SessionStart.ToString("yyyy-MM-dd HH:mm:ss"), `
        $end.ToString("yyyy-MM-dd HH:mm:ss"), `
        [int][math]::Round($script:StudyTime.TotalSeconds), `
        (Format-Duration $script:StudyTime)
    $line | Out-File -LiteralPath $script:LogPath -Append -Encoding UTF8
}

function Load-Bitmap {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return $null
    }

    $source = [System.Drawing.Image]::FromFile($Path)
    try {
        return New-Object System.Drawing.Bitmap($source)
    } finally {
        $source.Dispose()
    }
}

[System.Windows.Forms.Application]::EnableVisualStyles()
[System.Windows.Forms.Application]::SetCompatibleTextRenderingDefault($false)

$script:BackgroundImage = Load-Bitmap $script:BackgroundPath
if (Test-Path -LiteralPath $script:IconPath) {
    $script:AppIcon = New-Object System.Drawing.Icon($script:IconPath)
}

$form = New-Object System.Windows.Forms.Form
$form.Text = "Study Timer"
$form.ClientSize = New-Object -TypeName System.Drawing.Size -ArgumentList 440, 340
$form.StartPosition = "CenterScreen"
$form.TopMost = $true
$form.FormBorderStyle = "FixedSingle"
$form.MaximizeBox = $false
$form.BackColor = [System.Drawing.Color]::FromArgb(230, 238, 226)
$form.Font = New-Object -TypeName System.Drawing.Font -ArgumentList "Segoe UI", 10
if ($script:BackgroundImage) {
    $form.BackgroundImage = $script:BackgroundImage
    $form.BackgroundImageLayout = [System.Windows.Forms.ImageLayout]::None
}
if ($script:AppIcon) {
    $form.Icon = $script:AppIcon
}

$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = "Study Timer"
$titleLabel.AutoSize = $false
$titleLabel.Width = 208
$titleLabel.Height = 38
$titleLabel.Location = New-Object -TypeName System.Drawing.Point -ArgumentList 116, 30
$titleLabel.Font = New-Object -TypeName System.Drawing.Font -ArgumentList "Segoe UI", 12, ([System.Drawing.FontStyle]::Bold)
$titleLabel.ForeColor = [System.Drawing.Color]::FromArgb(47, 55, 38)
$titleLabel.BackColor = [System.Drawing.Color]::Transparent
$titleLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$form.Controls.Add($titleLabel)

$timeLabel = New-Object System.Windows.Forms.Label
$timeLabel.Text = "00:00"
$timeLabel.Width = 228
$timeLabel.Height = 78
$timeLabel.Location = New-Object -TypeName System.Drawing.Point -ArgumentList 58, 100
$timeLabel.Font = New-Object -TypeName System.Drawing.Font -ArgumentList "Consolas", 34, ([System.Drawing.FontStyle]::Bold)
$timeLabel.ForeColor = [System.Drawing.Color]::FromArgb(28, 90, 83)
$timeLabel.BackColor = [System.Drawing.Color]::Transparent
$timeLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$form.Controls.Add($timeLabel)

$idleLabel = New-Object System.Windows.Forms.Label
$idleLabel.Text = "Idle 00:00 / 05:00"
$idleLabel.Width = 228
$idleLabel.Height = 34
$idleLabel.Location = New-Object -TypeName System.Drawing.Point -ArgumentList 58, 196
$idleLabel.ForeColor = [System.Drawing.Color]::FromArgb(58, 66, 60)
$idleLabel.BackColor = [System.Drawing.Color]::Transparent
$idleLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$form.Controls.Add($idleLabel)

$pauseButton = New-Object System.Windows.Forms.Label
$pauseButton.Text = "Pause"
$pauseButton.Width = 92
$pauseButton.Height = 34
$pauseButton.Location = New-Object -TypeName System.Drawing.Point -ArgumentList 54, 262
$pauseButton.BackColor = [System.Drawing.Color]::Transparent
$pauseButton.ForeColor = [System.Drawing.Color]::FromArgb(45, 64, 58)
$pauseButton.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$pauseButton.Cursor = [System.Windows.Forms.Cursors]::Hand
$form.Controls.Add($pauseButton)

$resetButton = New-Object System.Windows.Forms.Label
$resetButton.Text = "Reset"
$resetButton.Width = 92
$resetButton.Height = 34
$resetButton.Location = New-Object -TypeName System.Drawing.Point -ArgumentList 174, 262
$resetButton.BackColor = [System.Drawing.Color]::Transparent
$resetButton.ForeColor = [System.Drawing.Color]::FromArgb(45, 64, 58)
$resetButton.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$resetButton.Cursor = [System.Windows.Forms.Cursors]::Hand
$form.Controls.Add($resetButton)

$closeButton = New-Object System.Windows.Forms.Label
$closeButton.Text = "Finish"
$closeButton.Width = 92
$closeButton.Height = 34
$closeButton.Location = New-Object -TypeName System.Drawing.Point -ArgumentList 294, 262
$closeButton.BackColor = [System.Drawing.Color]::Transparent
$closeButton.ForeColor = [System.Drawing.Color]::FromArgb(45, 64, 58)
$closeButton.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$closeButton.Cursor = [System.Windows.Forms.Cursors]::Hand
$form.Controls.Add($closeButton)

function Show-StudyTimer {
    if (-not $form.Visible) {
        $form.Show()
    }
    if ($form.WindowState -eq [System.Windows.Forms.FormWindowState]::Minimized) {
        $form.WindowState = [System.Windows.Forms.FormWindowState]::Normal
    }
    $form.Activate()
}

function Update-PauseUi {
    if ($script:ManualPaused) {
        $pauseButton.Text = "Resume"
        if ($pauseMenuItem) {
            $pauseMenuItem.Text = "Resume"
        }
    } else {
        $pauseButton.Text = "Pause"
        if ($pauseMenuItem) {
            $pauseMenuItem.Text = "Pause"
        }
    }
}

function Toggle-ManualPause {
    $script:ManualPaused = -not $script:ManualPaused
    $script:LastTick = Get-Date
    Update-PauseUi
}

function Hide-ToTray {
    $form.Hide()
    if ($script:NotifyIcon -and -not $script:TrayTipShown) {
        $script:NotifyIcon.BalloonTipTitle = "Study Timer is running"
        $script:NotifyIcon.BalloonTipText = "Closed window means hidden to tray. Timing continues in background."
        $script:NotifyIcon.ShowBalloonTip(2500)
        $script:TrayTipShown = $true
    }
}

function Finish-StudyTimer {
    $script:AllowExit = $true
    $form.Close()
}

$trayMenu = New-Object System.Windows.Forms.ContextMenuStrip
$showMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem -ArgumentList "Show Timer"
$pauseMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem -ArgumentList "Pause"
$finishMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem -ArgumentList "Finish and Exit"
[void]$trayMenu.Items.Add($showMenuItem)
[void]$trayMenu.Items.Add($pauseMenuItem)
[void]$trayMenu.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator))
[void]$trayMenu.Items.Add($finishMenuItem)

$script:NotifyIcon = New-Object System.Windows.Forms.NotifyIcon
if ($script:AppIcon) {
    $script:NotifyIcon.Icon = $script:AppIcon
} else {
    $script:NotifyIcon.Icon = [System.Drawing.SystemIcons]::Application
}
$script:NotifyIcon.Text = "Study Timer - timing in background"
$script:NotifyIcon.ContextMenuStrip = $trayMenu
$script:NotifyIcon.Visible = $true

$showMenuItem.Add_Click({ Show-StudyTimer })
$pauseMenuItem.Add_Click({ Toggle-ManualPause })
$finishMenuItem.Add_Click({ Finish-StudyTimer })
$script:NotifyIcon.Add_DoubleClick({ Show-StudyTimer })

$pauseButton.Add_Click({
    Toggle-ManualPause
})

$resetButton.Add_Click({
    $answer = [System.Windows.Forms.MessageBox]::Show(
        "Reset this study timer? The current session will be written to the log first.",
        "Reset Study Timer",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Question
    )

    if ($answer -eq [System.Windows.Forms.DialogResult]::Yes) {
        Write-StudyLog
        $script:StudyTime = [TimeSpan]::Zero
        $script:SessionStart = Get-Date
        $script:LastTick = Get-Date
    }
})

$closeButton.Add_Click({
    Finish-StudyTimer
})

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 1000
$timer.Add_Tick({
    $now = Get-Date
    $elapsed = $now - $script:LastTick
    $script:LastTick = $now

    $idle = [StudyIdle]::GetIdleTime()
    $isNormalTick = $elapsed -gt [TimeSpan]::Zero -and $elapsed -le $script:MaxTickInterval
    if ($isNormalTick -and -not $script:ManualPaused -and $idle -lt $script:IdleThreshold) {
        $script:StudyTime = $script:StudyTime.Add($elapsed)
    }

    $timeLabel.Text = Format-Duration $script:StudyTime
    $idleLabel.Text = "Idle {0} / 05:00" -f (Format-Duration $idle)
})

$form.Add_Shown({
    $script:LastTick = Get-Date
    $timer.Start()
})

$form.Add_FormClosing({
    param($sender, $eventArgs)

    if ($null -eq $eventArgs -and $null -ne $_) {
        $eventArgs = $_
    }

    if ($null -ne $eventArgs -and -not $script:AllowExit -and $eventArgs.CloseReason -ne [System.Windows.Forms.CloseReason]::WindowsShutDown) {
        $eventArgs.Cancel = $true
        Hide-ToTray
        return
    }

    $timer.Stop()
    Write-StudyLog
    if ($script:NotifyIcon) {
        $script:NotifyIcon.Visible = $false
        $script:NotifyIcon.Dispose()
    }
    if ($trayMenu) {
        $trayMenu.Dispose()
    }
    if ($script:SingleInstanceMutex) {
        $script:SingleInstanceMutex.ReleaseMutex()
        $script:SingleInstanceMutex.Dispose()
    }
    if ($script:BackgroundImage) {
        $script:BackgroundImage.Dispose()
    }
    if ($script:AppIcon) {
        $script:AppIcon.Dispose()
    }
})

[void][System.Windows.Forms.Application]::Run($form)
