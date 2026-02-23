#!/bin/bash
echo "Starte Recyclarr Add-on V9.4..."
trap "echo 'Beende Add-on sauber...'; exit 0" SIGTERM SIGINT

CONFIG_PATH=/data/options.json

if [ ! -f "$CONFIG_PATH" ]; then
    echo "Warte auf Konfigurationsdatei..."
    sleep 5
fi

SONARR_URL=$(jq --raw-output '.sonarr_url' $CONFIG_PATH)
SONARR_APIKEY=$(jq --raw-output '.sonarr_apikey' $CONFIG_PATH)
SONARR_1080P=$(jq --raw-output '.sonarr_profile_1080p' $CONFIG_PATH)
SONARR_2160P=$(jq --raw-output '.sonarr_profile_2160p' $CONFIG_PATH)
RADARR_URL=$(jq --raw-output '.radarr_url' $CONFIG_PATH)
RADARR_APIKEY=$(jq --raw-output '.radarr_apikey' $CONFIG_PATH)
RADARR_1080P=$(jq --raw-output '.radarr_profile_1080p' $CONFIG_PATH)
RADARR_4K=$(jq --raw-output '.radarr_profile_4k' $CONFIG_PATH)
ENABLE_HDR=$(jq --raw-output '.enable_hdr' $CONFIG_PATH)
ENABLE_DV=$(jq --raw-output '.enable_dv' $CONFIG_PATH)
ENABLE_ATMOS=$(jq --raw-output '.enable_atmos' $CONFIG_PATH)
ENABLE_TRUEHD=$(jq --raw-output '.enable_truehd' $CONFIG_PATH)
ENABLE_SURROUND=$(jq --raw-output '.enable_surround' $CONFIG_PATH)
PREFER_HQ=$(jq --raw-output '.prefer_hq_groups' $CONFIG_PATH)

export RECYCLARR_CONFIG_DIR=/data/recyclarr
mkdir -p /data/recyclarr
RECYCLARR_BIN="/app/recyclarr/recyclarr"

# ID aus Liste holen - Format: "│ Name    ID │"
get_id() {
    local SERVICE=$1
    local NAME=$2
    $RECYCLARR_BIN list custom-formats $SERVICE 2>/dev/null \
        | grep "│ $NAME " \
        | grep -oE '[a-f0-9]{32}' \
        | head -1
}

echo "Lade Custom Format IDs von TRaSH-Guide..."

# Radarr IDs
R_BRDISK=$(get_id radarr "BR-DISK")
R_LQ=$(get_id radarr "LQ")
R_LQ_TITLE=$(get_id radarr "LQ (Release Title)")
R_AV1=$(get_id radarr "AV1")
R_OBFUSCATED=$(get_id radarr "Obfuscated")
R_RETAGS=$(get_id radarr "Retags")
R_NO_RLSGROUP=$(get_id radarr "No-RlsGroup")
R_BAD_DUAL=$(get_id radarr "Bad Dual Groups")
R_HDR=$(get_id radarr "HDR")
R_DV=$(get_id radarr "DV Boost")
R_TRUEHD_ATMOS=$(get_id radarr "TrueHD ATMOS")
R_DDPLUS_ATMOS=$(get_id radarr "DD+ ATMOS")
R_TRUEHD=$(get_id radarr "TrueHD")
R_DTSHD=$(get_id radarr "DTS-HD MA")
R_SURROUND_71=$(get_id radarr "7.1 Surround")
R_WEB_TIER1=$(get_id radarr "WEB Tier 01")
R_WEB_TIER2=$(get_id radarr "WEB Tier 02")

# Sonarr IDs
S_BRDISK=$(get_id sonarr "BR-DISK")
S_LQ=$(get_id sonarr "LQ")
S_LQ_TITLE=$(get_id sonarr "LQ (Release Title)")
S_AV1=$(get_id sonarr "AV1")
S_OBFUSCATED=$(get_id sonarr "Obfuscated")
S_RETAGS=$(get_id sonarr "Retags")
S_NO_RLSGROUP=$(get_id sonarr "No-RlsGroup")
S_BAD_DUAL=$(get_id sonarr "Bad Dual Groups")
S_HDR=$(get_id sonarr "HDR")
S_DV=$(get_id sonarr "DV Boost")
S_TRUEHD_ATMOS=$(get_id sonarr "TrueHD ATMOS")
S_DDPLUS_ATMOS=$(get_id sonarr "DD+ ATMOS")
S_TRUEHD=$(get_id sonarr "TrueHD")
S_DTSHD=$(get_id sonarr "DTS-HD MA")
S_SURROUND_71=$(get_id sonarr "7.1 Surround")
S_WEB_TIER1=$(get_id sonarr "WEB Tier 01")
S_WEB_TIER2=$(get_id sonarr "WEB Tier 02")

echo "IDs geladen."

