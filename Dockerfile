FROM golang:1.9-alpine

RUN apk add --update git

RUN go get -v k8s.io/code-generator/... \
  && cd /go/src/k8s.io/code-generator \
  && git checkout release-1.9 \
  && go install ./...
