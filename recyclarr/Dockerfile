FROM ghcr.io/recyclarr/recyclarr:latest
ENTRYPOINT []
USER root
RUN apk add --no-cache jq bash
ENV RECYCLARR_APP_DATA=/config/recyclarr
COPY run.sh /run.sh
RUN chmod a+x /run.sh
CMD [ "/run.sh" ]
