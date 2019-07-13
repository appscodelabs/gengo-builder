FROM golang:1.12-alpine

RUN apk add --update git bash mercurial

RUN go get -v k8s.io/code-generator/... \
  && cd /go/src/k8s.io \
  && rm -rf code-generator \
  && git clone https://github.com/kmodules/code-generator.git \
  && cd code-generator \
  && git checkout release-1.14 \
  && go install ./...

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
