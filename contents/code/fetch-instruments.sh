#!/bin/bash
# Download, decompress and filter Upstox instruments data to create a small JS file
# This script creates a JavaScript file that can be included directly in QML

CACHE_DIR="$HOME/.cache/plasmoidviewer/stocktea"
CACHE_FILE="$CACHE_DIR/instruments.js"
CACHE_AGE_HOURS=6

# Create cache directory if it doesn't exist
mkdir -p "$CACHE_DIR"

# Check if cache exists and is fresh (less than 6 hours old)
if [ -f "$CACHE_FILE" ]; then
    AGE=$(($(date +%s) - $(stat -c %Y "$CACHE_FILE")))
    MAX_AGE=$((CACHE_AGE_HOURS * 3600))
    
    if [ $AGE -lt $MAX_AGE ]; then
        # Cache is fresh, exit success
        echo "Cache is fresh (age: $((AGE / 3600)) hours)"
        exit 0
    fi
fi

echo "Downloading instruments data..."

# Download and decompress, filter only NSE_EQ and BSE_EQ, convert to JavaScript array
# CSV Format: instrument_key,exchange_token,tradingsymbol,name,last_price,expiry,strike,tick_size,lot_size,instrument_type,option_type,exchange
curl -s "https://assets.upstox.com/market-quote/instruments/exchange/complete.csv.gz" | \
  gunzip | \
  awk -F',' '
    BEGIN {
      print "// Auto-generated instruments data"
      print "var INSTRUMENTS_DATA = ["
      first = 1
    }
    NR > 1 && ($12 == "\"NSE_EQ\"" || $12 == "\"BSE_EQ\"") {
      # Extract fields (removing quotes)
      instrument_key = $1
      gsub(/"/, "", instrument_key)
      
      trading_symbol = $3
      gsub(/"/, "", trading_symbol)
      
      name = $4
      gsub(/"/, "", name)
      
      exchange = $12
      gsub(/"/, "", exchange)
      
      # Skip if trading_symbol is empty
      if (trading_symbol == "") next
      
      # Create JSON object (escape quotes in name)
      gsub(/"/, "\\\"", name)
      
      if (!first) print ","
      first = 0
      printf "  {\"symbol\":\"%s\",\"name\":\"%s\",\"exchange\":\"%s\",\"instrument_key\":\"%s\"}", \
        trading_symbol, name, exchange, instrument_key
    }
    END {
      print ""
      print "];"
    }
  ' > "$CACHE_FILE.tmp"

if [ $? -eq 0 ] && [ -s "$CACHE_FILE.tmp" ]; then
    # Success - move temp file to cache
    mv "$CACHE_FILE.tmp" "$CACHE_FILE"
    INST_COUNT=$(grep -c '{' "$CACHE_FILE")
    echo "Successfully created instruments.js with $INST_COUNT instruments"
    exit 0
else
    # Failed - remove temp file
    rm -f "$CACHE_FILE.tmp"
    echo "Error: Failed to create instruments file" >&2
    exit 1
fi
