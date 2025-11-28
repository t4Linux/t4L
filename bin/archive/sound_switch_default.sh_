#!/bin/bash

# Function to list available sources
list_sources() {
  echo "Available audio sources:"
  pactl list short sources | awk '{print $1 ": " $2}'
}

# Function to switch to the selected source
switch_source() {
  local source_index=$1
  local source_name=$(pactl list short sources | awk -v index="$source_index" '$1 == index {print $2}')

  if [ -z "$source_name" ]; then
    echo "Invalid selection. Exiting."
    exit 1
  fi

  pactl set-default-source "$source_name"
  echo "Switched to source: $source_name"
}

# List sources
list_sources

# Ask the user to pick a source
echo -n "Enter the index number of the source you want to switch to: "
read source_index

# Switch to the selected source
switch_source "$source_index"

exit 0

#
# #!/bin/bash
#
# ACTIVE=$(pactl list cards | awk -v RS='' '/hdmi/' | awk -F': ' '/Active Profile/ { print $2 }')
#
# if [[ $ACTIVE == "output:hdmi-stereo" ]]; then
# 	ACTIVE="hdmi-stereo"
# elif [[ $ACTIVE == "output:analog-stereo" ]]; then
# 	ACTIVE="analog-stereo"
# fi
#
# card=$(pactl list cards short | grep pci | awk '{print $1}')
# PICK=$(echo -e "CROSAIR_HS70\nINTEL" | fzf --prompt="Please Make a Selection : " --border=rounded --margin=5% --color=dark --height 100% --reverse --header="     SOUND MENU    " --info=hidden --header-first)
# icon_name="/usr/share/icons/Faba/48x48/notifications/notification-audio-volume-high.svg"
#
# case "$PICK" in
# INTEL)
# 	pactl set-default-sink alsa_output.pci-0000_00_1f.3.$ACTIVE && notify-send -i $icon_name -t 2000 'Default SOUNDCARD' 'INTEL'
#
# 	;;
# CROSAIR_HS70)
# 	pactl set-default-sink alsa_output.usb-Corsair_CORSAIR_HS70_Pro_Wireless_Gaming_Headset-00.analog-stereo && notify-send -i $icon_name -t 2000 'Default SOUNDCARD' 'CROSAIR_HS70'
# 	;;
# *)
# 	exit 78
# 	;;
# esac
