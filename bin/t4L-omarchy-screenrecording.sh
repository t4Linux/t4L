#!/bin/bash

export PATH="$HOME/.local/share/omarchy/bin:$PATH"

menu() {
  local prompt="$1"
  local options="$2"
  local extra="$3"
  local preselect="$4"

  read -r -a args <<<"$extra"

  if [[ -n "$preselect" ]]; then
    local index
    index=$(echo -e "$options" | grep -nxF "$preselect" | cut -d: -f1)
    if [[ -n "$index" ]]; then
      args+=("-c" "$index")
    fi
  fi

  echo -e "$options" | omarchy-launch-walker --dmenu --width 295 --minheight 1 --maxheight 600 -p "$prompt…" "${args[@]}" 2>/dev/null
}

show_screenrecord_menu() {
  case $(menu "Screenrecord" "  Region
  Region + Audio
  Display
  Display + Audio
  Display + Webcam") in
  *"Region + Audio"*) omarchy-cmd-screenrecord region --with-audio ;;
  *Region*) omarchy-cmd-screenrecord ;;
  *"Display + Audio"*) omarchy-cmd-screenrecord output --with-audio ;;
  *"Display + Webcam"*) omarchy-cmd-screenrecord output --with-audio --with-webcam ;;
  *Display*) omarchy-cmd-screenrecord output ;;
  *) exit 0 ;;
  esac
}

show_screenrecord_menu