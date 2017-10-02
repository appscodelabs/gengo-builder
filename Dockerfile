FROM golang:1.9-alpine

RUN apk add --update git \
  && go get k8s.io/kubernetes || true \
  && cd /go/src/k8s.io/kubernetes \
  && git checkout v1.7.5 \
  && go install ./cmd/libs/go2idl/...

RUN go get github.com/ugorji/go/codec/codecgen || true \
  && cd /go/src/github.com/ugorji/go \
  && git checkout ded73eae5db7e7a0ef6f55aace87a2873c5d2b74 \
  && go install ./...
