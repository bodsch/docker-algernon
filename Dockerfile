
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
  go get github.com/xyproto/algernon || true

RUN \
  cd ${GOPATH}/src/github.com/xyproto/algernon && \
  if [[ "${BUILD_TYPE}" = "stable" ]] ; then \
    echo "switch to stable Tag ${ALGERNON_VERSION}" && \
    git checkout tags/${ALGERNON_VERSION} 2> /dev/null ; \
  fi && \
  ALGERNON_VERSION=$(git describe --tags --always | sed 's/^v//') && \
  echo "export ALGERNON_VERSION=${ALGERNON_VERSION}" >> /etc/profile.d/algernon.sh

# remove external refernces to google
RUN \
  cd ${GOPATH}/src/github.com/xyproto/algernon && \
  result=$(grep -r "fonts.googleapis.com" *) && \
  if [[ $(echo -e "${result}" | wc -l) -gt 0 ]] ; \
  then \
    echo "found $(echo -e "${result}" | wc -l) external references to fonts.googleapis.com" && \
    sed -i -e "/fonts\.googleapis\.com/d"    engine/prettyerror.go ; \
    sed -i -e "s|'Lato',||g"                 engine/prettyerror.go ; \
    sed -i -e 's|@import url(//fonts.googleapis.com/css?family=.*);||g' samples/*/style.gcss ; \
    sed -i -e 's|'Lato',||g'                                            samples/*/style.gcss ; \
    sed -i -e 's|@import url(//fonts.googleapis.com/css?family=.*);||g' themes/data.go ; \
    sed -i -e "s|'Lato',||g"                                            themes/data.go ; \
  fi

RUN \
  cd ${GOPATH}/src/github.com/xyproto/algernon &&\
  export name=algernon && \
  export version=$(grep -i version main.go | head -1 | cut -d' ' -f4 | cut -d'"' -f1) && \
  GOOS=linux go build -o $name.linux && \
  mkdir /tmp/algernon && \
  cp -v $name.linux /tmp/algernon/$name && \
  cp -arv samples /tmp/algernon/

CMD [ "/bin/sh" ]

# ---------------------------------------------------------------------------------------

# ---------------------------------------------------------------------------------------

FROM alpine:3.8

RUN \
  apk --quiet --no-cache update && \
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
