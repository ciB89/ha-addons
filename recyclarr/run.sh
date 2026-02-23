#!/bin/bash
echo "Starte Recyclarr Add-on für Home Assistant..."

# Fallback: Falls etwas schiefgeht, fangen wir Fehler ab, 
# damit das Add-on nicht in eine Absturz-Schleife gerät.
trap "echo 'Beende Add-on sauber...'; exit 0" SIGTERM SIGINT

export PATH="/app:$PATH"
CONFIG_PATH=/data/options.json

# Warten, falls die Config noch nicht bereit ist
if [ ! -f "$CONFIG_PATH" ]; then
    echo "Warte auf Home Assistant Konfiguration..."
    sleep 5
fi

SONARR_URL=$(jq --raw-output '.sonarr_url' $CONFIG_PATH)
SONARR_APIKEY=$(jq --raw-output '.sonarr_apikey' $CONFIG_PATH)
LOG_LEVEL=$(jq --raw-output '.log_level' $CONFIG_PATH)

echo "Konfiguration geladen. Log-Level: $LOG_LEVEL"

mkdir -p /config/recyclarr

if [ ! -f /config/recyclarr/recyclarr.yml ]; then
    echo "Erstelle Basis-Vorlage..."
    recyclarr config create
fi

export RECYCLARR_SONARR_URL="$SONARR_URL"
export RECYCLARR_SONARR_API_KEY="$SONARR_APIKEY"

# Haupt-Schleife, die das Add-on am Leben hält
while true; do
    echo "Führe TRaSH-Guide Sync aus..."
    recyclarr sync
    
    echo "Sync beendet. Nächster Lauf in 24 Stunden."
    # Das Skript schläft nun sicher, ohne den Container zu beenden
    sleep 86400
done
