
include env_make
NS       = bodsch
VERSION ?= latest

REPO     = docker-algernon
NAME     = algernon
INSTANCE = default

BUILD_DATE      := $(shell date +%Y-%m-%d)
BUILD_VERSION   := $(shell date +%y%m)
BUILD_TYPE      ?= stable
ALGERNON_VERSION ?= 1.10.1

.PHONY: build push shell run start stop rm release

default: build

params:
	@echo ""
	@echo " BUILD_DATE     : $(BUILD_DATE)"
	@echo ""

build:
	docker build \
		--build-arg BUILD_DATE=$(BUILD_DATE) \
		--build-arg BUILD_VERSION=$(BUILD_VERSION) \
		--build-arg BUILD_TYPE=$(BUILD_TYPE) \
		--build-arg ALGERNON_VERSION=$(ALGERNON_VERSION) \
		--tag $(NS)/$(REPO):$(ALGERNON_VERSION) .

clean:
	docker rmi \
		--force \
		`docker images -q $(NS)/$(REPO) | uniq`

history:
	docker history \
		$(NS)/$(REPO):$(ALGERNON_VERSION)

push:
	docker push \
		$(NS)/$(REPO):$(ALGERNON_VERSION)

shell:
	docker run \
		--rm \
		--name $(NAME)-$(INSTANCE) \
		--interactive \
		--tty \
		$(VOLUMES) \
		$(ENV) \
		$(NS)/$(REPO):$(ALGERNON_VERSION) \
		/bin/sh

run:
	docker run \
		--rm \
		--name $(NAME)-$(INSTANCE) \
		$(PORTS) \
		$(VOLUMES) \
		$(ENV) \
		$(NS)/$(REPO):$(ALGERNON_VERSION)

exec:
	docker exec \
		--interactive \
		--tty \
		$(NAME)-$(INSTANCE) \
		/bin/sh

start:
	docker run \
		--detach \
		--name $(NAME)-$(INSTANCE) \
		$(PORTS) \
		$(VOLUMES) \
		$(ENV) \
		$(NS)/$(REPO):$(ALGERNON_VERSION)

stop:
	docker stop \
		$(NAME)-$(INSTANCE)

rm:
	docker rm \
		$(NAME)-$(INSTANCE)

release: build
	make push -e VERSION=$(ALGERNON_VERSION)

default: build
