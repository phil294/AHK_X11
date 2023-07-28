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
# Other libraries that are missing on docker debian and frolvlad/alpine-glibc but are on excludelist
# https://github.com/AppImageCommunity/pkg2appimage/blob/master/excludelist)
# ...but that haven't caused problems so far: libfontconfig.so.1, libfribidi.so.0, libharfbuzz.so.0, libgpg-error.so.0(only alpine)
./linuxdeploy-x86_64.AppImage --appdir AppDir --output appimage --desktop-file ../assets/ahk_x11.desktop --icon-file ../assets/ahk_x11.png --executable ../bin/ahk_x11 --library ./libxdo.so.3 --library /lib/x86_64-linux-gnu/libthai.so.0 --plugin gtk
rm -rf AppDir

bin_name=ahk_x11-"$version"-x86_64.AppImage
mv ahk_x11-x86_64.AppImage "$bin_name"

echo "success!"