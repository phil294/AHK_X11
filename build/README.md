# Building from source

These are the steps required to build this project locally, such as if you want to contribute to the project. Please open an issue if anything doesn't work.

⚠️ **YOU DO <EM>NOT</EM> NEED TO FOLLOW THESE STEPS FOR AUTOHOTKEY SCRIPTING**. To do that, download AHK_X11 from the release section instead. Then you can use it like AHK on Windows. The below steps are for DEVELOPING IN **CRYSTAL LANGUAGE**. If you don't know what this is about, **[GO BACK TO THE MAIN README](../README.md) and read INSTALLATION**. ⚠️

## Development

### For local usage

1. Install development versions of prerequisites.
    1. Ubuntu 20.04 and up:
        1. Dependencies
            ```
            sudo apt-get install libxinerama-dev libxkbcommon-dev libxtst-dev libgtk-3-dev libxi-dev libx11-dev libgirepository1.0-dev libatspi2.0-dev libssl-dev libnotify-dev libyaml-dev
            ```
        1. [Install](https://crystal-lang.org/install/) Crystal and Shards (Shards is typically included in Crystal installation) (**due to issue #89, you currently need version 1.11 or (slightly) below**)
    1. Arch Linux:
        ```
        sudo pacman -S crystal shards gcc libxkbcommon libxinerama libxtst libnotify gtk3 gc
        ```
1. `git clone https://github.com/phil294/AHK_X11`
1. `cd AHK_X11`
1. `make bin/ahk_x11.dev`
1. Find your final binary in the `./bin` folder, it's about 13 MiB in size. It's not optimized for speed yet. Please also note that if you compile an `.ahk` script with it, it will NOT be portable across systems! For that, read on below.

### For making release-like binaries

The released binaries are special because they need to be portable. We achieve this by using AppImage. Portability is especially important because of the script compilation feature: You can use the binary to transform a script into a new stand-alone binary, and that resulting binary should be runnable in the future and across various Linux distributions without ever requiring the user to install any dependencies. Below are the instructions on how to do this / how the released binaries are produced.

1. Get on an Ubuntu 20.04 system, e.g. using Docker. 18.04 also works but Gtk 3.24 in 20.04 fixes the bug that ToolTips falsely grab focus
1. Do the same steps as listed in "For local usage": Install dependencies etc.
1. Run `make ahk_x11.AppImage`
1. Find your final binary as `ahk_x11.AppImage`. It's about 30 MiB in size.
1. You can then optionally either install it as usual for the current user by running directly *or* system-wide with `make install-appimage`. If you do the latter: Depending on your distribution, you might need to update the mime and desktop database with `sudo -i bash -c 'umask 0022 && update-mime-database /usr/share/mime && update-desktop-database /usr/share/applications && gtk-update-icon-cache -f -t /usr/share/icons/hicolor'`.

There's a script that does these things, makes a new release and publishes it etc., it's `./release.sh`. You most likely can't run it yourself though.

### Docker

In the rare case that you want to use ahk_x11 containerized for headless purposes, you can find a working Dockerfile example in `./ahk_x11.alpine.Dockerfile`. Build it in the parent (main) directory like so:

```bash
cp .gitignore .dockerignore && \
  docker build -t ahk_x11-alpine -f build/ahk_x11.alpine.Dockerfile . ; \
  rm .dockerignore
```

## Contributing

If you feel like it, you are welcome to contribute! The language in use, Crystal, is resembling Ruby syntax and consequently also great for beginners.

This program has a very modular structure due to its nature which should make it easier to add features. Most work pending is just implementing commands, as almost everything more complicated is now bootstrapped. Simply adhere to the 2004 spec that is the documentation for ahk_x11 (the large html file). There's documentation blocks all across the source.

Commands behave mostly autonomous. See for example [`src/cmd/file/file-copy.cr`](https://github.com/phil294/AHK_X11/blob/master/src/cmd/file/file-copy.cr): All that is needed for most commands is `min_args`, `max_args`, the `run` implementation and the correct class name: The last part of the class name (here `FileCopy`) is automatically inferred to be the actual command name in scripts.
Regarding `run`: Anything can happen here, but several commands will access the `thread` or `thread.runner`, mostly for `thread.runner.get_user_var_str`, `thread.get_var` and `thread.runner.set_user_var`.

GUI: Several controls and their options still need to be translated into GTK. For that, both the [GTK Docs for C](https://docs.gtk.org/gtk3) and the files in `lib/gi-crystal/src/auto/gtk-3.0/` will be helpful.

A more general overview:
- `src/build` does the parsing etc. and is mostly complete
- `src/run/runner` and `src/run/thread` are worth looking into, this is the heart of the application and where global and thread state is stored
- `src/cmd` contains all commands exposed to the user.
- There's *three* libraries included which somehow interact with the X server: `x_do.cr` for automatization (window, keyboard, mouse), `gi-crystal` for Gtk (`Gui`, `MsgBox`, `gui.cr`) and Atspi (control handling, `at-spi.cr`), and `x11-cr` for low-level X interaction (hotkeys, hotstrings, `x11.cr`).

There's also several `TODO:`s scattered around all source files mostly around technical problems that need some revisiting.

While Crystal brings its own hidden `::Thread` class, any reference to `Thread` in the source refers to `Run::Thread` which actually are no real threads (see [`Run::Thread`](https://github.com/phil294/AHK_X11/blob/master/src/run/thread.cr) docs).

There is a basic test script: `../tests.ahk`. Running it should complete without errors. It only covers the core functionality and a few edge cases right now, so the more tests we add, the better.
