#!/usr/bin/env bash
set -euo pipefail

# --- KONFIG --- (dostosuj do siebie)
MON1="DP-2" # np. zewnętrzny
MON3="eDP-1"    # np. laptop
MON2="DP-1"     # np. zewnętrzny

# Teams (flatpak) – oddzielne profile (polecane zamiast HOME=...)
TEAMS="com.github.IsmaelMartinez.teams_for_linux"
TEAMS_EXECON_CFG="$HOME/Work/teams/exe"
TEAMS_POLKO_CFG="$HOME/Work/teams/plk/"

# --- FUNKCJE POMOCNICZE ---
fm() { hyprctl dispatch focusmonitor "$1" >/dev/null 2>&1 || true; }
ws() { hyprctl dispatch workspace "$1" >/dev/null 2>&1 || true; }
run() { hyprctl dispatch exec "$*" >/dev/null 2>&1 || true; }

# --- START ---
# Monitor 1 → workspace 2_1
fm "$MON1"
ws "6"

# Dwie instancje Teams (osobne profile przez XDG_CONFIG_HOME):
run "env HOME=$TEAMS_EXECON_CFG flatpak run $TEAMS" &
sleep 2
run "env HOME=$TEAMS_POLKO_CFG flatpak run $TEAMS" &

sleep 5
ws "7"
run omarchy-launch-browser

sleep 5
ws "8"
run omarchy-launch-webapp "https://youtube.com"

# sleep 5
# ws "9"
# run omarchy-launch-webapp "https://chatgpt.com"

sleep 5
fm "$MON2"
ws "5"
run "virsh -c qemu:///system start manjaro_plk"
run "virt-viewer -c qemu:///system manjaro_plk"

# # Powrót na 1 (MON1), potem na 5 (MON0)
sleep 5
fm "$MON1"
ws "6"
fm $MON2
ws 5

exit 0
