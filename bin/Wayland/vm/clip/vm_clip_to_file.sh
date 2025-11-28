#!/bin/sh
set -eu

FILE="/home/dd/HOST/files/clip/v2h.txt"
DIR="$(dirname "$FILE")"
mkdir -p "$DIR"
: >"$FILE" 2>/dev/null || true

# Wayland
: "${XDG_RUNTIME_DIR:="/run/user/$(id -u)"}"
find_wl() {
  for s in "$XDG_RUNTIME_DIR"/wayland-*; do [ -S "$s" ] && {
    export WAYLAND_DISPLAY="${s##*/}"
    return 0
  }; done
  return 1
}
until find_wl; do sleep 0.25; done

# Zapisuj snap przy KAŻDEJ zmianie clipboardu (atomowo)
exec wl-paste --type text --watch sh -c '
  set -eu
  f="$1"
  t="${f}.tmp"
  cat > "$t" && mv -f "$t" "$f"
' sh "$FILE"
