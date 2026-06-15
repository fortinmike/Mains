#!/bin/sh

send_notification() {
    /usr/bin/osascript \
        -e 'on run arguments' \
        -e 'display notification (item 1 of arguments) with title "Mains"' \
        -e 'end run' \
        "$1"
}

case "$1" in
    mains)
        send_notification "Power restored. Running on mains power."
        ;;
    ups)
        send_notification "Mains power lost. Running on UPS."
        ;;
    battery)
        send_notification "Mains power lost. Running on battery."
        ;;
    unknown)
        send_notification "Unable to determine the current power source."
        ;;
esac
