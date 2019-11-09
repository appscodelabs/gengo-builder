FROM golang:1.12-buster

RUN set -x \
  && apt-get update \
  && apt-get install -y --no-install-recommends ca-certificates wget git bash mercurial bzr xz-utils socat build-essential protobuf-compiler

# install code-generator
RUN go get -v k8s.io/code-generator/... || true \
  && cd /go/src/k8s.io \
  && rm -rf code-generator \
  && git clone https://github.com/kmodules/code-generator.git \
  && cd code-generator \
  && git checkout release-1.14 \
  && go install ./...

# https://github.com/gardener/gardener/issues/289
RUN go get -u -v k8s.io/gengo/... || true \
  && go get -u -v k8s.io/kube-openapi/... \
  && cd /go/src/k8s.io/kube-openapi \
  && git checkout b3a7cee44a305be0a69e1b9ac03018307287e1b0 \
  && go install ./cmd/openapi-gen/...

# https://github.com/kubeform/kubeform/pull/2
RUN set -x \
  && mkdir -p /go/src/sigs.k8s.io \
  && cd /go/src/sigs.k8s.io \
  && rm -rf controller-tools \
  && git clone https://github.com/kmodules/controller-tools.git \
  && cd controller-tools \
  && git checkout v0.2.0-beta.3-ac-v3 \
  && GO111MODULE=on go install ./cmd/controller-gen

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
  && git checkout b515fa19cec88c32f305a962f34ae60068947aea \
  && cd /go/src/github.com/golang/protobuf \
  && git checkout v1.2.0 \
  && go install ./...

RUN set -x \
  && rm -rf /go/pkg/mod
