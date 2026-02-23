#!/bin/bash
echo "Starte Recyclarr Add-on V7..."

trap "echo 'Beende Add-on sauber...'; exit 0" SIGTERM SIGINT

CONFIG_PATH=/data/options.json

if [ ! -f "$CONFIG_PATH" ]; then
    sleep 5
fi

SONARR_URL=$(jq --raw-output '.sonarr_url' $CONFIG_PATH)
SONARR_APIKEY=$(jq --raw-output '.sonarr_apikey' $CONFIG_PATH)

export RECYCLARR_APP_DATA=/config/recyclarr
mkdir -p /config/recyclarr

# Wir nehmen den direkten, offiziellen Pfad
echo "Suche recyclarr binary..."
which recyclarr
find / -name "recyclarr" -type f 2>/dev/null
RECYCLARR_BIN="/app/recyclarr"

echo "Prüfe Pfad..."
if [ ! -f "$RECYCLARR_BIN" ]; then
    echo "FEHLER: /app/recyclarr nicht gefunden! Das liegt wirklich im Ordner /app:"
    ls -la /app
    echo "Breche ab, da Programm fehlt."
    sleep 3600
    exit 1
else
    echo "Recyclarr erfolgreich gefunden unter: $RECYCLARR_BIN"
fi

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
