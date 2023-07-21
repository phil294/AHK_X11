FROM alpine:latest as build-xdotool
RUN apk add --no-cache alpine-sdk libxtst-dev libxinerama-dev libxkbcommon-dev libx11-dev
RUN git clone --depth=1 https://github.com/jordansissel/xdotool /xdo
WORKDIR /xdo
RUN make WITHOUT_RPATH_FIX=1 libxdo.a

FROM crystallang/crystal:latest-alpine AS build-ahkx11
RUN apk add --no-cache gtk+3.0-dev gobject-introspection-dev libxtst-dev libnotify-dev
RUN git clone --depth=1 https://github.com/phil294/ahk_x11 /ahk
WORKDIR /ahk
RUN shards install
RUN bin/gi-crystal
RUN sed -i -E 's/private getter xdo_p/getter xdo_p/' lib/x_do/src/x_do.cr
RUN sed -i -E 's/GLib::String/::String/g' lib/gi-crystal/src/auto/gtk-3.0/gtk.cr
RUN mkdir static
COPY --from=build-xdotool /xdo/libxdo.a static
RUN shards build -Dpreview_mt --link-flags="-L$PWD/static -lxdo -lxkbcommon -lXinerama -lXtst -lXi -lX11" --release

FROM alpine:latest
RUN apk add --no-cache libx11 libnotify gtk+3.0 libgcc
COPY --from=build-ahkx11 /ahk/bin/ahk_x11 .
CMD ["./ahk_x11"]