#!/usr/bin/env bash
set -euo pipefail

# prefer kitty; fallback alacritty/foot
if command -v kitty >/dev/null 2>&1; then
  exec kitty --class updates-popup -T "System Updates" \
    bash -lc "$HOME/.config/waybar/scripts/t4L-updates-installer.sh"
elif command -v alacritty >/dev/null 2>&1; then
  exec alacritty --class updates-popup -t "System Updates" \
    -e bash -lc "$HOME/.config/waybar/scripts/t4L-updates-installer.sh"
elif command -v foot >/dev/null 2>&1; then
  exec foot --app-id updates-popup --title "System Updates" \
    bash -lc "$HOME/.config/waybar/scripts/t4L-updates-installer.sh"
else
  notify-send "Updater" "Brak terminala (kitty/alacritty/foot)"
  exit 1
fi

