.PHONY: proto build

VERSION=$(shell git semver get)
IMAGE_NAME=denkhaus/bitly-micro-srv:$(VERSION)

all: deploy

proto:
	cd proto && protoc --go_out=plugins=micro:. bitly.proto

deploy: push
	@IMAGE_NAME=$(IMAGE_NAME) \
	BITLY_ACCESS_TOKEN=$(BITLY_ACCESS_TOKEN) \
	BITLY_SECRET=$(BITLY_SECRET) \
	rancher-compose -p services up -d --force-upgrade

push: build
	docker push $(IMAGE_NAME)

build: proto commit
	docker build --build-arg VERSION=$(VERSION) --build-arg GIT_COMMIT=$(shell git rev-list -1 HEAD) -t $(IMAGE_NAME)  .

commit:
	git add -A
	-@if [ $(shell git status --porcelain 2>/dev/null | egrep "^(M| M)" | wc -l) ]; then \
		git semver next 2>/dev/null && git commit -a -m "proceed" && git push origin master; \
	fi