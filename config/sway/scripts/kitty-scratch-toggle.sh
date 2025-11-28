#!/usr/bin/env bash
set -euo pipefail

# ID scratchpada (app_id kitty na Waylandzie to "--class")
ID="${1:-kitty-scratch}"
W="${2:-1200}" # <- szerokość px
H="${3:-700}"  # <- wysokość px
CMD=(kitty --class "$ID")

exists() { swaymsg -t get_tree | jq -e 'recurse(.nodes[]?, .floating_nodes[]?)|select(.app_id=="'"$ID"'")' >/dev/null; }
visible() { swaymsg -t get_tree | jq -e 'recurse(.nodes[]?, .floating_nodes[]?)|select(.app_id=="'"$ID"'")|.visible==true' >/dev/null; }

if visible; then
  swaymsg '[app_id="'"$ID"'"] move to scratchpad'
elif exists; then
  swaymsg '[app_id="'"$ID"'"] scratchpad show, resize set '"$W $H"', move position center, focus'
else
  "${CMD[@]}" &
  for _ in {1..50}; do
    sleep 0.06
    exists && break
  done
  swaymsg '[app_id="'"$ID"'"] scratchpad show, resize set '"$W $H"', move position center, focus'
fi
