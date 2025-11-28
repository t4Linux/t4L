#!/bin/bash

SRL="$(echo -e "Shutdown\nReboot\nSuspend\nLogout\nLock\nCancel" | fzf --prompt="Please Make a Selection : " --border=rounded --margin=5% --color=dark --height 100% --reverse --header="         LOGOUT MENU " --info=hidden --header-first)"
case $SRL in
Shutdown)
	# sudo /sbin/shutdown -h now
	poweroff
	;;
Reboot)
	# sudo /sbin/reboot
	reboot
	;;
Suspend)
	systemctl suspend
	;;
Logout)
	dkcmd exit || herbstclient quit
	;;
Lock)
	logout.sh
	;;
*) ;;
esac
