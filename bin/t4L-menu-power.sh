#!/usr/bin/env bash
set -euo pipefail

# ------- mini helper: dmenu-like picker via omarchy-launch-walker -------
menu() {
  local prompt="$1" options="$2" extra="${3:-}"
  read -r -a args <<<"$extra"
  echo -e "$options" | omarchy-launch-walker --dmenu \
    --width 295 --minheight 1 --maxheight 600 -p "$prompt…" "${args[@]}" 2>/dev/null
}

# ------- akcje systemowe -------
handle_action() {
  local act="$1"

  case "$act" in
    # akceptuj różne formy: z menu (*Lock*), ręczne (Lock/lock)
    *Lock*|Lock|lock)
      pidof hyprlock >/dev/null || hyprlock &
      pkill -f "alacritty --class Screensaver" || true
      ;;

    *Restart*|Restart|restart)
      omarchy-state clear 're*-required' || true
      systemctl reboot --no-wall
      ;;

    *Shutdown*|Shutdown|shutdown|Poweroff|poweroff)
      omarchy-state clear 're*-required' || true
      systemctl poweroff --no-wall
      ;;

    *) return 1 ;;
  esac
}

# ------- tryb 1: wywołanie z argumentem -> bez menu -------
if [[ $# -gt 0 ]]; then
  handle_action "$1" || exit 1
  exit 0
fi

# ------- tryb 2: klasyczne menu w pętli -------
while true; do
  choice="$(menu "System" $'  Lock\n󰜉  Restart\n󰐥  Shutdown')" || exit 0
  handle_action "$choice" || exit 0
done

