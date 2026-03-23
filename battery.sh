#!/usr/bin/env bash

# Fetch the accent color dynamically from the current theme
ACCENT_COLOR=$(grep "^accent =" "$HOME/.config/omarchy/current/theme/colors.toml" | cut -d '"' -f 2)

# Fallback to white if the color isn't found
[ -z "$ACCENT_COLOR" ] && ACCENT_COLOR="#ffffff"

# Get battery capacity and status
CAPACITY=$(cat /sys/class/power_supply/BAT0/capacity)
STATUS=$(cat /sys/class/power_supply/BAT0/status)

# Choose icon based on status and capacity
if [ "$STATUS" = "Charging" ]; then
    ICONS=("󰢜" "󰂆" "󰂇" "󰂈" "󰢝" "󰂉" "󰢞" "󰂊" "󰂋" "󰂅")
else
    ICONS=("󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹")
fi

INDEX=$(( CAPACITY / 10 ))
[ $INDEX -gt 9 ] && INDEX=9
ICON=${ICONS[$INDEX]}

# Override for full or plugged
if [ "$STATUS" = "Full" ]; then
    ICON="󰂄"
    TEXT="FULL"
elif [ "$STATUS" = "Not charging" ] || [ "$STATUS" = "Unknown" ]; then
    ICON=""
    TEXT="PLG"
else
    TEXT="$CAPACITY%"
fi

# Construct Pango markup
PANGO_TEXT="<span weight='bold' foreground='$ACCENT_COLOR'>$ICON $TEXT</span>"

# Output JSON for Waybar
echo "{"text": "$PANGO_TEXT", "percentage": $CAPACITY}"
