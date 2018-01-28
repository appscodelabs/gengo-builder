#!/bin/bash
set -xeuo pipefail

docker build -t appscode/protoc:release-1.9 .
docker push appscode/protoc:release-1.9
