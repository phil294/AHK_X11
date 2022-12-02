#!/bin/bash
set -e
set -o pipefail

# this stuff is mostly necessary so the different dependencies get along fine (x11 and gobject bindings). As a bonus, the `build_namespace` invocations cache the GIR (`require_gobject` calls) and thus reduce the overall compile time from ~6 to ~3 seconds.

# populate cache
echo "building Gtk 3.0 namespace..." >&2
crystal run lib/gobject/src/generator/build_namespace.cr -- Gtk 3.0 > lib/gobject/src/gtk/gobject-cache-gtk.cr
echo "building xlib 2.0 namespace..." >&2
crystal run lib/gobject/src/generator/build_namespace.cr -- xlib 2.0 > lib/gobject/src/gtk/gobject-cache-xlib--modified.cr
for lib in "GObject 2.0" "GLib 2.0" "Gio 2.0" "GModule 2.0" "Atk 1.0" "freetype2" "HarfBuzz 0.0" "GdkPixbuf 2.0" "cairo 1.0" "Pango 1.0" "Gdk 3.0" "DBus 1.0" "Atspi 2.0" "GdkX11 3.0"; do
    echo "### $lib" >> lib/gobject/src/gtk/gobject-cache-gtk-other-deps.cr
    echo "building $lib namespace..." >&2
    crystal run lib/gobject/src/generator/build_namespace.cr -- $lib >> lib/gobject/src/gtk/gobject-cache-gtk-other-deps.cr
done
echo "fix some dependency code..." >&2
# update lib to use cache
sed -i -E 's/^(require_gobject)/# \1/g' lib/gobject/src/gtk/gobject-cache-gtk.cr lib/gobject/src/gtk/gobject-cache-gtk-other-deps.cr
sed -i -E 's/^require_gobject "Gtk", "3.0"$/require ".\/gobject-cache-gtk"/' lib/gobject/src/gtk/gtk.cr
echo 'require "./gobject-cache-xlib--modified"' > tmp.txt; echo 'require "./gobject-cache-gtk-other-deps"' >> tmp.txt; cat lib/gobject/src/gtk/gobject-cache-gtk.cr >> tmp.txt; mv tmp.txt lib/gobject/src/gtk/gobject-cache-gtk.cr
echo 'macro require_gobject(namespace, version = nil) end' >> lib/gobject/src/gobject.cr
# delete conflicting c function binding by modifying the cache
sed -i -E 's/  fun open_display = XOpenDisplay : Void$//' lib/gobject/src/gtk/gobject-cache-xlib--modified.cr
# https://github.com/jhass/crystal-gobject/issues/103
sed -i -E 's/(def self.new_from_stream.+: self)$/\1?/g' lib/gobject/src/gtk/gobject-cache-gtk-other-deps.cr