# Score-Block per trash_id generieren
make_score_block() {
    local SCORE=$1
    shift
    for PROFILE_ID in "$@"; do
        echo "          - trash_id: $PROFILE_ID"
        echo "            score: $SCORE"
    done
}

# Custom Format Block schreiben
write_cf_block() {
    local FILE=$1
    local ID=$2
    local NAME=$3
    local SCORE_BLOCK=$4

    if [ -z "$ID" ]; then
        echo "WARNUNG: ID für '$NAME' nicht gefunden, überspringe..."
        return
    fi

    cat >> $FILE << EOF
      - trash_ids:
          - $ID  # $NAME
        assign_scores_to:
$SCORE_BLOCK
EOF
}

> /data/recyclarr/recyclarr.yml

# --- SONARR ---
if [ "$SONARR_URL" != "" ] && [ "$SONARR_URL" != "null" ]; then

    SONARR_ACTIVE_PROFILES=()
    [ "$SONARR_1080P" = "true" ] && SONARR_ACTIVE_PROFILES+=("9d142234e45d6143785ac55f5a9e8dc9")
    [ "$SONARR_2160P" = "true" ] && SONARR_ACTIVE_PROFILES+=("dfa5eaae7894077ad6449169b6eb03e0")

    cat >> /data/recyclarr/recyclarr.yml << EOF
sonarr:
  series:
    base_url: $SONARR_URL
    api_key: $SONARR_APIKEY
    delete_old_custom_formats: true
    quality_definition:
      type: series
    quality_profiles:
EOF
    [ "$SONARR_1080P" = "true" ] && cat >> /data/recyclarr/recyclarr.yml << EOF
      - trash_id: 9d142234e45d6143785ac55f5a9e8dc9  # WEB-1080p
        reset_unmatched_scores:
          enabled: true
EOF
    [ "$SONARR_2160P" = "true" ] && cat >> /data/recyclarr/recyclarr.yml << EOF
      - trash_id: dfa5eaae7894077ad6449169b6eb03e0  # WEB-2160p
        reset_unmatched_scores:
          enabled: true
EOF

    echo "    custom_formats:" >> /data/recyclarr/recyclarr.yml

    NEG=$(make_score_block -10000 "${SONARR_ACTIVE_PROFILES[@]}")
    for ID_NAME in \
        "$S_BRDISK:BR-DISK" \
        "$S_LQ:LQ" \
        "$S_LQ_TITLE:LQ (Release Title)" \
        "$S_AV1:AV1" \
        "$S_OBFUSCATED:Obfuscated" \
        "$S_RETAGS:Retags" \
        "$S_NO_RLSGROUP:No-RlsGroup" \
        "$S_BAD_DUAL:Bad Dual Groups"; do
        write_cf_block /data/recyclarr/recyclarr.yml "${ID_NAME%%:*}" "${ID_NAME#*:}" "$NEG"
    done

    if [ "$ENABLE_HDR" = "true" ]; then
        write_cf_block /data/recyclarr/recyclarr.yml "$S_HDR" "HDR" "$(make_score_block 500 "${SONARR_ACTIVE_PROFILES[@]}")"
        write_cf_block /data/recyclarr/recyclarr.yml "$S_DV" "DV Boost" "$(make_score_block 600 "${SONARR_ACTIVE_PROFILES[@]}")"
    fi

    if [ "$ENABLE_ATMOS" = "true" ]; then
        write_cf_block /data/recyclarr/recyclarr.yml "$S_TRUEHD_ATMOS" "TrueHD ATMOS" "$(make_score_block 750 "${SONARR_ACTIVE_PROFILES[@]}")"
        write_cf_block /data/recyclarr/recyclarr.yml "$S_DDPLUS_ATMOS" "DD+ ATMOS" "$(make_score_block 700 "${SONARR_ACTIVE_PROFILES[@]}")"
    fi

    if [ "$ENABLE_TRUEHD" = "true" ]; then
        write_cf_block /data/recyclarr/recyclarr.yml "$S_TRUEHD" "TrueHD" "$(make_score_block 650 "${SONARR_ACTIVE_PROFILES[@]}")"
        write_cf_block /data/recyclarr/recyclarr.yml "$S_DTSHD" "DTS-HD MA" "$(make_score_block 600 "${SONARR_ACTIVE_PROFILES[@]}")"
    fi

    if [ "$ENABLE_SURROUND" = "true" ]; then
        write_cf_block /data/recyclarr/recyclarr.yml "$S_SURROUND_71" "7.1 Surround" "$(make_score_block 400 "${SONARR_ACTIVE_PROFILES[@]}")"
    fi

    if [ "$PREFER_HQ" = "true" ]; then
        write_cf_block /data/recyclarr/recyclarr.yml "$S_WEB_TIER1" "WEB Tier 01" "$(make_score_block 1500 "${SONARR_ACTIVE_PROFILES[@]}")"
        write_cf_block /data/recyclarr/recyclarr.yml "$S_WEB_TIER2" "WEB Tier 02" "$(make_score_block 1000 "${SONARR_ACTIVE_PROFILES[@]}")"
    fi
