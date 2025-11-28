#!/bin/sh
set -eu

BASE="/home/dd/HOST/clip"
TXT="$BASE/h2v.txt"
BIN="$BASE/h2v.bin"
MIME="$BASE/h2v.mime"

/usr/bin/mkdir -p "$BASE"
/usr/bin/touch "$TXT" "$BIN" "$MIME"

: "${XDG_RUNTIME_DIR:="/run/user/$(id -u)"}"
while :; do
  for s in "$XDG_RUNTIME_DIR"/wayland-*; do
    [ -S "$s" ] || continue
    export WAYLAND_DISPLAY="${s##*/}"
    break 2
  done
  sleep 0.25
done

last=""
while sleep 0.3; do
  cur="$(/usr/bin/stat -c '%Y:%s' "$MIME" 2>/dev/null || echo 0:0)-$(/usr/bin/stat -c '%Y:%s' "$TXT" 2>/dev/null || echo 0:0)-$(/usr/bin/stat -c '%Y:%s' "$BIN" 2>/dev/null || echo 0:0)"
  [ "$cur" = "$last" ] && continue
  last="$cur"

  mime="$(/usr/bin/cat "$MIME" 2>/dev/null || true)"
  case "$mime" in
    image/*)
      [ -s "$BIN" ] && /usr/bin/wl-copy --type "$mime" < "$BIN" || true
      ;;
    *)
      [ -s "$TXT" ] && /usr/bin/wl-copy --type text < "$TXT" || true
      ;;
  esac
done

