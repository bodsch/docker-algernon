
FROM golang:1-alpine as builder

ARG VCS_REF
ARG BUILD_DATE
ARG BUILD_VERSION
ARG BUILD_TYPE=stable
ARG ALGERNON_VERSION

ENV \
  TERM=xterm \
  TZ='Europe/Berlin' \
  GOPATH=/opt/go \
  GOMAXPROCS=4 \
  GOOS=linux \
  GOARCH=amd64 \
  name=algernon

# ---------------------------------------------------------------------------------------

# hadolint ignore=DL3008,DL3014,DL3015,DL3017,DL3018,DL3019,DL4005
RUN \
  apk update  --quiet && \
  apk upgrade --quiet && \
  apk add     --quiet \
    ca-certificates curl g++ git make

RUN \
  echo "export TZ=${TZ}"                  > /etc/profile.d/algernon.sh && \
  echo "export BUILD_DATE=${BUILD_DATE}" >> /etc/profile.d/algernon.sh && \
  echo "export BUILD_TYPE=${BUILD_TYPE}" >> /etc/profile.d/algernon.sh

RUN \
  go get github.com/xyproto/algernon

WORKDIR ${GOPATH}/src/github.com/xyproto/algernon

RUN \
  if [ "${BUILD_TYPE}" = "stable" ] ; then \
    echo "switch to stable Tag ${ALGERNON_VERSION}" && \
    git checkout "tags/${ALGERNON_VERSION}" 2> /dev/null ; \
  fi

# hadolint ignore=DL4006,SC2153
RUN \
  ALGERNON_VERSION=$(git describe --tags --always | sed 's/^v//') && \
  echo " => go version $(go version)" && \
  echo " => build version ${ALGERNON_VERSION}" && \
  echo "export ALGERNON_VERSION=${ALGERNON_VERSION}" >> /etc/profile.d/algernon.sh

# hadolint ignore=DL4006,SC2155
RUN \
  export version=$(grep -i version main.go | head -1 | cut -d' ' -f4 | cut -d'"' -f1)

# hadolint ignore=DL4006,SC2143
RUN \
  if [ "$(go version | grep --quiet '1.10')" ] ; then \
    echo "run go build ..." && \
    go build  ; \
  else \
    export GO111MODULE=on && \
    go mod verify && \
    go build ; \
  fi

RUN \
  mkdir /tmp/algernon && \
  cp     "${GOPATH}/src/github.com/xyproto/algernon/algernon" /tmp/algernon/ && \
  cp -ar "${GOPATH}/src/github.com/xyproto/algernon/samples"  /tmp/algernon/

# ---------------------------------------------------------------------------------------

FROM alpine:3.10

COPY --from=builder /etc/profile.d/algernon.sh /etc/profile.d/algernon.sh
COPY --from=builder /tmp/algernon/algernon     /usr/bin/algernon
COPY --from=builder /tmp/algernon/samples      /etc/algernon/samples

# hadolint ignore=DL3018
RUN \
  apk update --quiet --no-cache && \
  apk add    --quiet --no-cache \
    curl && \
  rm -rf \
    /tmp/* \
    /var/cache/apk/*

VOLUME ["/algernon", "/data"]

WORKDIR /data

CMD ["/usr/bin/algernon", "--simple", "--addr=:8080", "--dir=/data", "--cache=on", "--statcache"]

HEALTHCHECK \
  --interval=5s \
  --timeout=2s \
  --retries=12 \
  CMD curl --silent --fail localhost:8080 || exit 1

# ---------------------------------------------------------------------------------------

EXPOSE 8080

LABEL \
  version=${BUILD_VERSION} \
  maintainer="Bodo Schulz <bodo@boone-schulz.de>" \
  org.label-schema.build-date=${BUILD_DATE} \
  org.label-schema.name="Jolokia Docker Image" \
  org.label-schema.description="Inofficial Algernon Docker Image" \
  org.label-schema.url="https://algernon.roboticoverlords.org/" \
  org.label-schema.vcs-url="https://github.com/bodsch/docker-algernon" \
  org.label-schema.vcs-ref=${VCS_REF} \
  org.label-schema.vendor="Bodo Schulz" \
  org.label-schema.version=${ALGERNON_VERSION} \
  org.label-schema.schema-version="1.0" \
  com.microscaling.docker.dockerfile="/Dockerfile" \
  com.microscaling.license=""

# ---------------------------------------------------------------------------------------

