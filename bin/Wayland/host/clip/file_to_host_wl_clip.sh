#!/bin/sh
set -eu

FILE="/home/donald/HOST/clip/v2h.txt"
DIR="$(dirname "$FILE")"
/usr/bin/mkdir -p "$DIR"
/usr/bin/touch "$FILE"

# Czekaj na Waylanda i ustaw WAYLAND_DISPLAY
: "${XDG_RUNTIME_DIR:="/run/user/$(id -u)"}"
while :; do
  for s in "$XDG_RUNTIME_DIR"/wayland-*; do [ -S "$s" ] && {
    export WAYLAND_DISPLAY="${s##*/}"
    break 2
  }; done
  sleep 0.25
done

last=""
while sleep 0.3; do
  cur="$(/usr/bin/stat -c '%Y:%s' "$FILE" 2>/dev/null || echo '0:0')"
  [ "$cur" = "$last" ] && continue
  last="$cur"
  [ -s "$FILE" ] && /usr/bin/wl-copy --type text <"$FILE" || true
done
