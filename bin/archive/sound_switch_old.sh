#!/bin/bash

ACTIVE=$(pactl list cards | awk -v RS='' '/hdmi/' | awk -F': ' '/Active Profile/ { print $2 }')

if [[ $ACTIVE == "output:hdmi-stereo" ]]; then
	ACTIVE="LG_ULTRAWIDE"
elif [[ $ACTIVE == "output:analog-stereo" ]]; then
	ACTIVE="Headphones"
elif [[ $ACTIVE == "output:hdmi-stereo-extra1" ]]; then
	ACTIVE="24G2W1G5"
fi

card=$(pactl list short cards | awk '{print $1}')
PICK=$(echo -e "LG_ULTRAWIDE\nHeadphones\n24G2W1G5" | fzf --prompt="Please Make a Selection : " --border=rounded --margin=5% --color=dark --height 100% --reverse --header="     SOUND MENU             active - # $ACTIVE # " --info=hidden --header-first)
icon_name="/usr/share/icons/Faba/48x48/notifications/notification-audio-volume-high.svg"

case "$PICK" in
LG_ULTRAWIDE)
	pactl set-card-profile $card output:hdmi-stereo && notify-send -i $icon_name -t 2000 'Sound switch' 'LG ULTRAWIDE'
	;;
Headphones)
	pactl set-card-profile $card output:analog-stereo && notify-send -i $icon_name -t 2000 'Sound switch' 'Headphones'
	;;
24G2W1G5)
	pactl set-card-profile $card output:hdmi-stereo-extra1 && notify-send -i $icon_name -t 2000 'Sound switch' '24G2W1G5'
	;;
*)
	exit 78
	;;
esac
