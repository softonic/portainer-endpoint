FROM alpine:3.7

ARG version="0.1.0-dev"
ARG build_date="unknown"
ARG commit_hash="unknown"
ARG vcs_url="unknown"
ARG vcs_branch="unknown"

ENV PORTAINER_ADDR=mssing-portainer-address \
    PORTAINER_USER=missing-username \
    PORTAINER_PASS=missing-password \
    SSL_IGNORE_CERTIFICATION_CHECK=0 \
    SLEEP_IF_WORKER=10

LABEL org.label-schema.vendor="Softonic" \
    org.label-schema.name="Portainer-Endpoint" \
    org.label-schema.description="Autoregisters the swarm nodes in Portainer." \
    org.label-schema.usage="/src/README.md" \
    org.label-schema.url="https://github.com/softonic/portainer-autoregister/blob/master/README.md" \
    org.label-schema.vcs-url=$vcs_url \
    org.label-schema.vcs-branch=$vcs_branch \
    org.label-schema.vcs-ref=$commit_hash \
    org.label-schema.version=$version \
    org.label-schema.schema-version="1.0" \
    org.label-schema.docker.cmd.devel="" \
    org.label-schema.docker.params="HOST_HOSTNAME=Host hostname,\
PORTAINER_ADDR=Portainer address,\
PORTAINER_USER=Username to login,\
PORTAINER_PASS=Password to login, \
SSL_IGNORE_CERTIFICATION_CHECK=Allow insecure connections to portainer when using SSL, \
SLEEP_IF_WORKER=Seconds to wait before register the node in Portainer in case it's a worker \
" \
    org.label-schema.build-date=$build_date

RUN apk add --no-cache socat jq curl

ADD rootfs /

ENTRYPOINT  [ "/docker-entrypoint.sh" ]
CMD [ "/usr/bin/socat", "-d", "-d", "TCP-L:2375,fork", "UNIX:/var/run/docker.sock" ]
