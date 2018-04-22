#!/bin/bash
set -xeuo pipefail

docker build -t appscode/protoc:release-1.10 .
docker push appscode/protoc:release-1.10
