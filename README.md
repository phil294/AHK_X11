# AHK_X11

AutoHotkey for Linux. (WORK IN PROGRESS)

<div align="center">

![MsgBox](popup.png)

`MsgBox, AHK_X11` (*)
</div>

More specifically: A very basic but functional reimplementation AutoHotkey v1.0.24 (2004) for Unix-like systems with an X window system (X11), written from ground up in Crystal with the help of [x11-cr](https://github.com/TamasSzekeres/x11-cr/), [libxdo](https://github.com/jordansissel/xdotool)([bindings](https://github.com/woodruffw/x_do.cr)) and [crystal-gobject](https://github.com/jhass/crystal-gobject)(GTK), with the eventual goal of 80% feature parity, but most likely never full compatibility. More importantly, because of the old version of the spec (you can check the old manual by installing or extracting the old `.chm` manual from [here](https://www.autohotkey.com/download/1.0/AutoHotkey1024.exe)), many modern AHK features will be missing, especially expressions (`:=`, `% v`) and functions, so you probably can't just port your scripts from Windows. Maybe this will also be added some day, but it does not have high priority for me personally. This AHK will be shipped as a single executable native binary with very low resource overhead and fast execution time.

> Please also check out [Keysharp](https://bitbucket.org/mfeemster/keysharp/), a fork of [IronAHK](https://github.com/Paris/IronAHK/tree/master/IronAHK), another complete rewrite of AutoHotkey in C# that tries to be compatible with multiple OSes and support modern, v2-like AHK syntax with much more features than this one. In comparison, AHK_X11 is a lot less ambitious and more compact, and Linux only.

Features:
- [x] Hotkeys (basic support complete)
- [ ] Hotstrings (difficult in X11; help needed)
- [x] <strike>Window management (setup complete, but all commands are still missing)</strike> *currently broken*, [1](https://github.com/woodruffw/x_do.cr/issues/10) [2](https://github.com/woodruffw/x_do.cr/issues/12)
- [x] Send keys (basic support complete)
- [ ] Control mouse (TBD)
- [x] File management (setup complete, but all commands are still missing)
- [x] GUIs (setup complete, but all commands are missing)
- [ ] Compile script to executable (TBD)
- [x] Scripting: labels, flow control: If/Else, Loop
- [ ] Window Spy

Implementation details follow below; note however that this is not very representative. `Gui`, for example, is many times more massive and work requiring than any other command but still only listed as one.

```diff
DONE      ?% (27/214):
+ Else, { ... }, Break, Continue, Return, Exit, GoSub, GoTo, IfEqual, Loop, SetEnv, Sleep, FileCopy,
+ SetTimer, WinActivate, MsgBox (incomplete), Gui (demo window), SendRaw, #Persistent, ExitApp,
+ EnvAdd, EnvSub, EnvMult, EnvDiv, ControlSendRaw, IfWinExist/IfWinNotExist, SetWorkingDir,
+ FileAppend

NEW       1% (2/214): (new Linux-specific commands)
@@ Echo, ahk_x11_print_vars @@

REMOVED   ?% (21/214):
# ### Those that simply make no sense in Linux:
# EnvSet, EnvUpdate, PostMessage, RegDelete, RegRead, RegWrite, SendMessage, #InstallKeybdHook, 
# #InstallMouseHook, #UseHook
#
# ### "Control" commands are impossible with X11, I *think*?
# Control, ControlClick, ControlFocus, ControlGet, ControlGetFocus, 
# ControlGetPos, ControlGetText, ControlMove, ControlSetText, SetControlDelay
#
# ### Skipped for other reasons:
# AutoTrim: It's always Off. It would not differentiate between %a_space% and %some_var%.
#           It's possible but needs significant work.

TO DO     ?% (164/214): alphabetically
- BlockInput, ClipWait, ControlSend, CoordMode, 
- DetectHiddenText, DetectHiddenWindows, Drive, DriveGet, DriveSpaceFree, Edit, 
- FileCopyDir, FileCreateDir, FileCreateShortcut, FileDelete, 
- FileInstall, FileReadLine, FileGetAttrib, FileGetShortcut, FileGetSize, FileGetTime, FileGetVersion, 
- FileMove, FileMoveDir, FileRecycle, FileRecycleEmpty, FileRemoveDir, FileSelectFile, 
- FileSelectFolder, FileSetAttrib, FileSetTime, FormatTime, GetKeyState, GroupActivate, GroupAdd, 
- GroupClose, GroupDeactivate, Gui, GuiControl, GuiControlGet, Hotkey, If var [not] between,
- If var [not] in/contains MatchList, If var is [not] type, IfNotEqual, IfExist/IfNotExist, 
- IfGreater/IfGreaterOrEqual, IfInString/IfNotInString, IfLess/IfLessOrEqual, IfMsgBox, 
- IfWinActive/IfWinNotActive, IniDelete, IniRead, IniWrite, Input, 
- InputBox, KeyHistory, KeyWait, ListHotkeys, ListLines, ListVars, Loop (files & folders),
- Loop (parse a string), Loop (read file contents), Loop (registry), Menu, MouseClick, 
- MouseClickDrag, MouseGetPos, MouseMove, OnExit, Pause, PixelGetColor, PixelSearch, 
- Process, Progress, Random, Reload, Run, RunAs, RunWait, Send, SetBatchLines, 
- SetCapslockState, SetDefaultMouseSpeed, SetFormat, SetKeyDelay, SetMouseDelay, 
- SetNumlockState, SetScrollLockState, SetStoreCapslockMode, SetTitleMatchMode, 
- SetWinDelay, Shutdown, Sort, SoundGet, SoundGetWaveVolume, SoundPlay, SoundSet, 
- SoundSetWaveVolume, SplashImage, SplashTextOn, SplashTextOff, SplitPath, StatusBarGetText, 
- StatusBarWait, StringCaseSense, StringGetPos, StringLeft, StringLen, StringLower, StringMid, 
- StringReplace, StringRight, StringSplit, StringTrimLeft, StringTrimRight, StringUpper, Suspend, 
- SysGet, Thread, ToolTip, Transform, TrayTip, URLDownloadToFile, WinActivateBottom, 
- WinClose, WinGetActiveStats, WinGetActiveTitle, WinGetClass, WinGet, WinGetPos, WinGetText, 
- WinGetTitle, WinHide, WinKill, WinMaximize, WinMenuSelectItem, WinMinimize, WinMinimizeAll, 
- WinMinimizeAllUndo, WinMove, WinRestore, WinSet, WinSetTitle, WinShow, WinWait, WinWaitActive, 
- WinWaitClose, WinWaitNotActive, #AllowSameLineComments, #CommentFlag, #ErrorStdOut, #EscapeChar, 
- #HotkeyInterval, #HotkeyModifierTimeout, #Hotstring, #Include, #MaxHotkeysPerInterval, #MaxMem, 
- #MaxThreads, #MaxThreadsBuffer, #MaxThreadsPerHotkey, #NoTrayIcon, #SingleInstance, 
- #WinActivateForce
```

## Installation

You need (?) to have `libxdo` installed, which is usually done by installing `xdotool` on your distribution. Also required is a running X11 server and GTK installed, which you most likely already have.

Then, you can download the latest x86_64 binary from [here](https://github.com/phil294/AHK_X11/releases/download/0.0.1/ahk_x11) or build from source (see "Development" below). Make the downloaded file executable and you should be good to go.

**Binary was built on Arch Linux and probably does not run on Debian or Ubuntu. Please use the instructions under Development instead. (I'll attach Debian builds too soon)**

**Please note that the current version is still pretty useless** because most things are not implemented yet.

## Usage

Pass the script to execute as first parameter, e.g. `./ahk_x11 "path to your script.ahk"`.

In the future, we'll also have proper Desktop integration so you can double click ahk files to run them.

<details>
<summary>Here's a working demo script showing several of the commands so far implemented.</summary>

```AutoHotkey
GoSub greet
return ; some comment

greet:
my_var = 1234
sleep 0.001
IfEqual, my_var, 1234, MsgBox, %my_var%! Try pressing ctrl+shift+A.
else, msgbox ??
return

^+a::
msgbox You pressed ctrl shift A. If you press ctrl+shift+B, ahk_x11 should type something for you.
return

^+b::
SetTimer, my_timer, %myvar%
loop, 3
{
	sendraw, loop no %A_Index% `; ...
}
return

my_timer:
settimer, my_timer, off
msgbox, A timer was triggered!
return
```
</details>

### Caveats

#### Focus stealing prevention

`MsgBox` (which currently only accepts 0 or 1 arguments) should always work fine, but some Linux distros apply some form of focus stealing prevention. If you have enabled that, it is very likely that those msgbox popups will be created hidden behind all other open windows. This is even more problematic because popups do not appear in the task bar, so they are essentially invisible. (Only?) solution: Disable focus stealing prevention.

#### Appearance

(*) The `MsgBox` picture at the top was taken on a XFCE system with [Chicago95](https://github.com/grassmunk/Chicago95) installed, a theme that resembles Win95 look&feel. On your system, it will look like whatever GTK popups always look like.

## Development

These are the steps required to build this project locally. Most of it is all WIP and temporary and only necessary so the different dependencies get along fine (x11 and gobject bindings).
As a bonus, the `build_namespace` invocations cache the GIR (`require_gobject` calls) and thus reduce the overall compile time from ~6 to ~3 seconds.

1. [Install](https://crystal-lang.org/install/) Crystal and Shards (Shards is typically included in Crystal installation)
1. `git clone https://github.com/phil294/AHK_X11`
1. `cd AHK_X11`
1. Run these commands one by one (I haven't double them, so it's best to check the results manually)
    ```bash
    shards install
    # populate cache
    crystal run lib/gobject/src/generator/build_namespace.cr -- Gtk 3.0 > lib/gobject/src/gtk/gobject-cache-gtk.cr
    crystal run lib/gobject/src/generator/build_namespace.cr -- xlib 2.0 > lib/gobject/src/gtk/gobject-cache-xlib--modified.cr
    for lib in "GObject 2.0" "GLib 2.0" "Gio 2.0" "GModule 2.0" "Atk 1.0" "HarfBuzz 0.0" "GdkPixbuf 2.0" "cairo 1.0" "Pango 1.0" "Gdk 3.0"; do
        echo "### $lib" >> lib/gobject/src/gtk/gobject-cache-gtk-other-deps.cr
        crystal run lib/gobject/src/generator/build_namespace.cr -- $lib >> lib/gobject/src/gtk/gobject-cache-gtk-other-deps.cr
    done
    # update lib to use cache
    sed -i -E 's/^(require_gobject)/# \1/g' lib/gobject/src/gtk/gobject-cache-gtk.cr lib/gobject/src/gtk/gobject-cache-gtk-other-deps.cr
    sed -i -E 's/^require_gobject "Gtk", "3.0"$/require ".\/gobject-cache-gtk"/' lib/gobject/src/gtk/gtk.cr
    echo 'require "./gobject-cache-xlib--modified"' > tmp.txt; echo 'require "./gobject-cache-gtk-other-deps"' >> tmp.txt; cat lib/gobject/src/gtk/gobject-cache-gtk.cr >> tmp.txt; mv tmp.txt lib/gobject/src/gtk/gobject-cache-gtk.cr
    echo 'macro require_gobject(namespace, version = nil) end' >> lib/gobject/src/gobject.cr
    # delete conflicting c function binding by modifying the cache
    sed -i -E 's/  fun open_display = XOpenDisplay : Void$//'  lib/gobject/src/gtk/gobject-cache-xlib--modified.cr
    ```
1. `shards build -Dpreview_mt --release`, then `bin/ahk_x11 "your ahk file.ahk"` or while in development, `shards run -Dpreview_mt -- "your ahk file.ahk"`

## Performance

Not yet explicitly tuned for performance, but by design and choice of technology, it should run reasonably fast. Most recent tests yielded 0.03 ms for parsing one instruction line (this happens once at startup). Execution speed even is at least x100 faster than that.

TODO: speed measurements for `Send` and window operations

## Contributing

If you feel like it, you are welcome to contribute. This program has a very modular structure due to its nature which should make it easier to add features. Most work pending is just implementing commands, as almost everything more complicated is now bootstrapped. Simply adhere to the 2004 spec chm linked above. There's documentation blocks all across the source.

Commands behave mostly autonomous. See for example `src/cmd/file/file-copy.cr`: All that is needed for most commands is `min_args`, `max_args`, the `run` implementation and the correct class name: The last part of the class name (here `FileCopy`) is automatically inferred to be the actual command name in scripts.
Regarding `run`: Anything can happen here, but several commands will access the `thread` or `thread.runner`, mostly for `thread.runner.get_user_var`, `thread.get_var` and `thread.runner.set_user_var`.

GUI: A bit more complex than the other missing commands. Some wiring is still missing (variables, positioning, multi window etc.). Once that is done, all known controls need to be translated into GTK. For that, both the [GTK Docs for C](https://docs.gtk.org/gtk3) and `lib/gobject/src/gtk/gobject-cache-gtk.cr` will be helpful.

A more general overview:
- `src/build` does the parsing etc. and is mostly complete
- `src/run/runner` and `src/run/thread` are worth looking into, this is the heart of the application and where global and thread state is stored
- `src/cmd` contains all commands exposed to the user.

There's also several `TODO:`s scattered around all source files mostly around technical problems that need some revisiting.

While Crystal brings its own hidden `::Thread` class, any reference to `Thread` in the source refers to `Run::Thread` which actually are no real threads (see `Run::Thread` docs).

## Issues

For bugs and feature requests, please open up an issue. I am also available on the AHK Discord server or the [forum](https://www.autohotkey.com/boards/viewtopic.php?f=81&t=106640).

## License

[GPL-2.0](https://tldrlegal.com/license/gnu-general-public-license-v2)
