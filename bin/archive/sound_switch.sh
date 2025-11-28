#!/bin/bash

sink_check() {

  ACTIVE=$(pactl list cards | awk -v RS='' '/hdmi/' | awk -F': ' '/Active Profile/ { print $2 }')
  if [[ $ACTIVE == "output:hdmi-stereo" ]]; then
    ACTIVE="LG_ULTRAWIDE"
    ACTIVED="hdmi-stereo"
  elif [[ $ACTIVE == "output:analog-stereo" ]]; then
    if [[ $(pactl info | awk -F': ' '/Default Sink/' | grep Corsair) != "" ]]; then
      ACTIVE="CORSAIR_GS70"
      ACTIVED="analog-stereo"
    else
      ACTIVE="Headphones"
      ACTIVED="analog-stereo"
    fi
  elif [[ $ACTIVE == "output:hdmi-stereo-extra1" ]]; then
    ACTIVE="24G2W1G5"
    ACTIVED="hdmi-stereo-extra1"
  fi
}
sink_check
# card=$(pactl list short cards | awk '{print $1}')
PICK=$(echo -e "1 CROSAIR_HS70\n2 LG_ULTRAWIDE\n3 Headphones\n4 AOC" | fzf --prompt="Please Make a Selection : " --border=rounded --margin=5% --color=dark --height 100% --reverse --header="SOUND MENU -   $ACTIVE   " --info=hidden --header-first)
icon_name="/usr/share/icons/Faba/48x48/notifications/notification-audio-volume-high.svg"

case "$PICK" in
"1 CROSAIR_HS70")
  card=$(pactl list short cards | grep usb | grep Corsair | awk '{print $1}')
  pactl set-default-sink alsa_output.usb-Corsair_CORSAIR_HS70_Pro_Wireless_Gaming_Headset-00.analog-stereo && notify-send -i $icon_name -t 2000 'Default SOUNDCARD' 'CROSAIR_HS70'
  ;;
"2 LG_ULTRAWIDE")
  card=$(pactl list short cards | grep -v usb | awk '{print $1}')
  pactl set-card-profile $card output:hdmi-stereo && notify-send -i $icon_name -t 2000 'Sound switch' 'LG ULTRAWIDE'
  sink_check
  pactl set-default-sink alsa_output.pci-0000_00_1f.3.$ACTIVED
  ;;
"3 Headphones")
  pactl set-card-profile alsa_card.pci-0000_00_1f.3 output:analog-stereo+input:analog-stereo &&
    # pactl set-sink-port alsa_output.pci-0000_00_1f.3.analog-stereo.3 analog-output-headphones &&
    pactl set-sink-port alsa_output.pci-0000_00_1f.3.analog-stereo analog-output-headphones &&
    notify-send -i $icon_name -t 2000 'Sound switch' 'Headphones'
  ;;
"4 AOC")
  card=$(pactl list short cards | grep -v usb | awk '{print $1}')
  pactl set-card-profile $card output:hdmi-stereo-extra1 && notify-send -i $icon_name -t 2000 'Sound switch' '24G2W1G5'
  sink_check
  pactl set-default-sink alsa_output.pci-0000_00_1f.3.$ACTIVED
  ;;
*)
  exit 78
  ;;
esac
