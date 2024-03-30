.PHONY: all clean test-appimage test-dev install uninstall install install-bin install-assets install-appimage install-bin-appimage
PREFIX ?= /usr

all:
	echo Please specify target.

download-appimage:
	curl -s https://api.github.com/repos/phil294/ahk_x11/releases/latest \
		| grep "browser_download_url.*/ahk_x11-.\..\..-x86_64.AppImage" \
		| cut -d : -f 2,3 \
		| tr -d \" \
		| wget -i - -O ahk_x11.AppImage
	chmod +x ahk_x11.AppImage

ahk_x11.AppImage: bin/ahk_x11 linuxdeploy-plugin-gtk.sh linuxdeploy-x86_64.AppImage
	(cat /etc/lsb-release |grep "Ubuntu 20.04") || \
		(echo "It seems you're NOT on Ubuntu 20.04. AppImages should be built on that distribution for cross-distro compatibility. Please change your system e.g. by running all of this in a 20.04 Docker container. Alternatively, you can build for your local system only with the bin/ahk_x11 make target (not recommended)."; exit 1)
	rm -rf AppDir
# libthai: https://github.com/phil294/AHK_X11/issues/45 https://github.com/AppImageCommunity/pkg2appimage/issues/538
# Other libraries that are missing on docker debian and frolvlad/alpine-glibc but are on excludelist
# https://github.com/AppImageCommunity/pkg2appimage/blob/master/excludelist)
# ...but that haven't caused problems so far: libfontconfig.so.1, libfribidi.so.0, libharfbuzz.so.0, libgpg-error.so.0(only alpine)
	OUTPUT=ahk_x11.AppImage ./linuxdeploy-x86_64.AppImage --appdir AppDir --output appimage --desktop-file ./assets/ahk_x11.desktop --icon-file ./assets/ahk_x11.png --executable ./bin/ahk_x11 --library /usr/lib/x86_64-linux-gnu/libthai.so.0 --plugin gtk
	rm -rf AppDir

ahk_x11.deb: ahk_x11.AppImage
	fpm -s dir -t deb -n ahk_x11 -v "$$(shards version)" --architecture all --deb-no-default-config-files --iteration 1 --description "AHK_X11: AutoHotkey for Linux" --maintainer "Philip Waritschlager <philip+ahk_x11@waritschlager.de>" --url "https://github.com/phil294/ahk_x11" --license "GPL v2" --category "Development" --depends libfuse2 ahk_x11.AppImage=/usr/bin/ahk_x11

bin/ahk_x11:
ifneq ($(MAKECMDGOALS), ahk_x11.AppImage)
	@echo -e "WARNING: You are building the native release binary WITHOUT AppImage wrapper. The resulting program will work but not be very portable as dependencies are not bundled. This means that if you use AHK_X11's COMPILER FEATURE to bundle a script into a standalone binary, this binary will then VERY LIKELY NOT RUN ON OTHER LINUX SYSTEMS, or may fail to run on your system in the future. \n\nIt is highly recommended you make the "ahk_x11.AppImage" target instead. The file output size will be three times larger but eternally portable."
endif
	$(MAKE) bin/ahk_x11.dev BUILD_EXTRA_ARGS="--release"
	mv bin/ahk_x11.dev bin/ahk_x11

# Without the --release argument, this adds debug symbols and is slow at runtime
bin/ahk_x11.dev: lib/configured xdotool/libxdo.a
# We always link libxdo statically even when we're not using AppImage as we need
# the recent fixes from master branch, also its abi bump, we depend on v2021+.
# Xinerama etc. are its dependencies - these we keep dynamic.
# Cannot overwrite CRYSTAL_LIBRARY_PATH because crystal#12380, need link-flag instead.
	shards build -Dpreview_mt --link-flags="-no-pie \
        -L'${PWD}/xdotool' \
        -Wl,-Bstatic -lxdo \
        -Wl,-Bdynamic -lxkbcommon -lXinerama -lXext -lXtst -lXi" \
        $(BUILD_EXTRA_ARGS)
	mv bin/ahk_x11 bin/ahk_x11.dev

