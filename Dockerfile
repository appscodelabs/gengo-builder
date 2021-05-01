FROM golang:1.16-buster

LABEL org.opencontainers.image.source https://github.com/appscodelabs/gengo-builder

RUN set -x \
  && apt-get update \
  && apt-get install -y --no-install-recommends apt-utils ca-certificates wget git bash mercurial bzr xz-utils socat build-essential gcc protobuf-compiler \
  && rm -rf /var/lib/apt/lists/* /usr/share/doc /usr/share/man /tmp/*

# https://github.com/gardener/gardener/issues/289
RUN set -x \
  && mkdir -p /go/src/k8s.io \
  && cd /go/src/k8s.io \
  && rm -rf kube-openapi \
  && git clone https://github.com/kubernetes/kube-openapi.git \
  && cd kube-openapi \
  && git checkout 591a79e4bda7 \
  && GO111MODULE=on go install ./cmd/openapi-gen/... \
  && cd /go \
  && rm -rf /go/pkg /go/src

# https://github.com/kubeform/kubeform/pull/2
RUN set -x \
  && mkdir -p /go/src/sigs.k8s.io \
  && cd /go/src/sigs.k8s.io \
  && rm -rf controller-tools \
  && git clone https://github.com/kmodules/controller-tools.git \
  && cd controller-tools \
  && git checkout v0.6.0-ac \
  && GO111MODULE=on go install ./cmd/controller-gen \
  && cd /go \
  && rm -rf /go/pkg /go/src

RUN set -x \
  && mkdir -p /go/src/github.com/ahmetb \
  && cd /go/src/github.com/ahmetb \
  && rm -rf gen-crd-api-reference-docs \
  && git clone https://github.com/appscodelabs/gen-crd-api-reference-docs.git \
  && cd gen-crd-api-reference-docs \
  && git checkout master \
  && GO111MODULE=on go install ./... \
  && cd /go \
  && rm -rf /go/pkg /go/src

# install protobuf
RUN mkdir -p /go/src/github.com/golang \
  && cd /go/src/github.com/golang \
  && rm -rf protobuf \
  && git clone https://github.com/golang/protobuf.git \
  && cd protobuf \
  && git checkout v1.4.3 \
  && GO111MODULE=on go install ./... \
  && cd /go \
  && rm -rf /go/pkg /go/src

RUN set -x \
  && GO111MODULE=on go get -u golang.org/x/tools/cmd/goimports \
  && cd /go \
  && rm -rf /go/pkg /go/src

# install code-generator
RUN set -x \
  && mkdir -p /go/src/k8s.io \
  && cd /go/src/k8s.io \
  && rm -rf code-generator \
  && git clone https://github.com/kmodules/code-generator.git \
  && cd code-generator \
  && git checkout ac-1.21.0 \
  && GO111MODULE=on go install ./... \
  && cd /go \
  && rm -rf /go/pkg \
  && chmod -R 0777 /go/src
