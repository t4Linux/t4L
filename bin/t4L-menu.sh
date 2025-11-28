#!/bin/bash
set -euo pipefail

# --- Minimal helpers ---

menu() {
  local prompt="$1"
  local options="$2"
  local extra="${3:-}"
  read -r -a args <<<"$extra"
  echo -e "$options" | omarchy-launch-walker --dmenu --width 295 --minheight 1 --maxheight 600 -p "$prompt…" "${args[@]}" 2>/dev/null
}

terminal() {
  # użyj Alacritty jeśli jest; w przeciwnym razie $TERMINAL lub xterm
  if command -v alacritty >/dev/null 2>&1; then
    alacritty --class=Omarchy -e "$@"
  elif [[ -n "${TERMINAL:-}" ]]; then
    "$TERMINAL" -e "$@"
  else
    xterm -e "$@"
  fi
}

present_terminal() {
  # jeśli masz omarchy-launch-floating-terminal-with-presentation, użyj go;
  # w przeciwnym razie fallback na zwykły terminal
  if command -v omarchy-launch-floating-terminal-with-presentation >/dev/null 2>&1; then
    omarchy-launch-floating-terminal-with-presentation "$1"
  else
    terminal bash -lc "$1"
  fi
}

# --- Only Install Menu ---

show_install_menu() {
  local choice
  choice=$(menu "Packages action" "󰣇  Package\n󰣇  AUR\n  Web App\n󰭌  Remove")
  case "$choice" in
    *Package*)
      if command -v omarchy-pkg-install >/dev/null 2>&1; then
        terminal omarchy-pkg-install
      else
        # prosty fallback na pacman
        present_terminal "echo 'Interactive pacman…'; read -rp 'Package name: ' pkg; sudo pacman -S --noconfirm \"\$pkg\""
      fi
      ;;
    *AUR*)
      if command -v omarchy-pkg-aur-install >/dev/null 2>&1; then
        terminal omarchy-pkg-aur-install
      else
        # fallback na yay
        present_terminal "echo 'Interactive AUR (yay)…'; read -rp 'AUR package name: ' pkg; yay -S --noconfirm \"\$pkg\""
      fi
      ;;
    *Web*)
      if command -v omarchy-webapp-install >/dev/null 2>&1; then
        terminal omarchy-webapp-install
      else
        # fallback na yay
        present_terminal "echo 'Interactive AUR (yay)…'; read -rp 'AUR package name: ' pkg; yay -S --noconfirm \"\$pkg\""
      fi
      ;;
    *Remove*) 
      if command -v omarchy-pkg-install >/dev/null 2>&1; then
        terminal omarchy-pkg-remove 
        exut 0
      else
        # fallback na yay
        present_terminal "echo 'Interactive AUR (yay)…'; read -rp 'AUR package name: ' pkg; yay -S --noconfirm \"\$pkg\""
      fi
      ;;
    *)
      exit 0
      ;;
  esac
}

# --- Entry point ---

# opcjonalnie pozwól wywołać bez menu: ./script package|aur
case "${1:-}" in
  package) shift; if command -v omarchy-pkg-install >/dev/null 2>&1; then terminal omarchy-pkg-install "$@"; else present_terminal "sudo pacman -S --noconfirm $*"; fi; exit 0 ;;
  aur)     shift; if command -v omarchy-pkg-aur-install >/dev/null 2>&1; then terminal omarchy-pkg-aur-install "$@"; else present_terminal "yay -S --noconfirm $*"; fi; exit 0 ;;
  web)     shift; if command -v omarchy-webapp-install >/dev/null 2>&1; then terminal omarchy-webapp-install "$@"; fi; exit 0 ;;
esac

# pętla aby po instalacji wracać do menu, ESC zamyka
while true; do
  show_install_menu || exit 0
done

