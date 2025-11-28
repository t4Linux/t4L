#!/bin/bash

name="$(date '+%F_%H:%M:%S').png"
path=$HOME/Other/Pictures/Screenshots

gnome-screenshot -a --file=$path/$name
sleep 5
xclip -selection clipboard -t image/png -i $path/$name

echo $path/$name
