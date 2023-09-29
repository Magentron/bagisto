LARAVEL_CONTAINER=laravel.test

APT_PACKAGES=vim lsof wget curl less inetutils-tools inetutils-ping inetutils-traceroute

DOCKER=docker
DOCKER_COMPOSE=$(DOCKER) compose

SAIL=vendor/bin/sail
SAIL_EXEC=time $(SAIL) exec -it $(LARAVEL_CONTAINER)

WWWGROUP:=$(shell id -g)
WWWUSER=sail

all:
	@echo No default target...

apt:
	@make docker-cmd CMD='apt update && apt -y install vim lsof wget curl less inetutils-tools inetutils-ping inetutils-traceroute'

build:		build-prepare build-env build-containers     apt build-seed

build-apcu:	build-prepare build-env docker-build-up-apcu apt build-seed

build-dev:	build-prepare build-env docker-build-up-dev  apt build-seed

# prepare by installing composer locally in vendor
build-prepare:	vendor/bin/sail

# use default configuration for docker
build-env:
	[ -s .env ] || cp .env.example .env

# build containers
build-containers:
	$(SAIL) up -d --build

# initialize with demo data
build-seed:
	@make docker-cmd CMD='composer run-script post-create-project-cmd'

docker-build:
	time $(DOCKER_COMPOSE) build --build-arg WWWGROUP=$(WWWGROUP) --build-arg WWWUSER=$(WWWUSER) $(EXTRA)

docker-cmd:
	@[ ! -z '$(CMD)' ] || (echo Missing CMD=... 1>&2; exit 1)
	time $(SAIL_EXEC) bash -c '$(CMD)'

docker-compose:
	time $(DOCKER_COMPOSE) $(EXTRA)

docker-build-apcu docker-apcu-build:
	@make docker-build EXTRA='--build-arg BUILD_APCU=1 $(EXTRA)'

docker-build-dev docker-dev-build:
	@make docker-build-apcu EXTRA='--build-arg BUILD_DEVELOPMENT=1 $(EXTRA)'

docker-build-service docker-service-build:
	@[ ! -z '$(SERVICE)' ] || (echo Missing SERVICE=... 1>&2; exit 1)
	@make docker-build EXTRA='$(EXTRA) $(SERVICE)'

docker-build-service-apcu:
	@[ ! -z '$(SERVICE)' ] || (echo Missing SERVICE=... 1>&2; exit 1)
	@make docker-build-apcu EXTRA='$(EXTRA) $(SERVICE)'

docker-build-service-dev:
	@[ ! -z '$(SERVICE)' ] || (echo Missing SERVICE=... 1>&2; exit 1)
	@make docker-build-dev EXTRA='$(EXTRA) $(SERVICE)'

docker-down down:
	time $(SAIL) down $(EXTRA)

docker-down-volumes:
	@make docker-down EXTRA='--volumes $(EXTRA)'

docker-up:
	time $(SAIL) up $(EXTRA)

docker-up-detached up:
	@make docker-up EXTRA='-d $(EXTRA)'

docker-up-build docker-build-up run:		docker-build docker-up-detached

docker-build-up-apcu docker-up-build-apcu:	docker-build-apcu docker-up-detached

docker-build-up-dev docker-up-build-dev:	docker-build-dev docker-up-detached

docker-ps ps:
	$(SAIL) ps

rebuild-containers:	docker-down-volumes docker-up-build docker-ps

# @see: https://laravel.com/docs/10.x/sail#sail-customization
sail-publish publish:
	$(SAIL) artisan sail:publish

shell sh:
	$(SAIL) exec -it $(EXTRA) laravel.test bash

# first run composer install so we have sail
vendor/bin/sail:
	composer install
