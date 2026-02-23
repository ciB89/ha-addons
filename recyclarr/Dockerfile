ARG BUILD_FROM=ghcr.io/recyclarr/recyclarr:latest
FROM $BUILD_FROM

# Wir sagen Recyclarr, dass es seine Daten im HA-Config-Ordner ablegen soll
ENV RECYCLARR_APP_DATA=/config/recyclarr
ENV RECYCLARR_CONFIG_DIR=/config/recyclarr

# Kopiere unser Start-Skript in den Container
COPY run.sh /run.sh
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]
