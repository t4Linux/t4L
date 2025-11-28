#!/usr/bin/env bash
#   ____ _ _       _     _     _
#  / ___| (_)_ __ | |__ (_)___| |_
# | |   | | | '_ \| '_ \| / __| __|
# | |___| | | |_) | | | | \__ \ |_
#  \____|_|_| .__/|_| |_|_|___/\__|
#           |_|

case "$1" in
  d)
    # Delete wybrany wpis
    cliphist list | wofi --dmenu --width 500 --height 200 \
      --prompt "Delete:" --style ~/.config/wofi/cliphist.css | cliphist delete
    ;;

  w)
    # Wipe cały schowek
    if [ "$(printf "Clear\nCancel" | wofi --dmenu --width 500 --height 200 \
              --prompt "Action:" --style ~/.config/wofi/short.css)" = "Clear" ]; then
      cliphist wipe
    fi
    ;;

  *)
    # Wybierz i skopiuj wpis
    cliphist list | wofi --dmenu --width 500 --height 200 \
      --prompt "Clipboard:" --style ~/.config/wofi/cliphist.css | cliphist decode | wl-copy
    ;;
esac
