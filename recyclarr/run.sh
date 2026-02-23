#!/bin/bash
echo "Starte Recyclarr Add-on V6..."

trap "echo 'Beende Add-on sauber...'; exit 0" SIGTERM SIGINT

CONFIG_PATH=/data/options.json

if [ ! -f "$CONFIG_PATH" ]; then
    sleep 5
fi

SONARR_URL=$(jq --raw-output '.sonarr_url' $CONFIG_PATH)
SONARR_APIKEY=$(jq --raw-output '.sonarr_apikey' $CONFIG_PATH)

export RECYCLARR_APP_DATA=/config/recyclarr
mkdir -p /config/recyclarr

echo "Suche Recyclarr..."
# Sichere Suche, die in Alpine garantiert funktioniert
RECYCLARR_BIN=$(find /app /usr /bin /sbin /opt -iname "recyclarr" -o -iname "Recyclarr.Cli" 2>/dev/null | grep -v "/config/" | head -n 1)

echo "Recyclarr gefunden unter: $RECYCLARR_BIN"

if [ ! -f /config/recyclarr/recyclarr.yml ]; then
    echo "Erstelle Vorlage..."
    $RECYCLARR_BIN config create
fi

export RECYCLARR_SONARR_URL="$SONARR_URL"
export RECYCLARR_SONARR_API_KEY="$SONARR_APIKEY"

while true; do
    echo "Führe TRaSH-Guide Sync aus..."
    $RECYCLARR_BIN sync
    
    echo "Sync beendet. Nächster Lauf in 24 Stunden."
    sleep 86400
done
