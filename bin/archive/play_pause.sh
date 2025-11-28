#!/bin/bash

var="pause"
location=/home/donald/.local/bin
script=$(basename "$0")

if [[ $var == "play" ]]; then
	playerctl --all-players $var
	sed -i '0,/play/s/play/pause/' $location/$script
elif [[ $var == "pause" ]]; then
	sed -i '0,/pause/s/pause/play/' $location/$script
	playerctl --all-players $var
fi
