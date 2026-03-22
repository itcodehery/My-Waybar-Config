#!/usr/bin/env bash

# Fetch the accent color dynamically from the current theme
ACCENT_COLOR=$(grep "^accent =" "$HOME/.config/omarchy/current/theme/colors.toml" | cut -d '"' -f 2)

# Fallback to white if the color isn't found
[ -z "$ACCENT_COLOR" ] && ACCENT_COLOR="#ffffff"

time=$(date +"%I:%M %p")
date_str=$(date +"%a, %d/%m")
today_day=$(date +"%e" | sed 's/ //g')

# Fetch Nushell's cal output, strip ANSI colors
cal_output=$(nu -c "cal | table -e" | sed 's/\x1b\[[0-9;]*m//g')

# Escape function for Pango markup
pango_escape() {
    echo "$1" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g'
}

# Function to escape for JSON
json_escape() {
    echo "$1" | sed 's/"/\\"/g; s/\\/\\\\/g' | awk '{printf "%s\\n", $0}' | sed 's/\\n$//'
}

# Escape the whole table
escaped_cal=$(pango_escape "$cal_output")

# Regex to highlight today's day
if [ "$today_day" -lt 10 ]; then
    pattern="  $today_day "
else
    pattern=" $today_day "
fi

# Replace the pattern with a highlighted version
highlighted_cal=$(echo "$escaped_cal" | sed "s/$pattern/<span background='$ACCENT_COLOR' color='black' weight='bold'>$pattern<\/span>/")

# Convert literal newlines to \n for JSON
# We use awk to replace every newline with the characters \n
json_safe_cal=$(echo "$highlighted_cal" | awk '{printf "%s\\n", $0}' | sed 's/\\n$//')

# Full date for the bottom
full_date=$(date +"%A, %B %d, %Y")
# Increasing the size to 'large' (you can also use numeric values like '14000')
footer="<span size='large' weight='bold' foreground='$ACCENT_COLOR'>$full_date</span>"

# Construct the tooltip
tooltip_text="<tt>$json_safe_cal</tt>\\n\\n$footer"

# Manually construct JSON
echo "{\"text\": \"<span weight='bold' foreground='$ACCENT_COLOR'>$time</span> <span size='7500' rise='1500'>$date_str</span>\", \"tooltip\": \"$tooltip_text\"}"
