#!/bin/sh
set -eu

FILE="/home/donald/HOST/files/clip/v2h.txt"
DIR="/home/donald/HOST/files/clip"
/usr/bin/mkdir -p "$DIR"
/usr/bin/touch "$FILE"

export DISPLAY=":0"
export XAUTHORITY="/home/donald/.Xauthority"

last=""
while sleep 0.3; do
  cur="$(/usr/bin/stat -c '%Y:%s' "$FILE" 2>/dev/null || echo '0:0')"
  [ "$cur" = "$last" ] && continue
  last="$cur"
  [ -s "$FILE" ] && /usr/bin/xclip -i -selection clipboard -target UTF8_STRING <"$FILE" || true
done
