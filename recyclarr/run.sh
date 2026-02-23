#!/bin/bash
echo "Starte Recyclarr Add-on V8.8..."
trap "echo 'Beende Add-on sauber...'; exit 0" SIGTERM SIGINT

CONFIG_PATH=/data/options.json

if [ ! -f "$CONFIG_PATH" ]; then
    echo "Warte auf Konfigurationsdatei..."
    sleep 5
fi

SONARR_URL=$(jq --raw-output '.sonarr_url' $CONFIG_PATH)
SONARR_APIKEY=$(jq --raw-output '.sonarr_apikey' $CONFIG_PATH)
RADARR_URL=$(jq --raw-output '.radarr_url' $CONFIG_PATH)
RADARR_APIKEY=$(jq --raw-output '.radarr_apikey' $CONFIG_PATH)
QUALITY_PROFILES=$(jq --raw-output '.quality_profiles' $CONFIG_PATH)
ENABLE_HDR=$(jq --raw-output '.enable_hdr' $CONFIG_PATH)
ENABLE_DV=$(jq --raw-output '.enable_dv' $CONFIG_PATH)
ENABLE_HDR10=$(jq --raw-output '.enable_hdr10plus' $CONFIG_PATH)
PREFER_HQ=$(jq --raw-output '.prefer_hq_groups' $CONFIG_PATH)
BLOCK_X265=$(jq --raw-output '.block_x265_hd' $CONFIG_PATH)
ENABLE_ATMOS=$(jq --raw-output '.enable_atmos' $CONFIG_PATH)
ENABLE_TRUEHD=$(jq --raw-output '.enable_truehd' $CONFIG_PATH)

export RECYCLARR_CONFIG_DIR=/data/recyclarr
mkdir -p /data/recyclarr
RECYCLARR_BIN="/app/recyclarr/recyclarr"

# Hilfsfunktion: Profile-Block mit Score generieren
make_score_block() {
    local SCORE=$1
    IFS=',' read -ra PROFILES <<< "$QUALITY_PROFILES"
    for PROFILE in "${PROFILES[@]}"; do
        PROFILE=$(echo "$PROFILE" | xargs)
        echo "          - name: \"$PROFILE\""
        echo "            score: $SCORE"
    done
}

# Profile-Block ohne Score (für quality_profiles oben)
make_profiles_block() {
    IFS=',' read -ra PROFILES <<< "$QUALITY_PROFILES"
    for PROFILE in "${PROFILES[@]}"; do
        PROFILE=$(echo "$PROFILE" | xargs)
        echo "      - name: \"$PROFILE\""
    done
}

write_instance() {
    local URL=$1
    local APIKEY=$2
    local TYPE=$3
    local NAME=$4

    cat >> /data/recyclarr/recyclarr.yml << EOF
${TYPE}:
  ${NAME}:
    base_url: ${URL}
    api_key: ${APIKEY}
    quality_profiles:
$(make_profiles_block)
    custom_formats:

      - trash_ids:
          - 85c61b3b7a49e9a5f5b7e8b5dc1a1ba0  # BR-DISK
          - e6258996055b9878b6ecd62b31cf119e  # LQ
          - 47435ece6b99a0b477caf360e79ba0bb  # LQ (Release Title)
          - 15a05bc7c1a36e2b57fd628f8977e2fc  # AV1
          - 32b367365729d530ca1c124a0b180c64  # Bad Dual Groups
          - 82d40da2bc6923f41e149b7e688e122e  # No-RlsGroup
          - e1a997ddb54e3ecbfe06341ad323c458  # Obfuscated
          - 06d66ab109d4d2eddb2794d21526d140  # Retags
        assign_scores_to:
$(make_score_block -10000)
EOF

    if [ "$BLOCK_X265" = "true" ]; then
        cat >> /data/recyclarr/recyclarr.yml << EOF
      - trash_ids:
          - 9c38ebb7384dada637be8899efa68e6f  # x265 (HD)
        assign_scores_to:
$(make_score_block -10000)
EOF
    fi

    if [ "$ENABLE_HDR" = "true" ]; then
        cat >> /data/recyclarr/recyclarr.yml << EOF
      - trash_ids:
          - 3cce5f79b4f9f5fb7f3b4ac4c8d68cf7  # HDR
        assign_scores_to:
$(make_score_block 500)
EOF
    fi

    if [ "$ENABLE_DV" = "true" ]; then
        cat >> /data/recyclarr/recyclarr.yml << EOF
      - trash_ids:
          - 585c8b55df8f3b8fd8d3b563c5ec8b99  # Dolby Vision
        assign_scores_to:
$(make_score_block 600)
EOF
    fi

    if [ "$ENABLE_HDR10" = "true" ]; then
        cat >> /data/recyclarr/recyclarr.yml << EOF
      - trash_ids:
          - e61e28db5d5f0b21e4b4f0f9b7e71a42  # HDR10+
        assign_scores_to:
$(make_score_block 550)
EOF
    fi

    if [ "$PREFER_HQ" = "true" ]; then
        cat >> /data/recyclarr/recyclarr.yml << EOF
      - trash_ids:
          - e6819cba26759a536a10af3895ef69e9  # WEB Tier 01
          - 58790d4e2fdcd9733aa7ae68ba2bb503  # WEB Tier 02
        assign_scores_to:
$(make_score_block 1500)
EOF
    fi

    if [ "$ENABLE_ATMOS" = "true" ]; then
        cat >> /data/recyclarr/recyclarr.yml << EOF
      - trash_ids:
          - 496f355514737f7d83bf7aa4d24f8169  # TrueHD Atmos
          - 2f22d89048b01681dde8afe203bf2e95  # DD+ Atmos
        assign_scores_to:
$(make_score_block 750)
EOF
    fi

    if [ "$ENABLE_TRUEHD" = "true" ]; then
        cat >> /data/recyclarr/recyclarr.yml << EOF
      - trash_ids:
          - 3cafb66171b47f226146a0770576870f  # TrueHD
          - dcf3ec6938fa32445f590a4da84256cd  # DTS-HD MA
        assign_scores_to:
$(make_score_block 650)
EOF
    fi
}

# Config zurücksetzen
> /data/recyclarr/recyclarr.yml

if [ "$SONARR_URL" != "" ] && [ "$SONARR_URL" != "null" ]; then
    write_instance "$SONARR_URL" "$SONARR_APIKEY" "sonarr" "series"
fi

if [ "$RADARR_URL" != "" ] && [ "$RADARR_URL" != "null" ]; then
    write_instance "$RADARR_URL" "$RADARR_APIKEY" "radarr" "movies"
fi

echo "recyclarr.yml erstellt:"
cat /data/recyclarr/recyclarr.yml

while true; do
    echo "Führe TRaSH-Guide Sync aus..."
    $RECYCLARR_BIN sync
    echo "Sync beendet. Nächster Lauf in 24 Stunden."
    sleep 86400
done
