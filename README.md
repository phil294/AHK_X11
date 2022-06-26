# AHKX11

AutoHotkey for Linux. (WORK IN PROGRESS)

More specifically: A reimplementation AutoHotkey v1.0.24 (2004) for Unix-like systems with an X window system (X11), written from ground up in Crystal with the help of [x11-cr](https://github.com/TamasSzekeres/x11-cr/), [libxdo](https://github.com/jordansissel/xdotool)([bindings](https://github.com/woodruffw/x_do.cr)) and [crystal-gobject](https://github.com/jhass/crystal-gobject)(GTK), with the eventual goal of 80% feature parity, but most likely never full compatibility. More importantly, because of the old version of the spec (you can check the old manual by installing or extracting the old `.chm` manual from [here](https://www.autohotkey.com/download/1.0/AutoHotkey1024.exe)), many modern AHK features will be missing, especially expressions (`:=`, `% v`) and functions, so you probably can't just port your scripts from Windows. Maybe this will also be added some day, but it does not have high priority for me personally.

Features:
- [ ] Hotkeys
- [ ] Hotstrings
- [ ] Window management
- [ ] Keyboard and mouse control
- [ ] File management
- [ ] GUIs
- [ ] Compile script to executable

Status: None of the above yet, planned is all of it.

Please also check out [Keysharp](https://bitbucket.org/mfeemster/keysharp/), a fork of [IronAHK](https://github.com/Paris/IronAHK/tree/master/IronAHK), another complete rewrite in C# with a similar goal.

## Installation

This is a normal Crystal program, refer to the respective documentation

## Usage

TODO

## Development

TODO

## Contributing

TODO
