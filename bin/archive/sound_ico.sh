#!/bin/bash

check() {

	ACTIVE=$(pactl list cards | awk -v RS='' '/hdmi/' | awk -F': ' '/Active Profile/ { print $2 }')
	if [[ $ACTIVE == "output:hdmi-stereo" ]]; then
		echo "󱡶"
	elif [[ $ACTIVE == "output:analog-stereo" ]]; then
		if [[ $(pactl info | awk -F': ' '/Default Sink/' | grep Corsair) != "" ]]; then
			echo "󰋌"
		else
			echo "󰋋"
		fi
	elif [[ $ACTIVE == "output:hdmi-stereo-extra1" ]]; then
		ACTIVE="24G2W1G5"
		ACTIVED="hdmi-stereo-extra1"
	fi
}
check
