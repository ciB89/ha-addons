ARG BUILD_FROM=ghcr.io/recyclarr/recyclarr:latest
FROM $BUILD_FROM

# WICHTIG: Überschreibt den fehlerhaften Startbefehl des Basis-Images!
ENTRYPOINT []

# Installiere jq und bash
RUN apk add --no-cache jq bash

ENV RECYCLARR_APP_DATA=/config/recyclarr

COPY run.sh /run.sh
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]
