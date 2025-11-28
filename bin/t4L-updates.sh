#!/usr/bin/env bash
# Robust Waybar updates counter: Arch repo + AUR + Flatpak
# Always prints JSON, even on errors.

set -u  # nie używamy -e, żeby pojedyncza porażka nie zabiła skryptu

dbg(){ [ "${DEBUG:-0}" = "1" ] && printf '[updates][dbg] %s\n' "$*" >&2; }
exists(){ command -v "$1" >/dev/null 2>&1; }

# thresholds (kolory)
TH_YELLOW=${TH_YELLOW:-25}
TH_RED=${TH_RED:-100}

# absolutne ścieżki (Waybar czasem ma okrojony PATH)
PACMAN=$(command -v pacman || true)
CHECKUPDATES=$(command -v checkupdates || true)
DNF=$(command -v dnf || true)
FLATPAK=$(command -v flatpak || true)

detect_aur(){
  for h in yay paru pikaur trizen aura; do
    if exists "$h"; then echo "$h"; return; fi
  done
  echo ""
}

wait_locks(){
  local p="/var/lib/pacman/db.lck" c="${TMPDIR:-/tmp}/checkup-db-${UID}/db.lck" i=0
  while [ -f "$p" ] || [ -f "$c" ]; do sleep 1; i=$((i+1)); [ $i -gt 60 ] && break; done
}

count_repo(){
  local n=0
  if [ -n "$CHECKUPDATES" ]; then
    wait_locks
    # checkupdates potrafi zwrócić kod 2 -> nie zabijaj skryptu
    n=$($CHECKUPDATES 2>/dev/null | wc -l | tr -d ' ' || echo 0)
  elif [ -n "$PACMAN" ]; then
    wait_locks
    # fallback: policz paczki do pobrania
    n=$($PACMAN -Sup --needed 2>/dev/null | grep -E '^https?://' | wc -l | tr -d ' ' || echo 0)
  else
    n=0
  fi
  echo "${n:-0}"
}

count_aur(){
  local helper="$1" n=0
  case "$helper" in
    yay|paru|pikaur|trizen) n=$("$helper" -Qua 2>/dev/null | wc -l | tr -d ' ' || echo 0) ;;
    aura)                   n=$(aura -Auax 2>/dev/null | wc -l | tr -d ' ' || echo 0) ;;
    *)                      n=0 ;;
  esac
  echo "${n:-0}"
}

count_flatpak(){
  local n=0
  if [ -n "$FLATPAK" ]; then
    # niektóre wersje zwracają !=0 przy braku aktualizacji; ignorujemy exit code
    n=$($FLATPAK remote-ls --updates 2>/dev/null | wc -l | tr -d ' ' || echo 0)
  else
    n=0
  fi
  echo "${n:-0}"
}

# --- main ---
repo=0; aur=0; fp=0

if [ -n "$PACMAN" ]; then
  repo=$(count_repo); dbg "repo=$repo"
  helper=$(detect_aur); dbg "aur_helper=${helper:-none}"
  aur=$(count_aur "$helper"); dbg "aur=$aur"
elif [ -n "$DNF" ]; then
  # fallback Fedora
  repo=$($DNF check-update -q 2>/dev/null | grep -c '^[a-z0-9]' || echo 0)
fi

fp=$(count_flatpak); dbg "flatpak=$fp"

total=$(( repo + aur + fp ))

class="green"
[ "$total" -gt "$TH_YELLOW" ] && class="yellow"
[ "$total" -gt "$TH_RED" ] && class="red"

icon=""
short="R:${repo} A:${aur} F:${fp}"
tooltip="Repo: ${repo}\nAUR: ${aur}\nFlatpak: ${fp}"

# ZAWSZE drukujemy JSON
printf '{"text":"%s  %s","alt":"%s","tooltip":"%s","class":"%s"}' \
  "$icon" "$total" "$short" "$tooltip" "$class"
printf '\n'
