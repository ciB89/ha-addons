#!/bin/bash
echo "Starte Recyclarr Add-on V8.1..."
trap "echo 'Beende Add-on sauber...'; exit 0" SIGTERM SIGINT

CONFIG_PATH=/data/options.json

if [ ! -f "$CONFIG_PATH" ]; then
    echo "Warte auf Konfigurationsdatei..."
    sleep 5
fi

# Lese HA Add-on Optionen
SONARR_URL=$(jq --raw-output '.sonarr_url' $CONFIG_PATH)
SONARR_APIKEY=$(jq --raw-output '.sonarr_apikey' $CONFIG_PATH)
RADARR_URL=$(jq --raw-output '.radarr_url' $CONFIG_PATH)
RADARR_APIKEY=$(jq --raw-output '.radarr_apikey' $CONFIG_PATH)
QUALITY_PROFILE=$(jq --raw-output '.quality_profile' $CONFIG_PATH)
CUSTOM_FORMATS=$(jq --raw-output '.custom_formats' $CONFIG_PATH)

export RECYCLARR_CONFIG_DIR=/config/recyclarr
mkdir -p /config/recyclarr

RECYCLARR_BIN="/app/recyclarr/recyclarr"

# Custom Formats Block vorbereiten
if [ "$CUSTOM_FORMATS" = "true" ]; then
    CF_BLOCK="    custom_formats:
      - trash_ids:
          - 9c38ebb7384dada637be8899efa68e6f  # x265 (HD)
          - 4b900e171accbfb172729b63323f9d5b  # HDR"
else
    CF_BLOCK="    custom_formats: []"
fi

# Recyclarr Config neu generieren (immer, damit Änderungen übernommen werden)
echo "Erstelle recyclarr.yml aus HA-Optionen..."
cat > /config/recyclarr/recyclarr.yml << EOF
sonarr:
  series:
    base_url: $SONARR_URL
    api_key: $SONARR_APIKEY
    quality_profiles:
      - name: $QUALITY_PROFILE
$CF_BLOCK

radarr:
  movies:
    base_url: $RADARR_URL
    api_key: $RADARR_APIKEY
    quality_profiles:
      - name: $QUALITY_PROFILE
$CF_BLOCK
EOF

echo "recyclarr.yml erstellt."

# Sync-Loop
while true; do
    echo "Führe TRaSH-Guide Sync aus..."
    $RECYCLARR_BIN sync
    echo "Sync beendet. Nächster Lauf in 24 Stunden."
    sleep 86400
done
