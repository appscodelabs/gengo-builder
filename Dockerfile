FROM golang:1.13.4-buster

RUN set -x \
  && apt-get update \
  && apt-get install -y --no-install-recommends apt-utils ca-certificates wget git bash mercurial bzr xz-utils socat build-essential gcc protobuf-compiler

# install code-generator
RUN go get -v k8s.io/code-generator/... || true \
  && cd /go/src/k8s.io \
  && rm -rf code-generator \
  && git clone https://github.com/kmodules/code-generator.git \
  && cd code-generator \
  && git checkout ac-1.16.3 \
  && go install ./...

# https://github.com/gardener/gardener/issues/289
RUN go get -u -v k8s.io/gengo/... || true \
  && go get -u -v k8s.io/kube-openapi/... \
  && cd /go/src/k8s.io/kube-openapi \
  && git checkout 743ec37842bf \
  && go install ./cmd/openapi-gen/...

RUN set -x \
  && mkdir -p /go/src/github.com/ahmetb \
  && cd /go/src/github.com/ahmetb \
  && rm -rf gen-crd-api-reference-docs \
  && git clone https://github.com/appscodelabs/gen-crd-api-reference-docs.git \
  && cd gen-crd-api-reference-docs \
  && git checkout master \
  && GO111MODULE=on go install ./...

# install protobuf
RUN mkdir -p /go/src/github.com/golang \
  && cd /go/src/github.com/golang \
  && rm -rf protobuf \
  && git clone https://github.com/golang/protobuf.git \
  && mkdir -p /go/src/google.golang.org/genproto \
  && cd /go/src/google.golang.org \
  && git clone https://github.com/googleapis/go-genproto.git genproto \
  && cd /go/src/google.golang.org/genproto \
  && git checkout 54afdca5d873 \
  && cd /go/src/github.com/golang/protobuf \
  && git checkout v1.3.1 \
  && go install ./...

RUN set -x                                        \
  && export GO111MODULE=on                        \
  && export GOBIN=/usr/local/bin                  \
  && go get -u golang.org/x/tools/cmd/goimports   \
  && export GOBIN=                                \
  && export GO111MODULE=auto

# https://github.com/kubeform/kubeform/pull/2
RUN set -x \
  && mkdir -p /go/src/sigs.k8s.io \
  && cd /go/src/sigs.k8s.io \
  && rm -rf controller-tools \
  && git clone https://github.com/kmodules/controller-tools.git \
  && cd controller-tools \
  && git checkout v0.2.2-ac \
  && GO111MODULE=on go install ./cmd/controller-gen

RUN set -x \
  && rm -rf go.mod go.sum /go/pkg/mod
