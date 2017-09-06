FROM golang:1.9-alpine

RUN apk add --update git \
  && go get k8s.io/kubernetes || true \
  && cd src/k8s.io/kubernetes \
  && git checkout v1.7.5 \
  && go install ./cmd/libs/go2idl/...
