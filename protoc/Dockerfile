FROM golang:1.9.1-stretch

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
    libtool \
    unzip

# install protoc
RUN set -x \
  && mkdir -p /opt/protoc \
  && cd /opt/protoc \
  && curl -fsSOL https://github.com/google/protobuf/archive/v3.3.0.tar.gz \
  && tar -xzvf v3.3.0.tar.gz --strip-component=1 \
  && rm v3.3.0.tar.gz \
  && ./autogen.sh \
  && ./configure \
  && make \
  && make check \
  && make install \
  && ldconfig

# install code-generator
RUN go get -v k8s.io/code-generator/... \
  && cd /go/src/k8s.io/code-generator \
  && git checkout 4f9758469fda3ab9e9a17c3300f3476cc13a83b2 \
  && go install ./...

RUN go get -v github.com/gogo/protobuf/...

RUN go get -u golang.org/x/tools/cmd/goimports

RUN set -x \
  && rm -rf /var/lib/apt/lists/* /usr/share/doc /usr/share/man /tmp/*
