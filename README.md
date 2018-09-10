# docker-algernon

A - alpine based - docker container for [algernon](https://github.com/xyproto/algernon)


The default commandline attributes are:

```
/usr/bin/algernon --nobanner --domain --server --cachesize 67108864 --dev --debug --httponly --nodb --addr=:8080 --dir=/data
```

# Status

[![Docker Pulls](https://img.shields.io/docker/pulls/bodsch/docker-algernon)][hub]
[![Image Size](https://images.microbadger.com/badges/image/bodsch/docker-algernon)][microbadger]
[![Build Status](https://travis-ci.org/bodsch/docker-algernon)][travis]

[hub]: https://hub.docker.com/r/bodsch/docker-algernon/
[microbadger]: https://microbadger.com/images/bodsch/docker-algernon
[travis]: https://travis-ci.org/bodsch/docker-algernon


# Build

Your can use the included Makefile.

To build the Container: `make build`

To remove the builded Docker Image: `make clean`

Starts the Container: `make run`

Starts the Container with Login Shell: `make shell`

Entering the Container: `make exec`

Stop (but **not kill**): `make stop`

History `make history`


## get

    docker pull bodsch/docker-algernon


# supported Environment Vars


# Ports

- 8080
