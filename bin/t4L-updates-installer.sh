#!/usr/bin/env bash
set -euo pipefail

echo -e "\n=== System updater (Hyprland) ===\n"
command -v notify-send >/dev/null 2>&1 && notify-send "Updater" "Startuję aktualizacje…"

aur_helper=""
for h in yay paru pikaur trizen aura; do
  if command -v "$h" >/dev/null 2>&1; then aur_helper="$h"; break; fi
done

have_flatpak=0
command -v flatpak >/dev/null 2>&1 && have_flatpak=1

if command -v pacman >/dev/null 2>&1; then
  echo "[1] pacman/AUR…"
  if [[ -n "$aur_helper" ]]; then
    "$aur_helper" -Syu --sudoloop || true
  else
    sudo pacman -Syu || true
  fi
fi

if command -v dnf >/dev/null 2>&1; then
  echo "[1] dnf…"
  sudo dnf upgrade -y || true
fi

if [[ $have_flatpak -eq 1 ]]; then
  echo "[2] Flatpak…"
  flatpak update -y || true
fi

echo -e "\n✅ All done. Press any key to close…"
command -v notify-send >/dev/null 2>&1 && notify-send "Updater" "Gotowe ✅"

# czekamy na klawisz i kończymy (okno zamknie się samo)
read -n1 -s -r _ || read -r _