linuxdeploy-plugin-gtk.sh linuxdeploy-x86_64.AppImage:
	wget https://raw.githubusercontent.com/linuxdeploy/linuxdeploy-plugin-gtk/master/linuxdeploy-plugin-gtk.sh
# Custom themes are broken https://github.com/linuxdeploy/linuxdeploy-plugin-gtk/issues/39
	sed -i -E 's/export GTK_THEME=/# /' linuxdeploy-plugin-gtk.sh
	wget https://github.com/linuxdeploy/linuxdeploy/releases/latest/download/linuxdeploy-x86_64.AppImage
	chmod +x linuxdeploy-*

xdotool/.git:
	test -d .git && git submodule update --init || echo 'No .git folder present'

xdotool/libxdo.a: xdotool/.git
	$(MAKE) -C xdotool libxdo.a

lib/configured:
	shards install --frozen
	./bin/gi-crystal
# TODO: can be fixed in application code?
	sed -i -E 's/private getter xdo_p/getter xdo_p/' lib/x_do/src/x_do.cr
# https://github.com/hugopl/gi-crystal/issues/80
	sed -i -E 's/GLib::String/::String/g' lib/gi-crystal/src/auto/gtk-3.0/gtk.cr
	touch lib/configured

test-appimage: ahk_x11.AppImage
	./ahk_x11.AppImage tests.ahk
test-dev: bin/ahk_x11
	./bin/ahk_x11 tests.ahk

clean:
	rm -rf ahk_x11.AppImage bin/ahk_x11 bin/ahk_x11.dev linuxdeploy-plugin-gtk.sh linuxdeploy-x86_64.AppImage lib
	git submodule deinit --all

install: install-bin install-assets
install-appimage: install-bin-appimage install-assets
install-bin:
	install -D -m 0755 -t $(DESTDIR)$(PREFIX)/bin/ bin/ahk_x11
install-bin-appimage:
	install -D -m 0755 ahk_x11.AppImage $(DESTDIR)$(PREFIX)/bin/ahk_x11
install-assets:
	install -D -m 0644 assets/ahk_x11.png $(DESTDIR)$(PREFIX)/share/icons/hicolor/48x48/mimetypes/application-x-ahk_x11.png
	install -D -m 0644 -t $(DESTDIR)$(PREFIX)/share/mime/packages/ assets/ahk_x11-mime.xml
	install -D -m 0644 -t $(DESTDIR)$(PREFIX)/share/applications/ assets/ahk_x11.desktop
	install -D -m 0644 -t $(DESTDIR)$(PREFIX)/share/applications/ assets/ahk_x11-compiler.desktop
	install -D -m 0644 -t $(DESTDIR)$(PREFIX)/share/applications/ assets/ahk_x11-windowspy.desktop
# Setting a default ahk_x11.desktop for mime application/x-ahk_x11 seems to not really be possible by standard and it also would be too intrusive probably

uninstall:
	rm -f $(DESTDIR)$(PREFIX)/bin/ahk_x11*
	rm -f $(DESTDIR)$(PREFIX)/share/icons/hicolor/48x48/mimetypes/application-x-ahk_x11.png
	rm -f $(DESTDIR)$(PREFIX)/share/mime/packages/ahk_x11-mime.xml
	rm -f $(DESTDIR)$(PREFIX)/share/mime/application/x-ahk_x11.xml
	rm -f $(DESTDIR)$(PREFIX)/share/applications/ahk_x11.desktop
	rm -f $(DESTDIR)$(PREFIX)/share/applications/ahk_x11-compiler.desktop
	rm -f $(DESTDIR)$(PREFIX)/share/applications/ahk_x11-windowspy.desktop
