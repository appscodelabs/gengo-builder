FROM golang:1.27

LABEL org.opencontainers.image.source https://github.com/appscodelabs/gengo-builder

RUN set -x \
  && apt-get update \
  && apt-get install -y --no-install-recommends apt-utils ca-certificates wget git bash mercurial bzr xz-utils socat build-essential gcc protobuf-compiler \
  && rm -rf /var/lib/apt/lists/* /usr/share/doc /usr/share/man /tmp/*

# https://candid.technology/error-obtaining-vcs-status-exit-status-128/
# https://stackoverflow.com/a/73100228
RUN set -x \
  && git config --global --add safe.directory '*' \
  && cp /root/.gitconfig /.gitconfig

# code-generation is run via `docker run -u $(id -u):$(id -g) ...`, i.e. as an
# arbitrary non-root uid with no matching /etc/passwd entry and no $HOME. That
# breaks Go's default GOCACHE/GOENV resolution (both live under $HOME by
# default), which now matters because kube_codegen.sh (see below) invokes
# `go install`/`go list` at code-generation time, not just at image build
# time. Pin them to a world-writable directory instead.
ENV GOCACHE=/go/cache
ENV GOENV=off
RUN mkdir -p /go/cache && chmod -R 0777 /go/cache

# https://github.com/gardener/gardener/issues/289
#
# This kube-openapi commit also pins an old golang.org/x/tools that fails to
# compile under this image's Go toolchain (same tokeninternal constant-
# overflow issue as the code-generator step below), so bump it first.
RUN set -x \
  && mkdir -p /go/src/k8s.io \
  && cd /go/src/k8s.io \
  && rm -rf kube-openapi \
  && git clone https://github.com/kubernetes/kube-openapi.git \
  && cd kube-openapi \
  && git checkout f3f2b991d03b \
  && go get -u golang.org/x/tools@latest \
  && go mod tidy \
  && go install ./cmd/openapi-gen/... \
  && cd /go \
  && rm -rf /go/pkg /go/src

# https://github.com/kubeform/kubeform/pull/2
RUN set -x \
  && mkdir -p /go/src/sigs.k8s.io \
  && cd /go/src/sigs.k8s.io \
  && rm -rf controller-tools \
  && git clone https://github.com/kmodules/controller-tools.git \
  && cd controller-tools \
  && git checkout ac-0.19.0 \
  && go install ./cmd/controller-gen \
  && cd /go \
  && rm -rf /go/pkg /go/src

RUN set -x \
  && mkdir -p /go/src/github.com/ahmetb \
  && cd /go/src/github.com/ahmetb \
  && rm -rf gen-crd-api-reference-docs \
  && git clone https://github.com/appscodelabs/gen-crd-api-reference-docs.git \
  && cd gen-crd-api-reference-docs \
  && git checkout master \
  && go install ./... \
  && cd /go \
  && rm -rf /go/pkg /go/src

# install protobuf
RUN mkdir -p /go/src/github.com/golang \
  && cd /go/src/github.com/golang \
  && rm -rf protobuf \
  && git clone https://github.com/golang/protobuf.git \
  && cd protobuf \
  && git checkout v1.5.4 \
  && go install ./... \
  && cd /go \
  && rm -rf /go/pkg /go/src

RUN set -x \
  && go install golang.org/x/tools/cmd/goimports@latest \
  && cd /go \
  && rm -rf /go/pkg /go/src

# install code-generator
#
# This also provides kube_codegen.sh (https://github.com/kubernetes/code-generator/blob/master/kube_codegen.sh),
# the successor to the now-deprecated generate-groups.sh/generate-internal-groups.sh
# scripts, at /go/src/k8s.io/code-generator/kube_codegen.sh. Unlike the other
# tools installed above, kube_codegen.sh isn't a standalone binary: callers
# source it and it re-installs (`go install`) whichever generator binaries a
# given kube::codegen::gen_* function needs at the time it's invoked, so the
# cloned repo itself (not just its compiled binaries) has to remain on disk
# for downstream projects to source at code-generation time.
#
# ac-1.30.0 pins golang.org/x/tools v0.18.0, which fails to compile under
# this image's Go toolchain (a constant-overflow check added to the Go
# compiler after v0.18.0 was released rejects internal/tokeninternal), so
# bump it before building.
RUN set -x \
  && mkdir -p /go/src/k8s.io \
  && cd /go/src/k8s.io \
  && rm -rf code-generator \
  && git clone https://github.com/kmodules/code-generator.git \
  && cd code-generator \
  && git checkout ac-1.34.0 \
  && go get -u golang.org/x/tools@latest \
  && go mod tidy \
  && go install ./... \
  && cd /go \
  && rm -rf /go/pkg \
  && chmod -R 0777 /go/src /go/cache
