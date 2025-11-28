#!/usr/bin/env bash

# Terminate already running bar instances
# If all your bars have ipc enabled, you can use
# polybar-msg cmd quit
# Otherwise you can use the nuclear option:
killall -q polybar

# Launch bar1 and bar2
echo "---" | tee -a /tmp/polybar1.log /tmp/polybar3.log
polybar workspaces -c $HOME/.config/herbstluftwm/polybar/t4Linux_one.ini 2>&1 &
polybar date -c $HOME/.config/herbstluftwm/polybar/t4Linux_one.ini 2>&1 &
polybar battery -c $HOME/.config/herbstluftwm/polybar/t4Linux_one.ini 2>&1 &
polybar tray -c $HOME/.config/herbstluftwm/polybar/t4Linux_one.ini 2>&1 &
polybar volume -c $HOME/.config/herbstluftwm/polybar/t4Linux_one.ini 2>&1 &
polybar cpu-ram -c $HOME/.config/herbstluftwm/polybar/t4Linux_one.ini 2>&1 &
echo "Bars launched..."
