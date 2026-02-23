#!/bin/bash
echo "Starte Recyclarr Add-on für Home Assistant..."

# Lese die Werte aus der Home Assistant UI (options.json)
CONFIG_PATH=/data/options.json

SONARR_URL=$(jq --raw-output '.sonarr_url' $CONFIG_PATH)
SONARR_APIKEY=$(jq --raw-output '.sonarr_apikey' $CONFIG_PATH)
LOG_LEVEL=$(jq --raw-output '.log_level' $CONFIG_PATH)

echo "Konfiguration geladen. Log-Level: $LOG_LEVEL"

mkdir -p /config/recyclarr

# Erstelle Vorlage, falls sie fehlt
if [ ! -f /config/recyclarr/recyclarr.yml ]; then
    echo "Keine recyclarr.yml gefunden. Erstelle Basis-Vorlage..."
    recyclarr config create
fi

# Setze die Werte als Umgebungsvariablen für Recyclarr
export RECYCLARR_SONARR_URL=$SONARR_URL
export RECYCLARR_SONARR_API_KEY=$SONARR_APIKEY

# Starte Recyclarr. Wenn es fertig ist, schläft das Skript für 24 Stunden, bevor Home Assistant es neu startet.
echo "Führe Sync aus..."
recyclarr sync --app-data /config/recyclarr

echo "Sync beendet. Lege mich für 24 Stunden schlafen..."
sleep 86400
