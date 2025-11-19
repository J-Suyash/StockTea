#!/bin/bash
# Download and decompress Upstox instruments data
# This script is called by the QML applet to get instrument data

CACHE_DIR="$HOME/.cache/stocktea"
CACHE_FILE="$CACHE_DIR/instruments.json"
CACHE_AGE_HOURS=6

# Create cache directory if it doesn't exist
mkdir -p "$CACHE_DIR"

# Check if cache exists and is fresh (less than 6 hours old)
if [ -f "$CACHE_FILE" ]; then
    AGE=$(($(date +%s) - $(stat -c %Y "$CACHE_FILE")))
    MAX_AGE=$((CACHE_AGE_HOURS * 3600))
    
    if [ $AGE -lt $MAX_AGE ]; then
        # Cache is fresh, use it
        cat "$CACHE_FILE"
        exit 0
    fi
fi

# Download and decompress the gzipped JSON file
curl -s "https://assets.upstox.com/market-quote/instruments/exchange/complete.json.gz" | gunzip > "$CACHE_FILE.tmp"

if [ $? -eq 0 ] && [ -s "$CACHE_FILE.tmp" ]; then
    # Success - move temp file to cache
    mv "$CACHE_FILE.tmp" "$CACHE_FILE"
    cat "$CACHE_FILE"
    exit 0
else
    # Failed - remove temp file and return error
    rm -f "$CACHE_FILE.tmp"
    echo '{"error": "Failed to download instruments"}' >&2
    exit 1
fi
