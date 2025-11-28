#!/bin/sh
set -eu

FILE="/home/donald/Work/JDG/PLK/files/clip/v2h.txt"
DIR="/home/donald/Work/JDG/PLK/files/clip"
/usr/bin/mkdir -p "$DIR"
/usr/bin/touch "$FILE"

# --- Wayland: czekaj na socket i ustaw WAYLAND_DISPLAY
: "${XDG_RUNTIME_DIR:="/run/user/$(id -u)"}"
while :; do
  for s in "$XDG_RUNTIME_DIR"/wayland-*; do
    [ -S "$s" ] || continue
    export WAYLAND_DISPLAY="${s##*/}"
    break 2
  done
  sleep 0.25
done

# --- Debounce lokalnych kopii: znacznik + watcher
MARK="$XDG_RUNTIME_DIR/.vmclip_local.ts"
SUPPRESS_SEC="${SUPPRESS_SEC:-5}" # możesz zwiększyć, np. 8–10
: >"$MARK"
/usr/bin/wl-paste --watch "date +%s > $MARK" &
markpid=$!
trap 'kill $markpid 2>/dev/null || true' EXIT

last_sig=""
last_hash=""

while sleep 0.3; do
  # wykryj zmianę pliku (mtime:rozmiar)
  sig="$(/usr/bin/stat -c '%Y:%s' "$FILE" 2>/dev/null || echo 0:0)"
  [ "$sig" = "$last_sig" ] && continue
  last_sig="$sig"

  # nie ładuj pustego
  [ -s "$FILE" ] || continue

  # jeśli przed chwilą (SUPPRESS_SEC) było lokalne Ctrl+C — nie nadpisuj
  now="$(/usr/bin/date +%s)"
  loc="$(cat "$MARK" 2>/dev/null || echo 0)"
  [ $((now - loc)) -lt $SUPPRESS_SEC ] && continue

  # hash pliku vs. hash aktualnego schowka
  file_hash="$(/usr/bin/sha256sum "$FILE" | awk '{print $1}')"
  [ "$file_hash" = "$last_hash" ] && continue

  curr="$(/usr/bin/wl-paste --type text 2>/dev/null || true)"
  clip_hash="$(printf '%s' "$curr" | /usr/bin/sha256sum | awk '{print $1}')"
  [ "$file_hash" = "$clip_hash" ] && {
    last_hash="$file_hash"
    continue
  }

  # wstrzyknięcie do CLIPBOARD
  /usr/bin/wl-copy <"$FILE" && last_hash="$file_hash" || true
done
