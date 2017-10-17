.PHONY: proto build

VERSION=0.0.13
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
	test $(shell git status --porcelain 2>/dev/null| egrep "^(M| M)" | wc -l) == 0 || git commit -a -m "proceed" && \
	V=$(git describe --abbrev=0 --tags | awk 'BEGIN { FS="." } { $3++;  if ($3 > 99) { $3=0; $2++; if ($2 > 99) { $2=0; $1++ } } } { printf "%d.%d.%d\n", $1, $2, $3 }') && \
	$(shell git tag $V) 
	#&& git push origin master

