#!/usr/bin/env bash
set -euo pipefail

### ── Colors (Osaka-Jade vibe) ────────────────────────────────────────────────
# Try truecolor -> 256color -> no color
supports_truecolor=0
if [ "${COLORTERM:-}" = "truecolor" ] || [ "${COLORTERM:-}" = "24bit" ]; then
  supports_truecolor=1
fi

if [ -n "${NO_COLOR:-}" ]; then supports_truecolor=0; fi

if command -v tput >/dev/null 2>&1 && [ -t 1 ]; then
  bold="$(tput bold)"; dim="$(tput dim)"; reset="$(tput sgr0)"
else
  bold=""; dim=""; reset=""
fi

if [ $supports_truecolor -eq 1 ]; then
  # Jade-ish accents (hex-ish): primary #00A36C, secondary #2BD4A7
  JADE='\033[38;2;0;163;108m'
  JADE2='\033[38;2;43;212;167m'
  OK='\033[38;2;0;200;120m'
  WARN='\033[38;2;255;200;0m'
  ERR='\033[38;2;255;90;90m'
  FG='\033[38;2;220;220;220m'
  MUTED='\033[38;2;150;160;165m'
else
  # 256/8-bit fallback: choose close cousins
  JADE="$(tput setaf 36 2>/dev/null || printf '')"     # cyan-ish green
  JADE2="$(tput setaf 49 2>/dev/null || printf '')"    # aqua
  OK="$(tput setaf 2 2>/dev/null || printf '')"        # green
  WARN="$(tput setaf 3 2>/dev/null || printf '')"      # yellow
  ERR="$(tput setaf 1 2>/dev/null || printf '')"       # red
  FG="$(tput setaf 7 2>/dev/null || printf '')"        # white/gray
  MUTED="$(tput setaf 8 2>/dev/null || printf '')"     # dim
fi

hr() { printf "${MUTED}──────────────────────────────────────────────────────────────${reset}\n"; }
title() {
  printf "\n${JADE}${bold}=== %s ===${reset}\n" "$1"
}
stamp() { date +'%H:%M:%S'; }

log_info() { printf "%b[%s] %b%s%b\n" "$MUTED" "$(stamp)" "$FG" "$*" "$reset"; }
log_step() { printf "%b[%s] %b %s%b\n" "$MUTED" "$(stamp)" "$JADE2" "$*" "$reset"; }
log_ok()   { printf "%b[%s] %b %s%b\n" "$MUTED" "$(stamp)" "$OK" "$*" "$reset"; }
log_warn() { printf "%b[%s] %b %s%b\n" "$MUTED" "$(stamp)" "$WARN" "$*" "$reset"; }
log_err()  { printf "%b[%s] %b %s%b\n" "$MUTED" "$(stamp)" "$ERR" "$*" "$reset"; }

cleanup_colors() { printf "%b" "$reset"; }
trap cleanup_colors EXIT

### ── Banner ──────────────────────────────────────────────────────────────────
hr
title "System updater (Hyprland · Osaka-Jade)"
hr
command -v notify-send >/dev/null 2>&1 && notify-send "Updater" "Startuję aktualizacje…"

### ── Detect helpers ──────────────────────────────────────────────────────────
aur_helper=""
for h in yay paru pikaur trizen aura; do
  if command -v "$h" >/dev/null 2>&1; then aur_helper="$h"; break; fi
done
have_flatpak=0
command -v flatpak >/dev/null 2>&1 && have_flatpak=1

### ── Updates ─────────────────────────────────────────────────────────────────
if command -v pacman >/dev/null 2>&1; then
  log_step "[1] Pacman/AUR"
  if [[ -n "$aur_helper" ]]; then
    log_info "Helper: ${aur_helper} (with --sudoloop)"
    if ! "$aur_helper" -Syu --sudoloop; then
      log_warn "AUR run reported issues — kontynuuję…"
    fi
  else
    log_info "Brak AUR helpera → pacman -Syu"
    if ! sudo pacman -Syu; then
      log_warn "Pacman run reported issues — kontynuuję…"
    fi
  fi
fi

if command -v dnf >/dev/null 2>&1; then
  log_step "[1] DNF (Fedora)"
  if ! sudo dnf upgrade -y; then
    log_warn "DNF run reported issues — kontynuuję…"
  fi
fi

if [[ $have_flatpak -eq 1 ]]; then
  log_step "[2] Flatpak"
  if ! flatpak update -y; then
    log_warn "Flatpak update reported issues — kontynuuję…"
  fi
else
  log_info "Flatpak: nie znaleziono (pomijam)"
fi

### ── Done ────────────────────────────────────────────────────────────────────
hr
log_ok "✅ All done."
printf "%b%s%b\n" "$MUTED" "Press any key to close…" "$reset"
command -v notify-send >/dev/null 2>&1 && notify-send "Updater" "Gotowe ✅"
# wait for a keypress; fall back to enter
read -n1 -s -r _ || read -r _

