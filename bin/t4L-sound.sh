#!/bin/bash
set -euo pipefail

# --- Minimal helpers ---

menu() {
  local prompt="$1"
  local options="$2"
  local extra="${3:-}"

  read -r -a args <<<"$extra"

  echo -e "$options" | omarchy-launch-walker --dmenu --width 295 --minheight 1 --maxheight 600 -p "$prompt…" "${args[@]}" 2>/dev/null
}

terminal() {
  alacritty --class=Omarchy -e "$@"
}

open_in_editor() {
  notify-send "Editing config file" "$1"
  omarchy-launch-editor "$1"
}

show_install_menu() {
  local choice
  choice=$(menu "Sound source" "󰋋  Headphones\n󰍹  Monitor\n󰂯  Edifier")
  case "$choice" in
    *Headphones*)
      pactl set-card-profile alsa_card.pci-0000_00_1f.3 output:analog-stereo+input:analog-stereo 
      pactl set-sink-port alsa_output.pci-0000_00_1f.3.analog-stereo analog-output-headphones 
      pactl set-default-sink alsa_output.pci-0000_00_1f.3.analog-stereo 
      exit 0
      ;;
    *Monitor*)
      pactl set-card-profile alsa_card.pci-0000_00_1f.3 output:analog-stereo+input:analog-stereo 
      pactl set-card-profile alsa_card.pci-0000_00_1f.3 output:hdmi-stereo+input:analog-stereo 
      pactl set-default-sink alsa_output.pci-0000_00_1f.3.hdmi-stereo
      exit 0
      ;;
    *Edifier*)
      pactl set-card-profile bluez_card.B4_E7_B3_ED_AB_E1 a2dp-sink
      pactl set-sink-port bluez_output.B4_E7_B3_ED_AB_E1.1 headset-output
      pactl set-default-sink bluez_output.B4_E7_B3_ED_AB_E1.1
      exit 0
      ;;
    *)
      exit 0
      ;;
  esac
}

# pętla aby po instalacji wracać do menu, ESC zamyka
while true; do
  show_install_menu || exit 0
done

