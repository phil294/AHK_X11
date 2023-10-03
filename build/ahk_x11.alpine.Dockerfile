FROM crystallang/crystal:latest-alpine AS build-ahkx11
RUN apk add --no-cache gtk+3.0-dev gobject-introspection-dev libxtst-dev libnotify-dev alpine-sdk libxinerama-dev libxkbcommon-dev libx11-dev
RUN git clone --depth=1 https://github.com/phil294/ahk_x11 /ahk
WORKDIR /ahk
RUN make bin/ahk_x11

FROM alpine:latest
RUN apk add --no-cache libx11 libnotify gtk+3.0 libgcc
COPY --from=build-ahkx11 /ahk/bin/ahk_x11 .
CMD ["./ahk_x11"]