#!/bin/sh
set -eu

FILE="/home/dd/HOST/clip/v2h.txt"
DIR="$(dirname "$FILE")"
/usr/bin/mkdir -p "$DIR"
/usr/bin/touch "$FILE"

: "${XDG_RUNTIME_DIR:="/run/user/$(id -u)"}"
while :; do
  for s in "$XDG_RUNTIME_DIR"/wayland-*; do [ -S "$s" ] && {
    export WAYLAND_DISPLAY="${s##*/}"
    break 2
  }; done
  sleep 0.25
done

exec /usr/bin/wl-paste --type text --watch sh -c '
  set -eu
  f="$1"; t="${f}.tmp"
  cat > "$t" && mv -f "$t" "$f"
' sh "$FILE"
