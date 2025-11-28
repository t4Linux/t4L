#!/bin/bash

# Check if jq is installed
if ! command -v jq &> /dev/null;
    then
    echo "jq could not be found, please install it." >&2
    exit 1
fi

APP_ID="com.github.IsmaelMartinez.teams_for_linux"

set_urgent() {
    # It can take a moment for the window to be mapped and get a workspace.
    # Let's try a few times.
    for i in {1..5};
        do
        WINDOW_ADDRESS=$(hyprctl clients -j | jq -r --arg APP_ID "$APP_ID" '.[] | select(.initialClass == "com.github.IsmaelMartinez.teams_for_linux") | .address' | head -n 1)
        if [ -n "$WINDOW_ADDRESS" ];
            then
            hyprctl dispatch seturgent address:"$WINDOW_ADDRESS"
            return
        fi
        sleep 0.1
    done
}

dbus-monitor --session "interface='org.freedesktop.Notifications',member='Notify'" | \
grep --line-buffered "string \"$APP_ID\"" | \
while read -r _;
    do
    set_urgent
done
