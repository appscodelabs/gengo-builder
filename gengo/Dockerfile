FROM golang:1.9.1-alpine

RUN apk add --update git

RUN go get -v k8s.io/code-generator/... \
  && cd /go/src/k8s.io/code-generator \
  && git checkout 4f9758469fda3ab9e9a17c3300f3476cc13a83b2 \
  && go install ./...
