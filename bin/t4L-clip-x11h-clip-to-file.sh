#!/bin/sh
set -eu
FILE="/home/donald/HOST/files/clip/h2v.txt"
DIR="$(dirname "$FILE")"
mkdir -p "$DIR"
: >"$FILE" 2>/dev/null || true

save() {
  tmp="${FILE}.tmp"
  DISPLAY=:0 XAUTHORITY=/home/donald/.Xauthority \
    xclip -o -selection clipboard -target UTF8_STRING 2>/dev/null >"$tmp" || true
  mv -f "$tmp" "$FILE"
}

if command -v clipnotify >/dev/null 2>&1; then
  while clipnotify; do save; done
else
  last=""
  while sleep 0.3; do
    cur="$(DISPLAY=:0 XAUTHORITY=/home/donald/.Xauthority xclip -o -selection clipboard -target UTF8_STRING 2>/dev/null || true)"
    [ "$cur" = "$last" ] || {
      printf "%s" "$cur" >"$FILE.tmp"
      mv -f "$FILE.tmp" "$FILE"
      last="$cur"
    }
  done
fi
