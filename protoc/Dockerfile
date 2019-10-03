FROM golang:1.12-stretch

# protoc build dependency
RUN set -x \
  && apt-get update \
  && apt-get -y --no-install-recommends install \
    automake \
    build-essential \
    ca-certificates \
    curl \
    gettext \
    git \
    mercurial \
    bzr \
    libtool \
    unzip

# install protoc
RUN set -x \
  && mkdir -p /opt/protoc \
  && cd /opt/protoc \
  && curl -fsSOL https://github.com/google/protobuf/archive/v3.5.1.tar.gz \
  && tar -xzvf v3.5.1.tar.gz --strip-component=1 \
  && rm v3.5.1.tar.gz \
  && ./autogen.sh \
  && ./configure \
  && make \
  && make check \
  && make install \
  && ldconfig

# install code-generator
RUN go get -v k8s.io/code-generator/... || true \
  && cd /go/src/k8s.io \
  && rm -rf code-generator \
  && git clone https://github.com/kmodules/code-generator.git \
  && cd code-generator \
  && git checkout release-1.14 \
  && go install ./...

RUN go get -v github.com/gogo/protobuf/...

RUN go get -u golang.org/x/tools/cmd/goimports

RUN set -x \
  && rm -rf /var/lib/apt/lists/* /usr/share/doc /usr/share/man /tmp/*

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
  && git checkout v0.2.0-beta.3-ac-v2 \
  && GO111MODULE=on go install ./cmd/controller-gen

RUN set -x \
  && mkdir -p /go/src/github.com/ahmetb \
  && cd /go/src/github.com/ahmetb \
  && rm -rf gen-crd-api-reference-docs \
  && git clone https://github.com/appscodelabs/gen-crd-api-reference-docs.git \
  && cd gen-crd-api-reference-docs \
  && git checkout master \
  && GO111MODULE=on go install ./...

RUN set -x \
  && rm -rf /go/pkg/mod
