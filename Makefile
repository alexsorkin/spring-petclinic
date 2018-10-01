PROJECT_VERSION = 18.09

IMAGE_REPO=spring/petclinic
TARGET=prod

ifeq ($(DISABLE_CACHE), true)
NO_CACHE := -no-cache
endif

IS_DOCKER_BUILD := false
IS_ASSEMBLY_BUILD := true
ifneq (,$(findstring docker,$(MAKECMDGOALS)))
  IS_DOCKER_BUILD := true
  IS_ASSEMBLY_BUILD := false
endif

ifneq (,$(findstring docker,$(MAKECMDGOALS)))
  ifeq ($(strip $(TARGET)),)
    $(error TARGETS not set: example running: make docker)
  endif
endif
TARGET_ENV=$(TARGET)

JRE_IMAGE_TAG := java:jre-8-alpine-glibc
JDK_IMAGE_TAG := java:jdk-8-alpine-glibc
ARCHIVA_TAG := archiva:jre-8-alpine-glibc
IMAGE_TAG := $(PROJECT_VERSION)
BUILDER_TAG := $(PROJECT_VERSION)-builder
NGINX_TAG := $(PROJECT_VERSION)-nginx

ifeq ($(MIRROR), archiva)
  ifneq ($(strip $(DOCKER_HOST)),)
	  MIRROR_REPO_ADDR := $(shell echo $(DOCKER_HOST)|grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' | sort | uniq)
		MIRROR_REPO_URL := http://$(MIRROR_REPO_ADDR):18080/repository/internal
	endif
	ifneq ($(strip $(MIRROR_REPO_URL)),)
    MIRROR_ARG = --build-arg MIRROR_REPO_URL=$(MIRROR_REPO_URL)
	endif
else
  ifneq ($(strip $(MIRROR)),)
    MIRROR_ARG = --build-arg MIRROR_REPO_URL=$(MIRROR)
   endif
endif

MYSQL_URL := mysql:3306
MYSQL_URL_ARG := --build-arg MYSQL_URL=$(MYSQL_URL)

JDK_IMAGE := $(shell docker images $(JDK_IMAGE_TAG) -q)

.PHONY: clean prepare docker

all: clean prepare docker

prepare:
	$(info Building JRE Container Image..)
	docker build --target jre -t $(JRE_IMAGE_TAG) ./supplements/
	$(info Building JDK Container Image..)
	docker build --target jdk -t $(JDK_IMAGE_TAG) ./supplements/
	$(info Prepare phase completed.)

archiva: prepare
	$(info Building Archiva Mirror Container Image..)
	docker build --target archiva -t $(ARCHIVA_TAG) ./supplements/
	@if [ "x$(shell docker ps -f name=archiva -q)" != "x" ]; then \
		echo Archiva is already running. pid = $(shell docker ps -f name=archiva -q); \
	else \
		docker run -d -p 18080:8080 --name archiva $(ARCHIVA_TAG); \
	fi

nginx:
	$(info Building Nginx Container Image..)
	docker build --target nginx -t $(IMAGE_REPO):$(NGINX_TAG) ./supplements/

build: clean nginx
	$(info Building Package..)
	docker build --target builder $(MIRROR_ARG) $(MYSQL_URL_ARG) -t $(IMAGE_REPO):$(BUILDER_TAG) .

docker: nginx
	@if [ "x$(TARGET_ENV)" != "x" ]; then \
		docker build $(MIRROR_ARG) $(MYSQL_URL_ARG) -t $(IMAGE_REPO):$(IMAGE_TAG) .; \
	fi

purge:
	$(info Purging dead containers..)
	docker ps -a -f status=exited -q|xargs docker rm
	$(info Purging dangling images..)
	docker images -a -f dangling=true -q|xargs docker rmi
	$(info Purging dangling volumes..)
	docker volume ls -f dangling=true -q|xargs docker volume rm
	$(info Purging project images)
	docker images $(IMAGE_REPO) -q|xargs docker rmi

assembly:
	$(info Building local maven targets..)
	mvn package

clean:
	$(info Cleaning up local maven targets..)
	mvn clean
