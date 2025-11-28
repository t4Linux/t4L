#!/usr/bin/env bash

# Terminate already running bar instances
# If all your bars have ipc enabled, you can use
# polybar-msg cmd quit
# Otherwise you can use the nuclear option:
killall -q polybar

echo "---" | tee -a /tmp/polybar1.log /tmp/polybar3.log
# polybar mainbar-left -c ~/.config/herbstluftwm /polybar/t4Linux.ini 2>&1 | tee -a /tmp/polybar1.log &
polybar workspaces -c ~/.config/herbstluftwm/polybar/t4Linux.ini 2>&1 &
polybar date -c ~/.config/herbstluftwm/polybar/t4Linux.ini 2>&1 &
polybar mainbar-right -c ~/.config/herbstluftwm/polybar/t4Linux.ini 2>&1 &
polybar tray -c ~/.config/herbstluftwm/polybar/t4Linux.ini 2>&1 &
polybar volume -c ~/.config/herbstluftwm/polybar/t4Linux.ini 2>&1 &
polybar battery -c ~/.config/herbstluftwm/polybar/t4Linux.ini 2>&1 &
# disown
# polybar bar2 2>&1 | tee -a /tmp/polybar2.log &
# disown
if [[ $(xrandr -q | grep 'HDMI-1 connected') ]]; then
  polybar workspaces3 -c ~/.config/herbstluftwm/polybar/t4Linux.ini 2>&1 &
  polybar date-DP-2 -c ~/.config/herbstluftwm/polybar/t4Linux.ini 2>&1 &
  polybar mainbar-right2 -c ~/.config/herbstluftwm/polybar/t4Linux.ini 2>&1 &
fi
echo "Bars launched..."
