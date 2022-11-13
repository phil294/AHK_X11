# AHK_X11

AutoHotkey for Linux.

<div align="center">

![MsgBox](popup.png)

`MsgBox, AHK_X11` (*)
</div>

This project is usable, but WORK IN PROGRESS.

**Scripts from Windows will usually NOT WORK without modifications.** If you want this to become a reality, you're welcome to contribute, and/or join the [AHK Discord](https://discord.com/invite/autohotkey-115993023636176902)'s #ahk_x11 channel.

**Requires X11**, does not work with Wayland yet. This is important for Ubuntu version 22.04 and up ([link](https://askubuntu.com/q/1410256))

[**Direct download**](https://github.com/phil294/ahk_x11/releases/latest/download/ahk_x11.zip) (all Linux distributions, x86_64, single executable)

[**FULL DOCUMENTATION**](https://phil294.github.io/AHK_X11) (single HTML page)

[**Go to installation instructions**](#installation)

[**DEMO VIDEO**](https://raw.githubusercontent.com/phil294/AHK_X11/master/demo.mp4): Installation, script creation, compilation

[AutoHotkey](https://www.autohotkey.com/) is "Powerful. Easy to learn. The ultimate automation scripting language for Windows.". This project tries to bring large parts of that to Linux.

More specifically: A very basic but functional reimplementation AutoHotkey v1.0.24 (2004) for Unix-like systems with an X window system (X11), written from ground up with [Crystal](https://crystal-lang.org/)/[libxdo](https://github.com/jordansissel/xdotool)/[crystal-gobject](https://github.com/jhass/crystal-gobject)/[x11-cr](https://github.com/TamasSzekeres/x11-cr/)/[x_do.cr](https://github.com/woodruffw/x_do.cr), with the eventual goal of 80% feature parity, but most likely never full compatibility. Currently about 60% of work is done. This AHK is shipped as a single executable native binary with very low resource overhead and fast execution time.

Note that because of the old version of the spec (at least for now), many modern AHK features are missing, especially expressions (`:=`, `% v`), classes, objects and functions, so you probably can't just port your scripts from Windows. More to read: [Project goals](https://github.com/phil294/AHK_X11/issues/8)

You can use AHK_X11 to create stand-alone binaries with no dependencies, including full functionality like Hotkeys and GUIs. (just like on Windows)

Please also check out [Keysharp](https://bitbucket.org/mfeemster/keysharp/), a WIP fork of [IronAHK](https://github.com/Paris/IronAHK/tree/master/IronAHK), another complete rewrite of AutoHotkey in C# that tries to be compatible with multiple OSes and support modern, v2-like AHK syntax with much more features than this one. In comparison, AHK_X11 is a lot less ambitious and more compact, and Linux only.

Features:
- [x] Hotkeys
- [x] Hotstrings
- [x] Window management (but some commands are still missing)
- [x] Send keys
- [x] Control mouse
- [x] File management (but some commands are still missing)
- [x] GUIs (partially done)
- [x] One-click compile script to portable stand-alone executable
- [x] Scripting: labels, flow control: If/Else, Loop
- [ ] Window Spy
- [x] Graphical installer (optional)
- [x] Context menu and compilation just like on Windows

Besides:
- Interactive console (REPL)

AHK_X11 can be used completely without a terminal. You can however if you want use it console-only too. Graphical commands are optional, it also runs headless.

<details><summary><strong>CLICK TO SEE WHICH COMMANDS ARE IMPLEMENTED AND WHICH ARE MISSING</strong>. Note however that this is not very representative. For example, no `Gui` sub command is included in the listing. For a better overview on what is already done, skim through the <a href="https://phil294.github.io/AHK_X11">docs</a>.</summary>

```diff
DONE      ?% (86/217):
+ Else, { ... }, Break, Continue, Return, Exit, GoSub, GoTo, IfEqual, Loop, SetEnv, Sleep, FileCopy,
+ SetTimer, WinActivate, MsgBox, Gui, SendRaw, #Persistent, ExitApp,
+ EnvAdd, EnvSub, EnvMult, EnvDiv, ControlSendRaw, IfWinExist/IfWinNotExist, SetWorkingDir,
+ FileAppend, Hotkey, Send, ControlSend, #Hotstring, Menu, FileCreateDir, FileDelete, IfMsgBox,
+ #SingleInstance, Edit, FileReadLine, FileSelectFile, FileSelectFolder, FileSetAttrib, FileSetTime,
+ IfNotEqual, If var [not] between, IfExist/IfNotExist, IfGreater/IfGreaterOrEqual,
+ IfInString/IfNotInString, IfLess/IfLessOrEqual, IfWinActive/IfWinNotActive, IniDelete, IniRead,
+ IniWrite, Loop (files & folders), Loop (read file contents), MouseClick, Pause, Reload,
+ StringGetPos, StringLeft, StringLen, StringLower, StringMid, StringReplace, StringRight,
+ StringUpper, Suspend, URLDownloadToFile, WinClose, WinGetPos, WinKill, WinMaximize, WinMinimize,
+ WinMove, WinRestore, MouseGetPos, MouseMove, GetKeyState, KeyWait, ControlClick, WinGetText,
+ WinGetTitle, WinGetClass, PixelGetColor, CoordMode, GuiControl, ControlGetPos, ControlGetText,
+ WinGet

NEW       3% (6/217): (not part of spec or from a more recent version)
@@ Echo, ahk_x11_print_vars, FileRead, RegExGetPos, RegExReplace, EnvGet @@

REMOVED   6% (12/217):
# ### Those that simply make no sense in Linux:
# EnvSet, EnvUpdate, PostMessage, RegDelete, RegRead, RegWrite, SendMessage, #InstallKeybdHook, 
# #InstallMouseHook, #UseHook, Loop (registry)
#
# ### Skipped for other reasons:
# AutoTrim: It's always Off. It would not differentiate between %a_space% and %some_var%.
#           It's possible but needs significant work.

TO DO     ?% (109/217): alphabetically
- BlockInput, ClipWait, Control, ControlFocus, ControlGet, ControlGetFocus, 
- ControlMove, ControlSetText,
- DetectHiddenText, DetectHiddenWindows, Drive, DriveGet, DriveSpaceFree,
- FileCopyDir, FileCreateShortcut,
- FileInstall, FileGetAttrib, FileGetShortcut, FileGetSize, FileGetTime, FileGetVersion,
- FileMove, FileMoveDir, FileRecycle, FileRecycleEmpty, FileRemoveDir,
- FormatTime, GroupActivate, GroupAdd,
- GroupClose, GroupDeactivate, GuiControlGet,
- If var [not] in/contains MatchList, If var is [not] type, Input, 
- InputBox, KeyHistory, ListHotkeys, ListLines, ListVars, Loop (parse a string),
- MouseClickDrag, OnExit, PixelSearch, 
- Process, Progress, Random, RunAs, SetBatchLines, 
- SetCapslockState, SetControlDelay, SetDefaultMouseSpeed, SetFormat, SetKeyDelay, SetMouseDelay, 
- SetNumlockState, SetScrollLockState, SetStoreCapslockMode, SetTitleMatchMode, 
- SetWinDelay, Shutdown, Sort, SoundGet, SoundGetWaveVolume, SoundPlay, SoundSet, 
- SoundSetWaveVolume, SplashImage, SplashTextOn, SplashTextOff, SplitPath, StatusBarGetText, 
- StatusBarWait, StringCaseSense, StringSplit, StringTrimLeft, StringTrimRight,
- SysGet, Thread, ToolTip, Transform, TrayTip, WinActivateBottom,
- WinGetActiveStats, WinGetActiveTitle,
- WinHide, WinMenuSelectItem, WinMinimizeAll,
- WinMinimizeAllUndo, WinSet, WinSetTitle, WinShow, WinWait, WinWaitActive, 
- WinWaitClose, WinWaitNotActive, #CommentFlag, #ErrorStdOut, #EscapeChar, 
- #HotkeyInterval, #HotkeyModifierTimeout, #Include, #MaxHotkeysPerInterval, #MaxMem, 
- #MaxThreads, #MaxThreadsBuffer, #MaxThreadsPerHotkey, #NoTrayIcon, #WinActivateForce

Also planned, even though it's not part of 1.0.24 spec:
- ImageSearch
- Maybe some kind of OCR command
- #IfWinActive (the directive)
```
</details>

## Installation

Prerequisites:
- X11 and GTK are the only dependencies. You most likely have them already. Wayland support would be cool too some day.
- Old distros like Debian *before* 10 (Buster) or Ubuntu *before* 18.04 are not supported ([reason](https://github.com/jhass/crystal-gobject/issues/73#issuecomment-661235729)). Otherwise, it should not matter what system you use.

Then, you can download the latest binary from the [release section](https://github.com/phil294/AHK_X11/releases). Make the downloaded file executable and you should be good to go.

There is no auto updater yet! (but planned) You will probably want to get the latest version then and again.

## Usage

There are different ways to use it.

1. The graphical way, like on Windows: Running the program directly opens up the interactive installer.
    - Once installed, all `.ahk` files are associated with AHK_X11, so you can simply double click them.
    - Also adds the Compiler into `Open as...` Menus.
2. Command line: Pass the script to execute as first parameter, e.g. `./ahk_x11 "path to your script.ahk"`
    - Once your script's auto-execute section has finished, you can also execute arbitrary single line commands in the console. Code blocks aren't supported yet in that situation. Those single lines each run in their separate threads, which is why variables like `%ErrorLevel%` will always be `0`.
    - When you don't want to pass a script, you can specify `--repl` instead (implicit `#Persistent`).
    - If you want to pass your command from stdin instead of file, do it like this: `./ahk_x11 /dev/stdin <<< 'MsgBox'`.
    - Compile scripts with `./ahk_x11 --compile "path/script.ahk"
    - Hashbang supported if first line starts with `#!`

### Caveats

#### Focus stealing prevention

Some Linux distros offer a configurable setting for focus stealing prevention. Usually, it's default off. But if you have activated it, window focus changing actions like `MsgBox` or `WinActivate` will not work as expected: A `MsgBox` will appear hidden *behind* the active window. This can be useful to prevent accidental popup dismissal but when you don't like that, you have three options:
- disable said setting
- use the `always on top` setting of MsgBox
- <details><summary>hack around it with code</summary>

    ```AutoHotkey
    SetTimer, MsgBoxToFront, 1
    MsgBox, Hello
    Return

    MsgBoxToFront:
    SetTimer, MsgBoxToFront, off
    ; You might want to adjust the matching criteria, especially for compiled scripts
    WinActivate ahk_class ahk_x11
    return
    ```

#### Appearance

(*) The `MsgBox` picture at the top was taken on a XFCE system with [Chicago95](https://github.com/grassmunk/Chicago95) installed, a theme that resembles Win95 look&feel. On your system, it will look like whatever GTK popups always look like.

#### Incompatibilities with Windows versions

Like covered above, AHK_X11 is vastly different to modern Windows-AutoHotkey because it is 1. *missing its more recent features* and 2. there are *still several features missing*. Apart from that, there are a few minor *incompatibilities* between AHK_X11 and the then-Windows-AutoHotkey 1.0.24:
- `#NoEnv` is the default, this means, to access environment variables, you'll have to use `EnvGet`.
- All arguments are always evaluated only at runtime, even if they are static. This can lead to slightly different behavior or error messages at runtime vs. build time.
- Several more small subtle differences highlighted in green throughout the docs page

Besides, it should be noted that un[documented](https://phil294.github.io/AHK_X11) == undefined.

## Development

These are the steps required to build this project locally, such as if you want to contribute to the project. Please open an issue if anything doesn't work.

You don't need to follow this procedure to *use* AHK_X11, for that, please see Installation above.

1. Install development versions of prerequisites.
    1. Ubuntu 20.04 and up:
        1. Dependencies
            ```
            sudo apt-get install libxinerama-dev libxkbcommon-dev libxtst-dev libgtk-3-dev libxi-dev libx11-dev libgirepository1.0-dev libatspi2.0-dev
            ```
        1. [Install](https://crystal-lang.org/install/) Crystal and Shards (Shards is typically included in Crystal installation)
    1. Arch Linux:
        ```
        sudo pacman -S crystal shards gcc libxkbcommon libxinerama libxtst gtk3 gc
        ```
1. `git clone https://github.com/phil294/AHK_X11`
1. `cd AHK_X11`
1. `shards install`
1. Run various library tweaks with `./setup_dependencies.sh`. This is mostly WIP and hacked together, so if anything doesn't work, please open an issue.
1. Now everything is ready for local use with `shards build -Dpreview_mt`, *if* you have `libxdo` (xdotool) version 2021* upwards installed. For version 2016*, you'll need to upgrade this dependency somehow. One way to achieve this is explained below.<br>Read on for a cross-distro compatible build.
1. To make AHK_X11 maximally portable, various dependencies should be statically linked. This is especially important because of the script compilation feature: You can use the binary to transform a script into a new stand-alone binary, and that resulting binary should be portable across various Linux distributions without ever requiring the user to install any dependencies. Here is an overview of all dependencies. All of this was tested on Ubuntu 18.04.
    - Should be statically linked:
        - `libxdo`. Additionally to the above reasons, it isn't backwards compatible (e.g. Ubuntu 18.04 and 20.04 versions are incompatible) and may introduce even more breaking changes in the future. Also, we fix a rarely occurring fatal error here (probably Crystal-specific?). So,
            - clone [xdotool](https://github.com/jordansissel/xdotool) somewhere, in there,
            - in `xdo.c`, after `data = xdo_get_window_property_by_atom(xdo, wid, request, &nitems, &type, &size);`, add another `if(data == NULL) return XDO_ERROR;`
            - run `make clean && make libxdo.a` and then copy the file `libxdo.a` into our `static` folder (create if it doesn't exist yet).
        - Dependencies of `libxdo`: `libxkbcommon`, `libXtst`, `libXi`, `libXinerama` and `libXext`. The static libraries should be available from your package manager dependencies installed above so normally there's nothing you need to do.
        - Other (crystal dependencies?), also via package manager: `libevent_pthreads`, `libevent`, and `libpcre`
        - `libgc` is currently shipped and linked automatically by Crystal itself so there is no need for it
    - Stays dynamically linked:
        - `libgtk-3` and its dependencies, because afaik Gtk is installed everywhere, even on Qt-based distros. If you know of any common distribution that does not include Gtk libs by default please let me know. Gtk does also not officially support static linking. `libgtk-3`, `libgd_pixbuf-2.0`, `libgio-2.0`, `libgobject-2.0`, `libglib-2.0`, `libgobject-2.0`
        - glibc / unproblematic libraries according to [this list](https://github.com/AppImage/pkg2appimage/blob/master/excludelist): `libX11`, `libm`, `libpthread`, `librt`, `libdl`.
1. All in all, once you have `libxdo.a` inside the folder `static`, the following builds the final binary which should be very portable: `shards build -Dpreview_mt --link-flags="-no-pie -L$PWD/static -Wl,-Bstatic -lxdo -lxkbcommon -lXinerama -lXext -lXtst -lXi -levent_pthreads -levent -lpcre -Wl,-Bdynamic"`. When not in development, increase optimizations and runtime speed by adding `--release`. The resulting binary is about 4.7 MiB in size.
1. Attach the installer with `bin/ahk_x11 --compile src/installer.ahk tmp && mv tmp bin/ahk_x11`. Explanation: The installer is not shipped separately and instead bundled with the binary by doing this. Bundling is the same thing as compiling a script as a user. As you can see, it is possible to repeatedly compile a binary, with each script being appended at the end each time. Only the last one actually executed - and only if no params are passed to the program. There's no point in compiling multiple times, but it allows us to ship a default script (the installer) for when no arguments are passed. In other words, this is possible for a user: `ahk_x11 --compile script1.ahk && ./script1 --compile script2.ahk && ./script2` but no one will ever do that.

## Performance

Not yet explicitly tuned for performance, but by design and choice of technology, it should run reasonably fast. Most recent tests yielded 0.03 ms for parsing one instruction line (this happens once at startup). Execution speed even is at least x100 faster than that.

TODO: speed measurements for `Send` and window operations

## Contributing

If you feel like it, you are welcome to contribute! The language in use, Crystal, is resembling Ruby syntax also great for beginners.

This program has a very modular structure due to its nature which should make it easier to add features. Most work pending is just implementing commands, as almost everything more complicated is now bootstrapped. Simply adhere to the 2004 spec chm linked above. There's documentation blocks all across the source.

Commands behave mostly autonomous. See for example [`src/cmd/file/file-copy.cr`](https://github.com/phil294/AHK_X11/blob/master/src/cmd/file/file-copy.cr): All that is needed for most commands is `min_args`, `max_args`, the `run` implementation and the correct class name: The last part of the class name (here `FileCopy`) is automatically inferred to be the actual command name in scripts.
Regarding `run`: Anything can happen here, but several commands will access the `thread` or `thread.runner`, mostly for `thread.runner.get_user_var`, `thread.get_var` and `thread.runner.set_user_var`.

GUI: Several controls and their options still need to be translated into GTK. For that, both the [GTK Docs for C](https://docs.gtk.org/gtk3) and `lib/gobject/src/gtk/gobject-cache-gtk.cr` are helpful.

A more general overview:
- `src/build` does the parsing etc. and is mostly complete
- `src/run/runner` and `src/run/thread` are worth looking into, this is the heart of the application and where global and thread state is stored
- `src/cmd` contains all commands exposed to the user.
- There's *three* libraries included which somehow interact with the X server: `x_do.cr` for automatization (window, keyboard, mouse) as `runner.x_do`, `crystal-gobject` for Gtk (`Gui`, `MsgBox`) as `runner.gui` (`gui.cr`) and Atspi (control handling) as `runner.at_spi` (`at-spi.cr`), and `x11-cr` for low-level X interaction (hotkeys, hotstrings) as `runner.x11` (`x11.cr`).

There's also several `TODO:`s scattered around all source files mostly around technical problems that need some revisiting.

While Crystal brings its own hidden `::Thread` class, any reference to `Thread` in the source refers to `Run::Thread` which actually are no real threads (see [`Run::Thread`](https://github.com/phil294/AHK_X11/blob/master/src/run/thread.cr) docs).

Current commits are collected in the `development` branch and then merged into `master` for each release.

## Issues

For bugs and feature requests, please open up an issue, or check the Discord or [Forum](https://www.autohotkey.com/boards/viewtopic.php?f=81&t=106640).

## License

[GPL-2.0](https://tldrlegal.com/license/gnu-general-public-license-v2)
