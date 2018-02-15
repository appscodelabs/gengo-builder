FROM golang:1.9-alpine

RUN apk add --update git

RUN go get -v k8s.io/code-generator/... \
  && cd /go/src/k8s.io \
  && rm -rf code-generator \
  && git clone https://github.com/kubedb/code-generator.git \
  && cd code-generator \
  && git checkout release-1.9 \
  && go install ./...
