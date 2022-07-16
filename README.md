# AHK_X11

AutoHotkey for Linux. (WORK IN PROGRESS)

More specifically: A very basic but functional reimplementation AutoHotkey v1.0.24 (2004) for Unix-like systems with an X window system (X11), written from ground up in Crystal with the help of [x11-cr](https://github.com/TamasSzekeres/x11-cr/), [libxdo](https://github.com/jordansissel/xdotool)([bindings](https://github.com/woodruffw/x_do.cr)) and [crystal-gobject](https://github.com/jhass/crystal-gobject)(GTK), with the eventual goal of 80% feature parity, but most likely never full compatibility. More importantly, because of the old version of the spec (you can check the old manual by installing or extracting the old `.chm` manual from [here](https://www.autohotkey.com/download/1.0/AutoHotkey1024.exe)), many modern AHK features will be missing, especially expressions (`:=`, `% v`) and functions, so you probably can't just port your scripts from Windows. Maybe this will also be added some day, but it does not have high priority for me personally. This AHK will be shipped as a single executable native binary with very low resource overhead and fast execution time.

> Please also check out [Keysharp](https://bitbucket.org/mfeemster/keysharp/), a fork of [IronAHK](https://github.com/Paris/IronAHK/tree/master/IronAHK), another complete rewrite in C# with a similar goal.

Features:
- [x] Hotkeys (basic support complete)
- [ ] Hotstrings (difficult in X11; help needed)
- [ ] Window management (TBD)
- [ ] Keyboard and mouse control (TBD)
- [x] File management (setup complete, but most commands are still missing)
- [ ] GUIs (TBD)
- [ ] Compile script to executable (TBD)
- [x] Scripting: labels, flow control: If/Else, Loop

Implementation details follow below; note however that this is not very representative. `Gui`, for example, is many times more massive and work requiring than any other command but still only listed as one.

```diff
DONE      7% (14/213):
+ Else, { ... }, Break, Continue, Return, Exit, GoSub, GoTo, IfEqual, Loop, SetEnv, Sleep, FileCopy, SetTimer

NEW       1% (2/213): (new Linux-specific commands)
@@ Echo, ahk_x11_print_vars @@

REMOVED   5% (11/213):
# ### Those that simply make no sense in Linux:
# EnvSet, EnvUpdate, PostMessage, RegDelete, RegRead, RegWrite, SendMessage, #InstallKeybdHook, 
# #InstallMouseHook, #UseHook
# ### Skipped for other reasons:
# AutoTrim: It's always Off. It would not differentiate between %a_space% and %some_var%. It's possible but needs significant work

TO DO     87% (186/213): alphabetically
- BlockInput, ClipWait, Control, ControlClick, ControlFocus, ControlGet, ControlGetFocus, 
- ControlGetPos, ControlGetText, ControlMove, ControlSend / ControlSendRaw, ControlSetText, CoordMode, 
- DetectHiddenText, DetectHiddenWindows, Drive, DriveGet, DriveSpaceFree, Edit, EnvAdd, EnvDiv, 
- EnvMult, EnvSub, ExitApp, FileAppend, FileCopyDir, FileCreateDir, FileCreateShortcut, FileDelete, 
- FileInstall, FileReadLine, FileGetAttrib, FileGetShortcut, FileGetSize, FileGetTime, FileGetVersion, 
- FileMove, FileMoveDir, FileRecycle, FileRecycleEmpty, FileRemoveDir, FileSelectFile, 
- FileSelectFolder, FileSetAttrib, FileSetTime, FormatTime, GetKeyState, GroupActivate, GroupAdd, 
- GroupClose, GroupDeactivate, Gui, GuiControl, GuiControlGet, Hotkey, If var [not] between,
- If var [not] in/contains MatchList, If var is [not] type, IfNotEqual, IfExist/IfNotExist, 
- IfGreater / IfGreaterOrEqual, IfInString/IfNotInString, IfLess/IfLessOrEqual, IfMsgBox, 
- IfWinActive / IfWinNotActive, IfWinExist/IfWinNotExist, IniDelete, IniRead, IniWrite, Input, 
- InputBox, KeyHistory, KeyWait, ListHotkeys, ListLines, ListVars, Loop (files & folders),
- Loop (parse a string), Loop (read file contents), Loop (registry), Menu, MouseClick, 
- MouseClickDrag, MouseGetPos, MouseMove, MsgBox, OnExit, Pause, PixelGetColor, PixelSearch, 
- Process, Progress, Random, Reload, Run, RunAs, RunWait, Send / SendRaw, SetBatchLines, 
- SetCapslockState, SetControlDelay, SetDefaultMouseSpeed, SetFormat, SetKeyDelay, SetMouseDelay, 
- SetNumlockState, SetScrollLockState, SetStoreCapslockMode, SetTitleMatchMode, 
- SetWinDelay, SetWorkingDir, Shutdown, Sort, SoundGet, SoundGetWaveVolume, SoundPlay, SoundSet, 
- SoundSetWaveVolume, SplashImage, SplashTextOn, SplashTextOff, SplitPath, StatusBarGetText, 
- StatusBarWait, StringCaseSense, StringGetPos, StringLeft, StringLen, StringLower, StringMid, 
- StringReplace, StringRight, StringSplit, StringTrimLeft, StringTrimRight, StringUpper, Suspend, 
- SysGet, Thread, ToolTip, Transform, TrayTip, URLDownloadToFile, WinActivate, WinActivateBottom, 
- WinClose, WinGetActiveStats, WinGetActiveTitle, WinGetClass, WinGet, WinGetPos, WinGetText, 
- WinGetTitle, WinHide, WinKill, WinMaximize, WinMenuSelectItem, WinMinimize, WinMinimizeAll, 
- WinMinimizeAllUndo, WinMove, WinRestore, WinSet, WinSetTitle, WinShow, WinWait, WinWaitActive, 
- WinWaitClose, WinWaitNotActive, #AllowSameLineComments, #CommentFlag, #ErrorStdOut, #EscapeChar, 
- #HotkeyInterval, #HotkeyModifierTimeout, #Hotstring, #Include, #MaxHotkeysPerInterval, #MaxMem, 
- #MaxThreads, #MaxThreadsBuffer, #MaxThreadsPerHotkey, #NoTrayIcon, #Persistent, #SingleInstance, 
- #WinActivateForce
```

## Performance

Not yet explicitly tuned for performance, but by design and choice of technology, it should run reasonably fast. Most recent tests yielded 0.03 ms for parsing one instruction line (this happens once at startup). Execution speed even is at least x100 faster than that.

TODO: speed measurements for `Send` and window operations

## Installation

This is a normal Crystal program, refer to the respective documentation

## Usage

TODO

## Development

TODO

## Contributing

TODO
