#!/bin/sh
set -eu

FILE="/home/donald/HOST/clip/h2v.txt"
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

# Zapisuj snapshot przy KAŻDEJ zmianie schowka (atomowo)
exec /usr/bin/wl-paste --type text --watch sh -c '
  set -eu
  f="$1"; t="${f}.tmp"
  cat > "$t" && mv -f "$t" "$f"
' sh "$FILE"
