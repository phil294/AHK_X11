#!/bin/bash
set -e

cd "$(dirname "$0")"

version=$(cat ../shard.yml |head -2 |tail -1 |cut -c10-)

: ''
cd ..
# Cannot overwrite CRYSTAL_LIBRARY_PATH because crystal#12380, need link-flag instead.
shards build \
  -Dpreview_mt \
  --link-flags="-L$PWD/build $PWD/build/libxkbcustom.a $PWD/build/libxkbcommon.so.1.0.0 -lxkbcustom -lxkbcommon -lwayland-client" \
  # -Dgc_none \
  # --release \
  # --debug
cd build
# '


rm -rf AppDir
# export DEPLOY_GTK_VERSION=3 # is autodetected
export LD_LIBRARY_PATH="$PWD"
export BINCACHE_BIN_TARGET_FOLDER='$HOME/.cache/ahk_x11/AppImage'
TODO: libthai below, works? https://github.com/phil294/AHK_X11/issues/45
./linuxdeploy-x86_64.AppImage --appdir AppDir --output appimage --desktop-file ../assets/ahk_x11.desktop --icon-file ../assets/ahk_x11.png --executable ../bin/ahk_x11 --library ./libxdo.so.3 --library ./libxkbcommon.so.1 --library libthai.so --plugin gtk
rm -rf AppDir

bin_name=ahk_x11-"$version"-x86_64.AppImage
mv ahk_x11-x86_64.AppImage "$bin_name"

# Attaching the installer:
# The installer is not shipped separately and instead bundled with the binary by doing this.
# Bundling is the same thing as compiling a script as a user.
# It is possible to repeatedly compile a binary, with each script being appended at the end each time.
# Only the last one actually executed - and only if no params are passed to the program.
# There's no point in compiling multiple times, but it allows us to ship a default script (the installer)
# for when no arguments are passed.
# In other words, this is possible for a user:
#     ahk_x11 --compile script1.ahk && ./script1 --compile script2.ahk && ./script2
# but no one will ever do that.
cp "$bin_name" "$bin_name".pre_installer
./"$bin_name" --compile ../src/installer.ahk tmp && mv tmp "$bin_name"

echo "success! Bin is ./$bin_name"