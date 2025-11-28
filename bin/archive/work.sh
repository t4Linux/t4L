#!/bin/bash
herbstclient chain , focus_monitor 1 , use 2_1
env HOME=/home/donald/E_One/teams/execon flatpak run com.github.IsmaelMartinez.teams_for_linux &
sleep 2
env HOME=/home/donald/E_One/teams/polko flatpak run com.github.IsmaelMartinez.teams_for_linux &
# herbstclient set_layout horizontal
sleep 5
herbstclient use 2_3
# superproductivity &
# obsidian &
vivaldi-stable &
sleep 5
herbstclient use 2_4
flatpak run io.astian.midori &
sleep 5
herbstclient chain , focus_monitor 0 , use 1_5
virt-manager &
virsh start manjaro_plk &
sleep 5
herbstclient chain , focus_monitor 1 , use 2_1
herbstclient chain , focus_monitor 0 , use 1_5
sed -i 's/monitor = 0/monitor = 1/g' ~/.config/dunst/dunstrc
killall -9 dunst
dunst &
~/.config/herbstluftwm/polybar/launch_work.sh &
