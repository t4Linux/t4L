#!/usr/bin/env bash

killall -q polybar

# Launch bar1 and bar2
echo "---" | tee -a /tmp/polybar1.log /tmp/polybar3.log
polybar workspaces -c ~/.config/herbstluftwm/polybar/t4Linux.ini 2>&1 &
polybar date -c ~/.config/herbstluftwm/polybar/t4Linux.ini 2>&1 &
polybar volume -c ~/.config/herbstluftwm/polybar/t4Linux.ini 2>&1 &
if [[ $(xrandr -q | grep 'DP-2 connected') || $(xrandr -q | grep 'DP-3 connected') ]]; then
  polybar tray-w -c ~/.config/herbstluftwm/polybar/t4Linux.ini 2>&1 &
  polybar workspaces-DP-2 -c ~/.config/herbstluftwm/polybar/t4Linux.ini 2>&1 &
  polybar date-DP-2 -c ~/.config/herbstluftwm/polybar/t4Linux.ini 2>&1 &
  polybar menu-w -c ~/.config/herbstluftwm/polybar/t4Linux.ini 2>&1 &
fi
echo "Bars launched..."
