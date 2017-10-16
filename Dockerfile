FROM denkhaus/micro-base:latest

ARG VERSION
ARG GIT_COMMIT

WORKDIR /go/src/github.com/denkhaus/microservices/bitly
COPY . .

# Run a gofmt and exclude all vendored code.
RUN test -z "$(gofmt -l $(find . -type f -name '*.go' -not -path "./vendor/*"))" || { echo "Run \"gofmt -s -w\" on your Golang code"; exit 1; }

RUN go get -v . \
 && CGO_ENABLED=0 GOOS=linux go build --ldflags "-s -w -X main.GitCommit=${GIT_COMMIT} -X main.Version=${VERSION}" -a -installsuffix cgo -o service . \
 && go test $(go list ./... | grep -v /vendor/ | grep -v /template/) -cover


FROM alpine:latest
RUN apk --no-cache add ca-certificates

WORKDIR /root/

COPY --from=0 /go/src/github.com/denkhaus/microservices/bitly/service .

ENTRYPOINT ["./service"]
