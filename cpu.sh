#!/usr/bin/env bash

# Icons for different load levels
icons=("󰪞" "󰪟" "󰪠" "󰪡" "󰪢" "󰪣" "󰪤" "󰪥")

# Get CPU usage from /proc/stat
# We sample twice with a short delay to calculate the load percentage
sample_cpu() {
    grep '^cpu' /proc/stat | awk '{print $1, $2+$3+$4+$5+$6+$7+$8, $5}'
}

# Capture samples
S1=$(sample_cpu)
sleep 0.2
S2=$(sample_cpu)

# Process in AWK to get percentages
# Output: core1 usage1
#        core2 usage2
#        ...
# Also calculates total average for the icon
results=$(join <(echo "$S1") <(echo "$S2") | awk '
    {
        total = $4 - $2
        idle = $5 - $3
        if (total == 0) usage = 0
        else usage = 100 * (total - idle) / total
        print $1, usage
    }
')

# Extract usage data (excluding the "cpu" total line)
usage_data=$(echo "$results" | grep -v '^cpu ')

# Extract total usage (the "cpu" line) for the icon
total_usage=$(echo "$results" | grep '^cpu ' | awk '{print $2}')

# Pick the icon using integer arithmetic
icon_idx=$(awk -v usage="$total_usage" 'BEGIN { idx = int(usage * 8 / 100); if (idx > 7) idx = 7; print idx }')
icon=${icons[$icon_idx]}

# Use Nushell directly with the usage_data passed as a string literal
nu_table=$(nu -c "
    \"$usage_data\"
    | lines 
    | split column \" \" core usage 
    | upsert usage { |it| (\$it.usage | into float | math round | \$\"(\$in)%\") }
    | table -e -i false
" | sed 's/\x1b\[[0-9;]*m//g')

# Escape for Pango
pango_escape() {
    echo "$1" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g'
}

# Escape for JSON
json_escape() {
    echo "$1" | sed 's/"/\\"/g; s/\\/\\\\/g' | awk '{printf "%s\\n", $0}' | sed 's/\\n$//'
}

tooltip="<tt>$(pango_escape "$nu_table")</tt>"
escaped_tooltip=$(json_escape "$tooltip")

# Wrapping the icon in a span to increase its size (e.g., 13500)
echo "{\"text\": \"<span size='14500'>$icon</span>  \", \"tooltip\": \"$escaped_tooltip\"}"