fi

# --- RADARR ---
if [ "$RADARR_URL" != "" ] && [ "$RADARR_URL" != "null" ]; then

    RADARR_ACTIVE_PROFILES=()
    [ "$RADARR_1080P" = "true" ] && RADARR_ACTIVE_PROFILES+=("d1d67249d3890e49bc12e275d989a7e9")
    [ "$RADARR_4K" = "true" ] && RADARR_ACTIVE_PROFILES+=("64fb5f9858489bdac2af690e27c8f42f")

    cat >> /data/recyclarr/recyclarr.yml << EOF
radarr:
  movies:
    base_url: $RADARR_URL
    api_key: $RADARR_APIKEY
    delete_old_custom_formats: true
    quality_definition:
      type: movie
    quality_profiles:
EOF
    [ "$RADARR_1080P" = "true" ] && cat >> /data/recyclarr/recyclarr.yml << EOF
      - trash_id: d1d67249d3890e49bc12e275d989a7e9  # HD Bluray + WEB
        reset_unmatched_scores:
          enabled: true
EOF
    [ "$RADARR_4K" = "true" ] && cat >> /data/recyclarr/recyclarr.yml << EOF
      - trash_id: 64fb5f9858489bdac2af690e27c8f42f  # UHD Bluray + WEB
        reset_unmatched_scores:
          enabled: true
EOF

    echo "    custom_formats:" >> /data/recyclarr/recyclarr.yml

    NEG=$(make_score_block -10000 "${RADARR_ACTIVE_PROFILES[@]}")
    for ID_NAME in \
        "$R_BRDISK:BR-DISK" \
        "$R_LQ:LQ" \
        "$R_LQ_TITLE:LQ (Release Title)" \
        "$R_AV1:AV1" \
        "$R_OBFUSCATED:Obfuscated" \
        "$R_RETAGS:Retags" \
        "$R_NO_RLSGROUP:No-RlsGroup" \
        "$R_BAD_DUAL:Bad Dual Groups"; do
        write_cf_block /data/recyclarr/recyclarr.yml "${ID_NAME%%:*}" "${ID_NAME#*:}" "$NEG"
    done

    if [ "$ENABLE_HDR" = "true" ]; then
        write_cf_block /data/recyclarr/recyclarr.yml "$R_HDR" "HDR" "$(make_score_block 500 "${RADARR_ACTIVE_PROFILES[@]}")"
        write_cf_block /data/recyclarr/recyclarr.yml "$R_DV" "DV Boost" "$(make_score_block 600 "${RADARR_ACTIVE_PROFILES[@]}")"
    fi

    if [ "$ENABLE_ATMOS" = "true" ]; then
        write_cf_block /data/recyclarr/recyclarr.yml "$R_TRUEHD_ATMOS" "TrueHD ATMOS" "$(make_score_block 750 "${RADARR_ACTIVE_PROFILES[@]}")"
        write_cf_block /data/recyclarr/recyclarr.yml "$R_DDPLUS_ATMOS" "DD+ ATMOS" "$(make_score_block 700 "${RADARR_ACTIVE_PROFILES[@]}")"
    fi

    if [ "$ENABLE_TRUEHD" = "true" ]; then
        write_cf_block /data/recyclarr/recyclarr.yml "$R_TRUEHD" "TrueHD" "$(make_score_block 650 "${RADARR_ACTIVE_PROFILES[@]}")"
        write_cf_block /data/recyclarr/recyclarr.yml "$R_DTSHD" "DTS-HD MA" "$(make_score_block 600 "${RADARR_ACTIVE_PROFILES[@]}")"
    fi

    if [ "$ENABLE_SURROUND" = "true" ]; then
        write_cf_block /data/recyclarr/recyclarr.yml "$R_SURROUND_71" "7.1 Surround" "$(make_score_block 400 "${RADARR_ACTIVE_PROFILES[@]}")"
    fi

    if [ "$PREFER_HQ" = "true" ]; then
        write_cf_block /data/recyclarr/recyclarr.yml "$R_WEB_TIER1" "WEB Tier 01" "$(make_score_block 1500 "${RADARR_ACTIVE_PROFILES[@]}")"
        write_cf_block /data/recyclarr/recyclarr.yml "$R_WEB_TIER2" "WEB Tier 02" "$(make_score_block 1000 "${RADARR_ACTIVE_PROFILES[@]}")"
    fi
fi

echo "recyclarr.yml erstellt:"
cat /data/recyclarr/recyclarr.yml

while true; do
    echo "Führe TRaSH-Guide Sync aus..."
    $RECYCLARR_BIN sync
    echo "Sync beendet. Nächster Lauf in 24 Stunden."
    sleep 86400
done
