#!/usr/bin/env bash
# List available updates: Arch repo + AUR + Flatpak
# Based on t4L-updates-checker.sh logic but for human reading

set -u

# Kolory dla czytelności
BOLD="\033[1m"
GREEN="\033[32m"
BLUE="\033[34m"
CYAN="\033[36m"
RED="\033[31m"
RESET="\033[0m"

exists(){ command -v "$1" >/dev/null 2>&1; }

# Wykrywanie narzędzi
CHECKUPDATES=$(command -v checkupdates || true)
PACMAN=$(command -v pacman || true)
FLATPAK=$(command -v flatpak || true)
DNF=$(command -v dnf || true)

detect_aur(){
  for h in yay paru pikaur trizen aura; do
    if exists "$h"; then echo "$h"; return; fi
  done
  echo ""
}

wait_locks(){
  local p="/var/lib/pacman/db.lck" c="${TMPDIR:-/tmp}/checkup-db-${UID}/db.lck" i=0
  if [ -f "$p" ] || [ -f "$c" ]; then
    echo -e "${RED}Oczekiwanie na zwolnienie blokady bazy danych pacman...${RESET}" >&2
  fi
  while [ -f "$p" ] || [ -f "$c" ]; do
    sleep 1
    i=$((i+1))
    [ $i -gt 60 ] && break
  done
}

print_header(){
  echo -e "\n${BOLD}${BLUE}=== $1 ===${RESET}"
}

format_output() {
    # Funkcja AWK do formatowania tabelarycznego z wyrównaniem strzałek -> i zamknięciem tabeli |
    awk '
    BEGIN { max_name = 0; max_old = 0; max_new = 0; }
    {
        line = $0
        # Usuwanie kodów ANSI
        gsub(/\x1b\[[0-9;]*m/, "", line)

        name = $1
        idx = index(line, "->")
        
        if (idx > 0) {
            has_arrow[NR] = 1
            
            before = substr(line, 1, idx - 1)
            after = substr(line, idx + 2)
            
            old_v = substr(before, length(name) + 1)
            gsub(/^[ \t]+|[ \t]+$/, "", old_v)
            gsub(/^[ \t]+|[ \t]+$/, "", after)
            
            old_ver[NR] = old_v
            new_ver[NR] = after
            
            if (length(old_v) > max_old) max_old = length(old_v)
            if (length(after) > max_new) max_new = length(after)
        } else {
            has_arrow[NR] = 0
            rest = substr(line, length(name) + 1)
            gsub(/^[ \t]+|[ \t]+$/, "", rest)
            info[NR] = rest
            # Zbieramy długość, żeby ewentualnie dostosować tabelę
            if (length(rest) > max_info) max_info = length(rest)
        }
        
        names[NR] = name
        if (length(name) > max_name) max_name = length(name)
    }
    END {
        if (max_name < 20) max_name = 20
        if (max_old < 10) max_old = 10
        if (max_new < 8)  max_new = 8

        # Szerokość prawej sekcji (Stara -> Nowa)
        right_width = max_old + 4 + max_new
        
        # Jeśli jakiś wpis bez strzałki jest szerszy, dostosujmy szerokość
        if (max_info > right_width) right_width = max_info

        # Ponowne obliczenie max_new na wypadek gdyby right_width wzrosło
        # (żeby kreska końcowa była równo, musimy rozciągnąć ostatnią kolumnę)
        final_new_width = right_width - max_old - 4
        
        for (i = 1; i <= NR; i++) {
            if (has_arrow[i]) {
                # Format: Spacja + Nazwa | Stara -> Nowa |
                printf " %-" max_name "s | %-" max_old "s -> %-" final_new_width "s |\n", names[i], old_ver[i], new_ver[i]
            } else {
                # Format: Spacja + Nazwa | Info          |
                printf " %-" max_name "s | %-" right_width "s |\n", names[i], info[i]
            }
        }
    }
    '
}

list_repo(){
  print_header "PACMAN (Official Repo)"
  if [ -n "$CHECKUPDATES" ]; then
    wait_locks
    # checkupdates zwraca: "pakiet stara -> nowa"
    out=$($CHECKUPDATES 2>/dev/null)
    if [ -n "$out" ]; then
        echo "$out" | format_output
    else
        echo "System jest aktualny."
    fi
  elif [ -n "$PACMAN" ]; then
    wait_locks
    # W ostateczności pacman -Qu
    out=$($PACMAN -Qu 2>/dev/null)
    if [ -n "$out" ]; then
       echo "$out" | format_output
    else
       echo "Brak aktualizacji lub wymagane odświeżenie bazy."
    fi
  elif [ -n "$DNF" ]; then
    $DNF check-update -q 2>/dev/null | awk '{print $1, $2}' | format_output || echo "System jest aktualny."
  else
    echo "Nie znaleziono menedżera pakietów."
  fi
}

list_aur(){
  local helper="$1"
  print_header "AUR (Arch User Repository)"
  
  if [ -z "$helper" ]; then
    echo "Nie wykryto helpera AUR (yay, paru, itp.)."
    return
  fi

  case "$helper" in
    yay|paru|pikaur|trizen) 
      out=$("$helper" -Qua 2>/dev/null)
      if [ -n "$out" ]; then
          echo "$out" | format_output
      else
          echo "Wszystkie pakiety AUR są aktualne."
      fi
      ;;
    aura) 
      out=$(aura -Auax 2>/dev/null)
      if [ -n "$out" ]; then
          echo "$out" | format_output
      else
          echo "Wszystkie pakiety AUR są aktualne."
      fi
      ;;
    *) 
      echo "Nieobsługiwany helper: $helper" 
      ;;
  esac
}

list_flatpak(){
  print_header "FLATPAK"
  if [ -n "$FLATPAK" ]; then
    # --columns=name,version daje "Nazwa Wersja"
    out=$($FLATPAK remote-ls --updates --app --columns=name,version 2>/dev/null)
    if [ -n "$out" ]; then
        echo "$out" | format_output
    else
        echo "Brak aktualizacji Flatpak."
    fi
  else
    echo "Flatpak nie jest zainstalowany."
  fi
}

# --- Main Execution ---

echo -e "${BOLD}Sprawdzanie dostępnych aktualizacji...${RESET}"

# 1. Repo
list_repo

# 2. AUR
helper=$(detect_aur)
list_aur "$helper"

# 3. Flatpak
list_flatpak

echo -e "\n${BOLD}${GREEN}Zakończono.${RESET}"
read -p "Naciśnij Enter, aby zamknąć okno..."
