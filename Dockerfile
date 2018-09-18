
FROM golang:1-alpine as builder

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
  GOARCH=amd64

# ---------------------------------------------------------------------------------------

RUN \
  apk update  --quiet && \
  apk upgrade --quiet && \
  apk add     --quiet \
    ca-certificates curl g++ git make && \
  echo "export TZ=${TZ}"                  > /etc/profile.d/algernon.sh && \
  echo "export BUILD_DATE=${BUILD_DATE}" >> /etc/profile.d/algernon.sh && \
  echo "export BUILD_TYPE=${BUILD_TYPE}" >> /etc/profile.d/algernon.sh

RUN \
  go get github.com/xyproto/algernon

RUN \
  cd ${GOPATH}/src/github.com/xyproto/algernon && \
  if [[ "${BUILD_TYPE}" = "stable" ]] ; then \
    echo "switch to stable Tag ${ALGERNON_VERSION}" && \
    git checkout tags/${ALGERNON_VERSION} 2> /dev/null ; \
  fi && \
  ALGERNON_VERSION=$(git describe --tags --always | sed 's/^v//') && \
  echo " => go version $(go version)" && \
  echo " => build version ${ALGERNON_VERSION}" && \
  echo "export ALGERNON_VERSION=${ALGERNON_VERSION}" >> /etc/profile.d/algernon.sh

RUN \
  cd ${GOPATH}/src/github.com/xyproto/algernon && \
  export name=algernon && \
  export version=$(grep -i version main.go | head -1 | cut -d' ' -f4 | cut -d'"' -f1) && \
  if [[ "$(go version | grep '1.10')" ]] ; then \
    echo "run go build ..." && \
    go build  ; \
  else \
    export GO111MODULE=on && \
    go mod verify && \
    go build && \
    go test ; \
  fi && \
  mkdir /tmp/algernon && \
  cp     ${GOPATH}/src/github.com/xyproto/algernon/algernon /tmp/algernon/ && \
  cp -ar ${GOPATH}/src/github.com/xyproto/algernon/samples  /tmp/algernon/

CMD [ "/bin/sh" ]

# ---------------------------------------------------------------------------------------

FROM alpine:3.8

RUN \
  apk update --quiet --no-cache && \
  apk add    --quiet \
    curl && \
  if [ -f /etc/profile.d/algernon.sh ] ; then . /etc/profile; fi && \
  mkdir /etc/algernon && \
  rm -rf \
    /tmp/* \
    /var/cache/apk/*

COPY --from=builder /etc/profile.d/algernon.sh /etc/profile.d/algernon.sh
COPY --from=builder /tmp/algernon/algernon /usr/bin/algernon
COPY --from=builder /tmp/algernon/samples  /etc/algernon/samples

VOLUME [ "/algernon", "/data" ]

WORKDIR /data

HEALTHCHECK \
  --interval=5s \
  --timeout=2s \
  --retries=12 \
  CMD curl --silent --fail localhost:8080 || exit 1

CMD ["/usr/bin/algernon", "--nobanner", "--domain", "--server", "--cachesize", "67108864", "--dev", "--debug", "--httponly", "--nodb", "--addr=:8080", "--dir=/data"]

# ---------------------------------------------------------------------------------------

EXPOSE 8080

LABEL \
  version="${BUILD_VERSION}" \
  maintainer="Bodo Schulz <bodo@boone-schulz.de>" \
  org.label-schema.build-date=${BUILD_DATE} \
  org.label-schema.name="Grafana Docker Image" \
  org.label-schema.description="" \
  org.label-schema.url="" \
  org.label-schema.vcs-url="" \
  org.label-schema.vendor="Bodo Schulz" \
  org.label-schema.version=${ALGERNON_VERSION} \
  org.label-schema.schema-version="1.0" \
  com.microscaling.docker.dockerfile="/Dockerfile" \
  com.microscaling.license="GNU Lesser General Public License v3.0"
