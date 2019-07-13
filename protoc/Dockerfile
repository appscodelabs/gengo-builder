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
RUN go get -v k8s.io/code-generator/... \
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
RUN go get -u -v k8s.io/gengo/... \
  && go get -u -v k8s.io/kube-openapi/... \
  && cd /go/src/k8s.io/kube-openapi \
  && git checkout b3a7cee44a305be0a69e1b9ac03018307287e1b0 \
  && go install ./cmd/openapi-gen/...

# https://github.com/kubeform/kubeform/pull/2
RUN GO111MODULE=on \
  go get sigs.k8s.io/controller-tools/cmd/controller-gen@v0.2.0-beta.3 \
  && rm -rf /go/pkg/mod
