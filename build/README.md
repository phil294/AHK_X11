# Building from source

These are the steps required to build this project locally, such as if you want to contribute to the project. Please open an issue if anything doesn't work.

⚠️ **YOU DO <EM>NOT</EM> NEED TO FOLLOW THESE STEPS FOR AUTOHOTKEY SCRIPTING**. To do that, download AHK_X11 from the release section instead. Then you can use it like AHK on Windows. The below steps are for DEVELOPING IN **CRYSTAL LANGUAGE**. If you don't know what this is about, **[GO BACK TO THE MAIN README](../README.md) and read INSTALLATION**. ⚠️

## Development

### For local usage

1. Install development versions of prerequisites.
    1. Ubuntu 20.04 and up:
        1. Dependencies
            ```
            sudo apt-get install libxinerama-dev libxkbcommon-dev libxtst-dev libgtk-3-dev libxi-dev libx11-dev libgirepository1.0-dev libatspi2.0-dev libssl-dev
            ```
        1. [Install](https://crystal-lang.org/install/) Crystal and Shards (Shards is typically included in Crystal installation)
    1. Arch Linux:
        ```
        sudo pacman -S crystal shards gcc libxkbcommon libxinerama libxtst gtk3 gc
        ```
1. `git clone https://github.com/phil294/AHK_X11`
1. `cd AHK_X11`
1. `shards install`
1. `bin/gi-crystal`
1. Remove the `private` from `private getter xdo_p : LibXDo::XDo*` in `lib/x_do/src/x_do.cr` (this is a temporary fix)
1. In `lib/gtk3/lib/gi-crystal/src/auto/gtk-3.0/gtk.cr`, replace all usages of `Glib::String` with `::String` (this is a temporary fix)
1. Now everything is ready for local use with `shards build -Dpreview_mt`, *if* you have `libxdo` (xdotool) version 2021* upwards installed. For version 2016*, you'll need to upgrade this dependency somehow. One way to achieve this is explained below.
1. Find your final binary in the `./bin` folder, it's about 4 MiB in size.

### For making release-like binaries

The released binaries are special because they need to be portable. We achieve this by using AppImage. Portability is especially important because of the script compilation feature: You can use the binary to transform a script into a new stand-alone binary, and that resulting binary should be portable across various Linux distributions without ever requiring the user to install any dependencies. Below are the instructions on how to do this / how the released binaries are produced. It's all optional but recommended. Might automate this some day, but for now it's all manual.

1. Get on an Ubuntu 20.04 system, e.g. using Docker. 18.04 also works but Gtk 3.24 in 20.04 fixes the bug that ToolTips falsely grab focus
1. `libxdo` isn't backwards compatible (e.g. Ubuntu 18.04 and 20.04 versions are incompatible). Also, we fix a rarely occurring fatal error here (probably Crystal-specific?). So,

    - clone [xdotool](https://github.com/jordansissel/xdotool) somewhere, in there,
    - in `xdo.c`, after `data = xdo_get_window_property_by_atom(xdo, wid, request, &nitems, &type, &size);`, add another `if(data == NULL) return XDO_ERROR;`
    - run `make clean && make` and then copy the files `libxdo.so` and `libxdo.so.3` into this very `build` folder.
1. Do the same steps as listed in "For local testing": Install dependencies etc.
1. Get `linuxdeploy-x86_64.AppImage` from https://github.com/linuxdeploy/linuxdeploy/, into this `build` folder
1. Get `linuxdeploy-plugin-gtk.sh` from https://raw.githubusercontent.com/linuxdeploy/linuxdeploy-plugin-gtk/master/linuxdeploy-plugin-gtk.sh
1. In that same file, *delete the line* `export GTK_THEME="$APPIMAGE_GTK_THEME" # Custom themes are broken` (this is a temporary fix ([issue](https://github.com/linuxdeploy/linuxdeploy-plugin-gtk/issues/39)))
1. Instead of `shards build`, run `./build.sh`. This also does shards build, but it adds the `--release` flag (slower compilation, faster output binary) and does the AppImage magic and attaches the installer.
1. Find your final binary `ahk_x11-[version]-x86_64.AppImage` in the `build` folder. It's about 30 MiB in size.

## Contributing

If you feel like it, you are welcome to contribute! The language in use, Crystal, is resembling Ruby syntax and consequently also great for beginners.

This program has a very modular structure due to its nature which should make it easier to add features. Most work pending is just implementing commands, as almost everything more complicated is now bootstrapped. Simply adhere to the 2004 spec that is the documentation for ahk_x11 (the large html file). There's documentation blocks all across the source.

Commands behave mostly autonomous. See for example [`src/cmd/file/file-copy.cr`](https://github.com/phil294/AHK_X11/blob/master/src/cmd/file/file-copy.cr): All that is needed for most commands is `min_args`, `max_args`, the `run` implementation and the correct class name: The last part of the class name (here `FileCopy`) is automatically inferred to be the actual command name in scripts.
Regarding `run`: Anything can happen here, but several commands will access the `thread` or `thread.runner`, mostly for `thread.runner.get_user_var`, `thread.get_var` and `thread.runner.set_user_var`.

GUI: Several controls and their options still need to be translated into GTK. For that, both the [GTK Docs for C](https://docs.gtk.org/gtk3) and the files in `lib/gi-crystal/src/auto/gtk-3.0/` will be helpful.

A more general overview:
- `src/build` does the parsing etc. and is mostly complete
- `src/run/runner` and `src/run/thread` are worth looking into, this is the heart of the application and where global and thread state is stored
- `src/cmd` contains all commands exposed to the user.
- There's *three* libraries included which somehow interact with the X server: `x_do.cr` for automatization (window, keyboard, mouse), `gi-crystal` for Gtk (`Gui`, `MsgBox`, `gui.cr`) and Atspi (control handling, `at-spi.cr`), and `x11-cr` for low-level X interaction (hotkeys, hotstrings, `x11.cr`).

There's also several `TODO:`s scattered around all source files mostly around technical problems that need some revisiting.

While Crystal brings its own hidden `::Thread` class, any reference to `Thread` in the source refers to `Run::Thread` which actually are no real threads (see [`Run::Thread`](https://github.com/phil294/AHK_X11/blob/master/src/run/thread.cr) docs).
