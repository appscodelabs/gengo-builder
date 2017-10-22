#!/bin/bash
set -x
set -euo pipefail

docker build -t appscode/protoc:release-1.8 .
docker push appscode/protoc:release-1.8
