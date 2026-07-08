# Study Timer

一个 Windows 桌面学习计时器。

## 功能

- 开机登录后自动启动。
- 键盘或鼠标有活动时自动计入学习时间。
- 电脑空闲超过 5 分钟后自动暂停。
- 点右上角关闭按钮时隐藏到系统托盘，后台继续计时。
- 双击托盘图标可重新显示窗口。
- 点击 `Finish` 才会真正结束本次计时并写入日志。

## 安装

1. 解压 `StudyTimer-portable.zip`。
2. 双击 `Install-StudyTimer.cmd`。
3. 安装后会创建桌面快捷方式和开机启动项。

默认安装位置：

```text
%LOCALAPPDATA%\StudyTimer
```

## 卸载

双击 `Uninstall-StudyTimer.cmd`。

## 日志

学习记录会保存到安装目录里的：

```text
StudyTimer_log.csv
```

## 文件说明

- `StudyTimer.ps1`：主程序。
- `StartStudyTimerHidden.vbs`：隐藏 PowerShell 黑窗口的启动器。
- `assets/`：界面图片和图标资源。
- `Install-StudyTimer.ps1` / `.cmd`：安装脚本。
- `Uninstall-StudyTimer.ps1` / `.cmd`：卸载脚本。

## 注意

图片资源来自用户提供的素材。公开发布或商业传播前，请先确认图片版权和授权。
