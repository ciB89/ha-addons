#!/bin/bash
echo "Starte Recyclarr Add-on V8..."
trap "echo 'Beende Add-on sauber...'; exit 0" SIGTERM SIGINT

CONFIG_PATH=/data/options.json

# Warte auf options.json falls noch nicht vorhanden
if [ ! -f "$CONFIG_PATH" ]; then
    echo "Warte auf Konfigurationsdatei..."
    sleep 5
fi

# Lese HA Add-on Optionen
SONARR_URL=$(jq --raw-output '.sonarr_url' $CONFIG_PATH)
SONARR_APIKEY=$(jq --raw-output '.sonarr_apikey' $CONFIG_PATH)

# Recyclarr Verzeichnis vorbereiten
export RECYCLARR_CONFIG_DIR=/config/recyclarr
mkdir -p /config/recyclarr

RECYCLARR_BIN="/app/recyclarr/recyclarr"

# Recyclarr Konfiguration automatisch erstellen falls nicht vorhanden
if [ ! -f /config/recyclarr/recyclarr.yml ]; then
    echo "Erstelle recyclarr.yml aus HA-Optionen..."
    cat > /config/recyclarr/recyclarr.yml << EOF
sonarr:
  series:
    base_url: $SONARR_URL
    api_key: $SONARR_APIKEY
    quality_profiles:
      - name: HD-1080p
    custom_formats: []
EOF
    echo "recyclarr.yml erstellt."
fi

# Sync-Loop
while true; do
    echo "Führe TRaSH-Guide Sync aus..."
    $RECYCLARR_BIN sync
    echo "Sync beendet. Nächster Lauf in 24 Stunden."
    sleep 86400
done
