#!/bin/bash
set -e

cd "$(dirname "$0")"

version=$(shards version)

cd ..
# Cannot overwrite CRYSTAL_LIBRARY_PATH because crystal#12380, need link-flag instead.
# -no-pie prevents
shards build -Dpreview_mt --link-flags="-L$PWD/build" \
  "$@"
# Flags lik -Dgc_none or --release or --debug should be passed from outside

cd build

rm -rf AppDir
# export DEPLOY_GTK_VERSION=3 # is autodetected
export LD_LIBRARY_PATH="$PWD"
export BINCACHE_BIN_TARGET_FOLDER='$HOME/.cache/ahk_x11/AppImage'
# libthai: https://github.com/phil294/AHK_X11/issues/45 https://github.com/AppImageCommunity/pkg2appimage/issues/538
./linuxdeploy-x86_64.AppImage --appdir AppDir --output appimage --desktop-file ../assets/ahk_x11.desktop --icon-file ../assets/ahk_x11.png --executable ../bin/ahk_x11 --library ./libxdo.so.3 --library /lib/x86_64-linux-gnu/libthai.so.0.3.1 --plugin gtk
rm -rf AppDir

bin_name=ahk_x11-"$version"-x86_64.AppImage
mv ahk_x11-x86_64.AppImage "$bin_name"

echo "success!"