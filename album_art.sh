#!/bin/bash

# Configuration
LOG_FILE="/tmp/hyprlock_art.log"
CACHE_DIR="/tmp/hyprlock_cache"
mkdir -p "$CACHE_DIR"

echo "[$(date)] --- Script started ---" >> "$LOG_FILE"

# Get metadata using playerctl
STATUS=$(playerctl status 2>/dev/null)
ART_URL=$(playerctl metadata mpris:artUrl 2>/dev/null)

echo "[$(date)] Status: $STATUS, Art URL: $ART_URL" >> "$LOG_FILE"

# Fallback function to return nothing
fallback() {
    echo ""
    echo "[$(date)] Result: (fallback)" >> "$LOG_FILE"
    exit 0
}

# If no music is playing or no art URL is found, fallback
if [ "$STATUS" != "Playing" ] || [ -z "$ART_URL" ]; then
    echo "[$(date)] Not playing or no art URL found." >> "$LOG_FILE"
    fallback
fi

# Handle Spotify/Web URLs vs Local Files
if [[ "$ART_URL" == http* ]]; then
    # Use a hash of the URL as the filename to avoid re-downloading the same art
    IMG_HASH=$(echo "$ART_URL" | md5sum | cut -d' ' -f1)
    IMG_PATH="$CACHE_DIR/$IMG_HASH.png"
    
    if [ ! -f "$IMG_PATH" ]; then
        # Download the image if it doesn't exist
        echo "[$(date)] Downloading $ART_URL to $IMG_PATH" >> "$LOG_FILE"
        if ! curl -s --max-time 5 "$ART_URL" -o "$IMG_PATH"; then
            echo "[$(date)] Download failed." >> "$LOG_FILE"
            fallback
        fi
    else
        echo "[$(date)] Using cached file: $IMG_PATH" >> "$LOG_FILE"
    fi
    echo "$IMG_PATH"
    echo "[$(date)] Result: $IMG_PATH" >> "$LOG_FILE"
elif [[ "$ART_URL" == file://* ]]; then
    # Strip 'file://' prefix
    CLEAN_PATH="${ART_URL#file://}"
    # Decode URL-encoded characters (e.g., %20 to space)
    DECODED_PATH=$(printf '%b' "${CLEAN_PATH//%/\\x}")
    if [ -f "$DECODED_PATH" ]; then
        echo "$DECODED_PATH"
        echo "[$(date)] Result: $DECODED_PATH (file://)" >> "$LOG_FILE"
    else
        echo "[$(date)] File not found: $DECODED_PATH" >> "$LOG_FILE"
        fallback
    fi
else
    # Assume it's already a local path
    if [ -f "$ART_URL" ]; then
        echo "$ART_URL"
        echo "[$(date)] Result: $ART_URL (direct path)" >> "$LOG_FILE"
    else
        echo "[$(date)] File not found: $ART_URL" >> "$LOG_FILE"
        fallback
    fi
fi
