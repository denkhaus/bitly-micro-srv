.PHONY: proto build

IMAGE_NAME=denkhaus/bitly-micro-srv

all: deploy

proto:
	cd proto && protoc --go_out=plugins=micro:. bitly.proto

deploy: push
	@IMAGE_NAME=$(IMAGE_NAME) \
	BITLY_ACCESS_TOKEN=$(BITLY_ACCESS_TOKEN) \
	BITLY_SECRET=$(BITLY_SECRET) \
	rancher-compose -p services up -d --force-upgrade

push: build
	docker push $(IMAGE_NAME):latest

build: proto commit
	docker build  -t $(IMAGE_NAME)  .

commit:
	git add -A && git commit -a -m "proceed"
	git push origin master

