FROM golang:1.11-alpine

RUN apk add --update git bash

RUN go get -v k8s.io/code-generator/... \
  && cd /go/src/k8s.io \
  && rm -rf code-generator \
  && git clone https://github.com/pharmer/code-generator.git \
  && cd code-generator \
  && git checkout release-1.12 \
  && go install ./...
