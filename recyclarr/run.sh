#!/bin/bash
echo "Starte Recyclarr Add-on für Home Assistant..."

trap "echo 'Beende Add-on sauber...'; exit 0" SIGTERM SIGINT

CONFIG_PATH=/data/options.json

if [ ! -f "$CONFIG_PATH" ]; then
    echo "Warte auf Home Assistant Konfiguration..."
    sleep 5
fi

SONARR_URL=$(jq --raw-output '.sonarr_url' $CONFIG_PATH)
SONARR_APIKEY=$(jq --raw-output '.sonarr_apikey' $CONFIG_PATH)
LOG_LEVEL=$(jq --raw-output '.log_level' $CONFIG_PATH)

echo "Konfiguration geladen. Log-Level: $LOG_LEVEL"

mkdir -p /config/recyclarr

# Wir nutzen den direkten Pfad zum Programm
RECYCLARR_BIN="/app/recyclarr"

# Automatischer Fallback: Falls der Ordner anders heißt, sucht das Skript die Datei selbst
if [ ! -f "$RECYCLARR_BIN" ]; then
    echo "Standard-Pfad nicht gefunden. Suche nach ausführbarer Datei..."
    RECYCLARR_BIN=$(find / -type f -name "recyclarr" | head -n 1)
    echo "Recyclarr gefunden unter: $RECYCLARR_BIN"
fi

# Erstelle Vorlage
if [ ! -f /config/recyclarr/recyclarr.yml ]; then
    echo "Erstelle Basis-Vorlage..."
    $RECYCLARR_BIN config create
fi

export RECYCLARR_SONARR_URL="$SONARR_URL"
export RECYCLARR_SONARR_API_KEY="$SONARR_APIKEY"

# Hauptschleife
while true; do
    echo "Führe TRaSH-Guide Sync aus..."
    $RECYCLARR_BIN sync
    
    echo "Sync beendet. Nächster Lauf in 24 Stunden."
    sleep 86400
done
