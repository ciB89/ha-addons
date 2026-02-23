#!/bin/bash
echo "Starte Recyclarr Add-on für Home Assistant..."

# Sicherstellen, dass der Ordner existiert
mkdir -p /config/recyclarr

# Falls noch keine Config existiert, erstelle eine Standard-Vorlage
if [ ! -f /config/recyclarr/recyclarr.yml ]; then
    echo "Keine recyclarr.yml gefunden. Erstelle Vorlage..."
    recyclarr config create
    echo "BITTE BEACHTEN: Du musst die Datei /config/recyclarr/recyclarr.yml jetzt in Home Assistant anpassen!"
fi

echo "Starte Recyclarr (läuft automatisch 1x täglich im Hintergrund)..."
# Startet Recyclarr im Standard-Modus (führt den Sync aus und wartet dann 24h)
exec recyclarr
