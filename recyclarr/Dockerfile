ARG BUILD_FROM=ghcr.io/recyclarr/recyclarr:latest
FROM $BUILD_FROM

# jq installieren (wird benötigt, um die HA options.json zu lesen)
RUN apk add --no-cache jq

ENV RECYCLARR_APP_DATA=/config/recyclarr
ENV RECYCLARR_CONFIG_DIR=/config/recyclarr

COPY run.sh /run.sh
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]
