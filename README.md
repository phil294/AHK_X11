# AHK_X11

AutoHotkey for Linux. (WORK IN PROGRESS)

More specifically: A very basic but functional reimplementation AutoHotkey v1.0.24 (2004) for Unix-like systems with an X window system (X11), written from ground up in Crystal with the help of [x11-cr](https://github.com/TamasSzekeres/x11-cr/), [libxdo](https://github.com/jordansissel/xdotool)([bindings](https://github.com/woodruffw/x_do.cr)) and [crystal-gobject](https://github.com/jhass/crystal-gobject)(GTK), with the eventual goal of 80% feature parity, but most likely never full compatibility. More importantly, because of the old version of the spec (you can check the old manual by installing or extracting the old `.chm` manual from [here](https://www.autohotkey.com/download/1.0/AutoHotkey1024.exe)), many modern AHK features will be missing, especially expressions (`:=`, `% v`) and functions, so you probably can't just port your scripts from Windows. Maybe this will also be added some day, but it does not have high priority for me personally. This AHK will be shipped as a single executable native binary with very low resource overhead and fast execution time.

> Please also check out [Keysharp](https://bitbucket.org/mfeemster/keysharp/), a fork of [IronAHK](https://github.com/Paris/IronAHK/tree/master/IronAHK), another complete rewrite in C# with a similar goal.

Features:
- [ ] Hotkeys
- [ ] Hotstrings
- [ ] Window management
- [ ] Keyboard and mouse control
- [ ] File management
- [ ] GUIs
- [ ] Compile script to executable

Status: None of the above yet, planned is all of it. Basic implementation details follow below; note however that this is not very representative. `Gui`, for example, is many times more massive and work requiring than any other command but still only listed as one.

- *Done* **3%** (14/213): Else, { ... }, Break, Continue, Return, Exit, GoSub, GoTo, IfEqual, Loop, SetEnv, Sleep, FileCopy, [Echo], [ahk_x11_print_vars]
- *Missing* **97%** (199/213): AutoTrim, BlockInput, ClipWait, Control, ControlClick, ControlFocus, ControlGet, ControlGetFocus, ControlGetPos, ControlGetText, ControlMove, ControlSend / ControlSendRaw , ControlSetText, CoordMode, DetectHiddenText, DetectHiddenWindows, Drive, DriveGet, DriveSpaceFree, Edit, EnvAdd, EnvDiv, EnvMult, EnvSet, EnvSub, EnvUpdate, ExitApp, FileAppend, FileCopyDir, FileCreateDir, FileCreateShortcut, FileDelete, FileInstall, FileReadLine, FileGetAttrib, FileGetShortcut, FileGetSize, FileGetTime, FileGetVersion, FileMove, FileMoveDir, FileRecycle, FileRecycleEmpty, FileRemoveDir, FileSelectFile, FileSelectFolder, FileSetAttrib, FileSetTime, FormatTime, GetKeyState, GroupActivate, GroupAdd, GroupClose, GroupDeactivate, Gui, GuiControl, GuiControlGet, Hotkey, If var [not] between, If var [not] in/contains MatchList , If var is [not] type, IfNotEqual, IfExist/IfNotExist, IfGreater/IfGreaterOrEqual, IfInString/IfNotInString, IfLess/IfLessOrEqual, IfMsgBox, IfWinActive/IfWinNotActive, IfWinExist/IfWinNotExist, IniDelete, IniRead, IniWrite, Input, InputBox, KeyHistory, KeyWait, ListHotkeys, ListLines, ListVars, Loop (files & folders) , Loop (parse a string) , Loop (read file contents) , Loop (registry), Menu, MouseClick, MouseClickDrag, MouseGetPos, MouseMove, MsgBox, OnExit, Pause, PixelGetColor, PixelSearch, PostMessage, Process, Progress, Random, RegDelete, RegRead, RegWrite, Reload, Run, RunAs, RunWait, Send / SendRaw , SendMessage, SetBatchLines, SetCapslockState, SetControlDelay, SetDefaultMouseSpeed, SetEnv, SetFormat, SetKeyDelay, SetMouseDelay, SetNumlockState, SetScrollLockState, SetStoreCapslockMode, SetTimer, SetTitleMatchMode, SetWinDelay, SetWorkingDir, Shutdown, Sort, SoundGet, SoundGetWaveVolume, SoundPlay, SoundSet, SoundSetWaveVolume, SplashImage, SplashTextOn, SplashTextOff, SplitPath, StatusBarGetText, StatusBarWait, StringCaseSense, StringGetPos, StringLeft, StringLen, StringLower, StringMid, StringReplace, StringRight, StringSplit, StringTrimLeft, StringTrimRight, StringUpper, Suspend, SysGet, Thread, ToolTip, Transform, TrayTip, URLDownloadToFile, WinActivate, WinActivateBottom, WinClose, WinGetActiveStats, WinGetActiveTitle, WinGetClass, WinGet, WinGetPos, WinGetText, WinGetTitle, WinHide, WinKill, WinMaximize, WinMenuSelectItem, WinMinimize, WinMinimizeAll, WinMinimizeAllUndo, WinMove, WinRestore, WinSet, WinSetTitle, WinShow, WinWait, WinWaitActive, WinWaitClose, WinWaitNotActive, #AllowSameLineComments, #CommentFlag, #ErrorStdOut, #EscapeChar, #HotkeyInterval, #HotkeyModifierTimeout, #Hotstring, #Include, #InstallKeybdHook, #InstallMouseHook, #MaxHotkeysPerInterval, #MaxMem, #MaxThreads, #MaxThreadsBuffer, #MaxThreadsPerHotkey, #NoTrayIcon, #Persistent, #SingleInstance, #UseHook, #WinActivateForce (some of these make no sense in Linux though and will never be done, such as RegRead)

## Installation

This is a normal Crystal program, refer to the respective documentation

## Usage

TODO

## Development

TODO

## Contributing

TODO
