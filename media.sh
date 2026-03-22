#!/usr/bin/env bash

# Fetch the accent color dynamically from the current theme
ACCENT_COLOR=$(grep "^accent =" "$HOME/.config/omarchy/current/theme/colors.toml" | cut -d '"' -f 2)

# Fallback to white if the color isn't found
[ -z "$ACCENT_COLOR" ] && ACCENT_COLOR="#ffffff"

title=$(playerctl metadata title 2>/dev/null)
artist=$(playerctl metadata artist 2>/dev/null)

if [ -n "$title" ]; then
    # Function to escape characters for Pango markup
    pango_escape() {
        echo "$1" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g'
    }

    # Function to escape double quotes for JSON strings
    json_escape() {
        echo "$1" | sed 's/"/\\"/g'
    }

    p_title=$(pango_escape "$title")
    p_artist=$(pango_escape "$artist")

    text="<span size='9000' weight='bold' foreground='$ACCENT_COLOR'>  $(pango_escape "$title")</span> <span size='8000' foreground='#a6adc8' rise='1000'>| $(pango_escape "$artist")</span>"
    tooltip="$title - $artist"

    echo "{\"text\": \"$(json_escape "$text")\", \"tooltip\": \"$(json_escape "$tooltip")\"}"
else
    echo ""
fi
