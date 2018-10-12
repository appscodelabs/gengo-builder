FROM golang:1.11-alpine

RUN apk add --update git bash mercurial

RUN go get -v k8s.io/code-generator/... \
  && cd /go/src/k8s.io \
  && rm -rf code-generator \
  && git clone https://github.com/kmodules/code-generator.git \
  && cd code-generator \
  && git checkout release-1.12 \
  && go install ./...

# https://github.com/gardener/gardener/issues/289
RUN go get -u -v k8s.io/gengo/... \
  && go get -u -v k8s.io/kube-openapi/... \
  && cd /go/src/k8s.io/kube-openapi \
  && go install ./cmd/openapi-gen/...
